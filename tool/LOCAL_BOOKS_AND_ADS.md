# Device books and ads

My library → On this device imports up to five PDFs per signed-in account on
this installation. Metadata lives in SQLite; PDFs are copied into app documents.
The native file picker grants access to selected files only. Files never go to
Supabase. Deleting an import leaves the original untouched; uninstalling removes
the app copies. Maximum import size: 100 MB. A PDF signature is checked; corrupt
or password-protected documents may still be rejected by the reader.

Ads are an anchored banner on the device bookshelf, separated from its list.
There are no reader ads or mandatory ads before opening a book. Consent uses
Google UMP, with a privacy-options entry when required. Ad/consent failures must
not block the bookshelf. Debug uses Google test units. Release ads default OFF.

Before live release:

1. Register Android/iOS apps in AdMob and create banner units.
2. Replace Google test app IDs in AndroidManifest.xml and ios/Runner/Info.plist.
3. Configure AdMob Privacy & messaging, publish a privacy policy, and complete
   applicable store data-safety/privacy declarations. Follow Google's current
   iOS setup requirements (including SKAdNetwork IDs if applicable).
4. Test consent acceptance/decline, privacy choices, no network, ad failure,
   rotation, device text sizes, and actual PDF imports on Android/iOS.
5. Build with --dart-define=ENABLE_ADS=true and
   --dart-define=ADMOB_ANDROID_BANNER_ID=YOUR_BANNER_UNIT (or
   --dart-define=ADMOB_IOS_BANNER_ID=YOUR_BANNER_UNIT).
   Without a configured unit, Google test units are used; they earn no revenue.

Do not click live ads during testing. Dependencies increase app size; compare
split-per-ABI release sizes before publishing.

References:
- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/flutter/test-ads
