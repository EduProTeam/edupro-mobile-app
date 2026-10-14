# Saved educational posts

Tap a post's bookmark to save it, or tap its filled bookmark to remove it.
The button confirms where to find saved posts and rolls back on a failed write.
Repeated taps while a write is pending do not create extra writes.

Profile has **Posts** and **Saved** tabs beneath the profile details:

- Posts queries only the signed-in user's published posts, newest first.
- Saved lists that user's bookmarks, most recently saved first. Bookmarks are
  private, including their existence and save timestamps.
- Tap a preview to read the full post and use the existing like, comment,
  edit/delete (for the author), and bookmark actions.
- Tap the filled bookmark on a Saved preview to remove it directly.
- Deleted or withdrawn posts disappear from both grids. Removing a bookmark
  also works when its original post is gone.
- Grids initially display up to 12 previews, with a Show more control.

## Firestore

Bookmarks live at `users/{userId}/savedPosts/{postId}` and contain only
`postId` and `savedAt` (a server timestamp). Saving is an idempotent transaction:
it checks the original published post and preserves an existing save timestamp.
The post is referenced rather than copied, so edits remain current.

The included `firestore.rules` adds owner-only bookmark reads/creation/deletion.
Clients cannot update bookmark records or create bookmarks for unpublished
posts. Parent user-document permissions do not grant subcollection access.
**The updated rules must be deployed to the app's Firebase project before the
new bookmark path can be used against that backend.** From an authenticated
Firebase CLI, use:

```powershell
firebase deploy --only firestore:rules --project edupro-b2b9d
```

Saved posts are resolved through published-post queries in batches of up to 10
IDs. There is no public `savedBy` field and the saved collection does not load
the entire community feed. Query listeners are cancelled when switching tabs
or accounts. Both tabs include loading, empty, error and retry states.

## Verification

```powershell
flutter test test/post_save_button_test.dart test/saved_posts_test.dart test/profile_dashboard_test.dart
```

Service tests cover persistence, per-account paths, idempotent saves, failed
writes, signed-out users, own-post filtering, batched live updates, unavailable
posts and listener cancellation. Widget tests cover immediate bookmark feedback,
duplicate taps, rollback/retry, and saving/viewing/opening/removing a post through
the profile tabs. These use an in-memory Firestore double; production rule
deployment and a two-account device smoke test remain separate backend checks.
