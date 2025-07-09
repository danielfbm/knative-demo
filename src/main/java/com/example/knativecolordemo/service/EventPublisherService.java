package com.example.knativecolordemo.service;

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

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.model.ColorChange.Color;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UncheckedIOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.time.OffsetDateTime;
import java.time.ZonedDateTime;
import java.util.UUID;

@Service
public class EventPublisherService {

    private static final Logger logger = LoggerFactory.getLogger(EventPublisherService.class);

    @Value("${knative.broker.url:http://broker-ingress.knative-eventing.svc.cluster.local/eventing-demo/default}")
    private String brokerUrl;

    private final ObjectMapper objectMapper;

    public EventPublisherService() {

        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }    public void publishManualColorChangeEvent(Color color, ZonedDateTime timestamp, String source) {
        try {
            // Create event data
            ColorChange eventData = new ColorChange(color, timestamp, source);

            // Serialize event data to JSON
            String eventDataJson = objectMapper.writeValueAsString(eventData);
            byte[] eventDataBytes = eventDataJson.getBytes();

            // Build CloudEvent
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    // .withType("com.example.color.manual.change")
                    .withType("com.example.color.change")
                    .withSource(URI.create("com.example.knativecolordemo"))
                    .withSubject("manual-color-change")
                    .withTime(OffsetDateTime.now())
                    .withData("application/json", eventDataBytes)
                    .build();

            // Publish event
            publishEvent(event);

        } catch (Exception e) {
            logger.error("Error publishing color change event", e);
        }
    }

      private void publishEvent(CloudEvent event) {
        try {

            URL url = URI.create(brokerUrl).toURL();
            HttpURLConnection httpUrlConnection = (HttpURLConnection) url.openConnection();
            httpUrlConnection.setRequestMethod("POST");
            httpUrlConnection.setDoOutput(true);
            httpUrlConnection.setDoInput(true);

            logger.info("sending message to broker {}", brokerUrl);

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

            logger.info("Successfully published event: {} ({})", event.getId(), event.getType());

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
}
