from django.conf import settings
from django.db import models


class EmergencyContact(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="emergency_contacts")
    name = models.CharField(max_length=120)
    relation = models.CharField(max_length=80, blank=True)
    phone_number = models.CharField(max_length=20)
    email = models.EmailField(blank=True)
    is_primary = models.BooleanField(default=False)


class EmergencyEvent(models.Model):
    class TriggerType(models.TextChoices):
        MANUAL = "manual", "Manual"
        FALL_DETECTED = "fall_detected", "FallDetected"
        INACTIVITY = "inactivity", "Inactivity"
        DANGEROUS_MOVEMENT = "dangerous_movement", "DangerousMovement"
        LOW_BATTERY = "low_battery", "LowBattery"
        CAMERA_FAILURE = "camera_failure", "CameraFailure"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="emergency_events")
    trigger_type = models.CharField(max_length=30, choices=TriggerType.choices)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    message = models.TextField()
    is_resolved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
