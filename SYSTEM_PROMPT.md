# ShelfLife System Architecture & Design Document

## Project Overview
**ShelfLife** is a Flutter-based smart food inventory management application designed to help users track food items, manage expiration dates, and reduce food waste. The app provides barcode scanning, expiry notifications, storage categorization, and spending analytics.

**Platform**: iOS, Android, Web, macOS, Windows, Linux  
**Language**: Dart  
**State Management**: Riverpod  
**Navigation**: GoRouter  
**Local Storage**: Hive + Shared Preferences + Secure Storage

---

## Architecture Pattern
The application follows **Clean Architecture** with separation of concerns:

```
lib/
├── main.dart                          # App entry point
├── app/
│   └── router.dart                   # Navigation configuration (GoRouter)
├── constants/
│   ├── app_constants.dart            # Color, size, string constants
│   └── app_theme.dart                # Material theme definitions
├── pages/                            # UI Layer (Presentation)
│   ├── home_page.dart
│   ├── inventory_page.dart
│   ├── add_item_page.dart
│   ├── item_detail_page.dart
│   ├── edit_item_page.dart
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── profile_page.dart
│   ├── notifications_page.dart
│   ├── notification_settings_page.dart
│   ├── statistics_page.dart
│   ├── help_page.dart
│   └── splash_page.dart
├── widgets/                          # Reusable UI components
│   ├── shared_widgets.dart
│   └── main_scaffold.dart            # Bottom navigation scaffold
└── core/                             # Business Logic & Data Layer
    ├── business/                     # Business Logic Layer
    │   ├── providers/
    │   │   └── inventory_provider.dart    # Riverpod state management
    │   ├── services/
    │   │   ├── inventory_service.dart
    │   │   ├── product_service.dart
    │   │   └── auth_service.dart
    │   └── dtos/
    │       ├── inventory_dto.dart
    │       ├── product_dto.dart
    │       └── user_dto.dart
    ├── data/                         # Data Layer
    │   ├── services/
    │   │   ├── api_client.dart       # HTTP abstraction layer
    │   │   ├── cache_service.dart    # Local caching (Hive)
    │   │   └── notification_service.dart  # Local notifications
    │   └── config/
    │       └── app_config.dart       # Environment & API configuration
    └── common/                       # Shared Domain Layer
        ├── entities/
        │   ├── food_item.dart
        │   ├── product.dart
        │   ├── user.dart
        │   ├── notification.dart
        │   └── entities.dart         # Enums & extensions
        └── interfaces/
            ├── i_inventory_service.dart
            ├── i_product_service.dart
            └── i_auth_service.dart
```

---

## Key Entities & Data Models

### FoodItem (Core Domain Entity)
```dart
class FoodItem {
  final String id;
  final String name;
  final ItemCategory category;      // fridge, pantry, freezer, others
  final int quantity;
  final String? weight;
  final String? weightUnit;
  final DateTime expiryDate;
  final DateTime dateAdded;
  final String? imagePath;
  final String? notes;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final int? consumeWithinDays;
  
  ItemStatus get status;            // fresh, expiringSoon, expired
  int get daysUntilExpiry;
}

enum ItemCategory { fridge, pantry, freezer, others }
enum ItemStatus { fresh, expiringSoon, expired }
```

### AddInventoryItemRequest (Input DTO)
```dart
class AddInventoryItemRequest {
  final bool isCustomItem;          // true = no barcode, false = barcode lookup
  final String? barcodeRef;         // Barcode string if scanned
  final String? customName;         // Manual entry name
  final String? customCategory;     // Manual entry category
  final double? customWeightGrams;  // Manual entry weight
  final double? customPrice;        // Manual entry price
  final int quantity;
  final String quality;             // "Good" (extensible)
  final String? notes;
  final DateTime expirationDate;
}
```

### User & Authentication
```dart
class User {
  final String id;
  final String username;
  final String email;
}

class LoginRequest { final String email; final String password; }
class LoginResponse { final String token; final String userId; final String username; final String email; }
class RegisterRequest { final String email; final String password; final String username; }
```

---

## Data Flow Architecture

### Request → Backend → Response Cycle

