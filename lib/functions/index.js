const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_TON_SECRET_KEY'); // Ta clé secrète
const admin = require('firebase-admin');
admin.initializeApp();

// ... tes fonctions existantes (createPaymentIntent, stripeWebhook)

// NOUVEAU: Endpoint pour créer un refund (callable depuis Flutter)
exports.requestRefund = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { paymentIntentId, amount, reason = 'requested_by_customer' } = data; // Amount en centimes, ou null pour total
  const userId = context.auth.uid; // Proprio

  try {
    // Vérif que user est proprio du booking
    const bookingDoc = await admin.firestore().collection('bookings').doc(paymentIntentId).get();
    if (!bookingDoc.exists || bookingDoc.data().ownerId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'Non autorisé');
    }

    const refundParams = {
      payment_intent: paymentIntentId,
      reason: reason, // 'requested_by_customer', 'duplicate', etc.
    };
    if (amount) refundParams.amount = amount; // Partiel

    const refund = await stripe.refunds.create(refundParams);

    // Update booking status
    await admin.firestore().collection('bookings').doc(paymentIntentId).update({
      refundId: refund.id,
      status: 'refunded',
      refundAmount: refund.amount / 100, // En € pour UI
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { refundId: refund.id, status: 'succeeded' };
  } catch (error) {
    console.error('Refund error:', error);
    throw new functions.https.HttpsError('internal', `Erreur refund: ${error.message}`);
  }
});

// UPDATE: Extension webhook pour refunds (ajoute case dans stripeWebhook existant)
switch (event.type) {
  // ... tes cases existantes (succeeded, failed)
  case 'charge.refunded':
    const refundEvent = event.data.object;
    await handleRefundEvent(refundEvent);
    break;
}

// Helper: Gère événement refund
async function handleRefundEvent(refund) {
  const paymentIntentId = refund.payment_intent;
  const bookingDoc = await admin.firestore().collection('bookings').doc(paymentIntentId).get();
  if (bookingDoc.exists) {
    await bookingDoc.ref.update({
      refundStatus: 'completed',
      refundAmount: refund.amount / 100,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Notif FCM à user et proprio
    console.log('Refund complété pour booking:', paymentIntentId);
  }
}