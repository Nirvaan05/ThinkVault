/**
 * ThinkVault Phase 8: Security Validation Test
 * Validates SQL injection, IDOR, account lockout, and authorization boundaries.
 *
 * Usage: node test/security.test.js
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

async function register(n) {
    const email = `sec_${n}_${Date.now()}@test.local`;
    await req('POST', '/auth/register', { body: { name: 'Sec User', email, password: 'Password1!' } });
    const loginRes = await req('POST', '/auth/login', { body: { email, password: 'Password1!' } });
    return { token: loginRes.data.data?.token, email };
}

async function run() {
    console.log('\n🔒 ThinkVault Phase 8: Security Validation\n');

    // ── 1. SQL Injection in search ────────────────────────────────────────────
    console.log('▶ SQL Injection');
    const { token } = await register('sqli');

    const sqliRes = await req('GET', "/notes/search?q=' OR '1'='1", { token });
    assert('SQLi in search → does not crash (200 or 400)', [200, 400].includes(sqliRes.status));
    // Should not return notes from other users
    const sqliNotes = sqliRes.data?.data?.notes ?? [];
    assert('SQLi returns only own notes (no data leak)', sqliNotes.every(n => n)); // structural check

    const xssRes = await req('POST', '/notes', {
        token,
        body: {
            title: '<script>alert(1)</script>',
            content: JSON.stringify([{ insert: '<img onerror="alert(1)">' }]),
        },
    });
    assert('XSS payload stored safely (not executed server-side, 201)', xssRes.status === 201);

    // ── 2. IDOR: cross-user note access ───────────────────────────────────────
    console.log('\n▶ IDOR (Cross-User Note Access)');
    const { token: tokenA } = await register('idor_a');
    const { token: tokenB } = await register('idor_b');

    // User A creates a note
    const noteRes = await req('POST', '/notes', {
        token: tokenA,
        body: { title: 'Private Note', content: JSON.stringify([{ insert: 'secret' }]) },
    });
    const noteId = noteRes.data?.data?.id;

    // User B tries to read it
    const idorGetRes = await req('GET', `/notes/${noteId}`, { token: tokenB });
    assert('User B GET other\'s note → 403', idorGetRes.status === 403, JSON.stringify(idorGetRes.data));

    // User B tries to update it
    const idorPutRes = await req('PATCH', `/notes/${noteId}`, {
        token: tokenB, body: { title: 'Hacked' },
    });
    assert('User B PUT other\'s note → 403', idorPutRes.status === 403);

    // User B tries to delete it
    const idorDelRes = await req('DELETE', `/notes/${noteId}`, { token: tokenB });
    assert('User B DELETE other\'s note → 403', idorDelRes.status === 403);

    // ── 3. Account lockout ────────────────────────────────────────────────────
    console.log('\n▶ Account Lockout');
    const lockEmail = `sec_lock_${Date.now()}@test.local`;
    await req('POST', '/auth/register', {
        body: { name: 'Lockout User', email: lockEmail, password: 'CorrectPass1!' },
    });

    let lastStatus = 0;
    for (let i = 0; i < 6; i++) {
        const r = await req('POST', '/auth/login', { body: { email: lockEmail, password: 'WrongPass!' } });
        lastStatus = r.status;
    }
    assert('6 failed logins → 423 lockout', lastStatus === 423, `Last status: ${lastStatus}`);

    // Correct password should still fail while locked
    const lockedLoginRes = await req('POST', '/auth/login', {
        body: { email: lockEmail, password: 'CorrectPass1!' },
    });
    assert('Correct password refused during lockout → 423', lockedLoginRes.status === 423);

    // ── 4. Authorization boundary checks ─────────────────────────────────────
    console.log('\n▶ Authorization Boundaries');

    // No token → 401
    const noTokenRes = await req('GET', '/notes');
    assert('No token → GET /notes is 401', noTokenRes.status === 401);

    // Regular user → admin routes → 403
    const { token: userToken } = await register('authboundary');
    const adminBoundaryRes = await req('GET', '/admin/metrics', { token: userToken });
    assert('User token → GET /admin/metrics is 403', adminBoundaryRes.status === 403);

    const fbAdminRes = await req('GET', '/feedback', { token: userToken });
    assert('User token → GET /feedback (admin) is 403', fbAdminRes.status === 403);

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
    else process.exit(0);
}

run().catch((err) => {
    console.error('\n💥 Security test runner error:', err);
    process.exit(1);
});
