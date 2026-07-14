// scripts/notify-telegram.mjs (med retry ved 5xx-feil)
export async function sendTelegram(message, opts = {}) {
  const token = process.env.TG_BOT_TOKEN;
  const chatId = process.env.TG_CHAT_ID;
  if (!token) throw new Error("Missing env var: TG_BOT_TOKEN");
  if (!chatId) throw new Error("Missing env var: TG_CHAT_ID");
  const parseMode = opts.parse_mode ?? "HTML";
  const disablePreview = opts.disable_web_page_preview ?? true;
  const chunks = splitTelegram(String(message ?? ""), 4000);
  for (const text of chunks) {
    await sendOneMessage(token, chatId, text, parseMode, disablePreview);
  }
}

async function sendOneMessage(token, chatId, text, parseMode, disablePreview, maxRetries = 3) {
  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  let lastErr;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
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
    if (res.ok) return;
    const txt = await res.text();
    lastErr = new Error(`Telegram API error ${res.status}: ${txt}`);
    // Kun retry på 5xx (serverfeil/timeout hos Telegram), ikke 4xx (auth/config)
    if (res.status >= 500 && attempt < maxRetries) {
      const waitMs = attempt * 2000; // 2s, 4s
      console.log(`Telegram ${res.status}, forsøk ${attempt}/${maxRetries}, venter ${waitMs}ms...`);
      await new Promise(r => setTimeout(r, waitMs));
      continue;
    }
    throw lastErr;
  }
  throw lastErr;
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
