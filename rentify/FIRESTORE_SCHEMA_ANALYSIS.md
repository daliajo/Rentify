# Firestore Schema Analysis Report

## Collections Overview

### 1. `rentify_items`
**Purpose:** Stores rental items/products listed by renters.

### 2. `orders`
**Purpose:** Stores rental orders placed by customers.

### 3. `users`
**Purpose:** Stores user profile information and account data.

### 4. `chats`
**Purpose:** Stores chat conversations between buyers and sellers.

### 5. `chats/{chatId}/messages`
**Purpose:** Subcollection storing individual messages within a chat.

### 6. `users/{userId}/wishlist`
**Purpose:** Subcollection storing wishlist items per user.

### 7. `reviews`
**Purpose:** Stores product reviews submitted by customers.

---

## Field Inventory (per collection)

### Collection: `rentify_items`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `id` | String | `add_item_page.dart:265` | Not read directly (doc.id used instead) |
| `renterId` | String | `add_item_page.dart:266` | Multiple: `product_detail_page.dart`, `checkout.dart`, `renter_dashboard_content.dart`, `homepage.dart`, `products_page.dart`, `wishlist_service.dart`, `admin_dashboard.dart` |
| `renterEmail` | String | `add_item_page.dart:267` | `admin_dashboard.dart:272` |
| `name` | String | `add_item_page.dart:268` | Multiple: All product display pages |
| `price` | Number | `add_item_page.dart:269` | Multiple: All product display and cart pages |
| `depositRate` | Number | `add_item_page.dart:270` | `product_detail_page.dart:103`, `wishlist_page.dart:352` |
| `depositAmount` | Number | `add_item_page.dart:271-272` | `product_detail_page.dart:100`, `checkout.dart`, `wishlist_page.dart:346` |
| `category` | String | `add_item_page.dart:273` | `homepage.dart:58`, `products_page.dart`, `admin_dashboard.dart:269` |
| `subcategory` | String | `add_item_page.dart:274` | `homepage.dart:362`, `products_page.dart` |
| `description` | String | `add_item_page.dart:275` | `product_detail_page.dart:96`, `item_details_page.dart:46` |
| `imageUrl` | String | `add_item_page.dart:276` | Multiple: All product display pages |
| `status` | String | `add_item_page.dart:277`, `checkout.dart:477`, `item_status_service.dart:70`, `item_details_page.dart:418` | Multiple: `products_page.dart`, `homepage.dart:214`, `item_status_service.dart:98`, `admin_dashboard.dart:191,273` |
| `totalQuantity` | Number | `add_item_page.dart:278` | Multiple: `checkout.dart:462`, `product_detail_page.dart:122`, `item_details_page.dart:48`, `renter_dashboard_content.dart:182` |
| `availableQuantity` | Number | `add_item_page.dart:279`, `checkout.dart:475`, `item_status_service.dart:68`, `item_details_page.dart:417` | Multiple: `checkout.dart:463`, `product_detail_page.dart:116`, `item_details_page.dart:49`, `renter_dashboard_content.dart:183` |
| `viewsCount` | Number | `add_item_page.dart:280`, `product_detail_page.dart:84` | Not read (incremented only) |
| `wishlistCount` | Number | `add_item_page.dart:281`, `wishlist_service.dart:118` | `item_details_page.dart:337` |
| `createdAt` | Timestamp | `add_item_page.dart:282` | Multiple: `products_page.dart:42`, `homepage.dart:61`, `renter_dashboard_content.dart:144`, `admin_dashboard.dart:216` |
| `quantity` | Number | Legacy field | `checkout.dart:462`, `item_status_service.dart:39,59`, `renter_dashboard_content.dart:182`, `products_page.dart:368` (fallback only) |

**Note:** `quantity` appears to be a legacy field that is read as fallback when `totalQuantity` is missing, but never written in current code.

---

