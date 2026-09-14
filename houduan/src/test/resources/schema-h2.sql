-- 智校通57张业务表；首次迁移只建表，不删除已有数据。
CREATE TABLE `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_name` VARCHAR(64) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `real_name` VARCHAR(32) NOT NULL,
    `user_no` VARCHAR(32) DEFAULT NULL,
    `gender` TINYINT NOT NULL DEFAULT 0,
    `phone` VARCHAR(128) DEFAULT NULL,
    `email` VARCHAR(128) DEFAULT NULL,
    `org_id` BIGINT NOT NULL,
    `class_id` BIGINT DEFAULT NULL,
    `avatar_id` BIGINT DEFAULT NULL,
    `user_status` TINYINT NOT NULL DEFAULT 1,
    `failed_count` INT NOT NULL DEFAULT 0,
    `lock_until` DATETIME DEFAULT NULL,
    `token_version` INT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_user_01` CHECK (`gender` IN (0,1,2)),
    CONSTRAINT `ck_user_02` CHECK (`user_status` IN (0,1,2)),
    CONSTRAINT `ck_user_03` CHECK (`failed_count` >= 0),
    CONSTRAINT `ck_user_04` CHECK (`token_version` >= 0)
);

CREATE TABLE `org_unit` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `parent_id` BIGINT DEFAULT NULL,
    `org_code` VARCHAR(32) NOT NULL,
    `org_name` VARCHAR(64) NOT NULL,
    `org_type` TINYINT NOT NULL DEFAULT 1,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_org_unit_01` CHECK (`org_type` IN (1,2,3,4)),
    CONSTRAINT `ck_org_unit_02` CHECK (`is_enabled` IN (0,1))
);

CREATE TABLE `school_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `class_code` VARCHAR(32) NOT NULL,
    `class_name` VARCHAR(64) NOT NULL,
    `grade_id` BIGINT NOT NULL,
    `entry_year` SMALLINT NOT NULL,
    `school_years` TINYINT NOT NULL DEFAULT 3,
    `class_status` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_school_class_01` CHECK (`class_status` IN (0,1,2))
);

CREATE TABLE `role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `role_code` VARCHAR(32) NOT NULL,
    `role_name` VARCHAR(32) NOT NULL,
    `scope_type` TINYINT NOT NULL DEFAULT 1,
    `description` VARCHAR(255) DEFAULT NULL,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_role_01` CHECK (`scope_type` IN (1,2,3,4,5)),
    CONSTRAINT `ck_role_02` CHECK (`is_enabled` IN (0,1))
);

CREATE TABLE `permission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `parent_id` BIGINT DEFAULT NULL,
    `permission_code` VARCHAR(64) NOT NULL,
    `permission_name` VARCHAR(64) NOT NULL,
    `permission_type` TINYINT NOT NULL DEFAULT 1,
    `resource_path` VARCHAR(255) DEFAULT NULL,
    `http_method` VARCHAR(16) DEFAULT NULL,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_permission_01` CHECK (`permission_type` IN (1,2,3)),
    CONSTRAINT `ck_permission_02` CHECK (`is_enabled` IN (0,1))
);

CREATE TABLE `user_role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `role_id` BIGINT NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE `role_permission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `role_id` BIGINT NOT NULL,
    `permission_id` BIGINT NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE `user_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_role_id` BIGINT NOT NULL,
    `org_id` BIGINT DEFAULT NULL,
    `class_id` BIGINT DEFAULT NULL,
    `include_children` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_user_scope_01` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_user_scope_02` CHECK ((`org_id` IS NOT NULL AND `class_id` IS NULL) OR (`org_id` IS NULL AND `class_id` IS NOT NULL))
);

CREATE TABLE `counselor_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `counselor_id` BIGINT NOT NULL,
    `class_id` BIGINT NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_counselor_class_01` CHECK (`end_time` IS NULL OR `end_time` > `start_time`)
);

CREATE TABLE `semester` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `semester_code` VARCHAR(32) NOT NULL,
    `semester_name` VARCHAR(64) NOT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `week_count` TINYINT NOT NULL,
    `is_current` TINYINT NOT NULL DEFAULT 0,
    `is_locked` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_semester_01` CHECK (`is_current` IN (0,1)),
    CONSTRAINT `ck_semester_02` CHECK (`is_locked` IN (0,1)),
    CONSTRAINT `ck_semester_03` CHECK (`end_date` >= `start_date`),
    CONSTRAINT `ck_semester_04` CHECK (`week_count` > 0)
);

CREATE TABLE `course` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `course_code` VARCHAR(32) NOT NULL,
    `course_name` VARCHAR(128) NOT NULL,
    `org_id` BIGINT NOT NULL,
    `course_type` VARCHAR(32) NOT NULL,
    `credit` DECIMAL(4,1) NOT NULL,
    `total_hours` INT NOT NULL,
    `syllabus` TEXT DEFAULT NULL,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_course_01` CHECK (`is_enabled` IN (0,1)),
    CONSTRAINT `ck_course_02` CHECK (`credit` >= 0),
    CONSTRAINT `ck_course_03` CHECK (`total_hours` > 0)
);

CREATE TABLE `course_prereq` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `course_id` BIGINT NOT NULL,
    `prereq_id` BIGINT NOT NULL,
    `min_score` DECIMAL(5,2) NOT NULL DEFAULT 60,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_course_prereq_01` CHECK (`course_id` <> `prereq_id`),
    CONSTRAINT `ck_course_prereq_02` CHECK (`min_score` BETWEEN 0 AND 100)
);

CREATE TABLE `classroom` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `room_code` VARCHAR(32) NOT NULL,
    `room_name` VARCHAR(64) NOT NULL,
    `campus_name` VARCHAR(64) NOT NULL,
    `building_name` VARCHAR(64) NOT NULL,
    `capacity` INT NOT NULL,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_classroom_01` CHECK (`is_enabled` IN (0,1)),
    CONSTRAINT `ck_classroom_02` CHECK (`capacity` > 0)
);

