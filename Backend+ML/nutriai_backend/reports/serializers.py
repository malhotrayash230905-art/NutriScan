import json
from rest_framework import serializers
from .models import HealthMetrics, Report


class HealthMetricsSerializer(serializers.ModelSerializer):
    blood_pressure = serializers.SerializerMethodField()

    class Meta:
        model  = HealthMetrics
        exclude = ['user', 'blood_pressure_systolic', 'blood_pressure_diastolic']

    def get_blood_pressure(self, obj):
        return f"{obj.blood_pressure_systolic}/{obj.blood_pressure_diastolic}"

    def to_internal_value(self, data):
        # Accept "120/80" format for blood_pressure
        if 'blood_pressure' in data:
            try:
                systolic, diastolic = data['blood_pressure'].split('/')
                data = data.copy()
                data['blood_pressure_systolic']  = int(systolic.strip())
                data['blood_pressure_diastolic'] = int(diastolic.strip())
            except (ValueError, AttributeError):
                pass
        return super().to_internal_value(data)


class ReportSerializer(serializers.ModelSerializer):
    ai_summary_parsed = serializers.SerializerMethodField()
    file_url          = serializers.SerializerMethodField()

    class Meta:
        model  = Report
        fields = [
            'id', 'title', 'report_type', 'file', 'file_url',
            'notes', 'status', 'ai_summary', 'ai_summary_parsed',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'ai_summary', 'ai_summary_parsed', 'created_at', 'updated_at', 'file_url']

    def get_ai_summary_parsed(self, obj):
        if obj.ai_summary:
            try:
                return json.loads(obj.ai_summary)
            except json.JSONDecodeError:
                return obj.ai_summary
        return None

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return None


class ReportListSerializer(serializers.ModelSerializer):
    """Lighter serializer for list view."""
    class Meta:
        model  = Report
        fields = ['id', 'title', 'report_type', 'status', 'created_at']