### Collection: `orders`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `orderId` | String | `checkout.dart:492` | Not read (doc.id used instead) |
| `itemId` | String | `checkout.dart:493` | `product_detail_page.dart:65,408`, `item_status_service.dart:38,115` |
| `itemName` | String | `checkout.dart:494` | Not read |
| `renterId` | String | `checkout.dart:495` | `product_detail_page.dart:64` |
| `ownerId` | String | `checkout.dart:496` | `renter_dashboard_content.dart:35,47` |
| `pricePerDay` | Number | `checkout.dart:497` | Not read |
| `rentalDays` | Number | `checkout.dart:498` | Not read |
| `totalPrice` | Number | `checkout.dart:499` | `renter_dashboard_content.dart:57` (fallback) |
| `startDate` | Timestamp | `checkout.dart:500` | Not read |
| `endDate` | Timestamp | `checkout.dart:501` | `item_status_service.dart:24,116` |
| `depositAmount` | Number | `checkout.dart:502` | Not read |
| `selectedQuantity` | Number | `checkout.dart:503` | `item_status_service.dart:40` |
| `quantity` | Number | `checkout.dart:504` | `item_status_service.dart:39` (fallback) |
| `shippingOption` | String | `checkout.dart:505` | Not read |
| `shippingFee` | Number | `checkout.dart:506` | Not read |
| `shippingAddress` | String | `checkout.dart:507-509` | Not read |
| `shippingLocation` | Object (lat/lng) | `checkout.dart:510-516` | Not read |
| `paymentMethod` | String | `checkout.dart:517` | Not read |
| `paymentStatus` | String | `checkout.dart:518` | `item_status_service.dart:25,117`, `renter_dashboard_content.dart:57` |
| `shippingCost` | Number | `checkout.dart:519` | Not read |
| `grandTotal` | Number | `checkout.dart:520` | `renter_dashboard_content.dart:56` (primary) |
| `createdAt` | Timestamp | `checkout.dart:521` | Not read |
| `totalCost` | Number | `checkout.dart:522` | `renter_dashboard_content.dart:57` (fallback) |

**Note:** Multiple redundant price/total fields: `totalPrice`, `grandTotal`, `totalCost`, `shippingFee`, `shippingCost`.

---

### Collection: `users`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `firstName` | String | `auth_service.dart:34,141`, `profile_page.dart:94` | Multiple: `product_detail_page.dart:375`, `chat_screen.dart`, `chat_page.dart:76`, `admin_users_page.dart:88` |
| `lastName` | String | `auth_service.dart:35,142`, `profile_page.dart:95` | Multiple: `product_detail_page.dart:376`, `chat_screen.dart`, `chat_page.dart:78`, `admin_users_page.dart:89` |
| `mobile` | String | `auth_service.dart:36,146`, `profile_page.dart:96` | `admin_users_page.dart:93` |
| `email` | String | `auth_service.dart:37,147`, `profile_page.dart:97` | Multiple: `product_detail_page.dart:474`, `admin_users_page.dart:90`, `admin_dashboard.dart:813` |
| `emailVerified` | Boolean | `auth_service.dart:38,148` | `auth_service.dart:75` |
| `role` | String | `auth_service.dart:39-40,149-150` | `auth_service.dart:201`, `admin_users_page.dart:91,327` |
| `accountStatus` | String | `auth_service.dart:41-42,151-152` | `auth_service.dart:186`, `admin_users_page.dart:55,92` |
| `profileImage` | String | `profile_page.dart:98` | `product_detail_page.dart:381`, `chat_screen.dart:99,107`, `chat_page.dart:87` |

---

### Collection: `chats`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `buyerId` | String | `chat_service.dart:100` | `chat_service.dart:37,63`, `chat_screen.dart:57,294` |
| `sellerId` | String | `chat_service.dart:101` | `chat_service.dart:64,83`, `product_detail_page.dart:358` |
| `participants` | Array | `chat_service.dart:102` | `chat_service.dart:13` |
| `lastMessage` | String | `chat_service.dart:103,49` | `chat_page.dart:186` |
| `lastMessageAt` | Timestamp | `chat_service.dart:104,50` | `chat_service.dart:14` |
| `deletedFor` | Object | `chat_service.dart:105-108,71-74,90-93` | `chat_page.dart:48,50`, `chat_screen.dart:312` |
| `unreadCount` | Object | `chat_service.dart:109-112,51,60` | `chat_page.dart:56`, `chat_screen.dart:60` |
| `createdAt` | Timestamp | `chat_service.dart:113` | Not read |
| `customerId` | String | Legacy field | `chat_service.dart:37,82`, `chat_screen.dart:57,294`, `chat_page.dart:47,61` (legacy support) |

**Note:** `customerId` is a legacy field that is read for backward compatibility but new chats use `buyerId`.

---