CREATE TABLE `teaching_class` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `class_code` VARCHAR(32) NOT NULL,
    `course_id` BIGINT NOT NULL,
    `semester_id` BIGINT NOT NULL,
    `teacher_id` BIGINT NOT NULL,
    `class_name` VARCHAR(64) NOT NULL,
    `capacity` INT NOT NULL,
    `enrolled_count` INT NOT NULL DEFAULT 0,
    `usual_weight` DECIMAL(5,4) NOT NULL DEFAULT 0.4000,
    `final_weight` DECIMAL(5,4) NOT NULL DEFAULT 0.6000,
    `version` INT NOT NULL DEFAULT 0,
    `class_status` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_teaching_class_01` CHECK (`class_status` IN (0,1,2)),
    CONSTRAINT `ck_teaching_class_02` CHECK (`capacity` > 0),
    CONSTRAINT `ck_teaching_class_03` CHECK (`enrolled_count` BETWEEN 0 AND `capacity`),
    CONSTRAINT `ck_teaching_class_04` CHECK (`usual_weight` BETWEEN 0 AND 1),
    CONSTRAINT `ck_teaching_class_05` CHECK (`final_weight` BETWEEN 0 AND 1),
    CONSTRAINT `ck_teaching_class_06` CHECK (`usual_weight` + `final_weight` = 1),
    CONSTRAINT `ck_teaching_class_07` CHECK (`version` >= 0)
);

CREATE TABLE `timetable` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `teaching_class_id` BIGINT NOT NULL,
    `classroom_id` BIGINT NOT NULL,
    `start_week` TINYINT NOT NULL,
    `end_week` TINYINT NOT NULL,
    `week_mode` TINYINT NOT NULL DEFAULT 1,
    `week_day` TINYINT NOT NULL,
    `start_period` TINYINT NOT NULL,
    `end_period` TINYINT NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_timetable_01` CHECK (`week_mode` IN (1,2,3)),
    CONSTRAINT `ck_timetable_02` CHECK (`start_week` >= 1 AND `end_week` >= `start_week`),
    CONSTRAINT `ck_timetable_03` CHECK (`week_day` BETWEEN 1 AND 7),
    CONSTRAINT `ck_timetable_04` CHECK (`start_period` >= 1 AND `end_period` >= `start_period`),
    CONSTRAINT `ck_timetable_05` CHECK (`end_time` > `start_time`)
);

CREATE TABLE `selection_batch` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `batch_code` VARCHAR(32) NOT NULL,
    `batch_name` VARCHAR(64) NOT NULL,
    `semester_id` BIGINT NOT NULL,
    `batch_stage` TINYINT NOT NULL DEFAULT 1,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NOT NULL,
    `drop_deadline` DATETIME DEFAULT NULL,
    `max_courses` INT NOT NULL DEFAULT 0,
    `max_credits` DECIMAL(5,1) NOT NULL DEFAULT 0,
    `announcement` TEXT DEFAULT NULL,
    `batch_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_selection_batch_01` CHECK (`batch_stage` IN (1,2,3)),
    CONSTRAINT `ck_selection_batch_02` CHECK (`batch_status` IN (0,1,2,3)),
    CONSTRAINT `ck_selection_batch_03` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_selection_batch_04` CHECK (`max_courses` >= 0),
    CONSTRAINT `ck_selection_batch_05` CHECK (`max_credits` >= 0)
);

CREATE TABLE `batch_course` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `batch_id` BIGINT NOT NULL,
    `teaching_class_id` BIGINT NOT NULL,
    `admission_type` TINYINT NOT NULL DEFAULT 1,
    `priority_rule` VARCHAR(200000) DEFAULT NULL,
    `process_status` TINYINT NOT NULL DEFAULT 0,
    `process_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_batch_course_01` CHECK (`admission_type` IN (1,2,3)),
    CONSTRAINT `ck_batch_course_02` CHECK (`process_status` IN (0,1,2)),
    CONSTRAINT `ck_batch_course_03` CHECK (`admission_type` <> 3 OR `priority_rule` IS NOT NULL)
);

CREATE TABLE `selection_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `batch_course_id` BIGINT NOT NULL,
    `org_id` BIGINT DEFAULT NULL,
    `class_id` BIGINT DEFAULT NULL,
    `include_children` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_selection_scope_01` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_selection_scope_02` CHECK ((`org_id` IS NOT NULL AND `class_id` IS NULL) OR (`org_id` IS NULL AND `class_id` IS NOT NULL))
);

CREATE TABLE `enrollment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `teaching_class_id` BIGINT NOT NULL,
    `batch_course_id` BIGINT DEFAULT NULL,
    `request_key` VARCHAR(64) NOT NULL,
    `enroll_status` TINYINT NOT NULL DEFAULT 0,
    `selection_rank` INT DEFAULT NULL,
    `enroll_time` DATETIME NOT NULL,
    `drop_time` DATETIME DEFAULT NULL,
    `result_note` VARCHAR(255) DEFAULT NULL,
    `version` INT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_enrollment_01` CHECK (`enroll_status` IN (0,1,2,3))
);

CREATE TABLE `course_resource` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `teaching_class_id` BIGINT NOT NULL,
    `resource_title` VARCHAR(128) NOT NULL,
    `file_id` BIGINT NOT NULL,
    `uploader_id` BIGINT NOT NULL,
    `visible_scope` TINYINT NOT NULL DEFAULT 1,
    `sort_order` INT NOT NULL DEFAULT 0,
    `publish_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_course_resource_01` CHECK (`visible_scope` IN (1,2)),
    CONSTRAINT `ck_course_resource_02` CHECK (`publish_status` IN (0,1))
);

