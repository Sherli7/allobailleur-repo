const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret);

admin.initializeApp();

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Vérifier l'authentification
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  const { amount, currency = 'eur', bookingId, hostId } = data;

  try {
    // Calculer la commission (3%)
    const platformFee = Math.round(amount * 0.03); // En centimes
    const hostAmount = amount - platformFee;

    // Créer le PaymentIntent avec application_fee_amount pour la commission
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      application_fee_amount: platformFee,
      transfer_data: {
        destination: hostId, // ID Stripe Connect du compte hôte
      },
      metadata: {
        bookingId: bookingId,
      },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

exports.createSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  const { customerId, plan } = data;

  try {
    const prices = {
      'monthly': 'price_monthly_id', // Remplacer par les vrais IDs de produits Stripe
      'semesterly': 'price_semesterly_id',
    };

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [
        {
          price: prices[plan],
        },
      ],
      payment_behavior: 'default_incomplete',
      expand: ['latest_invoice.payment_intent'],
    });

    return {
      subscriptionId: subscription.id,
      clientSecret: subscription.latest_invoice.payment_intent.client_secret,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});