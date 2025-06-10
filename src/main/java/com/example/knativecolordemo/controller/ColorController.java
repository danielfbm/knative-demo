package com.example.knativecolordemo.controller;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.service.ColorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/colors")
@CrossOrigin(origins = "*")
public class ColorController {

    @Autowired
    private ColorService colorService;

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

            ColorChange.Color color = ColorChange.Color.valueOf(colorStr.toUpperCase());
            ColorChange colorChange = colorService.setColor(color, source);

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