CREATE TABLE `assignment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `teaching_class_id` BIGINT NOT NULL,
    `teacher_id` BIGINT NOT NULL,
    `assignment_title` VARCHAR(128) NOT NULL,
    `content` TEXT NOT NULL,
    `grading_rule` TEXT DEFAULT NULL,
    `max_score` DECIMAL(6,2) NOT NULL DEFAULT 100,
    `deadline` DATETIME NOT NULL,
    `allow_late` TINYINT NOT NULL DEFAULT 0,
    `publish_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_assignment_01` CHECK (`allow_late` IN (0,1)),
    CONSTRAINT `ck_assignment_02` CHECK (`publish_status` IN (0,1,2)),
    CONSTRAINT `ck_assignment_03` CHECK (`max_score` > 0)
);

CREATE TABLE `submission` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `assignment_id` BIGINT NOT NULL,
    `student_id` BIGINT NOT NULL,
    `submit_round` INT NOT NULL DEFAULT 1,
    `content` TEXT DEFAULT NULL,
    `submit_time` DATETIME NOT NULL,
    `submit_status` TINYINT NOT NULL DEFAULT 0,
    `score` DECIMAL(6,2) DEFAULT NULL,
    `feedback` TEXT DEFAULT NULL,
    `grader_id` BIGINT DEFAULT NULL,
    `grade_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_submission_01` CHECK (`submit_status` IN (0,1,2,3)),
    CONSTRAINT `ck_submission_02` CHECK (`submit_round` >= 1),
    CONSTRAINT `ck_submission_03` CHECK (`score` IS NULL OR `score` >= 0)
);

CREATE TABLE `grade` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `enrollment_id` BIGINT NOT NULL,
    `review_id` BIGINT DEFAULT NULL,
    `usual_score` DECIMAL(5,2) DEFAULT NULL,
    `final_score` DECIMAL(5,2) DEFAULT NULL,
    `total_score` DECIMAL(5,2) DEFAULT NULL,
    `grade_point` DECIMAL(3,2) DEFAULT NULL,
    `exam_flag` TINYINT NOT NULL DEFAULT 0,
    `grade_status` TINYINT NOT NULL DEFAULT 0,
    `operator_id` BIGINT NOT NULL,
    `publish_time` DATETIME DEFAULT NULL,
    `version` INT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_grade_01` CHECK (`exam_flag` IN (0,1,2,3)),
    CONSTRAINT `ck_grade_02` CHECK (`grade_status` IN (0,1,2,3)),
    CONSTRAINT `ck_grade_03` CHECK (`usual_score` IS NULL OR `usual_score` BETWEEN 0 AND 100),
    CONSTRAINT `ck_grade_04` CHECK (`final_score` IS NULL OR `final_score` BETWEEN 0 AND 100),
    CONSTRAINT `ck_grade_05` CHECK (`total_score` IS NULL OR `total_score` BETWEEN 0 AND 100)
);

CREATE TABLE `grade_review` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `teaching_class_id` BIGINT NOT NULL,
    `review_round` INT NOT NULL DEFAULT 1,
    `submitter_id` BIGINT NOT NULL,
    `submit_time` DATETIME NOT NULL,
    `grade_snapshot` VARCHAR(200000) NOT NULL,
    `warning_note` VARCHAR(255) DEFAULT NULL,
    `reviewer_id` BIGINT DEFAULT NULL,
    `review_status` TINYINT NOT NULL DEFAULT 0,
    `review_comment` VARCHAR(255) DEFAULT NULL,
    `review_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_grade_review_01` CHECK (`review_status` IN (0,1,2)),
    CONSTRAINT `ck_grade_review_02` CHECK (`review_round` >= 1)
);

CREATE TABLE `grade_change` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `grade_id` BIGINT NOT NULL,
    `applicant_id` BIGINT NOT NULL,
    `before_value` VARCHAR(200000) NOT NULL,
    `after_value` VARCHAR(200000) NOT NULL,
    `change_reason` VARCHAR(255) NOT NULL,
    `reviewer_id` BIGINT DEFAULT NULL,
    `review_status` TINYINT NOT NULL DEFAULT 0,
    `review_comment` VARCHAR(255) DEFAULT NULL,
    `review_time` DATETIME DEFAULT NULL,
    `apply_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_grade_change_01` CHECK (`review_status` IN (0,1,2))
);

CREATE TABLE `exam_plan` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `teaching_class_id` BIGINT NOT NULL,
    `classroom_id` BIGINT NOT NULL,
    `exam_name` VARCHAR(64) NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NOT NULL,
    `invigilator_id` BIGINT NOT NULL,
    `assistant_id` BIGINT DEFAULT NULL,
    `plan_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_exam_plan_01` CHECK (`plan_status` IN (0,1,2)),
    CONSTRAINT `ck_exam_plan_02` CHECK (`end_time` > `start_time`)
);

CREATE TABLE `teaching_evaluation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `enrollment_id` BIGINT NOT NULL,
    `total_score` DECIMAL(5,2) NOT NULL,
    `item_scores` VARCHAR(200000) NOT NULL,
    `comment` TEXT DEFAULT NULL,
    `is_anonymous` TINYINT NOT NULL DEFAULT 1,
    `submit_time` DATETIME NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_teaching_evaluation_01` CHECK (`is_anonymous` IN (0,1)),
    CONSTRAINT `ck_teaching_evaluation_02` CHECK (`total_score` BETWEEN 0 AND 100)
);

