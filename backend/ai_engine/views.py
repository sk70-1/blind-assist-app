from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AISessionFrame, UserMemoryProfile
from .serializers import AISessionFrameSerializer, UserMemoryProfileSerializer


class AISessionFrameListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = AISessionFrameSerializer

    def get_queryset(self):
        return AISessionFrame.objects.filter(user=self.request.user).order_by("-frame_timestamp")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserMemoryProfileAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = UserMemoryProfileSerializer

    def get_object(self):
        profile, _ = UserMemoryProfile.objects.get_or_create(user=self.request.user)
        return profile


class MockRealtimeInferenceAPIView(APIView):
    def post(self, request):
        detected_objects = request.data.get("detected_objects", [])
        hazard = any(obj.get("distance_m", 99) < 2 for obj in detected_objects if isinstance(obj, dict))
        guidance = "Obstacle nearby. Slow down and keep slightly left." if hazard else "Path appears safe ahead."
        return Response(
            {"is_hazardous": hazard, "guidance": guidance, "objects_count": len(detected_objects)},
            status=status.HTTP_200_OK,
        )
