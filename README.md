🏠 Maebanjumpen – Housekeeper Hiring Platform

Maebanjumpen is a housekeeper hiring platform that enables users to search, hire, and manage housekeeper services through a mobile app, powered by a secure backend API.
Built as a full-stack project, it showcases mobile app development, backend API creation, and database integration.

✨ Key Features

🔍 Search & Browse Housekeepers: View available housekeepers with profiles and ratings.

📝 Booking & Hiring: Request services and schedule housekeeper visits.

🔑 Authentication & Authorization: Role-based access for users and admins.

📊 Manage Requests: Track status of bookings (pending, confirmed, completed).

📱 Responsive & User-Friendly: Optimized mobile experience built with Flutter.

🛠 Technology Stack
Mobile App	Backend	Database	Tools
Flutter (Dart)	Spring Boot (Java)	MySQL	Postman, GitHub, VS Code, IntelliJ IDEA
🚀 How to Run
Prerequisites

Ensure you have installed:

Flutter SDK → flutter.dev

Java (JDK 17+) → Oracle

MySQL Server → MySQL

Backend Setup
# Clone the backend repository
git clone https://github.com/Chanakan060703/maebanjumpen-intellij-API
cd maebanjumpen-intellij-API

# Configure application.properties for your MySQL credentials
# Then run Spring Boot application
./mvnw spring-boot:run

Mobile App Setup
# Clone the mobile app repository
git clone https://github.com/Chanakan060703/maebanjumpen
cd maebanjumpen

# Install Flutter dependencies
flutter pub get

# Run the app on emulator or device
flutter run

📱 How It Works

Sign Up / Log In → Users create an account and log in securely.

Browse Services → Search for housekeepers by location, rating, or availability.

Book a Service → Select preferred date and time, then send a request.

Track Status → View pending, confirmed, or completed services in real-time.

📂 Project Structure
maebanjumpen/
├── lib/                 # Flutter app source code
├── android/             # Android-specific files
├── ios/                 # iOS-specific files
├── pubspec.yaml         # Flutter dependencies
└── README.md            # Project documentation

maebanjumpen-intellij-API/
├── src/main/java/       # Spring Boot API code
├── src/main/resources/  # Config files (application.properties)
└── pom.xml              # Maven dependencies

🔗 Related Repositories

📱 Mobile App Code: Maebanjumpen Mobile

🖥 Backend API Code: Maebanjumpen API

🤝 Contributing

Contributions are welcome! Feel free to fork the repository, create a feature branch, and submit a pull request.

📜 License

This project is licensed under the MIT License – see the LICENSE
 file for details.

📬 Contact

👤 Chanakan Kongyen
📧 Chonakankongyen@gmail.com

💻 GitHub Profile
