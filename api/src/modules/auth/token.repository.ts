import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';
import { DynamoService } from '../../infra/dynamo.service';

export interface TokenRecord {
  tokenId: string;
  tenantId: string;
  revoked: boolean;
  createdAt: string;
}

export interface CreatedToken extends TokenRecord {
  rawToken: string;
}

@Injectable()
export class TokenRepository {
  private get table() {
    return process.env.TENANTS_TABLE ?? 'TenantsTable';
  }

  constructor(private readonly dynamo: DynamoService) {}

  async create(tenantId: string): Promise<CreatedToken> {
    const rawToken = randomBytes(32).toString('hex');
    const tokenHash = this.hash(rawToken);
    const tokenId = randomBytes(8).toString('hex');
    const createdAt = new Date().toISOString();

    await Promise.all([
      this.dynamo.putItem(this.table, {
        PK: `TOKEN_HASH#${tokenHash}`,
        SK: 'METADATA',
        tokenId,
        tenantId,
        revoked: false,
        createdAt,
      }),
      this.dynamo.putItem(this.table, {
        PK: `TENANT_TOKENS#${tenantId}`,
        SK: `TOKEN#${tokenId}`,
        tokenId,
        tenantId,
        revoked: false,
        createdAt,
        tokenHash,
      }),
    ]);

    return { rawToken, tokenId, tenantId, revoked: false, createdAt };
  }

  async validate(rawToken: string): Promise<TokenRecord | null> {
    const tokenHash = this.hash(rawToken);
    const item = await this.dynamo.getItem(
      this.table,
      `TOKEN_HASH#${tokenHash}`,
      'METADATA',
    );
    if (!item) return null;
    return {
      tokenId: item.tokenId as string,
      tenantId: item.tenantId as string,
      revoked: item.revoked as boolean,
      createdAt: item.createdAt as string,
    };
  }

  async listByTenant(tenantId: string): Promise<TokenRecord[]> {
    const items = await this.dynamo.queryItems(
      this.table,
      `TENANT_TOKENS#${tenantId}`,
      'TOKEN#',
    );
    return items.map((item) => ({
      tokenId: item.tokenId as string,
      tenantId: item.tenantId as string,
      revoked: item.revoked as boolean,
      createdAt: item.createdAt as string,
    }));
  }

  async revoke(tenantId: string, tokenId: string): Promise<boolean> {
    const items = await this.dynamo.queryItems(
      this.table,
      `TENANT_TOKENS#${tenantId}`,
      `TOKEN#${tokenId}`,
    );
    if (!items.length) return false;

    const tokenHash = items[0].tokenHash as string;

    await Promise.all([
      this.dynamo.updateItem(
        this.table,
        `TOKEN_HASH#${tokenHash}`,
        'METADATA',
        { revoked: true },
      ),
      this.dynamo.updateItem(
        this.table,
        `TENANT_TOKENS#${tenantId}`,
        `TOKEN#${tokenId}`,
        { revoked: true },
      ),
    ]);

    return true;
  }

  private hash(rawToken: string): string {
    return createHash('sha256').update(rawToken).digest('hex');
  }
}
