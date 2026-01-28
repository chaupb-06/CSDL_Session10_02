-- Xóa bảng nếu đã tồn tại
drop table if exists orders;
drop table if exists customers;

-- Tạo bảng customers
create table customers (
    id serial primary key,
    name varchar(100),
    credit_limit numeric(12,2)
);

-- Tạo bảng orders
create table orders (
    id serial primary key,
    customer_id int references customers(id),
    order_amount numeric(12,2)
);

-- Function kiểm tra hạn mức tín dụng
create or replace function check_credit_limit()
returns trigger as $$
declare
    total_amount numeric;
    limit_amount numeric;
begin
    -- Tổng giá trị đơn hàng hiện tại của khách hàng
    select coalesce(sum(order_amount), 0)
    into total_amount
    from orders
    where customer_id = new.customer_id;

    -- Lấy hạn mức tín dụng
    select credit_limit
    into limit_amount
    from customers
    where id = new.customer_id;

    -- Kiểm tra vượt hạn mức
    if total_amount + new.order_amount > limit_amount then
        raise exception 
        'Credit limit exceeded! Current: %, New order: %, Limit: %',
        total_amount, new.order_amount, limit_amount;
    end if;

    return new;
end;
$$ language plpgsql;

-- Trigger gọi function trước khi INSERT
create trigger trg_check_credit
before insert on orders
for each row
execute function check_credit_limit();

-- Chèn dữ liệu mẫu vào customers
insert into customers (name, credit_limit) values
('Alice', 5000),
('Bob', 3000),
('Charlie', 10000);

-- Thực hành INSERT đơn hàng (HỢP LỆ)
insert into orders (customer_id, order_amount) values
(1, 2000),
(1, 1500),
(2, 1000);

-- Kiểm tra dữ liệu hiện tại
select * from orders;

-- Thử INSERT VƯỢT HẠN MỨC (sẽ bị chặn)
-- Tổng của Alice = 3500, thêm 2000 -> vượt 5000
insert into orders (customer_id, order_amount)
values (1, 2000);

-- Trường hợp hợp lệ khác
insert into orders (customer_id, order_amount)
values (3, 4000);
