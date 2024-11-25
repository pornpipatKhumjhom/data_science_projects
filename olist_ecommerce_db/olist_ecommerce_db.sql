/*Task Requirements

What is Olist’s total sales in each year and month?

SELECT
    strftime('%Y-%m', order_purchase_timestamp) as YYYY_mm,
    round(sum(price))                           as total_sales
FROM orders      as ord
JOIN order_items as ord_itm
on ord.order_id = ord_itm.order_id
GROUP by YYYY_mm
ORDER by YYYY_mm
;
--------------------

Which products are the top-selling ones?

WITH pd_sales as (
    SELECT
        pro.product_id,
        cat_en.product_category_name_english as categories,
        round(sum(price),2)                  as total_sales
    FROM order_items as ord_itm
    JOIN products    as pro
    on ord_itm.product_id = pro.product_id
    JOIN product_category_name_translation as cat_en
    on cat_en.product_category_name = pro.product_category_name
    GROUP by pro.product_id
)
 
 
SELECT
    product_id,
    categories,
    total_sales
FROM pd_sales
ORDER by total_sales DESC
LIMIT 10
;
--------------------

Which categories are the top-selling ones?

WITH cat_sales as (
    SELECT
        cat_en.product_category_name_english as categories,
        round(sum(price),2)                  as total_sales
    FROM order_items as ord_itm
    JOIN products    as pro
    on ord_itm.product_id = pro.product_id
    JOIN product_category_name_translation as cat_en
    on cat_en.product_category_name = pro.product_category_name
    GROUP by categories
)
 
SELECT
    categories,
    total_sales
FROM cat_sales
ORDER by total_sales DESC
LIMIT 10
;
--------------------

Which customer has the highest customer spending?

WITH cus_spending as (
    SELECT
        cus.customer_id,
        customer_city ||', '|| customer_state as customer_city_state,
        round(sum(price),2)                   as total_spending
    FROM order_items as ord_itm
    JOIN orders as ord
    on ord_itm.order_id = ord.order_id
    JOIN customers as cus
    on ord.customer_id = cus.customer_id
    GROUP by cus.customer_id
)
 
SELECT
    customer_id,
    customer_city_state,
    total_spending
FROM cus_spending
ORDER by total_spending DESC
LIMIT 10
;
--------------------

Which city has the highest customer spending?

WITH city_spending as (
    SELECT
        cus.customer_id,
        customer_city ||', '|| customer_state as customer_city_state,
        round(sum(price),2)                   as total_spending
    FROM order_items as ord_itm
    JOIN orders as ord
    on ord_itm.order_id = ord.order_id
    JOIN customers as cus
    on ord.customer_id = cus.customer_id
    GROUP by customer_city_state
)
 
SELECT
    customer_city_state,
    total_spending
FROM city_spending
ORDER by total_spending DESC
LIMIT 10
;
--------------------

Which state has the highest customer spending?

WITH state_spending as (
    SELECT
        customer_state,
        round(sum(price),2) as total_spending
    FROM order_items as ord_itm
    JOIN orders as ord
    on ord_itm.order_id = ord.order_id
    JOIN customers as cus
    on ord.customer_id = cus.customer_id
    GROUP by customer_state
)
 
SELECT
    customer_state,
    total_spending
FROM state_spending
ORDER by total_spending DESC
LIMIT 10
;
--------------------

Segment all customers based on their spending into three levels: High, Medium, and Low.

WITH cus_spending as (  
     
    SELECT
        cus.customer_id,
        customer_city ||', '|| customer_state as customer_city_state,
        round(sum(price),2)                   as total_spending
    FROM order_items as ord_itm
    JOIN orders as ord
    on ord_itm.order_id = ord.order_id
    JOIN customers as cus
    on ord.customer_id = cus.customer_id
    GROUP by cus.customer_id
),
 
num_seg as (
    SELECT
        customer_id,
        customer_city_state,
        total_spending,
        ntile(3) OVER (ORDER by total_spending DESC) as num_segment 
FROM cus_spending
)
 
SELECT
    CASE WHEN num_segment = 1 THEN 'High'
         WHEN num_segment = 1 THEN 'Medium'
    ELSE 'Low'
    END as label_segment,
    customer_id,
    customer_city_state,
    total_spending
FROM num_seg
;
--------------------

Which product has the lowest customer satisfaction?

SELECT
    pro.product_id,
    round(avg(review_score),2) as avg_rv_score
FROM order_items as ord_itm
JOIN orders      as ord
on ord_itm.order_id = ord.order_id
JOIN products as pro
on ord_itm.product_id = pro.product_id
JOIN order_reviews ord_rv
on ord_itm.order_id = ord_rv.order_id
GROUP by pro.product_id
ORDER by avg_rv_score
;
--------------------

Which products are most frequently purchased together? (Market Basket Analysis)

- Using the concept of Association Rules: Product A frequently appears together with Product B
- Aanalyzed from orders (order_id) containing more than one item.

WITH paired_pd as (
    SELECT
        a.product_id as pd_a,
        b.product_id as pd_b,
        count(*) as pair_count
    FROM order_items a
    JOIN order_items b 
    on  a.order_id = b.order_id
    and a.product_id < b.product_id
    GROUP by a.product_id, b.product_id
)
 
SELECT
    pd_a,
    pd_b,
    pair_count
FROM paired_pd
WHERE pair_count > 20
ORDER by pair_count DESC
;
--------------------

Which product category has the highest return rate among the top-selling products?

- Top-selling products: Products with total sales (price) in the top 20%.
- Return rate: The ratio of orders with order_status = 'canceled' to the total number of orders in the category.

WITH pd_sales as (
    SELECT
        pro.product_id,
        cat_en.product_category_name_english as categories,
        round(sum(price),2)                  as total_sales
    FROM order_items as ord_itm
    JOIN products    as pro
    on ord_itm.product_id = pro.product_id
    JOIN product_category_name_translation as cat_en
    on cat_en.product_category_name = pro.product_category_name
    GROUP by pro.product_id
),
 
ranked_pd as (
    SELECT
        product_id,
        categories,
        total_sales,
        ntile(5) OVER (ORDER by total_sales DESC) as pd_rank
    FROM pd_sales
),
 
rank1_pd as (
    SELECT
        product_id,
        categories,
        total_sales
    FROM ranked_pd
    WHERE pd_rank = 1
),
 
cat_rt_rates as (
    SELECT
        categories,
        COUNT(CASE WHEN ord.order_status = 'canceled'
                   THEN 1 
                   END
              ) *1.0 / 
        COUNT(ord.order_id) as return_rate
    FROM orders      as ord
    JOIN order_items as ord_itm
    on ord.order_id = ord_itm.order_id
    JOIN rank1_pd as r1_pd
    on ord_itm.product_id = r1_pd.product_id
    GROUP by categories
)   
 
SELECT
    categories,
    round(return_rate,4) as return_rate
FROM cat_rt_rates
ORDER by return_rate DESC
LIMIT 10
;
--------------------*/
