const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const stripe = require('stripe')(functions.config().stripe.secret);

admin.initializeApp();

// Supabase client using service_role key (set via `firebase functions:config:set supabase.url="..." supabase.service_role="..."`)
const SUPABASE_URL = functions.config().supabase?.url || process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = functions.config().supabase?.service_role || process.env.SUPABASE_SERVICE_ROLE_KEY;
let supabase = null;
if (SUPABASE_URL && SUPABASE_SERVICE_KEY) {
  supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
} else {
  console.warn('Supabase service role key or URL not configured for functions.');
}

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

// Create Supabase profile using the service_role key. Callable from client after Firebase signup.
exports.createSupabaseProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  if (!supabase) {
    throw new functions.https.HttpsError('failed-precondition', 'Supabase not configured on server');
  }

  const uid = context.auth.uid;
  const email = data.email || context.auth.token.email || '';
  const firstName = data.firstName || '';
  const lastName = data.lastName || '';
  const city = data.city || null;
  const country = data.country || null;
  const bio = data.bio || null;
  const role = data.role || 'tenant';

  try {
    const userRow = {
      uid,
      email,
      firstName,
      lastName,
      role,
      city,
      country,
      bio,
      createdAt: new Date().toISOString(),
    };

    const { data: insertData, error } = await supabase
      .from('users')
      .insert(userRow)
      .select();

    if (error) {
      console.error('Supabase insert error', error);
      throw new functions.https.HttpsError('internal', 'Supabase insert failed: ' + error.message);
    }

    return { success: true, inserted: insertData };
  } catch (err) {
    console.error('createSupabaseProfile error', err);
    throw new functions.https.HttpsError('internal', err.message || 'Unknown error');
  }
});