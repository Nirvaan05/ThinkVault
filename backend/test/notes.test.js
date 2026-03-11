/**
 * ThinkVault Phase 3 Smoke Test — Core Notes Lifecycle
 * Tests CRUD, ownership enforcement, auth guards, and validation.
 *
 * Usage: node test/notes.test.js
 * Requires: backend running on http://localhost:3000
 */

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

async function req(method, path, { body, token, query } = {}) {
    let url = `${BASE}${path}`;
    if (query) {
        url += '?' + new URLSearchParams(query).toString();
    }
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

function assert(label, condition, detail = '') {
    if (condition) {
        console.log(`  ✅ ${label}`);
        passed++;
    } else {
        console.error(`  ❌ ${label}${detail ? ' — ' + detail : ''}`);
        failed++;
    }
}

/** Register + login a test user, return token and userId */
async function makeUser(suffix) {
    const email = `notes_${suffix}_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: `Notes ${suffix}`, email, password: 'Notes@Test123' },
    });
    const r = await req('POST', '/auth/login', {
        body: { email, password: 'Notes@Test123' },
    });
    return {
        token: r.data?.data?.token,
        userId: r.data?.data?.user?.id,
    };
}

async function run() {
    console.log('\n🔬 ThinkVault Phase 3 Smoke Tests — Notes\n');

    // ── Setup: two users ──────────────────────────────────────────────────────
    console.log('▶ Setup: creating two test users');
    const userA = await makeUser('A');
    const userB = await makeUser('B');
    assert('User A registered and logged in', !!userA.token);
    assert('User B registered and logged in', !!userB.token);

    // ── Create note ──────────────────────────────────────────────────────────
    console.log('\n▶ Create note (User A)');
    const createRes = await req('POST', '/notes', {
        token: userA.token,
        body: { title: 'My First Note', content: '{"ops":[{"insert":"Hello world!\\n"}]}', is_pinned: false },
    });
    assert('POST /notes → 201', createRes.status === 201, JSON.stringify(createRes.data));
    const noteId = createRes.data?.data?.id;
    assert('Response includes note id', !!noteId, JSON.stringify(createRes.data));
    assert('Title matches', createRes.data?.data?.title === 'My First Note');

    // ── List notes ────────────────────────────────────────────────────────────
    console.log('\n▶ List notes (User A)');
    const listRes = await req('GET', '/notes', { token: userA.token });
    assert('GET /notes → 200', listRes.status === 200, JSON.stringify(listRes.data));
    const notesList = listRes.data?.data?.notes ?? [];
    assert('List contains created note', notesList.some((n) => n.id === noteId));
    assert('Pagination metadata present', !!listRes.data?.data?.pagination);

    // ── List pagination params ────────────────────────────────────────────────
    console.log('\n▶ Pagination params');
    const pageRes = await req('GET', '/notes', {
        token: userA.token,
        query: { page: 1, limit: 5, sort: 'created_at', order: 'asc' },
    });
    assert('GET /notes with pagination → 200', pageRes.status === 200, JSON.stringify(pageRes.data));

    // ── Get by ID ─────────────────────────────────────────────────────────────
    console.log('\n▶ Get note by ID (User A)');
    const getRes = await req('GET', `/notes/${noteId}`, { token: userA.token });
    assert('GET /notes/:id → 200', getRes.status === 200, JSON.stringify(getRes.data));
    assert('Correct title returned', getRes.data?.data?.title === 'My First Note');
    assert('Content returned', getRes.data?.data?.content !== undefined);

    // ── Update note ───────────────────────────────────────────────────────────
    console.log('\n▶ Update note (User A)');
    const updateRes = await req('PATCH', `/notes/${noteId}`, {
        token: userA.token,
        body: { title: 'Updated Title', is_pinned: true },
    });
    assert('PATCH /notes/:id → 200', updateRes.status === 200, JSON.stringify(updateRes.data));
    assert('Title updated', updateRes.data?.data?.title === 'Updated Title');
    assert('is_pinned updated', updateRes.data?.data?.is_pinned === 1 || updateRes.data?.data?.is_pinned === true);

    // ── Validation: empty title ────────────────────────────────────────────────
    console.log('\n▶ Validation');
    const badCreate = await req('POST', '/notes', {
        token: userA.token,
        body: { title: '' },
    });
    assert('Empty title → 400', badCreate.status === 400, JSON.stringify(badCreate.data));

    const badUpdate = await req('PATCH', `/notes/${noteId}`, {
        token: userA.token,
        body: {},
    });
    assert('Empty PATCH body → 400', badUpdate.status === 400, JSON.stringify(badUpdate.data));

    // ── Cross-user ownership enforcement ──────────────────────────────────────
    console.log('\n▶ Ownership enforcement (User B → User A\'s note)');
    const crossGet = await req('GET', `/notes/${noteId}`, { token: userB.token });
    assert('User B GET User A note → 403', crossGet.status === 403, JSON.stringify(crossGet.data));

    const crossPatch = await req('PATCH', `/notes/${noteId}`, {
        token: userB.token,
        body: { title: 'Hijacked' },
    });
    assert('User B PATCH User A note → 403', crossPatch.status === 403, JSON.stringify(crossPatch.data));

    const crossDelete = await req('DELETE', `/notes/${noteId}`, { token: userB.token });
    assert('User B DELETE User A note → 403', crossDelete.status === 403, JSON.stringify(crossDelete.data));

    // ── User B list only sees own notes ───────────────────────────────────────
    console.log('\n▶ User isolation');
    const bList = await req('GET', '/notes', { token: userB.token });
    const bNotes = bList.data?.data?.notes ?? [];
    assert('User B list does NOT contain User A\'s note', !bNotes.some((n) => n.id === noteId));

    // ── Unauthenticated requests → 401 ───────────────────────────────────────
    console.log('\n▶ Auth guards');
    const noTokenList = await req('GET', '/notes');
    assert('GET /notes without token → 401', noTokenList.status === 401);

    const noTokenCreate = await req('POST', '/notes', {
        body: { title: 'Sneaky note' },
    });
    assert('POST /notes without token → 401', noTokenCreate.status === 401);

    const noTokenGet = await req('GET', `/notes/${noteId}`);
    assert('GET /notes/:id without token → 401', noTokenGet.status === 401);

    // ── Delete note ───────────────────────────────────────────────────────────
    console.log('\n▶ Delete note (User A)');
    const delRes = await req('DELETE', `/notes/${noteId}`, { token: userA.token });
    assert('DELETE /notes/:id → 200', delRes.status === 200, JSON.stringify(delRes.data));

    const afterDel = await req('GET', `/notes/${noteId}`, { token: userA.token });
    assert('GET deleted note → 404', afterDel.status === 404, JSON.stringify(afterDel.data));

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err.message);
    process.exit(1);
});
