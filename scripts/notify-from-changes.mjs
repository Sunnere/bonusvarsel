import fs from "node:fs";
import path from "node:path";

const summaryPath = path.resolve("data", "changes.summary.json");

function main() {
  if (!fs.existsSync(summaryPath)) {
    console.error(`Fant ikke ${summaryPath}. Kjør collector først: node scripts/collect-loyaltykey.mjs`);
    process.exit(1);
  }

  const summary = JSON.parse(fs.readFileSync(summaryPath, "utf-8"));

  const c = summary.campaigns || {};
  const s = summary.shops || {};

  const hasChanges =
    (c.added || 0) > 0 || (c.updated || 0) > 0 ||
    (s.added || 0) > 0 || (s.updated || 0) > 0;

  if (!hasChanges) {
    console.log("Ingen endringer ✅");
    console.log(`Campaigns: +${c.added || 0} / ~${c.updated || 0} / -${c.removed || 0}`);
    console.log(`Shops:     +${s.added || 0} / ~${s.updated || 0} / -${s.removed || 0}`);
    return;
  }

  console.log("ENDRINGER 🚨");
  console.log(`Campaigns: +${c.added || 0} / ~${c.updated || 0} / -${c.removed || 0}`);
  console.log(`Shops:     +${s.added || 0} / ~${s.updated || 0} / -${s.removed || 0}`);

  // Neste steg: send til Discord/Slack/Push/Webhook.
  // Foreløpig: bare print til console.
}

main();
