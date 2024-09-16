USE swiggy_data;

SELECT * FROM users;
SELECT * FROM restaurants;
SELECT * FROM food;
SELECT * FROM menu;
SELECT * FROM orders;
SELECT * FROM delivery_partners;
SELECT * FROM order_details;


#1. Find customers who have never ordered
SELECT 
	user_id,
    name
FROM users 
WHERE user_id NOT IN  (SELECT DISTINCT user_id
						FROM orders);


#2. Average Price/dish
SELECT f.f_name, ROUND(AVG(m.price),2) AS Avg_Price
FROM food f
JOIN menu m ON f.f_id = m.f_id
GROUP BY f.f_name ;


#3. Find the top restaurant in terms of the number of orders for a given month
WITH monthly_order_count AS(
	SELECT 
			r.r_name , 
			MONTH(o.date) AS Month, 
			COUNT(o.order_id) AS Total_Orders,
			RANK() OVER (PARTITION BY MONTH(o.date) ORDER BY COUNT(o.order_id) DESC) As rank_num
	FROM orders o
	JOIN restaurants r ON o.r_id = r.r_id
	GROUP BY  r.r_name , MONTH(o.date)
	ORDER BY Month, Total_orders DESC
    )

SELECT r_name AS Restaurant, Month, Total_Orders
FROM monthly_order_count
WHERE rank_num = 1;


#4. Restaurants with monthly sales greater than x for
-- Define the threshold X
SET @threshold = 500;        -- Change this value as needed

SELECT 
    r.r_name,
    MONTH(o.date) AS Month,
    SUM(o.amount) AS total_sales
FROM orders o
JOIN restaurants r ON o.r_id = r.r_id
GROUP BY r.r_name, month
HAVING total_sales > @threshold
ORDER BY MONTH(o.date), SUM(o.amount) DESC ;


#5. Show all orders with order details for a particular customer in a particular date range
-- Define the customer ID and the date range
SET @customer_id = 1;                 -- Change this value as needed
SET @start_date = '2022-06-01';       -- Change this value as needed
SET @end_date = '2022-06-30';         -- Change this value as needed

SELECT 
    o.order_id,
    o.date,
    o.amount,
    r.r_name,
    dp.partner_name,
    od.f_id,
    f.f_name,
    f.type
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN food f ON od.f_id = f.f_id
JOIN restaurants r ON o.r_id = r.r_id
JOIN delivery_partners dp ON o.partner_id = dp.partner_id
WHERE o.user_id = @customer_id
AND o.date BETWEEN @start_date AND @end_date
ORDER BY o.date, o.order_id;


#6. Find restaurants with max repeated customers
WITH repeated_customers AS(
	SELECT 
		o.user_id,
		COUNT(r.r_id) AS order_count, 
		r.r_name,
		RANK() OVER(PARTITION BY o.user_id ORDER BY COUNT(r.r_id) DESC ) AS rank_num
	FROM orders o
	JOIN restaurants r ON o.r_id = r.r_id
	GROUP BY o.user_id,r.r_name 
	HAVING COUNT(r.r_id) >1 
	)
    
SELECT user_id, order_count, r_name
FROM repeated_customers
WHERE rank_num =1;


#7. Month over month revenue growth of Swiggy
SELECT
	   Month(date) AS Month,
	   SUM(amount) AS total_revenue,
	   (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY Month(date))) AS revenue_growth
FROM orders 
GROUP BY Month(date);


#8. Customer — favourite food
WITH fav_food_count AS(
SELECT  
	u.name, 
    f.f_name, 
    COUNT(od.f_id) AS food_count,
    RANk() OVER(PARTITION BY u.name ORDER BY  COUNT(od.f_id) DESC) AS rank_num
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN food f ON od.f_id = f.f_id
JOIN users u ON o.user_id = u.user_id
GROUP BY u.name, f.f_name)

SELECT name, f_name, food_count
FROM fav_food_count
WHERE rank_num = 1;


#9. Find the most loyal customers for all restaurant
SELECT 
	  u.name,
	  COUNT(r.r_id) AS order_count, 
	  r.r_name
FROM users u
JOIN orders o ON o.user_id = u.user_id
JOIN restaurants r ON o.r_id = r.r_id
GROUP BY u.name, r.r_name
HAVING COUNT(r.r_id) >1 
ORDER BY order_count DESC, r_name;


#10. Month-over-month revenue growth of a restaurant
SELECT r.r_name,
	   Month(date) AS month,
	   SUM(o.amount) AS total_revenue,
	   (SUM(o.amount) - LAG(SUM(o.amount)) OVER (PARTITION BY r.r_name ORDER BY Month(date))) AS revenue_growth
FROM orders o
JOIN restaurants r ON o.r_id = r.r_id
GROUP BY r.r_name, Month(date);

