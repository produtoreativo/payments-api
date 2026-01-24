import { OnEvent } from '@nestjs/event-emitter';
import { Injectable } from '@nestjs/common';

@Injectable()
class KafkaService {
  @OnEvent('payments.invoice.confirmed')
  handlePaymentsConfirmedEvent(payload: any) {
    // handle and process "OrderCreatedEvent" event
    console.log(
      'KafkaService - payments.invoice.confirmed event received:',
      payload,
    );
  }
  @OnEvent('**')
  handleAllEvent(payload: any) {
    // handle and process "OrderCreatedEvent" event
    console.log('event received:', payload);
  }
}

export default KafkaService;
