import { OnEvent } from '@nestjs/event-emitter';
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
class KafkaService {
  constructor(private readonly logger: Logger) {}
  @OnEvent('payments.invoice.confirmed')
  handlePaymentsConfirmedEvent(payload: any) {
    this.logger.log(
      'KafkaService - payments.invoice.confirmed event received:',
      payload,
    );
  }
  @OnEvent('**')
  handleAllEvent(payload: any) {
    // handle and process "OrderCreatedEvent" event
    this.logger.log('event received:', payload);
  }
}

export default KafkaService;
