# EduPro unit testing report

Verified on 17 October 2026 (Asia/Colombo). Flutter/Dart versions and build outcome appear in the execution details below. This report uses actual test-run JSON events and LCOV line records; results are not estimated.

## Objectives and scope

Test EduPro's existing business decisions, validation boundaries, serialization, authorization, persistence requests, and error handling independently of live services. Preserve application behavior and existing tests. Use Arrange, Act, Assert (AAA), fresh mocks in each test, descriptive names, and stable IDs in every new case.

## Project inspection

The project contains Flutter application code in lib/, assets/, platform runners in android/, ios/, web/, windows/, macos/, and linux/, existing tests in test/, supporting tools in tool/, and feature documentation in docs/. merge-resolution/ is an excluded saved merge artifact. build/ and .dart_tool/ are generated output.

| Area | Existing implementation and testable logic |
| --- | --- |
| Authentication | AuthService; login, registration and forgot-password forms; Firebase error mapping, account/profile creation, cleanup, profile updates and sign-out. |
| Educational posts | PostService, PostModerationService, PublishedPost, PostComment, attachment types, categories, blocked-word matching, post/share links. Create/edit/soft-delete, ownership, likes, comments, bookmarks and streams. |
| Home feed | filterHomePosts searches title/content/author/category/tags, filters by owner/category, ranks engagement and date. Existing unit tests retained. |
| User profile | Profile updates are implemented by AuthService and Firestore maps. ProfilePhotoService and sharing helpers exist. There is no standalone User/Profile serialization model to test. |
| Courses and learning | CourseDraft, CourseLesson, CourseMedia, CourseEnrollment, CourseService, CourseVerificationService; publishing validation, quizzes, enrollment transactions, lesson completion and progress. |
| Messaging and groups | MessageModel, GroupModel, GroupMemberModel, ChatService, GroupService; message trimming, profile lookup, group filtering, membership, admin permissions, reassignment and ordering. |
| Skill sharing | SkillSharingStore extends ChangeNotifier with local/demo and Firebase modes; requests, offers, saved IDs, scheduled sessions, meeting links and model helpers. |
| Other code | AppThemeController handles persisted preference state; link-sharing helpers, Firebase startup, splash timing, onboarding and branding exist. Existing tests remain. There are no separate repository/provider layers. |

Before this change the suite contained 29 test files and 177 runnable cases, mixing unit and widget tests. The final suite contains 41 test files. New tests are organized only into models/, services/, utils/ and helpers/; no empty repository/provider directories were created.

## Framework and isolation

- flutter_test supplies test groups, expectations, async/stream assertions and the existing widget harness.
- mocktail is declared as ^1.0.4 and locked to 1.0.5; no generated mocks are required.
- FirebaseAuth, users/credentials, Firestore collections/documents/queries/snapshots and transactions are mocked. Tests execute real service callbacks and inspect intended writes and failures.
- No new test initializes Firebase, connects to Supabase/production databases, reads real credentials, or sends messages. Fixture identities are synthetic. Link attachments and media metadata are inert fixture strings.
- Fresh setup state and explicit disposal/cancellation keep cases independent. Transactions are SDK boundary mocks, not a Firestore implementation or security-rules emulator.

## Changes made for testability

Existing email/password/name/confirmation rules were extracted to AuthValidators and ProfileValidators. Screens delegate to those exact rules and retain their submission guards. ChatService and GroupService gained optional Firebase dependencies with their original default instances. The existing clamped learning-progress ratio was extracted to calculateLearningProgress and reused by the learning screen. No new validation policy, feature or UI redesign was introduced.

Three retained widget-test files had stale assumptions and were repaired: the course verification test now asserts the existing verification gate, lesson and course controls wait for scrolling to render, and the skill scheduling test uses the current Accept Request label. Their intended behavior assertions remain.

## Execution results

| Run | Executed cases | Passed | Failed | Skipped | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| New unit tests only | 297 | 297 | 0 | 0 | Pass |
| Full suite: flutter test | 474 | 474 | 0 | 0 | Pass |
| Full suite: flutter test --coverage | 474 | 474 | 0 | 0 | Pass |

Counts exclude suite-loading, setUpAll and tearDownAll events. Repeated verification runs are not added together as extra tests.

| New unit-test module | Implemented | Passed | Failed |
| --- | ---: | ---: | ---: |
| Messaging | 14 | 14 | 0 |
| Groups | 36 | 36 | 0 |
| Courses | 78 | 78 | 0 |
| Post models | 7 | 7 | 0 |
| Skill sharing | 31 | 31 | 0 |
| Authentication | 67 | 67 | 0 |
| User profile | 11 | 11 | 0 |
| Educational posts | 53 | 53 | 0 |

## Code coverage

| Coverage run | Covered executable lines | Instrumented executable lines | Line coverage |
| --- | ---: | ---: | ---: |
| New unit tests only | 1107 | 9617 | 11.51% |
| Complete retained + new suite | 5433 | 9672 | 56.17% |

Coverage is calculated from DA records in coverage/unit_lcov.info and coverage/lcov.info: covered lines / instrumented lines × 100. This is executable line coverage for libraries instrumented by these runs, not branch coverage or a claim that every application file is covered. The complete-suite value includes retained widget tests. No threshold or exclusions were added to inflate results.

Business-logic coverage by file, with retained tests included in the complete-suite column:

| File | New unit tests: covered / instrumented | Complete suite: covered / instrumented |
| --- | ---: | ---: |
| lib/features/chat/models/group_model.dart | 29/29 (100.00%) | 29/29 (100.00%) |
| lib/features/chat/models/message_model.dart | 19/19 (100.00%) | 19/19 (100.00%) |
| lib/features/posts/models/blocked_word_filter.dart | 21/27 (77.78%) | 27/27 (100.00%) |
| lib/features/posts/models/post_comment.dart | 11/12 (91.67%) | 11/12 (91.67%) |
| lib/features/posts/services/post_moderation_service.dart | 14/21 (66.67%) | 21/21 (100.00%) |
| lib/features/posts/services/post_service.dart | 188/384 (48.96%) | 298/384 (77.60%) |
| lib/features/auth/validation/auth_validators.dart | 15/15 (100.00%) | 15/15 (100.00%) |
| lib/features/auth/services/auth_service.dart | 69/71 (97.18%) | 69/71 (97.18%) |
| lib/features/chat/models/group_member_model.dart | 1/1 (100.00%) | 1/1 (100.00%) |
| lib/features/chat/services/chat_service.dart | 30/32 (93.75%) | 30/32 (93.75%) |
| lib/features/chat/services/group_service.dart | 153/180 (85.00%) | 153/180 (85.00%) |
| lib/features/courses/models/course_draft.dart | 73/73 (100.00%) | 73/73 (100.00%) |
| lib/features/courses/services/course_service.dart | 129/164 (78.66%) | 129/164 (78.66%) |
| lib/features/courses/services/course_verification_service.dart | 35/35 (100.00%) | 35/35 (100.00%) |
| lib/features/home/models/home_feed_filter.dart | 0/23 (0.00%) | 23/23 (100.00%) |
| lib/features/profile/validation/profile_validators.dart | 3/3 (100.00%) | 3/3 (100.00%) |
| lib/features/skill_sharing/models/skill_models.dart | 18/18 (100.00%) | 18/18 (100.00%) |
| lib/features/skill_sharing/services/skill_sharing_store.dart | 258/270 (95.56%) | 258/270 (95.56%) |

## Test case summary

