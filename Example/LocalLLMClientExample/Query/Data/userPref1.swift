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
      "event": "tab_click",
      "timestamp": "2025-07-30T08:32:25.567Z",
      "properties": {
        "tab": "holdings",
        "previous_tab": "homepage"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:32:26.123Z",
      "properties": {
        "url": "/holdings",
        "title": "Portfolio Holdings",
        "referrer": "/homepage"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T08:32:45.456Z",
      "properties": {
        "filter": "assetclass",
        "value": "Equity",
        "previous_filter": "all"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T08:33:02.789Z",
      "properties": {
        "filter": "countryregion",
        "value": "United States",
        "previous_filter": "all"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:33:15.123Z",
      "properties": {
        "column": "totalmarketvalue",
        "direction": "desc",
        "table": "holdings_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:33:45.456Z",
      "properties": {
        "row_id": "AAPL",
        "symbol": "AAPL",
        "cusip": "037833100",
        "row_type": "holding",
        "totalmarketvalue": 45230.50,
        "assetclass": "Equity",
        "countryregion": "United States"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:33:46.567Z",
      "properties": {
        "url": "/holdings/details/037833100",
        "title": "AAPL Holding Details",
        "referrer": "/holdings",
        "symbol": "AAPL",
        "cusip": "037833100"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:34:15.890Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "marketprice_performance",
        "action": "hover",
        "symbol": "AAPL"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:34:35.123Z",
      "properties": {
        "action": "select_date_range",
        "start_date": "2025-01-01",
        "end_date": "2025-07-30",
        "period_type": "ytd"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T08:35:10.456Z",
      "properties": {
        "from": "/holdings/details/037833100",
        "to": "/holdings",
        "method": "back_button"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:35:25.789Z",
      "properties": {
        "row_id": "MSFT",
        "symbol": "MSFT",
        "cusip": "594918104",
        "row_type": "holding",
        "totalmarketvalue": 32150.75,
        "assetclass": "Equity",
        "countryregion": "United States"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:35:26.890Z",
      "properties": {
        "url": "/holdings/details/594918104",
        "title": "MSFT Holding Details",
        "referrer": "/holdings",
        "symbol": "MSFT",
        "cusip": "594918104"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:35:55.123Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "marketprice_performance",
        "action": "zoom",
        "symbol": "MSFT"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:36:15.456Z",
      "properties": {
        "action": "select_preset",
        "period_type": "1y",
        "start_date": "2024-07-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:36:45.789Z",
      "properties": {
        "tab": "transactions",
        "context": "holding_detail"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:37:05.123Z",
      "properties": {
        "column": "transactiondate",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T08:37:35.456Z",
      "properties": {
        "from": "/holdings/details/594918104",
        "to": "/holdings",
        "method": "back_button"
      }
    },
    {
      "event": "search",
      "timestamp": "2025-07-30T08:37:55.789Z",
      "properties": {
        "query": "GOOGL",
        "type": "symbol_lookup",
        "results": 1
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:38:05.123Z",
      "properties": {
        "row_id": "GOOGL",
        "symbol": "GOOGL",
        "cusip": "02079K305",
        "row_type": "holding",
        "totalmarketvalue": 28750.25,
        "assetclass": "Equity",
        "countryregion": "United States"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:38:06.234Z",
      "properties": {
        "url": "/holdings/details/02079K305",
        "title": "GOOGL Holding Details",
        "referrer": "/holdings",
        "symbol": "GOOGL",
        "cusip": "02079K305"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:38:35.567Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "marketprice_performance",
        "action": "hover",
        "symbol": "GOOGL"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:39:05.890Z",
      "properties": {
        "action": "select_preset",
        "period_type": "6m",
        "start_date": "2025-01-30",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T08:39:45.123Z",
      "properties": {
        "from": "/holdings/details/02079K305",
        "to": "/holdings",
        "method": "back_button"
      }
    },
    {
      "event": "search",
      "timestamp": "2025-07-30T08:40:05.456Z",
      "properties": {
        "query": "NVDA",
        "type": "symbol_lookup",
        "results": 1
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:40:15.789Z",
      "properties": {
        "row_id": "NVDA",
        "symbol": "NVDA",
        "cusip": "67066G104",
        "row_type": "holding",
        "totalmarketvalue": 22340.75,
        "assetclass": "Equity",
        "countryregion": "United States"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:40:16.890Z",
      "properties": {
        "url": "/holdings/details/67066G104",
        "title": "NVDA Holding Details",
        "referrer": "/holdings",
        "symbol": "NVDA",
        "cusip": "67066G104"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:40:55.123Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "marketprice_performance",
        "action": "zoom",
        "symbol": "NVDA"
      }
    },
    {
      "event": "date_picker",
      "timestamp": "2025-07-30T08:41:25.456Z",
      "properties": {
        "action": "select_preset",
        "period_type": "ytd",
        "start_date": "2025-01-01",
        "end_date": "2025-07-30"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T08:41:55.789Z",
      "properties": {
        "tab": "transactions",
        "context": "holding_detail"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T08:42:15.123Z",
      "properties": {
        "filter": "transactiontype",
        "value": "BUY",
        "context": "holding_transactions"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:42:35.456Z",
      "properties": {
        "column": "transactionamt",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T08:43:05.789Z",
      "properties": {
        "from": "/holdings/details/67066G104",
        "to": "/holdings",
        "method": "back_button"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T08:43:25.123Z",
      "properties": {
        "column": "marketplinbccy",
        "direction": "desc",
        "table": "holdings_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T08:43:45.456Z",
      "properties": {
        "row_id": "TSLA",
        "symbol": "TSLA",
        "cusip": "88160R101",
        "row_type": "holding",
        "totalmarketvalue": 18950.50,
        "assetclass": "Equity",
        "countryregion": "United States"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T08:43:46.567Z",
      "properties": {
        "url": "/holdings/details/88160R101",
        "title": "TSLA Holding Details",
        "referrer": "/holdings",
        "symbol": "TSLA",
        "cusip": "88160R101"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T08:44:15.890Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "marketprice_performance",
        "action": "hover",
        "symbol": "TSLA"
      }
    },
    {
      "event": "export",
      "timestamp": "2025-07-30T08:44:45.123Z",
      "properties": {
        "type": "holdings_summary",
        "format": "csv",
        "filter": "us_equity_only",
        "context": "holdings_view",
        "include_fields": ["symbol", "cusip", "totalmarketvalue", "marketplinbccy", "assetclass", "countryregion"]
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