### Collection: `chats/{chatId}/messages`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `text` | String | `chat_service.dart:41`, `chat_screen.dart:272` | `chat_screen.dart:179` |
| `senderId` | String | `chat_service.dart:42`, `chat_screen.dart:273` | `chat_screen.dart:45,161` |
| `createdAt` | Timestamp | `chat_service.dart:43`, `chat_screen.dart:274` | `chat_service.dart:23`, `chat_screen.dart:183` |
| `delivered` | Boolean | `chat_service.dart:44`, `chat_screen.dart:275` | `chat_screen.dart:45,181` |
| `seen` | Boolean | `chat_service.dart:45`, `chat_screen.dart:276` | `chat_screen.dart:73,182` |
| `replyToText` | String | `chat_screen.dart:277` | `chat_screen.dart:184` |

---

### Collection: `users/{userId}/wishlist`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `itemId` | String | `wishlist_service.dart:90` | `wishlist_page.dart:90` |
| `name` | String | `wishlist_service.dart:91` | Not read (fetched from rentify_items instead) |
| `price` | Number | `wishlist_service.dart:92` | Not read (fetched from rentify_items instead) |
| `imageUrl` | String | `wishlist_service.dart:93` | Not read (fetched from rentify_items instead) |
| `ownerId` | String | `wishlist_service.dart:94-95` | Not read (fetched from rentify_items instead) |
| `createdAt` | Timestamp | `wishlist_service.dart:96` | `wishlist_service.dart:59` |

**Note:** Wishlist subcollection stores duplicate data that is re-fetched from `rentify_items` when displayed. Only `itemId` and `createdAt` are actually used.

---

### Collection: `reviews`

| Field Name | Data Type | Where Written | Where Read |
|------------|-----------|---------------|------------|
| `itemId` | String | `product_detail_page.dart:471` | `product_detail_page.dart:509`, `admin_dashboard.dart:742`, `admin_reviews_page.dart:190` |
| `orderId` | String | `product_detail_page.dart:472` | Not read |
| `userId` | String | `product_detail_page.dart:473` | `product_detail_page.dart:526,561`, `admin_dashboard.dart:743`, `admin_reviews_page.dart:191` |
| `userEmail` | String | `product_detail_page.dart:474` | Not read (user data fetched separately) |
| `rating` | Number | `product_detail_page.dart:475`, `product_detail_page.dart:644` | `product_detail_page.dart:552,598`, `admin_dashboard.dart:739`, `admin_reviews_page.dart:187` |
| `comment` | String | `product_detail_page.dart:476`, `product_detail_page.dart:645` | `product_detail_page.dart:558`, `admin_dashboard.dart:794`, `admin_reviews_page.dart:188` |
| `createdAt` | Timestamp | `product_detail_page.dart:477` | `product_detail_page.dart:510`, `admin_dashboard.dart:741`, `admin_reviews_page.dart:189` |

**Note:** `userEmail` is written but never read (user data is fetched from `users` collection instead).

---

## Duplicate / Conflicting Fields

### 1. `rentify_items`: `quantity` ↔ `totalQuantity`
- **Conflict:** `quantity` is legacy, `totalQuantity` is current
- **Where:** Code reads both with fallback logic (`totalQuantity ?? quantity`)
- **Impact:** Safe to remove `quantity` after migration

### 2. `rentify_items`: `renterId` ↔ `ownerId`
- **Conflict:** Items use `renterId`, but wishlist/checkout sometimes reference `ownerId`
- **Where:** `wishlist_service.dart:94-95` checks both, `products_page.dart:266` maps `renterId` to `ownerId`
- **Impact:** Inconsistent naming - should standardize to `renterId` or `ownerId`

### 3. `orders`: `totalPrice` ↔ `grandTotal` ↔ `totalCost`
- **Conflict:** Three fields storing similar total amounts
- **Where:** `renter_dashboard_content.dart:56-57` reads all three with fallback chain
- **Impact:** Redundant - only `grandTotal` is needed

### 4. `orders`: `shippingFee` ↔ `shippingCost`
- **Conflict:** Both store shipping cost
- **Where:** Both written in `checkout.dart:506,519`, neither read
- **Impact:** Redundant - remove one

### 5. `orders`: `quantity` ↔ `selectedQuantity`
- **Conflict:** Both store order quantity
- **Where:** `item_status_service.dart:39-40` reads both with fallback
- **Impact:** Redundant - only `selectedQuantity` needed

### 6. `chats`: `customerId` ↔ `buyerId`
- **Conflict:** `customerId` is legacy, `buyerId` is current
- **Where:** `chat_service.dart:37,60-96` handles both for backward compatibility
- **Impact:** Safe to remove `customerId` after migration

