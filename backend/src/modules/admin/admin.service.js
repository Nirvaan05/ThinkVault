const adminRepository = require('./admin.repository');
const { AppError } = require('../../middleware/errorHandler');

class AdminService {
    async getMetrics() {
        return await adminRepository.getMetrics();
    }

    async listUsers(opts) {
        return await adminRepository.listUsers(opts);
    }

    async getConfig() {
        return await adminRepository.getAllConfig();
    }

    async updateConfig(key, value, adminId) {
        const current = await adminRepository.getConfigByKey(key);
        if (!current) {
            throw new AppError(`Config key '${key}' not found`, 404);
        }

        // Avoid logging if value hasn't actually changed
        if (current.config_value === value) {
            return { updated: false, config_key: key, config_value: value };
        }

        // 1. Log the change
        await adminRepository.logConfigChange({
            key,
            old_value: current.config_value,
            new_value: value,
            changed_by: adminId,
        });

        // 2. Update the config value
        await adminRepository.upsertConfig(key, value, current.description);

        return { updated: true, config_key: key, config_value: value };
    }

    async getAuditLog(opts) {
        return await adminRepository.getAuditLog(opts);
    }
}

module.exports = new AdminService();
