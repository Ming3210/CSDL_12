-- 2
create table budget_warnings (
    warning_id int auto_increment primary key,
    project_id int not null,
    warning_message varchar(255) not null,
    foreign key (project_id) references projects(project_id)
);


-- 3
DELIMITER &&

create trigger after_update_project
after update on projects
for each row
begin
    if new.total_salary > new.budget then
        -- Kiểm tra xem dự án đã có cảnh báo trước đó chưa
        if not exists (select 1 from budget_warnings where project_id = new.project_id) then
            insert into budget_warnings (project_id, warning_message) 
            values (new.project_id, 'Budget exceeded due to high salary');
        end if;
    end if;
end &&;


DELIMITER ;


-- 4
create view ProjectOverview as
select 
    p.project_id, 
    p.p_name as project_name, 
    p.budget, 
    p.total_salary, 
    bw.warning_message
from projects p
left join budget_warnings bw on p.project_id = bw.project_id;


-- 5
insert into workers (name, project_id, salary) values ('michael', 1, 6000.00);
insert into workers (name, project_id, salary) values ('sarah', 2, 10000.00);
insert into workers (name, project_id, salary) values ('david', 3, 1000.00);




-- 6
select * from budget_warnings;

select * from projectoverview;