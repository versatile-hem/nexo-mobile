# Nexo Mobile App - API Integration Guide

## Overview
This Flutter application is fully integrated with the live EC Agent backend API and tested against the actual OpenAPI v3.0.1 specification available at `http://localhost:8080/swagger-ui/index.html`.

## API Contracts Alignment

### 1. Authentication - POST /api/auth/login

**Request Format:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response Format (LoginResponse):**
```json
{
  "token": "string",
  "roles": ["string"]
}
```

**Implementation:**
- File: `lib/services/auth_service.dart`
- Extracted: token, roles, userId (generated from username if not present)
- Stored: JWT token + roles in SharedPreferences alongside username

---

### 2. Products Master Data - GET /api/products

**Response Format (Array of ProductDto):**
```json
[
  {
    "productId": 123,
    "name": "string",
    "sku": "string",
    "barcode": "string",
    "price": 599.99,
    ...
  }
]
```

**Implementation:**
- File: `lib/models/product.dart`
- Maps: productId → int id, name, barcode, price
- Used by: Stock In, Daily Operations, Create Order screens

---

### 3. Customers Master Data - GET /api/customers

**Response Format (Array of CustomerSummaryResponse):**
```json
[
  {
    "id": 456,
    "cpId": "string",
    "name": "Customer Name",
    "gstin": "string"
  }
]
```

**Implementation:**
- File: `lib/models/customer.dart`
- Maps: id (int), name
- Used by: Create Order screen

---

### 4. Stock In - POST /api/stock-in

**Request Format (Array of StockInRequestDto):**
```json
[
  {
    "productId": 123,
    "quantity": 50.5,
    "unit": "UNIT",  // Required
    "supplier": "string",  // Optional
    "batchNumber": "string"  // Optional
  }
]
```

**Response Format (Array of InventoryBalanceResponseDto):**
```json
[
  {
    "productId": 123,
    "quantity": 150.5
  }
]
```

**Implementation:**
- File: `lib/features/operation/stock_in_screen.dart`
- Requirement: Unit field required (defaults to "UNIT")
- Barcode scan support via mobile_scanner plugin
- One row per request item

---

### 5. Daily Operations - POST /api/daily-operations

**Request Format (Per DailyOperationRequestDto):**
```json
{
  "type": "ORDER",  // Enum: ["ORDER", "RETURN"]
  "productId": 123,
  "quantity": 25.0,
  "unit": "UNIT",
  "courier": "Delhivery",
  "channel": "FLIPKART"  // Enum: ["FLIPKART", "MEESHO", "OFFLINE", "AMAZON", "WAREHOUSE"]
}
```

**Response Format (InventoryBalanceResponseDto):**
```json
{
  "productId": 123,
  "quantity": 125.0
}
```

**Implementation:**
- File: `lib/features/operation/daily_operations_screen.dart`
- Hardcoded couriers: Delhivery, BlueDart, XpressBees, Ekart
- Channel options: Meesho, Flipkart mapped to enum values
- One POST per row (not batched)
- Type always "ORDER" in current UI

---

### 6. Sales Orders - POST /api/sales-orders

**Request Format (CreateSalesOrderRequest):**
```json
{
  "customerId": 456,
  "items": [
    {
      "productId": 123,
      "quantity": 10.0,
      "price": 599.99
    }
  ]
}
```

**Response Format (SalesOrderResponse):**
```json
{
  "id": 789,
  "orderNumber": "ORDER-001",
  "customerId": 456,
  "createdBy": "username",
  "orderDate": "2026-04-19",
  "totalAmount": 5999.90,
  "status": "CREATED",
  "paymentStatus": "PENDING",
  "createdAt": "2026-04-19T10:30:00",
  "items": [...]
}
```

**Implementation:**
- File: `lib/features/fse/create_order_screen.dart`
- Auto-calculates line totals and order total
- Each item must include price from product master
- Response status enums: CREATED, CONFIRMED, DELIVERED, CANCELLED
- Payment status enums: PENDING, PARTIAL, PAID

---

### 7. Sales Orders List - GET /api/sales-orders

**Query Parameters:**
- `createdBy: userId` (optional but used for FSE-specific orders)

**Response Format (Array of SalesOrderResponse):**
- Same as POST response above

**Implementation:**
- File: `lib/features/fse/my_orders_screen.dart`
- Extracts totalAmount as order amount
- Displays status and paymentStatus

---

### 8. Payments - POST /api/payments

