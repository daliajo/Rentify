# Rentify 🏠

Rentify is a mobile rental platform designed to provide users with convenient access to a wide range of items without the need for ownership.
The platform enables individuals to rent items for short-term use, reducing unnecessary purchases and promoting efficient resource utilization.

---

🎯 Purpose & Goals
Rentify was designed with the following goals in mind:
- Support **temporary item needs** without unnecessary purchasing
- Enable **item owners** to earn income from unused or underused items
- Promote **sustainability** by encouraging reuse and shared access
- Provide a **clear, intuitive user experience** for both customers and renters
- Deliver a scalable solution using modern mobile technologies

---

## 🚀 Features

- Real-time item availability and updates
- Category-based browsing and searching
- Wishlist and cart functionality
- Secure image upload and storage
- Automatic inventory and availability handling
- Dynamic security deposit calculation based on item category
- Separate renter and customer workflows
- Clean and responsive UI with a strong UX focus

---

## 🛠️ Technologies Used

### 📱 Frontend (Mobile App)
- **Flutter (Dart)**  
  Used to build a cross-platform mobile application with a consistent UI and smooth performance.
- **Flutter Widgets & Navigation**
  - `StatefulWidget` for interactive screens (search, filters, editing states)
  - `Navigator` and route-based navigation for page transitions
  - `BottomNavigationBar` for customer and renter main flows
- **UI/UX Implementation**
  - Responsive layouts using `GridView`, `ListView`, `SingleChildScrollView`
  - Consistent styling (colors, spacing, typography) across the app
  - Friendly states (loading indicators, empty states, validation messages)

### 🔥 Backend-as-a-Service (Firebase)
- **Firebase Authentication**
  - User sign-in identity via `FirebaseAuth.instance.currentUser`
  - Role-based flows using `uid` references (e.g., `renterId` stored in item documents)
- **Cloud Firestore (NoSQL Database)**
  - Primary database for core collections such as:
    - `rentify_items` (items + metadata)
    - `orders` (rental orders + dates + totals)
    - chat-related collections (messages/threads depending on implementation)
  - Real-time updates using streams:
    - `snapshots()` + `StreamBuilder` for live UI updates (home, store, dashboards)
  - Query features used in code:
    - `where(...)` filtering (category, renterId, status)
    - `orderBy(...)` sorting (createdAt, price)
    - `limit(...)` for previews (Discover section)
  - Server timestamps:
    - `FieldValue.serverTimestamp()` for consistent createdAt values
- **Firebase Storage**
  - Stores item images as files
  - Firestore stores only the **download URL**
  - Upload logic includes:
    - `putFile(...)` for mobile
    - `putData(...)` for web bytes
  - Image URLs are displayed via `Image.network(...)`

### 🧠 Business Logic & Services
- **ItemStatusService (Availability + Expired Rentals)**
  - Checks expired orders using `endDate < now`
  - Restocks quantities and updates status automatically
  - Uses Firestore **batch writes** for safer, atomic updates
- **Client-side Business Rules**
  - Deposit calculation based on category/subcategory risk ranges
  - Inventory consistency using `totalQuantity` and `availableQuantity`
  - Availability checks before allowing rental actions (based on status/quantity)

### 🖼️ Media Handling
- **image_picker**
  - Selects item images from the device gallery
- **flutter_image_compress + path_provider**
  - Compresses images before upload (smaller file size, faster uploads)
  - Uses temporary storage for compressed image generation

### 🧩 Helpful UI Libraries
- **photo_view**
  - Full-screen image preview with zoom/pan and swipe gallery support

---

## 🙌 Acknowledgment
This project was developed as part of a graduation project and represents the application of both technical and product-focused skills learned throughout the program.


