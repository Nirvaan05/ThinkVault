/**
 * ThinkVault Phase 7: Feedback and Support Module Smoke Test
 * Tests feedback submission and admin review endpoints.
 *
 * Usage: node test/feedback.test.js
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
    console.log('\n🔬 ThinkVault Phase 7 Feedback Smoke Tests\n');

    // ── Setup: create user and admin ──────────────────────────────────────────
    const ts = Date.now();
    const userEmail = `user_${ts}@test.local`;
    const adminEmail = `admin_${ts}@test.local`;

    await req('POST', '/auth/register', {
        body: { name: 'Test User', email: userEmail, password: 'Password1!' },
    });
    const { token: userToken } = (await req('POST', '/auth/login', {
        body: { email: userEmail, password: 'Password1!' },
    })).data.data;

    await req('POST', '/auth/register', {
        body: { name: 'Admin User', email: adminEmail, password: 'Password1!' },
    });
    const { pool } = require('../src/config/db');
    await pool.execute('UPDATE users SET role = "admin" WHERE email = ?', [adminEmail]);
    const { token: adminToken } = (await req('POST', '/auth/login', {
        body: { email: adminEmail, password: 'Password1!' },
    })).data.data;

    // ── 1. Submit feedback ────────────────────────────────────────────────────
    console.log('▶ Feedback Submission');

    const fbRes = await req('POST', '/feedback', {
        token: userToken,
        body: { type: 'feedback', subject: 'Great app!', body: 'I love ThinkVault.' },
    });
    assert('User → POST /feedback is 201', fbRes.status === 201, JSON.stringify(fbRes.data));
    assert('Returns feedback entry', fbRes.data?.data?.id !== undefined);
    assert('Entry has status "open"', fbRes.data?.data?.status === 'open');
    const feedbackId = fbRes.data?.data?.id;

    // ── 2. Submit bug report ──────────────────────────────────────────────────
    const bugRes = await req('POST', '/feedback', {
        token: userToken,
        body: { type: 'bug', subject: 'Crash on sync', body: 'App crashes when syncing offline.' },
    });
    assert('User → POST /feedback (bug) is 201', bugRes.status === 201, JSON.stringify(bugRes.data));
    assert('Bug type stored correctly', bugRes.data?.data?.type === 'bug');

    // ── 3. Missing fields → 400 ───────────────────────────────────────────────
    console.log('\n▶ Validation');
    const badRes = await req('POST', '/feedback', {
        token: userToken,
        body: { type: 'feedback' }, // missing subject and body
    });
    assert('Missing fields → 400', badRes.status === 400, JSON.stringify(badRes.data));

    // ── 4. Non-admin cannot list feedback ─────────────────────────────────────
    console.log('\n▶ Authorization');
    const uListRes = await req('GET', '/feedback', { token: userToken });
    assert('User → GET /feedback is 403', uListRes.status === 403);

    // ── 5. Admin lists feedback ───────────────────────────────────────────────
    console.log('\n▶ Admin Review');
    const aListRes = await req('GET', '/feedback', { token: adminToken });
    assert('Admin → GET /feedback is 200', aListRes.status === 200, JSON.stringify(aListRes.data));
    assert('Returns items array', Array.isArray(aListRes.data?.data?.items));
    assert('Contains submitted entries', aListRes.data?.data?.total >= 2);

    // Filter by type
    const bugListRes = await req('GET', '/feedback?type=bug', { token: adminToken });
    assert('Filter by type=bug works', bugListRes.status === 200 && bugListRes.data?.data?.items?.every(i => i.type === 'bug'));

    // ── 6. Admin gets single entry ────────────────────────────────────────────
    if (feedbackId) {
        const singleRes = await req('GET', `/feedback/${feedbackId}`, { token: adminToken });
        assert('Admin → GET /feedback/:id is 200', singleRes.status === 200);
        assert('Entry has user info', singleRes.data?.data?.user_email === userEmail);

        // ── 7. Admin updates status ───────────────────────────────────────────
        console.log('\n▶ Status Update');
        const patchRes = await req('PATCH', `/feedback/${feedbackId}/status`, {
            token: adminToken,
            body: { status: 'in_progress' },
        });
        assert('Admin → PATCH /feedback/:id/status is 200', patchRes.status === 200);
        assert('Status updated to in_progress', patchRes.data?.data?.status === 'in_progress');

        // Filter by status
        const inProgressList = await req('GET', '/feedback?status=in_progress', { token: adminToken });
        assert('Filter by status=in_progress works', inProgressList.status === 200 && inProgressList.data?.data?.items?.some(i => i.id === feedbackId));
    }

    // ── 8. Unauthenticated submit → 401 ──────────────────────────────────────
    console.log('\n▶ Unauthenticated Access');
    const noAuthRes = await req('POST', '/feedback', {
        body: { type: 'feedback', subject: 'test', body: 'test' },
    });
    assert('No token → POST /feedback is 401', noAuthRes.status === 401);

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
    else process.exit(0);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err);
    process.exit(1);
});
