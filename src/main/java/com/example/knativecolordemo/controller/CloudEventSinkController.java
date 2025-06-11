package com.example.knativecolordemo.controller;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.service.CloudEventService;
import com.example.knativecolordemo.service.ColorService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
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
            // Extract CloudEvent headers
            String eventId = headers.getFirst("ce-id");
            String eventType = headers.getFirst("ce-type");
            String source = headers.getFirst("ce-source");
            String specVersion = headers.getFirst("ce-specversion");
            String subject = headers.getFirst("ce-subject");
            String timeHeader = headers.getFirst("ce-time");

            // Set defaults if headers are missing
            if (eventId == null) eventId = "unknown-" + System.currentTimeMillis();
            if (eventType == null) eventType = "unknown.event";
            if (source == null) source = "unknown-source";

            LocalDateTime timestamp = LocalDateTime.now();
            if (timeHeader != null) {
                try {
                    timestamp = OffsetDateTime.parse(timeHeader).toLocalDateTime();
                } catch (Exception e) {
                    System.err.println("Failed to parse time header: " + timeHeader);
                }
            }

            String data = body != null ? body : "";

            System.out.println("Received CloudEvent:");
            System.out.println("  ID: " + eventId);
            System.out.println("  Type: " + eventType);
            System.out.println("  Source: " + source);
            System.out.println("  Data: " + data);

            // Save the cloud event
            cloudEventService.saveCloudEvent(eventId, eventType, source, timestamp, data, subject);

            // Check if this is a color change event
            if ("com.example.color.change".equals(eventType) && body != null && !body.trim().isEmpty()) {
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
        return ResponseEntity.ok(Map.of("status", "healthy", "timestamp", LocalDateTime.now().toString()));
    }

    // Debug endpoint to see all headers
    @PostMapping("/debug")
    public ResponseEntity<Map<String, Object>> debugCloudEvent(
            @RequestBody(required = false) String body,
            @RequestHeader HttpHeaders headers) {

        return ResponseEntity.ok(Map.of(
            "headers", headers.toSingleValueMap(),
            "body", body != null ? body : "null",
            "timestamp", LocalDateTime.now().toString()
        ));
    }
}