CREATE TABLE `leave_request` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `leave_type` VARCHAR(32) NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NOT NULL,
    `leave_days` DECIMAL(5,2) NOT NULL,
    `leave_reason` TEXT NOT NULL,
    `leave_status` TINYINT NOT NULL DEFAULT 0,
    `apply_round` INT NOT NULL DEFAULT 1,
    `submit_time` DATETIME DEFAULT NULL,
    `close_time` DATETIME DEFAULT NULL,
    `close_type` TINYINT NOT NULL DEFAULT 0,
    `closer_id` BIGINT DEFAULT NULL,
    `close_note` VARCHAR(255) DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_leave_request_01` CHECK (`leave_status` IN (0,1,2,3,4,5,6,7)),
    CONSTRAINT `ck_leave_request_02` CHECK (`close_type` IN (0,1,2)),
    CONSTRAINT `ck_leave_request_03` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_leave_request_04` CHECK (`leave_days` > 0),
    CONSTRAINT `ck_leave_request_05` CHECK (`apply_round` >= 1)
);

CREATE TABLE `leave_approval` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `leave_id` BIGINT NOT NULL,
    `apply_round` INT NOT NULL DEFAULT 1,
    `node_order` TINYINT NOT NULL,
    `node_type` TINYINT NOT NULL DEFAULT 1,
    `approver_id` BIGINT NOT NULL,
    `decision` TINYINT NOT NULL DEFAULT 0,
    `opinion` VARCHAR(255) DEFAULT NULL,
    `approve_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_leave_approval_01` CHECK (`node_type` IN (1,2)),
    CONSTRAINT `ck_leave_approval_02` CHECK (`decision` IN (0,1,2,3,4)),
    CONSTRAINT `ck_leave_approval_03` CHECK (`apply_round` >= 1),
    CONSTRAINT `ck_leave_approval_04` CHECK (`node_order` >= 1)
);

CREATE TABLE `student_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `record_type` TINYINT NOT NULL DEFAULT 1,
    `record_title` VARCHAR(128) NOT NULL,
    `record_level` VARCHAR(32) DEFAULT NULL,
    `description` TEXT NOT NULL,
    `record_date` DATE NOT NULL,
    `operator_id` BIGINT NOT NULL,
    `record_status` TINYINT NOT NULL DEFAULT 1,
    `revoke_reason` VARCHAR(255) DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_student_record_01` CHECK (`record_type` IN (1,2)),
    CONSTRAINT `ck_student_record_02` CHECK (`record_status` IN (1,2))
);

CREATE TABLE `dorm_check` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `dorm_location` VARCHAR(128) NOT NULL,
    `check_time` DATETIME NOT NULL,
    `check_result` TINYINT NOT NULL DEFAULT 1,
    `return_time` DATETIME DEFAULT NULL,
    `handle_note` VARCHAR(255) DEFAULT NULL,
    `checker_id` BIGINT NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_dorm_check_01` CHECK (`check_result` IN (1,2,3,4))
);

CREATE TABLE `student_focus` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `focus_type` VARCHAR(32) NOT NULL,
    `focus_content` TEXT NOT NULL,
    `follow_up` TEXT DEFAULT NULL,
    `owner_id` BIGINT NOT NULL,
    `focus_status` TINYINT NOT NULL DEFAULT 1,
    `close_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_student_focus_01` CHECK (`focus_status` IN (1,2))
);

CREATE TABLE `aid_batch` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `batch_name` VARCHAR(128) NOT NULL,
    `aid_type` VARCHAR(32) NOT NULL,
    `org_id` BIGINT NOT NULL,
    `semester_id` BIGINT NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NOT NULL,
    `quota` INT NOT NULL,
    `aid_amount` DECIMAL(10,2) NOT NULL,
    `requirements` TEXT NOT NULL,
    `batch_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_aid_batch_01` CHECK (`batch_status` IN (0,1,2,3)),
    CONSTRAINT `ck_aid_batch_02` CHECK (`end_time` > `start_time`),
    CONSTRAINT `ck_aid_batch_03` CHECK (`quota` > 0),
    CONSTRAINT `ck_aid_batch_04` CHECK (`aid_amount` >= 0)
);

CREATE TABLE `aid_application` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `batch_id` BIGINT NOT NULL,
    `student_id` BIGINT NOT NULL,
    `apply_reason` TEXT NOT NULL,
    `apply_amount` DECIMAL(10,2) NOT NULL,
    `apply_status` TINYINT NOT NULL DEFAULT 0,
    `apply_round` INT NOT NULL DEFAULT 1,
    `submit_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_aid_application_01` CHECK (`apply_status` IN (0,1,2,3,4,5)),
    CONSTRAINT `ck_aid_application_02` CHECK (`apply_amount` > 0),
    CONSTRAINT `ck_aid_application_03` CHECK (`apply_round` >= 1)
);

CREATE TABLE `aid_review` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `application_id` BIGINT NOT NULL,
    `apply_round` INT NOT NULL DEFAULT 1,
    `node_order` TINYINT NOT NULL,
    `reviewer_id` BIGINT NOT NULL,
    `review_score` DECIMAL(5,2) DEFAULT NULL,
    `decision` TINYINT NOT NULL DEFAULT 0,
    `opinion` VARCHAR(255) DEFAULT NULL,
    `review_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_aid_review_01` CHECK (`decision` IN (0,1,2,3)),
    CONSTRAINT `ck_aid_review_02` CHECK (`apply_round` >= 1),
    CONSTRAINT `ck_aid_review_03` CHECK (`node_order` >= 1)
);

CREATE TABLE `service_application` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `student_id` BIGINT NOT NULL,
    `service_type` TINYINT NOT NULL DEFAULT 1,
    `service_name` VARCHAR(128) NOT NULL,
    `apply_data` VARCHAR(200000) NOT NULL,
    `service_status` TINYINT NOT NULL DEFAULT 0,
    `result_file_id` BIGINT DEFAULT NULL,
    `submit_time` DATETIME DEFAULT NULL,
    `finish_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_service_application_01` CHECK (`service_type` IN (1,2)),
    CONSTRAINT `ck_service_application_02` CHECK (`service_status` IN (0,1,2,3,4))
);

CREATE TABLE `service_step` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `application_id` BIGINT NOT NULL,
    `step_order` INT NOT NULL,
    `step_name` VARCHAR(64) NOT NULL,
    `org_id` BIGINT NOT NULL,
    `handler_id` BIGINT DEFAULT NULL,
    `decision` TINYINT NOT NULL DEFAULT 0,
    `opinion` VARCHAR(255) DEFAULT NULL,
    `handle_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_service_step_01` CHECK (`decision` IN (0,1,2)),
    CONSTRAINT `ck_service_step_02` CHECK (`step_order` >= 1)
);

CREATE TABLE `card_account` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `card_no` VARCHAR(32) NOT NULL,
    `balance` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `account_status` TINYINT NOT NULL DEFAULT 1,
    `version` INT NOT NULL DEFAULT 0,
    `sync_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_card_account_01` CHECK (`account_status` IN (0,1,2)),
    CONSTRAINT `ck_card_account_02` CHECK (`balance` >= 0),
    CONSTRAINT `ck_card_account_03` CHECK (`version` >= 0)
);

CREATE TABLE `recharge_order` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `order_no` VARCHAR(64) NOT NULL,
    `account_id` BIGINT NOT NULL,
    `amount` DECIMAL(12,2) NOT NULL,
    `pay_channel` VARCHAR(32) NOT NULL,
    `pay_trade_no` VARCHAR(64) DEFAULT NULL,
    `request_key` VARCHAR(64) NOT NULL,
    `order_status` TINYINT NOT NULL DEFAULT 0,
    `pay_time` DATETIME DEFAULT NULL,
    `callback_time` DATETIME DEFAULT NULL,
    `posted_time` DATETIME DEFAULT NULL,
    `expire_time` DATETIME NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_recharge_order_01` CHECK (`order_status` IN (0,1,2,3)),
    CONSTRAINT `ck_recharge_order_02` CHECK (`amount` > 0)
);

