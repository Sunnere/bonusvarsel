#!/bin/zsh
set -e
cd /Users/sunnerehelse/bonusvarsel/api

echo "==> Skriver lib/monitor.js..."
mkdir -p lib
cat > lib/monitor.js << 'EOF'
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
EOF

echo "==> Skriver patch-script..."
cat > patch-monitor.mjs << 'EOF'
// patch-monitor.mjs – kobler monitor.js inn i server.js
import fs from 'fs';

const FILE = 'server.js';
let src = fs.readFileSync(FILE, 'utf8');
const orig = src;

function mustReplace(find, replace, label) {
  if (!src.includes(find)) {
    console.error(`❌ FANT IKKE (${label}):\n${find}`);
    process.exit(1);
  }
  src = src.split(find).join(replace);
  console.log(`✅ ${label}`);
}

// 1) Import etter sentKeysStore-importen (fra script 32)
mustReplace(
  `import * as sentKeysStore from './lib/sentKeysStore.js';`,
  `import * as sentKeysStore from './lib/sentKeysStore.js';
import { initMonitor, startMonitor, runMonitorCheck, monitorStatus } from './lib/monitor.js';`,
  'Import lagt til'
);

// 2) /health viser monitor-status
mustReplace(
  `    sentKeys: sentKeysStore.status(),
    pipeline: buildPipelineState(),`,
  `    sentKeys: sentKeysStore.status(),
    monitor: monitorStatus(),
    pipeline: buildPipelineState(),`,
  '/health viser monitor-status'
);

// 3) Manuelt testendepunkt + oppstart av monitor, rett før sentKeysStore.init()
mustReplace(
  `sentKeysStore.init();`,
  `app.post("/dev/monitor-check", async (req, res) => {
  try {
    const result = await runMonitorCheck();
    res.json({ ok: true, result });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

const monitorIntervalMs = Number(process.env.MONITOR_INTERVAL_MS || 30 * 60 * 1000);
initMonitor({ fetchAllCampaigns, sendTelegram });
startMonitor(monitorIntervalMs);

sentKeysStore.init();`,
  'Monitor-endepunkt + oppstart lagt til'
);

if (src === orig) {
  console.error('❌ Ingen endringer gjort');
  process.exit(1);
}
fs.writeFileSync(FILE, src);
console.log('✅ server.js patchet');
EOF

echo "==> Sikkerhetskopi..."
cp server.js server.js.bak-script33

echo "==> Kjører patch..."
node patch-monitor.mjs

echo "==> Syntaks-sjekk..."
node --check server.js && echo "✅ SYNTAKS OK"

echo "==> Rydder opp..."
rm patch-monitor.mjs

echo ""
echo "✅ FERDIG. Neste: commit + push."
