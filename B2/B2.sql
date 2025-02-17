-- 2
create table price_changes (
    change_id int auto_increment primary key,
    product varchar(100) not null,
    old_price decimal(10,2) not null,
    new_price decimal(10,2) not null
);


-- 3
DELIMITER &&

create trigger after_update_price
after update on products
for each row
begin
    -- Chỉ ghi lại khi giá thay đổi
    if old.price <> new.price then
        insert into price_changes (product, old_price, new_price)
        values (old.product, old.price, new.price);
    end if;
end &&;


DELIMITER ;


-- 4
update products set price = 1400.00 where product = 'Laptop';
update products set price = 800.00 where product = 'Smartphone';


-- 5
select * from price_changes;
