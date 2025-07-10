package com.example.eventconsumer;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.message.MessageReader;
import io.cloudevents.http.HttpMessageFactory;
import io.cloudevents.jackson.JsonFormat;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class EventConsumerController {

    private static final Logger logger = LoggerFactory.getLogger(EventConsumerController.class);

    @PostMapping("/")
    public ResponseEntity<String> receiveEvent(
            @RequestHeader HttpHeaders headers,
            @RequestBody(required = false) String body) {

        try {
            // Parse the CloudEvent from HTTP request
            MessageReader messageReader = HttpMessageFactory.createReader(
                headers.toSingleValueMap(),
                body != null ? body.getBytes() : new byte[0]
            );

            CloudEvent event = messageReader.toEvent();

            // Process the event
            logger.info("Received CloudEvent:");
            logger.info("  ID: {}", event.getId());
            logger.info("  Type: {}", event.getType());
            logger.info("  Source: {}", event.getSource());
            logger.info("  Subject: {}", event.getSubject());
            logger.info("  Data: {}", new String(event.getData().toBytes()));

            // Your business logic here
            processEvent(event);

            return ResponseEntity.accepted().build();

        } catch (Exception e) {
            logger.error("Error processing event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                 .body("Error processing event: " + e.getMessage());
        }
    }

    private void processEvent(CloudEvent event) {
        // Implement your event processing logic here
        switch (event.getType()) {
            case "com.example.user.created":
                handleUserCreated(event);
                break;
            case "com.example.order.placed":
                handleOrderPlaced(event);
                break;
            default:
                logger.warn("Unknown event type: {}", event.getType());
        }
    }

    private void handleUserCreated(CloudEvent event) {
        logger.info("Processing user created event: {}", event.getId());
        // Add your user creation handling logic
    }

    private void handleOrderPlaced(CloudEvent event) {
        logger.info("Processing order placed event: {}", event.getId());
        // Add your order processing logic
    }
}