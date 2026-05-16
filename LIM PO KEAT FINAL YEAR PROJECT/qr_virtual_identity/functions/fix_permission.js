const admin = require('firebase-admin');

// Attempt to initialize.
// We assume the environment is set up for Firebase Admin (e.g. via firebase login or GOOGLE_APPLICATION_CREDENTIALS)
try {
  admin.initializeApp();
} catch (e) {
  // If default app already exists or other issue
  if (admin.apps.length === 0) {
      console.error("Init error:", e);
  }
}

const db = admin.firestore();

async function fix() {
  const uid = 'c9pxF1KhaOSoOeobyEbklTbT7a93';
  const targetSp = 'SP006';
  
  console.log(`Reading user ${uid}...`);
  
  const ref = db.collection('users').doc(uid);
  const doc = await ref.get();
  
  if (!doc.exists) {
    console.error('User doc not found!');
    return;
  }
  
  const data = doc.data();
  const perms = data.access_permissions || [];
  
  console.log('Current permissions:', perms);

  if (perms.includes(targetSp)) {
    console.log('User already has permission.');
  } else {
    perms.push(targetSp);
    await ref.update({ access_permissions: perms });
    console.log(`Permission ${targetSp} added!`);
    console.log('New permissions:', perms);
  }
}

fix().then(() => {
    console.log("Done.");
    process.exit(0);
}).catch(e => { 
    console.error("Error:", e); 
    process.exit(1); 
});
