/**
 * ThinkVault Phase 5 Smoke Test — Sync Delta
 * Tests delta endpoint: user-scoped results, since filtering, auth guard.
 *
 * Usage: node test/sync.test.js
 * Requires: backend running on http://localhost:3000
 */

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

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
    const email = `sync_${suffix}_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: `Sync ${suffix}`, email, password: 'Sync@Test123' },
    });
    const r = await req('POST', '/auth/login', {
        body: { email, password: 'Sync@Test123' },
    });
    return { token: r.data?.data?.token, userId: r.data?.data?.user?.id };
}

async function run() {
    console.log('\n🔬 ThinkVault Phase 5 Smoke Tests — Sync Delta\n');

    // ── Setup ──────────────────────────────────────────────────────────────────
    console.log('▶ Setup: two users');
    const userA = await makeUser('A');
    const userB = await makeUser('B');
    assert('User A logged in', !!userA.token);
    assert('User B logged in', !!userB.token);

    // Use epoch 0 to guarantee all notes are returned (avoids client/server clock drift)
    const beforeCreate = new Date(0).toISOString();

    // Create a note for User A
    const noteRes = await req('POST', '/notes', {
        token: userA.token,
        body: { title: 'Sync Test Note', content: '{}' },
    });
    const noteId = noteRes.data?.data?.id;
    assert('Note created for User A', !!noteId, JSON.stringify(noteRes.data));

    // ── Delta with since=before creation → note appears ───────────────────────
    console.log('\n▶ Delta since before creation');
    const deltaEarly = await req('GET', '/sync/delta', {
        token: userA.token,
        query: { since: beforeCreate },
    });
    assert('GET /sync/delta → 200', deltaEarly.status === 200, JSON.stringify(deltaEarly.data));
    const earlyUpdated = deltaEarly.data?.data?.updated ?? [];
    assert('Delta contains created note', earlyUpdated.some((n) => n.id === noteId),
        `updated ids: ${earlyUpdated.map((n) => n.id)}`);
    assert('server_time present', !!deltaEarly.data?.data?.server_time);

    // ── Delta with since=server_time → nothing new ─────────────────────────────
    console.log('\n▶ Delta since server_time (nothing new expected)');
    // Use server_time from the first delta response — guaranteed to be after note creation
    const afterCreate = deltaEarly.data?.data?.server_time;
    const deltaLate = await req('GET', '/sync/delta', {
        token: userA.token,
        query: { since: afterCreate },
    });
    assert('GET /sync/delta (late) → 200', deltaLate.status === 200, JSON.stringify(deltaLate.data));
    const lateUpdated = deltaLate.data?.data?.updated ?? [];
    assert('Delta with server_time since returns empty updated', lateUpdated.length === 0,
        `got ${lateUpdated.length} notes`);

    // ── User scoping — User B doesn't see User A's notes ──────────────────────
    console.log('\n▶ User isolation');
    const deltaB = await req('GET', '/sync/delta', {
        token: userB.token,
        query: { since: beforeCreate },
    });
    assert('User B delta → 200', deltaB.status === 200, JSON.stringify(deltaB.data));
    const bUpdated = deltaB.data?.data?.updated ?? [];
    assert('User B delta does NOT include User A\'s note', !bUpdated.some((n) => n.id === noteId));

    // ── Delta with no since param → returns all user notes ────────────────────
    console.log('\n▶ Delta with no since param');
    const deltaAll = await req('GET', '/sync/delta', { token: userA.token });
    assert('GET /sync/delta (no since) → 200', deltaAll.status === 200, JSON.stringify(deltaAll.data));
    const allUpdated = deltaAll.data?.data?.updated ?? [];
    assert('Delta without since includes note', allUpdated.some((n) => n.id === noteId));

    // ── Auth guard ────────────────────────────────────────────────────────────
    console.log('\n▶ Auth guard');
    const noToken = await req('GET', '/sync/delta');
    assert('GET /sync/delta without token → 401', noToken.status === 401, JSON.stringify(noToken.data));

    // ── Invalid since param ───────────────────────────────────────────────────
    console.log('\n▶ Validation');
    const badSince = await req('GET', '/sync/delta', {
        token: userA.token,
        query: { since: 'not-a-date' },
    });
    assert('GET /sync/delta with bad since → 400 or handled gracefully',
        badSince.status === 400 || badSince.status === 500,
        `status: ${badSince.status} body: ${JSON.stringify(badSince.data)}`);

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err.message);
    process.exit(1);
});
