import re

path = 'api/server.js'
with open(path, 'r') as f:
    c = f.read()

old = """      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      if (!allFavSlugs.length) continue;

      const newCampaigns = [];
      for (const campaign of campaigns) {
        if (!campaign.slug) continue;
        const normalizedFavSlugs = allFavSlugs.map(s => 
          s.replace(/^tn_/, '').replace(/^sas_/, ''));
        const normalizedCampaignSlug = campaign.slug.replace(/^tn_/, '').replace(/^sas_/, '');
        if (!normalizedFavSlugs.includes(normalizedCampaignSlug)) continue;
        if ((campaign.multiplier ?? 1) <= 1) continue;
        const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
        if (sentKeysStore.has(key)) continue;
        newCampaigns.push(campaign);
        await sentKeysStore.add(key);
      }
      if (!newCampaigns.length) continue;"""

new = """      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];
      const isFreeTier = !allFavSlugs.length;

      const newCampaigns = [];
      if (isFreeTier) {
        // Free-tier uten favoritter: send topp 3 generelle tilbud
        const topGeneral = campaigns
          .filter(c => c.slug && (c.multiplier ?? 1) > 1)
          .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
          .slice(0, 3);
        for (const campaign of topGeneral) {
          const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      } else {
        for (const campaign of campaigns) {
          if (!campaign.slug) continue;
          const normalizedFavSlugs = allFavSlugs.map(s =>
            s.replace(/^tn_/, '').replace(/^sas_/, ''));
          const normalizedCampaignSlug = campaign.slug.replace(/^tn_/, '').replace(/^sas_/, '');
          if (!normalizedFavSlugs.includes(normalizedCampaignSlug)) continue;
          if ((campaign.multiplier ?? 1) <= 1) continue;
          const key = `${deviceId}-${campaign.slug}-${campaign.multiplier}`;
          if (sentKeysStore.has(key)) continue;
          newCampaigns.push(campaign);
          await sentKeysStore.add(key);
        }
      }
      if (!newCampaigns.length) continue;"""

if old not in c:
    print("❌ FEIL: Fant ikke original-koden. Ingen endring gjort. Sjekk om filen allerede er endret.")
    exit(1)

c = c.replace(old, new)

old_msg = """      const tgLines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => bvTelegramLine(c))
        .join('\\n');
      const msg = newCampaigns.length === 1
        ? `🔔 <b>${newCampaigns[0].title}</b> har ${newCampaigns[0].multiplier}x bonus akkurat nå!\\n\\n${bvTelegramLine(newCampaigns[0])}\\n\\n${BV_TG_REMINDER}`
        : `🔔 <b>${newCampaigns.length} favorittbutikker har kampanje!</b>\\n\\n${tgLines}\\n\\n${BV_TG_REMINDER}`;

      const tgOk = await sendTelegram(msg);

      if (favs.email) {
        const htmlCards = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => bvOfferCard(c))
          .join('');
        const htmlMsg = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 ${newCampaigns.length === 1 ? newCampaigns[0].title + ' har kampanje!' : newCampaigns.length + ' favorittbutikker har kampanje!'}</h2>${htmlCards}${BV_EMAIL_REMINDER}</div>`;
        await sendEmail(
          favs.email,
          '🔔 Bonusvarsel – kampanje hos favorittene dine!',
          htmlMsg
        );
      }"""

new_msg = """      const tgLines = newCampaigns
        .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
        .map(c => bvTelegramLine(c))
        .join('\\n');

      const headerText = isFreeTier
        ? (newCampaigns.length === 1
            ? `🔔 <b>Ukens beste tilbud: ${newCampaigns[0].title}</b>`
            : `🔔 <b>Ukens ${newCampaigns.length} beste tilbud</b>`)
        : (newCampaigns.length === 1
            ? `🔔 <b>${newCampaigns[0].title}</b> har ${newCampaigns[0].multiplier}x bonus akkurat nå!`
            : `🔔 <b>${newCampaigns.length} favorittbutikker har kampanje!</b>`);

      const msg = `${headerText}\\n\\n${tgLines}\\n\\n${BV_TG_REMINDER}`;

      const tgOk = await sendTelegram(msg);

      if (favs.email) {
        const htmlCards = newCampaigns
          .sort((a,b) => (b.multiplier??0)-(a.multiplier??0))
          .map(c => bvOfferCard(c))
          .join('');
        const emailHeader = isFreeTier
          ? (newCampaigns.length === 1 ? newCampaigns[0].title + ' er ukens beste tilbud!' : 'Ukens ' + newCampaigns.length + ' beste tilbud')
          : (newCampaigns.length === 1 ? newCampaigns[0].title + ' har kampanje!' : newCampaigns.length + ' favorittbutikker har kampanje!');
        const htmlMsg = `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;"><h2 style="color:#0F2340;">🔔 ${emailHeader}</h2>${htmlCards}${BV_EMAIL_REMINDER}</div>`;
        await sendEmail(
          favs.email,
          isFreeTier ? '🔔 Bonusvarsel – ukens beste tilbud!' : '🔔 Bonusvarsel – kampanje hos favorittene dine!',
          htmlMsg
        );
      }"""

if old_msg not in c:
    print("❌ FEIL: Fant ikke melding-koden. Sjekk om filen allerede er endret.")
    exit(1)

c = c.replace(old_msg, new_msg)

with open(path, 'w') as f:
    f.write(c)

print("✅ Free-tier generelle tilbud lagt til i checkFavoritesAndNotify()")
