from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.translation import gettext_lazy as _


class CustomUserManager(BaseUserManager):
    """Define a model manager for User model with no username field."""

    def _create_user(self, student_id, password=None, **extra_fields):
        """Create and save a User with the given student_id and password."""
        if not student_id:
            raise ValueError(_('The Student ID must be set'))
        user = self.model(student_id=student_id, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, student_id, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(student_id, password, **extra_fields)

    def create_superuser(self, student_id, password=None, **extra_fields):
        """Create and save a SuperUser with the given student_id and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))

        return self._create_user(student_id, password, **extra_fields)


class CustomUser(AbstractUser):
    username = None
    student_id = models.CharField(_('student ID'), unique=True, max_length=20)
    nickname = models.CharField(max_length=100, blank=True)
    age = models.PositiveIntegerField(null=True, blank=True)
    sex = models.CharField(max_length=10, blank=True)
    mbti = models.CharField(max_length=10, blank=True)
    location = models.CharField(max_length=100, blank=True)
    question1 = models.CharField(max_length=255, blank=True, null=True)
    question2 = models.CharField(max_length=255, blank=True, null=True)
    question3 = models.CharField(max_length=255, blank=True, null=True)
    volunteer_field = models.CharField(max_length=255, blank=True, null=True)

    USERNAME_FIELD = 'student_id'
    REQUIRED_FIELDS = []

    objects = CustomUserManager()

    def __str__(self):
        return self.student_id

class Task(models.Model):
    title = models.CharField(max_length=200)
    completed = models.BooleanField(default=False)

    def __str__(self):
        return self.title

class UserAnswer(models.Model):
    question_owner = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='received_answers'
    )
    answerer = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='given_answers'
    )
    question_number = models.IntegerField(choices=[(1, 'Question 1'), (2, 'Question 2'), (3, 'Question 3')])
    answer_text = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('question_owner', 'answerer', 'question_number')
        ordering = ['timestamp']

    def __str__(self):
        return f"{self.answerer.student_id} answered {self.question_owner.student_id}'s question {self.question_number}"
