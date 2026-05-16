from django.urls import path

from .views import (
    FrequentPlaceListCreateAPIView,
    HabitListCreateAPIView,
    HealthCheckAPIView,
    ProfileAPIView,
    RegisterAPIView,
)

urlpatterns = [
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("profile/", ProfileAPIView.as_view(), name="profile"),
    path("habits/", HabitListCreateAPIView.as_view(), name="habits"),
    path("frequent-places/", FrequentPlaceListCreateAPIView.as_view(), name="frequent-places"),
    path("health/", HealthCheckAPIView.as_view(), name="accounts-health"),
]
