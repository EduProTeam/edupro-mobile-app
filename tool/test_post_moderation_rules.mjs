// Run only through the Firestore emulator; no npm packages are required.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const host = process.env.FIRESTORE_EMULATOR_HOST;
const project = process.env.GCLOUD_PROJECT;
assert.match(host ?? '', /^(localhost|127\.0\.0\.1):\d+$/,
  'A local FIRESTORE_EMULATOR_HOST is required.');
assert.match(project ?? '', /^demo-/,
  'Use a demo- project ID so these tests cannot write to a live project.');
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const config = JSON.parse(await readFile(
  new URL('../assets/moderation/blocked_words.json', import.meta.url), 'utf8'));
const blocked = config.blockedWords[0];
let checks = 0;

function token(uid) {
  const seconds = Math.floor(Date.now() / 1000);
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`,
    aud: project, sub: uid, user_id: uid, iat: seconds,
    exp: seconds + 3600, auth_time: seconds,
    firebase: { sign_in_provider: 'custom', identities: {} },
  })}.`;
}

function value(input) {
  if (typeof input === 'string') return { stringValue: input };
  if (typeof input === 'number') return { integerValue: String(input) };
  if (Array.isArray(input)) return { arrayValue: { values: input.map(value) } };
  if (input === null) return { nullValue: null };
  throw new Error('Unsupported test value');
}

async function write(id, fields, { actor = 'alice', admin = false, update = false } = {}) {
  const query = new URLSearchParams();
  if (update) Object.keys(fields).forEach(key => query.append('updateMask.fieldPaths', key));
  const response = await fetch(`${root}/posts/${id}?${query}`, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      ...(actor === null ? {} : { authorization: `Bearer ${admin ? 'owner' : token(actor)}` }),
    },
    body: JSON.stringify({
      fields: Object.fromEntries(Object.entries(fields).map(([key, input]) => [key, value(input)])),
    }),
  });
  return { status: response.status, body: await response.text() };
}

function allowed(result, label) {
  assert.equal(result.status, 200, `${label}: ${result.body}`);
  checks++;
}

function denied(result, label) {
  assert.equal(result.status, 403, `${label}: ${result.body}`);
  checks++;
}

const safePost = changes => ({
  userId: 'alice', title: 'Learning Flutter', content: 'A helpful lesson',
  tags: ['learning'], status: 'published', likeCount: 0,
  likedBy: [], commentCount: 0, ...changes,
});

allowed(await write('clean', safePost()), 'Owner creates a clean post');
denied(await write('anonymous', safePost(), { actor: null }), 'Anonymous creation');
denied(await write('wrong-owner', safePost(), { actor: 'bob' }), 'Creation for another owner');
denied(await write('malformed', safePost({ title: null })), 'Non-string title');
denied(await write('malformed-content', safePost({ content: null })), 'Non-string content');
denied(await write('malformed-tags', safePost({ tags: 'learning' })), 'Non-list tags');
denied(await write('clean', { userId: 'bob' }, { update: true }), 'Reassigning ownership');
allowed(await write('clean', { likeCount: 1, likedBy: ['bob'] }, { actor: 'bob', update: true }),
  'Non-owner counters remain usable');
denied(await write('clean', { content: 'A replacement lesson', likeCount: 2 },
  { actor: 'bob', update: true }), 'Non-owner cannot mix text with counters');

if (blocked) {
  for (const [index, word] of config.blockedWords.entries()) {
    denied(await write(`blocked-word-${index}`, safePost({ title: `Before ${word} after` })),
      `Configured word ${index + 1} is blocked by RE2`);
  }
  for (const field of ['title', 'content', 'tags']) {
    const text = `First line\n${blocked.toUpperCase()}\nLast line`;
    denied(await write(`blocked-${field}`, safePost({
      [field]: field === 'tags' ? ['learning', blocked.toUpperCase()] : text,
    })), `Blocked ${field}`);
  }
  denied(await write('separated-word', safePost({ title: [...blocked].join('.') })),
    'Punctuation inserted between letters');
  allowed(await write('substring', safePost({ title: `prefix${blocked}suffix` })),
    'Harmless substrings do not trigger whole-word checks');
  allowed(await write('unicode-boundary', safePost({ title: `නරක${blocked}சொல்` })),
    'Sinhala and Tamil letters are word characters in RE2');
  const leetWord = config.blockedWords.find(word => /[aeiost]/i.test(word));
  if (leetWord) {
    const substitutions = { a: '@', e: '3', i: '1', o: '0', s: '5', t: '7' };
    const disguised = [...leetWord.toLowerCase()].map(letter => substitutions[letter] ?? letter).join('');
    denied(await write('leet-word', safePost({ title: disguised })),
      'Common letter substitutions are blocked by RE2');
  }
  denied(await write('many-tags', safePost({ tags: [...Array(25).fill('learning'), blocked] })),
    'The last tag is checked without a fixed tag limit');
  denied(await write('clean', { title: blocked, likeCount: 2 }, { update: true }),
    'Owner cannot bypass moderation by mixing text with counters');
  denied(await write('clean', { tags: [blocked], commentCount: 2 }, { update: true }),
    'Owner cannot bypass tag moderation by mixing counters');

  // Seed old data with the emulator's administrator token to test migration cases.
  allowed(await write('legacy', safePost({ content: blocked, status: 'draft' }), { admin: true }),
    'Seed a legacy draft containing a blocked word');
  denied(await write('legacy', { status: 'published' }, { update: true }),
    'A legacy draft cannot be published with blocked content');
  allowed(await write('legacy', { commentCount: 1 }, { actor: 'bob', update: true }),
    'Legacy counters remain usable');
  denied(await write('legacy', { status: 'deleted', title: blocked }, { update: true }),
    'Soft deletion cannot carry a new blocked text edit');
  allowed(await write('legacy', {
    status: 'deleted', deletedAt: 'test timestamp', updatedAt: 'test timestamp',
  }, { update: true }), 'An owner can soft-delete legacy flagged content');
  denied(await write('legacy', { status: 'published' }, { update: true }),
    'Restoring legacy flagged content is checked');
  allowed(await write('legacy', { content: 'Corrected lesson', status: 'published' }, { update: true }),
    'Corrected legacy content can be published');
} else {
  console.log('The configured list is empty; blocked-text cases are disabled.');
}

console.log(`Passed ${checks} Firestore post moderation checks.`);
