// Import and configure the Firebase SDK
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyBYg4EXSH_8uKrvrG_Vfh_7dbHTFsh8oG8',
  appId: '1:40543426548:web:93896f5b4d7618ea848ba1',
  messagingSenderId: '40543426548',
  projectId: 'allobailleur-c7e9d',
  authDomain: 'allobailleur-c7e9d.firebaseapp.com',
  storageBucket: 'allobailleur-c7e9d.firebasestorage.app',
  measurementId: 'G-VHJ3N3ZJY3'
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'Background Message Title';
  const notificationOptions = {
    body: payload.notification?.body || 'Background Message body.',
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});