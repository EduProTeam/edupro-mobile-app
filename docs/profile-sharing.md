# Profile and post sharing

Share Profile offers Message, WhatsApp, and Copy Link. Message opens the device's SMS composer, and WhatsApp opens its sharing composer. The user chooses a recipient and sends the message; opening a composer does not send anything automatically. Copy Link places the same profile link on the clipboard.

Post Share offers the same three options. The shared text identifies the selected
post and includes `edupro://app/post/<encoded-post-id>`. Copy Link copies that post
link, so a recipient can open the selected post rather than only receiving its
text. The post ID is encoded as one segment and decoded once when the app opens.

Profile links use `edupro://app/profile/<encoded-user-id>`. The receiving device needs EduPro installed, and the viewer must sign in before the profile loads. This change registers a custom app scheme; it does not provide a website, an installation fallback, or an HTTPS profile domain. Whether a custom scheme is clickable inside a message depends on the receiving app.

Links open the existing visitor profile screen. Owner editing controls remain hidden, and the visitor post list uses the existing public, published-post filter. Sharing a link does not grant additional Firestore permissions or expose posts restricted by the existing profile reader.

Post links load the selected published post by ID after authentication. The
shared-post screen checks that it is public and shows an unavailable message if
it is missing, unpublished, deleted, or restricted to followers. Live changes to
the post's status or visibility remove it from this screen. Signed-in viewers
retain normal post interactions; owner editing remains restricted to the author.
These are application visibility checks and do not add new server privacy rules.

Both link types retain their selected ID through sign-in or account creation.
Signing out hides shared content until the viewer signs in again. Initial links
open directly without a timed splash route underneath; a link received during
the splash transition remains open when that timer completes.

`ProfileLink.forUser(String userId)` builds the encoded URI. `ProfileLink.userIdFromRoute(String? route)` accepts the app URI, `/profile/<encoded-user-id>`, and `/#/profile/<encoded-user-id>`. It rejects unrelated schemes or hosts, query parameters, unexpected fragments, extra path segments, blank IDs, slashes, traversal IDs, malformed encoding, and control characters. IDs are decoded once before being passed to the profile lookup.

`PostLink.forPost(String postId)` and
`PostLink.postIdFromRoute(String? route)` provide the same validation for
`edupro://app/post/<encoded-post-id>`, `/post/<encoded-post-id>`, and
`/#/post/<encoded-post-id>`. Profile routes cannot resolve to posts, and post
routes cannot resolve to profiles.

## Native configuration

Android registers the `edupro` scheme, `app` host, and `/profile/` and `/post/`
path prefixes on MainActivity. iOS registers `edupro` through
`CFBundleURLTypes`, which already accepts both paths. Both explicitly enable
Flutter's default deep-link handling. This uses the platform integration
described in the [Flutter deep-link documentation](https://docs.flutter.dev/ui/navigation/deep-linking)
and [Apple custom URL scheme documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app).

Rebuild and reinstall the mobile app after changing AndroidManifest.xml or Info.plist; hot reload does not update native URL registrations. The application validates incoming paths even when the operating system has already matched the registered scheme.

The sharing service launches external composers directly and handles launch failure. No extra package-visibility queries or iOS queried-scheme entries are needed for that flow.

## Verification

Run the link parser tests with the rest of the profile tests:

```powershell
flutter test test/profile_link_test.dart test/post_link_test.dart test/shared_profile_test.dart test/shared_post_test.dart test/profile_routes_test.dart
```

After rebuilding and installing Android, replace `USER_ID` with an existing user's encoded Firebase UID and run:

```powershell
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "edupro://app/profile/USER_ID" com.example.edupro_mobile_app
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "edupro://app/post/POST_ID" com.example.edupro_mobile_app
```

Check both a terminated app and an already running app. Confirm that a signed-out viewer reaches sign-in and continues to the intended profile after signing in; a signed-in viewer should open that profile directly. A missing profile should show the existing unavailable-profile message. Also try a malformed link and confirm that it cannot open an editor or a different document path.

Use the ID of an existing public published post for `POST_ID` and repeat both
launch cases. Confirm continuation to that post through login and registration.
Also verify missing, draft, deleted, and followers-only posts, and change a
visible post's publication status or visibility while its shared screen is open.

On an iOS simulator after rebuilding, use:

```sh
xcrun simctl openurl booted "edupro://app/profile/USER_ID"
xcrun simctl openurl booted "edupro://app/post/POST_ID"
```

Finally, open each sharing option on a device, cancel the SMS and WhatsApp composers to confirm that nothing is sent, and paste Copy Link into a note to verify its value. Exercise missing or unavailable external apps and check that a useful failure message appears.

SMS body prefilling depends on the installed messaging app and platform. The
iOS URI uses the common composer-body convention, which still needs device
verification; Apple's SMS URL scheme does not guarantee prefilled message text.
