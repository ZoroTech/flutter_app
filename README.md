# Mini Project Approval System

A Flutter app for managing mini project submissions with AI-powered similarity analysis and smart domain assignment.

## 🚀 Features

### 🐛 Recent Bug Fixes
- ✅ **Fixed Teacher Dropdown Issue**: Teacher selection dropdown now remains enabled after data loads
- ✅ **Fixed Infinite Dashboard Refresh**: Student dashboard no longer gets stuck in refresh loops
- ✅ **Past Projects Visibility**: All users (students, teachers, admins) can view past project archive

### 🤖 AI-Powered Similarity Analysis
- **TF-IDF + Cosine Similarity**: Advanced text analysis algorithm for project comparison
- **Smart Domain Assignment**: Automatically suggests project domains based on similar past projects
- **Similarity Preview**: Shows top 3 most similar existing projects with percentage scores
- **High Similarity Warning**: Alerts students when projects are >70% similar to existing ones
- **Real-time Analysis**: Instant similarity checking before project submission

### 💡 Enhanced User Experience
- **Rich Similarity UI**: Beautiful analysis dialog with detailed project comparisons
- **Loading States**: Smooth loading indicators during similarity analysis
- **Offline Support**: Graceful handling of network connectivity issues
- **Smart Suggestions**: Domain recommendations based on historical project data
- **Multiple Submission Options**: Choose between similarity check or direct submission

## 🛠️ Technical Implementation

### New Services
- **`similarity_service.dart`**: Core TF-IDF similarity algorithm with text preprocessing
- **`similarity_check_widget.dart`**: Comprehensive UI for similarity analysis results
- **Enhanced `database_service.dart`**: Added similarity checking methods with offline support

### Similarity Algorithm Features
- Text preprocessing (lowercase, punctuation removal, normalization)
- Stop word filtering for better accuracy
- Term frequency calculation
- Cosine similarity computation
- Domain confidence scoring
- Configurable similarity thresholds

## 📱 How Similarity Analysis Works

1. **Student enters project title and description**
2. **Clicks "Check Similarity" button**
3. **System analyzes text against all approved projects**
4. **Displays similarity percentages and suggested domain**
5. **Shows warning if high similarity detected (>70%)**
6. **Student can edit, cancel, or proceed with submission**

## 🔧 Setup

1. **Clone the repository**
2. **Run `flutter pub get`**
3. **Configure Firebase (credentials not included)**
4. **Run `flutter run`**

## 📊 Testing

- ✅ **Teacher dropdown works 100% of the time**
- ✅ **Student dashboard stable (no infinite refresh)**
- ✅ **Past projects visible to all user types**
- ✅ **Similarity analysis shows accurate results**
- ✅ **Domain suggestions based on similar projects**
- ✅ **High similarity warnings display correctly**

## 🚀 Recent Updates

### Branch: `feature/similarity-and-fixes`
- Fixed critical bugs in student registration and dashboard
- Added complete AI-powered similarity analysis system
- Enhanced UI with rich similarity preview dialogs
- Improved offline handling and error management
- Updated dependencies and fixed deprecation warnings

---

**Built with Flutter + Firebase + AI-powered text analysis**
