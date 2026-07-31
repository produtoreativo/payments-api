import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import type { Request } from 'express';
import { ApiTokenService } from './api-token.service';

@Injectable()
export class ApiTokenGuard implements CanActivate {
  constructor(
    private readonly apiTokenService: ApiTokenService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const rawToken = req.headers['x-api-token'] as string | undefined;
    const correlationId =
      (req.headers['x-correlation-id'] as string | undefined) ?? 'unknown';
    const path = req.path;
    const method = req.method;

    if (!rawToken) {
      this.emitRejected({
        correlationId,
        path,
        method,
        reason: 'token_missing',
      });
      throw new UnauthorizedException('Missing X-Api-Token header');
    }

    const entry = await this.apiTokenService.validate(rawToken);

    if (!entry) {
      this.emitRejected({
        correlationId,
        path,
        method,
        reason: 'token_invalid',
      });
      throw new UnauthorizedException('Invalid or revoked API token');
    }

    if (entry.revoked) {
      this.emitRejected({
        correlationId,
        path,
        method,
        reason: 'token_revoked',
        tokenId: entry.tokenId,
      });
      throw new UnauthorizedException('Invalid or revoked API token');
    }

    this.eventEmitter.emit('payments.observability', {
      event_key: 'api.token.validated',
      tenantId: entry.tenantId,
      tokenId: entry.tokenId,
      correlationId,
      path,
      method,
    });

    req['tenantId'] = entry.tenantId;
    req['tokenId'] = entry.tokenId;

    return true;
  }

  private emitRejected(payload: {
    correlationId: string;
    path: string;
    method: string;
    reason: string;
    tokenId?: string;
  }): void {
    this.eventEmitter.emit('payments.observability', {
      event_key: 'api.token.rejected',
      ...payload,
    });
  }
}
