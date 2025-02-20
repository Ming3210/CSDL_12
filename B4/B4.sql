-- 2

create table order_warnings (
	warning_id int primary key auto_increment,
    order_id int not null ,
    foreign key (order_id) references orders(order_id),
    warning_message varchar(255) not null
);


-- 3
DELIMITER &&
create trigger after_insert_order
after insert on orders 
for each row
begin
	if(new.quantity * new.price) > 5000 then
		insert into order_warnings (order_id,warning_message)
        values(new.order_id,'Total value exceeds limit');
	end if;
end &&
DELIMITER &&;


-- 4
insert into orders (customer_name, product, quantity, price, order_date) values
('mark', 'monitor', 2, 3000.00, '2023-08-01'),
('paul', 'mouse', 1, 50.00, '2023-08-02');

select * from orders;
