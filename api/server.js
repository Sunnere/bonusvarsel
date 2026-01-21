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
      headers: { "User-Agent": "BonusVarsel/1.0 (Codespaces)" }
    });

    if (!r.ok) {
      return res.status(502).json({ error: "Upstream error", status: r.status });
    }

    const html = await r.text();
    const $ = cheerio.load(html);

    const items = [];

    $("a").each((_, a) => {
      const href = $(a).attr("href") || "";
      const text = $(a).text().replace(/\s+/g, " ").trim();
      if (!text || text.length < 10) return;

      const absolute = href.startsWith("http")
        ? href
        : href.startsWith("/")
          ? `https://onlineshopping.flysas.com${href}`
          : `https://onlineshopping.flysas.com/${href}`;

      const lower = text.toLowerCase();
      const looksLikeCampaign =
        lower.includes("poeng") || lower.includes("bonus") || /(\d+\s*x)/i.test(text);

      if (!looksLikeCampaign) return;

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

    const seen = new Set();
    const campaigns = items
      .filter((x) => {
        const k = `${x.url}::${x.title}`;
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      })
      .slice(0, 50);

    res.json({ source: url, count: campaigns.length, campaigns });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});
app.get("/api/debug", async (_, res) => {
  try {
    const url = "https://onlineshopping.flysas.com/nb-NO/kampanjer/1";
    const r = await fetch(url, {
      headers: { "User-Agent": "BonusVarsel/1.0 (Codespaces)" },
    });

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

    const foundKeywords = [];
    const hay = html.toLowerCase();
    const needles = ["api", "json", "graphql", "campaign", "kampanj", "offers", "prom"];
    for (const n of needles) {
      if (hay.includes(n)) foundKeywords.push(n);
    }

    res.json({
      status: r.status,
      url,
      scripts: scripts.slice(0, 80),
      links: links.slice(0, 80),
      foundKeywords,
      htmlSnippet: html.slice(0, 2000),
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});
const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`API running on http://0.0.0.0:${port}`));
