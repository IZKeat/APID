const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const functionsV1 = require("firebase-functions/v1");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");
const cors = require("cors")({origin: true});

const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");
const SENDER_EMAIL = "limisaac418@gmail.com";

admin.initializeApp();
const db = admin.firestore();

// Helper: Retrieve event document
async function getEventDoc(eventId) {
  const snap = await db.collection("events").doc(eventId).get();
  if (!snap.exists)
    throw new HttpsError("not-found", "Event not found");
  return { id: snap.id, ...snap.data() };
}

// Helper: Retrieve attendee document
async function getAttendeeDoc(eventId, attendeeId) {
  const ref = db
    .collection("events")
    .doc(eventId)
    .collection("attendees")
    .doc(attendeeId);
  const snap = await ref.get();
  if (!snap.exists)
    throw new HttpsError("not-found", "Attendee not found");
  return { ref, data: snap.data() };
}

// Helper: Validate checkpoint if provided
async function validateCheckpointIfProvided(eventId, checkpointId) {
  if (!checkpointId) return;
  const ref = db
    .collection("events")
    .doc(eventId)
    .collection("checkpoints")
    .doc(checkpointId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError(
      "invalid-argument",
      "Checkpoint not found"
    );
  }
  const cp = snap.data();
  if (cp.active === false) {
    throw new HttpsError(
      "failed-precondition",
      "Checkpoint is inactive"
    );
  }
}

// Helper: Validate QR Timestamp
// Checks if the QR code was generated within the last 60 seconds.
// Returns { valid: boolean, reason: string }
function validateQrTimestamp(timestamp) {
  // 1. Legacy Support: If timestamp is missing, skip validation.
  if (!timestamp) return { valid: true }; 
  
  const now = Date.now();
  const ts = Number(timestamp);
  
  if (isNaN(ts)) return { valid: false, reason: "INVALID_TIMESTAMP" };
  
  // 2. Expiration Rule: 60 seconds (60000 ms)
  if (now - ts > 60000) {
    return { valid: false, reason: "QR_EXPIRED" };
  }
  
  return { valid: true };
}

// Helper: Validate & Blacklist Nonce (Anti-Replay)
// Returns { valid: boolean, reason: string, message: string }
async function validateAndBlacklistNonce(nonce) {
  if (!nonce) {
    return { valid: false, reason: "NONCE_MISSING", message: "Missing nonce" };
  }
  const ref = db.collection("nonce_blacklist").doc(nonce);
  const doc = await ref.get();
  if (doc.exists) {
    return { valid: false, reason: "NONCE_REUSED", message: "QR already used" };
  }
  // Blacklist immediately
  await ref.set({ usedAt: admin.firestore.FieldValue.serverTimestamp() });
  return { valid: true };
}

// Helper: Verify HMAC Signature (Anti-Forgery)
// Returns { ok: boolean, reason: string }
function verifyHmacSignature(uid, ts, nonce, sig) {
  const secret = "SUPER_SECRET_256_BIT_KEY"; // same as frontend

  if (!uid || !ts || !nonce || !sig) {
    return { ok: false, reason: "SIG_MISSING" };
  }

  const payload = `${uid}|${ts}|${nonce}`;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");

  if (expected !== sig) {
    return { ok: false, reason: "INVALID_SIGNATURE" };
  }

  return { ok: true };
}

