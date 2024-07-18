USE foodie_fi;

-- B. DATA ANALYSIS QUESTIONS

-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) as total_customers
FROM subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT 
   MONTH(start_date) AS month,
   COUNT(customer_id) AS customer_count
FROM subscriptions
WHERE plan_id = '0'
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT
   YEAR(s.start_date) as year,
   p.plan_name,
   COUNT(s.customer_id) as customer_count
FROM plans p
JOIN subscriptions s
   ON p.plan_id = s.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY plan_name, YEAR(s.start_date);


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
  SUM(CASE WHEN plan_id = '4' THEN 1 END) AS churn_count,
  CAST(100*SUM(CASE WHEN plan_id = '4' THEN 1 END) AS FLOAT(1)) 
    / COUNT(DISTINCT customer_id) AS churn_pct
FROM subscriptions;

SELECT 
   SUM(CASE WHEN p.plan_name = 'churn' THEN 1 END) AS churn_count,
   CAST(100*SUM(CASE WHEN p.plan_name = 'churn' THEN 1 END) AS FLOAT(1)) 
    / COUNT(DISTINCT customer_id) AS churn_pct
FROM subscriptions s
JOIN plans p 
   ON s.plan_id = p.plan_id;


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH NextPlan AS (
SELECT
   s.customer_id,
   s.start_date,
   p.plan_name,
   LEAD(p.plan_name, 1) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
FROM subscriptions s
JOIN plans p
   ON s.plan_id = p.plan_id
)

SELECT
   COUNT(*) AS churn_after_trial,
   100*COUNT(*)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS churn_after_trial_pct
FROM NextPlan
WHERE plan_name = 'trial' 
   and next_plan = 'churn';


-- 6. What is the number and percentage of customer plans after their initial free trial?

with NextPlan AS (
SELECT
   s.customer_id,
   s.start_date,
   p.plan_name,
   LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) as next_plan
FROM subscriptions s
JOIN plans p
   ON s.plan_id = p.plan_id
)
SELECT
   next_plan,
   count(*) as customer_count,
   CAST(100*COUNT(*) AS FLOAT)
		/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS customer_pct
FROM NextPlan
WHERE next_plan is NOT NULL
   and plan_name = 'trial'
GROUP BY next_plan;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH CTE AS (
SELECT 
   s.customer_id,
   p.plan_id,
   p.plan_name,
   s.start_date,
   LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id
)

SELECT 
   plan_id,
   plan_name,
   COUNT(*) AS customers,
   CAST(100*COUNT(*) AS FLOAT) 
      / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS customer_pct
FROM CTE
WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
   OR (next_date IS NULL AND start_date < '2020-12-31')
GROUP BY plan_id, plan_name
ORDER BY plan_id;


-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT
   COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions s
JOIN plans p
   ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual' 
   and YEAR(s.start_date) = '2020'


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH TrialPlan AS (
   SELECT 
      s.customer_id,
      s.start_date AS trial_date
   FROM subscriptions s
   JOIN plans p ON s.plan_id = p.plan_id
   WHERE p.plan_name = 'trial'
),
AnnualPlan AS (
   SELECT 
      s.customer_id,
      s.start_date AS annual_date
   FROM subscriptions s
   JOIN plans p ON s.plan_id = p.plan_id
   WHERE p.plan_name = 'pro annual'
)

SELECT
   AVG(CAST(DATEDIFF(d, trial_date, annual_date) AS FLOAT)) AS avg_days_to_annual
FROM TrialPlan t
JOIN AnnualPlan a 
   ON t.customer_id = a.customer_id;
    


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH TrialPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS trial_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'trial'
),
AnnualPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS annual_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'pro annual'
),
datesDiff AS (
  SELECT 
    t.customer_id,
    DATEDIFF(d, trial_date, annual_date) AS diff
  FROM trialPlan t
  JOIN annualPlan a ON t.customer_id = a.customer_id
),
daysRecursion AS (
  SELECT 
    0 AS start_period, 
    30 AS end_period
  UNION ALL
  SELECT 
    end_period + 1 AS start_period,
    end_period + 30 AS end_period
  FROM daysRecursion
  WHERE end_period < 360
)

SELECT 
  dr.start_period,
  dr.end_period,
  COUNT(*) AS customer_count
FROM daysRecursion dr
LEFT JOIN datesDiff dd 
  ON (dd.diff >= dr.start_period AND dd.diff <= dr.end_period)
GROUP BY dr.start_period, dr.end_period;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH NextPlan AS (
   SELECT 
    s.customer_id,
    s.start_date,
    p.plan_name,
    LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
   FROM subscriptions s
   JOIN plans p ON s.plan_id = p.plan_id
)

SELECT 
   COUNT(*) AS pro_to_basic_monthly
FROM NextPlan
WHERE plan_name = 'pro monthly'
   AND next_plan = 'basic monthly'
   AND YEAR(start_date) = 2020;

