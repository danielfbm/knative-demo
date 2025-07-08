package com.example.knativecolordemo.service;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.builder.CloudEventBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.model.ColorChange.Color;

import java.net.URI;
import java.time.OffsetDateTime;
import java.time.ZonedDateTime;
import java.util.UUID;

@Service
public class EventPublisherService {

    private static final Logger logger = LoggerFactory.getLogger(EventPublisherService.class);

    @Value("${knative.broker.url:http://broker-ingress.knative-eventing.svc.cluster.local/eventing-demo/default}")
    private String brokerUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public EventPublisherService() {
        this.restTemplate = new RestTemplate();
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
                    .withType("com.example.color.manual.change")
                    .withSource(URI.create("com.example.knativecolordemo"))
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
            // Convert CloudEvent to HTTP format
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Ce-Id", event.getId());
            headers.set("Ce-Specversion", event.getSpecVersion().toString());
            headers.set("Ce-Type", event.getType());
            headers.set("Ce-Source", event.getSource().toString());
            headers.set("Ce-Time", event.getTime().toString());

            // Get event data as string
            String eventDataJson = "";
            if (event.getData() != null) {
                eventDataJson = new String(event.getData().toBytes());
            }

            HttpEntity<String> request = new HttpEntity<>(eventDataJson, headers);

            logger.info("sending message to broker {}", brokerUrl);

            // Send HTTP POST to broker
            restTemplate.exchange(brokerUrl, HttpMethod.POST, request, String.class);

            logger.info("Successfully published event: {} ({})", event.getId(), event.getType());

        } catch (Exception e) {
            logger.error("Error publishing event to broker", e);
            throw new RuntimeException("Failed to publish event", e);
        }
    }
}