CREATE TABLE `card_transaction` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `transaction_no` VARCHAR(64) NOT NULL,
    `account_id` BIGINT NOT NULL,
    `recharge_id` BIGINT DEFAULT NULL,
    `source_system` VARCHAR(32) NOT NULL,
    `source_trade_no` VARCHAR(64) NOT NULL,
    `transaction_type` TINYINT NOT NULL DEFAULT 1,
    `amount` DECIMAL(12,2) NOT NULL,
    `balance_before` DECIMAL(12,2) NOT NULL,
    `balance_after` DECIMAL(12,2) NOT NULL,
    `merchant_name` VARCHAR(128) DEFAULT NULL,
    `transaction_time` DATETIME NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_card_transaction_01` CHECK (`transaction_type` IN (1,2,3)),
    CONSTRAINT `ck_card_transaction_02` CHECK (`balance_before` >= 0 AND `balance_after` >= 0),
    CONSTRAINT `ck_card_transaction_03` CHECK (`balance_after` = `balance_before` + `amount`),
    CONSTRAINT `ck_card_transaction_04` CHECK ((`transaction_type` IN (1,3) AND `amount` > 0) OR (`transaction_type` = 2 AND `amount` < 0)),
    CONSTRAINT `ck_card_transaction_05` CHECK (`transaction_type` <> 1 OR `recharge_id` IS NOT NULL)
);

CREATE TABLE `book` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `book_code` VARCHAR(32) NOT NULL,
    `isbn` VARCHAR(20) DEFAULT NULL,
    `book_name` VARCHAR(128) NOT NULL,
    `author` VARCHAR(128) NOT NULL,
    `publisher` VARCHAR(128) DEFAULT NULL,
    `category_code` VARCHAR(32) NOT NULL,
    `summary` TEXT DEFAULT NULL,
    `cover_id` BIGINT DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE `book_copy` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `book_id` BIGINT NOT NULL,
    `copy_no` VARCHAR(32) NOT NULL,
    `location` VARCHAR(128) NOT NULL,
    `copy_status` TINYINT NOT NULL DEFAULT 0,
    `version` INT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_book_copy_01` CHECK (`copy_status` IN (0,1,2,3)),
    CONSTRAINT `ck_book_copy_02` CHECK (`version` >= 0)
);

CREATE TABLE `book_loan` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `reader_id` BIGINT NOT NULL,
    `copy_id` BIGINT NOT NULL,
    `external_loan_no` VARCHAR(64) DEFAULT NULL,
    `borrow_time` DATETIME NOT NULL,
    `due_time` DATETIME NOT NULL,
    `return_time` DATETIME DEFAULT NULL,
    `renew_count` TINYINT NOT NULL DEFAULT 0,
    `renew_time` DATETIME DEFAULT NULL,
    `loan_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_book_loan_01` CHECK (`loan_status` IN (0,1,2)),
    CONSTRAINT `ck_book_loan_02` CHECK (`due_time` > `borrow_time`),
    CONSTRAINT `ck_book_loan_03` CHECK (`return_time` IS NULL OR `return_time` >= `borrow_time`),
    CONSTRAINT `ck_book_loan_04` CHECK (`renew_count` >= 0)
);