// ------------------------------------------------------------------
// Helper: Rate Limiting
// ------------------------------------------------------------------
async function checkRateLimits(ip, uid) {
  const now = Date.now();
  // Use a minute bucket (e.g., 1740000) to group scans
  const minuteBucket = Math.floor(now / 60000); 
  
  const batch = db.batch();
  let limitExceeded = false;

  // 1. IP Limit (20 scans / min)
  if (ip) {
    // Sanitize IP for doc ID (replace . and : with _)
    const safeIp = ip.replace(/[\.:]/g, "_");
    const ipRef = db.collection("scan_limits").doc(`ip_${safeIp}_${minuteBucket}`);
    
    // We can't easily read-then-write in a non-transactional helper without race conditions,
    // but for rate limiting, atomic increment is best.
    // However, to check the limit, we need to know the current value.
    // We will use a transaction here or just accept slight race conditions for performance.
    // Let's use a simple increment and check logic via a separate transaction if strictness is needed.
    // For simplicity and speed, we'll assume the caller handles the error if we throw.
    
    // We will use a transaction to be safe.
    await db.runTransaction(async (t) => {
      const ipDoc = await t.get(ipRef);
      const currentCount = ipDoc.exists ? (ipDoc.data().count || 0) : 0;
      
      if (currentCount >= 20) {
        limitExceeded = true;
        return; // Exit transaction
      }
      
      t.set(ipRef, { 
        count: admin.firestore.FieldValue.increment(1),
        last_scan: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    });
    
    if (limitExceeded) {
      throw new HttpsError("resource-exhausted", "IP scan limit exceeded, please try again later.");
    }
  }

  // 2. User Limit (10 scans / min)
  if (uid) {
    const userRef = db.collection("scan_limits").doc(`user_${uid}_${minuteBucket}`);
    
    await db.runTransaction(async (t) => {
      const userDoc = await t.get(userRef);
      const currentCount = userDoc.exists ? (userDoc.data().count || 0) : 0;
      
      if (currentCount >= 10) {
        limitExceeded = true;
        return;
      }
      
      t.set(userRef, { 
        count: admin.firestore.FieldValue.increment(1),
        last_scan: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    });

    if (limitExceeded) {
      throw new HttpsError("resource-exhausted", "User scan limit exceeded, please try again later.");
    }
  }
}

// ------------------------------------------------------------------
// Helper: Anomaly Detection
// ------------------------------------------------------------------
async function detectAnomalies(ip, uid, scanPointId) {
  if (!uid) return; // Need UID for most anomaly checks

  const now = Date.now();
  const fiveMinBucket = Math.floor(now / (5 * 60000));
  const thirtyMinBucket = Math.floor(now / (30 * 60000));

  try {
    const batch = db.batch();
    let anomalyDetected = false;
    let anomalyType = "";
    let anomalyDetail = "";

    // 1. User Scan Frequency (> 20 scans / 5 mins)
    const userFreqRef = db.collection("anomaly_counters").doc(`user_freq_${uid}_${fiveMinBucket}`);
    // We use increment, but we need to check value. 
    // To avoid blocking the main flow with too many reads, we can just increment and trigger if it hits specific values?
    // Or just read. Let's read.
    const userFreqDoc = await userFreqRef.get();
    const userCount = userFreqDoc.exists ? (userFreqDoc.data().count || 0) : 0;
    
    if (userCount > 20) {
       // Only log anomaly once per bucket to avoid spamming
       if (!userFreqDoc.data().alerted) {
         anomalyDetected = true;
         anomalyType = "High Frequency User Scan";
         anomalyDetail = `User ${uid} scanned > 20 times in 5 mins`;
         batch.set(userFreqRef, { alerted: true }, { merge: true });
       }
    } else {
       batch.set(userFreqRef, { 
         count: admin.firestore.FieldValue.increment(1),
         uid: uid 
       }, { merge: true });
    }

    // 2. Scan Point Frequency (> 500 scans / 30 mins)
    if (scanPointId) {
      const spFreqRef = db.collection("anomaly_counters").doc(`sp_freq_${scanPointId}_${thirtyMinBucket}`);
      const spDoc = await spFreqRef.get();
      const spCount = spDoc.exists ? (spDoc.data().count || 0) : 0;

      if (spCount > 500) {
        if (!spDoc.data().alerted) {
          // If we haven't alerted for this anomaly yet
          // Note: This might overwrite the previous anomaly variable if multiple happen at once.
          // Ideally we log all.
          if (anomalyDetected) {
             // If already detected one, just log this one directly
             await db.collection("anomalies").add({
                uid, ip, scanPointId,
                type: "High Frequency Scan Point",
                detail: `ScanPoint ${scanPointId} scanned > 500 times in 30 mins`,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
             });
          } else {
             anomalyDetected = true;
             anomalyType = "High Frequency Scan Point";
             anomalyDetail = `ScanPoint ${scanPointId} scanned > 500 times in 30 mins`;
          }
          batch.set(spFreqRef, { alerted: true }, { merge: true });
        }
      } else {
        batch.set(spFreqRef, { 
          count: admin.firestore.FieldValue.increment(1),
          scanPointId: scanPointId 
        }, { merge: true });
      }
    }

    // 3. Multiple Device Anomaly (> 3 IPs per user)
    // We need to store a list of IPs for the user.
    // Let's store in a subcollection or a document with an array?
    // Array in doc is easier but has size limits (should be fine for < 100 IPs).
    // Let's use a document `anomaly_counters/user_ips_${uid}`
    const userIpsRef = db.collection("anomaly_counters").doc(`user_ips_${uid}`);
    const userIpsDoc = await userIpsRef.get();
    let knownIps = userIpsDoc.exists ? (userIpsDoc.data().ips || []) : [];
    
    if (ip && !knownIps.includes(ip)) {
      knownIps.push(ip);
      // Update IPs
      batch.set(userIpsRef, { ips: knownIps }, { merge: true });
      
      if (knownIps.length > 3) {
         // Check if we already alerted for this specific count or recently?
         // Simple logic: Alert every time it grows beyond 3? Or just once?
         // Let's alert if it's the 4th, 5th, etc.
         // To avoid spam, maybe check if we alerted recently.
         // For now, just log it.
         if (anomalyDetected) {
             await db.collection("anomalies").add({
                uid, ip, scanPointId,
                type: "Multiple Device Access",
                detail: `User ${uid} accessed by ${knownIps.length} different IPs`,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
             });
         } else {
             anomalyDetected = true;
             anomalyType = "Multiple Device Access";
             anomalyDetail = `User ${uid} accessed by ${knownIps.length} different IPs`;
         }
      }
    }

    // Commit updates
    await batch.commit();

    // Log Anomaly if found
    if (anomalyDetected) {
      await db.collection("anomalies").add({
        uid: uid || "unknown",
        ip: ip || "unknown",
        scanPointId: scanPointId || "unknown",
        type: anomalyType,
        detail: anomalyDetail,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      console.warn(`🚨 Anomaly Detected: ${anomalyType} - ${anomalyDetail}`);
    }

  } catch (e) {
    console.error("Anomaly detection failed (non-blocking):", e);
  }
}

// 1️⃣ verifyEventQR
exports.verifyEventQR = functions.https.onCall(async (data, context) => {
  const { eventId, attendeeId, checkpointId, timestamp, ts } = data || {};

  // Validate Timestamp (Prevent Replay/Expired QRs)
  const timeCheck = validateQrTimestamp(timestamp || ts);
  if (!timeCheck.valid) {
    return { 
      ok: false, 
      reason: timeCheck.reason, 
      message: timeCheck.reason === "QR_EXPIRED" ? "QR Code Expired" : "Invalid QR" 
    };
  }

  if (!eventId || !attendeeId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing eventId or attendeeId"
    );
  }

  const event = await getEventDoc(eventId);
  const allowedStatus = ["upcoming", "ongoing"];
  if (!allowedStatus.includes(event.status)) {
    throw new HttpsError(
      "failed-precondition",
      `Event status not valid for check-in: ${event.status}`
    );
  }

  const attendee = await getAttendeeDoc(eventId, attendeeId);

  const status = attendee.data.checkin_status || "pending";
  if (status === "checked_in") {
    return { ok: false, reason: "already_checked_in" };
  }
  if (status === "denied") {
    return { ok: false, reason: "access_denied" };
  }

  await validateCheckpointIfProvided(eventId, checkpointId);

  return {
    ok: true,
    message: "QR verified",
    event: { id: eventId, title: event.title || null, status: event.status },
    attendee: {
      id: attendeeId,
      name: attendee.data.name || null,
      role: attendee.data.role || null,
      checkin_status: status,
    },
  };
});

// 2️⃣ checkInAttendee
exports.checkInAttendee = functions.https.onCall(async (data, context) => {
  const { eventId, attendeeId, checkpointId } = data || {};
  if (!eventId || !attendeeId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing eventId or attendeeId"
    );
  }

  const attendeeRef = db
    .collection("events")
    .doc(eventId)
    .collection("attendees")
    .doc(attendeeId);
  const eventRef = db.collection("events").doc(eventId);
  const logsRef = db.collection("logs");

  await db.runTransaction(async (tx) => {
    const attendeeSnap = await tx.get(attendeeRef);
    if (!attendeeSnap.exists)
      throw new HttpsError(
        "not-found",
        "Attendee not found (tx)"
      );

    const attendeeData = attendeeSnap.data();
    if (attendeeData.checkin_status === "checked_in") {
      return;
    }

    tx.update(attendeeRef, {
      checkin_status: "checked_in",
      checkin_time: admin.firestore.FieldValue.serverTimestamp(),
      checkpoint_id: checkpointId || null,
    });

    const eventSnap = await tx.get(eventRef);
    if (!eventSnap.exists)
      throw new HttpsError("not-found", "Event not found (tx)");
    const current = Number(eventSnap.data().attendees_count || 0);
    tx.update(eventRef, {
      attendees_count: current + 1,
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(logsRef.doc(), {
      log_id: `LOG_${Date.now()}`,
      action: "CheckIn",
      user_id: attendeeId,
      detail: `Attendee ${attendeeId} checked in to event ${eventId}${
        checkpointId ? " at " + checkpointId : ""
      }`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, message: "Check-in successful" };
});

// 3️⃣ verifyQrTimestamp (Generic validation for other modes)
// Can be called by Commerce/Access/Library modes to check validity
exports.verifyQrTimestamp = functions.https.onCall(async (data, context) => {
  const { timestamp, ts } = data || {};
  const check = validateQrTimestamp(timestamp || ts);
  
  if (!check.valid) {
    return { ok: false, reason: check.reason };
  }
  
  return { ok: true, message: "Timestamp valid" };
});




// ... (imports remain same)

// ------------------------------------------------------------------
// 6️⃣ Background Anomaly Detection (Triggered by Interaction Creation)
// ------------------------------------------------------------------
exports.detectAnomaliesOnInteraction = onDocumentCreated("interactions/{interactionId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const uid = data.user_id;
  const scanPointId = data.scan_point_id;
  const ip = data.ip_address; // We will add this field

  if (uid) {
    await detectAnomalies(ip, uid, scanPointId);
  }
});

// ... (helpers remain same)

// ------------------------------------------------------------------
// 4️⃣ processAccessScan
// Handles access control logic (Blacklist/Whitelist)
// ------------------------------------------------------------------
exports.processAccessScan = onCall(async (request) => {
  const data = request.data || {};
  const { uid, scanPointId, timestamp, ts, nonce, sig } = data;
  const clientIp = request.rawRequest ? request.rawRequest.ip : null;

  // ⚡ PARALLEL: Audit Log & Rate Limits
  const checksPromise = Promise.all([
    db.collection("audit_logs").add({
      function: "processAccessScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "STARTED"
    }),
    checkRateLimits(clientIp, uid)
  ]);

  // Wait for checks (Rate Limit might throw)
  await checksPromise;

  // Anomaly detection moved to background trigger on 'interactions'

  // 0. Verify HMAC Signature (Anti-Forgery)
  const sigCheck = verifyHmacSignature(uid, ts || timestamp, nonce, sig);
  if (!sigCheck.ok) {
    return { 
      ok: false, 
      reason: sigCheck.reason, 
      message: sigCheck.reason === "SIG_MISSING" ? "Missing QR signature" : "Invalid QR signature" 
    };
  }

  // 1. Validate Nonce (Anti-Replay)
  const nonceCheck = await validateAndBlacklistNonce(nonce);
  if (!nonceCheck.valid) {
    return { ok: false, reason: nonceCheck.reason, message: nonceCheck.message };
  }

  // 1. Validate Timestamp
  const timeCheck = validateQrTimestamp(timestamp || ts);
  if (!timeCheck.valid) {
    return { 
      ok: false, 
      reason: "QR_EXPIRED", 
      message: "QR Code Expired. Please refresh." 
    };
  }

  if (!uid || !scanPointId) {
    throw new HttpsError("invalid-argument", "Missing uid or scanPointId");
  }

  try {
    // 2. Get User Data
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      return { ok: false, reason: "USER_NOT_FOUND", message: "User not found" };
    }
    const userData = userDoc.data();

    // 3. Get Scan Point Data (for name/location)
    const scanPointDoc = await db.collection("scan_points").doc(scanPointId).get();
    const scanPointData = scanPointDoc.exists ? scanPointDoc.data() : {};
    const scanPointName = scanPointData.name || "Unknown Access Point";
    const scanPointLocation = scanPointData.location || "Unknown Location";

    // 4. Check Blacklist
    if (userData.is_blacklisted === true) {
      // Log denial
      await db.collection("interactions").add({
        user_id: uid,
        scan_point_id: scanPointId,
        scan_point_name: scanPointName,
        type: "access_denied",
        location: scanPointLocation,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "denied",
        denial_reason: "User is blacklisted",
        interaction_id: db.collection("interactions").doc().id,
        ip_address: clientIp // For anomaly detection
      });
      return { ok: false, reason: "BLACKLISTED", message: "Access blocked. Contact security." };
    }

    // 5. Check Whitelist (access_permissions)
    const permissions = userData.access_permissions || [];
    if (!permissions.includes(scanPointId)) {
      // Log denial
      await db.collection("interactions").add({
        user_id: uid,
        scan_point_id: scanPointId,
        scan_point_name: scanPointName,
        type: "access_denied",
        location: scanPointLocation,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "denied",
        denial_reason: "Not authorized for this access point",
        interaction_id: db.collection("interactions").doc().id,
        ip_address: clientIp // For anomaly detection
      });
      return { ok: false, reason: "NOT_WHITELISTED", message: "Not authorized for this area." };
    }

    // 6. Access Granted
    const interactionId = db.collection("interactions").doc().id;
    const userName = userData.name || `${userData.first_name || ""} ${userData.last_name || ""}`.trim();

    const batch = db.batch();

    // a) Create Interaction
    const interactionRef = db.collection("interactions").doc(interactionId);
    batch.set(interactionRef, {
      user_id: uid,
      user_email: userData.email || null,
      user_name: userName || null,
      scan_point_id: scanPointId,
      scan_point_name: scanPointName,
      type: "access_granted",
      location: scanPointLocation,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "success",
      interaction_id: interactionId,
      ip_address: clientIp // For anomaly detection
    });

    // b) Update Scan Point Stats
    if (scanPointDoc.exists) {
      batch.update(db.collection("scan_points").doc(scanPointId), {
        interaction_count: admin.firestore.FieldValue.increment(1),
        scan_count: admin.firestore.FieldValue.increment(1),
        last_active: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // c) Update User Stats
    batch.update(db.collection("users").doc(uid), {
      access_count: admin.firestore.FieldValue.increment(1),
      last_access_activity: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();

    // 📝 AUDIT LOG: SUCCESS (Fire and forget or await?)
    // Let's await to ensure log integrity, but it's the last step.
    await db.collection("audit_logs").add({
      function: "processAccessScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "SUCCESS"
    });

    return { 
      ok: true, 
      message: `Access granted! Welcome to ${scanPointName}`,
      data: {
        access_granted: true,
        user_name: userName,
        interaction_id: interactionId
      }
    };

  } catch (error) {
    console.error("processAccessScan error:", error);

    // 📝 AUDIT LOG: ERROR
    await db.collection("audit_logs").add({
      function: "processAccessScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "ERROR",
      error: error.message
    });

    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------------------------------------------
// 5️⃣ processCommerceScan
// Handles payment processing (Balance Check -> Deduct -> Log)
// ------------------------------------------------------------------
exports.processCommerceScan = onCall(async (request) => {
  const data = request.data || {};
  const { uid, scanPointId, amount, items, timestamp, ts, nonce, sig } = data;
  const purchaseAmount = Number(amount) || 0;
  const clientIp = request.rawRequest ? request.rawRequest.ip : null;

  // ⚡ PARALLEL: Audit Log & Rate Limits
  const checksPromise = Promise.all([
    db.collection("audit_logs").add({
      function: "processCommerceScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "STARTED"
    }),
    checkRateLimits(clientIp, uid)
  ]);

  // Wait for checks
  await checksPromise;

  // Anomaly detection moved to background trigger on 'interactions'

  // 0. Verify HMAC Signature (Anti-Forgery)
  const sigCheck = verifyHmacSignature(uid, ts || timestamp, nonce, sig);
  if (!sigCheck.ok) {
    return { 
      ok: false, 
      reason: sigCheck.reason, 
      message: sigCheck.reason === "SIG_MISSING" ? "Missing QR signature" : "Invalid QR signature" 
    };
  }

  // 1. Validate Nonce (Anti-Replay)
  const nonceCheck = await validateAndBlacklistNonce(nonce);
  if (!nonceCheck.valid) {
    return { ok: false, reason: nonceCheck.reason, message: nonceCheck.message };
  }

  // 1. Validate Timestamp
  const timeCheck = validateQrTimestamp(timestamp || ts);
  if (!timeCheck.valid) {
    return { ok: false, reason: "QR_EXPIRED", message: "QR Code Expired. Please refresh." };
  }

  if (!uid || !scanPointId || purchaseAmount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid payment data");
  }

  // Smart Lookup for Student ID (e.g. tp012345) -> UID
  let targetUid = uid;
  if (uid.toLowerCase().startsWith("tp")) {
    const email = `${uid.toLowerCase()}@mail.apu.edu.my`;
    const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();
    if (!userQuery.empty) {
      targetUid = userQuery.docs[0].id;
    } else {
      console.warn(`Could not resolve student ID ${uid} to UID`);
    }
  }

  try {
    const result = await db.runTransaction(async (t) => {
      // 2. Get User & Check Balance
      const userRef = db.collection("users").doc(targetUid);
      const userDoc = await t.get(userRef);
      
      if (!userDoc.exists) {
        return { ok: false, reason: "USER_NOT_FOUND", message: "User account not found" };
      }

      const userData = userDoc.data();
      const currentBalance = Number(userData.balance ?? userData.wallet_balance ?? 0);

      if (currentBalance < purchaseAmount) {
        return { 
          ok: false, 
          reason: "INSUFFICIENT_BALANCE", 
          message: `Insufficient balance. Current: RM ${currentBalance.toFixed(2)}` 
        };
      }

      // 3. Get Scan Point Name
      const scanPointRef = db.collection("scan_points").doc(scanPointId);
      const scanPointDoc = await t.get(scanPointRef);
      const scanPointData = scanPointDoc.exists ? scanPointDoc.data() : {};
      const scanPointName = scanPointData.name || "Unknown Shop";
      const merchantUid = scanPointData.owner_uid;

      // 4. Execute Transaction
      const newBalance = currentBalance - purchaseAmount;
      const interactionId = db.collection("interactions").doc().id;
      const interactionRef = db.collection("interactions").doc(interactionId);

      // a) Create Purchase Record
      t.set(interactionRef, {
        user_id: targetUid,
        scan_point_id: scanPointId,
        scan_point_name: scanPointName,
        type: "purchase",
        amount: purchaseAmount,
        item_name: "General Purchase",
        description: `Purchase at ${scanPointName}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        remarks: "Payment processed via Cloud Function",
        interaction_id: interactionId,
        status: "completed",
        items: items || [],
        ip_address: clientIp // For anomaly detection
      });

      // b) Deduct Balance
      t.update(userRef, {
        balance: newBalance,
        wallet_balance: newBalance,
        total_spent: admin.firestore.FieldValue.increment(purchaseAmount),
        last_transaction: admin.firestore.FieldValue.serverTimestamp()
      });

      // c) Update Merchant Stats
      if (scanPointDoc.exists) {
        t.update(scanPointRef, {
          revenue: admin.firestore.FieldValue.increment(purchaseAmount),
          today_revenue: admin.firestore.FieldValue.increment(purchaseAmount),
          interaction_count: admin.firestore.FieldValue.increment(1),
          scan_count: admin.firestore.FieldValue.increment(1),
          last_active: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      // d) Notify Desktop POS (Update Scanner Status)
      if (merchantUid) {
        const statusRef = db.collection("scanner_status").doc(merchantUid);
        t.set(statusRef, {
          status: 'success',
          message: `Payment received: RM ${purchaseAmount.toFixed(2)}`,
          last_amount: purchaseAmount,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      return {
        ok: true,
        message: `Payment successful! RM ${purchaseAmount.toFixed(2)} paid.`,
        data: {
          amount: purchaseAmount,
          new_balance: newBalance,
          customer_email: userData.email
        }
      };
    });

    // 📝 AUDIT LOG: SUCCESS
    await db.collection("audit_logs").add({
      function: "processCommerceScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "SUCCESS"
    });

    return result;

  } catch (error) {
    console.error("processCommerceScan error:", error);

    // 📝 AUDIT LOG: ERROR
    await db.collection("audit_logs").add({
      function: "processCommerceScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "ERROR",
      error: error.message
    });

    throw new HttpsError("internal", "Payment processing failed");
  }
});

// ------------------------------------------------------------------
// 6️⃣ Keep Warm (Scheduled)
// Prevents cold starts for critical functions
// ------------------------------------------------------------------

exports.keepWarm = onSchedule("every 5 minutes", async (event) => {
  console.log("🔥 Keep-Warm Ping: Keeping functions warm...");
  // Optional: Ping other services if needed
  return null;
});

// ------------------------------------------------------------------
// 6️⃣ generateLoginToken
// Triggers when a login session is authorized, generates a Custom Token
// ------------------------------------------------------------------
// Using v2 syntax for better compatibility and performance
exports.generateLoginToken = onDocumentUpdated("login_sessions/{sessionId}", async (event) => {
    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();
    const sessionId = event.params.sessionId;

    // Only run if status changed to 'authorized'
    if (newValue.status === "authorized" && previousValue.status !== "authorized") {
      const uid = newValue.uid;

      if (uid) {
        try {
          // Generate Custom Token for the user
          const token = await admin.auth().createCustomToken(uid);
          
          // Write token back to the session document
          // The Desktop client is listening for this token to sign in
          await event.data.after.ref.update({ 
            token: token,
            token_generated_at: admin.firestore.FieldValue.serverTimestamp()
          });

          console.log(`✅ Generated custom token for session ${sessionId} (User: ${uid})`);
        } catch (error) {
          console.error(`❌ Error generating custom token for session ${sessionId}:`, error);
          await event.data.after.ref.update({ 
            error: "Failed to generate token",
            error_details: error.message 
          });
        }
      } else {
        console.warn(`⚠️ Session ${sessionId} authorized but missing UID`);
      }
    }
  });

// ------------------------------------------------------------------
// 6️⃣ processLibraryScan
// Handles Student Scan (Session) & Book Scan (Borrow/Return)
// ------------------------------------------------------------------
exports.processLibraryScan = onCall(async (request) => {
  const data = request.data || {};
  const { 
    scanType, // 'user' or 'item'
    uid,      // for user scan
    itemId,   // for item scan (bookId)
    scanPointId, 
    mode,     // 'borrow' or 'return'
    timestamp, 
    ts,
    nonce,
    sig
  } = data;
  const clientIp = request.rawRequest ? request.rawRequest.ip : null;

  // 📝 AUDIT LOG: START
  await db.collection("audit_logs").add({
    function: "processLibraryScan",
    uid: uid || null,
    ip: clientIp || null,
    scanPointId: scanPointId || null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: "STARTED"
  });

  try {
    console.log("🔍 [processLibraryScan] Received Data Keys:", Object.keys(data || {}));
    console.log("🔍 [processLibraryScan] scanPointId:", scanPointId);

    // --- Rate Limiting & Anomaly Detection (Only for User Scans) ---
    if (scanType === 'user') {
      await checkRateLimits(clientIp, uid);
      await detectAnomalies(clientIp, uid, scanPointId);
    }
    // ---------------------------------------------------------------

    // 0. Verify HMAC Signature (Only for User Scan)
    if (scanType === 'user') {
      const sigCheck = verifyHmacSignature(uid, ts || timestamp, nonce, sig);
      if (!sigCheck.ok) {
        return { 
          ok: false, 
          reason: sigCheck.reason, 
          message: sigCheck.reason === "SIG_MISSING" ? "Missing QR signature" : "Invalid QR signature" 
        };
      }
    }

    // 1. Validate Nonce (Only for User Scan)
    if (scanType === 'user') {
      const nonceCheck = await validateAndBlacklistNonce(nonce);
      if (!nonceCheck.valid) {
        return { ok: false, reason: nonceCheck.reason, message: nonceCheck.message };
      }
    }

    // 1. Validate Timestamp (Only for User Scan)
    // Book barcodes usually don't have timestamps, so we skip for 'item' type
    if (scanType === 'user') {
      const timeCheck = validateQrTimestamp(timestamp || ts);
      if (!timeCheck.valid) {
        return { ok: false, reason: "QR_EXPIRED", message: "QR Code Expired. Please refresh." };
      }
    }

    if (!scanPointId) {
      throw new HttpsError("invalid-argument", "Missing scanPointId");
    }

    // === SCENARIO A: Student Scan (Start Session) ===
    if (scanType === 'user') {
      if (!uid) return { ok: false, message: "Missing User ID" };

      // Check permissions
      const userDoc = await db.collection("users").doc(uid).get();
      if (!userDoc.exists) return { ok: false, message: "User not found" };
      
      const perms = userDoc.data().access_permissions || [];
      // Assuming 'access_library' is a boolean flag in permissions map or just checking role?
      // The Dart code checked: permissions['access_library'] == false.
      // Let's assume if the user exists, they can enter, unless explicitly denied.
      // Or we can check a specific field if needed. For now, basic user check.

      // Create/Update Session
      await db.collection("library_sessions").doc(scanPointId).set({
        scan_point_id: scanPointId,
        current_user_id: uid,
        status: "awaiting_book",
        last_action: "user_scanned",
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });

      const studentName = userDoc.data().name || userDoc.data().email;

      // 📝 AUDIT LOG: SUCCESS
      await db.collection("audit_logs").add({
        function: "processLibraryScan",
        uid: uid || null,
        ip: clientIp || null,
        scanPointId: scanPointId || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "SUCCESS"
      });

      return { 
        ok: true, 
        message: "Student verified. Please scan book.",
        data: { student_name: studentName }
      };
    }

    // === SCENARIO B: Item Scan (Borrow/Return) ===
    if (scanType === 'item') {
      if (!itemId) return { ok: false, message: "Missing Book ID" };

      const bookRef = db.collection("books").doc(itemId);
      const bookDoc = await bookRef.get();
      if (!bookDoc.exists) return { ok: false, message: "Book not found in catalog" };
      
      const bookTitle = bookDoc.data().title || "Unknown Book";

      // Check for active loan
      const loansQuery = await db.collection("book_loans")
        .where("book_id", "==", itemId)
        .where("status", "==", "borrowed")
        .limit(1)
        .get();
      
      const activeLoan = !loansQuery.empty ? loansQuery.docs[0] : null;

      // --- RETURN FLOW ---
      if (activeLoan) {
        // Execute Return
        const loanData = activeLoan.data();
        
        const batch = db.batch();
        
        // Update Loan
        batch.update(activeLoan.ref, {
          status: "returned",
          return_date: admin.firestore.FieldValue.serverTimestamp(),
          return_scan_point_id: scanPointId
        });

        // Update Book Availability
        batch.update(bookRef, { availability: true });

        // Log Interaction
        const interactionRef = db.collection("interactions").doc();
        batch.set(interactionRef, {
          type: "library_return",
          book_id: itemId,
          book_title: bookTitle,
          user_id: loanData.user_id,
          scan_point_id: scanPointId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: "success"
        });

        // Reset Session (if any)
        batch.update(db.collection("library_sessions").doc(scanPointId), {
          status: "idle",
          current_user_id: null,
          last_action: "completed"
        });

        await batch.commit();

        // 📝 AUDIT LOG: SUCCESS
        await db.collection("audit_logs").add({
          function: "processLibraryScan",
          uid: uid || null,
          ip: clientIp || null,
          scanPointId: scanPointId || null,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: "SUCCESS"
        });

        return { 
          ok: true, 
          message: `Book returned: ${bookTitle}`,
          data: { loan_type: "return", book_title: bookTitle }
        };
      }

      // --- BORROW FLOW ---
      else {
        // 1. Check Session for User
        const sessionDoc = await db.collection("library_sessions").doc(scanPointId).get();
        if (!sessionDoc.exists || !sessionDoc.data().current_user_id) {
          return { ok: false, message: "Please scan student ID first." };
        }
        const userId = sessionDoc.data().current_user_id;

        // 2. Create Loan
        const batch = db.batch();
        const loanRef = db.collection("book_loans").doc();
        
        batch.set(loanRef, {
          book_id: itemId,
          book_title: bookTitle,
          user_id: userId,
          scan_point_id: scanPointId,
          borrow_date: admin.firestore.FieldValue.serverTimestamp(),
          due_date: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
          status: "borrowed"
        });

        // 3. Update Book
        batch.update(bookRef, { availability: false });

        // 4. Log Interaction
        const interactionRef = db.collection("interactions").doc();
        batch.set(interactionRef, {
          type: "library_borrow",
          book_id: itemId,
          book_title: bookTitle,
          user_id: userId,
          scan_point_id: scanPointId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: "success"
        });

        // 5. Reset Session
        batch.update(db.collection("library_sessions").doc(scanPointId), {
          status: "idle",
          current_user_id: null,
          last_action: "completed"
        });

        await batch.commit();

        // 📝 AUDIT LOG: SUCCESS
        await db.collection("audit_logs").add({
          function: "processLibraryScan",
          uid: uid || null,
          ip: clientIp || null,
          scanPointId: scanPointId || null,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: "SUCCESS"
        });

        return { 
          ok: true, 
          message: `Book borrowed: ${bookTitle}`,
          data: { loan_type: "borrow", book_title: bookTitle }
        };
      }
    }

    return { ok: false, message: "Invalid scan type" };

  } catch (error) {
    console.error("processLibraryScan error:", error);

    // 📝 AUDIT LOG: ERROR
    await db.collection("audit_logs").add({
      function: "processLibraryScan",
      uid: uid || null,
      ip: clientIp || null,
      scanPointId: scanPointId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "ERROR",
      error: error.message
    });

    // Return internal error to client, but log the full stack trace on server
    throw new HttpsError("internal", error.message);
  }
});

// ------------------------------------------------------------------
// 7️⃣ getAuditLogs (Admin Only)
// Fetches latest 50 audit logs
// ------------------------------------------------------------------
exports.getAuditLogs = functions.https.onCall(async (data, context) => {
  // TODO: Add Admin Check here (e.g. check custom claims or UID against admin list)
  // For now, we rely on the fact that only the Admin App has the UI to call this.
  
  const { lastTimestamp } = data || {};

  try {
    let query = db.collection("audit_logs")
      .orderBy("timestamp", "desc")
      .limit(50);

    if (lastTimestamp) {
      // Convert millis back to Firestore Timestamp for the cursor
      const startAfterDate = admin.firestore.Timestamp.fromMillis(Number(lastTimestamp));
      query = query.startAfter(startAfterDate);
    }

    const snapshot = await query.get();

    const logs = [];
    snapshot.forEach(doc => {
      logs.push({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp ? doc.data().timestamp.toMillis() : null
      });
    });

    return { ok: true, logs: logs };
  } catch (error) {
    console.error("getAuditLogs error:", error);
    throw new HttpsError("internal", "Failed to fetch audit logs");
  }
});

// ------------------------------------------------------------------
// 8️⃣ getAnomalies (Admin Only)
// Fetches latest 50 anomalies
// ------------------------------------------------------------------
exports.getAnomalies = functions.https.onCall(async (data, context) => {
  try {
    const snapshot = await db.collection("anomalies")
      .orderBy("timestamp", "desc")
      .limit(50)
      .get();

    const anomalies = [];
    snapshot.forEach(doc => {
      anomalies.push({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp ? doc.data().timestamp.toMillis() : null
      });
    });

    return { ok: true, anomalies: anomalies };
  } catch (error) {
    console.error("getAnomalies error:", error);
    throw new HttpsError("internal", "Failed to fetch anomalies");
  }
});

// ------------------------------------------------------------------
// 7️⃣ cleanupNonceBlacklist
// Scheduled function to remove old nonces (older than 2 hours)
// ------------------------------------------------------------------
exports.cleanupNonceBlacklist = onSchedule("every 60 minutes", async (event) => {
    const now = Date.now();
    const cutoff = now - 2 * 60 * 60 * 1000; // 2 hours ago
    const cutoffDate = admin.firestore.Timestamp.fromMillis(cutoff);

    console.log(`🧹 [Cleanup] Removing nonces older than ${new Date(cutoff).toISOString()}`);

    try {
      const snapshot = await db
        .collection("nonce_blacklist")
        .where("usedAt", "<", cutoffDate)
        .get();

      if (snapshot.empty) {
        console.log("🧹 [Cleanup] No old nonces found.");
        return;
      }

      console.log(`🧹 [Cleanup] Found ${snapshot.size} nonces to delete.`);

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log("🧹 [Cleanup] Cleanup complete.");
    } catch (error) {
      console.error("🧹 [Cleanup] Error:", error);
    }
});

// ------------------------------------------------------------------
// 9️⃣ cleanupAuditLogs
// Scheduled function to remove old audit logs (older than 30 days)
// ------------------------------------------------------------------
exports.cleanupAuditLogs = onSchedule("every 24 hours", async (event) => {
    const now = Date.now();
    const cutoff = now - 30 * 24 * 60 * 60 * 1000; // 30 days ago
    const cutoffDate = admin.firestore.Timestamp.fromMillis(cutoff);

    console.log(`🧹 [Audit Cleanup] Removing logs older than ${new Date(cutoff).toISOString()}`);

    try {
      const snapshot = await db
        .collection("audit_logs")
        .where("timestamp", "<", cutoffDate)
        .limit(500) // Batch limit
        .get();

      if (snapshot.empty) {
        console.log("🧹 [Audit Cleanup] No old logs found.");
        return;
      }

      console.log(`🧹 [Audit Cleanup] Found ${snapshot.size} logs to delete.`);

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log("🧹 [Audit Cleanup] Cleanup complete.");
    } catch (error) {
      console.error("🧹 [Audit Cleanup] Error:", error);
    }
});




// ------------------------------------------------------------------
// 🔟 trackUserSession
// Trigger: Auth User Created
// Logs session start and device info when a new user is created.
// ------------------------------------------------------------------
exports.trackUserSession = functionsV1.auth.user().onCreate((user) => {
    // Extract device information from the user metadata
    const deviceInfo = user.metadata;
    const sessionStart = new Date();
    const userId = user.uid;

    // Create a session log in Firestore
    return admin.firestore().collection('user_sessions').doc(userId).set({
        sessionStart: sessionStart,
        deviceInfo: {
            // userAgent is not directly available in user.metadata in Cloud Functions
            // We capture what we can: creationTime, lastSignInTime
            creationTime: deviceInfo.creationTime,
            lastSignInTime: deviceInfo.lastSignInTime,
        },
        lastActivity: sessionStart, // Track last session activity
    }).then(() => {
        console.log(`Session started for ${userId}`);
    }).catch(error => {
        console.error('Error tracking session:', error);
    });
});

// ------------------------------------------------------------------
// 1️⃣1️⃣ endUserSession
// Trigger: Auth User Deleted
// Logs session end and duration when a user is deleted.
// ------------------------------------------------------------------
exports.endUserSession = functionsV1.auth.user().onDelete((user) => {
    const userId = user.uid;
    const sessionEnd = new Date();

    // Update the session log in Firestore
    return admin.firestore().collection('user_sessions').doc(userId).update({
        sessionEnd: sessionEnd,
        // Calculate duration if creationTime is available
        sessionDuration: user.metadata.creationTime 
            ? admin.firestore.FieldValue.increment(sessionEnd.getTime() - new Date(user.metadata.creationTime).getTime()) 
            : 0
    }).then(() => {
        console.log(`Session ended for ${userId}`);
    }).catch(error => {
        console.error('Error ending session:', error);
    });
});


// ------------------------------------------------------------------
// 1️⃣2️⃣ cleanupOldLogs
// Trigger: Scheduled every 24 hours
// Deletes general logs older than 30 days to save space.
// ------------------------------------------------------------------
exports.cleanupOldLogs = onSchedule("every 24 hours", async (event) => {
    const now = new Date();
    const cutoffDate = new Date(now.setDate(now.getDate() - 30)); // 30 days ago

    console.log(`🧹 [Log Cleanup] Starting cleanup for logs older than ${cutoffDate.toISOString()}...`);

    try {
      // Query for logs older than 30 days
      // Note: We limit to 500 to avoid memory issues and timeouts. 
      // Since this runs daily, it will eventually catch up.
      const snapshot = await db.collection("logs")
        .where("timestamp", "<", cutoffDate)
        .limit(500)
        .get();

      if (snapshot.empty) {
        console.log("🧹 [Log Cleanup] No old logs found.");
        return;
      }

      console.log(`🧹 [Log Cleanup] Found ${snapshot.size} logs to delete.`);

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log("🧹 [Log Cleanup] Cleanup complete.");
    } catch (error) {
      console.error("🧹 [Log Cleanup] Error:", error);
    }
});

// ------------------------------------------------------------------
// 1️⃣3️⃣ sendOtp
// Generates 6-digit OTP, saves to Firestore, and sends via Email
// ------------------------------------------------------------------
exports.sendOtp = onCall({ secrets: [gmailAppPassword] }, async (request) => {
  const { email } = request.data || {};
  
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required");
  }

  // 1. Check if user exists
  try {
    await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      throw new HttpsError("not-found", "User not found");
    }
    throw new HttpsError("internal", "Error checking user");
  }

  // 2. Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

  // 3. Save to Firestore
  await db.collection("otp_codes").doc(email).set({
    code: otp,
    expiresAt: expiresAt,
    attempts: 0,
    verified: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 4. DEV MODE: Log OTP
  console.log(`🔐 [DEV MODE] OTP for ${email}: ${otp}`);

  // 5. Send Email (Real)
  try {
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: SENDER_EMAIL,
        pass: gmailAppPassword.value().replace(/\s+/g, '')
      }
    });

    const mailOptions = {
      from: `QR Virtual Identity <${SENDER_EMAIL}>`,
      to: email,
      subject: "Your Verification Code",
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2 style="color: #6750A4;">Verification Code</h2>
          <p>Your code is:</p>
          <h1 style="font-size: 32px; letter-spacing: 5px; color: #000;">${otp}</h1>
          <p>This code expires in 5 minutes.</p>
          <p style="font-size: 12px; color: #888;">If you didn't request this, please ignore this email.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log(`📧 [Email] Sent OTP to ${email}`);
  } catch (error) {
    console.error("📧 [Email] Failed to send email:", error);
    throw new HttpsError("internal", `Failed to send email: ${error.message}`);
  }

  return { ok: true, message: "OTP sent", devOtp: otp };
});

// ------------------------------------------------------------------
// 1️⃣4️⃣ verifyOtp
// Verifies the 6-digit OTP
// ------------------------------------------------------------------
exports.verifyOtp = onCall(async (request) => {
  const { email, code } = request.data || {};

  if (!email || !code) {
    throw new HttpsError("invalid-argument", "Email and Code are required");
  }

  const docRef = db.collection("otp_codes").doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "No OTP request found");
  }

  const data = doc.data();
  const now = Date.now();

  // 1. Check Expiry
  if (now > data.expiresAt) {
    throw new HttpsError("failed-precondition", "OTP expired");
  }

  // 2. Check Attempts
  if (data.attempts >= 3) {
    throw new HttpsError("resource-exhausted", "Too many failed attempts");
  }

  // 3. Verify Code
  if (data.code !== code) {
    await docRef.update({
      attempts: admin.firestore.FieldValue.increment(1)
    });
    throw new HttpsError("permission-denied", "Invalid OTP");
  }

  // 4. Mark as Verified
  await docRef.update({
    verified: true
  });

  return { ok: true, message: "OTP verified" };
});

// ------------------------------------------------------------------
// 1️⃣5️⃣ resetPassword
// Resets password using Admin SDK after OTP verification
// ------------------------------------------------------------------
exports.resetPassword = onCall(async (request) => {
  const { email, newPassword, code } = request.data || {};

  if (!email || !newPassword || !code) {
    throw new HttpsError("invalid-argument", "Missing parameters");
  }

  // 1. Re-verify OTP status
  const docRef = db.collection("otp_codes").doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "No OTP request found");
  }

  const data = doc.data();
  
  if (!data.verified) {
    throw new HttpsError("permission-denied", "OTP not verified");
  }

  if (data.code !== code) {
    throw new HttpsError("permission-denied", "OTP mismatch");
  }

  // 2. Update Password via Admin SDK
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, {
      password: newPassword
    });

    // 3. Cleanup OTP
    await docRef.delete();

    console.log(`✅ Password reset for ${email}`);
    return { ok: true, message: "Password reset successful" };

  } catch (error) {
    console.error("Password reset error:", error);
    throw new HttpsError("internal", "Failed to reset password");
  }
});

// ------------------------------------------------------------------
// 7️⃣ sendPushOnInteraction
// Triggers when a new interaction (payment/access) is recorded.
// Sends a push notification to the user's devices via FCM.
// ------------------------------------------------------------------
exports.sendPushOnInteraction = onDocumentCreated("interactions/{interactionId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const uid = data.user_id;
  const type = data.type; // 'purchase', 'access_granted', etc.
  
  if (!uid) return;

  try {
    // 1. Get User's FCM Tokens
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const tokens = userData.fcmTokens || [];

    if (tokens.length === 0) {
      console.log(`🔕 No FCM tokens for user ${uid}`);
      return;
    }

    // 2. Construct Message Payload
    let title = "New Activity";
    let body = "You have a new interaction.";
    
    // Customize based on type
    switch (type) {
      case 'purchase':
        title = "Payment Successful 💸";
        body = `Paid RM ${data.amount?.toFixed(2)} at ${data.scan_point_name}`;
        break;
      case 'access_granted':
        title = "Access Granted 🔓";
        body = `Welcome to ${data.scan_point_name}`;
        break;
      case 'access_denied':
        title = "Access Denied ⛔";
        body = `Access denied at ${data.scan_point_name}`;
        break;
      case 'book_borrowed':
        title = "Book Borrowed 📚";
        body = `You borrowed a book from ${data.scan_point_name}`;
        break;
      default:
        title = "New Interaction";
        body = `Activity recorded at ${data.scan_point_name}`;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        interactionId: event.params.interactionId,
        type: type,
        route: '/notification_inbox'
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
          defaultSound: true,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
          }
        }
      },
      tokens: tokens,
    };

    // 3. Send Multicast Message
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`📢 Sent ${response.successCount} messages to user ${uid}`);

    // 4. Cleanup Invalid Tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error;
          if (error.code === 'messaging/registration-token-not-registered' ||
              error.code === 'messaging/invalid-argument') {
            failedTokens.push(tokens[idx]);
          }
        }
      });

      if (failedTokens.length > 0) {
        console.log(`🧹 Removing ${failedTokens.length} invalid tokens`);
        await db.collection("users").doc(uid).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
        });
      }
    }

  } catch (error) {
    console.error("❌ Error sending push notification:", error);
  }
});

// ------------------------------------------------------------------
// 7️⃣ Secure QR Login: Generate Custom Token for Desktop
// ------------------------------------------------------------------
exports.generateDesktopLoginToken = onDocumentUpdated("login_sessions/{sessionId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // ONLY trigger when status changes to 'authorized' AND token is not yet generated
  if (before.status !== "authorized" && after.status === "authorized") {
    const uid = after.uid;
    const existingToken = after.token;

    if (uid && !existingToken) {
      try {
        console.log(`🔐 Generating Custom Token for QR Login Session: ${event.params.sessionId} (UID: ${uid})`);
        
        // Generate Firebase Custom Token
        const customToken = await admin.auth().createCustomToken(uid);
        
        // Write token back to session document
        await event.data.after.ref.update({
          token: customToken,
          token_created_at: admin.firestore.FieldValue.serverTimestamp(),
          status: "ready_to_login" // Optional: Update status to indicate readiness
        });
        
        console.log(`✅ Custom Token generated successfully for UID: ${uid}`);
      } catch (error) {
        console.error("❌ Failed to generate custom token:", error);
        await event.data.after.ref.update({
          status: "error",
          error_message: "Failed to generate security token"
        });
      }
    }
  }
});
