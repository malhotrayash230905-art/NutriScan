import json
from rest_framework import generics, permissions, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .ml.diet_plan import generate_meal_plan

from .ml.extract import extract_values
from .ml.predict import predict_diet

from .models import HealthMetrics, Report
from .serializers import HealthMetricsSerializer, ReportSerializer, ReportListSerializer


# ─── Health Metrics ───────────────────────────────────────────────────────────

class HealthMetricsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        metrics, _ = HealthMetrics.objects.get_or_create(user=request.user)
        return Response(HealthMetricsSerializer(metrics).data)

    def patch(self, request):
        metrics, _ = HealthMetrics.objects.get_or_create(user=request.user)
        serializer = HealthMetricsSerializer(metrics, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


# ─── Reports / Report History ─────────────────────────────────────────────────

class ReportListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'report_type', 'notes']
    ordering_fields = ['created_at', 'title', 'report_type']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = Report.objects.filter(user=self.request.user)
        report_type = self.request.query_params.get('type')
        status_filter = self.request.query_params.get('status')

        if report_type:
            qs = qs.filter(report_type=report_type)

        if status_filter:
            qs = qs.filter(status=status_filter)

        return qs

    def get_serializer_class(self):
        if self.request.method == 'GET':
            return ReportListSerializer
        return ReportSerializer

    def perform_create(self, serializer):
        report = serializer.save(user=self.request.user)

        if report.file:
            self._process_report(report)

    def _process_report(self, report):
        try:
            file_path = report.file.path

            # Extract values
            values = extract_values(file_path)

            # Predict diet
            diet = predict_diet(values)
            meal_plan = generate_meal_plan(diet)

            # Human-friendly condition
            # Human-friendly condition
            condition = "Healthy"

            if values.get("hba1c") and values["hba1c"] >= 6.5:
                condition = "High Blood Sugar (Diabetic Risk)"
            elif values.get("glucose") and values["glucose"] > 150:
                condition = "Elevated Glucose Level"

            # Human-friendly recommendation text
            recommendation = []

            if diet.get("low_carb"):
                recommendation.append("Low Carbohydrate Diet")

            if diet.get("low_sugar"):
                recommendation.append("Low Sugar Diet")

            if diet.get("thyroid_diet"):
                recommendation.append("Thyroid-Support Diet")

            recommendation_text = " + ".join(recommendation)


            # --- HISTORY INSIGHT ---
            previous_reports = Report.objects.filter(user=report.user).exclude(id=report.id).order_by('-created_at')

            trend = "No previous data"

            if previous_reports.exists():
                prev = previous_reports.first()

                try:
                    prev_summary = json.loads(prev.ai_summary)
                    prev_values = prev_summary.get("extracted_values", {})

                    if prev_values.get("glucose") and values.get("glucose"):
                        if values["glucose"] > prev_values["glucose"]:
                            trend = "Glucose level has increased"
                        elif values["glucose"] < prev_values["glucose"]:
                            trend = "Glucose level has improved"
                        else:
                            trend = "Glucose level unchanged"
                except:
                    trend = "Previous data unavailable"
            

            # Store result
            summary = {
                    "status": "processed",
                    "condition": condition,
                    "recommendation": recommendation_text,
                    "trend": trend,
                    "extracted_values": values,
                    "diet_recommendation": diet,
                    "meal_plan": meal_plan
                }

            report.ai_summary = json.dumps(summary)
            report.status = 'processed'
            report.save(update_fields=['ai_summary', 'status'])

        except Exception as e:
            report.status = 'failed'
            report.ai_summary = json.dumps({
                "status": "failed",
                "error": str(e)
            })
            report.save(update_fields=['ai_summary', 'status'])


class ReportDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReportSerializer

    def get_queryset(self):
        return Report.objects.filter(user=self.request.user)

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx


class ReportStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Report.objects.filter(user=request.user)

        total = qs.count()

        by_type = {}
        for rt, _ in Report.REPORT_TYPES:
            count = qs.filter(report_type=rt).count()
            if count:
                by_type[rt] = count

        by_status = {
            'pending': qs.filter(status='pending').count(),
            'processed': qs.filter(status='processed').count(),
            'failed': qs.filter(status='failed').count(),
        }

        recent = ReportListSerializer(qs[:5], many=True).data

        return Response({
            'total': total,
            'by_type': by_type,
            'by_status': by_status,
            'recent': recent,
        })