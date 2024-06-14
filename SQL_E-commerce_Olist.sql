/*Goal - to query the Olist Database (E-commerce Brazilian company) to get the insights about their customers behavior, products and operational efficiency*/

/*Who are the high-value customers at Olist?*/
WITH paid_per_order AS 
    (SELECT order_id
      , ROUND (SUM (payment_value),2) AS payment_value
    FROM `anna-lewagon-project.Olist.olist_order_payments`
    GROUP BY 1)

SELECT customers.customer_unique_id
  , SUM (paid_per_order.payment_value) AS payment_value
FROM paid_per_order
LEFT JOIN `anna-lewagon-project.Olist.olist_orders` AS orders
  ON orders.order_id = paid_per_order.order_id
LEFT JOIN `anna-lewagon-project.Olist.olist_customers` AS customers
    ON orders.customer_id = customers.customer_id
GROUP BY 1
ORDER BY payment_value DESC
LIMIT 5;

/*What is the average customer lifetime value?*/
WITH paid_per_order AS 
    (SELECT order_id
      , ROUND (SUM (payment_value),2) AS payment_value
    FROM `anna-lewagon-project.Olist.olist_order_payments`
    WHERE payment_value != 0
    GROUP BY 1)

    , avg_frequency_value AS 
    (SELECT AVG (paid_per_order.payment_value) AS avg_payment_value
        , COUNT (paid_per_order.order_id) / COUNT (DISTINCT customers.customer_unique_id) AS avg_frequency
    FROM paid_per_order
    LEFT JOIN `anna-lewagon-project.Olist.olist_orders` AS orders
    ON orders.order_id = paid_per_order.order_id
    LEFT JOIN `anna-lewagon-project.Olist.olist_customers` AS customers
        ON orders.customer_id = customers.customer_id)

SELECT ROUND ((avg_payment_value * avg_frequency),2) AS average_lifetime_value
FROM avg_frequency_value;

/*How frequently do customers make the repurchase?*/
WITH paid_per_order AS 
    (SELECT order_id
      , ROUND (SUM (payment_value),2) AS payment_value
    FROM `anna-lewagon-project.Olist.olist_order_payments`
    WHERE payment_value != 0
    GROUP BY 1)

SELECT COUNT (paid_per_order.order_id) AS total_nb
      , COUNT (DISTINCT customers.customer_unique_id) AS distinct_customer
      , ROUND (COUNT (paid_per_order.order_id) / COUNT (DISTINCT customers.customer_unique_id),2) AS avg_frequency
FROM paid_per_order
LEFT JOIN `anna-lewagon-project.Olist.olist_orders` AS orders
    ON orders.order_id = paid_per_order.order_id
LEFT JOIN `anna-lewagon-project.Olist.olist_customers` AS customers
    ON orders.customer_id = customers.customer_id;

    ###2. Product and Sales Questions:

/*Which products are the best-sellers at Olist?*/
SELECT product_id
  , ROUND (SUM (price),2) AS value
FROM `anna-lewagon-project.Olist.olist_order_items`
GROUP BY 1
ORDER BY value DESC
LIMIT 10;

/*What is the overall revenue trend for Olist over time?*/
SELECT EXTRACT (YEAR FROM shipping_limit_date) AS year
  , ROUND (SUM (price),2) AS value
FROM `anna-lewagon-project.Olist.olist_order_items`
GROUP BY 1;

/*Are there specific product categories that contribute significantly to revenue?*/
SELECT products_eng.string_field_1 AS category
  , ROUND (SUM (orders.price),2) AS value
FROM `anna-lewagon-project.Olist.olist_order_items` AS orders
LEFT JOIN `anna-lewagon-project.Olist.olist_products` AS products
  ON orders.product_id = products.product_id
LEFT JOIN `anna-lewagon-project.Olist.product_category_name_translation` AS products_eng
  ON  products.product_category_name = products_eng.string_field_0
GROUP BY 1
ORDER BY value DESC;

/*What is the average delivery time for orders on Olist?*/
SELECT ROUND (AVG (DATE_DIFF (order_delivered_customer_date, order_delivered_carrier_date, DAY)),2) AS avg_delivery_time
FROM `anna-lewagon-project.Olist.olist_orders`
WHERE order_delivered_customer_date IS NOT NULL;

/*Are there specific sellers or regions facing delays?*/
SELECT seller.seller_id AS seller_id
  , state.seller_state AS seller_state
  , ROUND (AVG (DATE_DIFF (order_delivered_customer_date,order_delivered_carrier_date, DAY)),2) AS dellivery_days
FROM `anna-lewagon-project.Olist.olist_orders` AS orders
LEFT JOIN `anna-lewagon-project.Olist.olist_order_items` AS seller
  ON orders.order_id = seller.order_id
LEFT JOIN `anna-lewagon-project.Olist.olist_sellers` AS state
  ON seller.seller_id = state.seller_id
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY 1,2
ORDER BY dellivery_days DESC;

/*How does order status impact customer satisfaction?*/
WITH order_review AS 
    (SELECT order_id
      , AVG (review_score) AS avg_review_score
    FROM `anna-lewagon-project.Olist.olist_order_reviews`
    GROUP BY 1)

SELECT orders.order_status
  , ROUND (AVG (reviews.avg_review_score),2) AS avg_review_score
FROM `anna-lewagon-project.Olist.olist_orders` AS orders
LEFT JOIN order_review AS reviews
  ON orders.order_id = reviews.order_id
GROUP  BY 1
ORDER BY avg_review_score DESC
