/**
 * Setup do teste de integração com o Datadog (jest-e2e-datadog.json).
 *
 * Roda antes de qualquer módulo da aplicação ser importado. Cada execução usa um `env`
 * único (e2e-<id>), assim a contagem no Datadog é exata e não se mistura com dados reais.
 * As chaves DD_API_KEY/DD_APP_KEY/DD_SITE vêm do ambiente ou de api/.env (nunca são impressas).
 */
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

try {
  const dotenv = readFileSync(join(__dirname, '../../.env'), 'utf8');
  for (const line of dotenv.split('\n')) {
    const m = /^(DD_API_KEY|DD_APP_KEY|DD_SITE)=(.*)$/.exec(line.trim());
    if (m && !process.env[m[1]])
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
} catch {
  // sem .env: as chaves precisam estar no ambiente
}

process.env.E2E_RUN_ID = randomBytes(4).toString('hex');
process.env.DD_ENV = `e2e-${process.env.E2E_RUN_ID}`;
process.env.DD_SERVICE = 'payments-api';
process.env.DD_TRACE_ENABLED = 'true';
process.env.DD_AGENT_HOST ??= 'localhost';
