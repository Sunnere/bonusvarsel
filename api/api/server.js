import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import * as cheerio from "cheerio";

const app = express();
app.use(cors());

app.get("/health", (_, res) => res.json({ ok: true }));

app.get("/api/campaigns", async (_, res) => {
  try {
    const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";

    const r = await fetch(url, {
      headers: {
        // enkel user-agent for å unngå enkelte 403
        "User-Agent": "BonusVarsel/1.0 (Codespaces)"
      }
    });

    if (!r.ok) {
      return res.status(502).json({ error: "Upstream error", status: r.status });
    }

    const html = await r.text();
    const $ = cheerio.load(html);

    // NOTE: SAS-siden kan endre HTML. Derfor parser vi defensivt:
    // Vi henter alle lenker som ser ut som kampanje-kort/elementer og tar med tekst.
    const items = [];

    $("a").each((_, a) => {
      const href = $(a).attr("href") || "";
      const text = $(a).text().replace(/\s+/g, " ").trim();

      // filtrer bort støy – vi vil bare ha "meningsfulle" kampanje-lenker
      if (!text || text.length < 10) return;

      // gjør relative lenker absolute
      const absolute = href.startsWith("http")
        ? href
        : href.startsWith("/")
          ? `https://onlineshopping.flysas.com${href}`
          : `https://onlineshopping.flysas.com/${href}`;

      // enkel heuristikk: kampanje-siden inneholder ofte "x" eller "poeng"
      const lower = text.toLowerCase();
      const looksLikeCampaign =
        lower.includes("poeng") || lower.includes("bonus") || /(\d+\s*x)/i.test(text);

      if (!looksLikeCampaign) return;

      // prøv å hente ut multiplikator som "2x", "6x" osv.
      const m = text.match(/(\d+)\s*x/i);
      const multiplier = m ? Number(m[1]) : null;

      items.push({
        title: text,
        store: null,
        details: null,
        multiplier,
        url: absolute
      });
    });

    // dedupe på url+title
    const seen = new Set();
    const campaigns = items.filter((x) => {
      const k = `${x.url}::${x.title}`;
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    }).slice(0, 50);

    res.json({ source: url, count: campaigns.length, campaigns });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`API running on http://0.0.0.0:${port}`);
});
cat > server.js << 'EOF'
import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import * as cheerio from "cheerio";

const app = express();
app.use(cors());

app.get("/health", (_, res) => res.json({ ok: true }));

app.get("/api/debug", async (_, res) => {
  const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";
  const r = await fetch(url, { headers: { "User-Agent": "BonusVarsel/1.0 (Codespaces)" } });
  const html = await r.text();
  const $ = cheerio.load(html);

  const scripts = [];
  $("script").each((_, s) => {
    const src = $(s).attr("src");
    if (src) scripts.push(src);
  });

  const links = [];
  $("link").each((_, l) => {
    const href = $(l).attr("href");
    if (href) links.push(href);
  });

  // Prøv å finne "json", "api", "graphql" osv i HTML
  const candidates = [];
  const haystack = html.toLowerCase();
  const needles = ["api", "json", "graphql", "campaign", "kampanj", "offers", "prom"];
  for (const n of needles) {
    if (haystack.includes(n)) candidates.push(n);
  }

  res.json({
    status: r.status,
    scripts: scripts.slice(0, 50),
    links: links.slice(0, 50),
    foundKeywords: candidates,
    htmlSnippet: html.slice(0, 1500)
  });
});