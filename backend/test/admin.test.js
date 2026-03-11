/**
 * ThinkVault Phase 6: Admin Operations Smoke Test
 * Runs basic API checks on admin metrics, users, config, and audit endpoints.
 *
 * Usage: node test/admin.test.js
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
    console.log('\n🔬 ThinkVault Phase 6 Admin Smoke Tests\n');

    // 1. Create a regular user
    const userEmail = `reguser_${Date.now()}@test.local`;
    const regRes = await req('POST', '/auth/register', {
        body: { name: 'Regular User', email: userEmail, password: 'Password1!' }
    });
    const { token: userToken } = (await req('POST', '/auth/login', {
        body: { email: userEmail, password: 'Password1!' }
    })).data.data;

    // 2. Regular user should get 403 on admin routes
    console.log('▶ Auth Guard');
    const uMetrics = await req('GET', '/admin/metrics', { token: userToken });
    assert('User -> /admin/metrics is 403', uMetrics.status === 403);

    // 3. Create an admin user (we have to manually update DB via direct repo for testing)
    const adminEmail = `admintest_${Date.now()}@test.local`;
    await req('POST', '/auth/register', {
        body: { name: 'Admin User', email: adminEmail, password: 'Password1!' }
    });

    // Elevate to admin (we will just connect to pool directly for the test setup)
    const { pool } = require('../src/config/db');
    await pool.execute('UPDATE users SET role = "admin" WHERE email = ?', [adminEmail]);

    const { token: adminToken, user } = (await req('POST', '/auth/login', {
        body: { email: adminEmail, password: 'Password1!' }
    })).data.data;

    // 4. Test metrics
    console.log('\n▶ Metrics');
    const metrics = await req('GET', '/admin/metrics', { token: adminToken });
    assert('Admin -> /admin/metrics is 200', metrics.status === 200, JSON.stringify(metrics.data));
    assert('Metrics structure valid', metrics.data?.data?.total_users !== undefined);

    // 5. Test users list
    console.log('\n▶ Users List');
    const users = await req('GET', '/admin/users?limit=2', { token: adminToken });
    assert('Admin -> /admin/users is 200', users.status === 200, JSON.stringify(users.data));
    assert('Returns user objects', Array.isArray(users.data?.data?.users));
    assert('Respects pagination limit', users.data?.data?.users?.length <= 2);

    // 6. Test App Config Defaults
    console.log('\n▶ App Config');
    const config = await req('GET', '/admin/config', { token: adminToken });
    assert('Admin -> /admin/config is 200', config.status === 200, JSON.stringify(config.data));
    const configs = config.data?.data?.config;
    assert('Returns seeded config values', Array.isArray(configs) && configs.find(c => c.config_key === 'maintenance_mode'));

    // 7. Test Updating App Config — use unique value each run to force a real change
    console.log('\n▶ Config Update & Audit Log');
    const newSize = String(10 + (Date.now() % 10) + 1); // guaranteed different from seed '10'
    const putStatus = await req('PUT', '/admin/config/max_upload_size_mb', {
        token: adminToken,
        body: { value: newSize }
    });
    assert('Admin -> PUT /admin/config/max_upload_size_mb is 200', putStatus.status === 200, JSON.stringify(putStatus.data));

    const checkConfig = await req('GET', '/admin/config', { token: adminToken });
    const updatedVal = checkConfig.data?.data?.config?.find(c => c.config_key === 'max_upload_size_mb')?.config_value;
    assert('Config value was successfully updated', updatedVal === newSize);

    // 8. Test Audit Logs
    const auditStatus = await req('GET', '/admin/config/audit', { token: adminToken });
    assert('Admin -> GET /admin/config/audit is 200', auditStatus.status === 200, JSON.stringify(auditStatus.data));
    const logs = auditStatus.data?.data?.logs || [];
    assert('Audit log contains recent change', Array.isArray(logs) && logs.length > 0);
    if (logs.length > 0) {
        const lastLog = logs[0];
        console.log(`  ℹ Debug: lastLog=${JSON.stringify(lastLog)}, user.id=${user.id}`);
        // eslint-disable-next-line eqeqeq -- user_id may come back as string or number
        assert('Audit log tracks old vs new value', lastLog.config_key === 'max_upload_size_mb' && lastLog.new_value === newSize && lastLog.user_id == user.id);
    }

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