Each ID below corresponds to one independently executed new unit case. Parameterized cases are counted separately only when the test runner reports a distinct case. Expected results describe the implemented assertions; actual results are taken from the final unit-only execution, also cross-checked against the complete runs.

| Test ID | Module | Test Scenario | Expected Result | Actual Result | Status |
| --- | --- | --- | --- | --- | --- |
| AUTH001 | Authentication | returns the credential and trims only the email | Returns the exact Firebase credential; trims email to learner@example.com and preserves password whitespace; performs no Firestore work. | All expected assertions passed. | Pass |
| AUTH002 | Authentication | maps sign-in error invalid-email to a useful failure | Throws AuthFailure: Enter a valid email address. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH003 | Authentication | maps sign-in error invalid-credential to a useful failure | Throws AuthFailure: Incorrect email or password. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH004 | Authentication | maps sign-in error user-not-found to a useful failure | Throws AuthFailure: Incorrect email or password. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH005 | Authentication | maps sign-in error wrong-password to a useful failure | Throws AuthFailure: Incorrect email or password. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH006 | Authentication | maps sign-in error user-disabled to a useful failure | Throws AuthFailure: This account has been disabled. Please contact support. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH007 | Authentication | maps sign-in error operation-not-allowed to a useful failure | Throws AuthFailure: Email/password sign-in is not enabled for this project yet. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH008 | Authentication | maps sign-in error network-request-failed to a useful failure | Throws AuthFailure: Please check your internet connection and try again. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH009 | Authentication | maps sign-in error too-many-requests to a useful failure | Throws AuthFailure: Too many attempts were made. Please wait a bit and try again. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH010 | Authentication | maps sign-in error invalid-api-key to a useful failure | Throws AuthFailure: This Firebase app configuration is invalid. Please check the project setup. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH011 | Authentication | maps sign-in error app-not-authorized to a useful failure | Throws AuthFailure: This app is not authorized in Firebase. Please check the Android app configuration. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH012 | Authentication | maps sign-in error internal-error to a useful failure | Throws AuthFailure: Firebase returned an internal error. Please try again in a moment. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH013 | Authentication | maps sign-in error channel-error to a useful failure | Throws AuthFailure: The request could not be sent. Please restart the app and try again. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH014 | Authentication | maps sign-in error unexpected-code to a useful failure | Throws AuthFailure: Could not sign you in right now. Please try again. No Firestore work occurs. | All expected assertions passed. | Pass |
| AUTH015 | Authentication | maps unexpected sign-in exceptions to a generic failure | Throws AuthFailure: Something went wrong while signing you in. Please try again. | All expected assertions passed. | Pass |
| AUTH016 | Authentication | saves a trimmed student profile after creating an account | Creates the account with trimmed email and unchanged password, updates the trimmed display name, and saves uid/name/email, student/password defaults, null image, incomplete-profile flag, and server timestamps; does not delete the user. | All expected assertions passed. | Pass |
| AUTH017 | Authentication | skips display-name updates when the trimmed name is empty | Skips display-name update for a whitespace-only name, saves fullName as an empty string, and does not delete the user. | All expected assertions passed. | Pass |
| AUTH018 | Authentication | fails safely when Firebase returns no created user | Throws AuthFailure: Your account could not be created right now. Please try again. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH019 | Authentication | maps registration error email-already-in-use without saving a profile | Throws AuthFailure: That email address is already in use. Try logging in instead. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH020 | Authentication | maps registration error invalid-email without saving a profile | Throws AuthFailure: Enter a valid email address. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH021 | Authentication | maps registration error weak-password without saving a profile | Throws AuthFailure: Choose a stronger password with at least 6 characters. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH022 | Authentication | maps registration error operation-not-allowed without saving a profile | Throws AuthFailure: Email/password sign-up is not enabled for this project yet. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH023 | Authentication | maps registration error network-request-failed without saving a profile | Throws AuthFailure: Please check your internet connection and try again. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH024 | Authentication | maps registration error too-many-requests without saving a profile | Throws AuthFailure: Too many attempts were made. Please wait a bit and try again. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH025 | Authentication | maps registration error configurations-not-found without saving a profile | Throws AuthFailure: Firebase Authentication is not configured correctly for this app yet. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH026 | Authentication | maps registration error invalid-api-key without saving a profile | Throws AuthFailure: This Firebase app configuration is invalid. Please check the project setup. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH027 | Authentication | maps registration error app-not-authorized without saving a profile | Throws AuthFailure: This app is not authorized in Firebase. Please check the Android app configuration. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH028 | Authentication | maps registration error internal-error without saving a profile | Throws AuthFailure: Firebase returned an internal error. Please try again in a moment. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH029 | Authentication | maps registration error channel-error without saving a profile | Throws AuthFailure: The request could not be sent. Please restart the app and try again. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH030 | Authentication | maps registration error unexpected-code without saving a profile | Throws AuthFailure: Could not create your account right now. Please try again. Performs no profile work or user deletion. | All expected assertions passed. | Pass |
| AUTH031 | Authentication | deletes the created account if storing its profile fails | Deletes the created user once and throws AuthFailure: Your account was created, but we could not finish saving your profile. Please try again. | All expected assertions passed. | Pass |
| AUTH032 | Authentication | preserves profile-save failure if account cleanup also fails | Attempts user deletion once and preserves the profile-save AuthFailure even when deletion fails: Your account was created, but we could not finish saving your profile. Please try again. | All expected assertions passed. | Pass |
| AUTH033 | Authentication | rolls back a created account for unexpected profile errors | Deletes the created user once and throws AuthFailure: Something went wrong while creating your account. Please try again. | All expected assertions passed. | Pass |
| AUTH034 | Authentication | preserves a domain failure and rolls back the created account | Rethrows the same AuthFailure instance with message Profile is temporarily unavailable. and deletes the created user once. | All expected assertions passed. | Pass |
| AUTH035 | Authentication | rolls back if updating the created display name fails | Deletes the created user once, performs no Firestore work, and throws AuthFailure: Something went wrong while creating your account. Please try again. | All expected assertions passed. | Pass |
| AUTH036 | User profile | merges editable profile fields and updates the display name | Updates the display name and merges all editable profile fields plus an updatedAt server timestamp using SetOptions(merge: true). | All expected assertions passed. | Pass |
| AUTH037 | User profile | persists null optional fields and empty skill lists | Explicitly saves null username, phone, organization, professionalTitle and bio, plus empty skills and learningInterests lists. | All expected assertions passed. | Pass |
| AUTH038 | User profile | rejects profile updates without a signed-in user | Throws AuthFailure: No signed-in user is available. Performs no Firestore work or display-name update. | All expected assertions passed. | Pass |
| AUTH039 | User profile | maps Firestore update errors to a profile failure | Throws AuthFailure: Unable to update profile. Please try again. Does not delete the signed-in user. | All expected assertions passed. | Pass |
| AUTH040 | User profile | stops before saving if the display-name update fails | Throws AuthFailure: Unable to update profile. Please try again. Performs no Firestore work or user deletion after display-name failure. | All expected assertions passed. | Pass |
| AUTH041 | User profile | maps unexpected profile update errors to a profile failure | Throws AuthFailure: Unable to update profile. Please try again. | All expected assertions passed. | Pass |
| AUTH042 | Authentication | signs out exactly once without changing profile data | Calls Firebase signOut exactly once and performs no Firestore work. | All expected assertions passed. | Pass |
| AUTH043 | Authentication | propagates sign-out failures to the caller | Propagates the exact FirebaseAuthException instance from signOut. | All expected assertions passed. | Pass |
| AUTH101 | Authentication | email accepts an ordinary email | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH102 | Authentication | email accepts surrounding whitespace | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH103 | Authentication | email accepts a subdomain and plus address | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH104 | Authentication | email rejects null | Returns validation message: Enter your email address. | All expected assertions passed. | Pass |
| AUTH105 | Authentication | email rejects an empty value | Returns validation message: Enter your email address. | All expected assertions passed. | Pass |
| AUTH106 | Authentication | email rejects whitespace only | Returns validation message: Enter your email address. | All expected assertions passed. | Pass |
| AUTH107 | Authentication | email rejects a missing at sign | Returns validation message: Enter a valid email address. | All expected assertions passed. | Pass |
| AUTH108 | Authentication | email rejects a missing domain suffix | Returns validation message: Enter a valid email address. | All expected assertions passed. | Pass |
| AUTH109 | Authentication | email rejects an empty local part | Returns validation message: Enter a valid email address. | All expected assertions passed. | Pass |
| AUTH110 | Authentication | email rejects embedded whitespace | Returns validation message: Enter a valid email address. | All expected assertions passed. | Pass |
| AUTH111 | Authentication | email rejects multiple at signs | Returns validation message: Enter a valid email address. | All expected assertions passed. | Pass |
| AUTH112 | Authentication | login password rejects null | Returns validation message: Enter your password. | All expected assertions passed. | Pass |
| AUTH113 | Authentication | login password rejects an empty password | Returns validation message: Enter your password. | All expected assertions passed. | Pass |
| AUTH114 | Authentication | login password allows a short existing password | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH115 | Authentication | login password preserves whitespace as password characters | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH116 | Authentication | registration full name rejects null | Returns validation message: Enter your full name. | All expected assertions passed. | Pass |
| AUTH117 | Authentication | registration full name rejects whitespace only | Returns validation message: Enter your full name. | All expected assertions passed. | Pass |
| AUTH118 | Authentication | registration full name accepts a single character under the existing rule | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH119 | Authentication | registration full name accepts a trimmed full name | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH120 | Authentication | registration password rejects null | Returns validation message: Enter a password. | All expected assertions passed. | Pass |
| AUTH121 | Authentication | registration password rejects an empty password | Returns validation message: Enter a password. | All expected assertions passed. | Pass |
| AUTH122 | Authentication | registration password rejects five characters | Returns validation message: Password must be at least 6 characters. | All expected assertions passed. | Pass |
| AUTH123 | Authentication | registration password accepts the six character boundary | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH124 | Authentication | registration password accepts more than six characters | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH125 | Authentication | registration password counts whitespace under the existing rule | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH126 | Authentication | password confirmation rejects null | Returns validation message: Confirm your password. | All expected assertions passed. | Pass |
| AUTH127 | Authentication | password confirmation rejects an empty confirmation | Returns validation message: Confirm your password. | All expected assertions passed. | Pass |
| AUTH128 | Authentication | password confirmation accepts an exact match | Returns null (valid under the existing rule). | All expected assertions passed. | Pass |
| AUTH129 | Authentication | password confirmation rejects different case | Returns validation message: Passwords do not match. | All expected assertions passed. | Pass |
| AUTH130 | Authentication | password confirmation rejects surrounding whitespace | Returns validation message: Passwords do not match. | All expected assertions passed. | Pass |
| CHAT001 | Messaging | serializes sender details and an explicit timestamp | Writes sender ID, name, avatar, message text and the explicit Firestore timestamp; excludes the local document ID. | All expected assertions passed. | Pass |
| CHAT002 | Messaging | requests a server timestamp when timestamp is absent | Writes a server-timestamp sentinel when the message timestamp is absent. | All expected assertions passed. | Pass |
| CHAT003 | Messaging | deserializes all message fields from a snapshot | Restores document ID, all sender details, text and the same timestamp instant from the snapshot. | All expected assertions passed. | Pass |
| CHAT004 | Messaging | defaults missing message data and pending timestamps | Null document data produces empty sender ID, avatar and text, Unknown sender name, and a null timestamp. | All expected assertions passed. | Pass |
| CHAT005 | Groups | serializes all group fields and creation time | Writes group details, creator, admins, members and the explicit creation timestamp; excludes the local document ID. | All expected assertions passed. | Pass |
| CHAT006 | Groups | round trips persisted group fields | Restores the snapshot ID and preserves every persisted group field through serialization and deserialization. | All expected assertions passed. | Pass |
| CHAT007 | Groups | treats legacy group creator as admin when admins absent | Uses the legacy creator as the sole admin when admins are absent; missing members are empty and creation time is null. | All expected assertions passed. | Pass |
| CHAT008 | Groups | preserves an explicitly empty admin list | Preserves an explicitly empty admin list even when a creator is present. | All expected assertions passed. | Pass |
| CHAT009 | Groups | defaults missing group data without inventing an admin | Null data produces empty group strings, admins and members; serialization requests a server creation timestamp. | All expected assertions passed. | Pass |
| CHAT010 | Messaging | rejects messages when no user is authenticated | Throws a not-logged-in exception and never accesses Firestore when the current user is null. | All expected assertions passed. | Pass |
| CHAT011 | Messaging | ignores whitespace-only messages without reading a profile | Whitespace-only text returns without accessing Firestore or adding a message. | All expected assertions passed. | Pass |
| CHAT012 | Messaging | sends trimmed text using the stored profile and server timestamp | Writes trimmed text, the authenticated sender ID, stored profile name and avatar, and a server timestamp. | All expected assertions passed. | Pass |
| CHAT013 | Messaging | falls back to account display name when the profile is absent | Uses the account display name and an empty avatar when the profile document is absent. | All expected assertions passed. | Pass |
| CHAT014 | Messaging | falls back to User when profile name is blank and display name null | Writes User as the sender name when the stored name is blank and the account display name is null. | All expected assertions passed. | Pass |
| CHAT015 | Messaging | propagates profile read failures without sending a message | Propagates the identical profile-read Firebase exception and adds no message. | All expected assertions passed. | Pass |
| CHAT016 | Messaging | propagates message write failures | Propagates the identical Firebase exception raised while adding the message. | All expected assertions passed. | Pass |
| CHAT017 | Messaging | maps ordered message snapshots to message models | Requests descending timestamp order and maps both message IDs and texts in snapshot order. | All expected assertions passed. | Pass |
| CHAT018 | Messaging | emits an empty list for groups without messages | Emits an empty message list for an empty messages snapshot. | All expected assertions passed. | Pass |
| CHAT019 | Messaging | forwards message stream errors to the subscriber | Emits the identical Firebase snapshot-stream exception to the subscriber. | All expected assertions passed. | Pass |
| CHAT020 | Groups | creates a trimmed group with the creator as member and admin | Writes trimmed name, description and image URL, the selected category, creator as sole member and admin, and a server timestamp. | All expected assertions passed. | Pass |
| CHAT021 | Groups | prevents group creation when signed out | Throws when signed out and never accesses Firestore to create a group. | All expected assertions passed. | Pass |
| CHAT022 | Groups | joins a group through an atomic member union | Updates members once using an atomic array union containing the authenticated user ID. | All expected assertions passed. | Pass |
| CHAT023 | Groups | checks membership and admin status against their own lists | Returns true for list membership and false for admin access when the creator is absent from the admin list. | All expected assertions passed. | Pass |
| CHAT024 | Groups | recognizes promoted admins and signed-out membership checks | Recognizes a promoted admin; after sign-out the current user ID is null and both membership checks return false. | All expected assertions passed. | Pass |
| CHAT025 | Groups | rejects blank group names before reading storage | Throws Group name cannot be empty for whitespace-only names before accessing Firestore. | All expected assertions passed. | Pass |
| CHAT026 | Groups | rejects blank descriptions before reading storage | Throws Description cannot be empty for whitespace-only descriptions before accessing Firestore. | All expected assertions passed. | Pass |
| CHAT027 | Groups | permits admins to update trimmed group details | An authorized admin writes trimmed name and description plus the selected category exactly once. | All expected assertions passed. | Pass |
| CHAT028 | Groups | denies group updates to a creator removed from admins | Throws an admins-only update exception and performs no update when the creator is no longer an admin. | All expected assertions passed. | Pass |
| CHAT029 | Groups | rejects updates when the group no longer exists | Throws Group not found for a missing document and performs no update. | All expected assertions passed. | Pass |
| CHAT030 | Groups | supports deleting legacy groups owned by the authenticated user | Deletes the group exactly once when its legacy creator is authenticated and admins are absent. | All expected assertions passed. | Pass |
| CHAT031 | Groups | denies deletion by non-admin members | Throws an admins-only deletion exception for a non-admin and never deletes the document. | All expected assertions passed. | Pass |
| CHAT032 | Groups | rejects null group data without deleting anything | Throws Group data not found for null document data and never deletes the document. | All expected assertions passed. | Pass |
| CHAT033 | Groups | removes a departing member and preserves the remaining admin | Removes the departing member, preserves the remaining admin and creator, and does not delete the group. | All expected assertions passed. | Pass |
| CHAT034 | Groups | promotes the sole remaining member when the creator exits | Promotes the sole remaining member to admin and creator when the original creator exits. | All expected assertions passed. | Pass |
| CHAT035 | Groups | deletes the group when its last member exits | Deletes the group transactionally when its final member exits and performs no group update. | All expected assertions passed. | Pass |
| CHAT036 | Groups | prevents nonmembers from exiting a group | Throws a not-a-member exception for an outsider and performs no transaction update or delete. | All expected assertions passed. | Pass |
| CHAT037 | Groups | removes stale admins and chooses a remaining member as admin | Removes the departed and stale admins, retains the remaining members, and chooses exactly one remaining member as admin and creator. | All expected assertions passed. | Pass |
| CHAT038 | Groups | allows admins to promote an existing member | An authorized admin adds the selected existing member to the admin list in one transaction update. | All expected assertions passed. | Pass |
| CHAT039 | Groups | does not write when a selected member is already an admin | Performs no transaction update when the selected member is already an admin. | All expected assertions passed. | Pass |
| CHAT040 | Groups | rejects promotion by non-admins | Throws an admins-only promotion exception and performs no update for a non-admin caller. | All expected assertions passed. | Pass |
| CHAT041 | Groups | rejects promotion of a user outside the group | Throws a not-a-member exception and performs no update when promoting an outsider. | All expected assertions passed. | Pass |
| CHAT042 | Groups | returns no member profiles for an empty group | Returns an empty member-profile list without accessing Firestore when the group has no members. | All expected assertions passed. | Pass |
| CHAT043 | Groups | orders admins first then names and falls back to email or unknown | Lists admins first, sorts remaining names alphabetically, trims profile text, and falls back to the email prefix or Unknown User. | All expected assertions passed. | Pass |
| CHAT044 | Groups | includes joined and created groups when filtering my groups | My-groups filtering includes groups joined by or created by the current user and excludes unrelated groups. | All expected assertions passed. | Pass |
| CHAT045 | Groups | matches trimmed case-insensitive description searches | A trimmed, case-insensitive Flutter description search returns only the coding group. | All expected assertions passed. | Pass |
| CHAT046 | Groups | combines category membership and name filters | Combined membership, case-insensitive category and name filters return only the matching Math club. | All expected assertions passed. | Pass |
| CHAT047 | Groups | returns an empty list when no group matches | Returns an empty list when no group matches the search query. | All expected assertions passed. | Pass |
| CHAT048 | Groups | searches the category as well as group text | A programming-category search returns the coding group even when the group name does not contain that term. | All expected assertions passed. | Pass |
| CHAT049 | Groups | watchGroup emits null for deleted groups | The group watcher emits null when the group document no longer exists. | All expected assertions passed. | Pass |
| CHAT050 | Groups | propagates group write failures | Propagates the identical Firebase write exception from joining a group. | All expected assertions passed. | Pass |
| COURSE001 | Courses | media serializes every stored file field | Writes exactly name, path and URL for course media | All expected assertions passed. | Pass |
| COURSE002 | Courses | missing and null media fields deserialize as empty | Decodes missing and null media fields as empty strings | All expected assertions passed. | Pass |
| COURSE003 | Courses | lesson without video preserves null and empty defaults | Decodes lesson defaults with null video and empty materials | All expected assertions passed. | Pass |
| COURSE004 | Courses | lesson round trip preserves descriptions and file details | Preserves lesson description, duration, video and materials in a round trip | All expected assertions passed. | Pass |
| COURSE005 | Courses | lesson defensively copies and locks its materials | Copies materials and exposes an unmodifiable list | All expected assertions passed. | Pass |
| COURSE006 | Courses | empty course data uses documented safe defaults | Decodes empty course data into safe draft defaults | All expected assertions passed. | Pass |
| COURSE007 | Courses | numeric strings and timestamps preserve paid course metadata | Parses paid price, rating, enrollment count and supplied timestamps | All expected assertions passed. | Pass |
| COURSE008 | Courses | unknown enums and invalid numeric text use fallbacks | Uses free/draft/zero fallbacks for unknown enums and invalid numbers | All expected assertions passed. | Pass |
| COURSE009 | Courses | course writes omit database-managed fields | Writes schema version 2 and omits ID, timestamps and enrollment count | All expected assertions passed. | Pass |
| COURSE010 | Courses | enrollment ignores non-string IDs and removes duplicates | Filters malformed lesson IDs, removes duplicates and locks the result | All expected assertions passed. | Pass |
| COURSE011 | Courses | missing and null lesson completion lists are empty | Decodes missing and null completion lists as empty sets | All expected assertions passed. | Pass |
| COURSE012 | Courses | lesson labels pad single digits without truncating large numbers | Produces Lesson 01, Lesson 09, Lesson 10 and Lesson 100 | All expected assertions passed. | Pass |
| COURSE013 | Courses | price accepts whitespace, fractions and the smallest positive value | Accepts positive fractional, tiny and large finite prices | All expected assertions passed. | Pass |
| COURSE014 | Courses | whitespace and negative infinity prices are rejected | Rejects whitespace, negative infinity, negative zero and overflow prices | All expected assertions passed. | Pass |
| COURSE015 | Courses | empty courses report zero progress | Returns zero progress for zero lessons | All expected assertions passed. | Pass |
| COURSE016 | Courses | partial completion calculates the fraction | Returns 0.25 for one of four completed lessons | All expected assertions passed. | Pass |
| COURSE017 | Courses | all lessons complete reports one | Returns 1.0 when all lessons are completed | All expected assertions passed. | Pass |
| COURSE018 | Courses | excess stored completions clamp to full progress | Clamps excessive completion counts to 1.0 | All expected assertions passed. | Pass |
| COURSE019 | Courses | negative completion counts clamp to zero | Clamps negative completion counts to zero | All expected assertions passed. | Pass |
| COURSE020 | Courses | stale completions on empty courses report zero | Returns zero for stale completions when no lessons remain | All expected assertions passed. | Pass |
| COURSE021 | Courses | generates five questions for JavaScript | Generates five four-option JavaScript questions from uppercase title | All expected assertions passed. | Pass |
| COURSE022 | Courses | generates five questions for UI Design | Generates five four-option UI Design questions from an alias | All expected assertions passed. | Pass |
| COURSE023 | Courses | generates five questions for SEO | Generates five four-option SEO questions from its expanded name | All expected assertions passed. | Pass |
| COURSE024 | Courses | generates five questions for Project Management | Generates five four-option Project Management questions | All expected assertions passed. | Pass |
| COURSE025 | Courses | generates five questions for Public Speaking | Generates five four-option Public Speaking questions | All expected assertions passed. | Pass |
| COURSE026 | Courses | a topic in another category is rejected with supported topics | Rejects cross-category topics with supported-topic guidance | All expected assertions passed. | Pass |
| COURSE027 | Courses | empty titles fail without generating a usable quiz | Rejects empty titles with supported Development topics | All expected assertions passed. | Pass |
| COURSE028 | Courses | unknown categories report an unavailable topic | Rejects unknown categories with the existing unavailable-topic message | All expected assertions passed. | Pass |
| COURSE029 | Courses | development aliases choose C sharp rather than an unrelated quiz | Matches C sharp alias to the C# topic | All expected assertions passed. | Pass |
| COURSE030 | Courses | all correct answers pass | Scores five correct answers as 5 and passes | All expected assertions passed. | Pass |
| COURSE031 | Courses | four correct answers meet the passing boundary | Scores four correct answers as 4 and passes at the boundary | All expected assertions passed. | Pass |
| COURSE032 | Courses | three correct answers fail below the boundary | Scores three correct answers as 3 and fails below the boundary | All expected assertions passed. | Pass |
| COURSE033 | Courses | all incorrect answers score zero | Scores all incorrect answers as zero and fails | All expected assertions passed. | Pass |
| COURSE034 | Courses | out-of-range choices count as incorrect | Counts out-of-range answer choices as incorrect | All expected assertions passed. | Pass |
| COURSE035 | Courses | submitting an unknown quiz returns the regeneration error | Rejects unknown quiz IDs with regeneration guidance | All expected assertions passed. | Pass |
| COURSE036 | Courses | completed quizzes cannot be submitted twice | Rejects a second submission of a completed quiz | All expected assertions passed. | Pass |
| COURSE037 | Courses | too few answers consume the quiz and require regeneration | Rejects too few answers and consumes the quiz key | All expected assertions passed. | Pass |
| COURSE038 | Courses | too many answers consume the quiz and require regeneration | Rejects too many answers and consumes the quiz key | All expected assertions passed. | Pass |
| COURSE039 | Courses | quiz keys are isolated between service instances | Keeps quiz keys isolated between service instances | All expected assertions passed. | Pass |
| COURSE040 | Courses | separate generated quizzes retain independent answer keys | Keeps separately generated quiz answer keys independent | All expected assertions passed. | Pass |
| COURSE041 | Courses | missing auth sessions expose an empty user ID | Returns an empty user ID when signed out without accessing Firestore | All expected assertions passed. | Pass |
| COURSE042 | Courses | new IDs come from the course collection | Returns the generated course document ID without writing data | All expected assertions passed. | Pass |
| COURSE043 | Courses | saving another owners course fails before database access | Rejects foreign-owner saves before database access | All expected assertions passed. | Pass |
| COURSE044 | Courses | publication rejects blank title | Rejects publication with a blank title before database access | All expected assertions passed. | Pass |
| COURSE045 | Courses | publication rejects blank description | Rejects publication with a blank description before database access | All expected assertions passed. | Pass |
| COURSE046 | Courses | publication rejects missing category | Rejects publication without a category before database access | All expected assertions passed. | Pass |
| COURSE047 | Courses | publication rejects missing language | Rejects publication without a language before database access | All expected assertions passed. | Pass |
| COURSE048 | Courses | publication rejects missing thumbnail | Rejects publication without a thumbnail before database access | All expected assertions passed. | Pass |
| COURSE049 | Courses | publication rejects no lessons | Rejects publication without lessons before database access | All expected assertions passed. | Pass |
| COURSE050 | Courses | publication rejects blank lesson title | Rejects publication with a blank lesson title before database access | All expected assertions passed. | Pass |
| COURSE051 | Courses | publication rejects missing lesson video | Rejects publication without a lesson video before database access | All expected assertions passed. | Pass |
| COURSE052 | Courses | publication rejects zero paid price | Rejects publication of a paid course with zero price before database access | All expected assertions passed. | Pass |
| COURSE053 | Courses | incomplete drafts save without writing enrollment or creation fields | Saves incomplete drafts without enrollment count or creation date | All expected assertions passed. | Pass |
| COURSE054 | Courses | a complete paid course publishes its price and lessons | Publishes a complete paid course with its price and lesson content | All expected assertions passed. | Pass |
| COURSE055 | Courses | a new course transaction initializes creation date and enrollment count | Creates a course transaction with enrollment count zero and server timestamps | All expected assertions passed. | Pass |
| COURSE056 | Courses | retrying new-course save updates an existing owner document | Updates existing owner documents on retries without resetting creation or enrollment fields | All expected assertions passed. | Pass |
| COURSE057 | Courses | Firestore save errors retain the backend error code | Maps Firestore save failures to an error containing the backend code | All expected assertions passed. | Pass |
| COURSE058 | Courses | unexpected save failures return the retained-entries retry message | Maps unexpected save failures to the retained-entries retry message | All expected assertions passed. | Pass |
| COURSE059 | Courses | a missing enrollment count starts at one with no completed lessons | Initializes missing enrollment count to one and stores empty completed lessons | All expected assertions passed. | Pass |
| COURSE060 | Courses | enrollment backend failures return a connection retry error | Maps enrollment backend errors to the connection retry message | All expected assertions passed. | Pass |
| COURSE061 | Courses | blank lesson IDs are rejected before database access | Rejects blank lesson IDs before database access | All expected assertions passed. | Pass |
| COURSE062 | Courses | signed-out students cannot mark lessons complete | Rejects signed-out lesson completion before database access | All expected assertions passed. | Pass |
| COURSE063 | Courses | completion requires an existing enrollment with its specific error | Rejects completion without enrollment and does not write progress | All expected assertions passed. | Pass |
| COURSE064 | Courses | completion filters malformed IDs and stores sorted unique IDs | Filters malformed completion IDs and writes sorted unique IDs with a timestamp | All expected assertions passed. | Pass |
| COURSE065 | Courses | completion backend failures return the progress retry message | Maps progress backend failures to the progress retry message | All expected assertions passed. | Pass |
| COURSE066 | Courses | deleting a missing owner course performs no write | Treats deletion of an absent owner course as a no-op | All expected assertions passed. | Pass |
| COURSE067 | Courses | changed ownership in Firestore prevents deletion | Rejects deletion after stored ownership changes without deleting data | All expected assertions passed. | Pass |
| COURSE068 | Courses | the owner deletes the course reference in a transaction | Deletes the owner course reference within a transaction | All expected assertions passed. | Pass |
| COURSE069 | Courses | delete failures return a connection retry error | Maps deletion failures to a connection retry message | All expected assertions passed. | Pass |
| COURSE070 | Courses | signed-out owned and enrollment streams emit empty data without Firestore | Emits empty owned-course and enrollment streams when signed out | All expected assertions passed. | Pass |
| COURSE071 | Courses | owned course streams sort newest first and decode Firestore dates | Sorts owned courses newest first and decodes Firestore timestamps | All expected assertions passed. | Pass |
| COURSE072 | Courses | public course streams select published documents while signed out | Queries published courses for signed-out public readers | All expected assertions passed. | Pass |
| COURSE073 | Courses | enrollment streams restore document IDs and completion records | Restores enrollment document IDs and unique completed lesson IDs | All expected assertions passed. | Pass |
| COURSE074 | Courses | Firestore stream errors are preserved for stream consumers | Preserves the original Firestore stream error | All expected assertions passed. | Pass |
| COURSE075 | Courses | signed-out uploads fail before storage or filesystem access | Rejects signed-out uploads before storage or filesystem access | All expected assertions passed. | Pass |
| COURSE076 | Courses | blank media paths fail before storage is initialized | Rejects blank media paths before storage initializes | All expected assertions passed. | Pass |
| COURSE077 | Courses | new-course retries never overwrite another owners existing document | Prevents retries from overwriting another owners existing course document | All expected assertions passed. | Pass |
| COURSE078 | Courses | deleting another owners course fails before database access | Rejects foreign-owner deletion before database access | All expected assertions passed. | Pass |
| POST001 | Educational posts | creation trims text, uses profile identity and initializes counters | Writes trimmed text, profile identity, zero counters, empty likedBy and a server timestamp. | All expected assertions passed. | Pass |
| POST002 | Educational posts | link attachment persists metadata without uploading a file | Stores link type and URL with no uploaded storage path. | All expected assertions passed. | Pass |
| POST003 | Educational posts | missing profile falls back to the Firebase display name | Uses Firebase displayName when the profile is missing. | All expected assertions passed. | Pass |
| POST004 | Educational posts | missing display name falls back to the email local part | Uses the email local part when profile and displayName are unavailable. | All expected assertions passed. | Pass |
| POST005 | Educational posts | missing all identity details uses the existing generic author | Uses the generic User author when identity details are absent. | All expected assertions passed. | Pass |
| POST006 | Educational posts | profile lookup failures prevent publication | Throws the publication failure and writes no post when profile lookup fails. | All expected assertions passed. | Pass |
| POST007 | Educational posts | failed metadata writes become a publication failure | Converts metadata write errors to the publication failure. | All expected assertions passed. | Pass |
| POST008 | Educational posts | signed-out publication never queries the database | Throws the sign-in requirement before accessing Firestore. | All expected assertions passed. | Pass |
| POST009 | Educational posts | owner edit changes only editable fields and preserves engagement | Updates only editable fields and updatedAt, preserving engagement metadata. | All expected assertions passed. | Pass |
| POST010 | Educational posts | explicit attachment removal clears every attachment field | Sets attachmentType to none and explicitly writes all attachment metadata keys as null. | All expected assertions passed. | Pass |
| POST011 | Educational posts | invalid ownership or status prevents an edit | Rejects another author's edit with the ownership failure and no writes. | All expected assertions passed. | Pass |
| POST012 | Educational posts | invalid ownership or status prevents an edit | Rejects edits of a deleted post with no writes. | All expected assertions passed. | Pass |
| POST013 | Educational posts | missing post cannot be edited | Reports a missing post as unavailable and writes nothing. | All expected assertions passed. | Pass |
| POST014 | Educational posts | ownership is checked again inside the transaction | Rejects an ownership change detected during the transaction. | All expected assertions passed. | Pass |
| POST015 | Educational posts | invalid edit fields are rejected before database access | Rejects an empty edit title before database access. | All expected assertions passed. | Pass |
| POST016 | Educational posts | invalid edit fields are rejected before database access | Rejects a 101-character edit title before database access. | All expected assertions passed. | Pass |
| POST017 | Educational posts | invalid edit fields are rejected before database access | Rejects unsupported edit visibility before database access. | All expected assertions passed. | Pass |
| POST018 | Educational posts | the maximum 100-character edit title is accepted | Accepts and persists a 100-character edit title. | All expected assertions passed. | Pass |
| POST019 | Educational posts | deleting an owned post writes a tombstone and timestamps | Soft-deletes the post with timestamps, without deleting its document. | All expected assertions passed. | Pass |
| POST020 | Educational posts | deleting an already deleted post is idempotent | Performs no update when the owned post is already deleted. | All expected assertions passed. | Pass |
| POST021 | Educational posts | another author cannot delete a post | Rejects another author's deletion with no updates. | All expected assertions passed. | Pass |
| POST022 | Educational posts | a missing post reports that it is unavailable | Throws the unavailable-post failure for a missing document. | All expected assertions passed. | Pass |
| POST023 | Educational posts | liking adds the current user and increments the persisted count | Atomically adds the current user and increments likeCount from 2 to 3. | All expected assertions passed. | Pass |
| POST024 | Educational posts | unliking removes only the current user and decrements the count | Atomically removes the current user and decrements likeCount from 2 to 1. | All expected assertions passed. | Pass |
| POST025 | Educational posts | repeated like state does not change counters | Does not write when an already-liked post is liked again. | All expected assertions passed. | Pass |
| POST026 | Educational posts | repeated like state does not change counters | Does not write when an already-unliked post is unliked again. | All expected assertions passed. | Pass |
| POST027 | Educational posts | unliking a stale zero count never creates a negative count | Clamps the unlike count at zero. | All expected assertions passed. | Pass |
| POST028 | Educational posts | unpublished posts cannot receive likes | Rejects likes on a draft with no writes. | All expected assertions passed. | Pass |
| POST029 | Educational posts | a comment is trimmed and atomically increases the post count | Writes trimmed comment and profile metadata and increments commentCount with lastCommentId. | All expected assertions passed. | Pass |
| POST030 | Educational posts | invalid comment text is rejected without database access | Rejects an empty comment before database access. | All expected assertions passed. | Pass |
| POST031 | Educational posts | invalid comment text is rejected without database access | Rejects a whitespace-only comment before database access. | All expected assertions passed. | Pass |
| POST032 | Educational posts | invalid comment text is rejected without database access | Rejects a 2,001-character comment before database access. | All expected assertions passed. | Pass |
| POST033 | Educational posts | comment length 1 is accepted at the boundary | Accepts and persists a one-character comment. | All expected assertions passed. | Pass |
| POST034 | Educational posts | comment length 2000 is accepted at the boundary | Accepts and persists a 2,000-character comment. | All expected assertions passed. | Pass |
| POST035 | Educational posts | comments on withdrawn posts do not write comment metadata | Rejects a comment on a deleted post without comment or counter writes. | All expected assertions passed. | Pass |
| POST036 | Educational posts | deleting an owned comment clamps a stale count at zero | Deletes the owned comment and clamps commentCount at zero. | All expected assertions passed. | Pass |
| POST037 | Educational posts | deleting a missing comment is idempotent | Does not delete or update counters for a missing comment. | All expected assertions passed. | Pass |
| POST038 | Educational posts | another author cannot delete a comment | Rejects deletion of another author's comment. | All expected assertions passed. | Pass |
| POST039 | Educational posts | editing an owned comment updates text without changing counters | Writes trimmed comment text and updatedAt without changing post counters. | All expected assertions passed. | Pass |
| POST040 | Educational posts | another author cannot edit a comment | Rejects edits of another author's comment with no writes. | All expected assertions passed. | Pass |
| POST041 | Educational posts | a missing comment cannot be edited | Rejects edits of a missing comment as unavailable. | All expected assertions passed. | Pass |
| POST042 | Educational posts | whitespace-only comment edits are rejected | Rejects a whitespace-only comment edit with no updates. | All expected assertions passed. | Pass |
| POST043 | Educational posts | signed-out users cannot delete your post | Requires sign-in for post deletion before database access. | All expected assertions passed. | Pass |
| POST044 | Educational posts | signed-out users cannot like a post | Requires sign-in for likes before database access. | All expected assertions passed. | Pass |
| POST045 | Educational posts | signed-out users cannot comment | Requires sign-in for commenting before database access. | All expected assertions passed. | Pass |
| POST046 | Educational posts | signed-out users cannot delete your comment | Requires sign-in for comment deletion before database access. | All expected assertions passed. | Pass |
| POST047 | Educational posts | signed-out users cannot edit your comment | Requires sign-in for comment edits before database access. | All expected assertions passed. | Pass |
| POST048 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to delete post, with no writes. | All expected assertions passed. | Pass |
| POST049 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to update like, with no writes. | All expected assertions passed. | Pass |
| POST050 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to send comment, with no writes. | All expected assertions passed. | Pass |
| POST051 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to delete comment, with no writes. | All expected assertions passed. | Pass |
| POST052 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to save comment, with no writes. | All expected assertions passed. | Pass |
| POST053 | Educational posts | transaction errors become an actionable domain failure | Maps a transaction failure to Unable to update post, with no writes. | All expected assertions passed. | Pass |
| POST101 | Post models | absent document data uses safe published-post defaults | Uses safe defaults for missing post document data. | All expected assertions passed. | Pass |
| POST102 | Post models | post decoding trims strings and removes malformed list entries | Trims strings and removes nonstring or empty tag and likedBy entries. | All expected assertions passed. | Pass |
| POST103 | Post models | malformed post fields and nonnumeric counters use defaults | Defaults malformed fields and nonnumeric counts and ignores invalid timestamps. | All expected assertions passed. | Pass |
| POST104 | Post models | numeric counts and Firebase timestamps retain their stored meaning | Converts numeric counts to integers and preserves a valid Timestamp. | All expected assertions passed. | Pass |
| POST105 | Post models | missing comment data uses safe optional fields and author defaults | Uses comment defaults with null optional identity and timestamp fields. | All expected assertions passed. | Pass |
| POST106 | Post models | comment decoding preserves valid fields and rejects wrong optional types | Preserves valid comment fields and defaults malformed optional fields. | All expected assertions passed. | Pass |
| POST107 | Post models | attachment upload requirement follows the actual attachment type | Links need no upload; file attachments require upload; enum values match stored types. | All expected assertions passed. | Pass |
| PROFILE001 | User profile | profile name rejects null | Returns validation message: Enter your full name. | All expected assertions passed. | Pass |
| PROFILE002 | User profile | profile name rejects whitespace only | Returns validation message: Enter your full name. | All expected assertions passed. | Pass |
| PROFILE003 | User profile | profile name rejects a single trimmed character | Returns validation message: Enter your full name. | All expected assertions passed. | Pass |
| PROFILE004 | User profile | profile name accepts the two character boundary | Returns null (valid full name). | All expected assertions passed. | Pass |
| PROFILE005 | User profile | profile name accepts a full name | Returns null (valid full name). | All expected assertions passed. | Pass |
| SKILL001 | Skill sharing | copyWith updates meeting details and preserves session identity | copyWith updates status, platform and link, preserves all session identity and profile fields, and leaves the original unchanged. | All expected assertions passed. | Pass |
| SKILL002 | Skill sharing | copyWith keeps existing optional values when arguments are null | Null copyWith arguments retain confirmed status, the existing link and default platform while returning a distinct session object. | All expected assertions passed. | Pass |
| SKILL003 | Skill sharing | toggles saved IDs independently and notifies listeners | Saving two IDs and unsaving one preserves the other ID, leaves unknown IDs unsaved, and notifies listeners three times. | All expected assertions passed. | Pass |
| SKILL004 | Skill sharing | offline offers mark only their request without duplicates | Repeated offline offers mark only their request as offered without adding remote sent offers. | All expected assertions passed. | Pass |
| SKILL005 | Skill sharing | rejects request creation without authentication | Throws a sign-in StateError when creating a skill request without authentication. | All expected assertions passed. | Pass |
| SKILL006 | Skill sharing | rescheduling a tutor replaces the previous session | Rescheduling the same tutor replaces the earlier session, keeps one entry first, and preserves the new date, time, platform and tutor profile. | All expected assertions passed. | Pass |
| SKILL007 | Skill sharing | publishing a local link confirms only the selected session | Publishing a local meeting link confirms the selected session with the chosen platform and link while preserving the other session object. | All expected assertions passed. | Pass |
| SKILL008 | Skill sharing | ignores a missing local session without notifying | Publishing a link for an unknown local session leaves sessions unchanged and sends no listener notification. | All expected assertions passed. | Pass |
| SKILL009 | Skill sharing | exposes immutable session and offer lists | Session, sent-offer and received-offer list mutations throw UnsupportedError and stored sessions remain intact. | All expected assertions passed. | Pass |
| SKILL010 | Skill sharing | formats boundary calendar dates with zero-padded month and day | Formats leap day and New Year as 2024-02-29 and 2026-01-01 with padded month and day. | All expected assertions passed. | Pass |
| SKILL011 | Skill sharing | stores independent saved state in separate instances | Saving a request in one store does not change the saved state of a separate store instance. | All expected assertions passed. | Pass |
| SKILL012 | Skill sharing | rejects sending an offer to an owned request | Recognizes an owned request, rejects the self-offer with StateError, accesses no Firestore, and leaves the request unoffered. | All expected assertions passed. | Pass |
| SKILL013 | Skill sharing | sends an offer with stable ID and trimmed profile details | Writes a pending offer under the stable request/user ID with trimmed profile metadata, sender/recipient/request IDs, availability and server timestamp, then marks it offered. | All expected assertions passed. | Pass |
| SKILL014 | Skill sharing | falls back to account identity when the profile is absent | An absent profile uses the account display name and avatar plus the Skill tutor title in the offer. | All expected assertions passed. | Pass |
| SKILL015 | Skill sharing | propagates offer failures without marking the request offered | Propagates the identical offer-write Firebase exception and does not mark the request as offered. | All expected assertions passed. | Pass |
| SKILL016 | Skill sharing | adds trimmed requests with dates levels tags and owner identity | Writes trimmed request title and description, owner/profile identity, tags, timestamp date, time, advanced level and server creation timestamp. | All expected assertions passed. | Pass |
| SKILL017 | Skill sharing | only the request recipient may accept an offer | A user who is not the offer recipient receives StateError and no offer update occurs. | All expected assertions passed. | Pass |
| SKILL018 | Skill sharing | offer senders cannot accept their own offers | An offer sender cannot accept their own offer; StateError is thrown and no update occurs. | All expected assertions passed. | Pass |
| SKILL019 | Skill sharing | accepting an offer stores scheduling and clears previous meeting links | Acceptance writes accepted status, scheduled date/time, platform and server acceptance timestamp, and deletes the previous meeting link. | All expected assertions passed. | Pass |
| SKILL020 | Skill sharing | rejecting an offer clears scheduling and link fields | Rejection writes rejected status and a server rejection timestamp, and deletes scheduled date/time, platform and link. | All expected assertions passed. | Pass |
| SKILL021 | Skill sharing | prevents another owner from rejecting an offer | Another owner cannot reject the offer; StateError is thrown and no offer update occurs. | All expected assertions passed. | Pass |
| SKILL022 | Skill sharing | skips remote initialization while signed out | Signed-out remote initialization retains the existing requests and never accesses Firestore. | All expected assertions passed. | Pass |
| SKILL023 | Skill sharing | initializes remote subscriptions once per authenticated user | Repeated initialization for the same user creates each of the three subscriptions once and clears local demo requests and sessions. | All expected assertions passed. | Pass |
| SKILL024 | Skill sharing | maps requests and defaults invalid optional document fields | Request mapping trims identity, derives initials, filters non-string tags, preserves the date, and defaults missing or invalid role/title/description/level/avatar/time/posting fields. | All expected assertions passed. | Pass |
| SKILL025 | Skill sharing | creates sessions only from accepted received and sent offers | Only accepted received and sent offers become sessions, with correct counterpart, ownership, date/time/title, and link-dependent confirmed or awaiting-link status. | All expected assertions passed. | Pass |
| SKILL026 | Skill sharing | filters received offers by request and resolves sent offers | Returns only received offers for the requested ID, resolves the matching sent offer, returns empty/null for unknown IDs, and tracks the request as offered. | All expected assertions passed. | Pass |
| SKILL027 | Skill sharing | replaces offered request tracking on sent-offer snapshots | An empty replacement sent-offer snapshot clears the offered flag, sent offers and derived sessions. | All expected assertions passed. | Pass |
| SKILL028 | Skill sharing | defaults unknown offer status and missing descriptive fields | Unknown status defaults to pending; blank identity and missing descriptive fields receive member/tutor/message/availability defaults, with no schedule, link or derived session. | All expected assertions passed. | Pass |
| SKILL029 | Skill sharing | publishes trimmed meeting links for accepted owned offers | An accepted offer owner writes the selected platform, trimmed meeting link and server publication timestamp exactly once. | All expected assertions passed. | Pass |
| SKILL030 | Skill sharing | prevents publishing links before acceptance | Publishing before acceptance throws a StateError mentioning acceptance and performs no offer update. | All expected assertions passed. | Pass |
| SKILL031 | Skill sharing | prevents publishing another owners or nonexistent meeting links | Another owner's offer and a nonexistent offer both reject meeting-link publication with StateError and perform no update. | All expected assertions passed. | Pass |

