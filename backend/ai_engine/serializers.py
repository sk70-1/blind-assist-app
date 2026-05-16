from rest_framework import serializers

from .models import AISessionFrame, UserMemoryProfile


class AISessionFrameSerializer(serializers.ModelSerializer):
    class Meta:
        model = AISessionFrame
        fields = "__all__"
        read_only_fields = ("user", "frame_timestamp")


class UserMemoryProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserMemoryProfile
        fields = "__all__"
        read_only_fields = ("user", "updated_at")
