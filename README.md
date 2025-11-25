# **FlashQR**

FlashQR is a fast and lightweight Flutter application that allows users to
**generate QR codes**, **scan QR codes using the camera**, and **scan QR codes from gallery images**.
Designed for simplicity and speed, FlashQR provides a seamless experience for managing QR-related actions in a modern mobile app.

---

## 🚀 Features

### **1. QR Code Generator**

* Generate QR codes from any text or URL
* Beautiful QR styling using `pretty_qr_code`
* Save QR codes to your device

### **2. Camera QR Scanner**

* Scan QR codes instantly with `mobile_scanner`
* Fast and fluid scanning performance
* Supports multiple QR and barcode formats

### **3. Scan QR from Gallery**

* Pick any image from the gallery
* Automatically detect QR codes inside the image
* Works even with low-quality images or screenshots

### **4. Scan History**

* Keeps track of previously scanned QR data
* Easily copy, share, or revisit scan results

### **5. Floating Quick Actions**

* Smooth and modern quick-action button using `flutter_speed_dial`

---

## 🛠️ Tech Stack

FlashQR is built using the following dependencies:

```yaml
dependencies:
  url_launcher: ^6.3.1
  mobile_scanner: ^7.1.3
  pretty_qr_code: ^3.5.0
  flutter_speed_dial: ^7.0.0
```

* **Flutter** — main framework
* **mobile_scanner** — real-time QR code scanning
* **pretty_qr_code** — stylish and customizable QR generator
* **url_launcher** — open URLs directly from scan results
* **flutter_speed_dial** — floating action menu for quick scan/generate actions

---

## 📦 Installation

Clone the repository:

```bash
git clone https://github.com/salehrashid/FlashQR.git
cd FlashQR
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```
---

## 🤝 Contributing

Contributions are welcome!
Feel free to open issues or submit pull requests.

---

## 📄 License

This project is licensed under the **MIT License**.
