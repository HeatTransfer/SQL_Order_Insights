select * from orders order by Placed_at;

-- Find top outlets by cuisine type without using limit and top function
with cte as (
	select cuisine, restaurant_id, count(order_id) as no_of_orders
	from orders
	group by cuisine, restaurant_id
)
select D.cuisine, D.restaurant_id from (
	select *, row_number() over(partition by cuisine order by no_of_orders desc) as rn from cte
) D
where rn = 1;

-- Find daily new customer count from launch date.
with first_orders as (
	select customer_code, cast(min(placed_at) as date) as first_order_date
	from orders
	group by customer_code
)
/*,
all_orders as (
	select O.Customer_code, cast(O.Placed_at as date) as order_date, FO.first_order_date
	from orders O 
	join first_orders FO on O.customer_code = FO.Customer_code
)
select order_date, sum(is_new) as count_of_new_customers from (
	select * , 
		case when order_date = first_order_date then 1 else 0 end as is_new
	from all_orders
) D
group by D.order_date
order by D.order_date;*/

select first_order_date, count(1) as count_of_new_customers 
from first_orders
group by first_order_date
order by first_order_date;


-- Count of all users who were acquired in Jan 2025 and only placed one order in Jan and did not place any other order.
with jan_customers as (
	select customer_code
	from orders
	where cast(placed_at as date) between '2025-01-01' and '2025-01-31'
	group by customer_code
	having count(1) = 1
),
other_orders as (
	select customer_code from orders
	where cast(placed_at as date) > '2025-01-31'
)
select customer_code from jan_customers
where customer_code not in (select * from other_orders);


-- List all the customers with no order in the last 7 days but acquired one month ago with their first order on promo.
select * from orders;

with cte as (
	select customer_code, cast(min(placed_at) as date) as first_order, cast(max(placed_at) as date) as latest_order
	from orders 
	group by customer_code
)
select cte.*, o.promo_code_name as first_promo
from cte
inner join orders o on cte.Customer_code = o.Customer_code and cte.first_order = cast(o.Placed_at as date)
where latest_order < dateadd(day, -7, getdate()) and 
	  first_order < dateadd(month, -1, getdate()) and o.promo_code_name is not null;


-- Growth team is planning to create a trigger that will target customers after their every third order
-- with a personalized communication.
select * from orders;
with cte as (
	select *, ROW_NUMBER() over(partition by customer_code order by placed_at) as order_no
	from orders
)
select * from cte 
where order_no%3 = 0 and cast(Placed_at as date) = cast(GETDATE() as date); 


-- List customers who placed more than 1 order and all their orders on a promo only.
select customer_code, count(*), count(promo_code_name) as promo_count
from orders
group by Customer_code
having count(*) > 1 and count(*) = count(promo_code_name);

select * from orders where Customer_code='DEF9876543210XYZ'

-- What % of customers were organically acquired in Jan 2025? (i.e. first order without promo code)
with non_promo as (
	select *, row_number() over(partition by customer_code order by placed_at) as rn
	from orders 
	where cast(Placed_at as date) between '2025-01-01' and '2025-01-31'
	
)
select 
	round(100.0*count(case when rn=1 and Promo_code_Name is null then customer_code end) / count(distinct Customer_code), 2) as '%organic'
from non_promo;
