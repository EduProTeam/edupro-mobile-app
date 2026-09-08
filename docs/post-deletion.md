# Deleting own posts

Owners can choose **Post options → Delete post**, then confirm or cancel. The app checks the authenticated user against the stored author inside a Firestore transaction. It sets `status: deleted`, `deletedAt`, and `updatedAt`. Repeated deletion requests are idempotent. Failed requests leave the dialog open with an error and a retry action.

This is a soft delete: the existing published-post query immediately removes the card, while its Firestore document, comment subcollection, and storage objects remain. There is no restore UI. Keeping the parent avoids orphaning comment documents. Existing post/comment mutations reject deleted posts, including edits opened before deletion. Permanent data/storage cleanup requires a separate trusted backend operation.

## Firestore rules

Deployed rules are not tracked in this repository and were not deployed by this change. Merge this condition into the existing `/posts/{postId}` match, preserving the separate like/comment/edit permissions. Any broader grant must not bypass ownership or permit restoring deleted posts.

```text
allow update: if request.auth != null
  && resource.data.userId == request.auth.uid
  && resource.data.status != 'deleted'
  && request.resource.data.status == 'deleted'
  && request.resource.data.deletedAt == request.time
  && request.resource.data.updatedAt == request.time
  && request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['status', 'deletedAt', 'updatedAt']);
```

Post-edit rules must also require `resource.data.status != 'deleted'`. Non-owner reads of posts and comments must require the parent post's published status so deleted content is not accessible through direct document queries. The feed already queries only published posts. Existing signed attachment URLs remain usable until expiry; soft deletion does not revoke them.

Verify against the real project: another user cannot delete a post, the owner can, deleted posts disappear for both users, stale edit/like/comment requests are rejected, and Cancel or a failed write leaves the post visible.