**Request Format (AddPaymentRequest):**
```json
{
  "orderId": 789,
  "amount": 2000.00,
  "paymentDate": "2026-04-19",  // Required, format: yyyy-MM-dd
  "mode": "CASH"  // Enum: ["CASH", "UPI", "BANK"]
}
```

**Response Format (PaymentResponse):**
```json
{
  "id": 999,
  "orderId": 789,
  "amount": 2000.00,
  "paymentDate": "2026-04-19",
  "mode": "CASH",
  "collectedBy": "username",
  "createdAt": "2026-04-19T10:35:00"
}
```

**Implementation:**
- File: `lib/features/fse/payments_screen.dart`
- Mode normalized to uppercase: CASH, UPI, BANK
- Payment date auto-populated as today (yyyy-MM-dd format)
- OrderId accepted as int or string (int casting applied)

---

### 9. Commission - GET /api/commission

**Query Parameters:**
- `userId: string` (optional, for user-specific commission)
- `month: string` (required, format: "yyyy-MM")

**Response Format (MonthlyCommissionResponse):**
```json
{
  "totalCommission": 5000.50,
  "orders": [
    {
      "orderId": 789,
      "amount": 10000.00,
      "commission": 500.00
    }
  ]
}
```

**Implementation:**
- File: `lib/features/fse/commission_screen.dart`
- Maps totalCommission → total (double)
- Maps orders → items (list of CommissionOrderEntry)
- Month picker UI with yyyy-MM format string
- Monthly view with breakdown per order

---

## Data Type Mappings

| Field | OpenAPI Type | Flutter Type | Examples |
|-------|-------------|--------------|----------|
| productId | int64 | int | 123 |
| customerId | int64 | int | 456 |
| orderId | int64 | int | 789 |
| quantity | number (double) | double | 50.5 |
| price | number (double) | double | 599.99 |
| amount | number (double) | double | 2000.00 |
| token | string | String | "eyJhbGc..." |
| roles | array of string | List<String> | ["operation_manager"] |
| channel | enum string | String | "FLIPKART" |
| mode | enum string | String | "CASH" |
| type | enum string | String | "ORDER" |
| status | enum string | String | "CREATED" |
| paymentStatus | enum string | String | "PENDING" |

---

## Special Mappings & Conversions

### Master Data Fallbacks
- **Product ID**: Tries `productId` then `id` field
- **Customer ID**: Tries `id` field
- **Couriers**: Hardcoded list (API endpoint not found) → Delhivery, BlueDart, XpressBees, Ekart

### Enum Normalizations
- **Payment Mode**: Input "cash" → "CASH", "upi" → "UPI"
- **Channel**: UI shows "Meesho", "Flipkart" → sends as enum-compatible strings
- **Type**: Always "ORDER" in daily operations UI

### Date Handling
- **Payment Date**: Auto-populated as today in yyyy-MM-dd format
- **Commission Month**: Month picker outputs "yyyy-MM" string

### ID Type Conversions
- Product/Customer/Order IDs stored as `int` internally
- When sending to API: passed as int
- Dropdown values are int, not string

---

## Error Handling

All screens implement standard error management:
- 401 Unauthorized → Auto-logout via Dio interceptor
- Network errors → Display snackbar with backend error message or generic "Something went wrong"
- Validation errors → Pre-submit client-side validation (required fields, positive numbers)

---

## Tested Endpoints

✅ POST /api/auth/login  
✅ GET /api/products  
✅ GET /api/customers  
✅ POST /api/stock-in  
✅ POST /api/daily-operations  
✅ POST /api/sales-orders  
✅ GET /api/sales-orders  
✅ POST /api/payments  
✅ GET /api/commission  

---

## Build & Run

```bash
# Set backend URL (defaults to http://localhost:8080)
flutter run --dart-define=API_BASE_URL=https://your-backend.com

# Or use default
flutter run
```

---

## Notes for Backend Developers

1. **Stock In**: Expects unit field in request (not optional despite schema marking)
2. **Daily Operations**: Each row is a separate POST call (not batched)
3. **Sales Orders**: Price must be included in request items (auto-calculated from product master in app)
4. **Commission**: Uses userId query param when available from auth session
5. **Dio Interceptor**: Adds `Authorization: Bearer {token}` to all requests

---

Generated: 2026-04-19  
Flutter: 3.41.7 | Dart: 3.11.5  
Status: ✅ All static analysis passed | ✅ All tests passed
