USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select products.name as product_name, products.price, categories.name as category_name from products
left join categories on categories.category_id = products.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select orders.order_id, orders.order_datetime, order_items.quantity, stores.name, products.name, (order_items.quantity * products.price) as line_total
from orders
join order_items on orders.order_id = order_items.order_id
join stores on orders.store_id = stores.store_id
join products on products.product_id = order_items.product_id
order by orders.order_datetime, orders.order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select 
orders.order_datetime, 
stores.name as store_name, 
concat(customers.first_name, ' ', customers.last_name) as customer_name
from orders
join stores on orders.store_id = stores.store_id
join customers on orders.customer_id = customers.customer_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
where orders.status = 'paid';
-- ORDER TOTAL ????

select sum(order_items.quantity * products.price) as total
from order_items 
join products on order_items.product_id = products.product_id;
-- TOTAL ORDERS TOTAL, need each customers orders total ???


-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select customers.first_name, customers.last_name, customers.city, customers.state, customers.customer_id
from customers
left join orders on orders.customer_id = customers.customer_id
where orders.order_id = null;

-- they've all placed orders, idk i know this can happen in real life but it makes me feel like the answer is wrong
-- anyway did some other queries and it's correct

 
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.



-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select on_hand, stores.name as store_name, products.name as product_name
from inventory
join stores on stores.store_id = inventory.store_id
join products on products.product_id = inventory.product_id
where on_hand < 12;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT hire_date, concat(first_name, ' ', last_name) as manager_name, stores.name
from employees
join stores on stores.store_id = employees.store_id
where title = 'Manager';



-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.


-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
