/**
 * ThinkVault Phase 8: End-to-End Smoke Test
 * Full happy-path: register → login → notes CRUD → search → submit feedback → admin review → logout.
 *
 * Usage: node test/e2e.test.js
 */

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

async function req(method, path, { body, token } = {}) {
    const res = await fetch(`${BASE}${path}`, {
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

async function run() {
    console.log('\n🌐 ThinkVault Phase 8: End-to-End Suite\n');
    const ts = Date.now();

    // ── 1. Health check ───────────────────────────────────────────────────────
    console.log('▶ Health');
    const health = await req('GET', '/health');
    assert('GET /api/health → 200', health.status === 200);

    // ── 2. Auth lifecycle ─────────────────────────────────────────────────────
    console.log('\n▶ Auth');
    const email = `e2e_${ts}@test.local`;
    const password = 'Password1!';

    const regRes = await req('POST', '/auth/register', { body: { name: 'E2E User', email, password } });
    assert('Register → 201', regRes.status === 201, JSON.stringify(regRes.data));

    const loginRes = await req('POST', '/auth/login', { body: { email, password } });
    assert('Login → 200', loginRes.status === 200);
    const { token } = loginRes.data.data;
    assert('Token present', !!token);

    // ── 3. Note CRUD ──────────────────────────────────────────────────────────
    console.log('\n▶ Notes CRUD');
    const createNote = await req('POST', '/notes', {
        token,
        body: { title: 'E2E Note', content: JSON.stringify([{ insert: 'hello' }]), priority: 'high' },
    });
    assert('Create note → 201', createNote.status === 201, JSON.stringify(createNote.data));
    const noteId = createNote.data?.data?.id;

    const getNote = await req('GET', `/notes/${noteId}`, { token });
    assert('Get note → 200', getNote.status === 200);
    assert('Note has correct title', getNote.data?.data?.title === 'E2E Note');

    const updateNote = await req('PATCH', `/notes/${noteId}`, {
        token,
        body: { title: 'E2E Note Updated', content: JSON.stringify([{ insert: 'updated' }]) },
    });
    assert('Update note → 200', updateNote.status === 200, JSON.stringify(updateNote.data));
    assert('Title updated', updateNote.data?.data?.title === 'E2E Note Updated');

    // ── 4. Search ─────────────────────────────────────────────────────────────
    console.log('\n▶ Search');
    const searchRes = await req('GET', '/notes/search?q=E2E', { token });
    assert('Search → 200', searchRes.status === 200);
    assert('Search returns results', Array.isArray(searchRes.data?.data?.notes));

    // ── 5. Feedback submission ────────────────────────────────────────────────
    console.log('\n▶ Feedback');
    const fbRes = await req('POST', '/feedback', {
        token,
        body: { type: 'feedback', subject: 'E2E feedback', body: 'All working great!' },
    });
    assert('Submit feedback → 201', fbRes.status === 201, JSON.stringify(fbRes.data));

    // ── 6. Admin flow ─────────────────────────────────────────────────────────
    console.log('\n▶ Admin Flow');
    const adminEmail = `e2e_admin_${ts}@test.local`;
    await req('POST', '/auth/register', { body: { name: 'E2E Admin', email: adminEmail, password } });
    const { pool } = require('../src/config/db');
    await pool.execute('UPDATE users SET role = "admin" WHERE email = ?', [adminEmail]);
    const { token: adminToken } = (await req('POST', '/auth/login', { body: { email: adminEmail, password } })).data.data;

    const metricsRes = await req('GET', '/admin/metrics', { token: adminToken });
    assert('Admin metrics → 200', metricsRes.status === 200);

    const fbListRes = await req('GET', '/feedback', { token: adminToken });
    assert('Admin feedback list → 200', fbListRes.status === 200);
    assert('Feedback visible to admin', fbListRes.data?.data?.total >= 1);

    // ── 7. Note deletion ──────────────────────────────────────────────────────
    console.log('\n▶ Cleanup');
    const delRes = await req('DELETE', `/notes/${noteId}`, { token });
    assert('Delete note → 200', delRes.status === 200);

    const getDeleted = await req('GET', `/notes/${noteId}`, { token });
    assert('Deleted note → 404', getDeleted.status === 404);

    // ── 8. Logout ─────────────────────────────────────────────────────────────
    const logoutRes = await req('POST', '/auth/logout', { token });
    assert('Logout → 200', logoutRes.status === 200);

    const afterLogout = await req('GET', '/notes', { token });
    assert('Token revoked after logout → 401', afterLogout.status === 401);

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
    else process.exit(0);
}

run().catch((err) => {
    console.error('\n💥 E2E runner error:', err);
    process.exit(1);
});
