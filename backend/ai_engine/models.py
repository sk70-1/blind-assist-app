from django.conf import settings
from django.db import models


class AISessionFrame(models.Model):
    class Mode(models.TextChoices):
        INDOOR = "indoor", "Indoor"
        OUTDOOR = "outdoor", "Outdoor"
        CROSSWALK = "crosswalk", "Crosswalk"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="ai_frames")
    navigation_mode = models.CharField(max_length=20, choices=Mode.choices)
    frame_timestamp = models.DateTimeField(auto_now_add=True)
    detected_objects = models.JSONField(default=list, blank=True)
    crowd_density = models.FloatField(default=0.0)
    visibility_score = models.FloatField(default=1.0)
    actionable_guidance = models.TextField(blank=True)
    is_hazardous = models.BooleanField(default=False)


class UserMemoryProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="memory_profile")
    learned_routes = models.JSONField(default=list, blank=True)
    dangerous_spots = models.JSONField(default=list, blank=True)
    preferred_walking_speed = models.FloatField(default=1.0)
    preferred_walking_style = models.CharField(max_length=100, blank=True)
    frequent_transit_patterns = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
