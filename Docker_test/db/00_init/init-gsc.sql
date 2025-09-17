-- =========================================================
-- GSC Portal Database Schema
-- =========================================================

CREATE DATABASE IF NOT EXISTS gsc_portal
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE gsc_portal;

-- =========================================================
-- 01. Users & Roles
-- =========================================================
CREATE TABLE grade (
                       grade_id   VARCHAR(20) PRIMARY KEY,
                       name       VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE level (
                       level_id   VARCHAR(20) PRIMARY KEY,
                       name       VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE level_class (
                             class_id   VARCHAR(20) PRIMARY KEY,
                             level_id   VARCHAR(20) NOT NULL,
                             name       VARCHAR(50) NOT NULL,
                             CONSTRAINT fk_level_class FOREIGN KEY (level_id) REFERENCES level(level_id),
                             UNIQUE KEY ux_level_class_level_name (level_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE language (
                          language_id VARCHAR(10) PRIMARY KEY,
                          name        VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE user_account (
                              user_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                              name          VARCHAR(100) NOT NULL,
                              email         VARCHAR(200),
                              phone         VARCHAR(50),
                              role_type ENUM('student', 'professor', 'admin') NOT NULL DEFAULT 'student',
                              status        ENUM('active','inactive','pending') NOT NULL DEFAULT 'pending',
                              refresh_token VARCHAR(255),
                              updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                              UNIQUE KEY ux_user_email (email),
                              UNIQUE KEY ux_user_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE user_role (
                           user_id   BIGINT UNSIGNED NOT NULL,
                           role_type ENUM('student','professor','admin') NOT NULL,
                           PRIMARY KEY (user_id, role_type),
                           KEY ix_user_role_type (role_type),
                           CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES user_account(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_entity (
                                user_id          BIGINT UNSIGNED PRIMARY KEY,
                                grade_id         VARCHAR(20) NOT NULL,
                                class_id         VARCHAR(20) NOT NULL,
                                language_id      VARCHAR(10) NOT NULL,
                                is_international VARCHAR(10) NOT NULL DEFAULT FALSE,
                                status ENUM('enrolled','leave','dropped', 'graduated') NOT NULL DEFAULT 'enrolled',
                                KEY ix_student_grade (grade_id),
                                KEY ix_student_class (class_id),
                                KEY ix_student_language (language_id),
                                CONSTRAINT fk_student_user     FOREIGN KEY (user_id) REFERENCES user_account(user_id) ON DELETE CASCADE,
                                CONSTRAINT fk_student_grade    FOREIGN KEY (grade_id) REFERENCES grade(grade_id),
                                CONSTRAINT fk_student_class    FOREIGN KEY (class_id) REFERENCES level_class(class_id),
                                CONSTRAINT fk_student_language FOREIGN KEY (language_id) REFERENCES language(language_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 02. Messaging (Kakao)
-- =========================================================
CREATE TABLE kakao_user (
                            user_id     BIGINT UNSIGNED PRIMARY KEY,
                            kakao_id    VARCHAR(128) NOT NULL UNIQUE,
                            linked_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            is_verified BOOLEAN NOT NULL DEFAULT FALSE,
                            CONSTRAINT fk_kakao_user FOREIGN KEY (user_id) REFERENCES user_account(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 03. Academic Structure
-- =========================================================
CREATE TABLE section (
                         sec_id     VARCHAR(8) PRIMARY KEY,
                         semester   TINYINT NOT NULL,
                         year       YEAR NOT NULL,
                         start_date DATE,
                         end_date   DATE,
                         UNIQUE KEY ux_section_year_sem (year, semester)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE time_slot (
                           time_slot_id VARCHAR(6) PRIMARY KEY,
                           start_time   TIME NOT NULL,
                           end_time     TIME NOT NULL,
                           UNIQUE KEY ux_slot_day_time (start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE classroom (
                           classroom_id VARCHAR(6) PRIMARY KEY,
                           building     VARCHAR(50) NOT NULL,
                           room_number  VARCHAR(10) NOT NULL,
                           room_type    ENUM('CLASSROOM','LAB') NOT NULL DEFAULT 'CLASSROOM',
                           UNIQUE KEY ux_room_building_no (building, room_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course (
                        course_id  VARCHAR(15) PRIMARY KEY,
                        sec_id     VARCHAR(8) NOT NULL,
                        title      VARCHAR(100) NOT NULL,
                        is_special BOOLEAN NOT NULL DEFAULT FALSE,
                        KEY ix_course_sec_title (sec_id, title),
                        CONSTRAINT fk_course_sec FOREIGN KEY (sec_id) REFERENCES section(sec_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_schedule (
                                 schedule_id  VARCHAR(10) PRIMARY KEY,
                                 classroom_id VARCHAR(6)  NOT NULL,
                                 time_slot_id VARCHAR(6)  NOT NULL,
                                 course_id    VARCHAR(15) NOT NULL,
                                 sec_id       VARCHAR(8)  NOT NULL,
                                 day_of_week  ENUM('MON','TUE','WED','THU','FRI') NOT NULL,
    -- 한 강의실/시간/요일에는 하나의 수업만
                                 UNIQUE KEY ux_sched_slot_room (time_slot_id, classroom_id, day_of_week),
                                 KEY ix_sched_course_slot (sec_id, course_id, time_slot_id, day_of_week),
                                 KEY ix_sched_room_day (classroom_id, day_of_week),
                                 CONSTRAINT fk_sched_classroom FOREIGN KEY (classroom_id) REFERENCES classroom(classroom_id),
                                 CONSTRAINT fk_sched_timeslot  FOREIGN KEY (time_slot_id) REFERENCES time_slot(time_slot_id),
                                 CONSTRAINT fk_sched_course    FOREIGN KEY (course_id) REFERENCES course(course_id),
                                 CONSTRAINT fk_sched_section   FOREIGN KEY (sec_id) REFERENCES section(sec_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_target (
                               target_id   VARCHAR(10) PRIMARY KEY,
                               course_id   VARCHAR(15) NOT NULL,
                               grade_id    VARCHAR(20),
                               level_id    VARCHAR(20),
                               language_id VARCHAR(10),
                               UNIQUE KEY ux_course_target_combo (course_id, grade_id, level_id, language_id),
                               CONSTRAINT fk_ct_course FOREIGN KEY (course_id) REFERENCES course(course_id),
                               CONSTRAINT fk_ct_grade  FOREIGN KEY (grade_id) REFERENCES grade(grade_id),
                               CONSTRAINT fk_ct_level  FOREIGN KEY (level_id) REFERENCES level(level_id),
                               CONSTRAINT fk_ct_lang   FOREIGN KEY (language_id) REFERENCES language(language_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_language (
                                 course_id   VARCHAR(15) NOT NULL,
                                 language_id VARCHAR(10) NOT NULL,
                                 PRIMARY KEY (course_id, language_id),
                                 CONSTRAINT fk_cl_course FOREIGN KEY (course_id) REFERENCES course(course_id),
                                 CONSTRAINT fk_cl_lang   FOREIGN KEY (language_id) REFERENCES language(language_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 04. Notice & Event & Files
-- =========================================================
CREATE TABLE file_assets (
                             file_id    CHAR(10) PRIMARY KEY,
                             file_name  VARCHAR(255) NOT NULL,
                             file_url   TEXT NOT NULL,
                             size_type  INT,
                             file_type  ENUM('PDF','IMG') NOT NULL,
                             uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notice (
                        notice_id  INT PRIMARY KEY AUTO_INCREMENT,
                        user_id BIGINT not null,
                        course_id  VARCHAR(15),
                        title      VARCHAR(100) NOT NULL,
                        content    TEXT NOT NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        KEY ix_notice_course_time (course_id, created_at),
                        CONSTRAINT fk_notice_course FOREIGN KEY (course_id) REFERENCES course(course_id),
                        CONSTRAINT fk_notice_user FOREIGN KEY (user_id) REFERENCES user_account(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notice_file (
                             file_id   CHAR(10) NOT NULL,
                             notice_id INT NOT NULL,
                             PRIMARY KEY (notice_id, file_id),
                             CONSTRAINT fk_nf_file FOREIGN KEY (file_id) REFERENCES file_assets(file_id),
                             CONSTRAINT fk_nf_notice FOREIGN KEY (notice_id) REFERENCES notice(notice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notice_target (
                               target_id   CHAR(10) PRIMARY KEY,
                               notice_id   INT NOT NULL,
                               grade_id    VARCHAR(20),
                               level_id    VARCHAR(20),
                               language_id VARCHAR(10),
                               UNIQUE KEY ux_notice_target_combo (notice_id, grade_id, level_id, language_id),
                               CONSTRAINT fk_nt_notice FOREIGN KEY (notice_id) REFERENCES notice(notice_id),
                               CONSTRAINT fk_nt_grade  FOREIGN KEY (grade_id) REFERENCES grade(grade_id),
                               CONSTRAINT fk_nt_level  FOREIGN KEY (level_id) REFERENCES level(level_id),
                               CONSTRAINT fk_nt_lang   FOREIGN KEY (language_id) REFERENCES language(language_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notification_delivery_notice (
                                              delivery_id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                              user_id     BIGINT UNSIGNED NOT NULL,
                                              notice_id   INT NOT NULL,
                                              message_id  VARCHAR(64) NOT NULL,
                                              send_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
                                              read_at     DATETIME,
                                              status      ENUM('QUEUED','SENT','FAILED') NOT NULL DEFAULT 'QUEUED',
                                              UNIQUE KEY ux_ndn_notice_user (notice_id, user_id),
                                              UNIQUE KEY ux_ndn_message (message_id),
                                              KEY ix_ndn_inbox (user_id, status, read_at),
                                              CONSTRAINT fk_ndn_user   FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                                              CONSTRAINT fk_ndn_notice FOREIGN KEY (notice_id) REFERENCES notice(notice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_event (
                              event_id    CHAR(10) PRIMARY KEY,
                              schedule_id VARCHAR(10) NOT NULL,
                              event_type  ENUM('CANCEL','MAKEUP') NOT NULL,
                              event_date  DATE NOT NULL,
                              UNIQUE KEY ux_event_sched_date_type (schedule_id, event_date, event_type),
                              KEY ix_event_date (event_date),
                              CONSTRAINT fk_event_sched FOREIGN KEY (schedule_id) REFERENCES course_schedule(schedule_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notification_delivery_event (
                                             delivery_id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                             user_id     BIGINT UNSIGNED NOT NULL,
                                             event_id    CHAR(10) NOT NULL,
                                             message_id  VARCHAR(64) NOT NULL,
                                             send_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
                                             read_at     DATETIME,
                                             status      ENUM('QUEUED','SENT','FAILED') NOT NULL DEFAULT 'QUEUED',
                                             UNIQUE KEY ux_nde_event_user (event_id, user_id),
                                             UNIQUE KEY ux_nde_message (message_id),
                                             KEY ix_nde_inbox (user_id, status, read_at),
                                             CONSTRAINT fk_nde_user  FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                                             CONSTRAINT fk_nde_event FOREIGN KEY (event_id) REFERENCES course_event(event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE log_entity (
                            log_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
                            user_id   BIGINT UNSIGNED NOT NULL,
                            action    ENUM('LOGIN','READ_NOTICE','READ_EVENT','RESERVE','VOTE') NOT NULL,
                            event_time DATETIME DEFAULT CURRENT_TIMESTAMP,
                            KEY ix_log_user_time (user_id, action, event_time),
                            CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES user_account(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE allowed_email (
                               id     INT PRIMARY KEY AUTO_INCREMENT,
                               email  VARCHAR(200) NOT NULL UNIQUE,
                               reason VARCHAR(100),
                               tag    VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_exams (
                               exam_id   CHAR(10) PRIMARY KEY,
                               user_id   BIGINT UNSIGNED NOT NULL,
                               file_id   CHAR(10),
                               level_id  VARCHAR(20),
                               exam_type ENUM('JLPT','TOPIK'),
                               score     INT,
                               UNIQUE KEY ux_exam_user_type_level (user_id, exam_type, level_id),
                               CONSTRAINT fk_exam_user FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                               CONSTRAINT fk_exam_file FOREIGN KEY (file_id) REFERENCES file_assets(file_id),
                               CONSTRAINT fk_exam_level FOREIGN KEY (level_id) REFERENCES level(level_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_professor (
                                  user_id   BIGINT UNSIGNED NOT NULL,
                                  course_id VARCHAR(15) NOT NULL,
                                  PRIMARY KEY (user_id, course_id),
                                  CONSTRAINT fk_cp_user   FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                                  CONSTRAINT fk_cp_course FOREIGN KEY (course_id) REFERENCES course(course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_student (
                                user_id   BIGINT UNSIGNED NOT NULL,
                                course_id VARCHAR(15) NOT NULL,
                                PRIMARY KEY (user_id, course_id),
                                CONSTRAINT fk_cs_user   FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                                CONSTRAINT fk_cs_course FOREIGN KEY (course_id) REFERENCES course(course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 05. Reservations
-- =========================================================
CREATE TABLE reservation (
                             reservation_id BIGINT PRIMARY KEY AUTO_INCREMENT,
                             user_id        BIGINT UNSIGNED NOT NULL,
                             classroom_id   VARCHAR(6) NOT NULL,
                             title          VARCHAR(100),
                             start_at       DATETIME NOT NULL,
                             end_at         DATETIME NOT NULL,
                             status         ENUM('ACTIVE','CANCELLED','FINISHED') NOT NULL DEFAULT 'ACTIVE',
                             created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
                             KEY ux_start (classroom_id, start_at),
                             KEY ux_end   (classroom_id, end_at),
                             CONSTRAINT fk_resv_user FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                             CONSTRAINT fk_resv_room FOREIGN KEY (classroom_id) REFERENCES classroom(classroom_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE weekend_attendance_poll (
                                         poll_id       CHAR(10) PRIMARY KEY,
                                         grade_id      VARCHAR(20),
                                         classroom_id  VARCHAR(6) NOT NULL,
                                         poll_date     DATE NOT NULL,
                                         target_weekend ENUM('SAT','SUN'),
                                         required_count INT NOT NULL DEFAULT 8,
                                         status        BOOLEAN NOT NULL DEFAULT FALSE,
                                         created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
                                         UNIQUE KEY ux_poll_room_date_day (classroom_id, poll_date, target_weekend),
                                         CONSTRAINT fk_poll_grade FOREIGN KEY (grade_id) REFERENCES grade(grade_id),
                                         CONSTRAINT fk_poll_room  FOREIGN KEY (classroom_id) REFERENCES classroom(classroom_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE weekend_attendance_votes (
                                          votes_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
                                          user_id   BIGINT UNSIGNED NOT NULL,
                                          poll_id   CHAR(10) NOT NULL,
                                          will_join BOOLEAN NOT NULL,
                                          voted_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
                                          UNIQUE KEY ux_poll_user_once (poll_id, user_id),
                                          CONSTRAINT fk_vote_user FOREIGN KEY (user_id) REFERENCES user_account(user_id),
                                          CONSTRAINT fk_vote_poll FOREIGN KEY (poll_id) REFERENCES weekend_attendance_poll(poll_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- 06. Cleaning
-- =========================================================
CREATE TABLE cleaning_assignment (
                                     assignment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                     grade_id      VARCHAR(20) NOT NULL,
                                     classroom_id  VARCHAR(6) NOT NULL,
                                     work_date     DATE NOT NULL,
                                     team_size     TINYINT NOT NULL DEFAULT 4,
                                     members_json  JSON,
                                     status        ENUM('SCHEDULED','DONE','MISSED','CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
                                     created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
                                     confirmed_at  DATETIME,
                                     UNIQUE KEY ux_cleaning_scope_day (grade_id, classroom_id, work_date),
                                     KEY ix_cleaning_date (work_date),
                                     CONSTRAINT fk_clean_grade FOREIGN KEY (grade_id) REFERENCES grade(grade_id),
                                     CONSTRAINT fk_clean_room  FOREIGN KEY (classroom_id) REFERENCES classroom(classroom_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;