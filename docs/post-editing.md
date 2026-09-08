# Editing own posts

The post options menu is shown only when the signed-in user matches the post's `userId`. Edit opens the existing form with the title, category, content, tags, visibility, and attachment prefilled. Cancel discards changes. Save updates the existing post; it does not reset likes, comments, author information, publication status, or `createdAt`.

An unchanged attachment is retained. Remove the current attachment to remove or replace it using the normal attachment buttons. Previous storage objects are not deleted, so replacing or removing media does not break existing signed links; unused object cleanup is separate. Failed metadata saves after uploads can leave unused objects, consistent with the existing creation flow.

The service checks ownership before uploading and rechecks it inside the update transaction. Missing posts and ownership mismatches reject the save. A successful update appears through the existing feed stream.

## Firestore rules

Deployed rules are not tracked here. Merge this owner-only update condition into the existing `match /posts/{postId}` alongside the separate like/comment rules, without broadening those grants. Ensure any other update grants cannot bypass these restrictions. No rules were deployed by this change.

```text
allow update: if request.auth != null
  && resource.data.userId == request.auth.uid
  && resource.data.status != 'deleted'
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
    'title', 'category', 'content', 'tags', 'visibility', 'updatedAt',
    'attachmentType', 'attachmentUrl', 'attachmentPath', 'attachmentName', 'linkUrl'
  ])
  && request.resource.data.title is string
  && request.resource.data.title.size() > 0
  && request.resource.data.title.size() <= 100
  && request.resource.data.content is string
  && request.resource.data.content.size() > 0
  && request.resource.data.category is string
  && request.resource.data.category.size() > 0
  && request.resource.data.tags is list
  && request.resource.data.visibility in ['public', 'followers']
  && request.resource.data.updatedAt == request.time;
```

Verify the combined rules in Firebase: the author can update allowed fields, another account cannot, and neither can alter author IDs, creation timestamps, likes, or comment counts through the editing grant. Test retaining, removing, and replacing attachments on a device. Existing visibility enforcement remains governed by the project's read rules.
