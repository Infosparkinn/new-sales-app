# 📊 Vyapar Sales App - Modern GST Billing, Inventory & Accounting

An offline-first, high-performance GST billing, inventory management, and business accounting application designed for Indian small & medium businesses (SMBs), retailers, wholesalers, and service providers. Inspired by Vyapar, built with Flutter and SQLite.

Available on **Android** (Release APK) and **Windows Desktop** (Native x64 binary).

---

## 🌟 Key Features

### 🏢 Multi-Company & Firms Management
- **Multiple Business Entities:** Create and manage separate firms (GSTIN, legal name, business address, bank account, IFSC, UPI ID, terms & conditions, and authorized signature).
- **Instant Firm Switching:** Effortlessly switch between companies with isolated transactions, invoices, and accounting entries.

### 🧾 Invoicing & Tax Engine
- **GST Vector PDF Generation:** Generates print-ready invoices with dynamic UPI QR payment codes, bank account details, and item breakdowns.
- **E-way Bills:** Record E-way Bill number, Transporter ID, Vehicle Number, and distance directly on bills and PDF receipts.
- **TCS & TDS Deduction:** Configurable Tax Collected at Source (TCS) and Tax Deducted at Source (TDS) percentages applied to invoice totals.
- **Real-Time Profit Margin:** Live calculation showing estimated profit and margin % while creating invoices before saving.
- **Whitelabel Invoices:** Toggle `hideBranding` to remove software watermarks or advertisements on printouts.

### 📦 Inventory & Multi-Tier Pricing
- **Tiered Pricing:** Define Retail, Wholesale, and Dealer prices for every product.
- **Party-Specific Rates:** Set and remember custom negotiated rates for specific customers.
- **Batch & Serial Tracking:** Track manufacturing dates, expiry dates, batch numbers, and serial numbers.
- **Bulk Item & Stock Editor:** Spreadsheet-like screen to update prices, stock adjustments, and tax rates for hundreds of items at once.
- **Custom Item Fields:** Add custom fields (e.g., IMEI, Color, Size, Rack Number, Warranty) to any inventory item.

### 👥 Parties & Credit Controls
- **Party Credit Limits:** Define maximum credit balances per party with real-time warning alerts during bill creation if limits are exceeded.
- **Party Statement & Ledger:** Real-time receivables and payables tracking.

### 🚜 Fixed Assets Register
- **Asset Categories:** Track Plant & Machinery, Vehicles, IT Equipment, Furniture, and Real Estate.
- **Depreciation Calculation:** Automatically calculate annual depreciation percentage and net book value for balance sheet integration.

### 🔔 Reminders & WhatsApp Connect
- **WhatsApp Invoicing:** Send invoices with PDF download links and UPI payment requests directly to party WhatsApp numbers.
- **Payment Reminders:** Automated reminder templates with pending balance, invoice reference, and due dates.
- **Service Reminders:** Manage upcoming service deadlines (AMC, vehicle service, warranty, renewal) with automated status updates.
- **Self & Update Notifications:** Send instant transaction confirmation and change alerts to business owner WhatsApp.

### 🔄 Orders & Challan Conversion
- Manage Quotations and Delivery Challans.
- Convert approved Challans and Orders into final GST Sales Invoices in a single tap without re-entering items.

### 📑 Comprehensive Accounting & Reports
- **Real-Time Balance Sheet:** Double-entry accounting tracking Assets (Current & Fixed), Liabilities, and Owner's Equity.
- **Billwise Profit & Loss:** Inspect exact cost vs. selling price profits for each generated bill.
- **Partywise Profit & Loss:** View profitability breakdowns for every customer and vendor.
- **Item Batch & Expiry Report:** Track aging stock and expiring batches.
- **Recycle Bin:** Soft-delete safeguard allowing easy recovery of deleted transactions, invoices, and items.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter 3.24.0 (Channel stable)
- **Programming Language:** Dart 3.5.0
- **Database:** SQLite v2 with 13 tables (`sqflite` on Android, `sqflite_common_ffi` on Windows Desktop)
- **State Management:** Provider
- **Document Generation:** `pdf` & `printing` with Vector Tax layout & dynamic QR codes
- **Sharing & Communications:** `share_plus` with deep-linked WhatsApp intents

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.24+
- Android Studio / Android SDK (for Android build)
- Visual Studio 2019 or 2022 with Desktop development with C++ (for Windows build)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Infosparkinn/new-sales-app.git
   cd new-sales-app
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on Windows Desktop:**
   ```bash
   flutter run -d windows
   ```

4. **Run on Android Device / Emulator:**
   ```bash
   flutter run -d android
   ```

---

## 📦 Building Releases

### Android APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Windows Desktop:
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/new_sales_app.exe
```

---

## 🌐 GitHub Pages Live Demo & Showcase

Visit the landing page and documentation:
**[https://Infosparkinn.github.io/new-sales-app/](https://Infosparkinn.github.io/new-sales-app/)**

---

## 📄 License
This project is open-source under the MIT License.
