-- 智校通建表语句及示例数据
-- 内容依据：智校通-数据库设计.docx；格式参考：建表语句-鸿医灵枢.txt。
-- 共57张业务表，每表5条数据，共285条；所有业务表均以id为自增主键。
-- 适用环境：MySQL 8.0.16及以上，InnoDB，utf8mb4。
-- 警告：本脚本会DROP并重建当前数据库中的57张同名表，原表数据将被删除且不能通过ROLLBACK恢复。
-- 必须先备份，并在独立、空的测试数据库执行；不要用于生产库或与其他业务共用的数据库。
-- 请先在客户端选中测试数据库；如需创建，可单独执行下面两行（确认库名未被使用）：
-- CREATE DATABASE `zhixiaotong_demo` DEFAULT CHARACTER SET utf8mb4;
-- USE `zhixiaotong_demo`;
-- 按文件顺序在同一连接执行；遇到错误立即停止，排查后从空测试库重跑，不要忽略错误继续执行。
-- 为处理用户与文件等循环引用，先按文档顺序建表和插入数据，再开启检查并添加109个外键。
-- 外键未指定级联删除，使用默认限制行为；biz_id等多态逻辑引用由应用按业务类型校验。
-- 更新时间沿用设计文档：默认CURRENT_TIMESTAMP，更新时由服务端写入，不擅自增加ON UPDATE。
-- 跨行规则（先修无环、容量并发、唯一当前学期、范围权限、账务一致性等）仍需业务事务保证。
-- 示例为2026-01-18 18:00的教学快照；人物、书目、支付订单、设备及业务数据均为虚构。
-- 用户ID 1学生、2教师、3辅导员、4管理员、5教学秘书；权限数据仅为示例，不是完整授权清单。
-- 五个演示账号密码均为Demo@123456，仅供本地测试；上线前必须删除演示账号或重置密码。
-- password_hash使用$pbkdf2-sha256$轮次$Base64盐$Base64摘要格式，600000轮，应用需匹配此格式。
-- 手机、推送令牌未填；重点关注内容为演示AES-GCM密文，实际部署需用应用密钥重新生成。
-- 文件表仅提供对象存储元数据，不附带实际存储对象；MOCK_PAY不代表真实支付。
-- 检查约束与外键语法参考：https://dev.mysql.com/doc/refman/8.0/en/create-table-check-constraints.html
-- https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html

