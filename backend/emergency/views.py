from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EmergencyContact, EmergencyEvent
from .serializers import EmergencyContactSerializer, EmergencyEventSerializer


class EmergencyContactListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = EmergencyContactSerializer

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class EmergencyEventListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = EmergencyEventSerializer

    def get_queryset(self):
        return EmergencyEvent.objects.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TriggerSOSAPIView(APIView):
    def post(self, request):
        serializer = EmergencyEventSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user, is_resolved=False)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
