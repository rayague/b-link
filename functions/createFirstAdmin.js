/**
 * Script Firebase Cloud Function pour créer le premier admin
 * À exécuter UNE SEULE FOIS pour initialiser le système
 * 
 * Commande: firebase deploy --only functions:createFirstAdmin
 * Puis appeler via HTTP ou console
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialiser Firebase Admin si pas déjà fait
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.createFirstAdmin = functions.https.onRequest(async (req, res) => {
  try {
    // CREDENTIALS DU PREMIER ADMIN
    const ADMIN_EMAIL = 'rayague03@gmail.com';
    const ADMIN_PASSWORD = 'Admin@BLink2025!'; // ⚠️ CHANGEZ CE MOT DE PASSE!

    // 1. Créer le compte Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        emailVerified: true,
      });
    } catch (error) {
      // Si l'utilisateur existe déjà, le récupérer
      if (error.code === 'auth/email-already-exists') {
        userRecord = await admin.auth().getUserByEmail(ADMIN_EMAIL);
      } else {
        throw error;
      }
    }

    // 2. Créer l'entrée admin dans Firestore
    await admin.firestore().collection('admins').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: ADMIN_EMAIL,
      role: 'super_admin',
      createdAt: new Date().toISOString(),
      lastLogin: null,
    });

    console.log('✅ Admin créé avec succès:', ADMIN_EMAIL);

    res.status(200).json({
      success: true,
      message: 'Admin créé avec succès',
      admin: {
        uid: userRecord.uid,
        email: ADMIN_EMAIL,
        role: 'super_admin',
      },
      credentials: {
        email: ADMIN_EMAIL,
        password: '*** (voir le code source)',
      },
    });
  } catch (error) {
    console.error('❌ Erreur création admin:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