CREATE TABLE `book_reservation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `reader_id` BIGINT NOT NULL,
    `book_id` BIGINT NOT NULL,
    `copy_id` BIGINT DEFAULT NULL,
    `request_key` VARCHAR(64) NOT NULL,
    `reserve_time` DATETIME NOT NULL,
    `expire_time` DATETIME DEFAULT NULL,
    `reserve_status` TINYINT NOT NULL DEFAULT 0,
    `notify_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_book_reservation_01` CHECK (`reserve_status` IN (0,1,2,3,4))
);

CREATE TABLE `notice` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `notice_title` VARCHAR(128) NOT NULL,
    `content` TEXT NOT NULL,
    `publisher_id` BIGINT NOT NULL,
    `urgency_level` TINYINT NOT NULL DEFAULT 0,
    `is_pinned` TINYINT NOT NULL DEFAULT 0,
    `need_ack` TINYINT NOT NULL DEFAULT 0,
    `start_time` DATETIME NOT NULL,
    `expire_time` DATETIME DEFAULT NULL,
    `publish_time` DATETIME DEFAULT NULL,
    `publish_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_notice_01` CHECK (`urgency_level` IN (0,1,2)),
    CONSTRAINT `ck_notice_02` CHECK (`is_pinned` IN (0,1)),
    CONSTRAINT `ck_notice_03` CHECK (`need_ack` IN (0,1)),
    CONSTRAINT `ck_notice_04` CHECK (`publish_status` IN (0,1,2)),
    CONSTRAINT `ck_notice_05` CHECK (`urgency_level` <> 2 OR `need_ack` = 1),
    CONSTRAINT `ck_notice_06` CHECK (`expire_time` IS NULL OR `expire_time` > `start_time`)
);

CREATE TABLE `notice_scope` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `notice_id` BIGINT NOT NULL,
    `scope_type` TINYINT NOT NULL DEFAULT 1,
    `org_id` BIGINT DEFAULT NULL,
    `class_id` BIGINT DEFAULT NULL,
    `teaching_class_id` BIGINT DEFAULT NULL,
    `include_children` TINYINT NOT NULL DEFAULT 1,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_notice_scope_01` CHECK (`scope_type` IN (1,2,3,4)),
    CONSTRAINT `ck_notice_scope_02` CHECK (`include_children` IN (0,1)),
    CONSTRAINT `ck_notice_scope_03` CHECK ((`scope_type` = 1 AND `org_id` IS NULL AND `class_id` IS NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 2 AND `org_id` IS NOT NULL AND `class_id` IS NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 3 AND `org_id` IS NULL AND `class_id` IS NOT NULL AND `teaching_class_id` IS NULL) OR (`scope_type` = 4 AND `org_id` IS NULL AND `class_id` IS NULL AND `teaching_class_id` IS NOT NULL))
);

CREATE TABLE `message` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `message_title` VARCHAR(128) NOT NULL,
    `content` TEXT NOT NULL,
    `notice_id` BIGINT DEFAULT NULL,
    `biz_type` VARCHAR(32) NOT NULL,
    `biz_id` BIGINT DEFAULT NULL,
    `event_key` VARCHAR(64) NOT NULL,
    `need_ack` TINYINT NOT NULL DEFAULT 0,
    `expire_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_message_01` CHECK (`need_ack` IN (0,1))
);

CREATE TABLE `message_receipt` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `message_id` BIGINT NOT NULL,
    `receiver_id` BIGINT NOT NULL,
    `delivery_status` TINYINT NOT NULL DEFAULT 0,
    `delivered_time` DATETIME DEFAULT NULL,
    `read_time` DATETIME DEFAULT NULL,
    `ack_time` DATETIME DEFAULT NULL,
    `retry_count` INT NOT NULL DEFAULT 0,
    `error_message` VARCHAR(255) DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_message_receipt_01` CHECK (`delivery_status` IN (0,1,2)),
    CONSTRAINT `ck_message_receipt_02` CHECK (`retry_count` >= 0)
);

CREATE TABLE `file_upload` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `bucket_name` VARCHAR(64) NOT NULL,
    `object_key` VARCHAR(255) NOT NULL,
    `original_name` VARCHAR(255) NOT NULL,
    `mime_type` VARCHAR(128) NOT NULL,
    `file_size` BIGINT NOT NULL,
    `file_hash` VARCHAR(64) NOT NULL,
    `biz_type` VARCHAR(32) NOT NULL,
    `biz_id` BIGINT DEFAULT NULL,
    `uploader_id` BIGINT NOT NULL,
    `scan_status` TINYINT NOT NULL DEFAULT 0,
    `file_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_file_upload_01` CHECK (`scan_status` IN (0,1,2)),
    CONSTRAINT `ck_file_upload_02` CHECK (`file_status` IN (0,1,2)),
    CONSTRAINT `ck_file_upload_03` CHECK (`file_size` BETWEEN 0 AND 104857600),
    CONSTRAINT `ck_file_upload_04` CHECK (`file_status` <> 1 OR `biz_id` IS NOT NULL)
);

CREATE TABLE `system_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `config_group` VARCHAR(64) NOT NULL,
    `config_key` VARCHAR(64) NOT NULL,
    `config_name` VARCHAR(64) NOT NULL,
    `config_value` TEXT NOT NULL,
    `value_type` VARCHAR(16) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_enabled` TINYINT NOT NULL DEFAULT 1,
    `updater_id` BIGINT NOT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_system_config_01` CHECK (`is_enabled` IN (0,1))
);

CREATE TABLE `audit_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `operator_id` BIGINT DEFAULT NULL,
    `action_type` VARCHAR(64) NOT NULL,
    `biz_type` VARCHAR(32) NOT NULL,
    `biz_id` BIGINT DEFAULT NULL,
    `request_id` VARCHAR(64) NOT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `change_data` VARCHAR(200000) DEFAULT NULL,
    `result_status` TINYINT NOT NULL DEFAULT 1,
    `confirmed` TINYINT NOT NULL DEFAULT 0,
    `operate_time` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_audit_log_01` CHECK (`result_status` IN (0,1)),
    CONSTRAINT `ck_audit_log_02` CHECK (`confirmed` IN (0,1))
);

