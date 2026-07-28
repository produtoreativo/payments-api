import type { CloudEventSource } from '@prodops/runtime-sdk';

// Accepts any valid URI (scheme://...) — loose check per CloudEvents §3.1
const URI_RE = /^[a-zA-Z][a-zA-Z0-9+\-.]*:\/\/.+/;

export class InvalidSourceError extends Error {
  constructor(uri: string) {
    super(
      `CloudEventSource must be a URI-reference (e.g. "prodops://payments-api/runtime"), got: "${uri}"`,
    );
    this.name = 'InvalidSourceError';
  }
}

/**
 * Casts a URI string into a typed CloudEventSource.
 * Use for deployment-time source configuration — never pass producer_identity here.
 *
 * Canonical ProdOps URI scheme: prodops://<repo>/<context>
 *   'prodops://payments-api/github-actions'
 *   'prodops://payments-api/runtime'
 *   'prodops://payments-api/human-cli'
 */
export function toCloudEventSource(uri: string): CloudEventSource {
  if (!uri || !URI_RE.test(uri)) {
    throw new InvalidSourceError(uri ?? '');
  }
  return uri as CloudEventSource;
}
