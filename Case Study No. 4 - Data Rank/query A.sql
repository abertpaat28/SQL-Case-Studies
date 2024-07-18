USE data_bank;

-- A. CUSTOMER NODES EXPLORATION

1. How many unique nodes are there on the Data Bank system?

SELECT
	COUNT(DISTINCT node_id) AS node_unq_cnt
FROM customer_nodes;



2. What is the number of nodes per region?

SELECT
	r.region_id,
	r.region_name,
	COUNT(c.node_id) AS node_count
FROM regions r
	JOIN customer_nodes c
	ON r.region_id = c.region_id
GROUP BY r.region_name, r.region_id
ORDER BY region_id ASC;



3. How many customers are allocated to each region?

SELECT
	r.region_id,
	r.region_name,
	COUNT(c.customer_id) AS customer_count
FROM regions r
	JOIN customer_nodes c
	ON r.region_id = c.region_id
GROUP BY r.region_name, r.region_id
ORDER BY region_id ASC;



4. How many days on average are customers reallocated to a different node?

WITH 
customerDates AS (
	SELECT 
		customer_id,
		region_id,
		node_id,
		MIN(start_date) AS first_date
	FROM customer_nodes
	GROUP BY customer_id, region_id, node_id
),
reallocation AS (
	SELECT
		customer_id,
		node_id,
		region_id,
		first_date,
		DATEDIFF(DAY, first_date, 
			     LEAD(first_date) OVER(PARTITION BY customer_id 
										ORDER BY first_date)) AS moving_days
	FROM customerDates
)

SELECT 
	AVG(CAST(moving_days AS FLOAT)) AS avg_moving_days
FROM reallocation;



5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH 
customerDates AS (
	SELECT 
		customer_id,
		region_id,
		node_id,
		MIN(start_date) AS first_date
	FROM customer_nodes
	GROUP BY customer_id, region_id, node_id
),
reallocation AS (
	SELECT
		customer_id,
		node_id,
		region_id,
		first_date,
		DATEDIFF(DAY, first_date, 
			     LEAD(first_date) OVER(PARTITION BY customer_id 
										ORDER BY first_date)) AS moving_days
	FROM customerDates
)

SELECT 
	DISTINCT rl.region_id,
	rg.region_name,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rl.moving_days) 
							OVER(PARTITION BY rl.region_id) AS median,
	PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY rl.moving_days) 
							OVER(PARTITION BY rl.region_id) AS pct_80,
	PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY rl.moving_days) 
							OVER(PARTITION BY rl.region_id) AS pct_95
FROM reallocation rl
	JOIN regions rg 
	ON rl.region_id = rg.region_id
WHERE moving_days IS NOT NULL;

