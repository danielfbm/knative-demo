package com.example.knativecolordemo.controller;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.service.ColorService;
import com.example.knativecolordemo.service.EventPublisherService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/colors")
@CrossOrigin(origins = "*")
public class ColorController {


    private static final Logger logger = LoggerFactory.getLogger(EventPublisherService.class);


    @Autowired
    private ColorService colorService;

    @Autowired
    private EventPublisherService eventPublisherService;

    @GetMapping("/current")
    public ResponseEntity<ColorChange> getCurrentColor() {
        ColorChange currentColor = colorService.getCurrentColor();
        return ResponseEntity.ok(currentColor);
    }

    @GetMapping("/history")
    public ResponseEntity<List<ColorChange>> getColorHistory() {
        List<ColorChange> history = colorService.getColorHistory();
        return ResponseEntity.ok(history);
    }

    @PostMapping("/set")
    public ResponseEntity<ColorChange> setColor(@RequestBody Map<String, String> request) {
        try {
            String colorStr = request.get("color");
            String source = request.getOrDefault("source", "manual");
            String publish = request.getOrDefault("publish", "false");

            ColorChange.Color color = ColorChange.Color.valueOf(colorStr.toUpperCase());

            ColorChange colorChange = new ColorChange(color, ZonedDateTime.now(), source);

            logger.info("Got color change: color {} source {} timestamp", colorChange.getColor(), colorChange.getSource(), colorChange.getTimestamp());

            switch (publish) {
                case "false":
                    // basic individual setting
                    colorChange = colorService.setColor(color, source);
                    break;
                case "true":
                    // Publishes as event into the broker
                    eventPublisherService.publishManualColorChangeEvent(colorChange.getColor(), colorChange.getTimestamp(), colorChange.getSource());
            }
            return ResponseEntity.ok(colorChange);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/available")
    public ResponseEntity<ColorChange.Color[]> getAvailableColors() {
        return ResponseEntity.ok(ColorChange.Color.values());
    }
}
