from django.urls import path
from .views import HealthMetricsView, ReportListCreateView, ReportDetailView, ReportStatsView

urlpatterns = [
    # Health metrics (dashboard data)
    path('metrics/',         HealthMetricsView.as_view(),      name='health-metrics'),

    # Report history
    path('',                 ReportListCreateView.as_view(),   name='report-list-create'),
    path('<int:pk>/',        ReportDetailView.as_view(),       name='report-detail'),
    path('stats/',           ReportStatsView.as_view(),        name='report-stats'),
]
