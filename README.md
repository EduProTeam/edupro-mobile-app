# EduPro

> **Community Skill-Exchange & Micro-Learning Mobile Application**

EduPro is a mobile learning platform designed to connect learners, peer tutors, skill providers, and educational content creators in one place. The application combines **skill sharing**, **micro-learning**, **recorded courses**, **educational posts**, **community discussions**, and planned **AI-assisted learning support**.

The project is built with **Flutter**, **Firebase**, and **Supabase**.

---

## Project Overview

Many learners need affordable, flexible, and easy-to-access learning opportunities, while skilled people often have no simple platform to share their knowledge and reach learners.

EduPro aims to solve this by providing a mobile-first community where users can:

- Learn practical or academic skills.
- Discover and share educational content.
- Publish and follow recorded courses.
- Join educational discussion groups.
- Share learning materials.
- Build profiles as learners, tutors, or skill providers.
- Interact with educational posts through likes and comments.
- Track course progress.
- Access planned notification and AI-chatbot support.

The product concept supports **SDG 4 – Quality Education** and **SDG 8 – Decent Work and Economic Growth**.

---

## Main Users

EduPro is designed around four main user types:

- **Skill Seekers** – users looking for affordable and trustworthy learning opportunities.
- **Skill Providers** – experienced people who want to teach their skills and reach learners.
- **Micro-Entrepreneurs** – small business owners who may need quick and affordable skill development.
- **Peer Tutors** – students or professionals who want to teach others and build a reputation.

---

## Core Features

### 1. Authentication & Onboarding

- Email and password registration.
- Sign in and sign out using Firebase Authentication.
- User onboarding flow.
- User profile setup and editing.
- Profile photo upload, replacement, and removal.

### 2. Educational Posts

- Create educational posts with:
  - Title
  - Category
  - Content
  - Tags
  - Visibility
- Attach one image, video, document, or link.
- Publish posts or save them as drafts.
- Like and unlike posts.
- Read and add comments.
- Edit or delete your own comments.
- Edit your own posts.
- Delete posts using soft deletion.
- Display the author's latest profile photo.
- Search and browse educational content.

### 3. Recorded Courses

- Create free or paid course listings.
- Add course thumbnails.
- Add lesson videos and supporting files.
- Save courses as drafts or publish them.
- Search and sort courses.
- Enroll in courses.
- Track completed lessons.
- Track learning progress.
- Play lesson videos inside the application.
- Manage created courses.
- Creator verification quiz before saving a new course.

> Paid-course checkout is currently a demonstration and does not process real payments.

### 4. Skill Sharing

The Skill Sharing module is designed to support:

- Browsing available skills.
- Searching skills.
- Skill categories.
- Skill provider information.
- Ratings.
- A **Share Your Skill** flow.
- Future support for availability, pricing, and session types.

> Some skill-sharing functionality is still under development.

### 5. Educational Chat Groups

- Browse and search educational groups.
- Filter by category.
- View joined groups.
- Create groups.
- Join and leave groups.
- Exchange text messages in real time.
- Manage group information.
- Manage group administrators.

### 6. Learning Materials

EduPro supports learning-material sharing through educational posts and course content, including:

- Documents
- Images
- Videos
- Links
- Course supporting files

### 7. Notifications & AI Chatbot

The project scope includes:

- Educational notifications.
- Quick access to an AI-assisted learning chatbot/tutor.
- Support for students who need on-demand academic help.

> These features are part of the project roadmap and may not be fully implemented yet.

---

## Jira Epics

The project is organized into the following main Jira epics:

| Epic | Name |
|---|---|
| EP-1 | Project Setup & Agile Planning |
| EP-2 | Authentication & Onboarding |
| EP-3 | Recorded Courses |
| EP-4 | Profile & Settings |
| EP-5 | Skill Sharing |
| EP-6 | Educational Chat Groups |
| EP-7 | Notifications & AI Chatbot |
| EP-8 | Home Navigation & Educational Posts |
| EP-9 | Learning Materials |
| EP-10 | Integration & Testing |

---

## UX Design Approach

The user experience was designed using:

1. User research
2. Personas
3. Empathy maps
4. User stories
5. User flows
6. Service blueprinting
7. Alternative sketches
8. Wireframes
9. Final wireframe selection

The design focuses on:

- Simple navigation
- Clear information hierarchy
- Low user effort
- Easy content discovery
- Visible actions
- Consistent navigation
- Mobile-first usability
- Scalability for future features

---

## Important UX Flows

The product research and design process identified these major flows:

### Learner Skill Discovery

`Open App → Select Learner → Set Location & Language → Browse Skills → Filter → View Provider → Select Session / Book`

### Become a Skill Provider

`Teach a Skill → Complete Profile → Add Rates → Verification → Review → Approval → Profile Goes Live`

### Booking & Payment

`Select Provider → View Time Slots → Confirm Booking → Payment → Confirmation → Calendar`

### Session Completion

`Attend Session → Mark Complete → Rate & Review → Rating Updates → Next Skill Suggestion`

> These flows represent the broader product design. Some booking, payment, and provider features are not yet fully implemented in the current application.

---

## Technology Stack

| Component | Technology |
|---|---|
| Mobile Application | Flutter & Dart |
| UI | Material 3 |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Real-time Updates | Cloud Firestore |
| Media Storage | Supabase Storage |
| Media Selection | `image_picker`, `file_picker` |
| Video Playback | `video_player` |
| SVG Support | `flutter_svg` |
| Testing | `flutter_test` |
| Linting | `flutter_lints` |
| Project Management | Jira |
| Version Control | Git & GitHub |

Firebase user tokens are used to access Supabase through Firebase third-party authentication integration.

---

## Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── supabase_options.dart
│
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── splash/
│   ├── home/
│   ├── profile/
│   ├── posts/
│   ├── courses/
│   ├── chat/
│   └── settings/
│
assets/
docs/
test/
```

### Main Folders

| Folder | Purpose |
|---|---|
| `auth/` | Registration and sign-in |
| `onboarding/` | Introductory screens |
| `splash/` | Application startup screen |
| `home/` | Home navigation and feed |
| `profile/` | User profile management |
| `posts/` | Educational post functionality |
| `courses/` | Recorded courses, enrollment, and progress |
| `chat/` | Groups and messaging |
| `settings/` | Application settings |
| `assets/` | Logos, illustrations, and other assets |
| `docs/` | Feature and backend documentation |
| `test/` | Automated tests |

---

## Data Overview

Main Firestore collections and paths:

| Firestore Path | Purpose |
|---|---|
| `users/{userId}` | User profile and profile-photo metadata |
| `posts/{postId}` | Educational posts, attachments, likes, and counts |
| `posts/{postId}/comments/{commentId}` | Post comments |
| `courses/{courseId}` | Course details, lessons, and media references |
| `users/{userId}/courseEnrollments/{courseId}` | Enrollment and lesson progress |
| `groups/{groupId}` | Group details, members, and administrators |
| `groups/{groupId}/messages/{messageId}` | Group messages |
| `categories/{categoryId}` | Group category data |

---

## Getting Started

### Requirements

Before running the application, install or configure:

- Flutter with a Dart SDK compatible with `^3.12.2`
- Android Studio
- Android Emulator or a physical Android device
- Firebase project
- Supabase project
- FlutterFire CLI when configuring a new Firebase project

For iOS development, macOS and Xcode are required.

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/EduProTeam/edupro-mobile-app.git
cd edupro-mobile-app
```

### 2. Check Flutter setup

```bash
flutter doctor
```

### 3. Install dependencies

```bash
flutter pub get
```

---

## Firebase Configuration

1. Create or use a Firebase project.
2. Enable **Email/Password** authentication.
3. Create a **Cloud Firestore** database.
4. Configure the project using FlutterFire.
5. Check:
   - `lib/firebase_options.dart`
   - `firebase.json`
   - Platform-specific Firebase files
6. Configure and deploy proper Firestore security rules.

> Do not rely only on client-side ownership checks. Database access must also be protected using Firestore rules.

---

## Supabase Configuration

1. Create or use a Supabase project.
2. Set the project URL and publishable key in:

```text
lib/supabase_options.dart
```

3. Create the private storage bucket:

```text
edupro-media
```

4. Enable Firebase third-party authentication.
5. Configure authenticated storage policies for:
   - Uploads
   - Signed URLs
   - File deletion

> Never place a Supabase service-role key inside the Flutter client application.

---

## Run the Application

Check connected devices:

```bash
flutter devices
```

Run the project:

```bash
flutter run
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

---

## Build Release APK

```bash
flutter build apk --release
```

---

## Testing

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

Example educational-post tests:

```bash
flutter test \
  test/post_actions_menu_test.dart \
  test/edit_post_test.dart \
  test/post_comments_sheet_test.dart \
  test/post_like_button_test.dart
```

Tests also cover course forms, course management, and enrollment behavior.

---

## Current Development Status

### Implemented / Available

- Firebase authentication
- Onboarding
- Profile management
- Profile photos
- Educational post creation and management
- Post likes
- Post comments
- Recorded course creation
- Course enrollment
- Course progress tracking
- Lesson video playback
- Group creation and membership
- Real-time group messaging
- Firebase + Supabase integration

### In Progress / Planned

- Complete Skill Sharing workflow
- AI educational chatbot
- Notifications
- Production-ready paid-course checkout
- Provider verification workflow
- Booking and session management
- Full payment workflow
- Saved-course persistence
- Password reset backend integration

---

## Current Limitations

- Password reset UI exists, but the backend action is not connected.
- Profile sharing is not fully implemented.
- Add Skill functionality is still incomplete.
- Saved-course state is not yet persisted.
- Paid checkout is only a demonstration.
- Signed media links do not currently enforce paid-content entitlement.
- Post visibility requires compatible backend security rules and queries.
- Course creator verification uses predefined client-side questions.
- Soft-deleted posts and unused media are retained.
- Automatic signed URL renewal is not implemented.
- Web support needs additional work because some file features depend on `dart:io`.

---

## Team

| Member | Student ID | Primary UX Feature |
|---|---|---|
| Perera H. C. T. | IT23727472 | Recorded Courses |
| Dilhara H. S. | IT23815896 | Skill Share |
| D. M. T. Shamendra | IT23664012 | Educational Post & Material Sharing |
| De Silva A. Y. R. | IT23549104 | Community Chat Groups & AI Chatbot |

**Group:** 051  
**Academic Year:** 2026

---

## Feature Documentation

Additional documentation is available in the `docs/` directory for areas such as:

- Post likes and unlikes
- Comments, editing, and deletion
- Post editing
- Post deletion
- Course persistence and enrollment
- Course media setup
- Course creator verification

---

## Future Improvements

- Complete the Skill Sharing module.
- Add provider booking and availability management.
- Add ratings and reviews for skill providers.
- Implement production payment integration.
- Add push notifications.
- Implement AI-powered educational assistance.
- Improve accessibility for users with low digital literacy.
- Add better moderation and reporting tools.
- Improve multi-platform compatibility.
- Expand automated and integration testing.

---

## Repository

**GitHub:** https://github.com/EduProTeam/edupro-mobile-app

---

## Project Note

EduPro is an academic project under active development. Some features represent the final product vision and UX design while others are already implemented in the current Flutter application.

Always validate Firebase and Supabase security rules before using the application in a production or shared environment.