### 7. `chats`: `deletedFor.customer` ↔ `deletedFor.buyer` ↔ `deletedFor.seller`
- **Conflict:** Inconsistent key usage (`customer` vs `buyer`)
- **Where:** `chat_page.dart:50` checks `customer`, but writes use `buyer`/`seller`
- **Impact:** Bug risk - should standardize to `buyer`/`seller`

---

## Unused / Legacy Fields

### Collection: `rentify_items`
- **`id`**: Written but never read (document ID used instead)
- **`quantity`**: Legacy field, only read as fallback for `totalQuantity`
- **`viewsCount`**: Written (incremented) but never read/displayed
- **`renterEmail`**: Only read in admin dashboard, not critical

### Collection: `orders`
- **`orderId`**: Written but never read (document ID used instead)
- **`itemName`**: Written but never read
- **`pricePerDay`**: Written but never read
- **`rentalDays`**: Written but never read
- **`startDate`**: Written but never read
- **`depositAmount`**: Written but never read
- **`shippingOption`**: Written but never read
- **`shippingFee`**: Written but never read
- **`shippingAddress`**: Written but never read
- **`shippingLocation`**: Written but never read
- **`paymentMethod`**: Written but never read
- **`shippingCost`**: Written but never read
- **`totalCost`**: Written but only read as fallback in earnings calculation
- **`totalPrice`**: Written but only read as fallback in earnings calculation
- **`quantity`**: Written but only read as fallback for `selectedQuantity`
- **`createdAt`**: Written but never read

### Collection: `users`
- All fields are actively used

### Collection: `chats`
- **`createdAt`**: Written but never read
- **`customerId`**: Legacy field, only read for backward compatibility

### Collection: `chats/{chatId}/messages`
- All fields are actively used

### Collection: `users/{userId}/wishlist`
- **`name`**: Written but never read (fetched from `rentify_items` instead)
- **`price`**: Written but never read (fetched from `rentify_items` instead)
- **`imageUrl`**: Written but never read (fetched from `rentify_items` instead)
- **`ownerId`**: Written but never read (fetched from `rentify_items` instead)

### Collection: `reviews`
- **`orderId`**: Written but never read
- **`userEmail`**: Written but never read (user data fetched from `users` collection)

---

## Derived Fields (Can Be Removed)

### Collection: `rentify_items`
- **`status`**: Can be derived from `availableQuantity > 0 ? 'available' : 'rented'`
  - **Where derived:** `checkout.dart:477`, `item_status_service.dart:70`, `item_details_page.dart:418`
  - **Where read:** Multiple places check status directly
  - **Recommendation:** Keep for query performance (indexed field)

- **`wishlistCount`**: Can be derived by counting `users/{userId}/wishlist` documents
  - **Where written:** `wishlist_service.dart:118`
  - **Where read:** `item_details_page.dart:337` (display only)
  - **Recommendation:** Can be removed if not needed for sorting/filtering

- **`viewsCount`**: Can be derived from analytics (if needed)
  - **Where written:** `product_detail_page.dart:84`
  - **Where read:** Never read
  - **Recommendation:** Remove if not used for analytics

### Collection: `orders`
- **`grandTotal`**: Can be calculated as `totalPrice + depositAmount + shippingCost`
  - **Where read:** `renter_dashboard_content.dart:56` (primary)
  - **Recommendation:** Keep for performance, but remove redundant `totalPrice` and `totalCost`

---

## Required Core Fields (Do NOT remove)

### Collection: `rentify_items`
- **`renterId`**: Critical - identifies item owner
- **`name`**: Critical - item display name
- **`price`**: Critical - rental price per day
- **`depositAmount`**: Critical - security deposit (or `depositRate` if calculated)
- **`category`**: Critical - item categorization
- **`subcategory`**: Critical - item subcategorization
- **`description`**: Critical - item details
- **`imageUrl`**: Critical - item image
- **`totalQuantity`**: Critical - total units available
- **`availableQuantity`**: Critical - currently available units
- **`createdAt`**: Critical - sorting/filtering

### Collection: `orders`
- **`itemId`**: Critical - links to rented item
- **`renterId`**: Critical - identifies customer
- **`ownerId`**: Critical - identifies item owner
- **`selectedQuantity`**: Critical - quantity rented
- **`endDate`**: Critical - rental period end
- **`paymentStatus`**: Critical - order status tracking
- **`grandTotal`**: Critical - total order amount (or calculate from components)

### Collection: `users`
- **`email`**: Critical - user identification
- **`role`**: Critical - access control
- **`accountStatus`**: Critical - account management
- **`firstName`**, **`lastName`**: Critical - user display
- **`emailVerified`**: Critical - email verification status