1. **UI Layer** (pages): User interacts with forms/buttons
2. **State Management** (Riverpod Provider): `inventoryProvider.notifier.addItem(request)`
3. **Business Logic** (Service): `InventoryService.addItem(request)`
4. **API Communication** (ApiClient): HTTP POST with Bearer token
5. **Backend Processing**: Returns 200/201 with JSON response
6. **Response Parsing** (DTO → Entity): `InventoryItemResponse.fromJson().toFoodItem()`
7. **State Update**: Riverpod updates the inventory list
8. **Cache Update**: Local Hive database synced
9. **Notifications**: Expiry notifications scheduled
10. **UI Rebuild**: Flutter rebuilds affected widgets

### Error Handling Flow
- **HTTP Errors**: Status codes checked (401, 409, 400, 5xx)
- **Parsing Errors**: `catch(e)` blocks catch JSON/serialization failures
- **Network Errors**: Fallback to cached data (getInventory)
- **Provider Level**: Exceptions caught, returns false/null to UI

---

## Core Services & Providers

### 1. InventoryProvider (Riverpod AsyncNotifier)
**Location**: `core/business/providers/inventory_provider.dart`

```dart
Future<bool> addItem(AddInventoryItemRequest request)
  - Calls InventoryService.addItem()
  - Updates local state with new item
  - Returns true on success, false on exception

Future<bool> discardItem(String inventoryId)
  - Removes item from inventory
  - Cancels notifications
  - Removes from cache

Future<void> refresh()
  - Fetches fresh inventory from backend
```

**Derived Providers**:
- `notificationsProvider`: Generates notifications from inventory (expired, expiring soon)
- `statisticsProvider`: Computes waste statistics, category breakdown

### 2. InventoryService (Business Logic)
**Location**: `core/business/services/inventory_service.dart`

```dart
Future<List<FoodItem>> getInventory()
  - Fetches from API → Parses JSON → Caches locally → Schedules notifications
  - Fallback: Returns cached items if API fails

Future<FoodItem> addItem(AddInventoryItemRequest request)
  - POST to /api/inventory
  - Parses response → Creates FoodItem → Schedules expiry notification
  - Throws exception if response != 200/201 or parsing fails

Future<bool> discardItem(String inventoryId)
  - DELETE /api/inventory/{id}
  - Cancels notification → Removes from cache
```

### 3. ProductService (Barcode Lookup)
**Location**: `core/business/services/product_service.dart`

Handles barcode scanning integration:
- Looks up product in backend database
- Returns `Product` with name, category, weight (if found)
- Falls back to manual entry if barcode not found

### 4. AuthService (Authentication)
**Location**: `core/business/services/auth_service.dart`

```dart
Future<LoginResponse> login(LoginRequest request)
  - POST /api/auth/login → Receives JWT token
  - Saves token to secure storage
  - Saves user metadata (id, username, email)

Future<void> register(RegisterRequest request)
  - POST /api/auth/register → Creates account
  - Throws exception on 409 (email exists) or 400 (validation)

Future<void> logout()
  - Clears all stored credentials

Future<bool> isLoggedIn()
  - Checks if token exists
```

### 5. ApiClient (HTTP Abstraction)
**Location**: `core/data/services/api_client.dart`

```dart
static Future<http.Response> get(String path, {bool requiresAuth = true})
static Future<http.Response> post(String path, Map data, {bool requiresAuth = true})
static Future<http.Response> delete(String path)

// Token Management
static Future<void> saveToken(String token)
static Future<String?> getToken()
static Future<void> clearAll()

// Headers automatically inject Bearer token for authenticated endpoints
// Auth header format: "Authorization: Bearer {JWT_TOKEN}"
```

### 6. CacheService (Local Persistence)
**Location**: `core/data/services/cache_service.dart`

Uses **Hive** for fast local storage:
- `saveInventory(List<FoodItem>)`: Persists inventory
- `loadInventory()`: Retrieves cached items
- `removeItem(String id)`: Deletes item
- Fallback data source when API is unavailable

### 7. LocalNotificationService (Push Notifications)
**Location**: `core/data/services/notification_service.dart`

- Initializes on app startup
- Schedules expiry notifications for each item
- Cancels notifications on item discard
- Runs on foreground/background
- Uses `timezone` package for accurate scheduling

---

## Navigation Structure

**Router Configuration**: `app/router.dart` (GoRouter)

