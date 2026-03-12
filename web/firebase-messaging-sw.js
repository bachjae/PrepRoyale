// Firebase Cloud Messaging Service Worker
// Handles background push notifications when the browser tab is closed.
//
// SETUP: Replace the placeholder values below with your Firebase web app config.
// Get them from: Firebase Console → Project sat-act-battle-royale → Settings → Your apps → Web
//
// Use compat scripts in service workers (importScripts cannot use ES modules).

importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC6UP3Jw0mQaotu9SehVrGOpmKmBbFt0ck",
  authDomain: "sat-act-battle-royale.firebaseapp.com",
  projectId: "sat-act-battle-royale",
  storageBucket: "sat-act-battle-royale.firebasestorage.app",
  messagingSenderId: "722112363962",
  appId: "1:722112363962:web:29ea13456da379ce863183",
  measurementId: "G-4J4PY4QV6D",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log("[firebase-messaging-sw.js] Received background message:", payload);

  const title = payload.notification?.title ?? "Prep Royale";
  const options = {
    body: payload.notification?.body ?? "",
    icon: "/icons/Icon-192.png",
    badge: "/favicon.png",
    data: payload.data,
  };

  self.registration.showNotification(title, options);
});
