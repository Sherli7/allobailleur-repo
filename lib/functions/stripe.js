const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_TON_SECRET_KEY'); // Ta clé secrète
const admin = require('firebase-admin');
admin.initializeApp(); // Init Firestore

// ... ton createPaymentIntent existant

// NOUVEAU: Webhook handler
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature']; // Signature Stripe
  const webhookSecret = 'whsec_TON_SIGNING_SECRET'; // Remplace par ton secret webhook

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret); // Vérifie signature
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Gère événements
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      await handlePaymentSucceeded(paymentIntent);
      break;
    case 'payment_intent.payment_failed':
      const failedIntent = event.data.object;
      await handlePaymentFailed(failedIntent);
      break;
    case 'payment_intent.requires_action': // Pour 3D Secure (rare, car PaymentSheet gère)
      const requiresAction = event.data.object;
      await handleRequiresAction(requiresAction);
      break;
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});

// Helper: Succès paiement → Update booking status dans Firestore
async function handlePaymentSucceeded(paymentIntent) {
  const propertyId = paymentIntent.metadata.propertyId;
  const userId = paymentIntent.metadata.userId; // Assume passé dans metadata lors creation

  // Update booking dans collection 'bookings'
  await admin.firestore().collection('bookings').doc(propertyId + '_' + userId).update({
    status: 'confirmed',
    paymentIntentId: paymentIntent.id,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notif au proprio (via FCM ou email)
  console.log('Booking confirmé pour property:', propertyId);
}

// Helper: Échec paiement
async function handlePaymentFailed(paymentIntent) {
  const propertyId = paymentIntent.metadata.propertyId;
  const userId = paymentIntent.metadata.userId;

  await admin.firestore().collection('bookings').doc(propertyId + '_' + userId).update({
    status: 'failed',
    error: paymentIntent.lastPaymentError?.message,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('Booking échoué pour property:', propertyId);
}

// Helper: Action requise (3D Secure)
async function handleRequiresAction(paymentIntent) {
  // Rare : Renvoie client_secret pour retry dans app
  console.log('3D Secure required for:', paymentIntent.id);
  // Option : Push FCM à user pour retry
}