### Routes
```
/                       → SplashPage (authentication check)
/login                 → LoginPage
/register              → RegisterPage
/home                  → HomePage (with MainScaffold)
/inventory             → InventoryPage (with MainScaffold)
/add-item              → AddItemPage
/item-detail?id={id}   → ItemDetailPage
/edit-item?id={id}     → EditItemPage
/notifications         → NotificationsPage (with MainScaffold)
/notification-settings → NotificationSettingsPage
/profile               → ProfilePage (with MainScaffold)
/statistics            → StatisticsPage
/help                  → HelpPage
```

**MainScaffold**: Provides bottom navigation bar for authenticated screens.

---

## Key Features & Their Implementation

### 1. Barcode Scanning (`add_item_page.dart`)
- **Tab-based UI**: Manual Entry vs. Scan Date
- **Scanner Tab** (`_ScanTab`):
  - Uses `mobile_scanner` package
  - Animates scan line
  - Shows dark vignette overlay
  - Corner bracket indicators
  - Flashlight toggle
- **Success Flow**:
  1. Barcode detected → Auto-lookup via `ProductService`
  2. If found → Auto-fill name & category
  3. If not found → User enters manually
  4. Switch to manual tab for expiry details

### 2. Expiry Date Management
Two modes toggle (`_ModeChip`):
- **Exact Date**: User picks expiry date directly
- **After Manufacturing**: User enters mfg date + shelf life (days)
  - `expiryDate = mfgDate + Duration(days: shelfLife)`

### 3. Notification System
**Flow**:
1. Item added → Expiry date calculated
2. `scheduleExpiryNotification(item)` triggered
3. Notification scheduled at specific time
4. On app startup → Reschedule all notifications from cache
5. On item discard → Notification cancelled

**Types**:
- `NotificationType.expired`: Red badge, urgent message
- `NotificationType.expiringSoon`: Yellow badge, 3-day warning

### 4. Statistics & Analytics
**Provider**: `statisticsProvider` (computes from inventory)
- `totalAdded`: Total items in inventory
- `totalExpired`: Count of expired items
- `totalConsumed`: Items successfully consumed
- `estimatedWasteCost`: Sum of purchase prices of expired items
- `categoryBreakdown`: Count per category
- `wastedByCategory`: Expired items per category

### 5. Item Categorization
**Categories**: Fridge, Pantry, Freezer, Others
- Each category has: color, icon, label
- Used for UI filtering & organization
- Stored in database

### 6. Caching & Offline Support
- **Primary Source**: Backend API
- **Cache Fallback**: Hive local storage
- **Sync Strategy**: Cache refreshed on every API call
- **Offline Scenario**: App loads cached inventory automatically

---

## Authentication & Authorization

### Token-Based (JWT)
1. **Login**: POST `/api/auth/login` with email/password
2. **Response**: Receives JWT token (typically has user claims)
3. **Storage**: Token saved in `FlutterSecureStorage` (encrypted)
4. **Usage**: Every API request includes `Authorization: Bearer {token}`
5. **Expiry**: Handled by backend (returns 401 if expired)
6. **Logout**: Token deleted from secure storage

### Splash Flow
- `SplashPage` checks `isLoggedIn()`
- If logged in → Route to `/home`
- If not logged in → Route to `/login`

---

## Important Implementation Details

### Why `addItem()` Returns False Despite 200 Status

The `addItem()` flow has multiple failure points after HTTP success:

```dart
// In InventoryService.addItem():
if (response.statusCode == 200 || response.statusCode == 201) {
  final item = InventoryItemResponse.fromJson(      // ← Can fail
    jsonDecode(response.body) as Map<String, dynamic>,
  ).toFoodItem();                                     // ← Can fail

  await LocalNotificationService.scheduleExpiryNotification(item);  // ← Can fail
  return item;
}

// In InventoryNotifier.addItem():
try {
  final newItem = await _service.addItem(request);
  // ...
  return true;
} catch (e) {
  return false;  // ← Exception silently returns false
}
```

**Common causes**:
- Invalid JSON in response body
- Mismatched response structure vs. DTO schema
- Missing required fields
- Notification scheduling failure

**Solution**: Add logging to catch clause to debug actual errors.

### Form Validation Flow (`_ManualForm`)
- Form wrapped in `Form` widget with `GlobalKey<FormState>`
- `_save()` calls `_formKey.currentState!.validate()`
- All `TextFormField` validators run
- Returns false if any validation fails
- After validation → Business logic execution

