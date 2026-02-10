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

## 🛠️ Tech Stack

### 📱 Frontend
- **Flutter (Dart)**  
  Used to build a cross-platform mobile application with a clean, responsive UI and smooth user interactions.
- **Flutter Navigation & Widgets**  
  Utilized core Flutter widgets such as `StatefulWidget`, `ListView`, `GridView`, and `BottomNavigationBar` to structure screens, manage state, and handle navigation flows.

### 🔥 Backend & Services (Firebase)
- **Firebase Authentication**  
  Handles user identification and role separation using unique user IDs.
- **Cloud Firestore**  
  Serves as the main database for storing items, orders, and user-related data, with real-time updates using streams.
- **Firebase Storage**  
  Used for storing item images, while Firestore maintains image URLs and metadata.

### 🧠 Application Logic
- **Client-side Business Logic**  
  Item availability, quantity management, deposit calculation, and expired rental handling are implemented in the application layer and synchronized with Firestore.

### 🖼️ Media & UI Enhancements
- **Image Picker & Image Compression**  
  Used to select and optimize images before upload for better performance.
- **Photo View**  
  Enables full-screen image preview with zoom and swipe support.

---

## 🙌 Acknowledgment
This project was developed as part of a graduation project and represents the application of both technical and product-focused skills learned throughout the program.


