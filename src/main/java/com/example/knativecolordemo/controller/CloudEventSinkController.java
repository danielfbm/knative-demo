package com.example.knativecolordemo.controller;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.service.CloudEventService;
import com.example.knativecolordemo.service.ColorService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.message.MessageReader;
import io.cloudevents.http.HttpMessageFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@RestController
@RequestMapping("/cloudevents")
public class CloudEventSinkController {

    @Autowired
    private CloudEventService cloudEventService;

    @Autowired
    private ColorService colorService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping
    public ResponseEntity<String> receiveCloudEvent(
            @RequestBody(required = false) String body,
            @RequestHeader HttpHeaders headers) {

        try {

            // Parse the CloudEvent from HTTP request
            MessageReader messageReader = HttpMessageFactory.createReader(
                headers.toSingleValueMap(),
                body != null ? body.getBytes() : new byte[0]
            );

            CloudEvent event = messageReader.toEvent();
            // Extract CloudEvent headers
            String eventId = event.getId();
            String eventType = event.getType();
            String source = event.getSource().toString();
            String specVersion = event.getSpecVersion().toString();
            String subject = event.getSubject();
            String timeHeader = event.getTime().toString();

            // Set defaults if headers are missing
            if (eventId == null) eventId = "unknown-" + System.currentTimeMillis();
            if (eventType == null) eventType = "unknown.event";
            if (source == null) source = "unknown-source";

            ZonedDateTime timestamp = LocalDateTime.now().atZone(ZoneId.systemDefault());
            if (timeHeader != null) {
                try {
                    timestamp = OffsetDateTime.parse(timeHeader).toZonedDateTime();
                } catch (Exception e) {
                    System.err.println("Failed to parse time header: " + timeHeader);
                }
            }

            String data = body != null ? body : "";

            System.out.println("Received CloudEvent:");
            System.out.println("  ID: " + eventId);
            System.out.println("  Type: " + eventType);
            System.out.println("  Source: " + source);
            System.out.println("  Subject: " + subject);
            System.out.println("  Time: " + timeHeader);
            System.out.println("  Data: " + data);


            // Save the cloud event
            cloudEventService.saveCloudEvent(eventId, eventType, source, timestamp, data, subject);

            // Check if this is a color change event

            if ((eventType.equals("com.example.color.change") || eventType.equals("com.example.color.manual.change")) && body != null && !body.trim().isEmpty()) {
                try {
                    JsonNode jsonData = objectMapper.readTree(body);
                    if (jsonData.has("color")) {
                        String colorStr = jsonData.get("color").asText();
                        ColorChange.Color color = ColorChange.Color.valueOf(colorStr.toUpperCase());

                        // Update the current color
                        colorService.setColor(color, "cloudevent:" + source);

                        System.out.println("Updated color to: " + color);
                    }
                } catch (Exception e) {
                    // Log error but don't fail the event processing
                    System.err.println("Failed to process color change from CloudEvent: " + e.getMessage());
                }
            }
            return ResponseEntity.accepted().build();

        } catch (Exception e) {
            System.err.println("Failed to process CloudEvent: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Failed to process CloudEvent: " + e.getMessage());
        }
    }

    // Health check endpoint for Knative
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "healthy", "timestamp", LocalDateTime.now().atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)));
    }

    // Debug endpoint to see all headers
    @PostMapping("/debug")
    public ResponseEntity<Map<String, Object>> debugCloudEvent(
            @RequestBody(required = false) String body,
            @RequestHeader HttpHeaders headers) {

        return ResponseEntity.ok(Map.of(
            "headers", headers.toSingleValueMap(),
            "body", body != null ? body : "null",
            "timestamp", LocalDateTime.now().atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
        ));
    }
}