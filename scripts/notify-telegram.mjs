// scripts/notify-telegram.mjs
import https from "node:https";

const TOKEN = process.env.TG_BOT_TOKEN;
const CHAT_ID = process.env.TG_CHAT_ID;

export async function sendTelegram(text) {
  if (!TOKEN) throw new Error("Mangler TG_BOT_TOKEN");
  if (!CHAT_ID) throw new Error("Mangler TG_CHAT_ID");
  if (!text) throw new Error("Mangler meldingstekst");

  const payload = JSON.stringify({
    chat_id: CHAT_ID,
    text: String(text),
    disable_web_page_preview: true,
  });

  const options = {
    hostname: "api.telegram.org",
    path: `/bot${TOKEN}/sendMessage`,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(payload),
    },
  };

  const resBody = await new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => resolve({ status: res.statusCode || 0, data }));
    });
    req.on("error", reject);
    req.write(payload);
    req.end();
  });

  if (resBody.status < 200 || resBody.status >= 300) {
    let msg = resBody.data;
    try {
      const parsed = JSON.parse(resBody.data);
      msg = parsed?.description || resBody.data;
    } catch {}
    throw new Error(`Telegram API feil: HTTP ${resBody.status} - ${msg}`);
  }

  return true;
}
