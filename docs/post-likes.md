# Post likes

Published posts store `likedBy` (Firebase user IDs) alongside `likeCount`. A Firestore transaction sets the authenticated user's requested like state: adding a missing user increments the count; removing an existing user decrements it. Requests for the already stored state do nothing, including transaction retries. Each user has at most one active like. The button toggles immediately, blocks taps while saving, and restores its previous state on failure. Old posts without `likedBy` start with an empty list; existing counts are preserved, but historical liker identities cannot be recovered.

## Firestore access rules

Deployed Firestore rules are not tracked in this repository. The app requires read access to published posts and permission to update the two like fields. To enforce uniqueness against modified clients too, merge the following predicate into the existing post update rules. Do not replace unrelated rules, and ensure broader update grants cannot bypass this validation for like fields.

```text
function isFirstPostLike() {
  let previous = resource.data.get('likedBy', []);
  let next = request.resource.data.likedBy;
  return request.auth != null
    && resource.data.status == 'published'
    && previous is list
    && next is list
    && !(request.auth.uid in previous)
    && next.size() == previous.size() + 1
    && next.hasAll(previous)
    && next.hasAll([request.auth.uid])
    && request.resource.data.likeCount == resource.data.get('likeCount', 0) + 1
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['likedBy', 'likeCount']);
}
function isPostUnlike() {
  let previous = resource.data.get('likedBy', []);
  let next = request.resource.data.likedBy;
  return request.auth != null
    && resource.data.status == 'published'
    && previous is list
    && next is list
    && request.auth.uid in previous
    && !(request.auth.uid in next)
    && next.size() == previous.size() - 1
    && previous.hasAll(next)
    && request.resource.data.likeCount >= 0
    && request.resource.data.likeCount == resource.data.likeCount - 1
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['likedBy', 'likeCount']);
}
// Inside match /posts/{postId}:
// allow update: if isFirstPostLike() || isPostUnlike();
```

Post creation rules should require `likeCount == 0` and an empty `likedBy` list. Ordinary post editing rules should prohibit changes to these fields. Verify the combined rules in the actual Firebase project before deployment. No rules were deployed by this change.

Manual integration check: sign in as user A, like a published post, reopen the feed, and confirm the filled heart. Tap again to unlike (count decreases by one), then tap to like again. Like from user B and confirm one additional like. Submit the same user's request to like from two devices concurrently and confirm only one increment. Check permission failures restore the previous heart/count and show a retryable error. Deploy both like and unlike rule predicates when updating an installation that previously allowed only likes.
