-- 智校通57张业务表；首次迁移只建表，不删除已有数据。
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

CREATE TABLE `user_role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `user_id` BIGINT NOT NULL COMMENT '用户ID；user(id)',
    `role_id` BIGINT NOT NULL COMMENT '角色ID；role(id)；与用户ID联合唯一',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role_user_id_role_id` (`user_id`, `role_id`),
    KEY `fk_user_role_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色关联表';

CREATE TABLE `role_permission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID；自增长类型',
    `role_id` BIGINT NOT NULL COMMENT '角色ID；role(id)',
    `permission_id` BIGINT NOT NULL COMMENT '权限ID；permission(id)；与角色ID联合唯一',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_permission_role_id_permission_id` (`role_id`, `permission_id`),
    KEY `fk_role_permission_permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';

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
