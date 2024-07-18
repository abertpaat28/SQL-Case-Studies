USE foodie_fi;

-- A. CUSTOMER JOURNEY

SELECT
	s.*,
	p.plan_name,
	p.price
FROM plans p
	JOIN subscriptions s
	ON p.plan_id = s.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);

