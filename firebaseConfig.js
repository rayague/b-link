// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDAWMiZq75sM5Qx-iDfbd54X4faM1xOma0",
  authDomain: "b-link-3b2d5.firebaseapp.com",
  projectId: "b-link-3b2d5",
  storageBucket: "b-link-3b2d5.firebasestorage.app",
  messagingSenderId: "1086266729781",
  appId: "1:1086266729781:web:cac79a6d43b106d35b187c",
  measurementId: "G-GJL437S33G"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);