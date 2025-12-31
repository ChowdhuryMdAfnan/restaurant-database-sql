-- View menu items table
SELECT * 
FROM menu_items;

-- Count the total number of items available on the menu
SELECT 
    COUNT(menu_item_id) AS total_menu_items
FROM menu_items;

-- Identify the most expensive item on the menu
SELECT 
    item_name, price
FROM menu_items
ORDER BY price DESC
LIMIT 1;

-- Identify the least expensive item on the menu
SELECT 
    item_name, price
FROM menu_items
ORDER BY price ASC
LIMIT 1;

-- Count the total number of Italian dishes on the menu
SELECT 
    category, 
    COUNT(menu_item_id) AS num_items
FROM menu_items
WHERE category = 'italian';

-- Find the most expensive Italian dish
SELECT 
    item_name, category, price
FROM menu_items
WHERE category = 'italian'
ORDER BY price DESC
LIMIT 1;

-- Find the least expensive Italian dish
SELECT 
    item_name, category, price
FROM menu_items
WHERE category = 'italian'
ORDER BY price ASC
LIMIT 1;

-- Analyze the number of dishes and average price for each menu category
SELECT
    category, 
    COUNT(item_name) AS num_dishes, 
    AVG(price) AS avg_price
FROM menu_items
GROUP BY category
ORDER BY num_dishes DESC;

-- View order details table
SELECT * 
FROM order_details;

-- Calculate total number of distinct orders within the full available date range
WITH date_range AS (
    SELECT
        MAX(order_date) AS max_date,
        MIN(order_date) AS min_date
    FROM order_details
)
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM order_details
JOIN date_range 
    ON order_date BETWEEN min_date AND max_date;

-- Calculate total number of items ordered within the full available date range
WITH date_range AS (
    SELECT
        MAX(order_date) AS max_date,
        MIN(order_date) AS min_date
    FROM order_details
)
SELECT
    COUNT(DISTINCT order_details_id) AS total_items_ordered
FROM order_details
JOIN date_range
    ON order_date BETWEEN min_date AND max_date;

-- Analyze daily order volume to identify ordering trends over time
WITH daily_orders AS (
    SELECT 
        order_date,
        COUNT(DISTINCT order_id) AS total_orders
    FROM order_details
    GROUP BY order_date
)
SELECT *
FROM daily_orders
ORDER BY order_date;

-- Calculate daily order volume for the last 30 days of available data
WITH max_date_cte AS (
    SELECT 
        MAX(order_date) AS max_date
    FROM order_details
)
SELECT 
    order_date,
    COUNT(DISTINCT order_id) AS orders
FROM order_details
WHERE order_date >= DATE_SUB(
        (SELECT max_date FROM max_date_cte),
        INTERVAL 30 DAY
)
GROUP BY order_date;

-- Identify orders with the highest number of items purchased
SELECT
    order_id, 
    COUNT(DISTINCT order_details_id) AS num_items
FROM order_details
GROUP BY order_id
ORDER BY num_items DESC;

-- Determine how many orders contained more than 12 items
WITH cte AS (
    SELECT
        order_id, 
        COUNT(DISTINCT order_details_id) AS items_ordered
    FROM order_details
    GROUP BY order_id
),
orders_rnk AS (
    SELECT *
    FROM cte
    WHERE items_ordered > 12
)
SELECT 
    COUNT(DISTINCT order_id) AS orders_more_than_12_items
FROM orders_rnk;

-- Alternative approach to count orders with more than 12 items using HAVING clause
WITH item_cte AS (
    SELECT 
        order_id, 
        COUNT(order_details_id) AS num_items
    FROM order_details
    GROUP BY order_id
    HAVING num_items > 12
)
SELECT 
    COUNT(order_id) AS orders
FROM item_cte;

-- Join menu and order tables to analyze item-level sales performance
SELECT 
    *
FROM menu_items mi
JOIN order_details od
    ON od.item_id = mi.menu_item_id;

-- Identify the most ordered menu items
SELECT 
    mi.item_name, 
    mi.category, 
    COUNT(od.order_details_id) AS num_orders
FROM order_details od
JOIN menu_items mi 
    ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name, mi.category
ORDER BY num_orders DESC;

-- Identify the least ordered menu items
SELECT 
    mi.item_name, 
    mi.category, 
    COUNT(od.order_details_id) AS num_orders
FROM order_details od
JOIN menu_items mi 
    ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name, mi.category
ORDER BY num_orders ASC;

-- Identify top revenue-generating menu items
SELECT 
    od.item_id, 
    mi.item_name, 
    SUM(mi.price) AS total_revenue
FROM order_details od
JOIN menu_items mi 
    ON od.item_id = mi.menu_item_id
GROUP BY od.item_id, mi.item_name
ORDER BY total_revenue DESC;

-- Identify the top 5 highest revenue-generating orders
SELECT 
    od.order_id,
    SUM(mi.price) AS revenue
FROM order_details od
JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
GROUP BY od.order_id
ORDER BY revenue DESC
LIMIT 5;

-- Analyze item-level details for the highest spending order
SELECT 
    od.order_id, 
    mi.item_name, 
    mi.category, 
    mi.price
FROM order_details od
JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
WHERE od.order_id = 440;

-- Analyze category distribution within the highest spending order
SELECT 
    mi.category, 
    COUNT(order_details_id) AS item_count
FROM order_details od
JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
WHERE od.order_id = 440
GROUP BY mi.category;

-- Identify category-wise item distribution for the highest revenue order dynamically
with top_orders as (
    select 
      od.order_id, sum(mi.price) as revenue
    from order_details od
    join menu_items mi
      on od.item_id = mi.menu_item_id
    group by od.order_id
    order by revenue desc
    limit 1
  )
select 
    od.order_id,
    mi.category,
    COUNT(od.order_details_id) AS item_count
from order_details od
join menu_items mi
  on od.item_id = mi.menu_item_id
join top_orders t
  on t.order_id = od.order_id
group by od.order_id, mi.category;

-- Retrieve item-level details for the highest revenue-generating order
WITH top_orders AS (
    SELECT 
        od.order_id, 
        SUM(mi.price) AS revenue
    FROM order_details od
    JOIN menu_items mi
        ON od.item_id = mi.menu_item_id
    GROUP BY od.order_id
    ORDER BY revenue DESC
    LIMIT 1
)
SELECT 
    od.order_id, 
    mi.item_name, 
    mi.category, 
    mi.price
FROM order_details od
JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
JOIN top_orders t
    ON od.order_id = t.order_id;

-- Analyze category-wise item distribution for the top 5 highest revenue orders
WITH top_orders AS (
    SELECT 
        od.order_id, 
        SUM(mi.price) AS revenue
    FROM order_details od
    JOIN menu_items mi
        ON od.item_id = mi.menu_item_id
    GROUP BY od.order_id
    ORDER BY revenue DESC
    LIMIT 5
)
SELECT 
    mi.category, 
    COUNT(od.order_details_id) AS item_count
FROM order_details od
JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
JOIN top_orders t
    ON od.order_id = t.order_id
GROUP BY mi.category;
