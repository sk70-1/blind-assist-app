from django.contrib import admin
from django.urls import include, path
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/token/", TokenObtainPairView.as_view(permission_classes=[AllowAny]), name="token-obtain"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(permission_classes=[AllowAny]), name="token-refresh"),
    path("api/accounts/", include("accounts.urls")),
    path("api/navigation/", include("navigation.urls")),
    path("api/emergency/", include("emergency.urls")),
    path("api/ai/", include("ai_engine.urls")),
]
