/**
 * ThinkVault Phase 5 Smoke Test — Attachments
 * Tests upload, list, download, delete, ownership enforcement, auth guards.
 *
 * Prerequisites:
 *   1. Backend running on http://localhost:3000
 *   2. A valid test image file at `test/fixtures/test_image.jpg`
 *      (created automatically if not present)
 *
 * Usage: node test/attachments.test.js
 */

const fs = require('fs');
const path = require('path');

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

// ── Tiny JPEG fixture (1×1 pixel) ────────────────────────────────────────────
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const FIXTURE_PATH = path.join(FIXTURES_DIR, 'test_image.jpg');

function ensureFixture() {
    if (!fs.existsSync(FIXTURES_DIR)) fs.mkdirSync(FIXTURES_DIR, { recursive: true });
    if (!fs.existsSync(FIXTURE_PATH)) {
        // Minimal valid JPEG (1x1 white pixel)
        const jpegBytes = Buffer.from(
            'FFD8FFE000104A464946000101000001000100' +
            '00FFDB004300080606070605080707070909' +
            '08080A0A0B0D100D0C0C10110F0C0C100C' +
            '1C131414120000' +
            'FFDA00030101003F00F0FFDA0008010100003F' +
            '007FFF00FFD8FFD9',
            'hex'
        );
        fs.writeFileSync(FIXTURE_PATH, jpegBytes);
    }
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────
async function req(method, urlPath, { body, token, query } = {}) {
    let url = `${BASE}${urlPath}`;
    if (query) url += '?' + new URLSearchParams(query).toString();

    const res = await fetch(url, {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, data };
}

async function uploadFile(noteId, token, filePath) {
    const form = new FormData();
    const bytes = fs.readFileSync(filePath);
    form.append('file', new Blob([bytes], { type: 'image/jpeg' }), path.basename(filePath));

    const res = await fetch(`${BASE}/notes/${noteId}/attachments`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: form,
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, data };
}

function assert(label, condition, detail = '') {
    if (condition) {
        console.log(`  ✅ ${label}`);
        passed++;
    } else {
        console.error(`  ❌ ${label}${detail ? ' — ' + detail : ''}`);
        failed++;
    }
}

async function makeUser(suffix) {
    const email = `attach_${suffix}_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: `Attach ${suffix}`, email, password: 'Attach@Test123' },
    });
    const r = await req('POST', '/auth/login', {
        body: { email, password: 'Attach@Test123' },
    });
    return { token: r.data?.data?.token, userId: r.data?.data?.user?.id };
}

async function run() {
    console.log('\n🔬 ThinkVault Phase 5 Smoke Tests — Attachments\n');

    ensureFixture();

    // ── Setup ──────────────────────────────────────────────────────────────────
    console.log('▶ Setup: users and note');
    const userA = await makeUser('A');
    const userB = await makeUser('B');
    assert('User A logged in', !!userA.token);
    assert('User B logged in', !!userB.token);

    const noteRes = await req('POST', '/notes', {
        token: userA.token,
        body: { title: 'Attachment Test Note' },
    });
    const noteId = noteRes.data?.data?.id;
    assert('Note created for User A', !!noteId, JSON.stringify(noteRes.data));

    // ── Upload ─────────────────────────────────────────────────────────────────
    console.log('\n▶ Upload attachment');
    const uploadRes = await uploadFile(noteId, userA.token, FIXTURE_PATH);
    assert('POST /notes/:id/attachments → 201', uploadRes.status === 201, JSON.stringify(uploadRes.data));
    const attachId = uploadRes.data?.data?.id;
    assert('Response includes attachment id', !!attachId, JSON.stringify(uploadRes.data));
    assert('Filename matches', uploadRes.data?.data?.filename === 'test_image.jpg');
    assert('MIME type correct', uploadRes.data?.data?.mime_type === 'image/jpeg');

    // ── List ───────────────────────────────────────────────────────────────────
    console.log('\n▶ List attachments');
    const listRes = await req('GET', `/notes/${noteId}/attachments`, { token: userA.token });
    assert('GET /notes/:id/attachments → 200', listRes.status === 200, JSON.stringify(listRes.data));
    const attachments = listRes.data?.data ?? [];
    assert('List contains uploaded attachment', attachments.some((a) => a.id === attachId));

    // ── Download ───────────────────────────────────────────────────────────────
    console.log('\n▶ Download attachment');
    const dlRes = await fetch(`${BASE}/attachments/${attachId}/download`, {
        headers: { Authorization: `Bearer ${userA.token}` },
    });
    assert('GET /attachments/:id/download → 200', dlRes.status === 200, `status: ${dlRes.status}`);
    assert('Content-Type is image/jpeg', dlRes.headers.get('content-type')?.startsWith('image/jpeg') ?? false);

    // ── Ownership enforcement ──────────────────────────────────────────────────
    console.log('\n▶ Ownership enforcement (User B → User A\'s note/attachment)');
    const crossList = await req('GET', `/notes/${noteId}/attachments`, { token: userB.token });
    assert('User B GET User A\'s attachments → 403', crossList.status === 403, JSON.stringify(crossList.data));

    const crossDl = await fetch(`${BASE}/attachments/${attachId}/download`, {
        headers: { Authorization: `Bearer ${userB.token}` },
    });
    assert('User B download User A\'s attachment → 403', crossDl.status === 403);

    const crossDel = await req('DELETE', `/attachments/${attachId}`, { token: userB.token });
    assert('User B DELETE User A\'s attachment → 403', crossDel.status === 403, JSON.stringify(crossDel.data));

    // ── Auth guards ────────────────────────────────────────────────────────────
    console.log('\n▶ Auth guards');
    const noTokenUpload = await fetch(`${BASE}/notes/${noteId}/attachments`, {
        method: 'POST',
        body: new FormData(),
    });
    assert('Upload without token → 401', noTokenUpload.status === 401);

    const noTokenList = await req('GET', `/notes/${noteId}/attachments`);
    assert('List without token → 401', noTokenList.status === 401);

    // ── Delete ─────────────────────────────────────────────────────────────────
    console.log('\n▶ Delete attachment');
    const delRes = await req('DELETE', `/attachments/${attachId}`, { token: userA.token });
    assert('DELETE /attachments/:id → 200', delRes.status === 200, JSON.stringify(delRes.data));

    const afterDel = await req('GET', `/notes/${noteId}/attachments`, { token: userA.token });
    const afterList = afterDel.data?.data ?? [];
    assert('After delete, list is empty', !afterList.some((a) => a.id === attachId));

    // ── Summary ────────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err.message);
    process.exit(1);
});
