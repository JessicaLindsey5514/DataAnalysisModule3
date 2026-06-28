USE coffeeshop_db;

-- =========================================================
-- ADVANCED SQL ASSIGNMENT
-- Subqueries, CTEs, Window Functions, Views
-- =========================================================
-- Notes:
-- - Unless a question says otherwise, use orders with status = 'paid'.
-- - Write ONE query per prompt.
-- - Keep results readable (use clear aliases, ORDER BY where it helps).

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
-- For each PAID order, compute order_total (= SUM(quantity * products.price)).
-- Return: order_id, customer_name, store_name, order_datetime, order_total.
-- Filter to orders where order_total is greater than the average PAID order_total
-- for THAT SAME store (correlated subquery).
-- Sort by store_name, then order_total DESC.

WITH paid_order_total as (
	select concat(customers.first_name, ' ', customers.last_name) as customer_name, 
	stores.name as store_name, 
	orders.order_id, 
	orders.order_datetime, 
	sum(order_items.quantity * products.price) as order_total
	from orders 
	join customers on customers.customer_id = orders.customer_id
	join stores on stores.store_id = orders.store_id
	join order_items on order_items.order_id = orders.order_id
	join products on products.product_id = order_items.product_id
	where orders.status = 'paid'
	group by store_name,orders.order_id),
avg_order as (
	select avg(order_total) as avg_order_total
	from paid_order_total)
SELECT store_name, customer_name, order_id, order_datetime, order_total
FROM paid_order_total, avg_order
WHERE order_total > avg_order_total
GROUP BY store_name, order_id
ORDER BY order_total DESC;


-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
-- Using a CTE, compute daily revenue per store:
--   revenue_day = SUM(quantity * products.price) grouped by store_id and DATE(order_datetime).
-- Then, for each store and date, return:
--   store_name, order_date, revenue_day,
--   rolling_3day_avg = average of revenue_day over the current day and the prior 2 days.
-- Use a window function for the rolling average.
-- Sort by store_name, order_date.

-- order_items.quantity, products.price, stores.store_id, orders.order_datetime
WITH daily_revenue as (
	SELECT 
		orders.store_id,
		DATE(orders.order_datetime) as order_date,
		SUM(order_items.quantity * products.price) as revenue_day
		from orders
		join order_items on order_items.order_id = orders.order_id
		join products on products.product_id = order_items.product_id
		where orders.status = 'paid'
		group by orders.store_id, DATE(orders.order_datetime)
)
select stores.name, 
	daily_revenue.order_date,
	daily_revenue.revenue_day,
		round(
			AVG(daily_revenue.revenue_day) OVER (
			partition by daily_revenue.store_id
			order by daily_revenue.order_date
			rows between 2 preceding and current row
			), 2
        ) as rolling_3day_avg
from daily_revenue
join stores on stores.store_id = daily_revenue.store_id
order by stores.name, order_date;

-- in class 

-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
-- Compute each customer's total spend across ALL stores (PAID only).
-- Return: customer_id, customer_name, total_spend,
--         spend_rank (DENSE_RANK by total_spend DESC).
-- Also include percent_of_total = customer's total_spend / total spend of all customers.
-- Sort by total_spend DESC.

WITH customers_spending as (
	select customers.customer_id, concat(customers.first_name, ' ', customers.last_name) as customer_name, sum(order_items.quantity * products.price) as total_spend
	from customers
	join orders on orders.customer_id = customers.customer_id
	join order_items on order_items.order_id = orders.order_id
	join products on products.product_id = order_items.product_id
    group by customers.customer_id)
SELECT customer_id, customer_name, total_spend, dense_rank() over (order by total_spend DESC) as spend_rank
from customers_spending;



-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
-- For each store, find the top-selling product by REVENUE (not units).
-- Revenue per product per store = SUM(quantity * products.price).
-- Return: store_name, product_name, category_name, product_revenue.
-- Use a CTE to compute product_revenue, then a window function (ROW_NUMBER)
-- partitioned by store to select the top 1.
-- Sort by store_name.

WITH stores_product_rev as (
SELECT stores.name as store_name, products.name as product_name, categories.name as category_name, SUM(order_items.quantity * products.price) as product_revenue,
rank() over (partition by stores.name order by SUM(order_items.quantity * products.price) DESC) as revenue_rank
FROM stores
join orders on orders.store_id = stores.store_id
join order_items on order_items.order_id = orders.order_id
join products on products.product_id = order_items.product_id
join categories on categories.category_id = products.category_id
GROUP BY store_name, product_name, category_name)
SELECT store_name, product_name, category_name
FROM stores_product_rev
WHERE revenue_rank = 1;



-- partition by store for top selling product at each store


-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
-- Return customers who have at least one PAID order in every store in the stores table.
-- Return: customer_id, customer_name.
-- Hint: Compare count(distinct store_id) per customer to (select count(*) from stores).
WITH paid_customer_orders as (
SELECT customers.customer_id, concat(customers.first_name, ' ', customers.last_name) as customer_name, count(distinct orders.store_id) as store_id_count
FROM customers
join orders on orders.customer_id = customers.customer_id
WHERE orders.status = 'Paid'
GROUP BY customers.customer_id)
SELECT customer_id, customer_name
FROM paid_customer_orders
WHERE store_id_count = 3;