## Running the tests

From the project root with Flutter on PATH:

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
```

Run the newly organized pure unit tests and measure them separately:

```bash
flutter test test/models test/services test/utils
flutter test test/models test/services test/utils --coverage --coverage-path coverage/unit_lcov.info
```

Use --machine to capture JSON events, or --reporter expanded to show descriptive case names. SDK/cache access outside the workspace is needed in a restricted shell because Flutter acquires a lock in its SDK directory. Tests require package resolution but do not require a running Firebase emulator or live service.

## Remaining limitations

- Tests mock requested database operations; they do not prove Firestore security rules, transaction retries, server timestamps, backend query indexes, network connectivity or concurrency behavior on a deployed backend.
- Actual Supabase binary uploads, signed-URL refresh and cleanup, camera/file picking, video playback and device sharing remain outside these unit tests. Storage clients are constructed internally; tested creation paths use metadata/link attachments and guards. No upload was attempted by the unit suite.
- Password-reset and Google sign-in actions are existing TODOs; no service behavior was invented for them. No standalone push-notification service exists. The skill meeting form mentions notifications, while the store currently writes meeting details only.
- There is no standalone user-model serializer; registration profile-map writes, nullable profile updates and other real model conversions are tested instead. Profile photo storage operations remain a gap.
- Existing validation is characterized, not strengthened: registration uses a six-character length check (including whitespace); registration and profile-name minimum rules differ; post creation relies on form checks for some required fields while edit has service checks.
- Registration cleanup is tested for Firestore, domain and unexpected failures. A FirebaseAuthException thrown after account creation by updateDisplayName follows the existing auth-error branch without deleting the created account; this remains an application limitation.
- Saved-course state is still the existing UI-local state with a persistence TODO. New tests cover implemented enrollment and lesson completion instead.
- Quiz IDs and model DateTime.now behavior remain as implemented; tests use bounded expectations or explicit timestamps rather than depending on exact wall-clock time.

## Execution details and changed files

Flutter 3.44.9 stable; Dart 3.12.2; Windows PowerShell host.

| Command executed | Actual outcome |
| --- | --- |
| flutter pub get | Passed; dependencies resolved and mocktail 1.0.5 locked. |
| flutter analyze | Exit 1: 13 pre-existing info-level notices, 0 errors and 0 warnings; deprecated Flutter APIs, brace style and unnecessary underscores in existing chat/course screens. No new-code diagnostics. |
| flutter test --machine | Passed; 474 cases. |
| flutter test --coverage --machine | Passed; 474 cases, coverage/lcov.info generated. |
| flutter test test/models test/services test/utils --coverage --coverage-path coverage/unit_lcov.info --machine | Passed; 297 unit cases. |
| flutter test test/course_test.dart --plain-name 'new-course lessons stay locked until verification' --no-pub --machine | Passed; 1 retained widget case after verifying the intentionally disabled lesson controls; no hit-test warning. |
| flutter build apk --debug --no-pub | Passed, exit 0; 458.3 seconds; build/app/outputs/flutter-apk/app-debug.apk (212,488,965 bytes). |
| dart format (changed Dart files) | Completed. |
| git diff --check | Passed. |

Targeted authentication, post, course, chat/skill and repaired-widget runs were also executed during implementation. The first full diagnostic run had 463 passing and 11 failing cases: eight newly written mocks had incorrect inferred generic types, and three retained widget tests had stale selectors/expectations. These were corrected and the final runs above provide the reported results. Assertions were kept specific to existing behavior.

The initial APK attempt failed before application compilation with Java local IPC/loopback connection errors. A command-scoped JVM workaround resolved this host issue and the APK build then succeeded. No project configuration or system settings were changed. The successful PowerShell invocation was:

```powershell
$env:JAVA_TOOL_OPTIONS = '-Djava.net.preferIPv4Stack=true "-Djdk.net.unixdomain.tmpdir=C:\Users\Sisira Chandrasiri\Documents\edupro-mobile-app\tmp" "-Djava.io.tmpdir=C:\Users\Sisira Chandrasiri\Documents\edupro-mobile-app\tmp"'
flutter build apk --debug --no-pub
```

Raw local JSON test events, analyzer output, SDK information, build evidence and report-generation inputs are retained under build/unit_testing/ (generated, Git-ignored output). LCOV files are under coverage/ (also Git-ignored). This report records their measured results. The 13 existing analyzer notices remain unresolved; they were not suppressed or changed as part of this testability-only task.

Created:

- lib/features/auth/validation/auth_validators.dart
- lib/features/profile/validation/profile_validators.dart
- test/helpers/chat_firebase_mocks.dart
- test/helpers/post_firebase_mocks.dart
- test/models/chat_models_test.dart
- test/models/course_models_unit_test.dart
- test/models/post_models_test.dart
- test/models/skill_models_test.dart
- test/services/auth_service_test.dart
- test/services/chat_service_test.dart
- test/services/course_service_unit_test.dart
- test/services/course_verification_unit_test.dart
- test/services/group_service_test.dart
- test/services/post_service_test.dart
- test/services/skill_sharing_store_test.dart
- test/utils/auth_validators_test.dart
- docs/UNIT_TESTING_REPORT.md

Modified:

- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/register_screen.dart
- lib/features/chat/services/chat_service.dart
- lib/features/chat/services/group_service.dart
- lib/features/courses/models/course_draft.dart
- lib/features/courses/presentation/screens/recorded_courses_screen.dart
- lib/features/profile/presentation/screens/edit_profile_screen.dart
- pubspec.yaml
- pubspec.lock
- test/course_enrollment_test.dart
- test/course_test.dart
- test/skill_sharing_test.dart
