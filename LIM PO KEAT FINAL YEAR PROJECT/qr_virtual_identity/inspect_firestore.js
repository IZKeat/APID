// inspect_firestore.js - READ-ONLY Firestore structure inspector
// Run with: node inspect_firestore.js

const http = require("http");

const FIRESTORE_EMULATOR_HOST = "127.0.0.1";
const FIRESTORE_EMULATOR_PORT = 8080;
const PROJECT_ID = "po-keat-fyp";

// Expected collections based on codebase analysis
const expectedCollections = [
  "admins",
  "users",
  "scan_points",
  "interactions",
  "logs",
  "events",
  "user_tickets",
  "guest_users",
  "guest_tickets",
  "books",
  "book_loans",
  "library_sessions",
  "ticket_scans",
  "scanner_triggers",
  "scanner_status",
];

console.log("🔍 FIRESTORE STRUCTURE INSPECTOR (READ-ONLY MODE)");
console.log("═══════════════════════════════════════════════════════════════");
console.log(
  `📡 Connecting to Firestore Emulator at ${FIRESTORE_EMULATOR_HOST}:${FIRESTORE_EMULATOR_PORT}`
);
console.log(`📋 Project ID: ${PROJECT_ID}\n`);

async function httpGet(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: FIRESTORE_EMULATOR_HOST,
      port: FIRESTORE_EMULATOR_PORT,
      path: path,
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    };

    const req = http.request(options, (res) => {
      let data = "";

      res.on("data", (chunk) => {
        data += chunk;
      });

      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed);
        } catch (e) {
          resolve({ error: "Failed to parse response", data });
        }
      });
    });

    req.on("error", (error) => {
      reject(error);
    });

    req.end();
  });
}

function inferSchema(data) {
  const schema = {};

  for (const [key, value] of Object.entries(data)) {
    if (value === null) {
      schema[key] = "null";
    } else if (typeof value === "string") {
      schema[key] = "string";
    } else if (typeof value === "number") {
      schema[key] = Number.isInteger(value) ? "integer" : "double";
    } else if (typeof value === "boolean") {
      schema[key] = "boolean";
    } else if (Array.isArray(value)) {
      if (value.length === 0) {
        schema[key] = "array (empty)";
      } else {
        const firstItemType = typeof value[0];
        schema[key] = `array<${firstItemType}>`;
      }
    } else if (typeof value === "object") {
      if (value._seconds !== undefined) {
        schema[key] = "Timestamp";
      } else {
        schema[key] = "map";
      }
    } else {
      schema[key] = typeof value;
    }
  }

  return schema;
}

function checkFieldConsistency(documents) {
  const allFields = new Set();
  const fieldCounts = {};

  for (const doc of documents) {
    for (const key of Object.keys(doc)) {
      allFields.add(key);
      fieldCounts[key] = (fieldCounts[key] || 0) + 1;
    }
  }

  const inconsistentFields = [];
  for (const field of allFields) {
    if (fieldCounts[field] < documents.length) {
      inconsistentFields.push(
        `${field} (${fieldCounts[field]}/${documents.length} docs)`
      );
    }
  }

  return inconsistentFields;
}

