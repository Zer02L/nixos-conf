/**
 * Web Tools Extension
 *
 * Adds web fetch and web search capabilities to the coding agent.
 * Allows the LLM to make HTTP requests and search the internet.
 *
 * Tools:
 *   web_fetch  - Make HTTP GET/POST requests to URLs
 *   web_search - Search the web using DuckDuckGo (no API key needed)
 *
 * Install: copy to ~/.pi/agent/extensions/ or .pi/extensions/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type, type Static } from "typebox";

// --------------- web_fetch tool ---------------

const WebFetchParams = Type.Object({
	url: Type.String({ description: "URL to fetch (must use http:// or https://)" }),
	method: Type.Optional(
		Type.Union([Type.Literal("GET"), Type.Literal("POST")], {
			description: "HTTP method (default: GET)",
		}),
	),
	headers: Type.Optional(
		Type.Record(Type.String(), Type.String(), {
			description: "Optional HTTP headers as key-value pairs",
		}),
	),
	body: Type.Optional(
		Type.String({ description: "Request body for POST requests" }),
	),
});

type WebFetchParamsType = Static<typeof WebFetchParams>;

async function webFetchExecute(
	_toolCallId: string,
	params: WebFetchParamsType,
	signal: AbortSignal | undefined,
	_onUpdate: ((update: { content: Array<{ type: "text"; text: string }> }) => void) | undefined,
	_ctx: any,
): Promise<{
	content: Array<{ type: "text"; text: string }>;
	details: Record<string, unknown>;
	isError?: boolean;
}> {
	const { url, method = "GET", headers, body } = params;

	// Validate URL
	try {
		const parsed = new URL(url);
		if (!["http:", "https:"].includes(parsed.protocol)) {
			return {
				content: [{ type: "text", text: `Error: Only http:// and https:// URLs are allowed, got ${parsed.protocol}` }],
				details: {},
				isError: true,
			};
		}
	} catch {
		return {
			content: [{ type: "text", text: `Error: Invalid URL: ${url}` }],
			details: {},
			isError: true,
		};
	}

	// Block dangerous/internal URLs
	const blockedPatterns = [
		/^https?:\/\/(localhost|127\.0\.0\.1|0\.0\.0\.0|10\.\d+\.\d+\.\d+)/i,
		/^https?:\/\/(172\.(1[6-9]|2\d|3[01])\.\d+\.\d+)/,
		/^https?:\/\/(192\.168\.\d+\.\d+)/,
		/^https?:\/\/169\.254\.\d+\.\d+/,
		/^https?:\/\/\[::[10]?\]/,
		/^https?:\/\/0x7f/i,
	];
	for (const pattern of blockedPatterns) {
		if (pattern.test(url)) {
			return {
				content: [{ type: "text", text: `Error: Requests to private/internal IPs are blocked: ${url}` }],
				details: {},
				isError: true,
			};
		}
	}

	try {
		const fetchHeaders: Record<string, string> = {
			"User-Agent": "Mozilla/5.0 (compatible; PiCodingAgent/1.0; +https://pi.dev)",
			...headers,
		};

		const fetchOptions: RequestInit & { headers: Record<string, string> } = {
			method,
			headers: fetchHeaders,
			signal,
		};

		if (body && method === "POST") {
			fetchOptions.body = body;
		}

		const response = await fetch(url, fetchOptions);
		const contentType = response.headers.get("content-type") || "";
		let text: string;

		if (contentType.includes("application/json")) {
			const json = await response.json();
			text = JSON.stringify(json, null, 2);
		} else {
			text = await response.text();
		}

		// Truncate response to avoid blowing up context
		if (text.length > 50000) {
			text = text.slice(0, 50000) + "\n\n... [truncated at 50000 chars]";
		}

		const result = {
			content: [{ type: "text" as const, text }],
			details: {
				status: response.status,
				statusText: response.statusText,
				contentType,
				url: response.url,
			},
			isError: !response.ok,
		};

		return result;
	} catch (error: unknown) {
		const msg = error instanceof Error ? error.message : String(error);
		// Check if aborted
		if (signal?.aborted) {
			return {
				content: [{ type: "text", text: "Request was cancelled." }],
				details: {},
				isError: true,
			};
		}
		return {
			content: [{ type: "text", text: `Error fetching ${url}: ${msg}` }],
			details: {},
			isError: true,
		};
	}
}

// --------------- web_search tool ---------------

/**
 * Searches DuckDuckgo's lite version (no JS, no API key).
 * Uses the lite endpoint because it returns clean HTML results.
 */
