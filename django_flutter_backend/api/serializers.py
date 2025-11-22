from rest_framework import serializers
from .models import CustomUser, Task, UserAnswer

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('id', 'student_id', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            student_id=validated_data['student_id'],
            password=validated_data['password']
        )
        return user

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('student_id', 'nickname', 'age', 'sex', 'mbti', 'location', 'question1', 'question2', 'question3', 'volunteer_field')
        read_only_fields = ('student_id',)

    def validate_nickname(self, value):
        # Check if a user with this nickname already exists
        # Exclude the current user if it's an update operation
        if self.instance:
            if CustomUser.objects.filter(nickname=value).exclude(id=self.instance.id).exists():
                raise serializers.ValidationError("This nickname is already in use by another user.")
        else:
            if CustomUser.objects.filter(nickname=value).exists():
                raise serializers.ValidationError("This nickname is already in use.")
        return value

class VolunteerSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('nickname', 'age', 'sex', 'mbti', 'location', 'volunteer_field')

class TaskSerializer(serializers.ModelSerializer):

    class Meta:

        model = Task

        fields = ('id', 'title', 'completed')





class VolunteerSearchRequestSerializer(serializers.Serializer):

    volunteer_field = serializers.CharField(max_length=255, required=True)


class UserQuestionsSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('question1', 'question2', 'question3')


class SingleAnswerSerializer(serializers.Serializer):
    question_owner_nickname = serializers.CharField(max_length=100)
    question_number = serializers.IntegerField(min_value=1, max_value=3)
    answer_text = serializers.CharField()

    def validate(self, data):
        try:
            question_owner = CustomUser.objects.get(nickname=data['question_owner_nickname'])
            data['question_owner'] = question_owner
        except CustomUser.DoesNotExist:
            raise serializers.ValidationError("Question owner with this nickname does not exist.")

        question_field = f'question{data["question_number"]}'
        if not getattr(question_owner, question_field):
            raise serializers.ValidationError(f"Question {data['question_number']} does not exist for this user.")

        return data


class AnswerBatchCreationSerializer(serializers.ListSerializer):
    child = SingleAnswerSerializer()

    def create(self, validated_data):
        answers = []
        for item in validated_data:
            answers.append(UserAnswer(
                question_owner=item['question_owner'],
                answerer=self.context['request'].user,
                question_number=item['question_number'],
                answer_text=item['answer_text']
            ))
        return UserAnswer.objects.bulk_create(answers)


class AnswerDisplaySerializer(serializers.ModelSerializer):
    answerer_nickname = serializers.CharField(source='answerer.nickname', read_only=True)

    class Meta:
        model = UserAnswer
        fields = ('id', 'answerer_nickname', 'question_number', 'answer_text', 'timestamp')


class DocumentUploadSerializer(serializers.Serializer):
    document = serializers.FileField()


class VerificationResultSerializer(serializers.Serializer):
    status = serializers.CharField(max_length=50)
    message = serializers.CharField()
    resident_reg_no_verified = serializers.BooleanField(default=False)
    sex_verified = serializers.BooleanField(default=False)
    student_id_admission_year_verified = serializers.BooleanField(default=False)
    discrepancies = serializers.ListField(child=serializers.CharField(), required=False)
