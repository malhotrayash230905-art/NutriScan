from django.db import models
from django.conf import settings


class HealthMetrics(models.Model):
    """Stores the latest health dashboard metrics per user."""
    user         = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='metrics')

    # Hydration
    hydration_current = models.FloatField(default=0)   # litres
    hydration_goal    = models.FloatField(default=3)

    # Calories
    calories_consumed = models.IntegerField(default=0)
    calories_goal     = models.IntegerField(default=2200)

    # Scores & vitals
    health_score  = models.IntegerField(default=0)     # /100
    hemoglobin    = models.FloatField(default=0)       # g/dL
    blood_glucose = models.IntegerField(default=0)     # mg/dL
    vitamin_d     = models.FloatField(default=0)       # ng/mL
    heart_rate    = models.IntegerField(default=0)     # bpm
    blood_pressure_systolic  = models.IntegerField(default=0)
    blood_pressure_diastolic = models.IntegerField(default=0)
    cholesterol   = models.IntegerField(default=0)     # mg/dL
    sleep_hours   = models.FloatField(default=0)

    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Metrics({self.user.email})"


class Report(models.Model):
    """Stores uploaded medical report history."""
    REPORT_TYPES = [
        ('blood_test',   'Blood Test'),
        ('urine_test',   'Urine Test'),
        ('xray',         'X-Ray'),
        ('mri',          'MRI'),
        ('ultrasound',   'Ultrasound'),
        ('other',        'Other'),
    ]

    STATUS_CHOICES = [
        ('pending',    'Pending'),
        ('processed',  'Processed'),
        ('failed',     'Failed'),
    ]

    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports')
    title       = models.CharField(max_length=200)
    report_type = models.CharField(max_length=50, choices=REPORT_TYPES, default='other')
    file        = models.FileField(upload_to='reports/%Y/%m/', blank=True, null=True)
    notes       = models.TextField(blank=True)
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    # AI-extracted summary stored as JSON text
    ai_summary  = models.TextField(blank=True)

    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.user.email})"
