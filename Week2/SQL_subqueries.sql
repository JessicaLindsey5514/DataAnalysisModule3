USE coffeeshop_db;

-- =========================================================
-- SUBQUERIES & NESTED LOGIC PRACTICE
-- =========================================================

-- Q1) Scalar subquery (AVG benchmark):
--     List products priced above the overall average product price.
--     Return product_id, name, price.

select product_id, name, price
from products
where price > (
	select avg(price)
    from products);

-- Q2) Scalar subquery (MAX within category):
--     Find the most expensive product(s) in the 'Beans' category.
--     (Return all ties if more than one product shares the max price.)
--     Return product_id, name, price.
select products.product_id, products.name, products.price 
from products
join categories on categories.category_id = products.category_id
where categories.name = 'Beans'
order by price desc
limit 1;
-- not how i am supposed to do it ... COME BACK

-- Q3) List subquery (IN with nested lookup):
--     List customers who have purchased at least one product in the 'Merch' category.
--     Return customer_id, first_name, last_name.
--     Hint: Use a subquery to find the category_id for 'Merch', then a subquery to find product_ids.
select customers.customer_id, concat(customers.first_name, ' ' , customers.last_name) as customer_name
from customers
join orders on orders.customer_id = customers.customer_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
join categories on products.category_id = categories.category_id
where categories.category_id in (
	select category_id
    from categories
    where name = 'Merch');
-- added concat to make cleaner

-- Q4) List subquery (NOT IN / anti-join logic):
--     List products that have never been ordered (their product_id never appears in order_items).
--     Return product_id, name, price.
select product_id, products.name, products.price
from products
where product_id NOT IN (
	select product_id
    from order_items);

-- double checking this is correct... and it is :)    
select product_id
from products;
select distinct product_id
from order_items;

-- Q5) Table subquery (derived table + compare to overall average):
--     Build a derived table that computes total_units_sold per product
--     (SUM(order_items.quantity) grouped by product_id).
--     Then return only products whose total_units_sold is greater than the
--     average total_units_sold across all products.
--     Return product_id, product_name, total_units_sold.
