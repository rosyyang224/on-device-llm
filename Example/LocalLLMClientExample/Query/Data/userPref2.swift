let userActivityLog2 = """
{
  "user_id": "user_123ghi",
  "session_id": "sess_456def789",
  "timestamp": "2025-07-30T09:15:22.345Z",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
  "ip_address": "192.168.1.150",
  "activities": [
    {
      "event": "page_view",
      "timestamp": "2025-07-30T09:15:22.345Z",
      "properties": {
        "url": "/homepage",
        "title": "Portfolio Homepage",
        "referrer": "direct"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T09:15:45.567Z",
      "properties": {
        "tab": "performance_graphs",
        "previous_tab": "homepage"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T09:15:46.123Z",
      "properties": {
        "url": "/performance",
        "title": "Portfolio Performance",
        "referrer": "/homepage"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T09:16:15.789Z",
      "properties": {
        "action": "select_preset",
        "period_type": "1y",
        "start_date": "2024-07-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:16:45.234Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "portfolio_value_over_time",
        "action": "zoom_in",
        "time_range": "6m"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:17:22.567Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "portfolio_value_over_time",
        "action": "hover_datapoint",
        "date": "2025-03-15",
        "value": "$487,250.00"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:17:55.890Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "portfolio_value_over_time",
        "action": "hover_datapoint",
        "date": "2025-06-01",
        "value": "$512,830.75"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T09:18:33.123Z",
      "properties": {
        "filter": "comparison_benchmark",
        "value": "sp500",
        "context": "performance_comparison"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:19:10.456Z",
      "properties": {
        "chart_type": "dual_line_chart",
        "chart_name": "portfolio_vs_benchmark",
        "action": "toggle_series",
        "series": "benchmark_line"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T09:19:45.789Z",
      "properties": {
        "action": "select_preset",
        "period_type": "3y",
        "start_date": "2022-07-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:20:22.123Z",
      "properties": {
        "chart_type": "dual_line_chart",
        "chart_name": "portfolio_vs_benchmark",
        "action": "zoom_to_period",
        "start_date": "2024-01-01",
        "end_date": "2024-12-31"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T09:21:05.456Z",
      "properties": {
        "filter": "performance_metric",
        "value": "total_return_percentage",
        "previous_value": "absolute_value"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:21:40.789Z",
      "properties": {
        "chart_type": "area_chart",
        "chart_name": "cumulative_returns",
        "action": "hover_datapoint",
        "date": "2024-11-15",
        "portfolio_return": "18.7%",
        "benchmark_return": "12.3%"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T09:22:18.123Z",
      "properties": {
        "action": "select_custom_range",
        "start_date": "2024-01-01",
        "end_date": "2025-01-01",
        "period_type": "custom"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:23:02.456Z",
      "properties": {
        "chart_type": "volatility_chart",
        "chart_name": "rolling_volatility",
        "action": "change_window",
        "window_size": "30d"
      }
    },
    {
      "event": "export",
      "timestamp": "2025-07-30T09:23:45.789Z",
      "properties": {
        "type": "performance_data",
        "format": "csv",
        "date_range": "2024-01-01_to_2025-01-01",
        "metrics": ["total_return", "volatility", "sharpe_ratio"]
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T09:24:20.123Z",
      "properties": {
        "filter": "time_granularity",
        "value": "monthly",
        "previous_value": "daily"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:24:55.456Z",
      "properties": {
        "chart_type": "bar_chart",
        "chart_name": "monthly_returns",
        "action": "hover_bar",
        "month": "2024-12",
        "return_value": "3.2%"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T09:25:30.789Z",
      "properties": {
        "action": "select_preset",
        "period_type": "5y",
        "start_date": "2020-07-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:26:10.123Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "long_term_performance",
        "action": "identify_trend",
        "trend_period": "2020-2025",
        "cagr": "11.4%"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T09:26:50.456Z",
      "properties": {
        "filter": "drawdown_analysis",
        "value": "enabled",
        "max_drawdown_period": "2022-03-15_to_2022-10-12"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:27:25.789Z",
      "properties": {
        "chart_type": "drawdown_chart",
        "chart_name": "portfolio_drawdowns",
        "action": "hover_peak_to_trough",
        "max_drawdown": "-23.7%",
        "recovery_date": "2023-01-20"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T09:28:05.123Z",
      "properties": {
        "tab": "homepage",
        "previous_tab": "performance_graphs"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T09:28:06.234Z",
      "properties": {
        "url": "/homepage",
        "title": "Portfolio Homepage",
        "referrer": "/performance"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:28:20.567Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "homepage_performance_summary",
        "action": "hover_recent_trend",
        "period": "last_30d",
        "return": "2.1%"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T09:28:45.890Z",
      "properties": {
        "tab": "performance_graphs",
        "previous_tab": "homepage"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T09:29:15.123Z",
      "properties": {
        "action": "select_preset",
        "period_type": "ytd",
        "start_date": "2025-01-01",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "export",
      "timestamp": "2025-07-30T09:29:50.456Z",
      "properties": {
        "type": "trend_analysis_report",
        "format": "pdf",
        "includes": ["performance_charts", "benchmark_comparison", "volatility_metrics"],
        "time_period": "ytd"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T09:30:25.789Z",
      "properties": {
        "chart_type": "correlation_heatmap",
        "chart_name": "asset_correlation_over_time",
        "action": "select_time_window",
        "window": "rolling_12m"
      }
    },
    {
      "event": "session_end",
      "timestamp": "2025-07-30T09:31:10.123Z",
      "properties": {
        "duration_sec": 948
      }
    }
  ]
}
"""
