import Stripe from 'stripe';
import * as entitlementStore from './entitlementStore.js';

let stripe = null;

function getStripe() {
  if (!stripe) {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) throw new Error('STRIPE_SECRET_KEY mangler i miljøvariabler');
    stripe = new Stripe(key);
  }
  return stripe;
}

function mapProductNameToTier(productName) {
  const name = (productName || '').toLowerCase();
  if (name.includes('elite')) return 'elite';
  if (name.includes('premium')) return 'premium';
  return 'free';
}

async function syncSubscription(subscription) {
  const s = getStripe();
  const customer = await s.customers.retrieve(subscription.customer);
  const email = customer?.email;
  if (!email) {
    console.warn(`[stripeWebhook] Ingen e-post funnet for kunde ${subscription.customer}, hopper over`);
    return null;
  }

  const isActive = ['active', 'trialing'].includes(subscription.status);

  if (!isActive) {
    await entitlementStore.setEntitlement(email, {
      tier: 'free', source: 'stripe',
      stripeCustomerId: subscription.customer,
      stripeSubscriptionId: subscription.id,
      status: subscription.status,
    });
    console.log(`[stripeWebhook] ${email}: abonnement ${subscription.status} -> free`);
    return { email, tier: 'free' };
  }

  const priceId = subscription.items?.data?.[0]?.price?.id;
  const productId = subscription.items?.data?.[0]?.price?.product;
  let productName = '';
  if (productId) {
    const product = await s.products.retrieve(productId);
    productName = product.name || '';
  }

  const tier = mapProductNameToTier(productName);

  await entitlementStore.setEntitlement(email, {
    tier, source: 'stripe',
    stripeCustomerId: subscription.customer,
    stripeSubscriptionId: subscription.id,
    stripePriceId: priceId,
    status: subscription.status,
  });

  console.log(`[stripeWebhook] ${email}: ${productName} (${subscription.status}) -> ${tier}`);
  return { email, tier };
}

export async function handleStripeWebhook(req, res) {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!webhookSecret) {
    console.error('[stripeWebhook] STRIPE_WEBHOOK_SECRET mangler');
    return res.status(500).json({ error: 'Webhook not configured' });
  }

  let event;
  try {
    event = getStripe().webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('[stripeWebhook] Signaturverifisering feilet:', err.message);
    return res.status(400).json({ error: `Webhook signature verification failed: ${err.message}` });
  }

  try {
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        const result = await syncSubscription(event.data.object);
        return res.json({ ok: true, handled: event.type, result });
      }
      default:
        return res.json({ ok: true, handled: false, type: event.type });
    }
  } catch (err) {
    console.error('[stripeWebhook] Feil under behandling:', err.message);
    return res.status(200).json({ ok: false, error: err.message });
  }
}

export { mapProductNameToTier, syncSubscription };
