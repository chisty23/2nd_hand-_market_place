# PassItOn — Campus Second-hand Marketplace with Offers

A modern student buy-and-sell Flutter application where sellers post items, buyers browse, save favourites and negotiate with real-time offers and counter-offers. Built for **CSE464 Project P07**.

---

## 🚀 Key Features

### 1. Account & Authentication
- Email & password registration and login using Firebase Authentication.
- Profile storage in Firestore with name, email, department/hostel, sold count, bought count, and average ratings.
- Passwords are exclusively handled by Firebase Auth.

### 2. Browse & Search (Buyer Flow)
- Real-time stream of available listings.
- Keyword search powered by lowercase `keywords` array.
- Multi-criteria filtering: category (Books, Electronics, Bikes & Cycles, Fashion, Stationery, etc.), condition (`new`, `like-new`, `used`, `worn`), and custom price slider.
- Sorting options: Newest first, Price: Low to High, Price: High to Low.
- Instant Favorites / Save to watchlist toggle.

### 3. Listing Details & Category Visuals
- Dynamic category theme styling with icons and colors.
- Support for optional pasted image URL links.
- Seller information card with live average star ratings.
- Buyer actions: **Make Offer** or **Buy at Asking Price**.
- Seller actions: **Edit**, **Reserve**, **Release back to Available**, **Mark Sold**, **Delete**.

### 4. Offer & Counter-Offer Negotiation State Machine
- Lifecycle states: `pending` $\to$ `countered` $\to$ `accepted` / `declined` / `withdrawn` / `expired`.
- Offers older than 48 hours automatically show as expired and non-actionable.
- Full negotiation audit trail/history tracking all price revisions between buyer and seller.
- **Concurrency & Atomic Transactions**: Accepting an offer locks the item with `reserved` status and automatically declines competing pending offers within a single transaction/batch write.

### 5. Sell & Listings Manager
- Quick listing creation form with title, category, condition, price, negotiable toggle, optional image link, and description.
- Dashboard of your own listings showing pending offers count badge.

### 6. Ratings & Reviews
- Buyers can leave a 1 to 5 star rating and comment for the seller once an item is marked sold.
- Second rating of the same sale is strictly blocked by using the `listingId` as the unique rating document ID.

---

## 🛠️ Architecture & State Management

Built strictly following the course rules:
- **State Management**: `Provider` (`ChangeNotifier`).
- **Layers**: UI Screens $\to$ Provider $\to$ Repository/Service Class $\to$ Cloud Firestore & Firebase Auth.
- **Timestamps**: All timestamps written using `FieldValue.serverTimestamp()`.
- **Streams**: Cancelled cleanly on logout and dispose.

---

## 🔒 Firestore Security Rules

See [firestore.rules](file:///C:/Users/USER/Desktop/mobile_app_project/firestore.rules) for full configuration protecting `/users`, `/listings`, `/offers`, and `/ratings`.
