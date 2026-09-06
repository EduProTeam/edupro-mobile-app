# Course persistence setup

The application stores course metadata in Cloud Firestore `courses/{courseId}` and all course files in the existing private Supabase `edupro-media` bucket. It uses the same Firebase JWT access-token integration as PostService and ProfilePhotoService. No new packages or second storage provider were added.

Documents include owner `userId`, title, description, category, language, type (`free`/`paid`), currency, numeric price, status (`draft`/`published`), thumbnail, a direct lessons array, schemaVersion and server timestamps. Each media reference includes the original filename, Supabase object path and a signed URL. Device paths are never written to Firestore. Drafts can be incomplete; all selected files must finish uploading before the document is saved. Failed saves retain uploaded references in the open editor so retries do not upload them again. Course IDs remain stable across retries and draft edits.

## Firestore access

No deployed Firestore rules are tracked in this repository. Merge this collection match into the existing `/databases/{database}/documents` rules; do not replace unrelated users/posts rules. Deployment must be verified against the actual project before considering production setup complete.

```text
match /courses/{courseId} {
  function signedIn() { return request.auth != null; }
  function owner() {
    return signedIn() && resource.data.userId == request.auth.uid;
  }
  function validCourse() {
    let d = request.resource.data;
    return d.userId == request.auth.uid
      && d.title is string && d.description is string
      && d.category is string && d.language is string
      && d.currency is string && d.price is number
      && d.type in ['free', 'paid']
      && d.status in ['draft', 'published']
      && d.lessons is list && d.lessons.size() > 0
      && (d.type != 'free' || d.price == 0)
      && (d.status != 'published' || (
        d.title.size() > 0 && d.description.size() > 0
        && d.category.size() > 0 && d.language.size() > 0
        && d.thumbnail is map
        && (d.type != 'paid' || d.price > 0)
      ));
  }
  allow read: if owner() || resource.data.status == 'published';
  allow create: if signedIn() && validCourse();
  allow update: if owner() && validCourse()
    && request.resource.data.userId == resource.data.userId;
  allow delete: if owner();
}
```

Firestore rules cannot iterate arbitrary lesson arrays to validate every lesson. The app validates lesson titles and videos on publish; if publish integrity must be protected against modified clients, enforce full nested validation in a trusted backend. Avoid any broad catch-all rule that grants access to private drafts.

The list uses separate `userId == currentUser` and `status == published` queries; the default single-field indexes suffice. It sorts by update time on the client.

## Supabase access

Keep Firebase third-party authentication enabled. Course object paths use the existing owner-first pattern:

`<firebase-user-id>/course_<course-id>_<timestamp>_<safe-filename>`

The existing bucket policies need to allow authenticated INSERT, SELECT (signed URL creation), and DELETE for objects whose first path segment equals the Firebase JWT `sub`. Do not make the bucket public or broaden access to other owners. Ensure bucket MIME and size restrictions permit cover images, lesson videos, PDF, DOCX and PPTX at your intended file sizes. No live bucket settings or policies were changed by this implementation.

Signed URLs follow the existing application's one-year expiry. Object paths are retained for future URL renewal. These URLs are bearer links, so a recipient can use a shared URL until expiry; this implementation does not add paid-content entitlement enforcement or automatic URL renewal.

## Verification on a configured device

1. Sign in and save an incomplete draft. Restart the app and reopen it using Edit Draft.
2. Add/edit/remove lessons and verify numbering and per-lesson files survive an editor round trip.
3. Select a cover, video and each document format. Save and verify objects are in Supabase and Firestore contains only remote references.
4. Interrupt an upload; verify inline failure and Retry. Interrupt the Firestore write; retry without re-uploading completed media.
5. Publish after completing all required fields. Confirm the published course appears in All Courses and drafts remain owner-only.
6. Confirm another account cannot update the course or read its draft document.

Known limits: video playback/document opening are not implemented (the previous viewer did not provide them). Existing lesson durations are preserved, but newly selected videos do not have duration extraction. Uploads show indeterminate progress because the existing standard storage-upload API has no byte-progress callback. Uploaded files removed from an editor or abandoned before saving can remain orphaned; schedule owner-aware cleanup before production use. Local selections are retained during an open editor session, not across an app kill before successful saving.