-- another way, wanted to double check because the answer is none
SELECT customers.customer_id, concat(customers.first_name, ' ', customers.last_name) as customer_name
FROM customers
join orders on orders.customer_id = customers.customer_id
WHERE orders.status = 'Paid' AND orders.store_id = 1 AND orders.store_id = 2 AND orders.store_id = 3;



-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
-- For each customer, list their PAID orders in chronological order and compute:
--   prev_order_datetime (LAG),
--   minutes_since_prev (difference in minutes between current and previous order).
-- Return: customer_name, order_id, order_datetime, prev_order_datetime, minutes_since_prev.
-- Only show rows where prev_order_datetime is NOT NULL.
-- Sort by customer_name, order_datetime.

WITH paid_customer_orders as (
SELECT concat(customers.first_name, ' ', customers.last_name) as customer_name, 
orders.order_id,
orders.order_datetime
FROM orders 
JOIN customers on customers.customer_id = orders.customer_id
ORDER BY orders.order_datetime DESC)
SELECT customer_name, 
order_datetime,
LAG(order_datetime, 1, 1) OVER (PARTITION BY customer_name) as prev_order_datetime,
(order_datetime - prev_order_datetime)as minutes_since_prev
FROM paid_customer_orders
GROUP BY customer_name;

-- ERROR i've googled this and trying to sort it out but i'm just not getting there
-- would love to see how it's actually done



-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
-- Create a view named v_paid_order_lines that returns one row per PAID order item:
--   order_id, order_datetime, store_id, store_name,
--   customer_id, customer_name,
--   product_id, product_name, category_name,
--   quantity, unit_price (= products.price),
--   line_total (= quantity * products.price)
--
-- After creating the view, write a SELECT that uses the view to return:
--   store_name, category_name, revenue
-- where revenue is SUM(line_total),
-- sorted by revenue DESC.

CREATE OR REPLACE VIEW v_paid_order_lines AS
SELECT orders.order_id, 
orders.order_datetime, 
orders.store_id,
stores.name as store_name, 
orders.customer_id,
concat(customers.first_name, ' ', customers.last_name) as customer_name,
products.product_id,
products.name as product_name,
categories.name as category_name,
products.price as unit_price,
order_items.quantity,
order_items.quantity * products.price as line_total
FROM orders
JOIN customers on customers.customer_id = orders.customer_id
JOIN order_items on order_items.order_id = orders.order_id
JOIN stores on stores.store_id = orders.store_id
JOIN products on products.product_id = order_items.product_id
JOIN categories on categories.category_id = products.category_id
WHERE orders.status = 'Paid'
GROUP BY order_items.order_id, orders.store_id, products.product_id;


SELECT store_name, category_name, sum(line_total) as revenue
FROM v_paid_order_lines
GROUP BY store_name, category_name
ORDER BY revenue desc;

-- GETTING AN ERROR BUT i know it's so close to working, waiting to see if anyone on slack can help?


-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
-- Create a view named v_paid_store_payments with:
--   store_id, store_name, payment_method, revenue
-- where revenue is total PAID revenue for that store/payment_method.
--
-- Then query the view to return:
--   store_name, payment_method, revenue,
--   store_total_revenue (window SUM over store),
--   pct_of_store_revenue (= revenue / store_total_revenue)
-- Sort by store_name, revenue DESC.


CREATE VIEW v_paid_store_payments AS 
SELECT stores.store_id, 
stores.name as store_name,
orders.payment_method,
sum(order_items.quantity * products.price) as revenue
FROM stores
JOIN orders on orders.store_id = stores.store_id
JOIN order_items on order_items.order_id = orders.order_id
JOIN products on products.product_id = order_items.product_id
GROUP BY store_name, orders.payment_method;

SELECT store_name, 
payment_method, 
revenue,
sum(revenue) as total_store_revenue,
(revenue / sum(revenue)) as pct_of_store_revenue
FROM v_paid_store_payments
GROUP BY store_name, payment_method
ORDER BY revenue DESC;

-- ERROR, second view I can't get to work, something must not be clicking.
-- WOULD appreciate feedback on these problems if I don't get them sorted out by duedate 

-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
-- Identify items where on_hand is low compared to recent demand:
-- Using a CTE, compute total_units_sold per store/product for PAID orders.
-- Then join inventory to that result and return rows where:
--   on_hand < total_units_sold
-- Return: store_name, product_name, on_hand, total_units_sold, units_gap (= total_units_sold - on_hand)
-- Sort by units_gap DESC.

WITH inventory_risk AS (
SELECT products.name as product_name,
stores.name as store_name,
inventory.on_hand as on_hand,
order_items.quantity * order_items.product_id as total_units_sold
FROM order_items
JOIN products on products.product_id = order_items.product_id
JOIN orders on orders.order_id = order_items.order_id
JOIN stores on stores.store_id = orders.store_id
JOIN inventory on inventory.product_id = products.product_id
WHERE orders.status = 'Paid')
SELECT store_name, product_name, on_hand, total_units_sold, (total_units_sold - on_hand) as units_gap
FROM inventory_risk
ORDER BY units_gap DESC;

-- not quite correct, I'm getting all three on hands connected to each store_id but with all the same store_name
-- so ""Cafe - latte - on_hand 40 and it repeatss but the on_hand changes to the next store_ids on_hand but it still says the same store_name
-- im not sure that is a good explanation but.. yeah the code runs but not the way i want it to 




