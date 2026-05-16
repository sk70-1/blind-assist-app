from django.urls import path

from .views import (
    DangerousLocationListCreateAPIView,
    NavigationSessionListCreateAPIView,
    SavedRouteListCreateAPIView,
)

urlpatterns = [
    path("saved-routes/", SavedRouteListCreateAPIView.as_view(), name="saved-routes"),
    path("sessions/", NavigationSessionListCreateAPIView.as_view(), name="navigation-sessions"),
    path("dangerous-locations/", DangerousLocationListCreateAPIView.as_view(), name="dangerous-locations"),
]
