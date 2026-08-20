import { getAuth } from 'firebase-admin/auth';
import * as entitlementStore from './entitlementStore.js';

export async function handleGetMe(req, res) {
  const authHeader = req.headers['authorization'] || '';
  const match = authHeader.match(/^Bearer (.+)$/);

  if (!match) {
    return res.json({ ok: true, tier: 'free', source: null, loggedIn: false });
  }

  try {
    const decoded = await getAuth().verifyIdToken(match[1]);
    const email = decoded.email;
    if (!email) {
      return res.json({ ok: true, tier: 'free', source: null, loggedIn: true, email: null });
    }
    const entitlement = await entitlementStore.getEntitlement(email);
    return res.json({
      ok: true, loggedIn: true, email,
      tier: entitlement.tier || 'free',
      source: entitlement.source || null,
      status: entitlement.status || null,
    });
  } catch (err) {
    console.error('[meHandler] Token-verifisering feilet:', err.message);
    return res.status(401).json({ ok: false, error: 'Ugyldig eller utløpt token' });
  }
}
