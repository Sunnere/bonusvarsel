// lib/monitor.js (ESM)
// Enkel overvåking: sjekker at kampanje-pipelinen leverer, og sender
// Telegram-alarm hvis totalen er 0 eller SAS-kilden (LoyaltyKey) er tom.
// Cooldown per problemtype så alarmer ikke spammer, og friskmelding når OK igjen.

const ALERT_COOLDOWN_MS = Number(process.env.MONITOR_ALERT_COOLDOWN_MS || 6 * 60 * 60 * 1000); // 6 timer

let deps = { fetchAllCampaigns: null, sendTelegram: null };

const monState = {
  lastCheckAt: null,
  lastResult: null,          // { total, trumf, sas, elite }
  issues: {},                // { [issueKey]: { since, lastAlertAt } }
  checksRun: 0,
  alertsSent: 0,
};

export function initMonitor(dependencies) {
  deps = dependencies;
}

function nowIso() {
  return new Date().toISOString();
}

async function maybeAlert(issueKey, message) {
  const now = Date.now();
  const existing = monState.issues[issueKey];

  if (!existing) {
    monState.issues[issueKey] = { since: nowIso(), lastAlertAt: now };
    monState.alertsSent += 1;
    await deps.sendTelegram(`🚨 <b>Bonusvarsel-overvåking</b>\n${message}`);
    return;
  }

  if (now - existing.lastAlertAt >= ALERT_COOLDOWN_MS) {
    existing.lastAlertAt = now;
    monState.alertsSent += 1;
    await deps.sendTelegram(`🚨 <b>Bonusvarsel-overvåking</b> (fortsatt)\n${message}\n<i>Problem siden ${existing.since}</i>`);
  }
}

async function maybeResolve(issueKey, message) {
  const existing = monState.issues[issueKey];
  if (!existing) return;
  delete monState.issues[issueKey];
  await deps.sendTelegram(`🟢 <b>Bonusvarsel-overvåking</b>\n${message}\n<i>Var nede siden ${existing.since}</i>`);
}

export async function runMonitorCheck() {
  monState.checksRun += 1;
  monState.lastCheckAt = nowIso();

  let campaigns = [];
  let fetchError = null;
  try {
    campaigns = await deps.fetchAllCampaigns('elite');
    if (!Array.isArray(campaigns)) campaigns = [];
  } catch (e) {
    fetchError = String(e);
    campaigns = [];
  }

  const total = campaigns.length;
  const trumf = campaigns.filter((c) => c.source === 'trumf').length;
  const sas = campaigns.filter((c) => c.source === 'sas').length;
  const elite = campaigns.filter((c) => c.source === 'elite').length;
  monState.lastResult = { total, trumf, sas, elite, fetchError };

  // Problem 1: hele pipelinen tom (eller kastet feil)
  if (total === 0) {
    await maybeAlert(
      'total-empty',
      `/api/campaigns er TOM (0 kampanjer).${fetchError ? `\nFeil: ${fetchError}` : ''}\nSjekk Railway-loggen.`,
    );
  } else {
    await maybeResolve('total-empty', `Kampanjer tilbake: ${total} totalt (Trumf ${trumf} / SAS ${sas} / Elite ${elite}).`);

    // Problem 2: SAS-kilden (LoyaltyKey) tom – feiler stille i dag
    if (sas === 0) {
      await maybeAlert(
        'sas-empty',
        `SAS/LoyaltyKey leverer 0 kampanjer (Trumf ${trumf} / Elite ${elite} er OK).\nLoyaltyKey-API-et er trolig nede eller har endret format.`,
      );
    } else {
      await maybeResolve('sas-empty', `SAS/LoyaltyKey leverer igjen: ${sas} kampanjer.`);
    }
  }

  return { ...monState.lastResult, activeIssues: Object.keys(monState.issues) };
}

export function startMonitor(intervalMs) {
  runMonitorCheck().catch((e) => console.error('[monitor] første sjekk feilet:', e));
  setInterval(() => {
    runMonitorCheck().catch((e) => console.error('[monitor] sjekk feilet:', e));
  }, intervalMs);
  console.log(`[monitor] Overvåking startet (hver ${Math.round(intervalMs / 60000)} min, cooldown ${Math.round(ALERT_COOLDOWN_MS / 3600000)} t)`);
}

export function monitorStatus() {
  return {
    lastCheckAt: monState.lastCheckAt,
    lastResult: monState.lastResult,
    activeIssues: Object.entries(monState.issues).map(([key, v]) => ({ issue: key, since: v.since })),
    checksRun: monState.checksRun,
    alertsSent: monState.alertsSent,
  };
}
