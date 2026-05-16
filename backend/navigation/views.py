from rest_framework import generics

from .models import DangerousLocation, NavigationSession, SavedRoute
from .serializers import DangerousLocationSerializer, NavigationSessionSerializer, SavedRouteSerializer


class SavedRouteListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = SavedRouteSerializer

    def get_queryset(self):
        return SavedRoute.objects.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class NavigationSessionListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = NavigationSessionSerializer

    def get_queryset(self):
        return NavigationSession.objects.filter(user=self.request.user).order_by("-started_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DangerousLocationListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = DangerousLocationSerializer

    def get_queryset(self):
        return DangerousLocation.objects.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
