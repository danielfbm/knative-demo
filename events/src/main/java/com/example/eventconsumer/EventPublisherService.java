package com.example.eventconsumer;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.message.MessageWriter;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.cloudevents.http.HttpMessageFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UncheckedIOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class EventPublisherService {

    private static final Logger logger = LoggerFactory.getLogger(EventPublisherService.class);

    @Value("${knative.broker.url:http://broker-ingress.knative-eventing.svc.cluster.local/my-app-namespace/default}")
    private String brokerUrl;

    private final ObjectMapper objectMapper;

    public EventPublisherService() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    public void publishUserCreatedEvent(String userId, String userEmail) {
        try {
            // Create event data
            UserCreatedData eventData = new UserCreatedData(userId, userEmail);

            // Serialize event data to JSON
            String eventDataJson = objectMapper.writeValueAsString(eventData);
            byte[] eventDataBytes = eventDataJson.getBytes();

            // Build CloudEvent
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withType("com.example.user.created")
                    .withSource(URI.create("https://example.com/user-service"))
                    .withTime(OffsetDateTime.now())
                    .withData("application/json", eventDataBytes)
                    .build();

            // Publish event
            publishEvent(event);

        } catch (Exception e) {
            logger.error("Error publishing user created event", e);
        }
    }

    public void publishOrderPlacedEvent(String orderId, String customerId, double amount) {
        try {
            // Create event data
            OrderPlacedData eventData = new OrderPlacedData(orderId, customerId, amount);

            // Serialize event data to JSON
            String eventDataJson = objectMapper.writeValueAsString(eventData);
            byte[] eventDataBytes = eventDataJson.getBytes();

            // Build CloudEvent
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withType("com.example.order.placed")
                    .withSource(URI.create("https://example.com/order-service"))
                    .withTime(OffsetDateTime.now())
                    .withData("application/json", eventDataBytes)
                    .build();

            // Publish event
            publishEvent(event);

        } catch (Exception e) {
            logger.error("Error publishing order placed event", e);
        }
    }

    private void publishEvent(CloudEvent event) {
        try {
            URL url = URI.create(brokerUrl).toURL();
            HttpURLConnection httpUrlConnection = (HttpURLConnection) url.openConnection();
            httpUrlConnection.setRequestMethod("POST");
            httpUrlConnection.setDoOutput(true);
            httpUrlConnection.setDoInput(true);

            logger.info("Sending message to broker {}", brokerUrl);

            // Use CloudEvents HTTP message factory to write the event
            MessageWriter messageWriter = createMessageWriter(httpUrlConnection);
            messageWriter.writeBinary(event);

            // Actually send the request and get the response
            int responseCode = httpUrlConnection.getResponseCode();
            logger.info("Broker response code: {}", responseCode);

            if (responseCode >= 200 && responseCode < 300) {
                logger.info("Successfully published event: {} ({})", event.getId(), event.getType());
            } else {
                // Read error response
                String errorResponse = "";
                try {
                    errorResponse = new String(httpUrlConnection.getErrorStream().readAllBytes());
                } catch (Exception e) {
                    // Ignore error reading error stream
                }
                logger.error("Failed to publish event. Response code: {}, Error: {}", responseCode, errorResponse);
                throw new RuntimeException("Failed to publish event. Response code: " + responseCode);
            }

        } catch (Exception e) {
            logger.error("Error publishing event to broker", e);
            throw new RuntimeException("Failed to publish event", e);
        }
    }

    private static MessageWriter createMessageWriter(HttpURLConnection httpUrlConnection) {
        return HttpMessageFactory.createWriter(
            httpUrlConnection::setRequestProperty,
            body -> {
                try {
                    if (body != null) {
                        httpUrlConnection.setRequestProperty("content-length", String.valueOf(body.length));
                        try (OutputStream outputStream = httpUrlConnection.getOutputStream()) {
                            outputStream.write(body);
                        }
                    } else {
                        httpUrlConnection.setRequestProperty("content-length", "0");
                    }
                } catch (IOException t) {
                    throw new UncheckedIOException(t);
                }
            });
    }

    // Event data classes
    public static class UserCreatedData {
        private String userId;
        private String email;

        public UserCreatedData(String userId, String email) {
            this.userId = userId;
            this.email = email;
        }

        // Getters and setters
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class OrderPlacedData {
        private String orderId;
        private String customerId;
        private double amount;

        public OrderPlacedData(String orderId, String customerId, double amount) {
            this.orderId = orderId;
            this.customerId = customerId;
            this.amount = amount;
        }

        // Getters and setters
        public String getOrderId() { return orderId; }
        public void setOrderId(String orderId) { this.orderId = orderId; }
        public String getCustomerId() { return customerId; }
        public void setCustomerId(String customerId) { this.customerId = customerId; }
        public double getAmount() { return amount; }
        public void setAmount(double amount) { this.amount = amount; }
    }
}
