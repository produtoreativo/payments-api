/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access */
/** Cliente mínimo da API de métricas do Datadog para os testes de integração. */

const site = () => process.env.DD_SITE ?? 'datadoghq.com';

function headers(): Record<string, string> {
  const api = process.env.DD_API_KEY;
  const app = process.env.DD_APP_KEY;
  if (!api || !app) {
    throw new Error(
      'DD_API_KEY e DD_APP_KEY são necessárias (ambiente ou api/.env) para o teste de integração com o Datadog',
    );
  }
  return { 'DD-API-KEY': api, 'DD-APPLICATION-KEY': app };
}

export async function assertDatadogReachable(): Promise<void> {
  const r = await fetch(`https://api.${site()}/api/v1/validate`, {
    headers: headers(),
  });
  if (r.status !== 200) {
    throw new Error(`Chave de API do Datadog inválida (HTTP ${r.status})`);
  }
  const agent = await fetch(
    `http://${process.env.DD_AGENT_HOST ?? 'localhost'}:8126/info`,
  ).catch(() => undefined);
  if (!agent?.ok) {
    throw new Error(
      'Agente do Datadog não responde em :8126 — suba o container datadog-agent-local',
    );
  }
}

/** Soma a métrica nos últimos 30 min, filtrando pelas tags (ex.: ['env:e2e-ab12', 'event:invoice.cancelled']). */
export async function sumMetric(
  metric: string,
  tags: string[],
): Promise<number> {
  const now = Math.floor(Date.now() / 1000);
  const q = `sum:${metric}{${tags.join(',')}}.as_count()`;
  const url =
    `https://api.${site()}/api/v1/query?from=${now - 1800}&to=${now + 60}` +
    `&query=${encodeURIComponent(q)}`;
  const r = await fetch(url, { headers: headers() });
  if (r.status !== 200)
    throw new Error(`Datadog query falhou (HTTP ${r.status})`);
  const body = await r.json();
  let total = 0;
  for (const s of body.series ?? []) {
    for (const p of s.pointlist ?? []) total += Number(p[1] ?? 0);
  }
  return total;
}

/** Espera até que `check` devolva vazio (tudo conferido) ou o prazo acabe; devolve o último relatório. */
export async function waitUntil(
  check: () => Promise<string[]>,
  timeoutMs = 720_000,
  everyMs = 15_000,
): Promise<string[]> {
  const deadline = Date.now() + timeoutMs;
  let last: string[] = ['não verificado'];
  while (Date.now() < deadline) {
    last = await check();
    if (last.length === 0) return [];
    await new Promise((r) => setTimeout(r, everyMs));
  }
  return last;
}
