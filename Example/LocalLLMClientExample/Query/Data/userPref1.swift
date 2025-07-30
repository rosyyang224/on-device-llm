//
//  userPref_1.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/30/25.
//

let userPref1 = """
{
  "user_id": "user_456def",
  "session_id": "sess_789abc123",
  "timestamp": "2025-07-30T08:32:15.234Z",
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
  "ip_address": "192.168.1.100",
  "activities": [
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:32:15.234Z",
      "properties": {
        "url": "/homepage",
        "title": "Portfolio Homepage",
        "referrer": "direct"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:32:47.567Z",
      "properties": {
        "chart_type": "pie_chart",
        "chart_name": "asset_allocation",
        "action": "click",
        "label": "US Equities"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:33:12.890Z",
      "properties": {
        "tab": "holdings",
        "previous_tab": "homepage"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:33:13.123Z",
      "properties": {
        "url": "/holdings",
        "title": "Portfolio Holdings",
        "referrer": "/homepage"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T08:33:45.456Z",
      "properties": {
        "filter": "asset_class",
        "value": "us_equity",
        "previous_filter": "all"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:34:02.789Z",
      "properties": {
        "column": "market_value",
        "direction": "desc",
        "table": "holdings_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:34:25.123Z",
      "properties": {
        "row_id": "AAPL",
        "label": "Apple Inc.",
        "row_type": "holding",
        "value": "$45,230.50"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:34:26.234Z",
      "properties": {
        "url": "/holdings/details/AAPL",
        "title": "AAPL Holding Details",
        "referrer": "/holdings"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:35:12.567Z",
      "properties": {
        "tab": "performance_graphs",
        "context": "holding_detail"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:35:45.890Z",
      "properties": {
        "action": "select_date_range",
        "start_date": "2025-01-01",
        "end_date": "2025-07-30",
        "period_type": "ytd"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:36:22.123Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "price_performance",
        "action": "zoom",
        "label": "AAPL"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:37:05.456Z",
      "properties": {
        "tab": "transactions",
        "context": "holding_detail"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:37:33.789Z",
      "properties": {
        "column": "transaction_date",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T08:38:15.123Z",
      "properties": {
        "from": "/holdings/details/AAPL",
        "to": "/holdings",
        "method": "back_button"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:38:22.456Z",
      "properties": {
        "row_id": "MSFT",
        "label": "Microsoft Corp.",
        "row_type": "holding",
        "value": "$32,150.75"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:38:23.567Z",
      "properties": {
        "url": "/holdings/details/MSFT",
        "title": "MSFT Holding Details",
        "referrer": "/holdings"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:39:10.890Z",
      "properties": {
        "tab": "performance_graphs",
        "context": "holding_detail"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:39:45.123Z",
      "properties": {
        "action": "select_preset",
        "period_type": "6m",
        "start_date": "2025-01-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:40:22.456Z",
      "properties": {
        "tab": "asset_class",
        "previous_tab": "holdings"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:40:23.567Z",
      "properties": {
        "url": "/asset-class",
        "title": "Asset Class Breakdown",
        "referrer": "/holdings/details/MSFT"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:40:55.890Z",
      "properties": {
        "chart_type": "pie_chart",
        "chart_name": "asset_class_allocation",
        "action": "click",
        "label": "US Domestic Equity"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T08:41:30.123Z",
      "properties": {
        "filter": "geography",
        "value": "us_domestic",
        "context": "asset_class_view"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:42:15.456Z",
      "properties": {
        "tab": "homepage",
        "previous_tab": "asset_class"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:42:16.567Z",
      "properties": {
        "url": "/homepage",
        "title": "Portfolio Homepage",
        "referrer": "/asset-class"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:42:45.890Z",
      "properties": {
        "chart_type": "pie_chart",
        "chart_name": "sector_allocation",
        "action": "click",
        "label": "Technology"
      }
    },
    {
      "event": "search",
      "timestamp": "2025-07-30T08:43:22.123Z",
      "properties": {
        "query": "NVDA",
        "type": "holding_lookup",
        "results": 1
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:43:25.456Z",
      "properties": {
        "row_id": "NVDA",
        "label": "NVIDIA Corp.",
        "row_type": "search_result"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:43:26.567Z",
      "properties": {
        "url": "/holdings/details/NVDA",
        "title": "NVDA Holding Details",
        "referrer": "/homepage"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:44:10.890Z",
      "properties": {
        "tab": "transactions",
        "context": "holding_detail"
      }
    },
    {
      "event": "export",
      "timestamp": "2025-07-30T08:44:55.123Z",
      "properties": {
        "type": "holdings_summary",
        "format": "csv",
        "filter": "us_equities_only",
        "context": "transactions_view"
      }
    },
    {
      "event": "session_end",
      "timestamp": "2025-07-30T08:45:12.456Z",
      "properties": {
        "duration_sec": 777
      }
    }
  ]
}
"""
