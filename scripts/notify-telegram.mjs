// scripts/notify-telegram.mjs
export async function sendTelegram(message) {
  const token = process.env.TG_BOT_TOKEN;
  const chatId = process.env.TG_CHAT_ID;

  if (!token) throw new Error("Missing env var: TG_BOT_TOKEN");
  if (!chatId) throw new Error("Missing env var: TG_CHAT_ID");

  // Telegram hard-limit er 4096 tegn per melding
  const chunks = splitTelegram(message, 4000);

  for (const text of chunks) {
    const url = `https://api.telegram.org/bot${token}/sendMessage`;

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        parse_mode: "HTML",
        disable_web_page_preview: false,
      }),
    });

    if (!res.ok) {
      const txt = await res.text();
      throw new Error(`Telegram API error ${res.status}: ${txt}`);
    }
  }
}

// Splitt på linjeskift hvis mulig (snillere enn å kutte midt i ord)
function splitTelegram(text, maxLen) {
  if (!text || text.length <= maxLen) return [text ?? ""];

  const lines = String(text).split("\n");
  const out = [];
  let buf = "";

  for (const line of lines) {
    // +1 for '\n'
    if ((buf.length ? buf.length + 1 : 0) + line.length <= maxLen) {
      buf = buf ? `${buf}\n${line}` : line;
    } else {
      if (buf) out.push(buf);
      // hvis en enkelt linje er for lang, hard-splitt den
      if (line.length > maxLen) {
        for (let i = 0; i < line.length; i += maxLen) {
          out.push(line.slice(i, i + maxLen));
        }
        buf = "";
      } else {
        buf = line;
      }
    }
  }

  if (buf) out.push(buf);
  return out;
}