async function analyzeCollection(collectionName) {
  try {
    const path = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collectionName}`;
    const response = await httpGet(path);

    if (response.error || !response.documents) {
      return {
        name: collectionName,
        empty: true,
        error: response.error,
      };
    }

    const documents = response.documents.map((doc) => {
      const data = {};
      if (doc.fields) {
        for (const [key, value] of Object.entries(doc.fields)) {
          // Extract the actual value based on Firestore type
          if (value.stringValue !== undefined) data[key] = value.stringValue;
          else if (value.integerValue !== undefined)
            data[key] = parseInt(value.integerValue);
          else if (value.doubleValue !== undefined)
            data[key] = value.doubleValue;
          else if (value.booleanValue !== undefined)
            data[key] = value.booleanValue;
          else if (value.timestampValue !== undefined)
            data[key] = { _seconds: value.timestampValue };
          else if (value.arrayValue !== undefined)
            data[key] = value.arrayValue.values || [];
          else if (value.mapValue !== undefined)
            data[key] = value.mapValue.fields || {};
          else if (value.nullValue !== undefined) data[key] = null;
          else data[key] = value;
        }
      }
      return {
        id: doc.name.split("/").pop(),
        data,
      };
    });

    return {
      name: collectionName,
      empty: false,
      count: documents.length,
      sampleIds: documents.slice(0, 5).map((d) => d.id),
      schema: documents.length > 0 ? inferSchema(documents[0].data) : {},
      inconsistentFields:
        documents.length > 1
          ? checkFieldConsistency(documents.map((d) => d.data))
          : [],
    };
  } catch (error) {
    return {
      name: collectionName,
      error: error.message,
    };
  }
}

async function main() {
  console.log("📋 ROOT COLLECTION LIST");
  console.log(
    "═══════════════════════════════════════════════════════════════\n"
  );

  const results = [];

  for (const collectionName of expectedCollections) {
    const result = await analyzeCollection(collectionName);
    results.push(result);

    if (result.error) {
      console.log(`❌ ${collectionName} (error: ${result.error})`);
    } else if (result.empty) {
      console.log(`⚪ ${collectionName} (empty)`);
    } else {
      console.log(`✅ ${collectionName} (${result.count} documents)`);
    }
  }

  console.log("\n");
  console.log(
    "═══════════════════════════════════════════════════════════════"
  );
  console.log("📊 DETAILED COLLECTION ANALYSIS");
  console.log(
    "═══════════════════════════════════════════════════════════════\n"
  );

  for (const result of results) {
    if (result.empty || result.error) continue;

    console.log(
      "─────────────────────────────────────────────────────────────────"
    );
    console.log(`Collection: ${result.name}`);
    console.log(
      "─────────────────────────────────────────────────────────────────"
    );
    console.log(`Sample Document IDs: ${result.sampleIds.join(", ")}`);
    console.log(`Documents Sampled: ${result.count}`);
    console.log("\nInferred Schema (from first document):");
    console.log(JSON.stringify(result.schema, null, 2));

    console.log("\nField Consistency Check:");
    if (result.inconsistentFields.length === 0) {
      console.log("✅ All fields consistent across sampled documents");
    } else {
      console.log("⚠️  Inconsistent fields detected:");
      for (const field of result.inconsistentFields) {
        console.log(`   - ${field}`);
      }
    }
    console.log("");
  }

  console.log(
    "═══════════════════════════════════════════════════════════════"
  );
  console.log("📈 FIRESTORE DATABASE SUMMARY");
  console.log(
    "═══════════════════════════════════════════════════════════════\n"
  );

  const populated = results.filter((r) => !r.empty && !r.error);
  const empty = results.filter((r) => r.empty);
  const errors = results.filter((r) => r.error);

  console.log(`Total Collections Checked: ${expectedCollections.length}`);
  console.log(`Collections with Data: ${populated.length}`);
  console.log(`Empty Collections: ${empty.length}`);
  console.log(`Errors: ${errors.length}`);

  if (empty.length > 0) {
    console.log("\n⚠️  Empty Collections:");
    for (const result of empty) {
      console.log(`   - ${result.name}`);
    }
  }

  if (errors.length > 0) {
    console.log("\n❌ Collections with Errors:");
    for (const result of errors) {
      console.log(`   - ${result.name}: ${result.error}`);
    }
  }

  // Summary analysis
  console.log("\n🔍 DESIGN ANALYSIS:");
  console.log(
    "─────────────────────────────────────────────────────────────────"
  );

  if (populated.some((r) => r.name === "scan_points")) {
    console.log(
      '✅ Using modern "scan_points" collection (replaces "merchants")'
    );
  }

  if (populated.some((r) => r.name === "interactions")) {
    console.log(
      '✅ Using modern "interactions" collection (replaces "transactions")'
    );
  }

  if (
    populated.some((r) => r.name === "guest_users") &&
    populated.some((r) => r.name === "guest_tickets")
  ) {
    console.log("✅ Guest event ticket system implemented");
  }

  if (
    populated.some((r) => r.name === "books") &&
    populated.some((r) => r.name === "book_loans")
  ) {
    console.log("✅ Library management system with books and loans");
  }

  if (
    populated.some((r) => r.name === "scanner_triggers") &&
    populated.some((r) => r.name === "scanner_status")
  ) {
    console.log("✅ Cross-device scanner synchronization system present");
  }

  console.log("\n✅ Inspection complete!\n");
}

main().catch(console.error);
