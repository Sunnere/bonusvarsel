const fs = require("fs");
const path = require("path");
const { _internal } = require(path.join(__dirname, "../flying_agent.js"));
const sys = _internal.buildSystem({ lang: "no", context: "", today: "2026-10-15" });
const src = fs.readFileSync(path.join(__dirname, "../flying_agent.js"), "utf8");
const must = ["Spenn", "Trumf", "13,5", "hotell", "bilutleie", "Hertz", "Scandic", "Strawberry", "CashPoints"];
for (const m of must) {
  if (!sys.includes(m)) { console.error("MANGLER i systemprompt: " + m); process.exit(1); }
}
for (const d of ["trumf.no", "hertz.no", "scandichotels.no"]) {
  if (!src.includes('"' + d + '"')) { console.error("MANGLER domene: " + d); process.exit(1); }
}
if (!/Trumf/.test(src.split("Du er Flying Agent")[1].slice(0, 500))) { console.error("Persona nevner ikke Trumf"); process.exit(1); }
console.log("SCOPE-TESTER OK");
