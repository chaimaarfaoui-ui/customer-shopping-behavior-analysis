-- customer_behavior_sql_queries.sql
-- Analysis queries for the `customer` table loaded via load_to_sql.py
-- Works on PostgreSQL/MySQL syntax with minor tweaks noted inline.

-- ============================================================
-- 1. Revenue overview
-- ============================================================
SELECT
    COUNT(*) AS total_orders,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount), 2) AS avg_order_value
FROM customer;

-- ============================================================
-- 2. Revenue by category
-- ============================================================
SELECT
    category,
    COUNT(*) AS orders,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount), 2) AS avg_order_value
FROM customer
GROUP BY category
ORDER BY total_revenue DESC;

-- ============================================================
-- 3. Top 10 best-selling items
-- ============================================================
SELECT
    item_purchased,
    COUNT(*) AS times_purchased,
    SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY item_purchased
ORDER BY times_purchased DESC
LIMIT 10;

-- ============================================================
-- 4. Revenue and average rating by age group
-- ============================================================
SELECT
    age_group,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount), 2) AS avg_spend,
    ROUND(AVG(review_rating)::numeric, 2) AS avg_rating
FROM customer
GROUP BY age_group
ORDER BY avg_spend DESC;

-- ============================================================
-- 5. Gender breakdown by category
-- ============================================================
SELECT
    category,
    gender,
    COUNT(*) AS orders,
    SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY category, gender
ORDER BY category, total_revenue DESC;

-- ============================================================
-- 6. Subscription status vs. average spend and previous purchases
-- ============================================================
SELECT
    subscription_status,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount), 2) AS avg_spend,
    ROUND(AVG(previous_purchases), 1) AS avg_previous_purchases
FROM customer
GROUP BY subscription_status;

-- ============================================================
-- 7. Discount usage impact on order value
-- ============================================================
SELECT
    discount_applied,
    COUNT(*) AS orders,
    ROUND(AVG(purchase_amount), 2) AS avg_order_value
FROM customer
GROUP BY discount_applied;

-- ============================================================
-- 8. Most popular payment methods
-- ============================================================
SELECT
    payment_method,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM customer
GROUP BY payment_method
ORDER BY orders DESC;

-- ============================================================
-- 9. Seasonal purchase trends
-- ============================================================
SELECT
    season,
    COUNT(*) AS orders,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(review_rating)::numeric, 2) AS avg_rating
FROM customer
GROUP BY season
ORDER BY total_revenue DESC;

-- ============================================================
-- 10. Top 10 states by revenue
-- ============================================================
SELECT
    location,
    COUNT(*) AS orders,
    SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY location
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================
-- 11. Shipping type preference vs. avg spend
-- ============================================================
SELECT
    shipping_type,
    COUNT(*) AS orders,
    ROUND(AVG(purchase_amount), 2) AS avg_order_value
FROM customer
GROUP BY shipping_type
ORDER BY orders DESC;

-- ============================================================
-- 12. Customer segments: frequent buyers with high spend
-- (potential "VIP" segment for marketing)
-- ============================================================
SELECT
    customer_id,
    previous_purchases,
    purchase_amount,
    purchase_frequency_days
FROM customer
WHERE previous_purchases > (SELECT AVG(previous_purchases) FROM customer)
  AND purchase_amount > (SELECT AVG(purchase_amount) FROM customer)
ORDER BY previous_purchases DESC, purchase_amount DESC
LIMIT 25;

-- ============================================================
-- 13. Revenue by gender
-- ============================================================
SELECT
    gender,
    COUNT(*) AS orders,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount), 2) AS avg_order_value
FROM customer
GROUP BY gender
ORDER BY total_revenue DESC;

-- ============================================================
-- 14. Top 5 highest-rated products
-- ============================================================
SELECT
    item_purchased,
    COUNT(*) AS times_purchased,
    ROUND(AVG(review_rating)::numeric, 2) AS avg_rating
FROM customer
GROUP BY item_purchased
ORDER BY avg_rating DESC
LIMIT 5;

-- ============================================================
-- 15. Products most often bought with a discount (% of orders)
-- ============================================================
SELECT
    item_purchased,
    COUNT(*) AS orders,
    ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2)
        AS pct_orders_with_discount
FROM customer
GROUP BY item_purchased
ORDER BY pct_orders_with_discount DESC
LIMIT 5;

-- ============================================================
-- 16. Top 3 best-selling items within each category
-- ============================================================
WITH item_counts AS (
    SELECT
        category,
        item_purchased,
        COUNT(*) AS orders,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(*) DESC) AS item_rank
    FROM customer
    GROUP BY category, item_purchased
)
SELECT category, item_purchased, orders, item_rank
FROM item_counts
WHERE item_rank <= 3
ORDER BY category, item_rank;

-- ============================================================
-- 17. Customer segmentation: New / Returning / Loyal
-- ============================================================
WITH segments AS (
    SELECT
        customer_id,
        purchase_amount,
        CASE
            WHEN previous_purchases = 1 THEN 'New'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'Loyal'
        END AS customer_segment
    FROM customer
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount), 2) AS avg_spend
FROM segments
GROUP BY customer_segment
ORDER BY customers DESC;

-- ============================================================
-- 18. Are repeat buyers (5+ previous purchases) subscribed?
-- ============================================================
SELECT
    subscription_status,
    COUNT(*) AS repeat_buyers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_repeat_buyers
FROM customer
WHERE previous_purchases > 5
GROUP BY subscription_status;

-- ============================================================
-- 19. Average rating by category
-- ============================================================
SELECT
    category,
    COUNT(*) AS orders,
    ROUND(AVG(review_rating)::numeric, 2) AS avg_rating
FROM customer
GROUP BY category
ORDER BY avg_rating DESC;

-- ============================================================
-- 20. Do high spenders rely more on discounts?
-- ============================================================
SELECT
    CASE
        WHEN purchase_amount >= (SELECT AVG(purchase_amount) FROM customer)
            THEN 'Above average spend'
        ELSE 'Below average spend'
    END AS spend_level,
    COUNT(*) AS orders,
    ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)
        AS pct_with_discount
FROM customer
GROUP BY spend_level
ORDER BY spend_level;

-- ============================================================
-- 21. Share of total revenue by age group
-- ============================================================
SELECT
    age_group,
    SUM(purchase_amount) AS total_revenue,
    ROUND(100.0 * SUM(purchase_amount) / SUM(SUM(purchase_amount)) OVER (), 1)
        AS pct_of_revenue
FROM customer
GROUP BY age_group
ORDER BY total_revenue DESC;