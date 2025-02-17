-- 1
create database ss10_7;
use ss10_7;

create table departments (
    dept_id int auto_increment primary key,
    name varchar(100) not null,
    manager varchar(100) not null,
    budget decimal(15,2) not null
);

create table employees (
    emp_id int auto_increment primary key,
    name varchar(100) not null,
    dept_id int,
    salary decimal(10,2) not null,
    hire_date date not null,
    foreign key (dept_id) references departments(dept_id)
);

create table projects (
    project_id int auto_increment primary key,
    name varchar(100) not null,
    emp_id int,
    start_date date not null,
    end_date date null,
    status varchar(50) not null,
    foreign key (emp_id) references employees(emp_id)
);

-- 2
DELIMITER &&

CREATE TRIGGER before_insert_employee
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    -- Kiểm tra nếu lương thấp hơn 500
    IF NEW.salary < 500 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary must be at least 500';
    END IF;

    -- Kiểm tra nếu phòng ban (dept_id) không tồn tại
    IF (SELECT COUNT(*) FROM departments WHERE dept_id = NEW.dept_id) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Department does not exist';
    END IF;

    -- Kiểm tra nếu tất cả dự án trong phòng ban đã hoàn thành
    IF (SELECT COUNT(*) FROM projects 
        WHERE emp_id IN (SELECT emp_id FROM employees WHERE dept_id = NEW.dept_id)
        AND status != 'Completed') = 0 
        AND (SELECT COUNT(*) FROM employees WHERE dept_id = NEW.dept_id) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'All projects in this department are completed. Cannot add new employee.';
    END IF;

END &&

DELIMITER ;




-- 3
create table project_warnings (
    warning_id int auto_increment primary key,
    project_id int not null,
    warning_message varchar(255) not null,
    warning_date timestamp default current_timestamp,
    foreign key (project_id) references projects(project_id)
);

create table dept_warnings (
    warning_id int auto_increment primary key,
    dept_id int not null,
    warning_message varchar(255) not null,
    warning_date timestamp default current_timestamp,
    foreign key (dept_id) references departments(dept_id)
);

DELIMITER &&

CREATE TRIGGER after_update_project
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    IF NEW.status = 'Delayed' THEN
        INSERT INTO project_warnings (project_id, warning_message)
        VALUES (NEW.project_id, 'Project has been delayed');
    END IF;
    
    -- Nếu trạng thái là "Completed"
    IF NEW.status = 'Completed' THEN
        -- Cập nhật ngày kết thúc nếu chưa có
        IF NEW.end_date IS NULL THEN
            UPDATE projects SET end_date = CURDATE() WHERE project_id = NEW.project_id;
        END IF;
        
        -- Kiểm tra tổng lương nhân viên trong phòng ban có vượt ngân sách không
        IF (SELECT SUM(salary) FROM employees WHERE dept_id = (SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id)) 
            > (SELECT budget FROM departments WHERE dept_id = (SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id)) THEN
            
            INSERT INTO dept_warnings (dept_id, warning_message)
            VALUES ((SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id), 'Department salary exceeds budget');
        END IF;
    END IF;
END &&

DELIMITER ;


-- 4
CREATE VIEW FullOverview AS
SELECT 
    e.emp_id,
    e.name AS employee_name,
    d.name AS department_name,
    p.name AS project_name,
    p.status,
    CONCAT('$', FORMAT(e.salary, 2)) AS salary,
    COALESCE(w.warning_message, '') AS warning_message
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN projects p ON e.emp_id = p.emp_id
LEFT JOIN project_warnings w ON p.project_id = w.project_id;



-- 5
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Alice', 1, 600, '2023-07-01');
-- Lỗi: salary phải >= 500

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Bob', 999, 1000, '2023-07-01'); 
-- Nếu dept_id = 999 không tồn tại, sẽ báo lỗi ràng buộc khóa ngoại

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Charlie', 2, 1500, '2023-07-01'); 
-- Thành công nếu dept_id = 2 tồn tại và còn dự án chưa hoàn thành

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('David', 1, 2000, '2023-07-01');
-- Thành công nếu dept_id = 1 còn dự án chưa hoàn thành

-- 6
UPDATE projects SET status = 'Delayed' WHERE project_id = 1;
-- Ghi cảnh báo vào bảng `project_warnings`.

UPDATE projects SET status = 'Completed', end_date = NULL WHERE project_id = 2;
-- Tự động cập nhật `end_date = CURDATE()`, kiểm tra tổng lương phòng ban.


UPDATE projects SET status = 'Completed' WHERE project_id = 3;
-- Kiểm tra tổng lương phòng ban, nếu vượt ngân sách thì ghi vào `dept_warnings`.

UPDATE projects SET status = 'In Progress' WHERE project_id = 4;
-- Không có tác động gì đặc biệt.


-- 7
SELECT * FROM FullOverview;

