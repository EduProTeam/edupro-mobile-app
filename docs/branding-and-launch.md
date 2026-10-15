# EduPro branding and launch

The approved source is `assets/images/edupro-icon.svg`. App widgets use
`lib/shared/branding/edupro_brand.dart` for the mark, navy/blue wordmark, and
generated animation layer paths.

## Launch timing

All timings live in `lib/features/splash/presentation/splash_timing.dart` and
start after the first Flutter splash frame has been rasterized by the engine:

| Element | Start | Fully revealed |
| --- | ---: | ---: |
| E | 0 ms | 650 ms |
| P | 100 ms | 750 ms |
| Cap | 250 ms | 900 ms |
| Tassel and complete logo | 400 ms | 1,000 ms |
| EduPro wordmark | 600 ms | 1,100 ms |
| Tagline | 850 ms | 1,300 ms |
| Accent and footer | 1,100 ms | 1,500 ms |
| Earliest exit | 2,800 ms | 3,150 ms |

Firebase initialization starts concurrently with the entrance and hold. Exit
requires both the minimum display duration and restored authentication state.
The destination is the existing home screen for a restored signed-in session,
or onboarding for a signed-out session. The replacement route fades over
350 ms and cannot return to the splash through Back. Initialization after
2,800 ms triggers exit immediately when ready, without an additional hold.

Reduced motion shows the composition immediately and keeps the same minimum
display duration. Resume does not restart the controller or timer. Logout goes
directly to onboarding. A 15-second initialization deadline offers Retry;
late results from expired attempts are ignored. Retry retains the completed
composition and elapsed hold. Controllers, timers and auth subscriptions are
disposed with the splash.

## Brand asset generation

The repository uses Flutter's native resource files and asset catalogues; there
was no existing icon-generation package. The checked-in generator uses the
existing `flutter_svg` renderer through `flutter_test`, requiring no new
dependency or image tool. Run it after changing the approved SVG:

```sh
flutter pub get
flutter test tool/generate_brand_assets.dart
```

It exports the four SVG groups with their original viewBox and gradients, and
renders each required raster size directly from the SVG. Generated files are
checked in; regular app builds do not need to rerun the generator.

Updated surfaces:

- Splash, shared login/registration branding, and the Settings About icon.
- Android legacy launcher images at five densities; adaptive foreground and
  white background; Android 13 monochrome layer; manifest icon and roundIcon;
  Android 12+ native splash icon. There is no explicit task-description icon
  override, so the manifest supplies recent-apps branding.
- Android white notification silhouettes at five densities. The app currently
  has no notification delivery implementation to configure; when adding one,
  use `ic_stat_edupro` as its small icon.
- iPhone/iPad/marketing AppIcon catalogue, display name and white static native
  launch screen. There are no alternate icons or appearance variants configured.
- macOS AppIcon catalogue, display/menu/window names.
- Windows multi-resolution executable ICO and display/window names.
- Linux window icon and packaged desktop/hicolor icon resources. The generated
  desktop entry expects `edupro_mobile_app` on PATH and its icon installed in the
  desktop environment's icon theme. The bundle includes these under `share/` for
  packaging; the runner independently loads `data/edupro-icon.png`.
- Web favicon, standard and maskable PWA icons, Apple touch icon, title and
  manifest metadata.

The obsolete logo and unused iOS LaunchImage catalogue were removed. Content
illustrations, user images and Google's logo retain their existing assets.
Identifiers, signing settings and Firebase options retain their existing values.

Launcher artwork has a white background with padding. Adaptive foregrounds
fit within Android's central safe area, and monochrome assets use white alpha
silhouettes. Apple app icons are opaque RGB PNGs with no alpha channel. The
operating system applies the final launcher mask.

## Rebuild and run

Launcher icons and native launch resources require a native rebuild. Hot reload
and hot restart do not update the installed app's icon.

From the repository root, for the available Android emulator:

```sh
flutter pub get
flutter run -d emulator-5554
```

For a USB Android phone, enable USB debugging, obtain its ID from `flutter
devices`, and use that ID with `flutter run -d DEVICE_ID`. To make a standalone
APK and install over the existing app while preserving its data:

```sh
flutter build apk --debug
adb -s DEVICE_ID install -r build/app/outputs/flutter-apk/app-debug.apk
```

On macOS with the appropriate signing and platform toolchains:

```sh
flutter run -d IOS_DEVICE_ID
flutter build macos
```

Other build commands are `flutter build windows`, `flutter build linux` and
`flutter build web`; they require their respective supported host toolchains.
The repository's existing Linux Firebase configuration is incomplete, and the
current standard web build has independent post-like integer compilation errors.

If a recent-apps thumbnail still shows the old screen, dismiss the old task and
reopen the rebuilt app. A thumbnail is a cached screen snapshot; it is separate
from the launcher/task icon. Replacing the app with an update preserves stored
sessions; clearing app data or uninstalling is unnecessary as an initial step.

Native platform references:
[Flutter launch icons](https://docs.flutter.dev/ui/assets/assets-and-images),
[Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
[Android native splash](https://developer.android.com/develop/ui/views/launch/splash-screen).

## Verification on 2026-10-14

- Ten splash widget tests passed: delayed first visible frame, fast/slow startup,
  signed-in destination selection, signed-out onboarding, exact minimum hold,
  350 ms route transition, one-time replacement and Back behavior, timeout and
  retry races, failure/retry, reduced motion, resume, disposal and 320×568 layout
  with 2× text scaling.
- Changed splash, branding, Settings, auth header, test and generator files
  passed Flutter analysis. Full-project analysis reported 12 informational
  findings in unchanged chat/course files.
- The full test suite ran with 48 passing tests and three failures. The same
  failures reproduced from an isolated copy of the committed baseline:
  `course_enrollment_test.dart` — marking a lesson complete;
  `course_test.dart` — saving before verification;
  `skill_sharing_test.dart` — accepting an offer.
- `flutter build apk --debug --no-pub --target-platform android-x64` passed.
  The APK was installed with `adb install -r` on the Pixel_8 Android 15 emulator.
  Screenshots verified the native splash icon, Flutter composition and hold,
  signed-out onboarding, warm resume, registration header, launcher and
  recent-apps icon. Launch logs had no unhandled errors or missing assets.
  Live signed-in sessions were not exercised; the route choice was verified
  without creating or changing an account.
- APK inspection confirmed the unchanged application ID, EduPro label,
  adaptive resource references, approved source SVG and all four layers, with
  no obsolete logo in the Flutter asset bundle.
- All generated PNGs decoded; all Apple catalogue sizes existed and matched
  their declarations; iOS icons had RGB mode with no alpha; the ICO contained
  16, 24, 32, 48, 64, 128 and 256 pixel images; monochrome foregrounds contained
  white pixels with alpha. Launcher padding was inspected both in the generated
  preview and the emulator's circular mask.
- Standard web build failed in unchanged post-like code because three
  `0x7FFFFFFFFFFFFFFF` literals cannot be represented exactly by JavaScript.
  Windows validation was stopped during a stalled Firebase C++ SDK download.
  iOS/macOS/Linux builds and actual themed-icon display were not available on
  this Windows host. The Linux runner already lacks Firebase options.

Screenshots and the emulator APK are under `build/branding/` and
`build/app/outputs/flutter-apk/` respectively. The APK built here targets x64
emulators. Use `flutter run -d DEVICE_ID` or a standard Android build for an
ARM phone. To launch this emulator yourself before running the app:

```sh
flutter emulators --launch Pixel_8
flutter run -d emulator-5554
```
