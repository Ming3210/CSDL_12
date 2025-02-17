-- 2
create table deleted_orders (
    deleted_id int auto_increment primary key,
    order_id int not null,
    customer_name varchar(100) not null,
    product varchar(100) not null,
    order_date date not null,
    deleted_at datetime not null
);


-- 3
DELIMITER &&

create trigger after_delete_orders
after delete on orders
for each row
begin
    insert into deleted_orders (order_id, customer_name, product, order_date, deleted_at)
    values (old.order_id, old.customer_name, old.product, old.order_date, now());
end &&;


DELIMITER ;


-- 4
delete from orders where order_id = 4;
delete from orders where order_id = 5;


-- 5
select * from deleted_orders;