CREATE TABLE `async_task` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `task_no` VARCHAR(64) NOT NULL,
    `task_type` VARCHAR(32) NOT NULL,
    `creator_id` BIGINT NOT NULL,
    `task_params` VARCHAR(200000) NOT NULL,
    `input_file_id` BIGINT DEFAULT NULL,
    `result_file_id` BIGINT DEFAULT NULL,
    `task_status` TINYINT NOT NULL DEFAULT 0,
    `progress` TINYINT NOT NULL DEFAULT 0,
    `error_message` VARCHAR(255) DEFAULT NULL,
    `start_time` DATETIME DEFAULT NULL,
    `finish_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_async_task_01` CHECK (`task_status` IN (0,1,2,3,4)),
    CONSTRAINT `ck_async_task_02` CHECK (`progress` BETWEEN 0 AND 100)
);

CREATE TABLE `outbox_event` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `event_key` VARCHAR(64) NOT NULL,
    `event_type` VARCHAR(64) NOT NULL,
    `payload` VARCHAR(200000) NOT NULL,
    `send_status` TINYINT NOT NULL DEFAULT 0,
    `retry_count` INT NOT NULL DEFAULT 0,
    `next_retry_time` DATETIME DEFAULT NULL,
    `lock_until` DATETIME DEFAULT NULL,
    `confirmed_time` DATETIME DEFAULT NULL,
    `error_message` VARCHAR(255) DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_outbox_event_01` CHECK (`send_status` IN (0,1,2,3)),
    CONSTRAINT `ck_outbox_event_02` CHECK (`retry_count` >= 0)
);

CREATE TABLE `device` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `device_code` VARCHAR(128) NOT NULL,
    `device_name` VARCHAR(64) NOT NULL,
    `device_type` VARCHAR(32) NOT NULL,
    `push_token` VARCHAR(512) DEFAULT NULL,
    `trust_status` TINYINT NOT NULL DEFAULT 0,
    `last_seen_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_device_01` CHECK (`trust_status` IN (0,1,2))
);

CREATE TABLE `continuation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `source_device_id` BIGINT NOT NULL,
    `target_device_id` BIGINT DEFAULT NULL,
    `biz_type` VARCHAR(32) NOT NULL,
    `biz_id` BIGINT NOT NULL,
    `scope_data` VARCHAR(200000) NOT NULL,
    `token_hash` VARCHAR(64) NOT NULL,
    `task_status` TINYINT NOT NULL DEFAULT 0,
    `expire_time` DATETIME NOT NULL,
    `accept_time` DATETIME DEFAULT NULL,
    `reclaim_time` DATETIME DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_continuation_01` CHECK (`task_status` IN (0,1,2,3,4)),
    CONSTRAINT `ck_continuation_02` CHECK (`target_device_id` IS NULL OR `source_device_id` <> `target_device_id`)
);

CREATE TABLE `attendance_task` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `timetable_id` BIGINT NOT NULL,
    `creator_id` BIGINT NOT NULL,
    `class_date` DATE NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NOT NULL,
    `code_hash` VARCHAR(64) NOT NULL,
    `task_status` TINYINT NOT NULL DEFAULT 0,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_attendance_task_01` CHECK (`task_status` IN (0,1,2)),
    CONSTRAINT `ck_attendance_task_02` CHECK (`end_time` > `start_time`)
);