### Collection: `chats`
- **`buyerId`**: Critical - chat participant
- **`sellerId`**: Critical - chat participant
- **`participants`**: Critical - arrayContains query
- **`lastMessage`**: Critical - chat list display
- **`lastMessageAt`**: Critical - chat list sorting
- **`unreadCount`**: Critical - unread message tracking
- **`deletedFor`**: Critical - soft delete per user

### Collection: `chats/{chatId}/messages`
- **`text`**: Critical - message content
- **`senderId`**: Critical - message author
- **`createdAt`**: Critical - message ordering

### Collection: `users/{userId}/wishlist`
- **`itemId`**: Critical - links to item
- **`createdAt`**: Critical - wishlist ordering

### Collection: `reviews`
- **`itemId`**: Critical - links to reviewed item
- **`userId`**: Critical - review author
- **`rating`**: Critical - review rating
- **`comment`**: Critical - review text
- **`createdAt`**: Critical - review ordering

---

## Recommended Clean Firestore Schema (AFTER RESET)

### Collection: `rentify_items`
```typescript
{
  renterId: string,              // REQUIRED
  name: string,                   // REQUIRED
  price: number,                  // REQUIRED
  depositAmount: number,          // REQUIRED (or depositRate if calculated)
  category: string,               // REQUIRED
  subcategory: string,            // REQUIRED
  description: string,             // REQUIRED
  imageUrl: string,               // REQUIRED
  totalQuantity: number,           // REQUIRED
  availableQuantity: number,      // REQUIRED
  status: string,                 // REQUIRED ('available' | 'rented') - for query performance
  createdAt: Timestamp,           // REQUIRED
  // Optional: wishlistCount (if needed for sorting)
}
```

**Removed:**
- `id` (use doc.id)
- `quantity` (legacy, replaced by totalQuantity)
- `renterEmail` (can fetch from users collection)
- `viewsCount` (not read)
- `depositRate` (if depositAmount is always stored)

---

### Collection: `orders`
```typescript
{
  itemId: string,                 // REQUIRED
  renterId: string,               // REQUIRED (customer)
  ownerId: string,                // REQUIRED (item owner)
  selectedQuantity: number,       // REQUIRED
  startDate: Timestamp,          // REQUIRED (if needed for rental period)
  endDate: Timestamp,             // REQUIRED
  paymentStatus: string,          // REQUIRED ('pending' | 'completed')
  grandTotal: number,             // REQUIRED (totalPrice + deposit + shipping)
  createdAt: Timestamp,           // REQUIRED (if needed for sorting)
  // Optional: shippingAddress, shippingLocation (if delivery tracking needed)
}
```

**Removed:**
- `orderId` (use doc.id)
- `itemName` (fetch from rentify_items)
- `pricePerDay` (fetch from rentify_items)
- `rentalDays` (calculate from startDate/endDate)
- `totalPrice` (redundant with grandTotal)
- `totalCost` (redundant with grandTotal)
- `depositAmount` (fetch from rentify_items or calculate)
- `quantity` (redundant with selectedQuantity)
- `shippingOption` (if not needed)
- `shippingFee` (redundant with shippingCost)
- `shippingCost` (include in grandTotal calculation)
- `shippingAddress` (if not needed)
- `shippingLocation` (if not needed)
- `paymentMethod` (if not needed)

---

### Collection: `users`
```typescript
{
  firstName: string,              // REQUIRED
  lastName: string,               // REQUIRED
  email: string,                  // REQUIRED
  emailVerified: boolean,         // REQUIRED
  role: string,                   // REQUIRED ('customer' | 'admin' | 'renter')
  accountStatus: string,          // REQUIRED ('active' | 'blocked')
  mobile?: string,                // OPTIONAL
  profileImage?: string,          // OPTIONAL
}
```

**No changes needed** - all fields are used.

---

### Collection: `chats`
```typescript
{
  buyerId: string,                // REQUIRED
  sellerId: string,               // REQUIRED
  participants: string[],          // REQUIRED [buyerId, sellerId]
  lastMessage: string,             // REQUIRED
  lastMessageAt: Timestamp,       // REQUIRED
  unreadCount: {                  // REQUIRED
    buyer: number,
    seller: number
  },
  deletedFor: {                   // REQUIRED
    buyer: boolean,
    seller: boolean
  },
  createdAt: Timestamp,           // OPTIONAL (if needed for sorting)
}
```

