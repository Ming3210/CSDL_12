create database ss10_8;
use ss10_8;

-- 1
CREATE TABLE departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    manager VARCHAR(100) NOT NULL,
    budget DECIMAL(15,2) NOT NULL
);

CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    dept_id INT,
    salary DECIMAL(10,2) NOT NULL,
    hire_date DATE NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    emp_id INT,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status VARCHAR(50) NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);


-- 2
CREATE TABLE salary_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    old_salary DECIMAL(10,2) NOT NULL,
    new_salary DECIMAL(10,2) NOT NULL,
    change_date DATETIME NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);




-- 3

CREATE TABLE salary_warnings (
    warning_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    warning_message VARCHAR(255) NOT NULL,
    warning_date DATETIME NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);



-- 4
DELIMITER &&

CREATE TRIGGER after_salary_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
    VALUES (NEW.emp_id, OLD.salary, NEW.salary, NOW());

    IF NEW.salary < OLD.salary * 0.7 THEN
        INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
        VALUES (NEW.emp_id, 'Salary decreased by more than 30%', NOW());
    END IF;
    IF NEW.salary > OLD.salary * 1.5 THEN
        UPDATE employees 
        SET salary = OLD.salary * 1.5
        WHERE emp_id = NEW.emp_id;

        INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
        VALUES (NEW.emp_id, 'Salary increased above allowed threshold (adjusted to 150% of previous salary)', NOW());
    END IF;
END &&;



DELIMITER &&;


-- 5
DELIMITER &&

CREATE TRIGGER after_project_insert
AFTER INSERT ON projects
FOR EACH ROW
BEGIN
    DECLARE active_project_count INT;

    -- Kiểm tra số lượng dự án đang hoạt động của nhân viên
    SELECT COUNT(*) INTO active_project_count
    FROM projects
    WHERE emp_id = NEW.emp_id AND status = 'In Progress';

    IF active_project_count > 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee cannot be assigned to more than 3 active projects';
    END IF;

    -- Kiểm tra nếu trạng thái "In Progress" nhưng ngày bắt đầu lớn hơn hiện tại
    IF NEW.status = 'In Progress' AND NEW.start_date > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project status cannot be "In Progress" if start date is in the future';
    END IF;

END &&;

DELIMITER &&;



-- 6
CREATE VIEW PerformanceOverview AS
SELECT 
    p.project_id,
    p.name AS project_name,
    COUNT(p.emp_id) AS employee_count,
    DATEDIFF(p.end_date, p.start_date) AS total_days,
    p.status
FROM projects p
GROUP BY p.project_id, p.name, p.start_date, p.end_date, p.status;


-- 7
-- Cập nhật lương để kiểm tra trigger
UPDATE employees 
SET salary = salary * 0.5 
WHERE emp_id = 1;

UPDATE employees 
SET salary = salary * 2 
WHERE emp_id = 2;

-- Kiểm tra dữ liệu sau khi cập nhật
SELECT * FROM employees WHERE emp_id IN (1, 2);
SELECT * FROM salary_history ORDER BY change_date DESC;
SELECT * FROM salary_warnings ORDER BY warning_date DESC;



-- 8
-- Trường hợp 1: Thử thêm 4 dự án cho nhân viên có emp_id = 1
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 1', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 2', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 3', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 4', 1, CURDATE(), 'In Progress');

-- Trường hợp 2: Thêm dự án có ngày bắt đầu trong tương lai nhưng trạng thái là "In Progress"
-- Trigger sẽ chặn lại và hiển thị lỗi
INSERT INTO projects (name, emp_id, start_date, status) 
VALUES ('Future Project', 2, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'In Progress');

-- Kiểm tra các dự án đã được thêm thành công
SELECT * FROM projects WHERE emp_id IN (1,2);


-- 9
SELECT * FROM PerformanceOverview;
