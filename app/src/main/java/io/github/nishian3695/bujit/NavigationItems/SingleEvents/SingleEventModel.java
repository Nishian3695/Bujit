package io.github.nishian3695.bujit.NavigationItems.SingleEvents;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.UUID;

public class SingleEventModel implements Serializable {
    private static final long serialVersionUID = 2L;

    private String id;
    private String name;
    private float amount; // always positive
    private boolean isDebit; // true = reduces balance
    private final LocalDate createdDate;
    private LocalDate lastModifiedDate;
    private float appliedAmount; // signed delta already applied to the funding source
    private String targetType;        // "BALANCE", "MANUAL_ACCOUNT", or "CREDIT_CARD"
    private String targetId;          // null for BALANCE; account id or card name otherwise
    private String targetDisplayName; // human-readable name for display in the list

    public SingleEventModel(String name, float amount, boolean isDebit) {
        this.id = UUID.randomUUID().toString();
        this.name = name;
        this.amount = Math.abs(amount);
        this.isDebit = isDebit;
        this.createdDate = LocalDate.now();
        this.lastModifiedDate = LocalDate.now();
        this.appliedAmount = isDebit ? -this.amount : this.amount;
        this.targetType = "BALANCE";
        this.targetId = null;
        this.targetDisplayName = null;
    }

    public SingleEventModel(String id, String name, float amount, boolean isDebit,
                            LocalDate createdDate, LocalDate lastModifiedDate,
                            float appliedAmount, String targetType, String targetId,
                            String targetDisplayName) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.name = name;
        this.amount = Math.abs(amount);
        this.isDebit = isDebit;
        this.createdDate = createdDate != null ? createdDate : LocalDate.now();
        this.lastModifiedDate = lastModifiedDate != null ? lastModifiedDate : LocalDate.now();
        this.appliedAmount = appliedAmount;
        this.targetType = targetType != null ? targetType : "BALANCE";
        this.targetId = targetId;
        this.targetDisplayName = targetDisplayName;
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public float getAmount() { return amount; }
    public boolean isDebit() { return isDebit; }
    public LocalDate getCreatedDate() { return createdDate; }
    public LocalDate getLastModifiedDate() { return lastModifiedDate; }
    public float getAppliedAmount() { return appliedAmount; }
    public String getTargetType() { return targetType; }
    public String getTargetId() { return targetId; }
    public String getTargetDisplayName() { return targetDisplayName; }

    public void setName(String name) { this.name = name; }
    public void setLastModifiedDate(LocalDate date) { this.lastModifiedDate = date; }
    public void setTargetType(String targetType) { this.targetType = targetType; }
    public void setTargetId(String targetId) { this.targetId = targetId; }
    public void setTargetDisplayName(String name) { this.targetDisplayName = name; }

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
