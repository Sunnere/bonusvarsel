// scripts/notify-telegram.mjs
export async function sendTelegram(message, opts = {}) {
  const token = process.env.TG_BOT_TOKEN;
  const chatId = process.env.TG_CHAT_ID;
  if (!token) throw new Error("Missing env var: TG_BOT_TOKEN");
  if (!chatId) throw new Error("Missing env var: TG_CHAT_ID");

  console.log(`DEBUG: TG_CHAT_ID lengde = ${chatId.length} tegn`);
  console.log(`DEBUG: TG_CHAT_ID verdi  = '${chatId}'`);
  console.log(`DEBUG: TG_BOT_TOKEN lengde = ${token.length} tegn`);
  console.log(`DEBUG: TG_BOT_TOKEN starter med = '${token.slice(0, 10)}...'`);

  const parseMode = opts.parse_mode ?? "HTML";
  const disablePreview = opts.disable_web_page_preview ?? true;
  const chunks = splitTelegram(String(message ?? ""), 4000);
  for (const text of chunks) {
    const url = `https://api.telegram.org/bot${token}/sendMessage`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        parse_mode: parseMode,
        disable_web_page_preview: disablePreview,
      }),
    });
    if (!res.ok) {
      const txt = await res.text();
      throw new Error(`Telegram API error ${res.status}: ${txt}`);
    }
  }
}
function splitTelegram(text, maxLen) {
  if (!text) return [""];
  if (text.length <= maxLen) return [text];
  const lines = text.split("\n");
  const out = [];
  let buf = "";
  for (const line of lines) {
    const candidate = buf ? `${buf}\n${line}` : line;
    if (candidate.length <= maxLen) {
      buf = candidate;
      continue;
    }
    if (buf) out.push(buf);
    buf = line;
    while (buf.length > maxLen) {
      out.push(buf.slice(0, maxLen));
      buf = buf.slice(maxLen);
    }
  }
  if (buf) out.push(buf);
  return out;
}
