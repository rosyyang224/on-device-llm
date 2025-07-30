let userPref2 = """
{
  "user_id": "user_789ghi",
  "session_id": "sess_456def789",
  "timestamp": "2025-07-30T14:15:30.123Z",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
  "ip_address": "192.168.1.105",
  "activities": [
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:15:30.123Z",
      "properties": {
        "url": "/homepage",
        "title": "Portfolio Homepage",
        "referrer": "direct"
      }
    },
    {
      "event": "tab_click",
      "timestamp": "2025-07-30T14:15:45.456Z",
      "properties": {
        "tab": "transactions",
        "previous_tab": "homepage"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:15:46.567Z",
      "properties": {
        "url": "/transactions",
        "title": "All Transactions",
        "referrer": "/homepage"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:16:05.890Z",
      "properties": {
        "filter": "transactiontype",
        "value": "BUY",
        "previous_filter": "all"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T14:16:25.123Z",
      "properties": {
        "column": "transactiondate",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:16:55.456Z",
      "properties": {
        "row_id": "TXN_001",
        "symbol": "AAPL",
        "cusip": "037833100",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-25",
        "transactionamt": 12500.00,
        "sharesoffacevalue": 75.5,
        "costprice": 165.56,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:16:56.567Z",
      "properties": {
        "url": "/transactions/details/TXN_001",
        "title": "Transaction Details - AAPL BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T14:17:35.890Z",
      "properties": {
        "from": "/transactions/details/TXN_001",
        "to": "/transactions",
        "method": "back_button"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:17:55.123Z",
      "properties": {
        "row_id": "TXN_002",
        "symbol": "MSFT",
        "cusip": "594918104",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-23",
        "transactionamt": 8750.50,
        "sharesoffacevalue": 25.0,
        "costprice": 350.02,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:17:56.234Z",
      "properties": {
        "url": "/transactions/details/TXN_002",
        "title": "Transaction Details - MSFT BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T14:18:25.567Z",
      "properties": {
        "from": "/transactions/details/TXN_002",
        "to": "/transactions",
        "method": "back_button"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:18:45.890Z",
      "properties": {
        "filter": "transactiondate",
        "value": "last_30_days",
        "previous_filter": "all_dates"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T14:19:05.123Z",
      "properties": {
        "column": "transactionamt",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:19:35.456Z",
      "properties": {
        "row_id": "TXN_003",
        "symbol": "GOOGL",
        "cusip": "02079K305",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-20",
        "transactionamt": 15250.75,
        "sharesoffacevalue": 110.25,
        "costprice": 138.32,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:19:36.567Z",
      "properties": {
        "url": "/transactions/details/TXN_003",
        "title": "Transaction Details - GOOGL BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T14:20:05.890Z",
      "properties": {
        "chart_type": "bar_chart",
        "chart_name": "transaction_amounts_over_time",
        "action": "hover",
        "transaction_type": "BUY"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T14:20:35.123Z",
      "properties": {
        "from": "/transactions/details/TXN_003",
        "to": "/transactions",
        "method": "back_button"
      }
    },
    {
      "event": "search",
      "timestamp": "2025-07-30T14:20:55.456Z",
      "properties": {
        "query": "NVDA",
        "type": "transaction_lookup",
        "results": 2
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:21:15.789Z",
      "properties": {
        "row_id": "TXN_004",
        "symbol": "NVDA",
        "cusip": "67066G104",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-18",
        "transactionamt": 9850.25,
        "sharesoffacevalue": 15.5,
        "costprice": 635.50,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:21:16.890Z",
      "properties": {
        "url": "/transactions/details/TXN_004",
        "title": "Transaction Details - NVDA BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:21:45.123Z",
      "properties": {
        "filter": "costprice",
        "value": "above_500",
        "context": "transaction_detail"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T14:22:15.456Z",
      "properties": {
        "from": "/transactions/details/TXN_004",
        "to": "/transactions",
        "method": "back_button"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:22:35.789Z",
      "properties": {
        "filter": "sharesoffacevalue",
        "value": "above_50",
        "context": "transactions_view"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T14:22:55.123Z",
      "properties": {
        "column": "costprice",
        "direction": "asc",
        "table": "transactions_table"
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:23:25.456Z",
      "properties": {
        "row_id": "TXN_005",
        "symbol": "TSLA",
        "cusip": "88160R101",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-15",
        "transactionamt": 6750.00,
        "sharesoffacevalue": 30.0,
        "costprice": 225.00,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:23:26.567Z",
      "properties": {
        "url": "/transactions/details/TXN_005",
        "title": "Transaction Details - TSLA BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T14:23:55.890Z",
      "properties": {
        "chart_type": "line_chart",
        "chart_name": "buy_transaction_frequency",
        "action": "zoom",
        "date_range": "last_30_days"
      }
    },
    {
      "event": "navigation",
      "timestamp": "2025-07-30T14:24:25.123Z",
      "properties": {
        "from": "/transactions/details/TXN_005",
        "to": "/transactions",
        "method": "back_button"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:24:45.456Z",
      "properties": {
        "filter": "commission",
        "value": "below_10",
        "context": "transactions_view"
      }
    },
    {
      "event": "table_sort",
      "timestamp": "2025-07-30T14:25:05.789Z",
      "properties": {
        "column": "settlementdate",
        "direction": "desc",
        "table": "transactions_table"
      }
    },
    {
      "event": "search",
      "timestamp": "2025-07-30T14:25:25.123Z",
      "properties": {
        "query": "AMD",
        "type": "transaction_lookup",
        "results": 1
      }
    },
    {
      "event": "row_click",
      "timestamp": "2025-07-30T14:25:45.456Z",
      "properties": {
        "row_id": "TXN_006",
        "symbol": "AMD",
        "cusip": "007903107",
        "transactiontype": "BUY",
        "transactiondate": "2025-07-10",
        "transactionamt": 4500.50,
        "sharesoffacevalue": 45.0,
        "costprice": 100.01,
        "row_type": "transaction"
      }
    },
    {
      "event": "page_view",
      "timestamp": "2025-07-30T14:25:46.567Z",
      "properties": {
        "url": "/transactions/details/TXN_006",
        "title": "Transaction Details - AMD BUY",
        "referrer": "/transactions",
        "transactiontype": "BUY"
      }
    },
    {
      "event": "export",
      "timestamp": "2025-07-30T14:26:15.890Z",
      "properties": {
        "type": "buy_transactions_summary",
        "format": "csv",
        "filter": "buy_only_last_30_days",
        "context": "transactions_view",
        "include_fields": ["symbol", "cusip", "transactiondate", "transactionamt", "sharesoffacevalue", "costprice", "commission"]
      }
    },
    {
      "event": "chart_interaction",
      "timestamp": "2025-07-30T14:26:45.123Z",
      "properties": {
        "chart_type": "pie_chart",
        "chart_name": "buy_transactions_by_symbol",
        "action": "click",
        "label": "GOOGL"
      }
    },
    {
      "event": "filter_applied",
      "timestamp": "2025-07-30T14:27:05.456Z",
      "properties": {
        "filter": "principal",
        "value": "above_5000",
        "context": "transactions_view"
      }
    },
    {
      "event": "session_end",
      "timestamp": "2025-07-30T14:27:30.789Z",
      "properties": {
        "duration_sec": 720
      }
    }
  ]
}
"""
