# Post comments

Tap the comment icon to read and add comments. Comments stream from `posts/{postId}/comments`, ordered by `createdAt`. Each document stores `userId`, `userName`, `profileImageUrl`, `text`, and a server timestamp. The name and photo are snapshots at submission time.

Submitting requires authentication and 1–2,000 characters after trimming. A transaction verifies that the post is still published, creates the comment, increments `commentCount`, and records `lastCommentId`. Repeated taps are blocked during submission. Failed submissions preserve the draft for retry. Authors can edit their own comments using Edit, Save, and Cancel. Editing checks the stored author ID in a transaction and changes only `text` and `updatedAt`; the count and original timestamp stay unchanged. Replies are not part of this feature.

Authors can also delete their own comments after confirmation. A transaction checks ownership, deletes the document, reduces `commentCount` once (never below zero), and records `lastDeletedCommentId`. Retrying an already deleted comment does not decrement again. Deleting the comment currently being edited exits editing and restores any new-comment draft.

## Firebase setup

The repository does not track deployed Firestore rules. Merge the following into the existing rules, preserving other access controls and ensuring broader write grants do not bypass this validation. No rules have been deployed by this change.

```text
match /posts/{postId} {
  function addsComment() {
    let id = request.resource.data.lastCommentId;
    let path = /databases/$(database)/documents/posts/$(postId)/comments/$(id);
    return request.auth != null
      && resource.data.status == 'published'
      && id is string
      && !exists(path)
      && getAfter(path).data.userId == request.auth.uid
      && request.resource.data.commentCount == resource.data.get('commentCount', 0) + 1
      && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['commentCount', 'lastCommentId']);
  }
  function deletesComment() {
    let id = request.resource.data.lastDeletedCommentId;
    let path = /databases/$(database)/documents/posts/$(postId)/comments/$(id);
    let count = resource.data.get('commentCount', 0);
    return request.auth != null
      && resource.data.status == 'published'
      && id is string
      && get(path).data.userId == request.auth.uid
      && !existsAfter(path)
      && request.resource.data.commentCount == (count > 0 ? count - 1 : 0)
      && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['commentCount', 'lastDeletedCommentId']);
  }
  allow update: if addsComment() || deletesComment();

  match /comments/{commentId} {
    function postPath() {
      return /databases/$(database)/documents/posts/$(postId);
    }
    allow read: if request.auth != null
      && get(postPath()).data.status == 'published';
    allow delete: if request.auth != null
      && resource.data.userId == request.auth.uid
      && get(postPath()).data.status == 'published'
      && getAfter(postPath()).data.lastDeletedCommentId == commentId
      && getAfter(postPath()).data.commentCount ==
        (get(postPath()).data.get('commentCount', 0) > 0
          ? get(postPath()).data.commentCount - 1 : 0);
    allow update: if request.auth != null
      && resource.data.userId == request.auth.uid
      && get(postPath()).data.status == 'published'
      && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['text', 'updatedAt'])
      && request.resource.data.text is string
      && request.resource.data.text.size() > 0
      && request.resource.data.text.size() <= 2000
      && request.resource.data.updatedAt == request.time;
    allow create: if request.auth != null
      && get(postPath()).data.status == 'published'
      && request.resource.data.keys().hasOnly([
        'userId', 'userName', 'profileImageUrl', 'text', 'createdAt'
      ])
      && request.resource.data.userId == request.auth.uid
      && request.resource.data.userName is string
      && (request.resource.data.profileImageUrl == null
          || request.resource.data.profileImageUrl is string)
      && request.resource.data.text is string
      && request.resource.data.text.size() > 0
      && request.resource.data.text.size() <= 2000
      && request.resource.data.createdAt == request.time
      && getAfter(postPath()).data.lastCommentId == commentId
      && getAfter(postPath()).data.commentCount == get(postPath()).data.get('commentCount', 0) + 1;
  }
}
```

Post creation rules should require `commentCount == 0`; ordinary editing rules should prohibit changes to `commentCount`, `lastCommentId`, and `lastDeletedCommentId`. Apply any existing post visibility restrictions to comment reads and creates as well. Validate the combined rules against the actual Firebase project. The query uses the default single-field `createdAt` index.

Manual integration check: submit a comment, confirm that it persists after reopening and increments the feed count once, and verify that a second signed-in user sees it. Confirm rejected/offline submissions retain the draft. Check simultaneous submissions from two users each add one comment and increment the count once.
