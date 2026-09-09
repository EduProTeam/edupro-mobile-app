# EduPro

**A community skill exchange and microlearning mobile application built with Flutter, Firebase, and Supabase.**

EduPro brings educational posts, recorded courses, and group discussions into one app. Learners can share knowledge, interact with posts, enroll in courses, and track lesson completion. Creators can publish learning materials and manage their own content.

## Features

### Accounts and profiles

- Email and password registration, sign-in, and sign-out using Firebase Authentication.
- Onboarding and a profile editor.
- Profile photo upload, replacement, and removal.
- Educational post cards display the author's current profile photo.

### Educational posts

- Create posts with a title, category, content, tags, and a visibility selection.
- Attach an image, video, document, or link; one attachment per post.
- Publish posts or save drafts.
- Like and unlike posts, with at most one active like per user per post.
- Read and submit comments with live comment counts.
- Edit or delete your own comments.
- Edit your own posts, including retaining, removing, or replacing attachments.
- Delete your own posts after confirmation. Post deletion is a **soft delete**: it removes the post from the feed while retaining database records and uploaded files.

### Recorded courses

- Create free or paid course listings with thumbnails, lesson videos, and supporting files.
- Save drafts, publish courses, and manage your own courses.
- Search and sort course listings.
- Complete a topic-specific creator verification quiz before saving a new course; the required score is 4 out of 5.
- Enroll in courses and persist lesson completion and learning progress.
- Play lesson videos within the app.

Paid-course checkout is currently a demonstration and does not charge money. Creator verification uses predefined, client-side questions rather than an external AI service.

### Group discussions

- Browse and search groups, including category and My Groups filters.
- Create, join, and leave groups.
- Exchange text messages in real time.
- Manage group details and administrators through the group management screens.

## Technology

| Component | Technology |
| --- | --- |
| Application | Flutter and Dart, Material 3 |
| Authentication | Firebase Authentication |
| Database and live updates | Cloud Firestore |
| Uploaded media | Supabase Storage, private `edupro-media` bucket |
| Media selection | `image_picker`, `file_picker` |
| Lesson playback | `video_player` |
| SVG assets | `flutter_svg` |
| Testing and linting | `flutter_test`, `flutter_lints` |

Firebase user tokens are used to access Supabase through its Firebase third-party authentication integration. Media metadata and signed URLs are stored in Firestore.

## Getting started

### Requirements

- Flutter with a Dart SDK compatible with `^3.12.2`, as specified in `pubspec.yaml`.
- Android Studio and an Android emulator, or a connected Android device with debugging enabled.
- Access to the Firebase and Supabase projects used by the app, or your own configured projects.
- For iOS builds, macOS with Xcode and the required Flutter iOS tooling.

Android is the straightforward starting target. Platform folders are also present for iOS, web, Windows, macOS, and Linux, but their presence does not establish full feature compatibility. Linux Firebase options are not configured, and file-based features use `dart:io`, so web support needs additional work.

### Install dependencies

From the repository root:

```sh
flutter doctor
flutter pub get
```

### Configure Firebase

1. Enable Email/Password sign-in in Firebase Authentication.
2. Create or use a Cloud Firestore database.
3. Check the existing project configuration in `lib/firebase_options.dart`, `firebase.json`, and the platform configuration files. For a different Firebase project, regenerate the configuration using the FlutterFire CLI rather than reusing the existing project identifiers.
4. Configure and deploy Firestore rules for profiles, posts, comments, courses, enrollments, groups, and messages.

Feature-specific rule examples are linked below. **Deployed Firestore rules are not tracked in this repository.** Merge and validate the examples against your actual project; a client-side ownership check alone does not secure database access. Group membership and administrator permissions also need corresponding database rules.

### Configure Supabase

1. Set the project URL, publishable key, and bucket name in `lib/supabase_options.dart`.
2. Create the private `edupro-media` storage bucket.
3. Enable Firebase third-party authentication for the Firebase project used by the app.
4. Configure authenticated storage policies for uploads, signed URL creation, and deletion, using the Firebase user ID in the first segment of each object path.

See [course persistence setup](docs/course-persistence.md) for storage policy requirements and media limitations. Use a publishable client key in the app; never add a Supabase service-role key to client code.

### Run the app

```sh
flutter devices
flutter run
```

When multiple devices are connected, select one with `flutter run -d <device-id>`.

To create a release APK after configuring the Android build environment:

```sh
flutter build apk --release
```

## Project structure

```text
lib/
  main.dart                 App startup and Firebase initialization
  firebase_options.dart     Firebase platform configuration
  supabase_options.dart     Supabase client and bucket configuration
  features/
    auth/                   Registration and sign-in
    onboarding/             Introductory screens
    splash/                 Startup screen
    home/                   Main navigation and educational feed
    profile/                Profile editing and photos
    posts/                  Post publishing, likes, comments, and owner actions
    courses/                Course creation, enrollment, progress, and playback
    chat/                   Groups, membership, and messaging
    settings/               Settings interface
assets/                     App illustrations and logos
docs/                       Feature setup and backend rule guidance
test/                       Automated tests
```

## Data overview

| Firestore path | Purpose |
| --- | --- |
| `users/{userId}` | User profile and profile photo metadata |
| `posts/{postId}` | Educational content, author, attachment metadata, likes, and counts |
| `posts/{postId}/comments/{commentId}` | Comments and their authors |
| `courses/{courseId}` | Course details, lessons, media references, and enrollment count |
| `users/{userId}/courseEnrollments/{courseId}` | Enrollment and completed lesson IDs |
| `groups/{groupId}` | Group details, members, and administrators |
| `groups/{groupId}/messages/{messageId}` | Group messages |
| `categories/{categoryId}` | Group category names |

## Tests and checks

```sh
flutter analyze
flutter test
```

To run the post feature tests:

```sh
flutter test test/post_actions_menu_test.dart test/edit_post_test.dart test/post_comments_sheet_test.dart test/post_like_button_test.dart
```

Tests also cover course forms, course management, and enrollment behavior. Widget tests do not verify deployed Firebase rules or live Supabase policies; check those separately with the configured backend. No current full-suite pass is claimed by this README.

## Feature documentation

- [Post likes and unlikes](docs/post-likes.md)
- [Comments, editing, and deletion](docs/post-comments.md)
- [Editing your own posts](docs/post-editing.md)
- [Deleting your own posts](docs/post-deletion.md)
- [Course persistence, enrollment, and media setup](docs/course-persistence.md)
- [Course creator verification](docs/course-verification.md)

## Current limitations

- Password reset has a screen but its backend action is not connected.
- Profile sharing and Add Skill are placeholders; saved-course state is not yet persisted.
- Paid checkout is a demo, and signed media links do not enforce paid-content entitlement.
- Post visibility is selectable in the form; follower-only access must be enforced through backend rules and compatible queries.
- Creator verification is a client-side academic demonstration, not a trusted credential check.
- Soft-deleted posts and unused media are retained. Permanent cleanup and automatic signed URL renewal are not implemented.

This repository is under active development. Consult the feature documentation before enabling backend writes in a shared environment.
