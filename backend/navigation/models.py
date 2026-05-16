from django.conf import settings
from django.db import models


class SavedRoute(models.Model):
    class Mode(models.TextChoices):
        INDOOR = "indoor", "Indoor"
        OUTDOOR = "outdoor", "Outdoor"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="saved_routes")
    name = models.CharField(max_length=120)
    mode = models.CharField(max_length=20, choices=Mode.choices)
    source_name = models.CharField(max_length=120)
    destination_name = models.CharField(max_length=120)
    source_latitude = models.FloatField(null=True, blank=True)
    source_longitude = models.FloatField(null=True, blank=True)
    destination_latitude = models.FloatField(null=True, blank=True)
    destination_longitude = models.FloatField(null=True, blank=True)
    path_metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class NavigationSession(models.Model):
    class SessionState(models.TextChoices):
        ACTIVE = "active", "Active"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="navigation_sessions")
    mode = models.CharField(max_length=20, choices=SavedRoute.Mode.choices)
    state = models.CharField(max_length=20, choices=SessionState.choices, default=SessionState.ACTIVE)
    current_latitude = models.FloatField(null=True, blank=True)
    current_longitude = models.FloatField(null=True, blank=True)
    destination_label = models.CharField(max_length=120)
    guidance_payload = models.JSONField(default=dict, blank=True)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)


class DangerousLocation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="dangerous_locations")
    label = models.CharField(max_length=120)
    latitude = models.FloatField()
    longitude = models.FloatField()
    risk_level = models.PositiveSmallIntegerField(default=1)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
