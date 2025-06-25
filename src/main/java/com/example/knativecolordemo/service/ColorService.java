package com.example.knativecolordemo.service;

import com.example.knativecolordemo.model.ColorChange;
import com.example.knativecolordemo.repository.ColorChangeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ColorService {

    @Autowired
    private ColorChangeRepository colorChangeRepository;

    public ColorChange getCurrentColor() {
        Optional<ColorChange> latest = colorChangeRepository.findLatest();
        if (latest.isPresent()) {
            return latest.get();
        }
        // Default to RED if no color has been set
        ColorChange defaultColor = new ColorChange(ColorChange.Color.RED, ZonedDateTime.now(), "default");
        return colorChangeRepository.save(defaultColor);
    }

    public ColorChange setColor(ColorChange.Color color, String source) {
        ColorChange colorChange = new ColorChange(color, ZonedDateTime.now(), source);
        return colorChangeRepository.save(colorChange);
    }

    public List<ColorChange> getColorHistory() {
        return colorChangeRepository.findAllOrderByTimestampDesc();
    }
}
