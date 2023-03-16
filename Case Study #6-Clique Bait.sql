CREATE schema clique_bait
1. Enterprise Relationship Diagram
CREATE TABLE clique_bait.event_identifier (
  "event_type" INTEGER,
  "event_name" VARCHAR(13)
);

CREATE TABLE clique_bait.campaign_identifier (
  "campaign_id" INTEGER,
  "products" VARCHAR(3),
  "campaign_name" VARCHAR(33),
  "start_date" TIMESTAMP,
  "end_date" TIMESTAMP
);

CREATE TABLE clique_bait.page_hierarchy (
  "page_id" INTEGER,
  "page_name" VARCHAR(14),
  "product_category" VARCHAR(9),
  "product_id" INTEGER
);

CREATE TABLE clique_bait.users (
  "user_id" INTEGER,
  "cookie_id" VARCHAR(6),
  "start_date" TIMESTAMP
);

CREATE TABLE clique_bait.events (
  "visit_id" VARCHAR(6),
  "cookie_id" VARCHAR(6),
  "page_id" INTEGER,
  "event_type" INTEGER,
  "sequence_number" INTEGER,
  "event_time" TIMESTAMP
);

A.Digital Analysis


How many users are there?
SELECT 
  COUNT(DISTINCT user_id) AS user_count
FROM clique_bait.users;
How many cookies does each user have on average?
WITH cookie AS (
  SELECT 
    user_id, 
    COUNT(cookie_id) AS cookie_id_count
  FROM clique_bait.users
  GROUP BY user_id)

SELECT 
  ROUND(AVG(cookie_id_count),0) AS avg_cookie_id
FROM cookie;
What is the unique number of visits by all users per month?
SELECT 
  EXTRACT(MONTH FROM event_time) as month, 
  COUNT(DISTINCT visit_id) AS unique_visit_count
FROM clique_bait.events
GROUP BY EXTRACT(MONTH FROM event_time);
What is the number of events for each event type?
SELECT 
  event_type, 
  COUNT(*) AS event_count
FROM clique_bait.events
GROUP BY event_type
ORDER BY event_type;
What is the percentage of visits which have a purchase event?
SELECT 
  100 * COUNT(DISTINCT e.visit_id)/
    (SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events) AS percentage_purchase
FROM clique_bait.events AS e
JOIN clique_bait.event_identifier AS ei
  ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';
What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH checkout_purchase AS (
SELECT 
  visit_id,
  MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
  MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
FROM clique_bait.events
GROUP BY visit_id)

SELECT 
  ROUND(100 * (1-(SUM(purchase)::numeric/SUM(checkout))),2) AS percentage_checkout_view_with_no_purchase
FROM checkout_purchase

What are the top 3 pages by number of views?
SELECT 
  ph.page_name, 
  COUNT(*) AS page_views
FROM clique_bait.events AS e
JOIN clique_bait.page_hierarchy AS ph
  ON e.page_id = ph.page_id
WHERE e.event_type = 1 -- "Page View"
GROUP BY ph.page_name
ORDER BY page_views DESC -- Order by descending to retrieve highest to lowest number of views
LIMIT 3; -- Limit results to 3 to find the top 3

What is the number of views and cart adds for each product category?
SELECT 
  ph.product_category, 
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM clique_bait.events AS e
JOIN clique_bait.page_hierarchy AS ph
  ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY page_views DESC;

What are the top 3 products by purchases?


 B. Product Funnel Analysis
 
 WITH product_page_events AS ( -- Note 1
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM clique_bait.events AS e
  JOIN clique_bait.page_hierarchy AS ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
purchase_events AS ( -- Note 2
  SELECT 
    DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3 -- 3 for Purchase
),
combined_table AS ( -- Note 3
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM product_page_events AS ppe
  LEFT JOIN purchase_events AS pe
    ON ppe.visit_id = pe.visit_id
),
product_info AS (
  SELECT 
    product_name, 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_id, product_name, product_category)

SELECT *
FROM product_info
ORDER BY product_id;

Part 2

WITH product_page_events AS ( -- Note 1
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM clique_bait.events AS e
  JOIN clique_bait.page_hierarchy AS ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
purchase_events AS ( -- Note 2
  SELECT 
    DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3 -- 3 for Purchase
),
combined_table AS ( -- Note 3
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM product_page_events AS ppe
  LEFT JOIN purchase_events AS pe
    ON ppe.visit_id = pe.visit_id
),
product_category AS (
  SELECT 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_category)

SELECT *
FROM product_category



Which product had the highest view to purchase percentage?

SELECT 
    product_name, 
  product_category, 
  ROUND(100 * purchases/views,2) AS purchase_per_view_percentage
FROM product_info
ORDER BY purchase_per_view_percentage DESC

What is the average conversion rate from view to cart add?

5. What is the average conversion rate from cart add to purchase?

SELECT 
  ROUND(100*AVG(cart_adds/views),2) AS avg_view_to_cart_add_conversion,
  ROUND(100*AVG(purchases/cart_adds),2) AS avg_cart_add_to_purchases_conversion_rate
FROM product_info

