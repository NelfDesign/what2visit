const functions = require("firebase-functions");
// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

const Stripe = require('stripe')(functions.config().stripe.testkey);
const { user } = require('firebase-functions/lib/providers/auth');
//const stripe = Stripe('sk_test_51J5BGiGmvQOSGWTDRd3ncRN5ppcAqXzOhUY5YADwAR00SiBlpeFZa34XT0Cohe5M5am6F99Vha6XPG72Y5KrwPY7001k3Y82Ij');

exports.onLogin = functions.https.onCall(async (data, context)=>{
    let uid = context.auth.uid;
    let user = await admin.firestore().doc("/users/"+uid).get();
    if(user.data().userType == "ADMIN"){
        console.info("SET ADMIN for user: "+user.data().email);
        await admin.auth().setCustomUserClaims(uid, {admin: true, mod: true});
    }
     else{
         console.info("SET NONE for user: "+user.data().email);
         await admin.auth().setCustomUserClaims(uid, {admin: false, mod: false});
     }
     return;
 });

/*
/**
 * When a user is created, create a Stripe customer object for them.
 *
 * @see https://stripe.com/docs/payments/save-and-reuse#web-create-customer
 */
exports.createStripeCustomer = functions.region("europe-west3").auth.user().onCreate(async (user) => {
  const customer = await Stripe.customers.create({ email: user.email });
  const intent = await Stripe.setupIntents.create({
    customer: customer.id,
  });
  await admin.firestore().collection('stripe_customers').doc(user.uid).set({
    customer_id: customer.id,
    setup_secret: intent.client_secret,
  });
  return;
});

/**
 * When adding the payment method ID on the client,
 * this function is triggered to retrieve the payment method details.
 */
exports.addPaymentMethodDetails = functions.region("europe-west3").firestore
  .document('/stripe_customers/{userId}/payment_methods/{pushId}')
  .onCreate(async (snap, context) => {
    try {
      const paymentMethodId = snap.data().id;
      const paymentMethod = await Stripe.paymentMethods.retrieve(
        paymentMethodId
      );
      await snap.ref.set(paymentMethod);
      // Create a new SetupIntent so the customer can add a new method next time.
      const intent = await Stripe.setupIntents.create({
        customer: paymentMethod.customer,
      });
      await snap.ref.parent.parent.set(
        { setup_secret: intent.client_secret },
        { merge: true }
      );
      return;
    } catch (error) {
      await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
      console.log(error);
    }
  });

  /**
   * When a payment document is written on the client,
   * this function is triggered to create the payment in Stripe.
   *
   * @see https://stripe.com/docs/payments/save-and-reuse#web-create-payment-intent-off-session
   */

  // [START chargecustomer]

  exports.createStripePayment = functions.region("europe-west3").firestore
    .document('stripe_customers/{userId}/payments/{pushId}')
    .onCreate(async (snap, context) => {
      const { amount, currency, payment_method } = snap.data();
      try {
        // Look up the Stripe customer id.
        const customer = (await snap.ref.parent.parent.get()).data().customer_id;
        // Create a charge using the pushId as the idempotency key
        // to protect against double charges.
        const idempotencyKey = context.params.pushId;
        const payment = await Stripe.paymentIntents.create(
          {
            amount,
            currency,
            customer,
            payment_method,
            off_session: false,
            confirm: true,
            confirmation_method: 'manual',
            return_url: 'https://google.com/'//TODO put url to redirect
          },
          { idempotencyKey }
        );
        // If the result is successful, write it back to the database.
        await snap.ref.set(payment);
      } catch (error) {
        // We want to capture errors and render them in a user-friendly way, while
        // still logging an exception with StackDriver
        console.log(error);
        await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
        await reportError(error, { user: context.params.userId });
      }
    });

  // [END chargecustomer]

  /**
   * When 3D Secure is performed, we need to reconfirm the payment
   * after authentication has been performed.
   *
   * @see https://stripe.com/docs/payments/accept-a-payment-synchronously#web-confirm-payment
   */
  exports.confirmStripePayment = functions.region("europe-west3").firestore
    .document('stripe_customers/{userId}/payments/{pushId}')
    .onUpdate(async (change, context) => {
      if (change.after.data().status === 'requires_confirmation') {
        const payment = await Stripe.paymentIntents.confirm(
          change.after.data().id,
        );
        change.after.ref.set(payment);
      }
    });