#!/usr/bin/env node
// DuckDuckGo Lite MCP Server
// No external dependencies — uses built-in fetch (Node.js 18+)
import { createInterface } from "node:readline";

// --- JSON-RPC helpers ---
const rl = createInterface({ input: process.stdin });

function respond(id, result) {
  process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id, result }) + "\n");
}
function respondError(id, code, message) {
  process.stdout.write(
    JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } }) + "\n",
  );
}
function notify(method, params) {
  process.stdout.write(
    JSON.stringify({ jsonrpc: "2.0", method, params }) + "\n",
  );
}

// --- Throttle: 1.5s between requests to avoid blocking ---
let lastRequest = 0;
async function throttle() {
  const wait = 1500 - (Date.now() - lastRequest);
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastRequest = Date.now();
}

// --- In-memory cache (5 min TTL) ---
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000;

async function search(query) {
  const cached = cache.get(query);
  if (cached && Date.now() - cached.ts < CACHE_TTL) return cached.data;

  await throttle();

  const url = `https://lite.duckduckgo.com/lite/?q=${encodeURIComponent(query)}`;
  const res = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (compatible; DuckDuckBot/1.0; +https://duckduckgo.com/duckduckbot)",
    },
  });
  if (!res.ok) throw new Error(`DuckDuckGo returned ${res.status}`);
  const html = await res.text();

  // Parse lite.duckduckgo.com — it uses tables, no JS
  const results = [];

  // Match result rows: two <tr> blocks per result — link row + snippet row
  const rowRegex = /<tr[^>]*>[\s\S]*?<\/tr>/gi;
  const rows = [...html.matchAll(rowRegex)].map((m) => m[0]);

  for (let i = 0; i < rows.length; i++) {
    // Link row: has class="result-link" in an <a> tag
    const linkMatch = rows[i].match(
      /<a[^>]+href="([^"]+)"[^>]*class="[^"]*result-link[^"]*"[^>]*>([\s\S]*?)<\/a>/i,
    );
    if (!linkMatch) continue;

    // Snippet row: next <tr> with class="result-snippet"
    let snippet = "";
    if (i + 1 < rows.length) {
      const snipMatch = rows[i + 1].match(
        /<td[^>]*class="[^"]*result-snippet[^"]*"[^>]*>([\s\S]*?)<\/td>/i,
      );
      if (snipMatch) {
        snippet = snipMatch[1].replace(/<[^>]+>/g, "").trim();
      }
    }

    let url = linkMatch[1];
    // DuckDuckGo wraps URLs in redirect — unwrap if internal
    if (url.startsWith("//")) url = "https:" + url;

    results.push({
      title: linkMatch[2].replace(/<[^>]+>/g, "").trim(),
      url,
      snippet,
    });

    if (results.length >= 10) break; // limit
  }

  const data = { results, count: results.length };
  cache.set(query, { data, ts: Date.now() });
  return data;
}

// --- MCP protocol handler ---
rl.on("line", async (line) => {
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return;
  }

  // Notifications (no id) — never respond
  if (msg.id == null) return;

  try {
    if (msg.method === "initialize") {
      respond(msg.id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "duckduckgo-lite", version: "1.0.0" },
      });
    } else if (msg.method === "tools/list") {
      respond(msg.id, {
        tools: [
          {
            name: "search",
            description: "Search DuckDuckGo (text-only, lite version)",
            inputSchema: {
              type: "object",
              properties: {
                q: {
                  type: "string",
                  description: "Search query",
                },
              },
              required: ["q"],
            },
          },
        ],
      });
    } else if (msg.method === "tools/call") {
      const { q } = msg.params.arguments;
      if (!q) throw new Error("Missing required parameter: q");

      const data = await search(q);
      const text =
        data.results.length === 0
          ? "No results found."
          : data.results
              .map(
                (r, i) =>
                  `[${i + 1}] ${r.title}\n    ${r.url}\n    ${r.snippet}`,
              )
              .join("\n\n");

      respond(msg.id, {
        content: [{ type: "text", text }],
        _meta: { count: data.count },
      });
    } else if (msg.method === "ping") {
      respond(msg.id, {});
    } else {
      respondError(msg.id, -32601, `Method not found: ${msg.method}`);
    }
  } catch (e) {
    respondError(msg.id, 0, e.message);
  }
});
