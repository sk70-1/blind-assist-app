from rest_framework import serializers

from .models import DangerousLocation, NavigationSession, SavedRoute


class SavedRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedRoute
        fields = "__all__"
        read_only_fields = ("user", "created_at")


class NavigationSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = NavigationSession
        fields = "__all__"
        read_only_fields = ("user", "started_at")


class DangerousLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DangerousLocation
        fields = "__all__"
        read_only_fields = ("user", "created_at")
