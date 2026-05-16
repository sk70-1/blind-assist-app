from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import FrequentlyVisitedPlace, UserHabit

User = get_user_model()


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "username",
            "password",
            "phone_number",
            "preferred_language",
            "voice_gender",
        )

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        exclude = ("password", "groups", "user_permissions")
        read_only_fields = ("id", "last_login", "date_joined", "is_staff", "is_superuser")


class UserHabitSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserHabit
        fields = "__all__"
        read_only_fields = ("user",)


class FrequentlyVisitedPlaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = FrequentlyVisitedPlace
        fields = "__all__"
        read_only_fields = ("user",)
