from django.contrib.auth import get_user_model
from rest_framework import generics, status, viewsets
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
import subprocess
import json
import os
import re # Import re module
from .models import Task, UserAnswer
from .serializers import (
    TaskSerializer, UserSerializer, UserProfileSerializer, VolunteerSearchSerializer, VolunteerSearchRequestSerializer, UserQuestionsSerializer,
    SingleAnswerSerializer, AnswerBatchCreationSerializer, AnswerDisplaySerializer, DocumentUploadSerializer, VerificationResultSerializer
)

CustomUser = get_user_model()

class SignupView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        user = serializer.instance
        token, created = Token.objects.get_or_create(user=user)
        return Response({'token': token.key}, status=status.HTTP_201_CREATED)


class LoginView(generics.GenericAPIView):
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        student_id = request.data.get('student_id')
        password = request.data.get('password')
        user = CustomUser.objects.filter(student_id=student_id).first()
        if user and user.check_password(password):
            token, created = Token.objects.get_or_create(user=user)
            return Response({'token': token.key})
        return Response({'error': 'Invalid Credentials'}, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserQuestionsView(generics.RetrieveAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = UserQuestionsSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'nickname'


class AnswerQuestionView(generics.CreateAPIView):
    serializer_class = AnswerBatchCreationSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        for validated_item in serializer.validated_data:
            question_owner = validated_item['question_owner']
            question_number = validated_item['question_number']
            answer_text = validated_item['answer_text']

            if question_owner == self.request.user:
                raise generics.ValidationError("You cannot answer your own questions.")
            
            UserAnswer.objects.update_or_create(
                question_owner=question_owner,
                answerer=self.request.user,
                question_number=question_number,
                defaults={'answer_text': answer_text}
            )


class ReceivedAnswersListView(generics.ListAPIView):
    serializer_class = AnswerDisplaySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserAnswer.objects.filter(question_owner=self.request.user)


class DocumentVerificationView(generics.GenericAPIView):
    serializer_class = DocumentUploadSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        document_file = serializer.validated_data['document']
        user_student_id = request.user.student_id # Get current user's student_id

        temp_pdf_path = os.path.join('/tmp', document_file.name)
        with open(temp_pdf_path, 'wb+') as destination:
            for chunk in document_file.chunks():
                destination.write(chunk)

        verification_results = {
            "status": "failed",
            "message": "Verification failed due to extraction errors or mismatches.",
            "resident_reg_no_verified": False,
            "student_id_admission_year_verified": False,
            "discrepancies": []
        }

        try:
            process = subprocess.run(
                ['python', 'real.py', temp_pdf_path],
                capture_output=True, text=True, check=True
            )
            ocr_output = json.loads(process.stdout)
            extracted_rrn = ocr_output.get('resident_reg_no')
            extracted_admission_date = ocr_output.get('admission_date')

            all_verified = True
            discrepancies = []

            # 1. Verify resident_reg_no for format only (sex verification removed)
            if extracted_rrn:
                rrn_match = re.match(r'^(\d{6})\s*[-—]\s*([1-4])', extracted_rrn)
                if rrn_match:
                    verification_results["resident_reg_no_verified"] = True
                else:
                    all_verified = False
                    discrepancies.append("Could not parse resident registration number from document or incorrect format.")
            else:
                all_verified = False
                discrepancies.append("Resident registration number not found in document.")

            # 2. Verify admission_date with user's student_id year
            if extracted_admission_date and user_student_id:
                admission_year_match = re.search(r'(\d{4})년', extracted_admission_date)
                student_id_year_match = re.match(r'^(\d{4})', user_student_id)

                if admission_year_match and student_id_year_match:
                    admission_year = admission_year_match.group(1)
                    admission_year_two_digits = admission_year[-2:]
                    student_id_two_digits = user_student_id[2:4]

                    if admission_year_two_digits == student_id_two_digits:
                        verification_results["student_id_admission_year_verified"] = True
                    else:
                        all_verified = False
                        discrepancies.append(f"Admission year ({admission_year_two_digits}) from document does not match student ID year ({student_id_two_digits}).")
                else:
                    all_verified = False
                    discrepancies.append("Could not parse admission year from document or student ID.")
            else:
                all_verified = False
                discrepancies.append("Admission date or user student ID not found.")

            verification_results["status"] = "success" if all_verified else "failed"
            verification_results["message"] = "Verification successful." if all_verified else "Verification failed with discrepancies."
            verification_results["discrepancies"] = discrepancies

        except subprocess.CalledProcessError as e:
            verification_results["message"] = f"OCR script failed: {e.stderr}"
            all_verified = False
        except json.JSONDecodeError:
            verification_results["message"] = "Failed to parse OCR script output."
            all_verified = False
        except Exception as e:
            verification_results["message"] = f"An unexpected error occurred: {str(e)}"
            all_verified = False
        finally:
            if os.path.exists(temp_pdf_path):
                os.remove(temp_pdf_path)

        return Response(VerificationResultSerializer(verification_results).data, status=status.HTTP_200_OK if all_verified else status.HTTP_400_BAD_REQUEST)


class VolunteerSearchView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = VolunteerSearchRequestSerializer

    def post(self, request, *args, **kwargs):
        input_serializer = self.get_serializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        requested_volunteer_field = input_serializer.validated_data['volunteer_field']

        user = request.user
        queryset = CustomUser.objects.filter(
            volunteer_field__iexact=requested_volunteer_field
        ).exclude(id=user.id)

        output_serializer = VolunteerSearchSerializer(queryset, many=True)
        return Response(output_serializer.data, status=status.HTTP_200_OK)


class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer