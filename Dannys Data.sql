CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;
drop schema human_resources;

CREATE TABLE sales 
(customer_id VARCHAR(1),
 order_date DATE,
 product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 
    SET SQL_SAFE_UPDATES = 0;
    
SELECT s.customer_id,Sum(m.price) as total_price 
FROM sales s
inner join menu m on s.product_id = m.product_id
GROUP BY s.customer_id;

SELECT customer_id, COUNT(DISTINCT(order_date)) AS total_visits
FROM sales 
GROUP BY customer_id;

/*SELECT customer_id, product_name
FROM ordered_sales_cte
WITH ordered_sales_cte AS
(
 SELECT customer_id, order_date, product_name,
  DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY s.order_date) AS rank
 FROM dbo.sales AS s
 JOIN dbo.menu AS m
  ON s.product_id = m.product_id
)
WHERE rank = 1
GROUP BY customer_id, product_name;*/

SELECT COUNT(s.product_id) as most_purchased,m.product_name
FROM sales AS s
JOIN menu AS m
 ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC
LIMIT 1;


			 

SELECT DISTINCT s.customer_id,m.product_name,
       (SELECT COUNT( m.product_id) from menu m) as Rank
FROM menu AS m
JOIN sales AS s ON m.product_id = s.product_id
ORDER BY s.customer_id ;

/* 6.Which item was purchased first by the customer after they became a member*/

    (
Select  S.customer_id,
        M.product_name,
        dense_rank() over (partition by S.customer_id order by S.order_date) as 'rank'
/*Dense_rank() OVER(Partition by S.Customer_id Order by S.Order_date) as 'Rank'*/
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)

select @@version


/*7.
Which item was purchased just before the customer became a member?*/

/*8.What is the total items and amount spent for each member before they became a member?*/
Select S.customer_id,count(S.product_id ) as quantity ,Sum(M.price) as total_sales
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date
Group by S.customer_id
/*9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/
/*In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
 how many points do customer A and B have at the end of January?*/
  