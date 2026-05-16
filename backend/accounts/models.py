import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        USER = "user", "User"
        GUARDIAN = "guardian", "Guardian"
        ADMIN = "admin", "Admin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, blank=True)
    preferred_language = models.CharField(max_length=30, default="en")
    voice_gender = models.CharField(max_length=20, default="neutral")
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.USER)
    home_location_name = models.CharField(max_length=120, blank=True)
    work_location_name = models.CharField(max_length=120, blank=True)
    home_latitude = models.FloatField(null=True, blank=True)
    home_longitude = models.FloatField(null=True, blank=True)
    work_latitude = models.FloatField(null=True, blank=True)
    work_longitude = models.FloatField(null=True, blank=True)
    is_verified = models.BooleanField(default=False)
    disability_proof = models.FileField(upload_to="proofs/disability/", null=True, blank=True)
    identity_proof = models.FileField(upload_to="proofs/identity/", null=True, blank=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]


class UserHabit(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="habits")
    label = models.CharField(max_length=100)
    route_pattern = models.TextField(blank=True)
    preferred_walking_speed = models.FloatField(default=1.0)
    preferred_walking_style = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class FrequentlyVisitedPlace(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="frequent_places")
    name = models.CharField(max_length=120)
    latitude = models.FloatField()
    longitude = models.FloatField()
    visit_count = models.PositiveIntegerField(default=1)
    is_dangerous = models.BooleanField(default=False)
    last_visited = models.DateTimeField(null=True, blank=True)
