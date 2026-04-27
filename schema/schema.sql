-- ============================================================
-- UNIVERSITY MANAGEMENT SYSTEM — DATABASE SCHEMA
-- Full RBAC: Admin (master), Staff/Teacher (edit+print), Student (view)
-- ============================================================

CREATE DATABASE IF NOT EXISTS university_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE university_db;

-- ─────────────────────────────────────────────
-- 1. ROLES & USERS
-- ─────────────────────────────────────────────

CREATE TABLE roles (
  role_id   TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  role_name ENUM('admin','staff','student') NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (role_name) VALUES ('admin'),('staff'),('student');

CREATE TABLE users (
  user_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  full_name     VARCHAR(120)  NOT NULL,
  email         VARCHAR(180)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,          -- bcrypt / argon2
  role_id       TINYINT UNSIGNED NOT NULL,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_role   ON users(role_id);

-- ─────────────────────────────────────────────
-- 2. DEPARTMENTS & PROGRAMS
-- ─────────────────────────────────────────────

CREATE TABLE departments (
  dept_id    SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  dept_name  VARCHAR(120) NOT NULL UNIQUE,
  dept_code  VARCHAR(10)  NOT NULL UNIQUE,
  hod_id     INT UNSIGNED,                        -- head of department (staff)
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE programs (
  program_id   SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  program_name VARCHAR(150) NOT NULL,
  degree_type  ENUM('UG','PG','PhD','Diploma') NOT NULL,
  dept_id      SMALLINT UNSIGNED NOT NULL,
  duration_yrs TINYINT UNSIGNED DEFAULT 4,
  CONSTRAINT fk_prog_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- ─────────────────────────────────────────────
-- 3. ACADEMIC YEAR & SEMESTERS
-- ─────────────────────────────────────────────

CREATE TABLE academic_years (
  ay_id      SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  label      VARCHAR(20) NOT NULL UNIQUE,    -- e.g. '2023-24'
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL
);

CREATE TABLE semesters (
  sem_id    SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  ay_id     SMALLINT UNSIGNED NOT NULL,
  sem_no    TINYINT UNSIGNED NOT NULL,       -- 1-8 for UG
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  is_current BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_sem_ay FOREIGN KEY (ay_id) REFERENCES academic_years(ay_id),
  UNIQUE KEY uq_sem (ay_id, sem_no)
);

-- ─────────────────────────────────────────────
-- 4. STAFF (TEACHERS)
-- ─────────────────────────────────────────────

CREATE TABLE staff (
  staff_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id        INT UNSIGNED NOT NULL UNIQUE,
  employee_code  VARCHAR(20)  NOT NULL UNIQUE,
  dept_id        SMALLINT UNSIGNED NOT NULL,
  designation    VARCHAR(80),
  joining_date   DATE,
  phone          VARCHAR(15),
  CONSTRAINT fk_staff_user FOREIGN KEY (user_id)  REFERENCES users(user_id),
  CONSTRAINT fk_staff_dept FOREIGN KEY (dept_id)  REFERENCES departments(dept_id)
);

ALTER TABLE departments
  ADD CONSTRAINT fk_dept_hod FOREIGN KEY (hod_id) REFERENCES staff(staff_id);

-- ─────────────────────────────────────────────
-- 5. STUDENTS
-- ─────────────────────────────────────────────

CREATE TABLE students (
  student_id    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id       INT UNSIGNED NOT NULL UNIQUE,
  roll_number   VARCHAR(20)  NOT NULL UNIQUE,
  program_id    SMALLINT UNSIGNED NOT NULL,
  current_sem   TINYINT UNSIGNED DEFAULT 1,
  dob           DATE,
  gender        ENUM('M','F','Other'),
  phone         VARCHAR(15),
  address       TEXT,
  guardian_name VARCHAR(120),
  admitted_ay   SMALLINT UNSIGNED,
  photo_url     VARCHAR(255),
  CONSTRAINT fk_stu_user    FOREIGN KEY (user_id)     REFERENCES users(user_id),
  CONSTRAINT fk_stu_prog    FOREIGN KEY (program_id)  REFERENCES programs(program_id),
  CONSTRAINT fk_stu_ay      FOREIGN KEY (admitted_ay) REFERENCES academic_years(ay_id)
);

CREATE INDEX idx_stu_roll ON students(roll_number);
CREATE INDEX idx_stu_prog ON students(program_id);

-- ─────────────────────────────────────────────
-- 6. COURSES & COURSE ASSIGNMENTS
-- ─────────────────────────────────────────────

CREATE TABLE courses (
  course_id    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  course_code  VARCHAR(20) NOT NULL UNIQUE,
  course_name  VARCHAR(180) NOT NULL,
  credits      TINYINT UNSIGNED DEFAULT 3,
  dept_id      SMALLINT UNSIGNED NOT NULL,
  course_type  ENUM('Theory','Lab','Elective','Project') DEFAULT 'Theory',
  CONSTRAINT fk_course_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Which staff teaches which course in which semester
CREATE TABLE course_assignments (
  assignment_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  course_id     INT UNSIGNED NOT NULL,
  staff_id      INT UNSIGNED NOT NULL,
  sem_id        SMALLINT UNSIGNED NOT NULL,
  section       VARCHAR(5) DEFAULT 'A',
  CONSTRAINT fk_ca_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
  CONSTRAINT fk_ca_staff  FOREIGN KEY (staff_id)  REFERENCES staff(staff_id),
  CONSTRAINT fk_ca_sem    FOREIGN KEY (sem_id)    REFERENCES semesters(sem_id),
  UNIQUE KEY uq_ca (course_id, staff_id, sem_id, section)
);

-- Which students are enrolled in which course-assignment
CREATE TABLE enrollments (
  enrollment_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  student_id     INT UNSIGNED NOT NULL,
  assignment_id  INT UNSIGNED NOT NULL,
  enrolled_on    DATE DEFAULT (CURRENT_DATE),
  status         ENUM('active','dropped','completed') DEFAULT 'active',
  CONSTRAINT fk_enr_stu FOREIGN KEY (student_id)    REFERENCES students(student_id),
  CONSTRAINT fk_enr_ca  FOREIGN KEY (assignment_id) REFERENCES course_assignments(assignment_id),
  UNIQUE KEY uq_enr (student_id, assignment_id)
);

-- ─────────────────────────────────────────────
-- 7. ATTENDANCE
-- ─────────────────────────────────────────────

CREATE TABLE attendance_sessions (
  session_id    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  assignment_id INT UNSIGNED NOT NULL,
  session_date  DATE NOT NULL,
  session_type  ENUM('lecture','lab','tutorial') DEFAULT 'lecture',
  topic_covered VARCHAR(255),
  marked_by     INT UNSIGNED,               -- staff_id who marked
  marked_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_as_ca    FOREIGN KEY (assignment_id) REFERENCES course_assignments(assignment_id),
  CONSTRAINT fk_as_staff FOREIGN KEY (marked_by)    REFERENCES staff(staff_id),
  UNIQUE KEY uq_session (assignment_id, session_date, session_type)
);

CREATE TABLE attendance_records (
  record_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  session_id  INT UNSIGNED NOT NULL,
  student_id  INT UNSIGNED NOT NULL,
  status      ENUM('present','absent','late','excused') DEFAULT 'absent',
  remarks     VARCHAR(120),
  CONSTRAINT fk_ar_session FOREIGN KEY (session_id) REFERENCES attendance_sessions(session_id),
  CONSTRAINT fk_ar_stu     FOREIGN KEY (student_id) REFERENCES students(student_id),
  UNIQUE KEY uq_ar (session_id, student_id)
);

CREATE INDEX idx_ar_student ON attendance_records(student_id);
CREATE INDEX idx_ar_session ON attendance_records(session_id);

-- Materialized attendance summary (updated via trigger)
CREATE TABLE attendance_summary (
  summary_id    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  student_id    INT UNSIGNED NOT NULL,
  assignment_id INT UNSIGNED NOT NULL,
  total_classes INT UNSIGNED DEFAULT 0,
  present_count INT UNSIGNED DEFAULT 0,
  late_count    INT UNSIGNED DEFAULT 0,
  percentage    DECIMAL(5,2) GENERATED ALWAYS AS
                  (IF(total_classes=0, 0, (present_count+late_count)*100.0/total_classes)) STORED,
  last_updated  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ats_stu FOREIGN KEY (student_id)    REFERENCES students(student_id),
  CONSTRAINT fk_ats_ca  FOREIGN KEY (assignment_id) REFERENCES course_assignments(assignment_id),
  UNIQUE KEY uq_ats (student_id, assignment_id)
);

-- ─────────────────────────────────────────────
-- 8. GRADES & MARKS
-- ─────────────────────────────────────────────

CREATE TABLE exam_types (
  exam_type_id   TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  type_name      VARCHAR(50) NOT NULL UNIQUE,   -- 'Internal', 'Mid-Sem', 'End-Sem'
  weightage_pct  DECIMAL(5,2) DEFAULT 100.00
);

INSERT INTO exam_types (type_name, weightage_pct)
VALUES ('Internal',30),('Mid-Sem',20),('End-Sem',50);

CREATE TABLE marks (
  mark_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  enrollment_id INT UNSIGNED NOT NULL,
  exam_type_id  TINYINT UNSIGNED NOT NULL,
  max_marks     DECIMAL(6,2) NOT NULL DEFAULT 100,
  scored_marks  DECIMAL(6,2),
  grade         VARCHAR(5),
  grade_points  DECIMAL(4,2),
  entered_by    INT UNSIGNED,
  entered_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_marks_enr  FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id),
  CONSTRAINT fk_marks_et   FOREIGN KEY (exam_type_id)  REFERENCES exam_types(exam_type_id),
  CONSTRAINT fk_marks_staff FOREIGN KEY (entered_by)   REFERENCES staff(staff_id),
  UNIQUE KEY uq_marks (enrollment_id, exam_type_id)
);

-- ─────────────────────────────────────────────
-- 9. TIMETABLE
-- ─────────────────────────────────────────────

CREATE TABLE timetable (
  slot_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  assignment_id INT UNSIGNED NOT NULL,
  day_of_week   TINYINT UNSIGNED NOT NULL CHECK (day_of_week BETWEEN 1 AND 6),
  start_time    TIME NOT NULL,
  end_time      TIME NOT NULL,
  room_no       VARCHAR(20),
  sem_id        SMALLINT UNSIGNED NOT NULL,
  CONSTRAINT fk_tt_ca  FOREIGN KEY (assignment_id) REFERENCES course_assignments(assignment_id),
  CONSTRAINT fk_tt_sem FOREIGN KEY (sem_id)        REFERENCES semesters(sem_id)
);

-- ─────────────────────────────────────────────
-- 10. ANNOUNCEMENTS / NOTICES
-- ─────────────────────────────────────────────

CREATE TABLE announcements (
  ann_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  title        VARCHAR(200) NOT NULL,
  body         TEXT,
  posted_by    INT UNSIGNED NOT NULL,           -- user_id
  target_role  ENUM('all','student','staff','admin') DEFAULT 'all',
  dept_id      SMALLINT UNSIGNED,               -- NULL = all depts
  is_pinned    BOOLEAN DEFAULT FALSE,
  expires_on   DATE,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ann_user FOREIGN KEY (posted_by) REFERENCES users(user_id),
  CONSTRAINT fk_ann_dept FOREIGN KEY (dept_id)   REFERENCES departments(dept_id)
);

-- ─────────────────────────────────────────────
-- 11. AUDIT / ACTIVITY LOG
-- ─────────────────────────────────────────────

CREATE TABLE audit_log (
  log_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id     INT UNSIGNED,
  action      VARCHAR(100) NOT NULL,
  table_name  VARCHAR(60),
  record_id   VARCHAR(40),
  old_value   JSON,
  new_value   JSON,
  ip_address  VARCHAR(45),
  logged_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ─────────────────────────────────────────────
-- 12. TRIGGERS — AUTO-UPDATE ATTENDANCE SUMMARY
-- ─────────────────────────────────────────────

DELIMITER $$

CREATE TRIGGER trg_attendance_after_insert
AFTER INSERT ON attendance_records
FOR EACH ROW
BEGIN
  DECLARE v_assignment_id INT UNSIGNED;
  SELECT assignment_id INTO v_assignment_id
    FROM attendance_sessions WHERE session_id = NEW.session_id;

  INSERT INTO attendance_summary (student_id, assignment_id, total_classes, present_count, late_count)
  VALUES (NEW.student_id, v_assignment_id, 1,
          IF(NEW.status='present',1,0),
          IF(NEW.status='late',1,0))
  ON DUPLICATE KEY UPDATE
    total_classes  = total_classes + 1,
    present_count  = present_count + IF(NEW.status='present',1,0),
    late_count     = late_count    + IF(NEW.status='late',1,0);
END$$

CREATE TRIGGER trg_attendance_after_update
AFTER UPDATE ON attendance_records
FOR EACH ROW
BEGIN
  DECLARE v_assignment_id INT UNSIGNED;
  SELECT assignment_id INTO v_assignment_id
    FROM attendance_sessions WHERE session_id = NEW.session_id;

  UPDATE attendance_summary
  SET present_count = present_count
        - IF(OLD.status='present',1,0)
        + IF(NEW.status='present',1,0),
      late_count    = late_count
        - IF(OLD.status='late',1,0)
        + IF(NEW.status='late',1,0)
  WHERE student_id=NEW.student_id AND assignment_id=v_assignment_id;
END$$

DELIMITER ;

-- ─────────────────────────────────────────────
-- 13. VIEWS FOR QUICK REPORTING
-- ─────────────────────────────────────────────

-- Attendance overview per student per course
CREATE OR REPLACE VIEW vw_attendance_overview AS
SELECT
  s.roll_number,
  u.full_name AS student_name,
  c.course_code,
  c.course_name,
  sm.sem_no,
  ay.label AS academic_year,
  ats.total_classes,
  ats.present_count,
  ats.percentage AS attendance_pct,
  CASE WHEN ats.percentage >= 75 THEN 'Eligible'
       WHEN ats.percentage >= 60 THEN 'Condonation'
       ELSE 'Detained' END AS eligibility
FROM attendance_summary ats
JOIN students       s   ON s.student_id    = ats.student_id
JOIN users          u   ON u.user_id       = s.user_id
JOIN course_assignments ca ON ca.assignment_id = ats.assignment_id
JOIN courses        c   ON c.course_id     = ca.course_id
JOIN semesters      sm  ON sm.sem_id       = ca.sem_id
JOIN academic_years ay  ON ay.ay_id        = sm.ay_id;

-- Student full profile
CREATE OR REPLACE VIEW vw_student_profile AS
SELECT
  s.student_id, s.roll_number, u.full_name, u.email,
  p.program_name, d.dept_name, p.degree_type,
  s.current_sem, ay.label AS admitted_year,
  s.dob, s.gender, s.phone, s.guardian_name
FROM students s
JOIN users          u  ON u.user_id    = s.user_id
JOIN programs       p  ON p.program_id = s.program_id
JOIN departments    d  ON d.dept_id    = p.dept_id
LEFT JOIN academic_years ay ON ay.ay_id = s.admitted_ay;

-- Consolidated marks sheet
CREATE OR REPLACE VIEW vw_marks_sheet AS
SELECT
  s.roll_number,
  u.full_name AS student_name,
  c.course_code,
  c.course_name,
  et.type_name AS exam_type,
  m.max_marks,
  m.scored_marks,
  ROUND(m.scored_marks / m.max_marks * 100, 2) AS percentage,
  m.grade,
  m.grade_points
FROM marks m
JOIN enrollments    e   ON e.enrollment_id  = m.enrollment_id
JOIN students       s   ON s.student_id     = e.student_id
JOIN users          u   ON u.user_id        = s.user_id
JOIN course_assignments ca ON ca.assignment_id = e.assignment_id
JOIN courses        c   ON c.course_id      = ca.course_id
JOIN exam_types     et  ON et.exam_type_id  = m.exam_type_id;

-- ─────────────────────────────────────────────
-- 14. STORED PROCEDURES
-- ─────────────────────────────────────────────

DELIMITER $$

-- Mark bulk attendance for a session
CREATE PROCEDURE sp_mark_attendance(
  IN p_assignment_id INT UNSIGNED,
  IN p_date          DATE,
  IN p_type          VARCHAR(20),
  IN p_topic         VARCHAR(255),
  IN p_staff_id      INT UNSIGNED
)
BEGIN
  DECLARE v_session_id INT UNSIGNED;

  INSERT IGNORE INTO attendance_sessions
    (assignment_id, session_date, session_type, topic_covered, marked_by)
  VALUES
    (p_assignment_id, p_date, p_type, p_topic, p_staff_id);

  SET v_session_id = LAST_INSERT_ID();

  -- Default all enrolled students to 'absent'
  INSERT IGNORE INTO attendance_records (session_id, student_id, status)
  SELECT v_session_id, e.student_id, 'absent'
  FROM enrollments e
  WHERE e.assignment_id = p_assignment_id AND e.status = 'active';

  SELECT v_session_id AS session_id;
END$$

-- Get student GPA for a semester
CREATE PROCEDURE sp_student_gpa(
  IN p_student_id INT UNSIGNED,
  IN p_sem_id     SMALLINT UNSIGNED
)
BEGIN
  SELECT
    s.roll_number,
    u.full_name,
    sm.sem_no,
    ROUND(SUM(m.grade_points * c.credits) / SUM(c.credits), 2) AS SGPA,
    SUM(c.credits) AS total_credits
  FROM marks m
  JOIN enrollments e   ON e.enrollment_id  = m.enrollment_id AND e.student_id = p_student_id
  JOIN course_assignments ca ON ca.assignment_id = e.assignment_id AND ca.sem_id = p_sem_id
  JOIN courses     c   ON c.course_id   = ca.course_id
  JOIN exam_types  et  ON et.exam_type_id = m.exam_type_id AND et.type_name = 'End-Sem'
  JOIN students    s   ON s.student_id  = p_student_id
  JOIN users       u   ON u.user_id     = s.user_id
  JOIN semesters   sm  ON sm.sem_id     = p_sem_id
  GROUP BY s.roll_number, u.full_name, sm.sem_no;
END$$

DELIMITER ;

-- ─────────────────────────────────────────────
-- 15. RBAC PERMISSIONS (application-level reference)
-- ─────────────────────────────────────────────

CREATE TABLE permissions (
  perm_id     SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  perm_code   VARCHAR(60) NOT NULL UNIQUE,
  description VARCHAR(200)
);

INSERT INTO permissions (perm_code, description) VALUES
  ('user.create',            'Create new users'),
  ('user.edit',              'Edit any user'),
  ('user.delete',            'Delete / deactivate users'),
  ('student.view',           'View student records'),
  ('student.edit',           'Edit student records'),
  ('attendance.mark',        'Mark attendance'),
  ('attendance.edit',        'Edit attendance after submission'),
  ('attendance.view',        'View attendance reports'),
  ('attendance.print',       'Print / export attendance'),
  ('marks.enter',            'Enter/edit marks'),
  ('marks.view',             'View marks'),
  ('marks.print',            'Print marks sheet'),
  ('course.manage',          'Create/edit courses and assignments'),
  ('announcement.post',      'Post announcements'),
  ('report.generate',        'Generate system-wide reports'),
  ('system.audit',           'View audit log');

CREATE TABLE role_permissions (
  role_id  TINYINT UNSIGNED NOT NULL,
  perm_id  SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, perm_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(role_id),
  CONSTRAINT fk_rp_perm FOREIGN KEY (perm_id) REFERENCES permissions(perm_id)
);

-- Admin gets ALL permissions
INSERT INTO role_permissions (role_id, perm_id)
SELECT 1, perm_id FROM permissions;

-- Staff: edit & print but not admin actions
INSERT INTO role_permissions (role_id, perm_id)
SELECT 2, perm_id FROM permissions
WHERE perm_code IN (
  'student.view','student.edit',
  'attendance.mark','attendance.edit','attendance.view','attendance.print',
  'marks.enter','marks.view','marks.print',
  'course.manage','announcement.post'
);

-- Student: view only
INSERT INTO role_permissions (role_id, perm_id)
SELECT 3, perm_id FROM permissions
WHERE perm_code IN (
  'student.view','attendance.view','marks.view'
);

-- ─────────────────────────────────────────────
-- 16. SAMPLE SEED DATA
-- ─────────────────────────────────────────────

-- Departments
INSERT INTO departments (dept_name, dept_code) VALUES
  ('Computer Science & Engineering', 'CSE'),
  ('Electronics & Communication',    'ECE'),
  ('Mechanical Engineering',          'MECH'),
  ('Business Administration',         'BBA');

-- Programs
INSERT INTO programs (program_name, degree_type, dept_id, duration_yrs) VALUES
  ('B.E. Computer Science',          'UG',  1, 4),
  ('B.E. Electronics & Communication','UG', 2, 4),
  ('B.E. Mechanical Engineering',    'UG',  3, 4),
  ('MBA',                            'PG',  4, 2);

-- Academic year
INSERT INTO academic_years (label, start_date, end_date) VALUES ('2023-24','2023-06-01','2024-05-31');

-- Semesters
INSERT INTO semesters (ay_id, sem_no, start_date, end_date, is_current) VALUES
  (1,1,'2023-06-01','2023-11-30',FALSE),
  (1,2,'2024-01-01','2024-05-31',TRUE);

-- Admin user (password: Admin@123 — bcrypt hash placeholder)
INSERT INTO users (full_name, email, password_hash, role_id) VALUES
  ('Super Admin',       'admin@university.edu',   '$2b$12$PLACEHOLDER_ADMIN_HASH',   1),
  ('Dr. Priya Sharma',  'priya@university.edu',   '$2b$12$PLACEHOLDER_STAFF_HASH',   2),
  ('Rahul Venkatesh',   'rahul@student.edu',      '$2b$12$PLACEHOLDER_STUDENT_HASH', 3);

INSERT INTO staff (user_id, employee_code, dept_id, designation, joining_date)
  VALUES (2, 'EMP001', 1, 'Associate Professor', '2018-07-15');

INSERT INTO students (user_id, roll_number, program_id, current_sem, dob, gender, admitted_ay)
  VALUES (3, 'CS2023001', 1, 2, '2005-03-22', 'M', 1);

-- Courses
INSERT INTO courses (course_code, course_name, credits, dept_id) VALUES
  ('CS301','Data Structures & Algorithms', 4, 1),
  ('CS302','Database Management Systems',  3, 1),
  ('CS303','Operating Systems',            3, 1);

-- Course assignments (sem 2)
INSERT INTO course_assignments (course_id, staff_id, sem_id, section) VALUES
  (1, 1, 2, 'A'),
  (2, 1, 2, 'A'),
  (3, 1, 2, 'A');

-- Enroll student
INSERT INTO enrollments (student_id, assignment_id)
  VALUES (1,1),(1,2),(1,3);
