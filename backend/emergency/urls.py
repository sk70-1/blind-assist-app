from django.urls import path

from .views import EmergencyContactListCreateAPIView, EmergencyEventListCreateAPIView, TriggerSOSAPIView

urlpatterns = [
    path("contacts/", EmergencyContactListCreateAPIView.as_view(), name="emergency-contacts"),
    path("events/", EmergencyEventListCreateAPIView.as_view(), name="emergency-events"),
    path("sos/", TriggerSOSAPIView.as_view(), name="emergency-sos"),
]
