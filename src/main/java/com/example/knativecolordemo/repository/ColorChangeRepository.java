package com.example.knativecolordemo.repository;

import com.example.knativecolordemo.model.ColorChange;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ColorChangeRepository extends JpaRepository<ColorChange, Long> {

    @Query("SELECT c FROM ColorChange c ORDER BY c.timestamp DESC")
    List<ColorChange> findAllOrderByTimestampDesc();

    @Query("SELECT c FROM ColorChange c ORDER BY c.timestamp DESC LIMIT 1")
    Optional<ColorChange> findLatest();
}
