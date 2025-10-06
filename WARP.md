# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter application for a Mini Project Approval System used in an academic environment. The system allows:
- **Students** to submit and track project proposals 
- **Teachers** to review and approve/reject student projects
- **Admins** to manage teachers and system-wide operations

The app uses Firebase for authentication and Firestore for data persistence.

## Development Commands

### Essential Flutter Commands
```powershell
# Run the app in debug mode
flutter run

# Run with hot reload (automatically enabled in debug mode)
flutter run --hot

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build for different platforms
flutter build apk --release       # Android APK
flutter build appbundle --release # Android App Bundle
flutter build web                 # Web build
```

### Testing Commands
```powershell
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Integration tests (if any exist)
flutter test integration_test/
```

### Code Quality Commands
```powershell
# Analyze code for issues
flutter analyze

# Format code according to Dart style
flutter format .

# Check for outdated dependencies
flutter pub outdated

# Get dependencies
flutter pub get

# Clean build artifacts
flutter clean
```

## Architecture Overview

### Application Structure
The app follows a standard Flutter architecture with separation of concerns:

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── project_model.dart    # Project entity with approval workflow
│   ├── student_model.dart    # Student/team data model  
│   └── teacher_model.dart    # Teacher profile model
├── services/                 # Business logic layer
│   ├── auth_service.dart     # Firebase Authentication wrapper
│   └── database_service.dart # Firestore operations
└── screens/                  # UI screens
    ├── role_selection_screen.dart    # Entry point for role selection
    ├── login_screen.dart             # Authentication screen
    ├── student_dashboard_screen.dart # Student project management
    ├── teacher_dashboard_screen.dart # Teacher review interface
    ├── admin_dashboard_screen.dart   # Admin management panel
    ├── student_registration_screen.dart # Student team setup
    └── project_detail_screen.dart    # Project details and editing
```

### Key Architectural Patterns

**State Management**: Uses Provider pattern for dependency injection of services (AuthService, DatabaseService)

**Authentication Flow**: 
1. Role selection → Login → Role-based dashboard routing
2. Special admin email (`admin@pvppcoe.ac.in`) for admin access
3. User roles determined by email lookup in Firestore collections

**Data Flow**:
- Students submit projects (max 4 per student) with team information
- Projects route to assigned teachers for review
- Approved projects are copied to `approved_projects` collection for future plagiarism checking
- Real-time updates using Firestore streams (`watchProjectsForStudent`, `watchProjectsForTeacher`)

**Firebase Collections**:
- `students` - Student profile and team data
- `teachers` - Teacher profiles  
- `projects` - Active project submissions with status workflow
- `approved_projects` - Historical approved projects for duplicate detection

### Business Logic Constraints
- Maximum 4 project submissions per student
- Projects have statuses: `pending`, `approved`, `rejected`
- Approved projects automatically saved to historical collection
- Similarity scoring system for plagiarism detection (field exists but implementation may be incomplete)

## Firebase Configuration

The app requires Firebase setup with:
- **Authentication**: Email/password authentication enabled
- **Firestore**: Database with proper security rules for student/teacher/admin access
- **firebase_options.dart**: Auto-generated configuration file

To regenerate Firebase options:
```powershell
flutterfire configure
```

## Code Style Guidelines

Based on `analysis_options.yaml` configuration:
- Prefer const constructors where possible
- Use const for immutable collections  
- Make fields final when they won't change
- Avoid unnecessary `this` references
- Print statements are allowed (avoid_print: false)

## Testing Strategy

- Widget tests exist in `test/widget_test.dart`
- Focus testing on:
  - Authentication flows
  - Project submission validation (4-project limit)
  - Role-based access control
  - Firebase service operations

## Development Notes

- App uses Material 3 design system with custom theming
- Blue color scheme (seedColor: `#2196F3`)
- Responsive design considerations for different screen sizes
- All navigation uses standard MaterialPageRoute
- No complex state management beyond Provider for service injection