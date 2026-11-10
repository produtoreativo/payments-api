import { readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';
import { PaymentsEvent } from './payments-events';

const SRC = join(__dirname, '..');

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) return sourceFiles(full);
    return full.endsWith('.ts') && !full.endsWith('.spec.ts') ? [full] : [];
  });
}

describe('PaymentsEvent — convenção de nomes dos eventos de negócio', () => {
  const names = Object.values(PaymentsEvent) as string[];

  it('todo nome segue payments.<agregado>.<fato> em minúsculas e snake_case', () => {
    for (const name of names) {
      expect(name).toMatch(/^payments\.[a-z]+(_[a-z]+)*\.[a-z]+(_[a-z]+)*$/);
    }
  });

  it('não há nomes repetidos', () => {
    expect(new Set(names).size).toBe(names.length);
  });

  it('não reutiliza o nome reservado do stream de observabilidade', () => {
    expect(names).not.toContain('payments.observability');
  });

  it('as duplicatas eliminadas não existem mais no catálogo', () => {
    const removed = [
      'payment.confirmed',
      'payment.cancelled',
      'payment.boleto.created',
      'payment.card.hosted_invoice.created',
      'payment.boleto.creation_failed',
      'payments.invoice.provider_failed',
    ];
    for (const legacy of removed) {
      expect(names).not.toContain(legacy);
    }
  });
});

describe('Código-fonte — emissão e escuta de eventos de negócio', () => {
  const files = sourceFiles(SRC).filter(
    (f) => !f.endsWith('payments-events.ts'),
  );

  it('nenhum emit/OnEvent usa um nome antigo como literal', () => {
    const legacy =
      /(emit|OnEvent)\(\s*'(payment\.(confirmed|cancelled|received|boleto|card|chargeback)|split_payment\.)/;
    const offenders = files.filter((f) => legacy.test(readFileSync(f, 'utf8')));
    expect(offenders).toEqual([]);
  });

  it('eventos de negócio são emitidos pelas constantes de PaymentsEvent', () => {
    const literalBusinessEvent = /emit\(\s*'payments\.(?!observability)/;
    const offenders = files.filter((f) =>
      literalBusinessEvent.test(readFileSync(f, 'utf8')),
    );
    expect(offenders).toEqual([]);
  });
});
