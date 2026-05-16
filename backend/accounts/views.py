from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import FrequentlyVisitedPlace, UserHabit
from .serializers import (
    FrequentlyVisitedPlaceSerializer,
    UserHabitSerializer,
    UserProfileSerializer,
    UserRegistrationSerializer,
)

User = get_user_model()


class RegisterAPIView(generics.CreateAPIView):
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]


class ProfileAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer

    def get_object(self):
        return self.request.user


class HabitListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = UserHabitSerializer

    def get_queryset(self):
        return UserHabit.objects.filter(user=self.request.user).order_by("-updated_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class FrequentPlaceListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = FrequentlyVisitedPlaceSerializer

    def get_queryset(self):
        return FrequentlyVisitedPlace.objects.filter(user=self.request.user).order_by("-visit_count")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class HealthCheckAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response({"status": "ok", "service": "accounts"})
