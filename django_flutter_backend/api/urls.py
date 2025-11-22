from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet, SignupView, LoginView, UserProfileView, VolunteerSearchView, UserQuestionsView, AnswerQuestionView, ReceivedAnswersListView, DocumentVerificationView

# Create a router and register our ViewSet with it.
router = DefaultRouter()
router.register(r'tasks', TaskViewSet)

# The API URLs are now determined automatically by the router.
urlpatterns = [
    path('', include(router.urls)),
    path('signup/', SignupView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
    path('user-profile/', UserProfileView.as_view(), name='user-profile'),
    path('volunteer-search/', VolunteerSearchView.as_view(), name='volunteer-search'),
    path('users/<str:nickname>/questions/', UserQuestionsView.as_view(), name='user-questions'),
    path('answer-question/', AnswerQuestionView.as_view(), name='answer-question'),
    path('my-answers/', ReceivedAnswersListView.as_view(), name='my-answers'),
    path('verify-document/', DocumentVerificationView.as_view(), name='verify-document'),
]