**Removed:**
- `customerId` (legacy, replaced by buyerId)

---

### Collection: `chats/{chatId}/messages`
```typescript
{
  text: string,                   // REQUIRED
  senderId: string,               // REQUIRED
  createdAt: Timestamp,           // REQUIRED
  delivered: boolean,             // REQUIRED
  seen: boolean,                  // REQUIRED
  replyToText?: string,          // OPTIONAL
}
```

**No changes needed** - all fields are used.

---

### Collection: `users/{userId}/wishlist`
```typescript
{
  itemId: string,                 // REQUIRED (document ID = itemId)
  createdAt: Timestamp,           // REQUIRED
}
```

**Removed:**
- `name` (fetch from rentify_items)
- `price` (fetch from rentify_items)
- `imageUrl` (fetch from rentify_items)
- `ownerId` (fetch from rentify_items)

**Note:** Document ID should be the `itemId` to avoid duplicate data.

---

### Collection: `reviews`
```typescript
{
  itemId: string,                 // REQUIRED
  userId: string,                 // REQUIRED
  rating: number,                 // REQUIRED (1-5)
  comment: string,                // REQUIRED
  createdAt: Timestamp,           // REQUIRED
  // Optional: orderId (if needed for verification)
}
```

**Removed:**
- `orderId` (if not needed for verification)
- `userEmail` (fetch from users collection)

---

## Summary of Recommended Removals

### High Priority (Safe to Remove)
1. **`rentify_items.quantity`** - Legacy, replaced by `totalQuantity`
2. **`rentify_items.id`** - Redundant with doc.id
3. **`rentify_items.viewsCount`** - Never read
4. **`orders.orderId`** - Redundant with doc.id
5. **`orders.totalPrice`** - Redundant with `grandTotal`
6. **`orders.totalCost`** - Redundant with `grandTotal`
7. **`orders.shippingFee`** - Redundant with `shippingCost` (or remove both if not needed)
8. **`orders.quantity`** - Redundant with `selectedQuantity`
9. **`chats.customerId`** - Legacy, replaced by `buyerId`
10. **`users/{userId}/wishlist.name`** - Duplicate data
11. **`users/{userId}/wishlist.price`** - Duplicate data
12. **`users/{userId}/wishlist.imageUrl`** - Duplicate data
13. **`users/{userId}/wishlist.ownerId`** - Duplicate data
14. **`reviews.userEmail`** - Duplicate data

### Medium Priority (Consider Removing)
1. **`rentify_items.renterEmail`** - Can fetch from users
2. **`rentify_items.wishlistCount`** - Can be derived
3. **`orders.itemName`** - Can fetch from rentify_items
4. **`orders.pricePerDay`** - Can fetch from rentify_items
5. **`orders.rentalDays`** - Can calculate from dates
6. **`orders.depositAmount`** - Can fetch from rentify_items
7. **`orders.shippingOption`** - If not needed
8. **`orders.shippingAddress`** - If not needed
9. **`orders.shippingLocation`** - If not needed
10. **`orders.paymentMethod`** - If not needed
11. **`orders.startDate`** - If not needed
12. **`orders.createdAt`** - If not needed for sorting
13. **`chats.createdAt`** - If not needed for sorting
14. **`reviews.orderId`** - If not needed for verification

### Low Priority (Keep for Performance)
1. **`rentify_items.status`** - Keep for indexed queries (can be derived but slower)
2. **`rentify_items.wishlistCount`** - Keep if needed for sorting/filtering

---

## Naming Inconsistencies to Fix

1. **Standardize:** Use `renterId` everywhere (remove `ownerId` references in items)
2. **Standardize:** Use `buyerId` everywhere in chats (remove `customerId`)
3. **Standardize:** Use `selectedQuantity` everywhere in orders (remove `quantity`)

---

## Critical Notes

1. **Backward Compatibility:** Code currently handles legacy fields (`customerId`, `quantity`, `ownerId`). After reset, remove fallback logic.

2. **Derived Fields:** `status` in `rentify_items` is written but can be derived. However, keeping it allows indexed queries which is faster than computing on-the-fly.

3. **Wishlist Duplication:** The wishlist subcollection stores duplicate item data. Consider storing only `itemId` and `createdAt`, then fetching full item data when displaying.

4. **Order Totals:** Multiple total fields exist. Standardize to `grandTotal` and calculate components if needed.

5. **Chat Deletion:** The `deletedFor` object uses inconsistent keys (`customer` vs `buyer`). Standardize to `buyer`/`seller`.

