-- data source from maven analytics

-- 1. What are the top 5 best-selling menu items by item name and category?
SELECT item_name, category, count(order_details_id) as total_sales
FROM menu_items as mi
JOIN order_details as od
ON od.item_id = mi.menu_item_id
GROUP BY item_name, category
ORDER BY total_sales DESC
LIMIT 5;

-- 2. Which menu items generate the highest revenue?
SELECT item_name, category, sum(price) AS total_revenue
FROM menu_items AS mi
LEFT JOIN order_details AS od
ON od.item_id = mi.menu_item_id
GROUP BY item_name, category
ORDER BY total_revenue DESC
LIMIT 5;

-- 3. What are the peak hours for sales?
SELECT HOUR(order_time) as hour, COUNT(order_id) as total_orders
FROM menu_items AS mi
LEFT JOIN order_details AS od
ON od.item_id = mi.menu_item_id
GROUP BY hour
ORDER BY total_orders DESC
LIMIT 5;

-- 4. Which day of the week generates the highest sales?
SELECT DAYNAME(order_date) AS day_of_week, SUM(price) AS total_revenue, COUNT(order_id) AS total_orders
FROM menu_items AS mi
LEFT JOIN order_details AS od
ON od.item_id = mi.menu_item_id
GROUP BY day_of_week
ORDER BY total_revenue DESC;

-- 5. What are the most common item combinations in orders?
WITH item_pairs AS (
    SELECT 
        o1.item_id AS item_id_1,
        o2.item_id AS item_id_2,
        COUNT(*) AS pair_count
    FROM order_details AS o1
    LEFT JOIN order_details AS o2 
    ON o1.order_id = o2.order_id AND o1.item_id < o2.item_id
    GROUP BY o1.item_id, o2.item_id
)
SELECT 
    mi1.item_name AS item_name_1,
    mi2.item_name AS item_name_2,
    pair_count
FROM item_pairs
LEFT JOIN menu_items mi1 
ON item_pairs.item_id_1 = mi1.menu_item_id
JOIN menu_items mi2 
ON item_pairs.item_id_2 = mi2.menu_item_id
ORDER BY  pair_count DESC
LIMIT 5;

-- 6. How many menu items are sold during each time period (Breakfast, Lunch, Tea-Time, and Dinner)?
WITH sales_by_hour AS (
	SELECT mi.Item_name,
		   CASE WHEN HOUR(od.order_time) BETWEEN 9 AND 11 THEN 'Breakfast'
				WHEN HOUR(od.order_time) BETWEEN 11 AND 15 THEN 'Lunch'
                WHEN HOUR(od.order_time) BETWEEN 15 AND 18 THEN 'Tea-Time'
                WHEN HOUR(od.order_time) BETWEEN 18 AND 24 THEN 'Dinner'
			END AS time_period,
           COUNT(od.item_id) AS total_sales
	FROM order_details AS od
	LEFT JOIN menu_items AS mi
	ON od.item_id = mi.menu_item_id
    GROUP BY mi.item_name, time_period
),
sales_difference AS (
	SELECT item_name,
		   SUM(CASE WHEN time_period = 'Breakfast' THEN total_sales ELSE 0 END) AS breakfast_sales,
		   SUM(CASE WHEN time_period = 'Lunch' THEN total_sales ELSE 0 END) AS lunch_sales,
		   SUM(CASE WHEN time_period = 'Tea-Time' THEN total_sales ELSE 0 END) AS tea_time_sales,
		   SUM(CASE WHEN time_period = 'Dinner' THEN total_sales ELSE 0 END) AS dinner_sales
	FROM sales_by_hour
    GROUP BY item_name
)
SELECT	item_name,
		breakfast_sales,
		lunch_sales,
		tea_time_sales,
		dinner_sales
FROM sales_difference
WHERE breakfast_sales > 0 
   OR lunch_sales > 0 
   OR tea_time_sales > 0 
   OR dinner_sales > 0
ORDER BY item_name;    

-- 7. What is the monthly revenue for each category, ranked by revenue within each month?WITH monthly_revenue AS (
    WITH monthly_revenue AS (
    SELECT mi.category,
           DATE_FORMAT(od.order_date, '%Y-%m') AS month,
           SUM(mi.price) AS total_revenue
    FROM order_details od
    LEFT JOIN menu_items mi
    ON od.item_id = mi.menu_item_id
    WHERE mi.category IS NOT NULL 
    GROUP BY mi.category, DATE_FORMAT(od.order_date, '%Y-%m')
)
SELECT category, month, total_revenue,
       RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS rank_per_month
FROM monthly_revenue
WHERE total_revenue IS NOT NULL 
ORDER BY month, rank_per_month;