SET NAMES utf8mb4;
SET @zhixiaotong_old_fk_checks = @@SESSION.FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. 用户表 (user)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID；自增长类型',
    `user_name` VARCHAR(64) NOT NULL COMMENT '账号',
    `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希；强哈希；不保存明文',
    `real_name` VARCHAR(32) NOT NULL COMMENT '姓名',
    `user_no` VARCHAR(32) DEFAULT NULL COMMENT '学工号；学生学号或教工号',
    `gender` TINYINT NOT NULL DEFAULT 0 COMMENT '性别；0未知；1男；2女',
    `phone` VARCHAR(128) DEFAULT NULL COMMENT '手机号；敏感信息加密保存',
    `email` VARCHAR(128) DEFAULT NULL COMMENT '邮箱',
    `org_id` BIGINT NOT NULL COMMENT '组织ID；org_unit(id)；查询索引',
    `class_id` BIGINT DEFAULT NULL COMMENT '班级ID；school_class(id)；学生必填；查询索引',
    `avatar_id` BIGINT DEFAULT NULL COMMENT '头像ID；file_upload(id)',
    `user_status` TINYINT NOT NULL DEFAULT 1 COMMENT '账号状态；0停用；1正常；2注销',
    `failed_count` INT NOT NULL DEFAULT 0 COMMENT '失败次数',
    `lock_until` DATETIME DEFAULT NULL COMMENT '锁定截止',
    `token_version` INT NOT NULL DEFAULT 0 COMMENT '令牌版本；修改密码或撤销时递增',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_user_name` (`user_name`),
    UNIQUE KEY `uk_user_user_no` (`user_no`),
    KEY `idx_user_org_id` (`org_id`),
    KEY `idx_user_class_id` (`class_id`),
    KEY `fk_user_avatar_id` (`avatar_id`),
    CONSTRAINT `ck_user_01` CHECK (`gender` IN (0,1,2)),
    CONSTRAINT `ck_user_02` CHECK (`user_status` IN (0,1,2)),
    CONSTRAINT `ck_user_03` CHECK (`failed_count` >= 0),
    CONSTRAINT `ck_user_04` CHECK (`token_version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 插入5条用户数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `user` (`id`, `user_name`, `password_hash`, `real_name`, `user_no`, `gender`, `phone`, `email`, `org_id`, `class_id`, `avatar_id`, `user_status`, `failed_count`, `lock_until`, `token_version`, `create_time`, `update_time`) VALUES
(1, 'student_demo', '$pbkdf2-sha256$600000$ul00CadQ8N1h068tVBp82g==$lgR4h4rCNdZH2FbAvFck9whEodKzclMY7WYk52a3ccM=', '林晨', '2023010101', 1, NULL, 'student_demo@example.com', 4, 1, NULL, 1, 0, NULL, 0, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'teacher_demo', '$pbkdf2-sha256$600000$xQFpo9PkJWdqSRyZZwtTZw==$ZNXKvLbcXkCAgTkohw1ZcwUF825TTDiLFDWTZhwYB6o=', '周敏', 'T2023001', 2, NULL, 'teacher_demo@example.com', 2, NULL, NULL, 1, 0, NULL, 0, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'counselor_demo', '$pbkdf2-sha256$600000$kjzm62V1TACfLsrOXwS+Xg==$GjX0ocijbRhpgcsIe8GPF4s+Ttqhw+7kYGdqnoj7B8g=', '陈晓', 'C2023001', 2, NULL, 'counselor_demo@example.com', 2, NULL, NULL, 1, 0, NULL, 0, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'admin_demo', '$pbkdf2-sha256$600000$uiVvmpdGa8Gu7xO2R5vhUA==$T2UTvcrfJ+054X1KtJyk+egnmKYD5jjVy84IBMhJROY=', '演示管理员', 'A2023001', 0, NULL, 'admin_demo@example.com', 1, NULL, NULL, 1, 0, NULL, 0, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'secretary_demo', '$pbkdf2-sha256$600000$rADQepg/rWDLMdncnapQ8w==$r5wLLmuGFdfJpS3KDiC3vxiqQv3ZHkubrb4lsBi4xHo=', '林博', 'J2023001', 1, NULL, 'secretary_demo@example.com', 2, NULL, NULL, 1, 0, NULL, 0, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 2. 组织机构表 (org_unit)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `org_unit`;
CREATE TABLE `org_unit` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '组织ID；自增长类型',
    `parent_id` BIGINT DEFAULT NULL COMMENT '父组织ID；org_unit(id)；根节点为空；禁止环路；查询索引',
    `org_code` VARCHAR(32) NOT NULL COMMENT '组织编码',
    `org_name` VARCHAR(64) NOT NULL COMMENT '组织名称',
    `org_type` TINYINT NOT NULL DEFAULT 1 COMMENT '组织类型；1学校；2院系；3专业；4年级',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序值',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_org_unit_org_code` (`org_code`),
    KEY `idx_org_unit_parent_id` (`parent_id`),
    CONSTRAINT `ck_org_unit_01` CHECK (`org_type` IN (1,2,3,4)),
    CONSTRAINT `ck_org_unit_02` CHECK (`is_enabled` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='组织机构表';

-- 插入5条组织机构数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `org_unit` (`id`, `parent_id`, `org_code`, `org_name`, `org_type`, `sort_order`, `is_enabled`, `create_time`, `update_time`) VALUES
(1, NULL, 'DEMO_SCHOOL', '演示职业技术学院', 1, 0, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 1, 'COMPUTER', '计算机学院', 2, 0, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 2, 'SOFTWARE', '软件技术专业', 3, 0, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 3, 'GRADE_2023', '软件技术2023级', 4, 0, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 3, 'GRADE_2024', '软件技术2024级', 4, 0, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 3. 班级表 (school_class)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `school_class`;
CREATE TABLE `school_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '班级ID；自增长类型',
    `class_code` VARCHAR(32) NOT NULL COMMENT '班级编码',
    `class_name` VARCHAR(64) NOT NULL COMMENT '班级名称',
    `grade_id` BIGINT NOT NULL COMMENT '年级ID；org_unit(id)；仅关联年级节点；查询索引',
    `entry_year` SMALLINT NOT NULL COMMENT '入学年份',
    `school_years` TINYINT NOT NULL DEFAULT 3 COMMENT '学制年数',
    `class_status` TINYINT NOT NULL DEFAULT 1 COMMENT '班级状态；0停用；1在读；2毕业',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_school_class_class_code` (`class_code`),
    KEY `idx_school_class_grade_id` (`grade_id`),
    CONSTRAINT `ck_school_class_01` CHECK (`class_status` IN (0,1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='班级表';

-- 插入5条班级数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `school_class` (`id`, `class_code`, `class_name`, `grade_id`, `entry_year`, `school_years`, `class_status`, `create_time`, `update_time`) VALUES
(1, 'SOFT_2023_01', '软件技术2023级1班', 4, 2023, 3, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'SOFT_2023_02', '软件技术2023级2班', 4, 2023, 3, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'SOFT_2023_03', '软件技术2023级3班', 4, 2023, 3, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'SOFT_2024_04', '软件技术2024级4班', 5, 2024, 3, 1, '2024-08-01 09:00:00', '2024-08-01 09:00:00'),
(5, 'SOFT_2024_05', '软件技术2024级5班', 5, 2024, 3, 1, '2024-08-01 09:00:00', '2024-08-01 09:00:00');

-- ------------------------------------------------------------
-- 4. 角色表 (role)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色ID；自增长类型',
    `role_code` VARCHAR(32) NOT NULL COMMENT '角色编码',
    `role_name` VARCHAR(32) NOT NULL COMMENT '角色名称',
    `scope_type` TINYINT NOT NULL DEFAULT 1 COMMENT '数据范围；1本人；2授课；3所辖；4自定义；5全校',
    `description` VARCHAR(255) DEFAULT NULL COMMENT '角色说明',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_role_code` (`role_code`),
    CONSTRAINT `ck_role_01` CHECK (`scope_type` IN (1,2,3,4,5)),
    CONSTRAINT `ck_role_02` CHECK (`is_enabled` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- 插入5条角色数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `role` (`id`, `role_code`, `role_name`, `scope_type`, `description`, `is_enabled`, `create_time`, `update_time`) VALUES
(1, 'STUDENT', '学生', 1, '学生演示角色', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'TEACHER', '教师', 2, '教师演示角色', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'COUNSELOR', '辅导员', 3, '辅导员演示角色', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'ADMIN', '系统管理员', 5, '系统管理员演示角色', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'ACADEMIC_SECRETARY', '教学秘书', 4, '教学秘书演示角色', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 5. 权限表 (permission)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `permission`;
CREATE TABLE `permission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '权限ID；自增长类型',
    `parent_id` BIGINT DEFAULT NULL COMMENT '父权限ID；permission(id)',
    `permission_code` VARCHAR(64) NOT NULL COMMENT '权限编码',
    `permission_name` VARCHAR(64) NOT NULL COMMENT '权限名称',
    `permission_type` TINYINT NOT NULL DEFAULT 1 COMMENT '权限类型；1菜单；2按钮；3接口',
    `resource_path` VARCHAR(255) DEFAULT NULL COMMENT '资源路径',
    `http_method` VARCHAR(16) DEFAULT NULL COMMENT '请求方法',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_permission_permission_code` (`permission_code`),
    KEY `fk_permission_parent_id` (`parent_id`),
    CONSTRAINT `ck_permission_01` CHECK (`permission_type` IN (1,2,3)),
    CONSTRAINT `ck_permission_02` CHECK (`is_enabled` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限表';

-- 插入5条权限数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `permission` (`id`, `parent_id`, `permission_code`, `permission_name`, `permission_type`, `resource_path`, `http_method`, `is_enabled`, `create_time`, `update_time`) VALUES
(1, NULL, 'student:portal', '学生服务入口', 1, '/student', NULL, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, NULL, 'teaching:manage', '教学管理入口', 1, '/teaching', NULL, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, NULL, 'student:affairs', '学生事务入口', 1, '/affairs', NULL, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, NULL, 'system:manage', '系统管理入口', 1, '/system', NULL, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, NULL, 'grade:review', '成绩审核入口', 1, '/grade-review', NULL, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 6. 用户角色关联表 (user_role)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `user_id` BIGINT NOT NULL COMMENT '用户ID；user(id)',
    `role_id` BIGINT NOT NULL COMMENT '角色ID；role(id)；与用户ID联合唯一',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role_user_id_role_id` (`user_id`, `role_id`),
    KEY `fk_user_role_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色关联表';

-- 插入5条用户角色关联数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `user_role` (`id`, `user_id`, `role_id`, `create_time`) VALUES
(1, 1, 1, '2023-08-01 09:00:00'),
(2, 2, 2, '2023-08-01 09:00:00'),
(3, 3, 3, '2023-08-01 09:00:00'),
(4, 4, 4, '2023-08-01 09:00:00'),
(5, 5, 5, '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 7. 角色权限关联表 (role_permission)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `role_permission`;
CREATE TABLE `role_permission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `role_id` BIGINT NOT NULL COMMENT '角色ID；role(id)',
    `permission_id` BIGINT NOT NULL COMMENT '权限ID；permission(id)；与角色ID联合唯一',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_permission_role_id_permission_id` (`role_id`, `permission_id`),
    KEY `fk_role_permission_permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';

-- 插入5条角色权限关联数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `role_permission` (`id`, `role_id`, `permission_id`, `create_time`) VALUES
(1, 1, 1, '2023-08-01 09:00:00'),
(2, 2, 2, '2023-08-01 09:00:00'),
(3, 3, 3, '2023-08-01 09:00:00'),
(4, 4, 4, '2023-08-01 09:00:00'),
(5, 5, 5, '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 8. 用户数据范围表 (user_scope)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `user_scope`;
CREATE TABLE `user_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '范围ID；自增长类型',
    `user_role_id` BIGINT NOT NULL COMMENT '授权ID；user_role(id)',
    `org_id` BIGINT DEFAULT NULL COMMENT '组织ID；org_unit(id)；与授权ID联合唯一',
    `class_id` BIGINT DEFAULT NULL COMMENT '班级ID；school_class(id)；与组织ID恰一非空；与授权ID联合唯一',
    `include_children` TINYINT NOT NULL DEFAULT 1 COMMENT '包含下级；0否；1是；仅组织范围有效',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_scope_user_role_id_org_id` (`user_role_id`, `org_id`),
    UNIQUE KEY `uk_user_scope_user_role_id_class_id` (`user_role_id`, `class_id`),
    KEY `fk_user_scope_org_id` (`org_id`),
    KEY `fk_user_scope_class_id` (`class_id`),
    CONSTRAINT `ck_user_scope_01` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_user_scope_02` CHECK ((`org_id` IS NOT NULL AND `class_id` IS NULL) OR (`org_id` IS NULL AND `class_id` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户数据范围表';

-- 插入5条用户数据范围数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `user_scope` (`id`, `user_role_id`, `org_id`, `class_id`, `include_children`, `create_time`) VALUES
(1, 5, NULL, 1, 0, '2023-08-01 09:00:00'),
(2, 5, NULL, 2, 0, '2023-08-01 09:00:00'),
(3, 5, NULL, 3, 0, '2023-08-01 09:00:00'),
(4, 5, NULL, 4, 0, '2024-08-01 09:00:00'),
(5, 5, NULL, 5, 0, '2024-08-01 09:00:00');

-- ------------------------------------------------------------
-- 9. 辅导员班级关联表 (counselor_class)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `counselor_class`;
CREATE TABLE `counselor_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `counselor_id` BIGINT NOT NULL COMMENT '辅导员ID；user(id)',
    `class_id` BIGINT NOT NULL COMMENT '班级ID；school_class(id)',
    `start_time` DATETIME NOT NULL COMMENT '生效时间；与辅导员ID、班级ID联合唯一',
    `end_time` DATETIME DEFAULT NULL COMMENT '失效时间；须晚于生效时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_counselor_class_counselor_id_class_id_start_time` (`counselor_id`, `class_id`, `start_time`),
    KEY `fk_counselor_class_class_id` (`class_id`),
    CONSTRAINT `ck_counselor_class_01` CHECK (`end_time` IS NULL OR `end_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='辅导员班级关联表';

-- 插入5条辅导员班级关联数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `counselor_class` (`id`, `counselor_id`, `class_id`, `start_time`, `end_time`, `create_time`, `update_time`) VALUES
(1, 3, 1, '2023-08-01 09:00:00', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 3, 2, '2023-08-01 09:00:00', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 3, 3, '2023-08-01 09:00:00', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 3, 4, '2024-08-01 09:00:00', NULL, '2024-08-01 09:00:00', '2024-08-01 09:00:00'),
(5, 3, 5, '2024-08-01 09:00:00', NULL, '2024-08-01 09:00:00', '2024-08-01 09:00:00');

-- ------------------------------------------------------------
-- 10. 学期表 (semester)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `semester`;
CREATE TABLE `semester` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '学期ID；自增长类型',
    `semester_code` VARCHAR(32) NOT NULL COMMENT '学期编码',
    `semester_name` VARCHAR(64) NOT NULL COMMENT '学期名称',
    `start_date` DATE NOT NULL COMMENT '开始日期',
    `end_date` DATE NOT NULL COMMENT '结束日期；不早于开始日期',
    `week_count` TINYINT NOT NULL COMMENT '教学周数；正整数',
    `is_current` TINYINT NOT NULL DEFAULT 0 COMMENT '当前学期；0否；1是；仅一条为1',
    `is_locked` TINYINT NOT NULL DEFAULT 0 COMMENT '锁定状态；0未锁；1锁定',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_semester_semester_code` (`semester_code`),
    CONSTRAINT `ck_semester_01` CHECK (`is_current` IN (0,1)),
    CONSTRAINT `ck_semester_02` CHECK (`is_locked` IN (0,1)),
    CONSTRAINT `ck_semester_03` CHECK (`end_date` >= `start_date`),
    CONSTRAINT `ck_semester_04` CHECK (`week_count` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学期表';

-- 插入5条学期数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `semester` (`id`, `semester_code`, `semester_name`, `start_date`, `end_date`, `week_count`, `is_current`, `is_locked`, `create_time`, `update_time`) VALUES
(1, '2023_2024_1', '2023—2024学年第一学期', '2023-09-04', '2024-01-21', 20, 0, 1, '2023-08-21 09:00:00', '2024-01-16 16:00:00'),
(2, '2023_2024_2', '2023—2024学年第二学期', '2024-02-26', '2024-07-14', 20, 0, 1, '2024-02-12 09:00:00', '2024-07-09 16:00:00'),
(3, '2024_2025_1', '2024—2025学年第一学期', '2024-09-02', '2025-01-19', 20, 0, 1, '2024-08-19 09:00:00', '2025-01-14 16:00:00'),
(4, '2024_2025_2', '2024—2025学年第二学期', '2025-02-24', '2025-07-13', 20, 0, 1, '2025-02-10 09:00:00', '2025-07-08 16:00:00'),
(5, '2025_2026_1', '2025—2026学年第一学期', '2025-09-01', '2026-01-18', 20, 1, 0, '2025-08-18 09:00:00', '2026-01-13 16:00:00');

-- ------------------------------------------------------------
-- 11. 课程表 (course)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `course`;
CREATE TABLE `course` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '课程ID；自增长类型',
    `course_code` VARCHAR(32) NOT NULL COMMENT '课程编码',
    `course_name` VARCHAR(128) NOT NULL COMMENT '课程名称',
    `org_id` BIGINT NOT NULL COMMENT '开课组织ID；org_unit(id)；组合查询索引',
    `course_type` VARCHAR(32) NOT NULL COMMENT '课程类别；关联课程类别字典',
    `credit` DECIMAL(4,1) NOT NULL COMMENT '学分；大于等于0',
    `total_hours` INT NOT NULL COMMENT '总学时；正整数',
    `syllabus` TEXT DEFAULT NULL COMMENT '课程大纲',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_course_course_code` (`course_code`),
    KEY `idx_course_org_id_course_type` (`org_id`, `course_type`),
    CONSTRAINT `ck_course_01` CHECK (`is_enabled` IN (0,1)),
    CONSTRAINT `ck_course_02` CHECK (`credit` >= 0),
    CONSTRAINT `ck_course_03` CHECK (`total_hours` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程表';

-- 插入5条课程数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `course` (`id`, `course_code`, `course_name`, `org_id`, `course_type`, `credit`, `total_hours`, `syllabus`, `is_enabled`, `create_time`, `update_time`) VALUES
(1, 'CS001', '程序设计基础', 2, 'PROFESSIONAL_REQUIRED', 3.0, 60, '程序设计基础：基础知识、课堂练习、项目实践与综合考核。', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'CS002', '面向对象程序设计', 2, 'PROFESSIONAL_REQUIRED', 3.0, 60, '面向对象程序设计：基础知识、课堂练习、项目实践与综合考核。', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'CS003', '数据结构', 2, 'PROFESSIONAL_REQUIRED', 3.0, 60, '数据结构：基础知识、课堂练习、项目实践与综合考核。', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'CS004', '数据库应用开发', 2, 'PROFESSIONAL_REQUIRED', 3.0, 60, '数据库应用开发：基础知识、课堂练习、项目实践与综合考核。', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'CS005', '综合项目实训', 2, 'PROFESSIONAL_REQUIRED', 3.0, 60, '综合项目实训：基础知识、课堂练习、项目实践与综合考核。', 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 12. 课程先修条件表 (course_prereq)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `course_prereq`;
CREATE TABLE `course_prereq` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '条件ID；自增长类型',
    `course_id` BIGINT NOT NULL COMMENT '课程ID；course(id)',
    `prereq_id` BIGINT NOT NULL COMMENT '先修课程ID；course(id)；禁止自指及循环依赖；与课程ID联合唯一',
    `min_score` DECIMAL(5,2) NOT NULL DEFAULT 60 COMMENT '最低成绩；取已发布成绩；范围0至100',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_course_prereq_course_id_prereq_id` (`course_id`, `prereq_id`),
    KEY `fk_course_prereq_prereq_id` (`prereq_id`),
    CONSTRAINT `ck_course_prereq_01` CHECK (`course_id` <> `prereq_id`),
    CONSTRAINT `ck_course_prereq_02` CHECK (`min_score` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程先修条件表';

-- 插入5条课程先修条件数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `course_prereq` (`id`, `course_id`, `prereq_id`, `min_score`, `create_time`, `update_time`) VALUES
(1, 2, 1, 60, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 3, 1, 60, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 4, 2, 60, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 4, 3, 60, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 5, 4, 60, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 13. 教室表 (classroom)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `classroom`;
CREATE TABLE `classroom` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '教室ID；自增长类型',
    `room_code` VARCHAR(32) NOT NULL COMMENT '教室编码',
    `room_name` VARCHAR(64) NOT NULL COMMENT '教室名称',
    `campus_name` VARCHAR(64) NOT NULL COMMENT '所在校区',
    `building_name` VARCHAR(64) NOT NULL COMMENT '教学楼',
    `capacity` INT NOT NULL COMMENT '容纳人数；大于0',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_classroom_room_code` (`room_code`),
    CONSTRAINT `ck_classroom_01` CHECK (`is_enabled` IN (0,1)),
    CONSTRAINT `ck_classroom_02` CHECK (`capacity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='教室表';

-- 插入5条教室数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `classroom` (`id`, `room_code`, `room_name`, `campus_name`, `building_name`, `capacity`, `is_enabled`, `create_time`, `update_time`) VALUES
(1, 'A101', '信息楼101教室', '主校区', '信息楼', 60, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'A102', '信息楼102教室', '主校区', '信息楼', 60, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'A103', '信息楼103教室', '主校区', '信息楼', 60, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'A104', '信息楼104教室', '主校区', '信息楼', 60, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'A105', '信息楼105教室', '主校区', '信息楼', 60, 1, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 14. 教学班表 (teaching_class)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `teaching_class`;
CREATE TABLE `teaching_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '教学班ID；自增长类型',
    `class_code` VARCHAR(32) NOT NULL COMMENT '教学班编码',
    `course_id` BIGINT NOT NULL COMMENT '课程ID；course(id)',
    `semester_id` BIGINT NOT NULL COMMENT '学期ID；semester(id)；组合查询索引',
    `teacher_id` BIGINT NOT NULL COMMENT '教师ID；user(id)',
    `class_name` VARCHAR(64) NOT NULL COMMENT '教学班名称',
    `capacity` INT NOT NULL COMMENT '容量；大于0',
    `enrolled_count` INT NOT NULL DEFAULT 0 COMMENT '已选人数；仅成功选课计数；原子更新',
    `usual_weight` DECIMAL(5,4) NOT NULL DEFAULT 0.4000 COMMENT '平时权重；0至1',
    `final_weight` DECIMAL(5,4) NOT NULL DEFAULT 0.6000 COMMENT '期末权重；两项权重之和为1',
    `version` INT NOT NULL DEFAULT 0 COMMENT '版本号；容量更新并发控制',
    `class_status` TINYINT NOT NULL DEFAULT 1 COMMENT '教学班状态；0未开；1开放；2结课',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_teaching_class_class_code` (`class_code`),
    KEY `idx_teaching_class_semester_id_teacher_id` (`semester_id`, `teacher_id`),
    KEY `fk_teaching_class_course_id` (`course_id`),
    KEY `fk_teaching_class_teacher_id` (`teacher_id`),
    CONSTRAINT `ck_teaching_class_01` CHECK (`class_status` IN (0,1,2)),
    CONSTRAINT `ck_teaching_class_02` CHECK (`capacity` > 0),
    CONSTRAINT `ck_teaching_class_03` CHECK (`enrolled_count` BETWEEN 0 AND `capacity`),
    CONSTRAINT `ck_teaching_class_04` CHECK (`usual_weight` BETWEEN 0 AND 1),
    CONSTRAINT `ck_teaching_class_05` CHECK (`final_weight` BETWEEN 0 AND 1),
    CONSTRAINT `ck_teaching_class_06` CHECK (`usual_weight` + `final_weight` = 1),
    CONSTRAINT `ck_teaching_class_07` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='教学班表';

-- 插入5条教学班数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `teaching_class` (`id`, `class_code`, `course_id`, `semester_id`, `teacher_id`, `class_name`, `capacity`, `enrolled_count`, `usual_weight`, `final_weight`, `version`, `class_status`, `create_time`, `update_time`) VALUES
(1, 'TC_2023_2024_1_01', 1, 1, 2, '程序设计基础教学一班', 40, 1, 0.4000, 0.6000, 1, 2, '2023-08-21 09:00:00', '2024-01-16 16:00:00'),
(2, 'TC_2023_2024_2_02', 2, 2, 2, '面向对象程序设计教学一班', 40, 1, 0.4000, 0.6000, 1, 2, '2024-02-12 09:00:00', '2024-07-09 16:00:00'),
(3, 'TC_2024_2025_1_03', 3, 3, 2, '数据结构教学一班', 40, 1, 0.4000, 0.6000, 1, 2, '2024-08-19 09:00:00', '2025-01-14 16:00:00'),
(4, 'TC_2024_2025_2_04', 4, 4, 2, '数据库应用开发教学一班', 40, 1, 0.4000, 0.6000, 1, 2, '2025-02-10 09:00:00', '2025-07-08 16:00:00'),
(5, 'TC_2025_2026_1_05', 5, 5, 2, '综合项目实训教学一班', 40, 1, 0.4000, 0.6000, 1, 2, '2025-08-18 09:00:00', '2026-01-13 16:00:00');

-- ------------------------------------------------------------
-- 15. 课表信息表 (timetable)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `timetable`;
CREATE TABLE `timetable` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '课表ID；自增长类型',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；查询索引',
    `classroom_id` BIGINT NOT NULL COMMENT '教室ID；classroom(id)；组合查询索引',
    `start_week` TINYINT NOT NULL COMMENT '开始周；从1开始',
    `end_week` TINYINT NOT NULL COMMENT '结束周',
    `week_mode` TINYINT NOT NULL DEFAULT 1 COMMENT '周次模式；1每周；2单周；3双周',
    `week_day` TINYINT NOT NULL COMMENT '星期；1至7对应周一至周日',
    `start_period` TINYINT NOT NULL COMMENT '起始节次',
    `end_period` TINYINT NOT NULL COMMENT '结束节次',
    `start_time` TIME NOT NULL COMMENT '上课时间',
    `end_time` TIME NOT NULL COMMENT '下课时间；需校验学生、教师及教室冲突',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_timetable_teaching_class_id` (`teaching_class_id`),
    KEY `idx_timetable_classroom_id_week_day` (`classroom_id`, `week_day`),
    CONSTRAINT `ck_timetable_01` CHECK (`week_mode` IN (1,2,3)),
    CONSTRAINT `ck_timetable_02` CHECK (`start_week` >= 1 AND `end_week` >= `start_week`),
    CONSTRAINT `ck_timetable_03` CHECK (`week_day` BETWEEN 1 AND 7),
    CONSTRAINT `ck_timetable_04` CHECK (`start_period` >= 1 AND `end_period` >= `start_period`),
    CONSTRAINT `ck_timetable_05` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课表信息表';

-- 插入5条课表信息数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `timetable` (`id`, `teaching_class_id`, `classroom_id`, `start_week`, `end_week`, `week_mode`, `week_day`, `start_period`, `end_period`, `start_time`, `end_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, 19, 1, 1, 1, 2, '08:00:00', '09:40:00', '2023-08-21 09:00:00', '2023-08-21 09:00:00'),
(2, 2, 2, 1, 19, 1, 1, 1, 2, '08:00:00', '09:40:00', '2024-02-12 09:00:00', '2024-02-12 09:00:00'),
(3, 3, 3, 1, 19, 1, 1, 1, 2, '08:00:00', '09:40:00', '2024-08-19 09:00:00', '2024-08-19 09:00:00'),
(4, 4, 4, 1, 19, 1, 1, 1, 2, '08:00:00', '09:40:00', '2025-02-10 09:00:00', '2025-02-10 09:00:00'),
(5, 5, 5, 1, 19, 1, 1, 1, 2, '08:00:00', '09:40:00', '2025-08-18 09:00:00', '2025-08-18 09:00:00');

-- ------------------------------------------------------------
-- 16. 选课批次表 (selection_batch)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `selection_batch`;
CREATE TABLE `selection_batch` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '批次ID；自增长类型',
    `batch_code` VARCHAR(32) NOT NULL COMMENT '批次编码',
    `batch_name` VARCHAR(64) NOT NULL COMMENT '批次名称',
    `semester_id` BIGINT NOT NULL COMMENT '学期ID；semester(id)；查询索引',
    `batch_stage` TINYINT NOT NULL DEFAULT 1 COMMENT '批次阶段；1预选；2正选；3补退选',
    `start_time` DATETIME NOT NULL COMMENT '开放时间',
    `end_time` DATETIME NOT NULL COMMENT '结束时间',
    `drop_deadline` DATETIME DEFAULT NULL COMMENT '退选截止',
    `max_courses` INT NOT NULL DEFAULT 0 COMMENT '限选门数；0表示不限制',
    `max_credits` DECIMAL(5,1) NOT NULL DEFAULT 0 COMMENT '限选学分；0表示不限制',
    `announcement` TEXT DEFAULT NULL COMMENT '选课公告',
    `batch_status` TINYINT NOT NULL DEFAULT 0 COMMENT '批次状态；0未开；1开放；2结束；3锁定',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_selection_batch_batch_code` (`batch_code`),
    KEY `idx_selection_batch_semester_id` (`semester_id`),
    CONSTRAINT `ck_selection_batch_01` CHECK (`batch_stage` IN (1,2,3)),
    CONSTRAINT `ck_selection_batch_02` CHECK (`batch_status` IN (0,1,2,3)),
    CONSTRAINT `ck_selection_batch_03` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_selection_batch_04` CHECK (`max_courses` >= 0),
    CONSTRAINT `ck_selection_batch_05` CHECK (`max_credits` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='选课批次表';

-- 插入5条选课批次数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `selection_batch` (`id`, `batch_code`, `batch_name`, `semester_id`, `batch_stage`, `start_time`, `end_time`, `drop_deadline`, `max_courses`, `max_credits`, `announcement`, `batch_status`, `create_time`, `update_time`) VALUES
(1, 'SEL_2023_2024_1', '2023—2024学年第一学期正选', 1, 2, '2023-08-28 09:00:00', '2023-09-03 18:00:00', '2023-09-10 18:00:00', 6, 24.0, '请核对先修课程和上课时间，在开放时间内完成选课。', 2, '2023-08-21 09:00:00', '2023-09-04 09:00:00'),
(2, 'SEL_2023_2024_2', '2023—2024学年第二学期正选', 2, 2, '2024-02-19 09:00:00', '2024-02-25 18:00:00', '2024-03-03 18:00:00', 6, 24.0, '请核对先修课程和上课时间，在开放时间内完成选课。', 2, '2024-02-12 09:00:00', '2024-02-26 09:00:00'),
(3, 'SEL_2024_2025_1', '2024—2025学年第一学期正选', 3, 2, '2024-08-26 09:00:00', '2024-09-01 18:00:00', '2024-09-08 18:00:00', 6, 24.0, '请核对先修课程和上课时间，在开放时间内完成选课。', 2, '2024-08-19 09:00:00', '2024-09-02 09:00:00'),
(4, 'SEL_2024_2025_2', '2024—2025学年第二学期正选', 4, 2, '2025-02-17 09:00:00', '2025-02-23 18:00:00', '2025-03-02 18:00:00', 6, 24.0, '请核对先修课程和上课时间，在开放时间内完成选课。', 2, '2025-02-10 09:00:00', '2025-02-24 09:00:00'),
(5, 'SEL_2025_2026_1', '2025—2026学年第一学期正选', 5, 2, '2025-08-25 09:00:00', '2025-08-31 18:00:00', '2025-09-07 18:00:00', 6, 24.0, '请核对先修课程和上课时间，在开放时间内完成选课。', 2, '2025-08-18 09:00:00', '2025-09-01 09:00:00');

-- ------------------------------------------------------------
-- 17. 批次课程关联表 (batch_course)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `batch_course`;
CREATE TABLE `batch_course` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `batch_id` BIGINT NOT NULL COMMENT '批次ID；selection_batch(id)',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；与批次ID联合唯一',
    `admission_type` TINYINT NOT NULL DEFAULT 1 COMMENT '录取方式；1先到先得；2抽签；3优先级',
    `priority_rule` JSON DEFAULT NULL COMMENT '优先级规则；方式3必填；保存规则及版本',
    `process_status` TINYINT NOT NULL DEFAULT 0 COMMENT '处理状态；0未处理；1处理中；2完成',
    `process_time` DATETIME DEFAULT NULL COMMENT '处理时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_batch_course_batch_id_teaching_class_id` (`batch_id`, `teaching_class_id`),
    KEY `fk_batch_course_teaching_class_id` (`teaching_class_id`),
    CONSTRAINT `ck_batch_course_01` CHECK (`admission_type` IN (1,2,3)),
    CONSTRAINT `ck_batch_course_02` CHECK (`process_status` IN (0,1,2)),
    CONSTRAINT `ck_batch_course_03` CHECK (`admission_type` <> 3 OR `priority_rule` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='批次课程关联表';

-- 插入5条批次课程关联数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `batch_course` (`id`, `batch_id`, `teaching_class_id`, `admission_type`, `priority_rule`, `process_status`, `process_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, NULL, 2, '2023-08-28 09:05:00', '2023-08-21 09:00:00', '2023-08-28 09:05:00'),
(2, 2, 2, 1, NULL, 2, '2024-02-19 09:05:00', '2024-02-12 09:00:00', '2024-02-19 09:05:00'),
(3, 3, 3, 1, NULL, 2, '2024-08-26 09:05:00', '2024-08-19 09:00:00', '2024-08-26 09:05:00'),
(4, 4, 4, 1, NULL, 2, '2025-02-17 09:05:00', '2025-02-10 09:00:00', '2025-02-17 09:05:00'),
(5, 5, 5, 1, NULL, 2, '2025-08-25 09:05:00', '2025-08-18 09:00:00', '2025-08-25 09:05:00');

-- ------------------------------------------------------------
-- 18. 选课开放范围表 (selection_scope)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `selection_scope`;
CREATE TABLE `selection_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '范围ID；自增长类型',
    `batch_course_id` BIGINT NOT NULL COMMENT '批次课程ID；batch_course(id)',
    `org_id` BIGINT DEFAULT NULL COMMENT '组织ID；org_unit(id)；与批次课程ID联合唯一',
    `class_id` BIGINT DEFAULT NULL COMMENT '班级ID；school_class(id)；与组织ID恰一非空；与批次课程ID联合唯一',
    `include_children` TINYINT NOT NULL DEFAULT 1 COMMENT '包含下级；0否；1是；无范围记录不开放',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_selection_scope_batch_course_id_org_id` (`batch_course_id`, `org_id`),
    UNIQUE KEY `uk_selection_scope_batch_course_id_class_id` (`batch_course_id`, `class_id`),
    KEY `fk_selection_scope_org_id` (`org_id`),
    KEY `fk_selection_scope_class_id` (`class_id`),
    CONSTRAINT `ck_selection_scope_01` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_selection_scope_02` CHECK ((`org_id` IS NOT NULL AND `class_id` IS NULL) OR (`org_id` IS NULL AND `class_id` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='选课开放范围表';

-- 插入5条选课开放范围数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `selection_scope` (`id`, `batch_course_id`, `org_id`, `class_id`, `include_children`, `create_time`) VALUES
(1, 1, 3, NULL, 1, '2023-08-21 09:00:00'),
(2, 2, 3, NULL, 1, '2024-02-12 09:00:00'),
(3, 3, 3, NULL, 1, '2024-08-19 09:00:00'),
(4, 4, 3, NULL, 1, '2025-02-10 09:00:00'),
(5, 5, 3, NULL, 1, '2025-08-18 09:00:00');

-- ------------------------------------------------------------
-- 19. 选课记录表 (enrollment)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `enrollment`;
CREATE TABLE `enrollment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '选课ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；锁定学生行校验同学期重复课程及时间冲突',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；与学生ID联合唯一；组合查询索引',
    `batch_course_id` BIGINT DEFAULT NULL COMMENT '批次课程ID；batch_course(id)；必修导入可空；教学班须一致',
    `request_key` VARCHAR(64) NOT NULL COMMENT '幂等键',
    `enroll_status` TINYINT NOT NULL DEFAULT 0 COMMENT '选课状态；0待筛选；1成功；2未录取；3已退',
    `selection_rank` INT DEFAULT NULL COMMENT '筛选顺序；保存抽签或优先级排序',
    `enroll_time` DATETIME NOT NULL COMMENT '选课时间',
    `drop_time` DATETIME DEFAULT NULL COMMENT '退选时间',
    `result_note` VARCHAR(255) DEFAULT NULL COMMENT '处理说明；仅成功占容量；退选原子释放',
    `version` INT NOT NULL DEFAULT 0 COMMENT '版本号；重选更新原记录；历史写审计',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_enrollment_student_id_teaching_class_id` (`student_id`, `teaching_class_id`),
    UNIQUE KEY `uk_enrollment_request_key` (`request_key`),
    KEY `idx_enrollment_teaching_class_id_enroll_status` (`teaching_class_id`, `enroll_status`),
    KEY `fk_enrollment_batch_course_id` (`batch_course_id`),
    CONSTRAINT `ck_enrollment_01` CHECK (`enroll_status` IN (0,1,2,3))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='选课记录表';

-- 插入5条选课记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `enrollment` (`id`, `student_id`, `teaching_class_id`, `batch_course_id`, `request_key`, `enroll_status`, `selection_rank`, `enroll_time`, `drop_time`, `result_note`, `version`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, 'enroll_demo_001', 1, NULL, '2023-08-28 09:05:00', NULL, '先修条件满足，正选成功', 1, '2023-08-28 09:05:00', '2023-08-28 09:05:00'),
(2, 1, 2, 2, 'enroll_demo_002', 1, NULL, '2024-02-19 09:05:00', NULL, '先修条件满足，正选成功', 1, '2024-02-19 09:05:00', '2024-02-19 09:05:00'),
(3, 1, 3, 3, 'enroll_demo_003', 1, NULL, '2024-08-26 09:05:00', NULL, '先修条件满足，正选成功', 1, '2024-08-26 09:05:00', '2024-08-26 09:05:00'),
(4, 1, 4, 4, 'enroll_demo_004', 1, NULL, '2025-02-17 09:05:00', NULL, '先修条件满足，正选成功', 1, '2025-02-17 09:05:00', '2025-02-17 09:05:00'),
(5, 1, 5, 5, 'enroll_demo_005', 1, NULL, '2025-08-25 09:05:00', NULL, '先修条件满足，正选成功', 1, '2025-08-25 09:05:00', '2025-08-25 09:05:00');

-- ------------------------------------------------------------
-- 20. 课程资源表 (course_resource)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `course_resource`;
CREATE TABLE `course_resource` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '资源ID；自增长类型',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；查询索引',
    `resource_title` VARCHAR(128) NOT NULL COMMENT '资源标题',
    `file_id` BIGINT NOT NULL COMMENT '文件ID；file_upload(id)',
    `uploader_id` BIGINT NOT NULL COMMENT '上传人ID；user(id)',
    `visible_scope` TINYINT NOT NULL DEFAULT 1 COMMENT '可见范围；1本班学生及教师；2仅教师',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序值',
    `publish_status` TINYINT NOT NULL DEFAULT 0 COMMENT '发布状态；0草稿；1已发布',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_course_resource_teaching_class_id` (`teaching_class_id`),
    KEY `fk_course_resource_file_id` (`file_id`),
    KEY `fk_course_resource_uploader_id` (`uploader_id`),
    CONSTRAINT `ck_course_resource_01` CHECK (`visible_scope` IN (1,2)),
    CONSTRAINT `ck_course_resource_02` CHECK (`publish_status` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程资源表';

-- 插入5条课程资源数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `course_resource` (`id`, `teaching_class_id`, `resource_title`, `file_id`, `uploader_id`, `visible_scope`, `sort_order`, `publish_status`, `create_time`, `update_time`) VALUES
(1, 1, '程序设计基础教学讲义', 1, 2, 1, 0, 1, '2023-09-04 09:00:00', '2023-09-04 09:00:00'),
(2, 2, '面向对象程序设计教学讲义', 2, 2, 1, 0, 1, '2024-02-26 09:00:00', '2024-02-26 09:00:00'),
(3, 3, '数据结构教学讲义', 3, 2, 1, 0, 1, '2024-09-02 09:00:00', '2024-09-02 09:00:00'),
(4, 4, '数据库应用开发教学讲义', 4, 2, 1, 0, 1, '2025-02-24 09:00:00', '2025-02-24 09:00:00'),
(5, 5, '综合项目实训教学讲义', 5, 2, 1, 0, 1, '2025-09-01 09:00:00', '2025-09-01 09:00:00');

-- ------------------------------------------------------------
-- 21. 作业表 (assignment)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `assignment`;
CREATE TABLE `assignment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '作业ID；自增长类型',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；查询索引',
    `teacher_id` BIGINT NOT NULL COMMENT '教师ID；user(id)',
    `assignment_title` VARCHAR(128) NOT NULL COMMENT '作业标题',
    `content` TEXT NOT NULL COMMENT '作业内容',
    `grading_rule` TEXT DEFAULT NULL COMMENT '评分标准',
    `max_score` DECIMAL(6,2) NOT NULL DEFAULT 100 COMMENT '满分；大于0',
    `deadline` DATETIME NOT NULL COMMENT '截止时间',
    `allow_late` TINYINT NOT NULL DEFAULT 0 COMMENT '允许补交；0否；1是',
    `publish_status` TINYINT NOT NULL DEFAULT 0 COMMENT '发布状态；0草稿；1发布；2关闭',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_assignment_teaching_class_id` (`teaching_class_id`),
    KEY `fk_assignment_teacher_id` (`teacher_id`),
    CONSTRAINT `ck_assignment_01` CHECK (`allow_late` IN (0,1)),
    CONSTRAINT `ck_assignment_02` CHECK (`publish_status` IN (0,1,2)),
    CONSTRAINT `ck_assignment_03` CHECK (`max_score` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作业表';

-- 插入5条作业数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `assignment` (`id`, `teaching_class_id`, `teacher_id`, `assignment_title`, `content`, `grading_rule`, `max_score`, `deadline`, `allow_late`, `publish_status`, `create_time`, `update_time`) VALUES
(1, 1, 2, '程序设计基础阶段练习', '完成课堂案例，实现指定功能，并提交设计思路、运行结果和总结。', '功能正确性60分，代码规范20分，报告完整性20分。', 100, '2023-09-25 23:59:00', 0, 2, '2023-09-11 09:00:00', '2023-09-26 09:00:00'),
(2, 2, 2, '面向对象程序设计阶段练习', '完成课堂案例，实现指定功能，并提交设计思路、运行结果和总结。', '功能正确性60分，代码规范20分，报告完整性20分。', 100, '2024-03-18 23:59:00', 0, 2, '2024-03-04 09:00:00', '2024-03-19 09:00:00'),
(3, 3, 2, '数据结构阶段练习', '完成课堂案例，实现指定功能，并提交设计思路、运行结果和总结。', '功能正确性60分，代码规范20分，报告完整性20分。', 100, '2024-09-23 23:59:00', 0, 2, '2024-09-09 09:00:00', '2024-09-24 09:00:00'),
(4, 4, 2, '数据库应用开发阶段练习', '完成课堂案例，实现指定功能，并提交设计思路、运行结果和总结。', '功能正确性60分，代码规范20分，报告完整性20分。', 100, '2025-03-17 23:59:00', 0, 2, '2025-03-03 09:00:00', '2025-03-18 09:00:00'),
(5, 5, 2, '综合项目实训阶段练习', '完成课堂案例，实现指定功能，并提交设计思路、运行结果和总结。', '功能正确性60分，代码规范20分，报告完整性20分。', 100, '2025-09-22 23:59:00', 0, 2, '2025-09-08 09:00:00', '2025-09-23 09:00:00');

-- ------------------------------------------------------------
-- 22. 作业提交表 (submission)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `submission`;
CREATE TABLE `submission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '提交ID；自增长类型',
    `assignment_id` BIGINT NOT NULL COMMENT '作业ID；assignment(id)',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)',
    `submit_round` INT NOT NULL DEFAULT 1 COMMENT '提交轮次；与作业ID、学生ID联合唯一',
    `content` TEXT DEFAULT NULL COMMENT '提交内容；文本或附件至少一项',
    `submit_time` DATETIME NOT NULL COMMENT '提交时间',
    `submit_status` TINYINT NOT NULL DEFAULT 0 COMMENT '提交状态；0已提交；1退回；2已批改；3已发布',
    `score` DECIMAL(6,2) DEFAULT NULL COMMENT '得分；0至作业满分',
    `feedback` TEXT DEFAULT NULL COMMENT '批改反馈',
    `grader_id` BIGINT DEFAULT NULL COMMENT '批改人ID；user(id)',
    `grade_time` DATETIME DEFAULT NULL COMMENT '批改时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_submission_assignment_id_student_id_submit_round` (`assignment_id`, `student_id`, `submit_round`),
    KEY `fk_submission_student_id` (`student_id`),
    KEY `fk_submission_grader_id` (`grader_id`),
    CONSTRAINT `ck_submission_01` CHECK (`submit_status` IN (0,1,2,3)),
    CONSTRAINT `ck_submission_02` CHECK (`submit_round` >= 1),
    CONSTRAINT `ck_submission_03` CHECK (`score` IS NULL OR `score` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作业提交表';

-- 插入5条作业提交数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `submission` (`id`, `assignment_id`, `student_id`, `submit_round`, `content`, `submit_time`, `submit_status`, `score`, `feedback`, `grader_id`, `grade_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, '已完成程序设计基础阶段练习，测试结果通过，附文字总结。', '2023-09-24 19:30:00', 3, 81, '完成要求，继续加强边界条件测试。', 2, '2023-09-26 14:00:00', '2023-09-24 19:30:00', '2023-09-26 14:30:00'),
(2, 2, 1, 1, '已完成面向对象程序设计阶段练习，测试结果通过，附文字总结。', '2024-03-17 19:30:00', 3, 82, '完成要求，继续加强边界条件测试。', 2, '2024-03-19 14:00:00', '2024-03-17 19:30:00', '2024-03-19 14:30:00'),
(3, 3, 1, 1, '已完成数据结构阶段练习，测试结果通过，附文字总结。', '2024-09-22 19:30:00', 3, 83, '完成要求，继续加强边界条件测试。', 2, '2024-09-24 14:00:00', '2024-09-22 19:30:00', '2024-09-24 14:30:00'),
(4, 4, 1, 1, '已完成数据库应用开发阶段练习，测试结果通过，附文字总结。', '2025-03-16 19:30:00', 3, 84, '完成要求，继续加强边界条件测试。', 2, '2025-03-18 14:00:00', '2025-03-16 19:30:00', '2025-03-18 14:30:00'),
(5, 5, 1, 1, '已完成综合项目实训阶段练习，测试结果通过，附文字总结。', '2025-09-21 19:30:00', 3, 85, '完成要求，继续加强边界条件测试。', 2, '2025-09-23 14:00:00', '2025-09-21 19:30:00', '2025-09-23 14:30:00');

-- ------------------------------------------------------------
-- 23. 成绩表 (grade)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `grade`;
CREATE TABLE `grade` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '成绩ID；自增长类型',
    `enrollment_id` BIGINT NOT NULL COMMENT '选课ID；enrollment(id)',
    `review_id` BIGINT DEFAULT NULL COMMENT '审核ID；grade_review(id)；查询索引',
    `usual_score` DECIMAL(5,2) DEFAULT NULL COMMENT '平时成绩；草稿可空；范围0至100',
    `final_score` DECIMAL(5,2) DEFAULT NULL COMMENT '期末成绩；草稿或缺考可空',
    `total_score` DECIMAL(5,2) DEFAULT NULL COMMENT '总评成绩；按权重计算；范围0至100',
    `grade_point` DECIMAL(3,2) DEFAULT NULL COMMENT '绩点；按学校绩点规则计算',
    `exam_flag` TINYINT NOT NULL DEFAULT 0 COMMENT '考试标记；0正常；1缺考；2缓考；3免修',
    `grade_status` TINYINT NOT NULL DEFAULT 0 COMMENT '成绩状态；0草稿；1待审；2退回；3发布',
    `operator_id` BIGINT NOT NULL COMMENT '录入人ID；user(id)',
    `publish_time` DATETIME DEFAULT NULL COMMENT '发布时间',
    `version` INT NOT NULL DEFAULT 0 COMMENT '版本号',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_grade_enrollment_id` (`enrollment_id`),
    KEY `idx_grade_review_id` (`review_id`),
    KEY `fk_grade_operator_id` (`operator_id`),
    CONSTRAINT `ck_grade_01` CHECK (`exam_flag` IN (0,1,2,3)),
    CONSTRAINT `ck_grade_02` CHECK (`grade_status` IN (0,1,2,3)),
    CONSTRAINT `ck_grade_03` CHECK (`usual_score` IS NULL OR `usual_score` BETWEEN 0 AND 100),
    CONSTRAINT `ck_grade_04` CHECK (`final_score` IS NULL OR `final_score` BETWEEN 0 AND 100),
    CONSTRAINT `ck_grade_05` CHECK (`total_score` IS NULL OR `total_score` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成绩表';

-- 插入5条成绩数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `grade` (`id`, `enrollment_id`, `review_id`, `usual_score`, `final_score`, `total_score`, `grade_point`, `exam_flag`, `grade_status`, `operator_id`, `publish_time`, `version`, `create_time`, `update_time`) VALUES
(1, 1, 1, 81, 86, 84.0, 3.40, 0, 3, 2, '2024-01-16 16:00:00', 1, '2024-01-15 17:00:00', '2024-01-16 16:00:00'),
(2, 2, 2, 82, 87, 85.0, 3.50, 0, 3, 2, '2024-07-09 16:00:00', 1, '2024-07-08 17:00:00', '2024-07-09 16:00:00'),
(3, 3, 3, 83, 88, 86.0, 3.60, 0, 3, 2, '2025-01-14 16:00:00', 1, '2025-01-13 17:00:00', '2025-01-14 16:00:00'),
(4, 4, 4, 84, 89, 87.0, 3.70, 0, 3, 2, '2025-07-08 16:00:00', 1, '2025-07-07 17:00:00', '2025-07-08 16:00:00'),
(5, 5, 5, 85, 90, 88.0, 3.80, 0, 3, 2, '2026-01-13 16:00:00', 1, '2026-01-12 17:00:00', '2026-01-13 16:00:00');

-- ------------------------------------------------------------
-- 24. 成绩审核表 (grade_review)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `grade_review`;
CREATE TABLE `grade_review` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '审核ID；自增长类型',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)',
    `review_round` INT NOT NULL DEFAULT 1 COMMENT '审核轮次；与教学班ID联合唯一',
    `submitter_id` BIGINT NOT NULL COMMENT '提交人ID；user(id)',
    `submit_time` DATETIME NOT NULL COMMENT '提交时间',
    `grade_snapshot` JSON NOT NULL COMMENT '成绩快照；提交时各成绩ID、版本与数值',
    `warning_note` VARCHAR(255) DEFAULT NULL COMMENT '异常提示；成绩分布异常及处理说明',
    `reviewer_id` BIGINT DEFAULT NULL COMMENT '审核人ID；user(id)',
    `review_status` TINYINT NOT NULL DEFAULT 0 COMMENT '审核状态；0待审；1通过；2退回',
    `review_comment` VARCHAR(255) DEFAULT NULL COMMENT '审核意见',
    `review_time` DATETIME DEFAULT NULL COMMENT '审核时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_grade_review_teaching_class_id_review_round` (`teaching_class_id`, `review_round`),
    KEY `fk_grade_review_submitter_id` (`submitter_id`),
    KEY `fk_grade_review_reviewer_id` (`reviewer_id`),
    CONSTRAINT `ck_grade_review_01` CHECK (`review_status` IN (0,1,2)),
    CONSTRAINT `ck_grade_review_02` CHECK (`review_round` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成绩审核表';

-- 插入5条成绩审核数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `grade_review` (`id`, `teaching_class_id`, `review_round`, `submitter_id`, `submit_time`, `grade_snapshot`, `warning_note`, `reviewer_id`, `review_status`, `review_comment`, `review_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 2, '2024-01-16 09:00:00', '[{"grade_id":1,"usual_score":81.0,"final_score":86.0,"total_score":84.0,"grade_point":3.4,"version":0}]', NULL, 5, 1, '已核对分项与总评计算，通过审核。', '2024-01-16 15:00:00', '2024-01-16 09:00:00', '2024-01-16 15:00:00'),
(2, 2, 1, 2, '2024-07-09 09:00:00', '[{"grade_id":2,"usual_score":82.0,"final_score":87.0,"total_score":85.0,"grade_point":3.5,"version":0}]', NULL, 5, 1, '已核对分项与总评计算，通过审核。', '2024-07-09 15:00:00', '2024-07-09 09:00:00', '2024-07-09 15:00:00'),
(3, 3, 1, 2, '2025-01-14 09:00:00', '[{"grade_id":3,"usual_score":83.0,"final_score":88.0,"total_score":86.0,"grade_point":3.6,"version":0}]', NULL, 5, 1, '已核对分项与总评计算，通过审核。', '2025-01-14 15:00:00', '2025-01-14 09:00:00', '2025-01-14 15:00:00'),
(4, 4, 1, 2, '2025-07-08 09:00:00', '[{"grade_id":4,"usual_score":84.0,"final_score":89.0,"total_score":87.0,"grade_point":3.7,"version":0}]', NULL, 5, 1, '已核对分项与总评计算，通过审核。', '2025-07-08 15:00:00', '2025-07-08 09:00:00', '2025-07-08 15:00:00'),
(5, 5, 1, 2, '2026-01-13 09:00:00', '[{"grade_id":5,"usual_score":85.0,"final_score":90.0,"total_score":88.0,"grade_point":3.8,"version":0}]', NULL, 5, 1, '已核对分项与总评计算，通过审核。', '2026-01-13 15:00:00', '2026-01-13 09:00:00', '2026-01-13 15:00:00');

-- ------------------------------------------------------------
-- 25. 成绩更正申请表 (grade_change)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `grade_change`;
CREATE TABLE `grade_change` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '更正ID；自增长类型',
    `grade_id` BIGINT NOT NULL COMMENT '成绩ID；grade(id)；查询索引',
    `applicant_id` BIGINT NOT NULL COMMENT '申请人ID；user(id)',
    `before_value` JSON NOT NULL COMMENT '原成绩；含分项、总评、绩点及版本',
    `after_value` JSON NOT NULL COMMENT '拟改成绩；与原成绩同结构',
    `change_reason` VARCHAR(255) NOT NULL COMMENT '更正原因',
    `reviewer_id` BIGINT DEFAULT NULL COMMENT '审核人ID；user(id)',
    `review_status` TINYINT NOT NULL DEFAULT 0 COMMENT '审核状态；0待审；1通过；2驳回',
    `review_comment` VARCHAR(255) DEFAULT NULL COMMENT '审核意见',
    `review_time` DATETIME DEFAULT NULL COMMENT '审核时间',
    `apply_time` DATETIME DEFAULT NULL COMMENT '生效时间；审核通过后事务更新原成绩',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_grade_change_grade_id` (`grade_id`),
    KEY `fk_grade_change_applicant_id` (`applicant_id`),
    KEY `fk_grade_change_reviewer_id` (`reviewer_id`),
    CONSTRAINT `ck_grade_change_01` CHECK (`review_status` IN (0,1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成绩更正申请表';

-- 插入5条成绩更正申请数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `grade_change` (`id`, `grade_id`, `applicant_id`, `before_value`, `after_value`, `change_reason`, `reviewer_id`, `review_status`, `review_comment`, `review_time`, `apply_time`, `create_time`, `update_time`) VALUES
(1, 1, 2, '{"usual_score":81.0,"final_score":86.0,"total_score":84.0,"grade_point":3.4,"version":1}', '{"usual_score":81.0,"final_score":87.0,"total_score":84.6,"grade_point":3.46,"version":2}', '申请复核末题计分。', 5, 2, '经复核原评分无误，维持已发布成绩。', '2024-01-18 16:00:00', NULL, '2024-01-17 09:00:00', '2024-01-18 16:00:00'),
(2, 2, 2, '{"usual_score":82.0,"final_score":87.0,"total_score":85.0,"grade_point":3.5,"version":1}', '{"usual_score":82.0,"final_score":88.0,"total_score":85.6,"grade_point":3.56,"version":2}', '申请复核末题计分。', 5, 2, '经复核原评分无误，维持已发布成绩。', '2024-07-11 16:00:00', NULL, '2024-07-10 09:00:00', '2024-07-11 16:00:00'),
(3, 3, 2, '{"usual_score":83.0,"final_score":88.0,"total_score":86.0,"grade_point":3.6,"version":1}', '{"usual_score":83.0,"final_score":89.0,"total_score":86.6,"grade_point":3.66,"version":2}', '申请复核末题计分。', 5, 2, '经复核原评分无误，维持已发布成绩。', '2025-01-16 16:00:00', NULL, '2025-01-15 09:00:00', '2025-01-16 16:00:00'),
(4, 4, 2, '{"usual_score":84.0,"final_score":89.0,"total_score":87.0,"grade_point":3.7,"version":1}', '{"usual_score":84.0,"final_score":90.0,"total_score":87.6,"grade_point":3.76,"version":2}', '申请复核末题计分。', 5, 2, '经复核原评分无误，维持已发布成绩。', '2025-07-10 16:00:00', NULL, '2025-07-09 09:00:00', '2025-07-10 16:00:00'),
(5, 5, 2, '{"usual_score":85.0,"final_score":90.0,"total_score":88.0,"grade_point":3.8,"version":1}', '{"usual_score":85.0,"final_score":91.0,"total_score":88.6,"grade_point":3.86,"version":2}', '申请复核末题计分。', 5, 2, '经复核原评分无误，维持已发布成绩。', '2026-01-15 16:00:00', NULL, '2026-01-14 09:00:00', '2026-01-15 16:00:00');

-- ------------------------------------------------------------
-- 26. 考试安排表 (exam_plan)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `exam_plan`;
CREATE TABLE `exam_plan` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '考试ID；自增长类型',
    `teaching_class_id` BIGINT NOT NULL COMMENT '教学班ID；teaching_class(id)；查询索引',
    `classroom_id` BIGINT NOT NULL COMMENT '教室ID；classroom(id)',
    `exam_name` VARCHAR(64) NOT NULL COMMENT '考试名称',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME NOT NULL COMMENT '结束时间',
    `invigilator_id` BIGINT NOT NULL COMMENT '主监考ID；user(id)；组合查询索引',
    `assistant_id` BIGINT DEFAULT NULL COMMENT '副监考ID；user(id)',
    `plan_status` TINYINT NOT NULL DEFAULT 0 COMMENT '安排状态；0草稿；1发布；2取消',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_exam_plan_teaching_class_id` (`teaching_class_id`),
    KEY `idx_exam_plan_invigilator_id_start_time` (`invigilator_id`, `start_time`),
    KEY `fk_exam_plan_classroom_id` (`classroom_id`),
    KEY `fk_exam_plan_assistant_id` (`assistant_id`),
    CONSTRAINT `ck_exam_plan_01` CHECK (`plan_status` IN (0,1,2)),
    CONSTRAINT `ck_exam_plan_02` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考试安排表';

-- 插入5条考试安排数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `exam_plan` (`id`, `teaching_class_id`, `classroom_id`, `exam_name`, `start_time`, `end_time`, `invigilator_id`, `assistant_id`, `plan_status`, `create_time`, `update_time`) VALUES
(1, 1, 1, '程序设计基础期末考试', '2024-01-15 09:00:00', '2024-01-15 11:00:00', 2, 3, 1, '2024-01-01 09:00:00', '2024-01-01 09:00:00'),
(2, 2, 2, '面向对象程序设计期末考试', '2024-07-08 09:00:00', '2024-07-08 11:00:00', 2, 3, 1, '2024-06-24 09:00:00', '2024-06-24 09:00:00'),
(3, 3, 3, '数据结构期末考试', '2025-01-13 09:00:00', '2025-01-13 11:00:00', 2, 3, 1, '2024-12-30 09:00:00', '2024-12-30 09:00:00'),
(4, 4, 4, '数据库应用开发期末考试', '2025-07-07 09:00:00', '2025-07-07 11:00:00', 2, 3, 1, '2025-06-23 09:00:00', '2025-06-23 09:00:00'),
(5, 5, 5, '综合项目实训期末考试', '2026-01-12 09:00:00', '2026-01-12 11:00:00', 2, 3, 1, '2025-12-29 09:00:00', '2025-12-29 09:00:00');

-- ------------------------------------------------------------
-- 27. 教学评价表 (teaching_evaluation)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `teaching_evaluation`;
CREATE TABLE `teaching_evaluation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '评价ID；自增长类型',
    `enrollment_id` BIGINT NOT NULL COMMENT '选课ID；enrollment(id)',
    `total_score` DECIMAL(5,2) NOT NULL COMMENT '综合评分；0至100',
    `item_scores` JSON NOT NULL COMMENT '指标评分；按系统配置保存指标及分值',
    `comment` TEXT DEFAULT NULL COMMENT '评价意见',
    `is_anonymous` TINYINT NOT NULL DEFAULT 1 COMMENT '匿名展示；0否；1是；教师端隐藏身份',
    `submit_time` DATETIME NOT NULL COMMENT '提交时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_teaching_evaluation_enrollment_id` (`enrollment_id`),
    CONSTRAINT `ck_teaching_evaluation_01` CHECK (`is_anonymous` IN (0,1)),
    CONSTRAINT `ck_teaching_evaluation_02` CHECK (`total_score` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='教学评价表';

-- 插入5条教学评价数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `teaching_evaluation` (`id`, `enrollment_id`, `total_score`, `item_scores`, `comment`, `is_anonymous`, `submit_time`, `create_time`) VALUES
(1, 1, 91, '{"教学态度":91,"内容组织":91,"实践指导":91}', '讲解清楚，实践案例有帮助。', 1, '2024-01-17 19:00:00', '2024-01-17 19:00:00'),
(2, 2, 92, '{"教学态度":92,"内容组织":92,"实践指导":92}', '讲解清楚，实践案例有帮助。', 1, '2024-07-10 19:00:00', '2024-07-10 19:00:00'),
(3, 3, 93, '{"教学态度":93,"内容组织":93,"实践指导":93}', '讲解清楚，实践案例有帮助。', 1, '2025-01-15 19:00:00', '2025-01-15 19:00:00'),
(4, 4, 94, '{"教学态度":94,"内容组织":94,"实践指导":94}', '讲解清楚，实践案例有帮助。', 1, '2025-07-09 19:00:00', '2025-07-09 19:00:00'),
(5, 5, 95, '{"教学态度":95,"内容组织":95,"实践指导":95}', '讲解清楚，实践案例有帮助。', 1, '2026-01-14 19:00:00', '2026-01-14 19:00:00');

-- ------------------------------------------------------------
-- 28. 请假单表 (leave_request)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `leave_request`;
CREATE TABLE `leave_request` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '请假ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；组合查询索引',
    `leave_type` VARCHAR(32) NOT NULL COMMENT '请假类型；请假类型字典',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME NOT NULL COMMENT '结束时间；必须晚于开始时间',
    `leave_days` DECIMAL(5,2) NOT NULL COMMENT '请假天数；按校规计算；超过3天转院系',
    `leave_reason` TEXT NOT NULL COMMENT '请假原因；覆盖上课时段时通知授课教师',
    `leave_status` TINYINT NOT NULL DEFAULT 0 COMMENT '请假状态；0草稿；1辅导员审；2院系审；3通过；4驳回；5退回；6撤回；7销假',
    `apply_round` INT NOT NULL DEFAULT 1 COMMENT '申请轮次',
    `submit_time` DATETIME DEFAULT NULL COMMENT '提交时间',
    `close_time` DATETIME DEFAULT NULL COMMENT '销假时间',
    `close_type` TINYINT NOT NULL DEFAULT 0 COMMENT '销假方式；0未销；1本人；2自动',
    `closer_id` BIGINT DEFAULT NULL COMMENT '销假人ID；user(id)；系统自动销假时为空',
    `close_note` VARCHAR(255) DEFAULT NULL COMMENT '销假说明',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_leave_request_student_id_leave_status` (`student_id`, `leave_status`),
    KEY `fk_leave_request_closer_id` (`closer_id`),
    CONSTRAINT `ck_leave_request_01` CHECK (`leave_status` IN (0,1,2,3,4,5,6,7)),
    CONSTRAINT `ck_leave_request_02` CHECK (`close_type` IN (0,1,2)),
    CONSTRAINT `ck_leave_request_03` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_leave_request_04` CHECK (`leave_days` > 0),
    CONSTRAINT `ck_leave_request_05` CHECK (`apply_round` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='请假单表';

-- 插入5条请假单数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `leave_request` (`id`, `student_id`, `leave_type`, `start_time`, `end_time`, `leave_days`, `leave_reason`, `leave_status`, `apply_round`, `submit_time`, `close_time`, `close_type`, `closer_id`, `close_note`, `create_time`, `update_time`) VALUES
(1, 1, 'PERSONAL', '2025-10-03 08:00:00', '2025-10-04 08:00:00', 1.00, '办理个人事务，按时返校。', 7, 1, '2025-10-01 09:00:00', '2025-10-03 20:00:00', 1, 1, '已返校，本人销假。', '2025-10-01 09:00:00', '2025-10-03 20:00:00'),
(2, 1, 'PERSONAL', '2025-10-10 08:00:00', '2025-10-11 08:00:00', 1.00, '办理个人事务，按时返校。', 7, 1, '2025-10-08 09:00:00', '2025-10-10 20:00:00', 1, 1, '已返校，本人销假。', '2025-10-08 09:00:00', '2025-10-10 20:00:00'),
(3, 1, 'PERSONAL', '2025-10-17 08:00:00', '2025-10-18 08:00:00', 1.00, '办理个人事务，按时返校。', 7, 1, '2025-10-15 09:00:00', '2025-10-17 20:00:00', 1, 1, '已返校，本人销假。', '2025-10-15 09:00:00', '2025-10-17 20:00:00'),
(4, 1, 'PERSONAL', '2025-10-24 08:00:00', '2025-10-25 08:00:00', 1.00, '办理个人事务，按时返校。', 7, 1, '2025-10-22 09:00:00', '2025-10-24 20:00:00', 1, 1, '已返校，本人销假。', '2025-10-22 09:00:00', '2025-10-24 20:00:00'),
(5, 1, 'PERSONAL', '2025-10-31 08:00:00', '2025-11-01 08:00:00', 1.00, '办理个人事务，按时返校。', 7, 1, '2025-10-29 09:00:00', '2025-10-31 20:00:00', 1, 1, '已返校，本人销假。', '2025-10-29 09:00:00', '2025-10-31 20:00:00');

-- ------------------------------------------------------------
-- 29. 请假审批记录表 (leave_approval)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `leave_approval`;
CREATE TABLE `leave_approval` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '审批ID；自增长类型',
    `leave_id` BIGINT NOT NULL COMMENT '请假ID；leave_request(id)',
    `apply_round` INT NOT NULL DEFAULT 1 COMMENT '申请轮次',
    `node_order` TINYINT NOT NULL COMMENT '节点顺序；与请假ID、申请轮次联合唯一',
    `node_type` TINYINT NOT NULL DEFAULT 1 COMMENT '节点类型；1辅导员；2院系领导',
    `approver_id` BIGINT NOT NULL COMMENT '审批人ID；user(id)；组合查询索引',
    `decision` TINYINT NOT NULL DEFAULT 0 COMMENT '审批结果；0待办；1同意；2驳回；3退回；4取消',
    `opinion` VARCHAR(255) DEFAULT NULL COMMENT '审批意见',
    `approve_time` DATETIME DEFAULT NULL COMMENT '审批时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_leave_approval_leave_id_apply_round_node_order` (`leave_id`, `apply_round`, `node_order`),
    KEY `idx_leave_approval_approver_id_decision` (`approver_id`, `decision`),
    CONSTRAINT `ck_leave_approval_01` CHECK (`node_type` IN (1,2)),
    CONSTRAINT `ck_leave_approval_02` CHECK (`decision` IN (0,1,2,3,4)),
    CONSTRAINT `ck_leave_approval_03` CHECK (`apply_round` >= 1),
    CONSTRAINT `ck_leave_approval_04` CHECK (`node_order` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='请假审批记录表';

-- 插入5条请假审批记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `leave_approval` (`id`, `leave_id`, `apply_round`, `node_order`, `node_type`, `approver_id`, `decision`, `opinion`, `approve_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, 1, 3, 1, '同意，请注意出行安全。', '2025-10-02 09:00:00', '2025-10-01 09:00:00', '2025-10-02 09:00:00'),
(2, 2, 1, 1, 1, 3, 1, '同意，请注意出行安全。', '2025-10-09 09:00:00', '2025-10-08 09:00:00', '2025-10-09 09:00:00'),
(3, 3, 1, 1, 1, 3, 1, '同意，请注意出行安全。', '2025-10-16 09:00:00', '2025-10-15 09:00:00', '2025-10-16 09:00:00'),
(4, 4, 1, 1, 1, 3, 1, '同意，请注意出行安全。', '2025-10-23 09:00:00', '2025-10-22 09:00:00', '2025-10-23 09:00:00'),
(5, 5, 1, 1, 1, 3, 1, '同意，请注意出行安全。', '2025-10-30 09:00:00', '2025-10-29 09:00:00', '2025-10-30 09:00:00');

-- ------------------------------------------------------------
-- 30. 学生奖惩记录表 (student_record)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `student_record`;
CREATE TABLE `student_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '记录ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；组合查询索引',
    `record_type` TINYINT NOT NULL DEFAULT 1 COMMENT '记录类型；1奖励；2处分',
    `record_title` VARCHAR(128) NOT NULL COMMENT '事项名称',
    `record_level` VARCHAR(32) DEFAULT NULL COMMENT '事项级别',
    `description` TEXT NOT NULL COMMENT '事项说明',
    `record_date` DATE NOT NULL COMMENT '发生日期',
    `operator_id` BIGINT NOT NULL COMMENT '登记人ID；user(id)',
    `record_status` TINYINT NOT NULL DEFAULT 1 COMMENT '记录状态；1有效；2撤销',
    `revoke_reason` VARCHAR(255) DEFAULT NULL COMMENT '撤销原因',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_student_record_student_id_record_date` (`student_id`, `record_date`),
    KEY `fk_student_record_operator_id` (`operator_id`),
    CONSTRAINT `ck_student_record_01` CHECK (`record_type` IN (1,2)),
    CONSTRAINT `ck_student_record_02` CHECK (`record_status` IN (1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学生奖惩记录表';

-- 插入5条学生奖惩记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `student_record` (`id`, `student_id`, `record_type`, `record_title`, `record_level`, `description`, `record_date`, `operator_id`, `record_status`, `revoke_reason`, `create_time`, `update_time`) VALUES
(1, 1, 1, '学习进步表扬', '院级', '演示记录：完成对应活动并获得表扬。', '2025-11-11', 3, 1, NULL, '2025-11-11 16:00:00', '2025-11-11 16:00:00'),
(2, 1, 1, '志愿服务表扬', '院级', '演示记录：完成对应活动并获得表扬。', '2025-11-12', 3, 1, NULL, '2025-11-12 16:00:00', '2025-11-12 16:00:00'),
(3, 1, 1, '技能竞赛优秀奖', '院级', '演示记录：完成对应活动并获得表扬。', '2025-11-13', 3, 1, NULL, '2025-11-13 16:00:00', '2025-11-13 16:00:00'),
(4, 1, 1, '文明宿舍表扬', '院级', '演示记录：完成对应活动并获得表扬。', '2025-11-14', 3, 1, NULL, '2025-11-14 16:00:00', '2025-11-14 16:00:00'),
(5, 1, 1, '项目实践优秀奖', '院级', '演示记录：完成对应活动并获得表扬。', '2025-11-15', 3, 1, NULL, '2025-11-15 16:00:00', '2025-11-15 16:00:00');

-- ------------------------------------------------------------
-- 31. 查寝晚归记录表 (dorm_check)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `dorm_check`;
CREATE TABLE `dorm_check` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '查寝ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；组合查询索引',
    `dorm_location` VARCHAR(128) NOT NULL COMMENT '宿舍位置',
    `check_time` DATETIME NOT NULL COMMENT '检查时间',
    `check_result` TINYINT NOT NULL DEFAULT 1 COMMENT '检查结果；1正常；2晚归；3未归；4已请假',
    `return_time` DATETIME DEFAULT NULL COMMENT '返寝时间',
    `handle_note` VARCHAR(255) DEFAULT NULL COMMENT '处理意见',
    `checker_id` BIGINT NOT NULL COMMENT '检查人ID；user(id)',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_dorm_check_student_id_check_time` (`student_id`, `check_time`),
    KEY `fk_dorm_check_checker_id` (`checker_id`),
    CONSTRAINT `ck_dorm_check_01` CHECK (`check_result` IN (1,2,3,4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='查寝晚归记录表';

-- 插入5条查寝晚归记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `dorm_check` (`id`, `student_id`, `dorm_location`, `check_time`, `check_result`, `return_time`, `handle_note`, `checker_id`, `create_time`, `update_time`) VALUES
(1, 1, '学生公寓一号楼301室', '2025-12-02 22:00:00', 1, NULL, '在寝，情况正常。', 3, '2025-12-02 22:00:00', '2025-12-02 22:00:00'),
(2, 1, '学生公寓一号楼301室', '2025-12-03 22:00:00', 1, NULL, '在寝，情况正常。', 3, '2025-12-03 22:00:00', '2025-12-03 22:00:00'),
(3, 1, '学生公寓一号楼301室', '2025-12-04 22:00:00', 1, NULL, '在寝，情况正常。', 3, '2025-12-04 22:00:00', '2025-12-04 22:00:00'),
(4, 1, '学生公寓一号楼301室', '2025-12-05 22:00:00', 1, NULL, '在寝，情况正常。', 3, '2025-12-05 22:00:00', '2025-12-05 22:00:00'),
(5, 1, '学生公寓一号楼301室', '2025-12-06 22:00:00', 1, NULL, '在寝，情况正常。', 3, '2025-12-06 22:00:00', '2025-12-06 22:00:00');

-- ------------------------------------------------------------
-- 32. 重点关注记录表 (student_focus)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `student_focus`;
CREATE TABLE `student_focus` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关注ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；查询索引',
    `focus_type` VARCHAR(32) NOT NULL COMMENT '关注类别',
    `focus_content` TEXT NOT NULL COMMENT '关注内容；加密保存；禁止无授权导出',
    `follow_up` TEXT DEFAULT NULL COMMENT '跟进记录',
    `owner_id` BIGINT NOT NULL COMMENT '负责人ID；user(id)；组合查询索引',
    `focus_status` TINYINT NOT NULL DEFAULT 1 COMMENT '关注状态；1跟进中；2已结束',
    `close_time` DATETIME DEFAULT NULL COMMENT '结束时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_student_focus_student_id` (`student_id`),
    KEY `idx_student_focus_owner_id_focus_status` (`owner_id`, `focus_status`),
    CONSTRAINT `ck_student_focus_01` CHECK (`focus_status` IN (1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='重点关注记录表';

-- 插入5条重点关注记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `student_focus` (`id`, `student_id`, `focus_type`, `focus_content`, `follow_up`, `owner_id`, `focus_status`, `close_time`, `create_time`, `update_time`) VALUES
(1, 1, 'ACADEMIC_SUPPORT', 'demo_aesgcm:NB56RTCre0qnFOdKcG6yaSE/s4ZhHNU/XKbxKTGc/HpA2zMa7R5FgXtnclCRcUzD1XHFbDOdHIYV/62Wn+09mR5kMRA1myRCZNmrePs=', '已完成阶段学习交流。', 3, 2, '2025-12-11 16:00:00', '2025-11-02 10:00:00', '2025-12-11 16:00:00'),
(2, 1, 'ACADEMIC_SUPPORT', 'demo_aesgcm:akt1PWpCrE/24Tq2hk1Q4plBMO6UmjdYZEGyPlSAdRbG+SygLh2+rnv7LaV7BLC5qf4mDhm6ioz3xVZiSFaEtDYNw8P90+IN4NaUy6s=', '已完成阶段学习交流。', 3, 2, '2025-12-12 16:00:00', '2025-11-03 10:00:00', '2025-12-12 16:00:00'),
(3, 1, 'ACADEMIC_SUPPORT', 'demo_aesgcm:uSIi+y1qtxMhFJBEQYuEPmllBHGhWysjWFjOj4JKEMr5LD1DV42kDYswnv3u/oRWZMZTl6R4lacw1ap0UbbSjfQVjqq0qvw8Q2SE+K0=', '已完成阶段学习交流。', 3, 2, '2025-12-13 16:00:00', '2025-11-04 10:00:00', '2025-12-13 16:00:00'),
(4, 1, 'ACADEMIC_SUPPORT', 'demo_aesgcm:1ltFOfVh9dB0d75Ka5Eg2lvdyDVXODNefDCHIuIIz9888JEHVliEBwM36z+SVATIo+LbQw1QuDqd7oFOLf9m1AM16HmgEMQP0EI0Kdo=', '已完成阶段学习交流。', 3, 2, '2025-12-14 16:00:00', '2025-11-05 10:00:00', '2025-12-14 16:00:00'),
(5, 1, 'ACADEMIC_SUPPORT', 'demo_aesgcm:mSQGQSeQ84s6X5FLl3oaAYksyl0X/pr2eEjLVqxdQ9eUPt2HPDzhsuB8UrgZNW4Hw7GVnY0B5O8BnJ+oGyQFdnrmTsJ1l+65xF8dcm8=', '已完成阶段学习交流。', 3, 2, '2025-12-15 16:00:00', '2025-11-06 10:00:00', '2025-12-15 16:00:00');

-- ------------------------------------------------------------
-- 33. 奖助贷批次表 (aid_batch)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `aid_batch`;
CREATE TABLE `aid_batch` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '批次ID；自增长类型',
    `batch_name` VARCHAR(128) NOT NULL COMMENT '批次名称',
    `aid_type` VARCHAR(32) NOT NULL COMMENT '资助类型',
    `org_id` BIGINT NOT NULL COMMENT '组织ID；org_unit(id)',
    `semester_id` BIGINT NOT NULL COMMENT '学期ID；semester(id)；组合查询索引',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME NOT NULL COMMENT '结束时间',
    `quota` INT NOT NULL COMMENT '名额；大于0',
    `aid_amount` DECIMAL(10,2) NOT NULL COMMENT '资助金额；单位元；大于等于0',
    `requirements` TEXT NOT NULL COMMENT '申请条件',
    `batch_status` TINYINT NOT NULL DEFAULT 0 COMMENT '批次状态；0草稿；1开放；2评审；3结束',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_aid_batch_semester_id_org_id` (`semester_id`, `org_id`),
    KEY `fk_aid_batch_org_id` (`org_id`),
    CONSTRAINT `ck_aid_batch_01` CHECK (`batch_status` IN (0,1,2,3)),
    CONSTRAINT `ck_aid_batch_02` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_aid_batch_03` CHECK (`quota` > 0),
    CONSTRAINT `ck_aid_batch_04` CHECK (`aid_amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='奖助贷批次表';

-- 插入5条奖助贷批次数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `aid_batch` (`id`, `batch_name`, `aid_type`, `org_id`, `semester_id`, `start_time`, `end_time`, `quota`, `aid_amount`, `requirements`, `batch_status`, `create_time`, `update_time`) VALUES
(1, '2025秋季第1期实践助学项目', 'STUDY_GRANT', 2, 5, '2025-09-02 09:00:00', '2025-09-12 18:00:00', 10, 1200, '在校学生，完成实践学习申请材料；本项目为演示批次。', 3, '2025-09-01 09:00:00', '2025-09-21 16:00:00'),
(2, '2025秋季第2期实践助学项目', 'STUDY_GRANT', 2, 5, '2025-09-03 09:00:00', '2025-09-13 18:00:00', 10, 1400, '在校学生，完成实践学习申请材料；本项目为演示批次。', 3, '2025-09-01 09:00:00', '2025-09-22 16:00:00'),
(3, '2025秋季第3期实践助学项目', 'STUDY_GRANT', 2, 5, '2025-09-04 09:00:00', '2025-09-14 18:00:00', 10, 1600, '在校学生，完成实践学习申请材料；本项目为演示批次。', 3, '2025-09-01 09:00:00', '2025-09-23 16:00:00'),
(4, '2025秋季第4期实践助学项目', 'STUDY_GRANT', 2, 5, '2025-09-05 09:00:00', '2025-09-15 18:00:00', 10, 1800, '在校学生，完成实践学习申请材料；本项目为演示批次。', 3, '2025-09-01 09:00:00', '2025-09-24 16:00:00'),
(5, '2025秋季第5期实践助学项目', 'STUDY_GRANT', 2, 5, '2025-09-06 09:00:00', '2025-09-16 18:00:00', 10, 2000, '在校学生，完成实践学习申请材料；本项目为演示批次。', 3, '2025-09-01 09:00:00', '2025-09-25 16:00:00');

-- ------------------------------------------------------------
-- 34. 奖助贷申请表 (aid_application)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `aid_application`;
CREATE TABLE `aid_application` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '申请ID；自增长类型',
    `batch_id` BIGINT NOT NULL COMMENT '批次ID；aid_batch(id)',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；与批次ID联合唯一',
    `apply_reason` TEXT NOT NULL COMMENT '申请理由；敏感资料按权限访问',
    `apply_amount` DECIMAL(10,2) NOT NULL COMMENT '申请金额；单位元；大于0',
    `apply_status` TINYINT NOT NULL DEFAULT 0 COMMENT '申请状态；0草稿；1待评；2通过；3驳回；4退回；5撤回',
    `apply_round` INT NOT NULL DEFAULT 1 COMMENT '申请轮次',
    `submit_time` DATETIME DEFAULT NULL COMMENT '提交时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_aid_application_batch_id_student_id` (`batch_id`, `student_id`),
    KEY `fk_aid_application_student_id` (`student_id`),
    CONSTRAINT `ck_aid_application_01` CHECK (`apply_status` IN (0,1,2,3,4,5)),
    CONSTRAINT `ck_aid_application_02` CHECK (`apply_amount` > 0),
    CONSTRAINT `ck_aid_application_03` CHECK (`apply_round` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='奖助贷申请表';

-- 插入5条奖助贷申请数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `aid_application` (`id`, `batch_id`, `student_id`, `apply_reason`, `apply_amount`, `apply_status`, `apply_round`, `submit_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, '申请参加实践助学项目。', 1200, 2, 1, '2025-09-06 10:00:00', '2025-09-06 10:00:00', '2025-09-16 16:00:00'),
(2, 2, 1, '申请参加实践助学项目。', 1400, 2, 1, '2025-09-07 10:00:00', '2025-09-07 10:00:00', '2025-09-17 16:00:00'),
(3, 3, 1, '申请参加实践助学项目。', 1600, 2, 1, '2025-09-08 10:00:00', '2025-09-08 10:00:00', '2025-09-18 16:00:00'),
(4, 4, 1, '申请参加实践助学项目。', 1800, 2, 1, '2025-09-09 10:00:00', '2025-09-09 10:00:00', '2025-09-19 16:00:00'),
(5, 5, 1, '申请参加实践助学项目。', 2000, 2, 1, '2025-09-10 10:00:00', '2025-09-10 10:00:00', '2025-09-20 16:00:00');

-- ------------------------------------------------------------
-- 35. 奖助贷评审记录表 (aid_review)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `aid_review`;
CREATE TABLE `aid_review` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '评审ID；自增长类型',
    `application_id` BIGINT NOT NULL COMMENT '申请ID；aid_application(id)',
    `apply_round` INT NOT NULL DEFAULT 1 COMMENT '申请轮次',
    `node_order` TINYINT NOT NULL COMMENT '节点顺序',
    `reviewer_id` BIGINT NOT NULL COMMENT '评审人ID；user(id)；与申请ID、申请轮次、节点顺序联合唯一',
    `review_score` DECIMAL(5,2) DEFAULT NULL COMMENT '评审分数',
    `decision` TINYINT NOT NULL DEFAULT 0 COMMENT '评审结果；0待评；1通过；2驳回；3退回',
    `opinion` VARCHAR(255) DEFAULT NULL COMMENT '评审意见',
    `review_time` DATETIME DEFAULT NULL COMMENT '评审时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_aid_review_application_id_apply_round_node_order_reviewer_id` (`application_id`, `apply_round`, `node_order`, `reviewer_id`),
    KEY `fk_aid_review_reviewer_id` (`reviewer_id`),
    CONSTRAINT `ck_aid_review_01` CHECK (`decision` IN (0,1,2,3)),
    CONSTRAINT `ck_aid_review_02` CHECK (`apply_round` >= 1),
    CONSTRAINT `ck_aid_review_03` CHECK (`node_order` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='奖助贷评审记录表';

-- 插入5条奖助贷评审记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `aid_review` (`id`, `application_id`, `apply_round`, `node_order`, `reviewer_id`, `review_score`, `decision`, `opinion`, `review_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, 3, 91, 1, '材料齐全，符合演示项目条件，通过。', '2025-09-16 16:00:00', '2025-09-12 18:00:00', '2025-09-16 16:00:00'),
(2, 2, 1, 1, 3, 92, 1, '材料齐全，符合演示项目条件，通过。', '2025-09-17 16:00:00', '2025-09-13 18:00:00', '2025-09-17 16:00:00'),
(3, 3, 1, 1, 3, 93, 1, '材料齐全，符合演示项目条件，通过。', '2025-09-18 16:00:00', '2025-09-14 18:00:00', '2025-09-18 16:00:00'),
(4, 4, 1, 1, 3, 94, 1, '材料齐全，符合演示项目条件，通过。', '2025-09-19 16:00:00', '2025-09-15 18:00:00', '2025-09-19 16:00:00'),
(5, 5, 1, 1, 3, 95, 1, '材料齐全，符合演示项目条件，通过。', '2025-09-20 16:00:00', '2025-09-16 18:00:00', '2025-09-20 16:00:00');

-- ------------------------------------------------------------
-- 36. 学生办事申请表 (service_application)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `service_application`;
CREATE TABLE `service_application` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '申请ID；自增长类型',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；组合查询索引',
    `service_type` TINYINT NOT NULL DEFAULT 1 COMMENT '事项类型；1证明开具；2毕业离校',
    `service_name` VARCHAR(128) NOT NULL COMMENT '事项名称',
    `apply_data` JSON NOT NULL COMMENT '申请内容；按事项模板校验；敏感项加密',
    `service_status` TINYINT NOT NULL DEFAULT 0 COMMENT '办理状态；0草稿；1办理中；2办结；3退回；4撤回',
    `result_file_id` BIGINT DEFAULT NULL COMMENT '结果文件ID；file_upload(id)',
    `submit_time` DATETIME DEFAULT NULL COMMENT '提交时间',
    `finish_time` DATETIME DEFAULT NULL COMMENT '办结时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_service_application_student_id_service_type` (`student_id`, `service_type`),
    KEY `fk_service_application_result_file_id` (`result_file_id`),
    CONSTRAINT `ck_service_application_01` CHECK (`service_type` IN (1,2)),
    CONSTRAINT `ck_service_application_02` CHECK (`service_status` IN (0,1,2,3,4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学生办事申请表';

-- 插入5条学生办事申请数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `service_application` (`id`, `student_id`, `service_type`, `service_name`, `apply_data`, `service_status`, `result_file_id`, `submit_time`, `finish_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, '在读证明', '{"用途":"教学演示","份数":1,"领取方式":"线上"}', 1, NULL, '2026-01-18 11:00:00', NULL, '2026-01-18 11:00:00', '2026-01-18 11:00:00'),
(2, 1, 1, '成绩证明', '{"用途":"教学演示","份数":1,"领取方式":"线上"}', 1, NULL, '2026-01-18 12:00:00', NULL, '2026-01-18 12:00:00', '2026-01-18 12:00:00'),
(3, 1, 1, '实习联系证明', '{"用途":"教学演示","份数":1,"领取方式":"线上"}', 1, NULL, '2026-01-18 13:00:00', NULL, '2026-01-18 13:00:00', '2026-01-18 13:00:00'),
(4, 1, 1, '学籍证明', '{"用途":"教学演示","份数":1,"领取方式":"线上"}', 1, NULL, '2026-01-18 14:00:00', NULL, '2026-01-18 14:00:00', '2026-01-18 14:00:00'),
(5, 1, 1, '学生身份说明', '{"用途":"教学演示","份数":1,"领取方式":"线上"}', 1, NULL, '2026-01-18 15:00:00', NULL, '2026-01-18 15:00:00', '2026-01-18 15:00:00');

-- ------------------------------------------------------------
-- 37. 学生办事环节表 (service_step)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `service_step`;
CREATE TABLE `service_step` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '环节ID；自增长类型',
    `application_id` BIGINT NOT NULL COMMENT '申请ID；service_application(id)',
    `step_order` INT NOT NULL COMMENT '环节顺序；与申请ID联合唯一',
    `step_name` VARCHAR(64) NOT NULL COMMENT '环节名称',
    `org_id` BIGINT NOT NULL COMMENT '办理组织ID；org_unit(id)',
    `handler_id` BIGINT DEFAULT NULL COMMENT '办理人ID；user(id)',
    `decision` TINYINT NOT NULL DEFAULT 0 COMMENT '办理结果；0待办；1通过；2退回',
    `opinion` VARCHAR(255) DEFAULT NULL COMMENT '办理意见',
    `handle_time` DATETIME DEFAULT NULL COMMENT '办理时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_service_step_application_id_step_order` (`application_id`, `step_order`),
    KEY `fk_service_step_org_id` (`org_id`),
    KEY `fk_service_step_handler_id` (`handler_id`),
    CONSTRAINT `ck_service_step_01` CHECK (`decision` IN (0,1,2)),
    CONSTRAINT `ck_service_step_02` CHECK (`step_order` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学生办事环节表';

-- 插入5条学生办事环节数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `service_step` (`id`, `application_id`, `step_order`, `step_name`, `org_id`, `handler_id`, `decision`, `opinion`, `handle_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, '院系审核并出具证明', 2, 5, 0, NULL, NULL, '2026-01-18 11:00:00', '2026-01-18 11:00:00'),
(2, 2, 1, '院系审核并出具证明', 2, 5, 0, NULL, NULL, '2026-01-18 12:00:00', '2026-01-18 12:00:00'),
(3, 3, 1, '院系审核并出具证明', 2, 5, 0, NULL, NULL, '2026-01-18 13:00:00', '2026-01-18 13:00:00'),
(4, 4, 1, '院系审核并出具证明', 2, 5, 0, NULL, NULL, '2026-01-18 14:00:00', '2026-01-18 14:00:00'),
(5, 5, 1, '院系审核并出具证明', 2, 5, 0, NULL, NULL, '2026-01-18 15:00:00', '2026-01-18 15:00:00');

-- ------------------------------------------------------------
-- 38. 校园卡账户表 (card_account)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `card_account`;
CREATE TABLE `card_account` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '账户ID；自增长类型',
    `user_id` BIGINT NOT NULL COMMENT '用户ID；user(id)',
    `card_no` VARCHAR(32) NOT NULL COMMENT '校园卡号',
    `balance` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '账户余额；单位元；禁止负值',
    `account_status` TINYINT NOT NULL DEFAULT 1 COMMENT '账户状态；0冻结；1正常；2注销',
    `version` INT NOT NULL DEFAULT 0 COMMENT '版本号；账务并发控制',
    `sync_time` DATETIME DEFAULT NULL COMMENT '同步时间；外部卡系统对账时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_card_account_user_id` (`user_id`),
    UNIQUE KEY `uk_card_account_card_no` (`card_no`),
    CONSTRAINT `ck_card_account_01` CHECK (`account_status` IN (0,1,2)),
    CONSTRAINT `ck_card_account_02` CHECK (`balance` >= 0),
    CONSTRAINT `ck_card_account_03` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='校园卡账户表';

-- 插入5条校园卡账户数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `card_account` (`id`, `user_id`, `card_no`, `balance`, `account_status`, `version`, `sync_time`, `create_time`, `update_time`) VALUES
(1, 1, 'CARD_DEMO_0001', 100, 1, 1, '2026-01-02 11:00:00', '2023-08-01 09:00:00', '2026-01-02 10:01:02'),
(2, 2, 'CARD_DEMO_0002', 200, 1, 1, '2026-01-03 11:00:00', '2023-08-01 09:00:00', '2026-01-03 10:01:02'),
(3, 3, 'CARD_DEMO_0003', 300, 1, 1, '2026-01-04 11:00:00', '2023-08-01 09:00:00', '2026-01-04 10:01:02'),
(4, 4, 'CARD_DEMO_0004', 400, 1, 1, '2026-01-05 11:00:00', '2023-08-01 09:00:00', '2026-01-05 10:01:02'),
(5, 5, 'CARD_DEMO_0005', 500, 1, 1, '2026-01-06 11:00:00', '2023-08-01 09:00:00', '2026-01-06 10:01:02');

-- ------------------------------------------------------------
-- 39. 充值订单表 (recharge_order)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `recharge_order`;
CREATE TABLE `recharge_order` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单ID；自增长类型',
    `order_no` VARCHAR(64) NOT NULL COMMENT '充值单号',
    `account_id` BIGINT NOT NULL COMMENT '账户ID；card_account(id)；组合查询索引',
    `amount` DECIMAL(12,2) NOT NULL COMMENT '充值金额；单位元；必须大于0',
    `pay_channel` VARCHAR(32) NOT NULL COMMENT '支付渠道',
    `pay_trade_no` VARCHAR(64) DEFAULT NULL COMMENT '支付流水号；与支付渠道联合唯一',
    `request_key` VARCHAR(64) NOT NULL COMMENT '幂等键',
    `order_status` TINYINT NOT NULL DEFAULT 0 COMMENT '订单状态；0待付；1支付成功待入账；2已入账；3关闭',
    `pay_time` DATETIME DEFAULT NULL COMMENT '支付时间',
    `callback_time` DATETIME DEFAULT NULL COMMENT '回调时间；验签并核对金额及订单',
    `posted_time` DATETIME DEFAULT NULL COMMENT '入账时间；与余额及流水同一事务',
    `expire_time` DATETIME NOT NULL COMMENT '过期时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_recharge_order_order_no` (`order_no`),
    UNIQUE KEY `uk_recharge_order_pay_channel_pay_trade_no` (`pay_channel`, `pay_trade_no`),
    UNIQUE KEY `uk_recharge_order_request_key` (`request_key`),
    KEY `idx_recharge_order_account_id_order_status` (`account_id`, `order_status`),
    CONSTRAINT `ck_recharge_order_01` CHECK (`order_status` IN (0,1,2,3)),
    CONSTRAINT `ck_recharge_order_02` CHECK (`amount` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='充值订单表';

-- 插入5条充值订单数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `recharge_order` (`id`, `order_no`, `account_id`, `amount`, `pay_channel`, `pay_trade_no`, `request_key`, `order_status`, `pay_time`, `callback_time`, `posted_time`, `expire_time`, `create_time`, `update_time`) VALUES
(1, 'RC202601020001', 1, 100, 'MOCK_PAY', 'MOCK_PAY_0001', 'recharge_demo_001', 2, '2026-01-02 10:01:00', '2026-01-02 10:01:01', '2026-01-02 10:01:02', '2026-01-02 10:30:00', '2026-01-02 10:00:00', '2026-01-02 10:01:02'),
(2, 'RC202601030001', 2, 200, 'MOCK_PAY', 'MOCK_PAY_0002', 'recharge_demo_002', 2, '2026-01-03 10:01:00', '2026-01-03 10:01:01', '2026-01-03 10:01:02', '2026-01-03 10:30:00', '2026-01-03 10:00:00', '2026-01-03 10:01:02'),
(3, 'RC202601040001', 3, 300, 'MOCK_PAY', 'MOCK_PAY_0003', 'recharge_demo_003', 2, '2026-01-04 10:01:00', '2026-01-04 10:01:01', '2026-01-04 10:01:02', '2026-01-04 10:30:00', '2026-01-04 10:00:00', '2026-01-04 10:01:02'),
(4, 'RC202601050001', 4, 400, 'MOCK_PAY', 'MOCK_PAY_0004', 'recharge_demo_004', 2, '2026-01-05 10:01:00', '2026-01-05 10:01:01', '2026-01-05 10:01:02', '2026-01-05 10:30:00', '2026-01-05 10:00:00', '2026-01-05 10:01:02'),
(5, 'RC202601060001', 5, 500, 'MOCK_PAY', 'MOCK_PAY_0005', 'recharge_demo_005', 2, '2026-01-06 10:01:00', '2026-01-06 10:01:01', '2026-01-06 10:01:02', '2026-01-06 10:30:00', '2026-01-06 10:00:00', '2026-01-06 10:01:02');

-- ------------------------------------------------------------
-- 40. 校园卡流水表 (card_transaction)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `card_transaction`;
CREATE TABLE `card_transaction` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '流水ID；自增长类型',
    `transaction_no` VARCHAR(64) NOT NULL COMMENT '流水号',
    `account_id` BIGINT NOT NULL COMMENT '账户ID；card_account(id)；组合查询索引',
    `recharge_id` BIGINT DEFAULT NULL COMMENT '充值订单ID；recharge_order(id)；充值入账时必填',
    `source_system` VARCHAR(32) NOT NULL COMMENT '来源系统',
    `source_trade_no` VARCHAR(64) NOT NULL COMMENT '来源流水号；与来源系统联合唯一',
    `transaction_type` TINYINT NOT NULL DEFAULT 1 COMMENT '交易类型；1充值；2消费；3退款',
    `amount` DECIMAL(12,2) NOT NULL COMMENT '变动金额；单位元；收入正、支出负',
    `balance_before` DECIMAL(12,2) NOT NULL COMMENT '变动前余额',
    `balance_after` DECIMAL(12,2) NOT NULL COMMENT '变动后余额；前余额加变动金额；非负',
    `merchant_name` VARCHAR(128) DEFAULT NULL COMMENT '商户名称',
    `transaction_time` DATETIME NOT NULL COMMENT '交易时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_card_transaction_transaction_no` (`transaction_no`),
    UNIQUE KEY `uk_card_transaction_recharge_id` (`recharge_id`),
    UNIQUE KEY `uk_card_transaction_source_system_source_trade_no` (`source_system`, `source_trade_no`),
    KEY `idx_card_transaction_account_id_transaction_time` (`account_id`, `transaction_time`),
    CONSTRAINT `ck_card_transaction_01` CHECK (`transaction_type` IN (1,2,3)),
    CONSTRAINT `ck_card_transaction_02` CHECK (`balance_before` >= 0 AND `balance_after` >= 0),
    CONSTRAINT `ck_card_transaction_03` CHECK (`balance_after` = `balance_before` + `amount`),
    CONSTRAINT `ck_card_transaction_04` CHECK ((`transaction_type` IN (1,3) AND `amount` > 0) OR (`transaction_type` = 2 AND `amount` < 0)),
    CONSTRAINT `ck_card_transaction_05` CHECK (`transaction_type` <> 1 OR `recharge_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='校园卡流水表';

-- 插入5条校园卡流水数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `card_transaction` (`id`, `transaction_no`, `account_id`, `recharge_id`, `source_system`, `source_trade_no`, `transaction_type`, `amount`, `balance_before`, `balance_after`, `merchant_name`, `transaction_time`, `create_time`) VALUES
(1, 'TXN_DEMO_0001', 1, 1, 'MOCK_PAY', 'MOCK_PAY_0001', 1, 100, 0.00, 100, '校园卡充值演示', '2026-01-02 10:01:02', '2026-01-02 10:01:02'),
(2, 'TXN_DEMO_0002', 2, 2, 'MOCK_PAY', 'MOCK_PAY_0002', 1, 200, 0.00, 200, '校园卡充值演示', '2026-01-03 10:01:02', '2026-01-03 10:01:02'),
(3, 'TXN_DEMO_0003', 3, 3, 'MOCK_PAY', 'MOCK_PAY_0003', 1, 300, 0.00, 300, '校园卡充值演示', '2026-01-04 10:01:02', '2026-01-04 10:01:02'),
(4, 'TXN_DEMO_0004', 4, 4, 'MOCK_PAY', 'MOCK_PAY_0004', 1, 400, 0.00, 400, '校园卡充值演示', '2026-01-05 10:01:02', '2026-01-05 10:01:02'),
(5, 'TXN_DEMO_0005', 5, 5, 'MOCK_PAY', 'MOCK_PAY_0005', 1, 500, 0.00, 500, '校园卡充值演示', '2026-01-06 10:01:02', '2026-01-06 10:01:02');

-- ------------------------------------------------------------
-- 41. 图书书目表 (book)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `book`;
CREATE TABLE `book` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '图书ID；自增长类型',
    `book_code` VARCHAR(32) NOT NULL COMMENT '书目编码',
    `isbn` VARCHAR(20) DEFAULT NULL COMMENT 'ISBN；查询索引',
    `book_name` VARCHAR(128) NOT NULL COMMENT '书名；查询索引',
    `author` VARCHAR(128) NOT NULL COMMENT '作者',
    `publisher` VARCHAR(128) DEFAULT NULL COMMENT '出版社',
    `category_code` VARCHAR(32) NOT NULL COMMENT '分类编码；查询索引',
    `summary` TEXT DEFAULT NULL COMMENT '内容简介',
    `cover_id` BIGINT DEFAULT NULL COMMENT '封面ID；file_upload(id)',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_book_book_code` (`book_code`),
    KEY `idx_book_isbn` (`isbn`),
    KEY `idx_book_book_name` (`book_name`),
    KEY `idx_book_category_code` (`category_code`),
    KEY `fk_book_cover_id` (`cover_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书书目表';

-- 插入5条图书书目数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `book` (`id`, `book_code`, `isbn`, `book_name`, `author`, `publisher`, `category_code`, `summary`, `cover_id`, `create_time`, `update_time`) VALUES
(1, 'BK_DEMO_001', NULL, '程序设计基础学习手册（演示）', '教学示例编写组', '演示资料中心', 'TP_SOFTWARE', '虚构书目，仅用于数据库测试。', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'BK_DEMO_002', NULL, '面向对象程序设计学习手册（演示）', '教学示例编写组', '演示资料中心', 'TP_SOFTWARE', '虚构书目，仅用于数据库测试。', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'BK_DEMO_003', NULL, '数据结构学习手册（演示）', '教学示例编写组', '演示资料中心', 'TP_SOFTWARE', '虚构书目，仅用于数据库测试。', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'BK_DEMO_004', NULL, '数据库应用开发学习手册（演示）', '教学示例编写组', '演示资料中心', 'TP_SOFTWARE', '虚构书目，仅用于数据库测试。', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'BK_DEMO_005', NULL, '综合项目实训学习手册（演示）', '教学示例编写组', '演示资料中心', 'TP_SOFTWARE', '虚构书目，仅用于数据库测试。', NULL, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 42. 图书馆藏副本表 (book_copy)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `book_copy`;
CREATE TABLE `book_copy` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '副本ID；自增长类型',
    `book_id` BIGINT NOT NULL COMMENT '图书ID；book(id)；组合查询索引',
    `copy_no` VARCHAR(32) NOT NULL COMMENT '馆藏条码',
    `location` VARCHAR(128) NOT NULL COMMENT '馆藏位置',
    `copy_status` TINYINT NOT NULL DEFAULT 0 COMMENT '副本状态；0可借；1借出；2预约留置；3停用',
    `version` INT NOT NULL DEFAULT 0 COMMENT '版本号；借出及预约并发控制',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_book_copy_copy_no` (`copy_no`),
    KEY `idx_book_copy_book_id_copy_status` (`book_id`, `copy_status`),
    CONSTRAINT `ck_book_copy_01` CHECK (`copy_status` IN (0,1,2,3)),
    CONSTRAINT `ck_book_copy_02` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书馆藏副本表';

-- 插入5条图书馆藏副本数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `book_copy` (`id`, `book_id`, `copy_no`, `location`, `copy_status`, `version`, `create_time`, `update_time`) VALUES
(1, 1, 'COPY_DEMO_0001', '图书馆二层A区第1架', 0, 2, '2023-08-01 09:00:00', '2025-12-16 15:00:00'),
(2, 2, 'COPY_DEMO_0002', '图书馆二层A区第2架', 0, 2, '2023-08-01 09:00:00', '2025-12-17 15:00:00'),
(3, 3, 'COPY_DEMO_0003', '图书馆二层A区第3架', 0, 2, '2023-08-01 09:00:00', '2025-12-18 15:00:00'),
(4, 4, 'COPY_DEMO_0004', '图书馆二层A区第4架', 0, 2, '2023-08-01 09:00:00', '2025-12-19 15:00:00'),
(5, 5, 'COPY_DEMO_0005', '图书馆二层A区第5架', 0, 2, '2023-08-01 09:00:00', '2025-12-20 15:00:00');

-- ------------------------------------------------------------
-- 43. 图书借阅记录表 (book_loan)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `book_loan`;
CREATE TABLE `book_loan` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '借阅ID；自增长类型',
    `reader_id` BIGINT NOT NULL COMMENT '读者ID；user(id)；组合查询索引',
    `copy_id` BIGINT NOT NULL COMMENT '副本ID；book_copy(id)；事务锁定副本；同册仅一笔未还；组合查询索引',
    `external_loan_no` VARCHAR(64) DEFAULT NULL COMMENT '外部借阅号',
    `borrow_time` DATETIME NOT NULL COMMENT '借出时间',
    `due_time` DATETIME NOT NULL COMMENT '应还时间',
    `return_time` DATETIME DEFAULT NULL COMMENT '归还时间',
    `renew_count` TINYINT NOT NULL DEFAULT 0 COMMENT '续借次数',
    `renew_time` DATETIME DEFAULT NULL COMMENT '最近续借',
    `loan_status` TINYINT NOT NULL DEFAULT 0 COMMENT '借阅状态；0借阅中；1已归还；2挂失',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_book_loan_external_loan_no` (`external_loan_no`),
    KEY `idx_book_loan_reader_id_loan_status` (`reader_id`, `loan_status`),
    KEY `idx_book_loan_copy_id_loan_status` (`copy_id`, `loan_status`),
    CONSTRAINT `ck_book_loan_01` CHECK (`loan_status` IN (0,1,2)),
    CONSTRAINT `ck_book_loan_02` CHECK (`due_time` > `borrow_time`),
    CONSTRAINT `ck_book_loan_03` CHECK (`return_time` IS NULL OR `return_time` >= `borrow_time`),
    CONSTRAINT `ck_book_loan_04` CHECK (`renew_count` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书借阅记录表';

-- 插入5条图书借阅记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `book_loan` (`id`, `reader_id`, `copy_id`, `external_loan_no`, `borrow_time`, `due_time`, `return_time`, `renew_count`, `renew_time`, `loan_status`, `create_time`, `update_time`) VALUES
(1, 1, 1, 'LIB_DEMO_0001', '2025-12-02 10:00:00', '2026-01-02 18:00:00', '2025-12-16 15:00:00', 0, NULL, 1, '2025-12-02 10:00:00', '2025-12-16 15:00:00'),
(2, 1, 2, 'LIB_DEMO_0002', '2025-12-03 10:00:00', '2026-01-03 18:00:00', '2025-12-17 15:00:00', 0, NULL, 1, '2025-12-03 10:00:00', '2025-12-17 15:00:00'),
(3, 1, 3, 'LIB_DEMO_0003', '2025-12-04 10:00:00', '2026-01-04 18:00:00', '2025-12-18 15:00:00', 0, NULL, 1, '2025-12-04 10:00:00', '2025-12-18 15:00:00'),
(4, 1, 4, 'LIB_DEMO_0004', '2025-12-05 10:00:00', '2026-01-05 18:00:00', '2025-12-19 15:00:00', 0, NULL, 1, '2025-12-05 10:00:00', '2025-12-19 15:00:00'),
(5, 1, 5, 'LIB_DEMO_0005', '2025-12-06 10:00:00', '2026-01-06 18:00:00', '2025-12-20 15:00:00', 0, NULL, 1, '2025-12-06 10:00:00', '2025-12-20 15:00:00');

-- ------------------------------------------------------------
-- 44. 图书预约表 (book_reservation)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `book_reservation`;
CREATE TABLE `book_reservation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '预约ID；自增长类型',
    `reader_id` BIGINT NOT NULL COMMENT '读者ID；user(id)；锁定读者行；同书仅一条有效预约；组合查询索引',
    `book_id` BIGINT NOT NULL COMMENT '图书ID；book(id)；组合查询索引',
    `copy_id` BIGINT DEFAULT NULL COMMENT '留置副本ID；book_copy(id)',
    `request_key` VARCHAR(64) NOT NULL COMMENT '幂等键',
    `reserve_time` DATETIME NOT NULL COMMENT '预约时间',
    `expire_time` DATETIME DEFAULT NULL COMMENT '取书截止',
    `reserve_status` TINYINT NOT NULL DEFAULT 0 COMMENT '预约状态；0排队；1可取；2完成；3取消；4过期',
    `notify_time` DATETIME DEFAULT NULL COMMENT '通知时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_book_reservation_request_key` (`request_key`),
    KEY `idx_book_reservation_book_id_reserve_status_reserve_time` (`book_id`, `reserve_status`, `reserve_time`),
    KEY `idx_book_reservation_reader_id_book_id` (`reader_id`, `book_id`),
    KEY `fk_book_reservation_copy_id` (`copy_id`),
    CONSTRAINT `ck_book_reservation_01` CHECK (`reserve_status` IN (0,1,2,3,4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书预约表';

-- 插入5条图书预约数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `book_reservation` (`id`, `reader_id`, `book_id`, `copy_id`, `request_key`, `reserve_time`, `expire_time`, `reserve_status`, `notify_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, 'book_reserve_demo_001', '2025-12-01 09:00:00', '2025-12-04 18:00:00', 2, '2025-12-01 10:00:00', '2025-12-01 09:00:00', '2025-12-02 10:00:00'),
(2, 1, 2, 2, 'book_reserve_demo_002', '2025-12-02 09:00:00', '2025-12-05 18:00:00', 2, '2025-12-02 10:00:00', '2025-12-02 09:00:00', '2025-12-03 10:00:00'),
(3, 1, 3, 3, 'book_reserve_demo_003', '2025-12-03 09:00:00', '2025-12-06 18:00:00', 2, '2025-12-03 10:00:00', '2025-12-03 09:00:00', '2025-12-04 10:00:00'),
(4, 1, 4, 4, 'book_reserve_demo_004', '2025-12-04 09:00:00', '2025-12-07 18:00:00', 2, '2025-12-04 10:00:00', '2025-12-04 09:00:00', '2025-12-05 10:00:00'),
(5, 1, 5, 5, 'book_reserve_demo_005', '2025-12-05 09:00:00', '2025-12-08 18:00:00', 2, '2025-12-05 10:00:00', '2025-12-05 09:00:00', '2025-12-06 10:00:00');

-- ------------------------------------------------------------
-- 45. 通知公告表 (notice)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '通知ID；自增长类型',
    `notice_title` VARCHAR(128) NOT NULL COMMENT '通知标题',
    `content` TEXT NOT NULL COMMENT '通知内容',
    `publisher_id` BIGINT NOT NULL COMMENT '发布人ID；user(id)',
    `urgency_level` TINYINT NOT NULL DEFAULT 0 COMMENT '紧急等级；0普通；1重要；2紧急',
    `is_pinned` TINYINT NOT NULL DEFAULT 0 COMMENT '是否置顶；0否；1是',
    `need_ack` TINYINT NOT NULL DEFAULT 0 COMMENT '需要回执；0否；1是；紧急通知须为1',
    `start_time` DATETIME NOT NULL COMMENT '生效时间',
    `expire_time` DATETIME DEFAULT NULL COMMENT '失效时间',
    `publish_time` DATETIME DEFAULT NULL COMMENT '发布时间',
    `publish_status` TINYINT NOT NULL DEFAULT 0 COMMENT '发布状态；0草稿；1已发布；2撤回；组合查询索引',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    KEY `idx_notice_publish_status_publish_time` (`publish_status`, `publish_time`),
    KEY `fk_notice_publisher_id` (`publisher_id`),
    CONSTRAINT `ck_notice_01` CHECK (`urgency_level` IN (0,1,2)),
    CONSTRAINT `ck_notice_02` CHECK (`is_pinned` IN (0,1)),
    CONSTRAINT `ck_notice_03` CHECK (`need_ack` IN (0,1)),
    CONSTRAINT `ck_notice_04` CHECK (`publish_status` IN (0,1,2)),
    CONSTRAINT `ck_notice_05` CHECK (`urgency_level` <> 2 OR `need_ack` = 1),
    CONSTRAINT `ck_notice_06` CHECK (`expire_time` IS NULL OR `expire_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知公告表';

-- 插入5条通知公告数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `notice` (`id`, `notice_title`, `content`, `publisher_id`, `urgency_level`, `is_pinned`, `need_ack`, `start_time`, `expire_time`, `publish_time`, `publish_status`, `create_time`, `update_time`) VALUES
(1, '期末学习安排', '请查看本学期期末考试安排并按时参加考试。', 4, 0, 0, 0, '2025-12-11 09:00:00', '2026-01-18 18:00:00', '2025-12-11 09:00:00', 1, '2025-12-11 09:00:00', '2025-12-11 09:00:00'),
(2, '学院实践成果展示', '请关注计算机学院实践成果展示活动。', 4, 0, 0, 0, '2025-12-12 09:00:00', '2026-01-18 18:00:00', '2025-12-12 09:00:00', 1, '2025-12-12 09:00:00', '2025-12-12 09:00:00'),
(3, '班级材料提交提醒', '请本班学生按时提交学期总结材料。', 4, 0, 0, 0, '2025-12-13 09:00:00', '2026-01-18 18:00:00', '2025-12-13 09:00:00', 1, '2025-12-13 09:00:00', '2025-12-13 09:00:00'),
(4, '项目实训复习安排', '综合项目实训教学班已发布复习提示。', 4, 0, 0, 0, '2025-12-14 09:00:00', '2026-01-18 18:00:00', '2025-12-14 09:00:00', 1, '2025-12-14 09:00:00', '2025-12-14 09:00:00'),
(5, '校园安全提示', '请完成校园安全提示阅读并确认回执。', 4, 2, 1, 1, '2025-12-15 09:00:00', '2026-01-18 18:00:00', '2025-12-15 09:00:00', 1, '2025-12-15 09:00:00', '2025-12-15 09:00:00');

-- ------------------------------------------------------------
-- 46. 通知范围表 (notice_scope)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `notice_scope`;
CREATE TABLE `notice_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '范围ID；自增长类型',
    `notice_id` BIGINT NOT NULL COMMENT '通知ID；notice(id)；查询索引',
    `scope_type` TINYINT NOT NULL DEFAULT 1 COMMENT '范围类型；1全校；2组织；3班级；4教学班',
    `org_id` BIGINT DEFAULT NULL COMMENT '组织ID；org_unit(id)',
    `class_id` BIGINT DEFAULT NULL COMMENT '班级ID；school_class(id)',
    `teaching_class_id` BIGINT DEFAULT NULL COMMENT '教学班ID；teaching_class(id)；全校时均空；其他类型仅对应ID非空',
    `include_children` TINYINT NOT NULL DEFAULT 1 COMMENT '包含下级；0否；1是；仅组织范围有效',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_notice_scope_notice_id` (`notice_id`),
    KEY `fk_notice_scope_org_id` (`org_id`),
    KEY `fk_notice_scope_class_id` (`class_id`),
    KEY `fk_notice_scope_teaching_class_id` (`teaching_class_id`),
    CONSTRAINT `ck_notice_scope_01` CHECK (`scope_type` IN (1,2,3,4)),
    CONSTRAINT `ck_notice_scope_02` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_notice_scope_03` CHECK ((`scope_type` = 1 AND `org_id` IS NULL AND `class_id` IS NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 2 AND `org_id` IS NOT NULL AND `class_id` IS NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 3 AND `org_id` IS NULL AND `class_id` IS NOT NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 4 AND `org_id` IS NULL AND `class_id` IS NULL AND `teaching_class_id` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知范围表';

-- 插入5条通知范围数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `notice_scope` (`id`, `notice_id`, `scope_type`, `org_id`, `class_id`, `teaching_class_id`, `include_children`, `create_time`) VALUES
(1, 1, 1, NULL, NULL, NULL, 0, '2025-12-11 09:00:00'),
(2, 2, 2, 2, NULL, NULL, 1, '2025-12-12 09:00:00'),
(3, 3, 3, NULL, 1, NULL, 0, '2025-12-13 09:00:00'),
(4, 4, 4, NULL, NULL, 5, 0, '2025-12-14 09:00:00'),
(5, 5, 1, NULL, NULL, NULL, 0, '2025-12-15 09:00:00');

-- ------------------------------------------------------------
-- 47. 站内消息表 (message)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '消息ID；自增长类型',
    `message_title` VARCHAR(128) NOT NULL COMMENT '消息标题',
    `content` TEXT NOT NULL COMMENT '消息内容',
    `notice_id` BIGINT DEFAULT NULL COMMENT '通知ID；notice(id)',
    `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型；请假、成绩、选课、充值等',
    `biz_id` BIGINT DEFAULT NULL COMMENT '业务ID；按类型校验的逻辑引用',
    `event_key` VARCHAR(64) NOT NULL COMMENT '事件编码',
    `need_ack` TINYINT NOT NULL DEFAULT 0 COMMENT '需要回执；0否；1是',
    `expire_time` DATETIME DEFAULT NULL COMMENT '失效时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_message_event_key` (`event_key`),
    KEY `fk_message_notice_id` (`notice_id`),
    CONSTRAINT `ck_message_01` CHECK (`need_ack` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内消息表';

-- 插入5条站内消息数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `message` (`id`, `message_title`, `content`, `notice_id`, `biz_type`, `biz_id`, `event_key`, `need_ack`, `expire_time`, `create_time`) VALUES
(1, '期末学习安排', '请查看本学期期末考试安排并按时参加考试。', 1, 'notice', 1, 'notice_published_demo_001', 0, '2026-01-18 18:00:00', '2025-12-11 09:00:00'),
(2, '学院实践成果展示', '请关注计算机学院实践成果展示活动。', 2, 'notice', 2, 'notice_published_demo_002', 0, '2026-01-18 18:00:00', '2025-12-12 09:00:00'),
(3, '班级材料提交提醒', '请本班学生按时提交学期总结材料。', 3, 'notice', 3, 'notice_published_demo_003', 0, '2026-01-18 18:00:00', '2025-12-13 09:00:00'),
(4, '项目实训复习安排', '综合项目实训教学班已发布复习提示。', 4, 'notice', 4, 'notice_published_demo_004', 0, '2026-01-18 18:00:00', '2025-12-14 09:00:00'),
(5, '校园安全提示', '请完成校园安全提示阅读并确认回执。', 5, 'notice', 5, 'notice_published_demo_005', 1, '2026-01-18 18:00:00', '2025-12-15 09:00:00');

-- ------------------------------------------------------------
-- 48. 消息回执表 (message_receipt)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `message_receipt`;
CREATE TABLE `message_receipt` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '回执ID；自增长类型',
    `message_id` BIGINT NOT NULL COMMENT '消息ID；message(id)',
    `receiver_id` BIGINT NOT NULL COMMENT '接收人ID；user(id)；与消息ID联合唯一；组合查询索引',
    `delivery_status` TINYINT NOT NULL DEFAULT 0 COMMENT '送达状态；0待送；1已送；2失败',
    `delivered_time` DATETIME DEFAULT NULL COMMENT '送达时间',
    `read_time` DATETIME DEFAULT NULL COMMENT '阅读时间',
    `ack_time` DATETIME DEFAULT NULL COMMENT '确认时间',
    `retry_count` INT NOT NULL DEFAULT 0 COMMENT '重试次数',
    `error_message` VARCHAR(255) DEFAULT NULL COMMENT '失败原因',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_message_receipt_message_id_receiver_id` (`message_id`, `receiver_id`),
    KEY `idx_message_receipt_receiver_id_read_time` (`receiver_id`, `read_time`),
    CONSTRAINT `ck_message_receipt_01` CHECK (`delivery_status` IN (0,1,2)),
    CONSTRAINT `ck_message_receipt_02` CHECK (`retry_count` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息回执表';

-- 插入5条消息回执数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `message_receipt` (`id`, `message_id`, `receiver_id`, `delivery_status`, `delivered_time`, `read_time`, `ack_time`, `retry_count`, `error_message`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, '2025-12-11 09:00:02', '2025-12-11 12:00:00', NULL, 0, NULL, '2025-12-11 09:00:00', '2025-12-11 12:00:00'),
(2, 2, 1, 1, '2025-12-12 09:00:02', '2025-12-12 12:00:00', NULL, 0, NULL, '2025-12-12 09:00:00', '2025-12-12 12:00:00'),
(3, 3, 1, 1, '2025-12-13 09:00:02', '2025-12-13 12:00:00', NULL, 0, NULL, '2025-12-13 09:00:00', '2025-12-13 12:00:00'),
(4, 4, 1, 1, '2025-12-14 09:00:02', '2025-12-14 12:00:00', NULL, 0, NULL, '2025-12-14 09:00:00', '2025-12-14 12:00:00'),
(5, 5, 1, 1, '2025-12-15 09:00:02', '2025-12-15 12:00:00', '2025-12-15 12:01:00', 0, NULL, '2025-12-15 09:00:00', '2025-12-15 12:01:00');

-- ------------------------------------------------------------
-- 49. 文件上传记录表 (file_upload)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `file_upload`;
CREATE TABLE `file_upload` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '文件ID；自增长类型',
    `bucket_name` VARCHAR(64) NOT NULL COMMENT '存储桶',
    `object_key` VARCHAR(255) NOT NULL COMMENT '对象键；与存储桶联合唯一',
    `original_name` VARCHAR(255) NOT NULL COMMENT '原始文件名',
    `mime_type` VARCHAR(128) NOT NULL COMMENT '文件类型',
    `file_size` BIGINT NOT NULL COMMENT '文件大小；单位字节；上限100MB',
    `file_hash` VARCHAR(64) NOT NULL COMMENT '内容哈希；SHA-256',
    `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型；组合查询索引',
    `biz_id` BIGINT DEFAULT NULL COMMENT '业务ID；按类型校验；附件绑定后必填',
    `uploader_id` BIGINT NOT NULL COMMENT '上传人ID；user(id)',
    `scan_status` TINYINT NOT NULL DEFAULT 0 COMMENT '检测状态；0待检；1通过；2拒绝',
    `file_status` TINYINT NOT NULL DEFAULT 0 COMMENT '文件状态；0临时；1已绑定；2待清理',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_file_upload_bucket_name_object_key` (`bucket_name`, `object_key`),
    KEY `idx_file_upload_biz_type_biz_id` (`biz_type`, `biz_id`),
    KEY `fk_file_upload_uploader_id` (`uploader_id`),
    CONSTRAINT `ck_file_upload_01` CHECK (`scan_status` IN (0,1,2)),
    CONSTRAINT `ck_file_upload_02` CHECK (`file_status` IN (0,1,2)),
    CONSTRAINT `ck_file_upload_03` CHECK (`file_size` BETWEEN 0 AND 104857600),
    CONSTRAINT `ck_file_upload_04` CHECK (`file_status` <> 1 OR `biz_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件上传记录表';

-- 插入5条文件上传记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `file_upload` (`id`, `bucket_name`, `object_key`, `original_name`, `mime_type`, `file_size`, `file_hash`, `biz_type`, `biz_id`, `uploader_id`, `scan_status`, `file_status`, `create_time`, `update_time`) VALUES
(1, 'zhixiaotong-demo', 'course/1/lecture.txt', '程序设计基础讲义.txt', 'text/plain', 72, 'f3814acddffec2249238e3b5f860b5e50a3ed41dadf00e644b007833f6789f53', 'course_resource', 1, 2, 1, 1, '2023-09-03 09:00:00', '2023-09-04 09:00:00'),
(2, 'zhixiaotong-demo', 'course/2/lecture.txt', '面向对象程序设计讲义.txt', 'text/plain', 78, '2cbf145ea6eecf2f8ec20dff2d9c18ee356575dfadb0e30d9de06cf80f90a43d', 'course_resource', 2, 2, 1, 1, '2024-02-25 09:00:00', '2024-02-26 09:00:00'),
(3, 'zhixiaotong-demo', 'course/3/lecture.txt', '数据结构讲义.txt', 'text/plain', 66, '871c9828ea4afa1df8965cb1f7e9f83133e244d737ece528d91325b116d1539d', 'course_resource', 3, 2, 1, 1, '2024-09-01 09:00:00', '2024-09-02 09:00:00'),
(4, 'zhixiaotong-demo', 'course/4/lecture.txt', '数据库应用开发讲义.txt', 'text/plain', 75, 'f7ff5f60c00a043fa0d23f0fb31c6161b6c993a13d97f7fb36faf5eb1c974891', 'course_resource', 4, 2, 1, 1, '2025-02-23 09:00:00', '2025-02-24 09:00:00'),
(5, 'zhixiaotong-demo', 'course/5/lecture.txt', '综合项目实训讲义.txt', 'text/plain', 72, '3ff24c4182dcee5148e8fc86f15bd1fb849294ce084088fcea63af00383951b6', 'course_resource', 5, 2, 1, 1, '2025-08-31 09:00:00', '2025-09-01 09:00:00');

-- ------------------------------------------------------------
-- 50. 系统配置字典表 (system_config)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `system_config`;
CREATE TABLE `system_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '配置ID；自增长类型',
    `config_group` VARCHAR(64) NOT NULL COMMENT '配置分组',
    `config_key` VARCHAR(64) NOT NULL COMMENT '配置编码；与配置分组联合唯一',
    `config_name` VARCHAR(64) NOT NULL COMMENT '配置名称',
    `config_value` TEXT NOT NULL COMMENT '配置值；不保存明文密钥',
    `value_type` VARCHAR(16) NOT NULL COMMENT '值类型；string、number、bool或json',
    `description` VARCHAR(255) DEFAULT NULL COMMENT '配置说明',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序值',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '启用状态；0停用；1启用',
    `updater_id` BIGINT NOT NULL COMMENT '更新人ID；user(id)',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_system_config_config_group_config_key` (`config_group`, `config_key`),
    KEY `fk_system_config_updater_id` (`updater_id`),
    CONSTRAINT `ck_system_config_01` CHECK (`is_enabled` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置字典表';

-- 插入5条系统配置字典数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `system_config` (`id`, `config_group`, `config_key`, `config_name`, `config_value`, `value_type`, `description`, `sort_order`, `is_enabled`, `updater_id`, `create_time`, `update_time`) VALUES
(1, 'dictionary', 'course_type', '课程类别', '{"PROFESSIONAL_REQUIRED":"专业必修"}', 'json', '教学演示配置，正式使用时按学校制度调整。', 0, 1, 4, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 'dictionary', 'leave_type', '请假类型', '{"PERSONAL":"事假","SICK":"病假"}', 'json', '教学演示配置，正式使用时按学校制度调整。', 0, 1, 4, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 'dictionary', 'focus_type', '关注类别', '{"ACADEMIC_SUPPORT":"学习帮扶"}', 'json', '教学演示配置，正式使用时按学校制度调整。', 0, 1, 4, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 'dictionary', 'aid_type', '资助类型', '{"STUDY_GRANT":"实践助学"}', 'json', '教学演示配置，正式使用时按学校制度调整。', 0, 1, 4, '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 'grading', 'grade_point_rule', '绩点规则', '{"pass_score":60,"formula":"score < 60 ? 0 : min(4.0, score / 10 - 5)","round_scale":2}', 'json', '教学演示配置，正式使用时按学校制度调整。', 0, 1, 4, '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 51. 操作审计日志表 (audit_log)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `audit_log`;
CREATE TABLE `audit_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '日志ID；自增长类型',
    `operator_id` BIGINT DEFAULT NULL COMMENT '操作人ID；user(id)；系统任务或登录失败可空；组合查询索引',
    `action_type` VARCHAR(64) NOT NULL COMMENT '操作类型',
    `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型；组合查询索引',
    `biz_id` BIGINT DEFAULT NULL COMMENT '业务ID；逻辑引用；不随业务删除',
    `request_id` VARCHAR(64) NOT NULL COMMENT '请求标识',
    `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '来源地址',
    `change_data` JSON DEFAULT NULL COMMENT '变更摘要；保存脱敏前后值；不记凭据',
    `result_status` TINYINT NOT NULL DEFAULT 1 COMMENT '操作结果；0失败；1成功',
    `confirmed` TINYINT NOT NULL DEFAULT 0 COMMENT '二次确认；0否；1是',
    `operate_time` DATETIME NOT NULL COMMENT '操作时间',
    PRIMARY KEY (`id`),
    KEY `idx_audit_log_operator_id_operate_time` (`operator_id`, `operate_time`),
    KEY `idx_audit_log_biz_type_biz_id` (`biz_type`, `biz_id`),
    CONSTRAINT `ck_audit_log_01` CHECK (`result_status` IN (0,1)),
    CONSTRAINT `ck_audit_log_02` CHECK (`confirmed` IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计日志表';

-- 插入5条操作审计日志数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `audit_log` (`id`, `operator_id`, `action_type`, `biz_type`, `biz_id`, `request_id`, `ip_address`, `change_data`, `result_status`, `confirmed`, `operate_time`) VALUES
(1, 5, 'grade.publish', 'grade', 1, 'request_grade_publish_001', '192.0.2.10', '{"before":{"grade_status":1,"version":0},"after":{"grade_status":3,"version":1}}', 1, 1, '2024-01-16 16:00:00'),
(2, 5, 'grade.publish', 'grade', 2, 'request_grade_publish_002', '192.0.2.10', '{"before":{"grade_status":1,"version":0},"after":{"grade_status":3,"version":1}}', 1, 1, '2024-07-09 16:00:00'),
(3, 5, 'grade.publish', 'grade', 3, 'request_grade_publish_003', '192.0.2.10', '{"before":{"grade_status":1,"version":0},"after":{"grade_status":3,"version":1}}', 1, 1, '2025-01-14 16:00:00'),
(4, 5, 'grade.publish', 'grade', 4, 'request_grade_publish_004', '192.0.2.10', '{"before":{"grade_status":1,"version":0},"after":{"grade_status":3,"version":1}}', 1, 1, '2025-07-08 16:00:00'),
(5, 5, 'grade.publish', 'grade', 5, 'request_grade_publish_005', '192.0.2.10', '{"before":{"grade_status":1,"version":0},"after":{"grade_status":3,"version":1}}', 1, 1, '2026-01-13 16:00:00');

-- ------------------------------------------------------------
-- 52. 异步任务表 (async_task)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `async_task`;
CREATE TABLE `async_task` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '任务ID；自增长类型',
    `task_no` VARCHAR(64) NOT NULL COMMENT '任务编码',
    `task_type` VARCHAR(32) NOT NULL COMMENT '任务类型',
    `creator_id` BIGINT NOT NULL COMMENT '发起人ID；user(id)；组合查询索引',
    `task_params` JSON NOT NULL COMMENT '任务参数；记录过滤条件和数据权限快照',
    `input_file_id` BIGINT DEFAULT NULL COMMENT '输入文件ID；file_upload(id)',
    `result_file_id` BIGINT DEFAULT NULL COMMENT '结果文件ID；file_upload(id)',
    `task_status` TINYINT NOT NULL DEFAULT 0 COMMENT '任务状态；0等待；1执行中；2成功；3失败；4取消',
    `progress` TINYINT NOT NULL DEFAULT 0 COMMENT '完成进度；0至100',
    `error_message` VARCHAR(255) DEFAULT NULL COMMENT '失败原因',
    `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
    `finish_time` DATETIME DEFAULT NULL COMMENT '结束时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_async_task_task_no` (`task_no`),
    KEY `idx_async_task_creator_id_task_status` (`creator_id`, `task_status`),
    KEY `fk_async_task_input_file_id` (`input_file_id`),
    KEY `fk_async_task_result_file_id` (`result_file_id`),
    CONSTRAINT `ck_async_task_01` CHECK (`task_status` IN (0,1,2,3,4)),
    CONSTRAINT `ck_async_task_02` CHECK (`progress` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='异步任务表';

-- 插入5条异步任务数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `async_task` (`id`, `task_no`, `task_type`, `creator_id`, `task_params`, `input_file_id`, `result_file_id`, `task_status`, `progress`, `error_message`, `start_time`, `finish_time`, `create_time`, `update_time`) VALUES
(1, 'EXPORT_DEMO_001', 'grade_export', 5, '{"semester_id":1,"class_ids":[1],"permission_snapshot":{"role":"ACADEMIC_SECRETARY","class_ids":[1]}}', NULL, NULL, 0, 0, NULL, NULL, NULL, '2026-01-18 17:01:00', '2026-01-18 17:01:00'),
(2, 'EXPORT_DEMO_002', 'grade_export', 5, '{"semester_id":2,"class_ids":[1],"permission_snapshot":{"role":"ACADEMIC_SECRETARY","class_ids":[1]}}', NULL, NULL, 0, 0, NULL, NULL, NULL, '2026-01-18 17:02:00', '2026-01-18 17:02:00'),
(3, 'EXPORT_DEMO_003', 'grade_export', 5, '{"semester_id":3,"class_ids":[1],"permission_snapshot":{"role":"ACADEMIC_SECRETARY","class_ids":[1]}}', NULL, NULL, 0, 0, NULL, NULL, NULL, '2026-01-18 17:03:00', '2026-01-18 17:03:00'),
(4, 'EXPORT_DEMO_004', 'grade_export', 5, '{"semester_id":4,"class_ids":[1],"permission_snapshot":{"role":"ACADEMIC_SECRETARY","class_ids":[1]}}', NULL, NULL, 0, 0, NULL, NULL, NULL, '2026-01-18 17:04:00', '2026-01-18 17:04:00'),
(5, 'EXPORT_DEMO_005', 'grade_export', 5, '{"semester_id":5,"class_ids":[1],"permission_snapshot":{"role":"ACADEMIC_SECRETARY","class_ids":[1]}}', NULL, NULL, 0, 0, NULL, NULL, NULL, '2026-01-18 17:05:00', '2026-01-18 17:05:00');

-- ------------------------------------------------------------
-- 53. 可靠消息事件表 (outbox_event)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `outbox_event`;
CREATE TABLE `outbox_event` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '事件ID；自增长类型',
    `event_key` VARCHAR(64) NOT NULL COMMENT '事件编码',
    `event_type` VARCHAR(64) NOT NULL COMMENT '事件类型',
    `payload` JSON NOT NULL COMMENT '事件内容；与业务同事务写入；不含明文敏感信息',
    `send_status` TINYINT NOT NULL DEFAULT 0 COMMENT '投递状态；0待发；1发送中；2已确认；3失败；组合查询索引',
    `retry_count` INT NOT NULL DEFAULT 0 COMMENT '重试次数',
    `next_retry_time` DATETIME DEFAULT NULL COMMENT '下次重试',
    `lock_until` DATETIME DEFAULT NULL COMMENT '锁定截止；工作进程中断后可重领',
    `confirmed_time` DATETIME DEFAULT NULL COMMENT '确认时间',
    `error_message` VARCHAR(255) DEFAULT NULL COMMENT '错误摘要',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_outbox_event_event_key` (`event_key`),
    KEY `idx_outbox_event_send_status_next_retry_time` (`send_status`, `next_retry_time`),
    CONSTRAINT `ck_outbox_event_01` CHECK (`send_status` IN (0,1,2,3)),
    CONSTRAINT `ck_outbox_event_02` CHECK (`retry_count` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='可靠消息事件表';

-- 插入5条可靠消息事件数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `outbox_event` (`id`, `event_key`, `event_type`, `payload`, `send_status`, `retry_count`, `next_retry_time`, `lock_until`, `confirmed_time`, `error_message`, `create_time`, `update_time`) VALUES
(1, 'notice_published_demo_001', 'notice.published', '{"notice_id":1,"message_id":1,"receiver_ids":[1]}', 2, 0, NULL, NULL, '2025-12-11 09:00:03', NULL, '2025-12-11 09:00:00', '2025-12-11 09:00:03'),
(2, 'notice_published_demo_002', 'notice.published', '{"notice_id":2,"message_id":2,"receiver_ids":[1]}', 2, 0, NULL, NULL, '2025-12-12 09:00:03', NULL, '2025-12-12 09:00:00', '2025-12-12 09:00:03'),
(3, 'notice_published_demo_003', 'notice.published', '{"notice_id":3,"message_id":3,"receiver_ids":[1]}', 2, 0, NULL, NULL, '2025-12-13 09:00:03', NULL, '2025-12-13 09:00:00', '2025-12-13 09:00:03'),
(4, 'notice_published_demo_004', 'notice.published', '{"notice_id":4,"message_id":4,"receiver_ids":[1]}', 2, 0, NULL, NULL, '2025-12-14 09:00:03', NULL, '2025-12-14 09:00:00', '2025-12-14 09:00:03'),
(5, 'notice_published_demo_005', 'notice.published', '{"notice_id":5,"message_id":5,"receiver_ids":[1]}', 2, 0, NULL, NULL, '2025-12-15 09:00:03', NULL, '2025-12-15 09:00:00', '2025-12-15 09:00:03');

-- ------------------------------------------------------------
-- 54. 用户设备表 (device)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `device`;
CREATE TABLE `device` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '设备ID；自增长类型',
    `user_id` BIGINT NOT NULL COMMENT '用户ID；user(id)',
    `device_code` VARCHAR(128) NOT NULL COMMENT '设备标识；存储脱敏标识；与用户ID联合唯一',
    `device_name` VARCHAR(64) NOT NULL COMMENT '设备名称',
    `device_type` VARCHAR(32) NOT NULL COMMENT '设备类型；手机、平板、手表或智慧屏',
    `push_token` VARCHAR(512) DEFAULT NULL COMMENT '推送标识；加密保存',
    `trust_status` TINYINT NOT NULL DEFAULT 0 COMMENT '信任状态；0未认证；1可信；2撤销',
    `last_seen_time` DATETIME DEFAULT NULL COMMENT '最近在线',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_device_user_id_device_code` (`user_id`, `device_code`),
    CONSTRAINT `ck_device_01` CHECK (`trust_status` IN (0,1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户设备表';

-- 插入5条用户设备数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `device` (`id`, `user_id`, `device_code`, `device_name`, `device_type`, `push_token`, `trust_status`, `last_seen_time`, `create_time`, `update_time`) VALUES
(1, 1, 'device_demo_001', '学习手机', 'phone', NULL, 1, '2026-01-18 17:00:00', '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(2, 1, 'device_demo_002', '学习平板', 'tablet', NULL, 1, '2026-01-18 17:00:00', '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(3, 1, 'device_demo_003', '课堂手表', 'watch', NULL, 1, '2026-01-18 17:00:00', '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(4, 1, 'device_demo_004', '宿舍智慧屏', 'smart_screen', NULL, 1, '2026-01-18 17:00:00', '2023-08-01 09:00:00', '2023-08-01 09:00:00'),
(5, 1, 'device_demo_005', '备用平板', 'tablet', NULL, 1, '2026-01-18 17:00:00', '2023-08-01 09:00:00', '2023-08-01 09:00:00');

-- ------------------------------------------------------------
-- 55. 跨设备流转任务表 (continuation)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `continuation`;
CREATE TABLE `continuation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '流转ID；自增长类型',
    `user_id` BIGINT NOT NULL COMMENT '用户ID；user(id)；组合查询索引',
    `source_device_id` BIGINT NOT NULL COMMENT '源设备ID；device(id)',
    `target_device_id` BIGINT DEFAULT NULL COMMENT '目标设备ID；device(id)；接收前校验属于同一用户',
    `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型',
    `biz_id` BIGINT NOT NULL COMMENT '业务ID；逻辑引用；重新校验业务权限',
    `scope_data` JSON NOT NULL COMMENT '授权范围；最小必要字段；不可扩大权限',
    `token_hash` VARCHAR(64) NOT NULL COMMENT '流转凭证哈希；一次性凭证；仅存哈希',
    `task_status` TINYINT NOT NULL DEFAULT 0 COMMENT '流转状态；0待接收；1已接收；2完成；3过期；4撤销',
    `expire_time` DATETIME NOT NULL COMMENT '失效时间',
    `accept_time` DATETIME DEFAULT NULL COMMENT '接收时间',
    `reclaim_time` DATETIME DEFAULT NULL COMMENT '回收时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_continuation_token_hash` (`token_hash`),
    KEY `idx_continuation_user_id_task_status` (`user_id`, `task_status`),
    KEY `fk_continuation_source_device_id` (`source_device_id`),
    KEY `fk_continuation_target_device_id` (`target_device_id`),
    CONSTRAINT `ck_continuation_01` CHECK (`task_status` IN (0,1,2,3,4)),
    CONSTRAINT `ck_continuation_02` CHECK (`target_device_id` IS NULL OR `source_device_id` <> `target_device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='跨设备流转任务表';

-- 插入5条跨设备流转任务数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `continuation` (`id`, `user_id`, `source_device_id`, `target_device_id`, `biz_type`, `biz_id`, `scope_data`, `token_hash`, `task_status`, `expire_time`, `accept_time`, `reclaim_time`, `create_time`, `update_time`) VALUES
(1, 1, 1, 2, 'course_resource', 5, '{"resource_id":5,"actions":["read"],"fields":["resource_title","file_id"]}', '45808a22bc7e1664c975cc73c4ee0b026c147f9578166c03dd359b0a7450c034', 2, '2026-01-18 16:08:00', '2026-01-18 16:05:10', '2026-01-18 16:05:30', '2026-01-18 16:05:00', '2026-01-18 16:05:30'),
(2, 1, 2, 3, 'course_resource', 5, '{"resource_id":5,"actions":["read"],"fields":["resource_title","file_id"]}', 'c9201c011dbbe9dd3b201c672db4a063b36dc578e546b712367e93819cba7a92', 2, '2026-01-18 16:13:00', '2026-01-18 16:10:10', '2026-01-18 16:10:30', '2026-01-18 16:10:00', '2026-01-18 16:10:30'),
(3, 1, 3, 4, 'course_resource', 5, '{"resource_id":5,"actions":["read"],"fields":["resource_title","file_id"]}', '9c3073fabb4f10554959ab52ac9ba8cff2f8677cb80d7b7979cb25b3f2b6d0e0', 2, '2026-01-18 16:18:00', '2026-01-18 16:15:10', '2026-01-18 16:15:30', '2026-01-18 16:15:00', '2026-01-18 16:15:30'),
(4, 1, 4, 5, 'course_resource', 5, '{"resource_id":5,"actions":["read"],"fields":["resource_title","file_id"]}', '92e2602f85db8d6811f9e7aed128a302093c123aaa41c1d12ed5e90edf124f32', 2, '2026-01-18 16:23:00', '2026-01-18 16:20:10', '2026-01-18 16:20:30', '2026-01-18 16:20:00', '2026-01-18 16:20:30'),
(5, 1, 5, 1, 'course_resource', 5, '{"resource_id":5,"actions":["read"],"fields":["resource_title","file_id"]}', 'ce08ccdd76deceb37e72add293f73f59e52ed072484ee92e64745efbd2d148ee', 2, '2026-01-18 16:28:00', '2026-01-18 16:25:10', '2026-01-18 16:25:30', '2026-01-18 16:25:00', '2026-01-18 16:25:30');

-- ------------------------------------------------------------
-- 56. 课程签到任务表 (attendance_task)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `attendance_task`;
CREATE TABLE `attendance_task` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '签到任务ID；自增长类型',
    `timetable_id` BIGINT NOT NULL COMMENT '课表ID；timetable(id)',
    `creator_id` BIGINT NOT NULL COMMENT '发起人ID；user(id)',
    `class_date` DATE NOT NULL COMMENT '上课日期；与课表ID联合唯一',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME NOT NULL COMMENT '截止时间',
    `code_hash` VARCHAR(64) NOT NULL COMMENT '签到码哈希；短期凭证；仅存哈希',
    `task_status` TINYINT NOT NULL DEFAULT 0 COMMENT '任务状态；0未开；1开放；2结束',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_attendance_task_timetable_id_class_date` (`timetable_id`, `class_date`),
    KEY `fk_attendance_task_creator_id` (`creator_id`),
    CONSTRAINT `ck_attendance_task_01` CHECK (`task_status` IN (0,1,2)),
    CONSTRAINT `ck_attendance_task_02` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程签到任务表';

-- 插入5条课程签到任务数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `attendance_task` (`id`, `timetable_id`, `creator_id`, `class_date`, `start_time`, `end_time`, `code_hash`, `task_status`, `create_time`, `update_time`) VALUES
(1, 1, 2, '2023-09-11', '2023-09-11 07:55:00', '2023-09-11 08:10:00', '735de36b1fba0db089147ecff81c85477829940643de3868e83b2464e096fb00', 2, '2023-09-11 07:50:00', '2023-09-11 08:10:00'),
(2, 2, 2, '2024-03-04', '2024-03-04 07:55:00', '2024-03-04 08:10:00', '6134e2f62921eb25a9aaee7486994154f3f0436b519b7bb93ac9b231e6051390', 2, '2024-03-04 07:50:00', '2024-03-04 08:10:00'),
(3, 3, 2, '2024-09-09', '2024-09-09 07:55:00', '2024-09-09 08:10:00', '4ddffd9f4b07f87579656c67b593741657066e75a6d3453a3337b016ad7dab48', 2, '2024-09-09 07:50:00', '2024-09-09 08:10:00'),
(4, 4, 2, '2025-03-03', '2025-03-03 07:55:00', '2025-03-03 08:10:00', '0e49f4a494d3edf2ce52f2062021e59b1a230ca70f8c7c707fed4b9923d17d65', 2, '2025-03-03 07:50:00', '2025-03-03 08:10:00'),
(5, 5, 2, '2025-09-08', '2025-09-08 07:55:00', '2025-09-08 08:10:00', '2f8a81da2d4485e88de7287e3a01078060b27d75a5529195a1abb45b13c1047d', 2, '2025-09-08 07:50:00', '2025-09-08 08:10:00');

-- ------------------------------------------------------------
-- 57. 课程签到记录表 (attendance_record)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `attendance_record`;
CREATE TABLE `attendance_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '签到ID；自增长类型',
    `task_id` BIGINT NOT NULL COMMENT '签到任务ID；attendance_task(id)',
    `student_id` BIGINT NOT NULL COMMENT '学生ID；user(id)；与签到任务ID联合唯一',
    `sign_status` TINYINT NOT NULL DEFAULT 0 COMMENT '签到结果；0待签；1已签；2迟到；3请假；4缺勤',
    `sign_time` DATETIME DEFAULT NULL COMMENT '签到时间',
    `device_id` BIGINT DEFAULT NULL COMMENT '设备ID；device(id)',
    `remark` VARCHAR(255) DEFAULT NULL COMMENT '备注；须验证在课名单和任务有效期',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间；更新时由服务端写入',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_attendance_record_task_id_student_id` (`task_id`, `student_id`),
    KEY `fk_attendance_record_student_id` (`student_id`),
    KEY `fk_attendance_record_device_id` (`device_id`),
    CONSTRAINT `ck_attendance_record_01` CHECK (`sign_status` IN (0,1,2,3,4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程签到记录表';

-- 插入5条课程签到记录数据（虚构示例，显式指定ID以保持关联一致）
INSERT INTO `attendance_record` (`id`, `task_id`, `student_id`, `sign_status`, `sign_time`, `device_id`, `remark`, `create_time`, `update_time`) VALUES
(1, 1, 1, 1, '2023-09-11 07:59:00', 1, '课堂签到成功', '2023-09-11 07:59:00', '2023-09-11 07:59:00'),
(2, 2, 1, 1, '2024-03-04 07:59:00', 1, '课堂签到成功', '2024-03-04 07:59:00', '2024-03-04 07:59:00'),
(3, 3, 1, 1, '2024-09-09 07:59:00', 1, '课堂签到成功', '2024-09-09 07:59:00', '2024-09-09 07:59:00'),
(4, 4, 1, 1, '2025-03-03 07:59:00', 1, '课堂签到成功', '2025-03-03 07:59:00', '2025-03-03 07:59:00'),
(5, 5, 1, 1, '2025-09-08 07:59:00', 1, '课堂签到成功', '2025-09-08 07:59:00', '2025-09-08 07:59:00');

-- ------------------------------------------------------------
-- 外键约束（全部表及数据建立后执行）
-- ------------------------------------------------------------
-- 开启检查后再ADD FOREIGN KEY，以校验已有示例记录；仅将检查开关设为1不会回查历史数据。
SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE `user` ADD CONSTRAINT `fk_user_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `user` ADD CONSTRAINT `fk_user_class_id` FOREIGN KEY (`class_id`) REFERENCES `school_class` (`id`);
ALTER TABLE `user` ADD CONSTRAINT `fk_user_avatar_id` FOREIGN KEY (`avatar_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `org_unit` ADD CONSTRAINT `fk_org_unit_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `school_class` ADD CONSTRAINT `fk_school_class_grade_id` FOREIGN KEY (`grade_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `permission` ADD CONSTRAINT `fk_permission_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `permission` (`id`);
ALTER TABLE `user_role` ADD CONSTRAINT `fk_user_role_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);
ALTER TABLE `user_role` ADD CONSTRAINT `fk_user_role_role_id` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`);
ALTER TABLE `role_permission` ADD CONSTRAINT `fk_role_permission_role_id` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`);
ALTER TABLE `role_permission` ADD CONSTRAINT `fk_role_permission_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`);
ALTER TABLE `user_scope` ADD CONSTRAINT `fk_user_scope_user_role_id` FOREIGN KEY (`user_role_id`) REFERENCES `user_role` (`id`);
ALTER TABLE `user_scope` ADD CONSTRAINT `fk_user_scope_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `user_scope` ADD CONSTRAINT `fk_user_scope_class_id` FOREIGN KEY (`class_id`) REFERENCES `school_class` (`id`);
ALTER TABLE `counselor_class` ADD CONSTRAINT `fk_counselor_class_counselor_id` FOREIGN KEY (`counselor_id`) REFERENCES `user` (`id`);
ALTER TABLE `counselor_class` ADD CONSTRAINT `fk_counselor_class_class_id` FOREIGN KEY (`class_id`) REFERENCES `school_class` (`id`);
ALTER TABLE `course` ADD CONSTRAINT `fk_course_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `course_prereq` ADD CONSTRAINT `fk_course_prereq_course_id` FOREIGN KEY (`course_id`) REFERENCES `course` (`id`);
ALTER TABLE `course_prereq` ADD CONSTRAINT `fk_course_prereq_prereq_id` FOREIGN KEY (`prereq_id`) REFERENCES `course` (`id`);
ALTER TABLE `teaching_class` ADD CONSTRAINT `fk_teaching_class_course_id` FOREIGN KEY (`course_id`) REFERENCES `course` (`id`);
ALTER TABLE `teaching_class` ADD CONSTRAINT `fk_teaching_class_semester_id` FOREIGN KEY (`semester_id`) REFERENCES `semester` (`id`);
ALTER TABLE `teaching_class` ADD CONSTRAINT `fk_teaching_class_teacher_id` FOREIGN KEY (`teacher_id`) REFERENCES `user` (`id`);
ALTER TABLE `timetable` ADD CONSTRAINT `fk_timetable_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `timetable` ADD CONSTRAINT `fk_timetable_classroom_id` FOREIGN KEY (`classroom_id`) REFERENCES `classroom` (`id`);
ALTER TABLE `selection_batch` ADD CONSTRAINT `fk_selection_batch_semester_id` FOREIGN KEY (`semester_id`) REFERENCES `semester` (`id`);
ALTER TABLE `batch_course` ADD CONSTRAINT `fk_batch_course_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `selection_batch` (`id`);
ALTER TABLE `batch_course` ADD CONSTRAINT `fk_batch_course_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `selection_scope` ADD CONSTRAINT `fk_selection_scope_batch_course_id` FOREIGN KEY (`batch_course_id`) REFERENCES `batch_course` (`id`);
ALTER TABLE `selection_scope` ADD CONSTRAINT `fk_selection_scope_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `selection_scope` ADD CONSTRAINT `fk_selection_scope_class_id` FOREIGN KEY (`class_id`) REFERENCES `school_class` (`id`);
ALTER TABLE `enrollment` ADD CONSTRAINT `fk_enrollment_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `enrollment` ADD CONSTRAINT `fk_enrollment_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `enrollment` ADD CONSTRAINT `fk_enrollment_batch_course_id` FOREIGN KEY (`batch_course_id`) REFERENCES `batch_course` (`id`);
ALTER TABLE `course_resource` ADD CONSTRAINT `fk_course_resource_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `course_resource` ADD CONSTRAINT `fk_course_resource_file_id` FOREIGN KEY (`file_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `course_resource` ADD CONSTRAINT `fk_course_resource_uploader_id` FOREIGN KEY (`uploader_id`) REFERENCES `user` (`id`);
ALTER TABLE `assignment` ADD CONSTRAINT `fk_assignment_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `assignment` ADD CONSTRAINT `fk_assignment_teacher_id` FOREIGN KEY (`teacher_id`) REFERENCES `user` (`id`);
ALTER TABLE `submission` ADD CONSTRAINT `fk_submission_assignment_id` FOREIGN KEY (`assignment_id`) REFERENCES `assignment` (`id`);
ALTER TABLE `submission` ADD CONSTRAINT `fk_submission_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `submission` ADD CONSTRAINT `fk_submission_grader_id` FOREIGN KEY (`grader_id`) REFERENCES `user` (`id`);
ALTER TABLE `grade` ADD CONSTRAINT `fk_grade_enrollment_id` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollment` (`id`);
ALTER TABLE `grade` ADD CONSTRAINT `fk_grade_review_id` FOREIGN KEY (`review_id`) REFERENCES `grade_review` (`id`);
ALTER TABLE `grade` ADD CONSTRAINT `fk_grade_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `user` (`id`);
ALTER TABLE `grade_review` ADD CONSTRAINT `fk_grade_review_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `grade_review` ADD CONSTRAINT `fk_grade_review_submitter_id` FOREIGN KEY (`submitter_id`) REFERENCES `user` (`id`);
ALTER TABLE `grade_review` ADD CONSTRAINT `fk_grade_review_reviewer_id` FOREIGN KEY (`reviewer_id`) REFERENCES `user` (`id`);
ALTER TABLE `grade_change` ADD CONSTRAINT `fk_grade_change_grade_id` FOREIGN KEY (`grade_id`) REFERENCES `grade` (`id`);
ALTER TABLE `grade_change` ADD CONSTRAINT `fk_grade_change_applicant_id` FOREIGN KEY (`applicant_id`) REFERENCES `user` (`id`);
ALTER TABLE `grade_change` ADD CONSTRAINT `fk_grade_change_reviewer_id` FOREIGN KEY (`reviewer_id`) REFERENCES `user` (`id`);
ALTER TABLE `exam_plan` ADD CONSTRAINT `fk_exam_plan_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `exam_plan` ADD CONSTRAINT `fk_exam_plan_classroom_id` FOREIGN KEY (`classroom_id`) REFERENCES `classroom` (`id`);
ALTER TABLE `exam_plan` ADD CONSTRAINT `fk_exam_plan_invigilator_id` FOREIGN KEY (`invigilator_id`) REFERENCES `user` (`id`);
ALTER TABLE `exam_plan` ADD CONSTRAINT `fk_exam_plan_assistant_id` FOREIGN KEY (`assistant_id`) REFERENCES `user` (`id`);
ALTER TABLE `teaching_evaluation` ADD CONSTRAINT `fk_teaching_evaluation_enrollment_id` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollment` (`id`);
ALTER TABLE `leave_request` ADD CONSTRAINT `fk_leave_request_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `leave_request` ADD CONSTRAINT `fk_leave_request_closer_id` FOREIGN KEY (`closer_id`) REFERENCES `user` (`id`);
ALTER TABLE `leave_approval` ADD CONSTRAINT `fk_leave_approval_leave_id` FOREIGN KEY (`leave_id`) REFERENCES `leave_request` (`id`);
ALTER TABLE `leave_approval` ADD CONSTRAINT `fk_leave_approval_approver_id` FOREIGN KEY (`approver_id`) REFERENCES `user` (`id`);
ALTER TABLE `student_record` ADD CONSTRAINT `fk_student_record_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `student_record` ADD CONSTRAINT `fk_student_record_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `user` (`id`);
ALTER TABLE `dorm_check` ADD CONSTRAINT `fk_dorm_check_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `dorm_check` ADD CONSTRAINT `fk_dorm_check_checker_id` FOREIGN KEY (`checker_id`) REFERENCES `user` (`id`);
ALTER TABLE `student_focus` ADD CONSTRAINT `fk_student_focus_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `student_focus` ADD CONSTRAINT `fk_student_focus_owner_id` FOREIGN KEY (`owner_id`) REFERENCES `user` (`id`);
ALTER TABLE `aid_batch` ADD CONSTRAINT `fk_aid_batch_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `aid_batch` ADD CONSTRAINT `fk_aid_batch_semester_id` FOREIGN KEY (`semester_id`) REFERENCES `semester` (`id`);
ALTER TABLE `aid_application` ADD CONSTRAINT `fk_aid_application_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `aid_batch` (`id`);
ALTER TABLE `aid_application` ADD CONSTRAINT `fk_aid_application_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `aid_review` ADD CONSTRAINT `fk_aid_review_application_id` FOREIGN KEY (`application_id`) REFERENCES `aid_application` (`id`);
ALTER TABLE `aid_review` ADD CONSTRAINT `fk_aid_review_reviewer_id` FOREIGN KEY (`reviewer_id`) REFERENCES `user` (`id`);
ALTER TABLE `service_application` ADD CONSTRAINT `fk_service_application_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `service_application` ADD CONSTRAINT `fk_service_application_result_file_id` FOREIGN KEY (`result_file_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `service_step` ADD CONSTRAINT `fk_service_step_application_id` FOREIGN KEY (`application_id`) REFERENCES `service_application` (`id`);
ALTER TABLE `service_step` ADD CONSTRAINT `fk_service_step_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `service_step` ADD CONSTRAINT `fk_service_step_handler_id` FOREIGN KEY (`handler_id`) REFERENCES `user` (`id`);
ALTER TABLE `card_account` ADD CONSTRAINT `fk_card_account_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);
ALTER TABLE `recharge_order` ADD CONSTRAINT `fk_recharge_order_account_id` FOREIGN KEY (`account_id`) REFERENCES `card_account` (`id`);
ALTER TABLE `card_transaction` ADD CONSTRAINT `fk_card_transaction_account_id` FOREIGN KEY (`account_id`) REFERENCES `card_account` (`id`);
ALTER TABLE `card_transaction` ADD CONSTRAINT `fk_card_transaction_recharge_id` FOREIGN KEY (`recharge_id`) REFERENCES `recharge_order` (`id`);
ALTER TABLE `book` ADD CONSTRAINT `fk_book_cover_id` FOREIGN KEY (`cover_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `book_copy` ADD CONSTRAINT `fk_book_copy_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`);
ALTER TABLE `book_loan` ADD CONSTRAINT `fk_book_loan_reader_id` FOREIGN KEY (`reader_id`) REFERENCES `user` (`id`);
ALTER TABLE `book_loan` ADD CONSTRAINT `fk_book_loan_copy_id` FOREIGN KEY (`copy_id`) REFERENCES `book_copy` (`id`);
ALTER TABLE `book_reservation` ADD CONSTRAINT `fk_book_reservation_reader_id` FOREIGN KEY (`reader_id`) REFERENCES `user` (`id`);
ALTER TABLE `book_reservation` ADD CONSTRAINT `fk_book_reservation_book_id` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`);
ALTER TABLE `book_reservation` ADD CONSTRAINT `fk_book_reservation_copy_id` FOREIGN KEY (`copy_id`) REFERENCES `book_copy` (`id`);
ALTER TABLE `notice` ADD CONSTRAINT `fk_notice_publisher_id` FOREIGN KEY (`publisher_id`) REFERENCES `user` (`id`);
ALTER TABLE `notice_scope` ADD CONSTRAINT `fk_notice_scope_notice_id` FOREIGN KEY (`notice_id`) REFERENCES `notice` (`id`);
ALTER TABLE `notice_scope` ADD CONSTRAINT `fk_notice_scope_org_id` FOREIGN KEY (`org_id`) REFERENCES `org_unit` (`id`);
ALTER TABLE `notice_scope` ADD CONSTRAINT `fk_notice_scope_class_id` FOREIGN KEY (`class_id`) REFERENCES `school_class` (`id`);
ALTER TABLE `notice_scope` ADD CONSTRAINT `fk_notice_scope_teaching_class_id` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`id`);
ALTER TABLE `message` ADD CONSTRAINT `fk_message_notice_id` FOREIGN KEY (`notice_id`) REFERENCES `notice` (`id`);
ALTER TABLE `message_receipt` ADD CONSTRAINT `fk_message_receipt_message_id` FOREIGN KEY (`message_id`) REFERENCES `message` (`id`);
ALTER TABLE `message_receipt` ADD CONSTRAINT `fk_message_receipt_receiver_id` FOREIGN KEY (`receiver_id`) REFERENCES `user` (`id`);
ALTER TABLE `file_upload` ADD CONSTRAINT `fk_file_upload_uploader_id` FOREIGN KEY (`uploader_id`) REFERENCES `user` (`id`);
ALTER TABLE `system_config` ADD CONSTRAINT `fk_system_config_updater_id` FOREIGN KEY (`updater_id`) REFERENCES `user` (`id`);
ALTER TABLE `audit_log` ADD CONSTRAINT `fk_audit_log_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `user` (`id`);
ALTER TABLE `async_task` ADD CONSTRAINT `fk_async_task_creator_id` FOREIGN KEY (`creator_id`) REFERENCES `user` (`id`);
ALTER TABLE `async_task` ADD CONSTRAINT `fk_async_task_input_file_id` FOREIGN KEY (`input_file_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `async_task` ADD CONSTRAINT `fk_async_task_result_file_id` FOREIGN KEY (`result_file_id`) REFERENCES `file_upload` (`id`);
ALTER TABLE `device` ADD CONSTRAINT `fk_device_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);
ALTER TABLE `continuation` ADD CONSTRAINT `fk_continuation_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);
ALTER TABLE `continuation` ADD CONSTRAINT `fk_continuation_source_device_id` FOREIGN KEY (`source_device_id`) REFERENCES `device` (`id`);
ALTER TABLE `continuation` ADD CONSTRAINT `fk_continuation_target_device_id` FOREIGN KEY (`target_device_id`) REFERENCES `device` (`id`);
ALTER TABLE `attendance_task` ADD CONSTRAINT `fk_attendance_task_timetable_id` FOREIGN KEY (`timetable_id`) REFERENCES `timetable` (`id`);
ALTER TABLE `attendance_task` ADD CONSTRAINT `fk_attendance_task_creator_id` FOREIGN KEY (`creator_id`) REFERENCES `user` (`id`);
ALTER TABLE `attendance_record` ADD CONSTRAINT `fk_attendance_record_task_id` FOREIGN KEY (`task_id`) REFERENCES `attendance_task` (`id`);
ALTER TABLE `attendance_record` ADD CONSTRAINT `fk_attendance_record_student_id` FOREIGN KEY (`student_id`) REFERENCES `user` (`id`);
ALTER TABLE `attendance_record` ADD CONSTRAINT `fk_attendance_record_device_id` FOREIGN KEY (`device_id`) REFERENCES `device` (`id`);

-- 恢复执行前的外键检查设置。正常业务连接应始终启用外键检查。
SET FOREIGN_KEY_CHECKS = @zhixiaotong_old_fk_checks;

-- ------------------------------------------------------------
-- 数据数量核对（每张表应显示5）
-- ------------------------------------------------------------
SELECT 'user' AS `table_name`, COUNT(*) AS `row_count` FROM `user`
UNION ALL
SELECT 'org_unit' AS `table_name`, COUNT(*) AS `row_count` FROM `org_unit`
UNION ALL
SELECT 'school_class' AS `table_name`, COUNT(*) AS `row_count` FROM `school_class`
UNION ALL
SELECT 'role' AS `table_name`, COUNT(*) AS `row_count` FROM `role`
UNION ALL
SELECT 'permission' AS `table_name`, COUNT(*) AS `row_count` FROM `permission`
UNION ALL
SELECT 'user_role' AS `table_name`, COUNT(*) AS `row_count` FROM `user_role`
UNION ALL
SELECT 'role_permission' AS `table_name`, COUNT(*) AS `row_count` FROM `role_permission`
UNION ALL
SELECT 'user_scope' AS `table_name`, COUNT(*) AS `row_count` FROM `user_scope`
UNION ALL
SELECT 'counselor_class' AS `table_name`, COUNT(*) AS `row_count` FROM `counselor_class`
UNION ALL
SELECT 'semester' AS `table_name`, COUNT(*) AS `row_count` FROM `semester`
UNION ALL
SELECT 'course' AS `table_name`, COUNT(*) AS `row_count` FROM `course`
UNION ALL
SELECT 'course_prereq' AS `table_name`, COUNT(*) AS `row_count` FROM `course_prereq`
UNION ALL
SELECT 'classroom' AS `table_name`, COUNT(*) AS `row_count` FROM `classroom`
UNION ALL
SELECT 'teaching_class' AS `table_name`, COUNT(*) AS `row_count` FROM `teaching_class`
UNION ALL
SELECT 'timetable' AS `table_name`, COUNT(*) AS `row_count` FROM `timetable`
UNION ALL
SELECT 'selection_batch' AS `table_name`, COUNT(*) AS `row_count` FROM `selection_batch`
UNION ALL
SELECT 'batch_course' AS `table_name`, COUNT(*) AS `row_count` FROM `batch_course`
UNION ALL
SELECT 'selection_scope' AS `table_name`, COUNT(*) AS `row_count` FROM `selection_scope`
UNION ALL
SELECT 'enrollment' AS `table_name`, COUNT(*) AS `row_count` FROM `enrollment`
UNION ALL
SELECT 'course_resource' AS `table_name`, COUNT(*) AS `row_count` FROM `course_resource`
UNION ALL
SELECT 'assignment' AS `table_name`, COUNT(*) AS `row_count` FROM `assignment`
UNION ALL
SELECT 'submission' AS `table_name`, COUNT(*) AS `row_count` FROM `submission`
UNION ALL
SELECT 'grade' AS `table_name`, COUNT(*) AS `row_count` FROM `grade`
UNION ALL
SELECT 'grade_review' AS `table_name`, COUNT(*) AS `row_count` FROM `grade_review`
UNION ALL
SELECT 'grade_change' AS `table_name`, COUNT(*) AS `row_count` FROM `grade_change`
UNION ALL
SELECT 'exam_plan' AS `table_name`, COUNT(*) AS `row_count` FROM `exam_plan`
UNION ALL
SELECT 'teaching_evaluation' AS `table_name`, COUNT(*) AS `row_count` FROM `teaching_evaluation`
UNION ALL
SELECT 'leave_request' AS `table_name`, COUNT(*) AS `row_count` FROM `leave_request`
UNION ALL
SELECT 'leave_approval' AS `table_name`, COUNT(*) AS `row_count` FROM `leave_approval`
UNION ALL
SELECT 'student_record' AS `table_name`, COUNT(*) AS `row_count` FROM `student_record`
UNION ALL
SELECT 'dorm_check' AS `table_name`, COUNT(*) AS `row_count` FROM `dorm_check`
UNION ALL
SELECT 'student_focus' AS `table_name`, COUNT(*) AS `row_count` FROM `student_focus`
UNION ALL
SELECT 'aid_batch' AS `table_name`, COUNT(*) AS `row_count` FROM `aid_batch`
UNION ALL
SELECT 'aid_application' AS `table_name`, COUNT(*) AS `row_count` FROM `aid_application`
UNION ALL
SELECT 'aid_review' AS `table_name`, COUNT(*) AS `row_count` FROM `aid_review`
UNION ALL
SELECT 'service_application' AS `table_name`, COUNT(*) AS `row_count` FROM `service_application`
UNION ALL
SELECT 'service_step' AS `table_name`, COUNT(*) AS `row_count` FROM `service_step`
UNION ALL
SELECT 'card_account' AS `table_name`, COUNT(*) AS `row_count` FROM `card_account`
UNION ALL
SELECT 'recharge_order' AS `table_name`, COUNT(*) AS `row_count` FROM `recharge_order`
UNION ALL
SELECT 'card_transaction' AS `table_name`, COUNT(*) AS `row_count` FROM `card_transaction`
UNION ALL
SELECT 'book' AS `table_name`, COUNT(*) AS `row_count` FROM `book`
UNION ALL
SELECT 'book_copy' AS `table_name`, COUNT(*) AS `row_count` FROM `book_copy`
UNION ALL
SELECT 'book_loan' AS `table_name`, COUNT(*) AS `row_count` FROM `book_loan`
UNION ALL
SELECT 'book_reservation' AS `table_name`, COUNT(*) AS `row_count` FROM `book_reservation`
UNION ALL
SELECT 'notice' AS `table_name`, COUNT(*) AS `row_count` FROM `notice`
UNION ALL
SELECT 'notice_scope' AS `table_name`, COUNT(*) AS `row_count` FROM `notice_scope`
UNION ALL
SELECT 'message' AS `table_name`, COUNT(*) AS `row_count` FROM `message`
UNION ALL
SELECT 'message_receipt' AS `table_name`, COUNT(*) AS `row_count` FROM `message_receipt`
UNION ALL
SELECT 'file_upload' AS `table_name`, COUNT(*) AS `row_count` FROM `file_upload`
UNION ALL
SELECT 'system_config' AS `table_name`, COUNT(*) AS `row_count` FROM `system_config`
UNION ALL
SELECT 'audit_log' AS `table_name`, COUNT(*) AS `row_count` FROM `audit_log`
UNION ALL
SELECT 'async_task' AS `table_name`, COUNT(*) AS `row_count` FROM `async_task`
UNION ALL
SELECT 'outbox_event' AS `table_name`, COUNT(*) AS `row_count` FROM `outbox_event`
UNION ALL
SELECT 'device' AS `table_name`, COUNT(*) AS `row_count` FROM `device`
UNION ALL
SELECT 'continuation' AS `table_name`, COUNT(*) AS `row_count` FROM `continuation`
UNION ALL
SELECT 'attendance_task' AS `table_name`, COUNT(*) AS `row_count` FROM `attendance_task`
UNION ALL
SELECT 'attendance_record' AS `table_name`, COUNT(*) AS `row_count` FROM `attendance_record`;
