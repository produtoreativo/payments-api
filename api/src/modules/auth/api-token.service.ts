import { Injectable, Logger } from '@nestjs/common';
import { TokenRepository } from './token.repository';

export interface ApiTokenEntry {
  tokenId: string;
  tenantId: string;
  revoked: boolean;
}

@Injectable()
export class ApiTokenService {
  private readonly logger = new Logger(ApiTokenService.name);

  constructor(private readonly tokenRepository: TokenRepository) {}

  async validate(rawToken: string): Promise<ApiTokenEntry | null> {
    const localToken = process.env.API_TOKEN_LOCAL;
    if (localToken && rawToken === localToken) {
      this.logger.log('Local dev token accepted (tokenId: local-dev)');
      return { tokenId: 'local-dev', tenantId: 'local', revoked: false };
    }

    const record = await this.tokenRepository.validate(rawToken);
    if (!record) return null;
    // Return the entry including revoked state so the guard can emit the
    // correct rejection reason (token_revoked vs token_invalid).
    return {
      tokenId: record.tokenId,
      tenantId: record.tenantId,
      revoked: record.revoked,
    };
  }
}