CREATE TABLE `attendance_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `task_id` BIGINT NOT NULL,
    `student_id` BIGINT NOT NULL,
    `sign_status` TINYINT NOT NULL DEFAULT 0,
    `sign_time` DATETIME DEFAULT NULL,
    `device_id` BIGINT DEFAULT NULL,
    `remark` VARCHAR(255) DEFAULT NULL,
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `ck_attendance_record_01` CHECK (`sign_status` IN (0,1,2,3,4))
);

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

ALTER TABLE `user` ADD CONSTRAINT `test_uk_user_0` UNIQUE (`user_name`);
ALTER TABLE `user` ADD CONSTRAINT `test_uk_user_1` UNIQUE (`user_no`);
ALTER TABLE `org_unit` ADD CONSTRAINT `test_uk_org_unit_0` UNIQUE (`org_code`);
ALTER TABLE `school_class` ADD CONSTRAINT `test_uk_school_class_0` UNIQUE (`class_code`);
ALTER TABLE `role` ADD CONSTRAINT `test_uk_role_0` UNIQUE (`role_code`);
ALTER TABLE `permission` ADD CONSTRAINT `test_uk_permission_0` UNIQUE (`permission_code`);
ALTER TABLE `user_role` ADD CONSTRAINT `test_uk_user_role_0` UNIQUE (`user_id`, `role_id`);
ALTER TABLE `role_permission` ADD CONSTRAINT `test_uk_role_permission_0` UNIQUE (`role_id`, `permission_id`);
ALTER TABLE `user_scope` ADD CONSTRAINT `test_uk_user_scope_0` UNIQUE (`user_role_id`, `org_id`);
ALTER TABLE `user_scope` ADD CONSTRAINT `test_uk_user_scope_1` UNIQUE (`user_role_id`, `class_id`);
ALTER TABLE `counselor_class` ADD CONSTRAINT `test_uk_counselor_class_0` UNIQUE (`counselor_id`, `class_id`, `start_time`);
ALTER TABLE `semester` ADD CONSTRAINT `test_uk_semester_0` UNIQUE (`semester_code`);
ALTER TABLE `course` ADD CONSTRAINT `test_uk_course_0` UNIQUE (`course_code`);
ALTER TABLE `course_prereq` ADD CONSTRAINT `test_uk_course_prereq_0` UNIQUE (`course_id`, `prereq_id`);
ALTER TABLE `classroom` ADD CONSTRAINT `test_uk_classroom_0` UNIQUE (`room_code`);
ALTER TABLE `teaching_class` ADD CONSTRAINT `test_uk_teaching_class_0` UNIQUE (`class_code`);
ALTER TABLE `selection_batch` ADD CONSTRAINT `test_uk_selection_batch_0` UNIQUE (`batch_code`);
ALTER TABLE `batch_course` ADD CONSTRAINT `test_uk_batch_course_0` UNIQUE (`batch_id`, `teaching_class_id`);
ALTER TABLE `selection_scope` ADD CONSTRAINT `test_uk_selection_scope_0` UNIQUE (`batch_course_id`, `org_id`);
ALTER TABLE `selection_scope` ADD CONSTRAINT `test_uk_selection_scope_1` UNIQUE (`batch_course_id`, `class_id`);
ALTER TABLE `enrollment` ADD CONSTRAINT `test_uk_enrollment_0` UNIQUE (`student_id`, `teaching_class_id`);
ALTER TABLE `enrollment` ADD CONSTRAINT `test_uk_enrollment_1` UNIQUE (`request_key`);
ALTER TABLE `submission` ADD CONSTRAINT `test_uk_submission_0` UNIQUE (`assignment_id`, `student_id`, `submit_round`);
ALTER TABLE `grade` ADD CONSTRAINT `test_uk_grade_0` UNIQUE (`enrollment_id`);
ALTER TABLE `grade_review` ADD CONSTRAINT `test_uk_grade_review_0` UNIQUE (`teaching_class_id`, `review_round`);
ALTER TABLE `teaching_evaluation` ADD CONSTRAINT `test_uk_teaching_evaluation_0` UNIQUE (`enrollment_id`);
ALTER TABLE `leave_approval` ADD CONSTRAINT `test_uk_leave_approval_0` UNIQUE (`leave_id`, `apply_round`, `node_order`);
ALTER TABLE `aid_application` ADD CONSTRAINT `test_uk_aid_application_0` UNIQUE (`batch_id`, `student_id`);
ALTER TABLE `aid_review` ADD CONSTRAINT `test_uk_aid_review_0` UNIQUE (`application_id`, `apply_round`, `node_order`, `reviewer_id`);
ALTER TABLE `service_step` ADD CONSTRAINT `test_uk_service_step_0` UNIQUE (`application_id`, `step_order`);
ALTER TABLE `card_account` ADD CONSTRAINT `test_uk_card_account_0` UNIQUE (`user_id`);
ALTER TABLE `card_account` ADD CONSTRAINT `test_uk_card_account_1` UNIQUE (`card_no`);
ALTER TABLE `recharge_order` ADD CONSTRAINT `test_uk_recharge_order_0` UNIQUE (`order_no`);
ALTER TABLE `recharge_order` ADD CONSTRAINT `test_uk_recharge_order_1` UNIQUE (`pay_channel`, `pay_trade_no`);
ALTER TABLE `recharge_order` ADD CONSTRAINT `test_uk_recharge_order_2` UNIQUE (`request_key`);
ALTER TABLE `card_transaction` ADD CONSTRAINT `test_uk_card_transaction_0` UNIQUE (`transaction_no`);
ALTER TABLE `card_transaction` ADD CONSTRAINT `test_uk_card_transaction_1` UNIQUE (`recharge_id`);
ALTER TABLE `card_transaction` ADD CONSTRAINT `test_uk_card_transaction_2` UNIQUE (`source_system`, `source_trade_no`);
ALTER TABLE `book` ADD CONSTRAINT `test_uk_book_0` UNIQUE (`book_code`);
ALTER TABLE `book_copy` ADD CONSTRAINT `test_uk_book_copy_0` UNIQUE (`copy_no`);
ALTER TABLE `book_loan` ADD CONSTRAINT `test_uk_book_loan_0` UNIQUE (`external_loan_no`);
ALTER TABLE `book_reservation` ADD CONSTRAINT `test_uk_book_reservation_0` UNIQUE (`request_key`);
ALTER TABLE `message` ADD CONSTRAINT `test_uk_message_0` UNIQUE (`event_key`);
ALTER TABLE `message_receipt` ADD CONSTRAINT `test_uk_message_receipt_0` UNIQUE (`message_id`, `receiver_id`);
ALTER TABLE `file_upload` ADD CONSTRAINT `test_uk_file_upload_0` UNIQUE (`bucket_name`, `object_key`);
ALTER TABLE `system_config` ADD CONSTRAINT `test_uk_system_config_0` UNIQUE (`config_group`, `config_key`);
ALTER TABLE `async_task` ADD CONSTRAINT `test_uk_async_task_0` UNIQUE (`task_no`);
ALTER TABLE `outbox_event` ADD CONSTRAINT `test_uk_outbox_event_0` UNIQUE (`event_key`);
ALTER TABLE `device` ADD CONSTRAINT `test_uk_device_0` UNIQUE (`user_id`, `device_code`);
ALTER TABLE `continuation` ADD CONSTRAINT `test_uk_continuation_0` UNIQUE (`token_hash`);
ALTER TABLE `attendance_task` ADD CONSTRAINT `test_uk_attendance_task_0` UNIQUE (`timetable_id`, `class_date`);
ALTER TABLE `attendance_record` ADD CONSTRAINT `test_uk_attendance_record_0` UNIQUE (`task_id`, `student_id`);
