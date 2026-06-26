package io.github.nishian3695.bujit.NavigationItems.SingleEvents;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.UUID;

public class SingleEventModel implements Serializable {
    private static final long serialVersionUID = 1L;

    private final String id;
    private String name;
    private float amount; // always positive
    private boolean isDebit; // true = reduces balance
    private final LocalDate createdDate;
    private LocalDate lastModifiedDate;
    private float appliedAmount; // signed delta already baked into curBalance

    public SingleEventModel(String name, float amount, boolean isDebit) {
        this.id = UUID.randomUUID().toString();
        this.name = name;
        this.amount = Math.abs(amount);
        this.isDebit = isDebit;
        this.createdDate = LocalDate.now();
        this.lastModifiedDate = LocalDate.now();
        this.appliedAmount = isDebit ? -this.amount : this.amount;
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public float getAmount() { return amount; }
    public boolean isDebit() { return isDebit; }
    public LocalDate getCreatedDate() { return createdDate; }
    public LocalDate getLastModifiedDate() { return lastModifiedDate; }
    public float getAppliedAmount() { return appliedAmount; }

    public void setName(String name) { this.name = name; }
    public void setLastModifiedDate(LocalDate date) { this.lastModifiedDate = date; }

    // Updates this model and returns the balance delta to apply externally.
    public float applyUpdate(float newAmount, boolean newIsDebit) {
        newAmount = Math.abs(newAmount);
        float newApplied = newIsDebit ? -newAmount : newAmount;
        float delta = newApplied - appliedAmount;
        this.amount = newAmount;
        this.isDebit = newIsDebit;
        this.appliedAmount = newApplied;
        this.lastModifiedDate = LocalDate.now();
        return delta;
    }

    // True when today is on or after lastModifiedDate + expiryDays.
    public boolean isExpired(int expiryDays) {
        return !LocalDate.now().isBefore(lastModifiedDate.plusDays(expiryDays));
    }
}
