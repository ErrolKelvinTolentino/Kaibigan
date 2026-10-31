// Public educational metadata only. No user text, identity or database access.
export const topics: Record<string, string> = {
  "mental-health-basics": "mental health",
  "understanding-anxiety": "anxiety",
  "low-mood-depression": "depression",
  "stress-burnout": "stress management",
  "sleep-and-mind": "healthy sleep",
  "asking-for-help": "mental health services",
  "panic-attacks": "panic disorder",
  "emotional-regulation": "emotional wellness",
  "self-compassion": "self esteem",
  "healthy-boundaries": "healthy relationships",
  "grief-and-loss": "grief",
  "types-of-care": "mental health services",
  "understanding-adhd": "attention deficit hyperactivity disorder",
  "understanding-ocd": "obsessive compulsive disorder",
  "understanding-bipolar": "bipolar disorder",
  "understanding-ptsd": "post traumatic stress disorder",
  "understanding-eating-disorders": "eating disorders",
  "understanding-schizophrenia": "schizophrenia",
  "social-anxiety": "social anxiety disorder",
  "substance-use-mental-health": "substance use disorder mental health",
  "supporting-someone": "helping someone with mental illness",
  "suicide-safety": "suicide prevention warning signs",
  "philippines-support-contacts": "mental health crisis support",
};

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Expose-Headers": "X-Resource-Cache",
};
type Cached = { body: string; type: string; expires: number };

export function createHandler(upstream: typeof fetch = fetch, now = Date.now) {
  const cache = new Map<string, Cached>();
  const pending = new Map<string, Promise<Cached>>();
  const visitors = new Map<string, { count: number; expires: number }>();
  let requests = Promise.resolve();
  let nextSlot = 0;

  function reply(body: string, status: number, type = "application/json", hit = false) {
    return new Response(body, { status, headers: {
      ...cors, "Content-Type": type, "X-Resource-Cache": hit ? "hit" : "miss",
      "Cache-Control": status === 200 ? "public, max-age=86400" : "no-store",
    } });
  }

  async function request(url: URL) {
    // Serialize upstream starts within an isolate. PubMed's no-key limit is
    // three requests/second; MedlinePlus's limit is 85/minute. Shared caching
    // and a 750ms gap keep this handler below both when reusing the isolate.
    const operation = requests.then(async () => {
      const delay = Math.max(0, nextSlot - now());
      if (delay > 0) await new Promise((resolve) => setTimeout(resolve, delay));
      nextSlot = now() + 750;
      const response = await upstream(url, { signal: AbortSignal.timeout(8000) });
      if (!response.ok) throw new Error("Upstream unavailable");
      return response;
    });
    requests = operation.then(() => undefined, () => undefined);
    return operation;
  }

  async function load(id: string, provider: string): Promise<Cached> {
    const term = topics[id];
    if (provider === "medline") {
      const url = new URL("https://wsearch.nlm.nih.gov/ws/query");
      url.search = new URLSearchParams({ db: "healthTopics", term,
        rettype: "brief", retmax: "4", tool: "kaibigan" }).toString();
      const response = await request(url);
      const body = await response.text();
      if (!body.includes("<nlmSearchResult")) throw new Error("Invalid reading response");
      return { body, type: "application/xml; charset=utf-8", expires: now() + 86400000 };
    }
    const search = new URL("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi");
    search.search = new URLSearchParams({ db: "pubmed",
      term: `(${term}) AND (review[Publication Type] OR systematic review[Publication Type])`,
      retmode: "json", retmax: "3", sort: "pub date", tool: "kaibigan" }).toString();
    const found = await (await request(search)).json();
    const ids = found.esearchresult?.idlist?.filter((id: unknown) =>
      typeof id === "string" && /^\d+$/.test(id)).slice(0, 3);
    if (!Array.isArray(ids)) throw new Error("Invalid research response");
    let articles: unknown[] = [];
    if (ids.length) {
      const summary = new URL("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi");
      summary.search = new URLSearchParams({ db: "pubmed", id: ids.join(","),
        retmode: "json", tool: "kaibigan" }).toString();
      const metadata = await (await request(summary)).json();
      articles = ids.flatMap((id: string) => {
        const item = metadata.result?.[id];
        if (!item || typeof item.title !== "string" || !item.title.trim()) return [];
        return [{ id, title: item.title.replace(/<[^>]*>/g, "").slice(0, 400),
          journal: String(item.fulljournalname ?? item.source ?? "").slice(0, 180),
          year: String(item.pubdate ?? "").match(/\b\d{4}\b/)?.[0] ?? "",
          url: `https://pubmed.ncbi.nlm.nih.gov/${id}/` }];
      });
    }
    return { body: JSON.stringify({ articles, provider: "PubMed" }),
      type: "application/json", expires: now() + 86400000 };
  }

  return async (request: Request) => {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "GET") return reply('{"error":"Use GET"}', 405);
    const url = new URL(request.url);
    const id = url.searchParams.get("lesson") ?? "";
    const provider = url.searchParams.get("provider") ?? "medline";
    if (!Object.hasOwn(topics, id) || !["medline", "pubmed"].includes(provider)) {
      return reply('{"error":"Unknown lesson or provider"}', 400);
    }
    // Only fixed lesson ids reach providers. A client cannot proxy arbitrary
    // URLs, user questions, symptom searches, or other outbound content.
    const address = request.headers.get("x-forwarded-for")?.split(",")[0] ?? "anonymous";
    if (visitors.size > 1000) {
      for (const [key, value] of visitors) if (value.expires <= now()) visitors.delete(key);
      if (visitors.size > 2000) visitors.clear();
    }
    const window = visitors.get(address);
    const visitor = window && window.expires > now() ? window : { count: 0, expires: now() + 60000 };
    visitors.set(address, visitor);
    if (++visitor.count > 30) return reply('{"error":"Please try again shortly"}', 429);
    const key = `${provider}:${id}`;
    const saved = cache.get(key);
    if (saved && saved.expires > now()) return reply(saved.body, 200, saved.type, true);
    try {
      let work = pending.get(key);
      if (!work) {
        work = load(id, provider);
        pending.set(key, work);
      }
      const value = await work;
      cache.set(key, value);
      return reply(value.body, 200, value.type);
    } catch (_) {
      if (saved) return reply(saved.body, 200, saved.type, true);
      return reply('{"error":"Reading is temporarily unavailable"}', 503);
    } finally {
      pending.delete(key);
    }
  };
}

if (typeof Deno !== "undefined") Deno.serve(createHandler());
