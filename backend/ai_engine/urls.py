from django.urls import path

from .views import AISessionFrameListCreateAPIView, MockRealtimeInferenceAPIView, UserMemoryProfileAPIView

urlpatterns = [
    path("frames/", AISessionFrameListCreateAPIView.as_view(), name="ai-frames"),
    path("memory/", UserMemoryProfileAPIView.as_view(), name="ai-memory"),
    path("inference/mock/", MockRealtimeInferenceAPIView.as_view(), name="ai-inference"),
]
