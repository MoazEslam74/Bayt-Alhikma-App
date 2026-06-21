# Bayt Al-Hikma (بيت الحكمة)

A comprehensive, bilingual (Arabic/English) digital library and social reading application built with Flutter. Bayt Al-Hikma seamlessly combines e-book reading, audiobook streaming, physical book discovery, and community engagement into a single platform.

## 📖 Features

* **Authentication:** Secure user sign-up and login using Firebase Auth (Email/Password & Phone Number).
* **Book Discovery:** Search for books within the app's database. If not found, a fallback option allows searching directly via Google.
* **E-Book Reader:** Built-in PDF reader (using Syncfusion) with automatic page-state saving to resume reading seamlessly.
* **Audiobook Player:** Custom audio interface (using `just_audio`) featuring offline downloading, dynamic waveform visualizers, and playback position saving.
* **Physical Book Locator:** Integration with Google Custom Search API to scrape and display prices (in EGP) and store links for users who prefer to buy physical hardcopies.
* **Smart Recommendations:** Curated book suggestions based on user-selected categories (e.g., Fiction, Philosophy, Science).
* **Bookshelves:** Users can save books, manage favorites, and rate the books they've read.
* **The Coffee Shop (Community):** Real-time chat rooms for users to discuss books, share recommendations, and explore participant profiles.
* **Customization:** Dynamic switching between Arabic (RTL) and English (LTR), along with Light/Dark mode toggling.

## 🛠️ Tech Stack

* **Frontend:** Flutter
* **Backend:** Firebase (Authentication, Cloud Firestore)
* **Local Storage:** Hive (for local caching and state management)
* **Media & Documents:** `just_audio`, `dio`, `syncfusion_flutter_pdfviewer`
* **External APIs:** Google Custom Search API

## 📱 From the APP

<img src='1.png'>
<img src='2.png'>
<img src='3.png'>

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (version 3.38.4 or higher)
* Dart SDK (version 3.10.3 or higher)
* A Firebase Project with Authentication and Firestore enabled.
* Google Custom Search API Key & Search Engine ID.

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/yourusername/bayt-alhikma.git](https://github.com/yourusername/bayt-alhikma.git)
   cd bayt-alhikma
2. **Install dependencies:**
   ```bash
   flutter pub get
3. **Configure Firebase:**
   * Set up your Firebase project and add your Android/iOS apps.
   * Download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files and place them in their respective directories.
4. **Environment Variables:**
   * Provide your Google API credentials by make `.env` file, you can use the example in file `.env.example`.
  
