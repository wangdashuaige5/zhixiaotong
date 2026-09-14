package com.zhixiaotong.config;

import com.zhixiaotong.service.MessageDispatcher;
import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import org.springframework.stereotype.Component;

@Configuration
@ConditionalOnProperty(name = "campus.message-mode", havingValue = "rabbit")
public class RabbitConfig {
  @Bean
  DirectExchange exchange() {
    return new DirectExchange("campus.events", true, false);
  }

  @Bean
  DirectExchange deadExchange() {
    return new DirectExchange("campus.dead", true, false);
  }

  @Bean
  Queue eventQueue() {
    return QueueBuilder.durable("campus.notifications")
        .deadLetterExchange("campus.dead")
        .deadLetterRoutingKey("failed")
        .build();
  }

  @Bean
  Queue deadQueue() {
    return QueueBuilder.durable("campus.failed").build();
  }

  @Bean
  Binding eventBinding() {
    return BindingBuilder.bind(eventQueue()).to(exchange()).with("notify");
  }

  @Bean
  Binding deadBinding() {
    return BindingBuilder.bind(deadQueue()).to(deadExchange()).with("failed");
  }

  @Component
  @ConditionalOnProperty(name = "campus.message-mode", havingValue = "rabbit")
  public static class Consumer {
    private final MessageDispatcher dispatcher;

    public Consumer(MessageDispatcher dispatcher) {
      this.dispatcher = dispatcher;
    }

    @RabbitListener(queues = "campus.notifications")
    public void receive(String id) {
      dispatcher.consume(Long.parseLong(id));
    }
  }
}