### State Management Pattern (Riverpod)
- `inventoryProvider` = `AsyncNotifierProvider<InventoryNotifier, List<FoodItem>>`
- Loading state: `AsyncValue.loading()`
- Success: `AsyncValue.data(items)`
- Error: `AsyncValue.error(error)`
- Watch in widgets: `ref.watch(inventoryProvider)`
- Modify: `ref.read(inventoryProvider.notifier).addItem(...)`

### DTO → Entity Conversion
Example flow for inventory items:
```
JSON Response → InventoryItemResponse.fromJson() → FoodItem.toFoodItem()
```
This separation allows:
- API responses to change without affecting domain models
- Domain entities to have computed properties (`status`, `daysUntilExpiry`)
- Easier testing of business logic

---

## Testing & Debugging

### Debug Printing
The app uses `debugPrint()` extensively:
- `[InventoryNotifier]` tag for provider logs
- `[Scanner]` tag for barcode scanner logs
- `[Inventory]` tag for service logs
- `[Register]`, `[main]` for other flows

### Key Debug Points
- Check logs when `addItem()` returns false
- Verify bearer token is present in API requests
- Confirm response JSON matches expected schema
- Check notification scheduling logs on app startup

---

## Dependencies & Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| **State** | flutter_riverpod | Reactive state management |
| **Navigation** | go_router | Client-side routing |
| **HTTP** | http | Backend API calls |
| **Local DB** | hive, hive_flutter | Fast local caching |
| **Secure Storage** | flutter_secure_storage | JWT token storage |
| **Notifications** | flutter_local_notifications, timezone | Push notifications |
| **Barcode** | mobile_scanner | Camera-based barcode scanning |
| **Permissions** | permission_handler | Camera & notification permissions |
| **UI/UX** | google_fonts, flutter_svg, fl_chart | Design system |
| **Analytics/Charts** | fl_chart | Spending & waste analytics |
| **Utilities** | intl, uuid, image_picker | Localization, IDs, images |

---

## Important Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App initialization, notification setup |
| `lib/app/router.dart` | Route definitions |
| `lib/core/business/providers/inventory_provider.dart` | Inventory state management |
| `lib/core/business/services/inventory_service.dart` | Inventory API & cache logic |
| `lib/core/business/services/auth_service.dart` | Authentication |
| `lib/core/data/services/api_client.dart` | HTTP client with token injection |
| `lib/core/data/services/cache_service.dart` | Hive-based local storage |
| `lib/core/data/services/notification_service.dart` | Local notifications |
| `lib/pages/add_item_page.dart` | Item creation (manual + barcode) |
| `lib/pages/inventory_page.dart` | Inventory list view |
| `lib/pages/home_page.dart` | Dashboard/statistics |

---

## Typical Development Workflow

1. **Add Feature**: Create page in `pages/`
2. **Manage State**: Add provider to `core/business/providers/`
3. **Backend Call**: Create/update service in `core/business/services/`
4. **Data Model**: Define DTO in `core/business/dtos/` and entity in `core/common/entities/`
5. **API Integration**: Add endpoint to `ApiClient` if needed
6. **Local Persistence**: Update `CacheService` if caching needed
7. **Notifications**: Add to `NotificationService` if alerts needed
8. **Routing**: Add route to `app/router.dart`
9. **UI Components**: Extract reusable widgets to `widgets/shared_widgets.dart`

---

## Common Patterns in Codebase

### Async/Await with Error Handling
```dart
try {
  final result = await someAsyncCall();
  // Process result
} catch (e) {
  debugPrint('Error: $e');
  // Handle error
}
```

### Riverpod State Watching & Reading
```dart
// Watch: rebuilds widget when state changes
final inventory = ref.watch(inventoryProvider);

// Read: get current value without triggering rebuild
final success = await ref.read(inventoryProvider.notifier).addItem(request);
```

### Form Validation
```dart
if (!_formKey.currentState!.validate()) return;
// Form is valid, proceed
```

### Null Safety & Default Values
```dart
final current = state.value ?? [];  // Default to empty list
```

---

## Notes for LLM Assistants

- **Know the layers**: Never mix UI logic in services or vice versa
- **Follow DTO pattern**: API responses → DTO → Domain Entity
- **Check bearer token**: All authenticated requests need `Authorization: Bearer {token}` header
- **Handle exceptions**: Services throw, providers catch and return false/null
- **Cache first**: Always check if caching needed before making API call
- **Debug systematically**: Use logging tags, check response status codes and body
- **Test permissions**: Camera, notifications, and storage need explicit permission requests
- **Validate input**: Always validate form data before API submission