async function searchDuckDuckGo(
	query: string,
	signal?: AbortSignal,
): Promise<string> {
	const url = `https://lite.duckduckgo.com/lite/?q=${encodeURIComponent(query)}`;
	const response = await fetch(url, {
		headers: {
			"User-Agent": "Mozilla/5.0 (compatible; PiCodingAgent/1.0; +https://pi.dev)",
		},
		signal,
	});

	if (!response.ok) {
		throw new Error(`DuckDuckGo returned ${response.status}`);
	}

	const html = await response.text();

	// Parse results from the HTML table structure
	const results: Array<{ title: string; link: string; snippet: string }> = [];
	// DuckDuckGo lite returns results in a specific table structure
	const linkRegex = /<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
	const snippetRegex = /<td[^>]*class="result-snippet"[^>]*>([\s\S]*?)<\/td>/gi;

	const links: Array<{ href: string; text: string }> = [];
	let m: RegExpExecArray | null;
	while ((m = linkRegex.exec(html)) !== null) {
		const href = m[1];
		const text = m[2].replace(/<[^>]+>/g, "").trim();
		if (href && text && !href.startsWith("#")) {
			links.push({ href, text });
		}
	}

	const snippets: string[] = [];
	while ((m = snippetRegex.exec(html)) !== null) {
		snippets.push(m[1].replace(/<[^>]+>/g, "").trim());
	}

	// Match links with snippets (they alternate: link, snippet, link, snippet...)
	// DDG lite has rows of [link][snippet] per result
	for (let i = 0; i < links.length && i < snippets.length; i++) {
		// Filter out navigation/UI links
		if (
			links[i].href.startsWith("http") &&
			!links[i].href.includes("duckduckgo.com")
		) {
			results.push({
				title: links[i].text,
				link: links[i].href,
				snippet: snippets[i],
			});
		}
	}

	if (results.length === 0) {
		return `No results found for "${query}". You may need to try a different query or use web_fetch directly.`;
	}

	return results
		.map(
			(r, i) =>
				`${i + 1}. ${r.title}\n   URL: ${r.link}\n   ${r.snippet}`,
		)
		.join("\n\n");
}

const WebSearchParams = Type.Object({
	query: Type.String({ description: "Search query" }),
});

type WebSearchParamsType = Static<typeof WebSearchParams>;

async function webSearchExecute(
	_toolCallId: string,
	params: WebSearchParamsType,
	signal: AbortSignal | undefined,
	_onUpdate: ((update: { content: Array<{ type: "text"; text: string }> }) => void) | undefined,
	_ctx: any,
): Promise<{
	content: Array<{ type: "text"; text: string }>;
	details: Record<string, unknown>;
	isError?: boolean;
}> {
	const { query } = params;

	try {
		const result = await searchDuckDuckGo(query, signal);
		return {
			content: [{ type: "text", text: `Search results for "${query}":\n\n${result}` }],
			details: { query },
		};
	} catch (error: unknown) {
		const msg = error instanceof Error ? error.message : String(error);
		if (signal?.aborted) {
			return {
				content: [{ type: "text", text: "Search was cancelled." }],
				details: {},
				isError: true,
			};
		}
		return {
			content: [{ type: "text", text: `Search failed: ${msg}` }],
			details: {},
			isError: true,
		};
	}
}

// --------------- Extension entry point ---------------

export default function webToolsExtension(pi: ExtensionAPI) {
	// Register web_fetch tool
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch a URL and return its contents. Supports GET (default) and POST. " +
			"Useful for reading web pages, APIs, and documentation from the internet.",
		promptSnippet: "Fetch web pages, APIs, and documentation",
		promptGuidelines: [
			"Use web_fetch when you need to read web pages, access APIs, or fetch documentation from the internet.",
			"Use web_fetch to access package registries (npm, PyPI, crates.io) or to look up information that may not be in the local knowledge base.",
			"When fetching HTML pages, the raw HTML is returned — use your understanding to extract the relevant information.",
		],
		parameters: WebFetchParams,
		async execute(toolCallId, params, signal, onUpdate, ctx) {
			const result = await webFetchExecute(toolCallId, params, signal, onUpdate, ctx);
			return {
				content: result.content,
				details: result.details as Record<string, unknown>,
				isError: result.isError,
			};
		},
	});

	// Register web_search tool
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web using DuckDuckGo. Returns a list of results with titles, URLs, and snippets. " +
			"Useful for finding current information, documentation, and resources.",
		promptSnippet: "Search the web for information",
		promptGuidelines: [
			"Use web_search when you need to find current information from the internet — documentation, news, tutorials, package info, etc.",
			"After searching, use web_fetch to read specific pages for full details.",
			"Search results are from DuckDuckGo and may not be comprehensive — try multiple queries if needed.",
		],
		parameters: WebSearchParams,
		async execute(toolCallId, params, signal, onUpdate, ctx) {
			const result = await webSearchExecute(toolCallId, params, signal, onUpdate, ctx);
			return {
				content: result.content,
				details: result.details as Record<string, unknown>,
				isError: result.isError,
			};
		},
	});
}
