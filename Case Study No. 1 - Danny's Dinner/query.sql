-- SQL CHALLENGE NO. 1 - DANNYS DINER
-- CREATOR: Angelbert Paat
-- TOOL USED: MS SQL Server Management Studio



-- CASE STUDY QUESTIONS --
-- Each of the following case study questions can be answered using a single SQL statement:



-- 1. What is the total amount each customer spent at the restaurant?

USE dannys_diner;

SELECT 
   s.customer_id,
   SUM(m.price) as total_spent
FROM menu m join sales s
   on m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;



-- 2. How many days has each customer visited the restaurant?

SELECT
   customer_id,
   COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;



-- 3. What was the first item from the menu purchased by each customer?

WITH orderRank AS (
  SELECT 
    customer_id,
    product_id,
    order_date,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS menu_rank
  FROM sales
)

SELECT 
  o.customer_id,
  o.order_date,
  o.product_id,
  m.product_name
FROM orderRank o
JOIN menu m 
  ON o.product_id = m.product_id
WHERE o.menu_rank = 1
GROUP BY o.customer_id, o.order_date, o.product_id, m.product_name;



-- 4 What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
   s.product_id,
   m.product_name,
   count(s.product_id) as product_count
FROM sales s join menu m
   ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name;

SELECT
   s.product_id,
   m.product_name,
   count(s.product_id) as product_count,
   s.customer_id
FROM sales s join menu m
   ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name
ORDER BY customer_id;



SELECT
   s.product_id,
   m.product_name,
   count(s.product_id) as product_count
FROM sales s join menu m
   ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name;

SELECT
   s.product_id,
   m.product_name,
   count(s.product_id) as product_count,
   s.customer_id
FROM sales s join menu m
   ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name
ORDER BY customer_id;



-- 5. Which item was the most popular for each customer?

with popu_rank as (
   SELECT
	  customer_id,
	  product_id,
	  count(*) as frequency,
	  DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) as rank
   FROM sales
   GROUP BY customer_id, product_id
)

SELECT
   p.customer_id,
   p.product_id,
   product_name,
   p.frequency
FROM popu_rank p join menu m
   ON p.product_id = m.product_id
WHERE p.rank = 1
ORDER BY p.customer_id



-- 6. Which item was purchased first by the customer after they became a member?

WITH OrderAfterMember AS (
  SELECT 
    s.customer_id,
    mn.product_name,
    s.order_date,
    mb.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM sales s
  JOIN members mb 
    ON s.customer_id = mb.customer_id
  JOIN menu mn 
    ON s.product_id = mn.product_id
  WHERE s.order_date >= mb.join_date
)

SELECT 
  customer_id,
  product_name,
  order_date,
  join_date
FROM OrderAfterMember
WHERE rank = 1;



-- 7. Which item was purchased just before the customer became a member?

WITH OrderAfterMember AS (
  SELECT 
    s.customer_id,
    mn.product_name,
    s.order_date,
    mb.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM sales s
  JOIN members mb 
    ON s.customer_id = mb.customer_id
  JOIN menu mn 
    ON s.product_id = mn.product_id
  WHERE s.order_date < mb.join_date
)

SELECT 
  customer_id,
  product_name,
  order_date,
  join_date
FROM OrderAfterMember
WHERE rank = 1;



-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
  s.customer_id,
  count(s.product_id) as total_items,
  sum(price) as total_spent
FROM sales s
JOIN members mb 
  ON s.customer_id = mb.customer_id
JOIN menu mn 
  ON s.product_id = mn.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;



-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- Note: Only customers who are members receive points when purchasing items

WITH CustomerPoints as (
   SELECT
      s.customer_id,
	  CASE
		WHEN s.customer_id IN (SELECT customer_id FROM members) AND mn.product_name = 'sushi' THEN mn.price*20
		WHEN s.customer_id IN (SELECT customer_id FROM members) AND mn.product_name != 'sushi' THEN mn.price*10
	  ELSE 0 END AS points
   FROM menu mn JOIN sales s
		ON mn.product_id = s.product_id
)
SELECT
   customer_id,
   SUM(points) AS total_points
FROM CustomerPoints
GROUP BY customer_id;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

WITH programDates AS (
  SELECT 
    customer_id, 
    join_date,
    DATEADD(d, 6, join_date) AS valid_date, 
    EOMONTH('2021-01-01') AS last_date
  FROM members
)

SELECT 
  p.customer_id,
  SUM(CASE 
      	WHEN s.order_date BETWEEN p.join_date AND p.valid_date THEN m.price*20
      	WHEN m.product_name = 'sushi' THEN m.price*20
      ELSE m.price*10 END) AS total_points
FROM sales s
JOIN programDates p 
  ON s.customer_id = p.customer_id
JOIN menu m 
  ON s.product_id = m.product_id
WHERE s.order_date <= last_date
GROUP BY p.customer_id;




-- BONUS QUESTION --

-- 1. JOIN ALL THE THINGS

SELECT
   s.customer_id, 
   s.order_date, 
   m.product_name, 
   m.price,
   CASE
      WHEN s.order_date >= mb.join_date THEN 'Y'
	  ELSE 'N'
   END AS member
FROM sales s
JOIN menu m
   ON s.product_id = m.product_id
LEFT JOIN members mb
   ON s.customer_id = mb.customer_id;



-- 2. RANK ALL THE THINGS

with CustomerRank AS (
SELECT
   s.customer_id, 
   s.order_date, 
   m.product_name, 
   m.price,
   CASE
      WHEN s.order_date >= mb.join_date THEN 'Y'
	  ELSE 'N'
   END AS member
FROM sales s
JOIN menu m
   ON s.product_id = m.product_id
LEFT JOIN members mb
   ON s.customer_id = mb.customer_id
)

SELECT *,
   CASE
	  WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	  ELSE null
   END AS ranking
FROM CustomerRank;



--- END ---
