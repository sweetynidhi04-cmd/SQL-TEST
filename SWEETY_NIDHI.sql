CREATE DATABASE Test2DB;
USE Test2DB;
CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME,
    refund_time DATETIME NULL,
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    gross_transaction_value INT
);
CREATE TABLE items (
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(50)
);
INSERT INTO transactions 
(buyer_id, purchase_time, refund_time, store_id, item_id, gross_transaction_value)
VALUES
(3, '2019-09-19 21:19:06', NULL, 'a', 'a1', 58),
(12, '2019-12-10 20:10:14', '2019-12-15 23:19:06', 'b', 'b2', 475),
(3, '2020-09-01 23:59:46', '2020-09-02 21:22:06', 'f', 'f9', 33),
(2, '2020-04-30 21:19:06', NULL, 'd', 'd3', 250),
(1, '2020-10-22 22:20:06', NULL, 'f', 'f2', 91),
(8, '2020-04-16 21:10:22', NULL, 'e', 'e7', 24),
(5, '2019-09-23 12:09:35', '2019-09-27 02:55:02', 'g', 'g6', 61);
INSERT INTO items
(store_id, item_id, item_category, item_name)
VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f5', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');
SELECT * FROM transactions;
SELECT * FROM items;

-- 1.What is the count of purchases per month(exclusing refunded purchases )
SELECT 
    FORMAT(purchase_time, 'yyyy-MM') AS purchase_month,
    COUNT(*) AS Count
FROM transactions
WHERE refund_time IS NULL
GROUP BY FORMAT(purchase_time, 'yyyy-MM')
ORDER BY purchase_month;

-- 2.How many stores receive at least 5 orders/transactions in October 2020?
SELECT COUNT(*) AS store_count
FROM (
        SELECT store_id, COUNT(*) AS order_count
        FROM transactions
        WHERE purchase_time >= '2020-10-01'
          AND purchase_time < '2020-11-01'
        GROUP BY store_id
        HAVING COUNT(*) >= 5
     ) t;

-- 3.For each store, what is the shortest interval (in min) from purchase to refund time?
SELECT
    store_id,
    MIN(DATEDIFF(MINUTE, purchase_time, refund_time)) AS shortest_interval_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;


-- 4.What is the gross_transaction_value of every stores first order?
SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN (
        SELECT store_id, MIN(purchase_time) AS first_purchase
        FROM transactions
        GROUP BY store_id
     ) x
ON t.store_id = x.store_id
AND t.purchase_time = x.first_purchase;


-- 5.What is the most popular item name that buyers order on their first purchase
WITH first_purchase AS (
    SELECT buyer_id, MIN(purchase_time) AS fp_time
    FROM transactions
    GROUP BY buyer_id
),
fp_items AS (
    SELECT t.buyer_id, t.item_id, t.store_id
    FROM transactions t
    JOIN first_purchase fp
      ON t.buyer_id = fp.buyer_id
     AND t.purchase_time = fp.fp_time
)
SELECT TOP 1 
    i.item_name
FROM fp_items f
JOIN items i
  ON f.item_id = i.item_id 
 AND f.store_id = i.store_id
GROUP BY i.item_name
ORDER BY COUNT(*) DESC;


-- 6.Create a flag in the transaction items table indicating whether the refund can be processed or not.The condition for a refund to be processed is that it has to happen within 72 of Purchase time.

SELECT
    *,
    CASE 
        WHEN refund_time IS NOT NULL
         AND DATEDIFF(HOUR, purchase_time, refund_time) <= 72
        THEN 1 
        ELSE 0 
    END AS refund_processed
FROM transactions;




-- 7.Create a rank by buyer_id column in the transaction items table and filter for only the second purchase per buyer. (Ignore refunds here)
WITH ranked_purchases AS (
    SELECT
        buyer_id,
        purchase_time,
        store_id,
        item_id,
        gross_transaction_value,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
    WHERE refund_time IS NULL   -- ignore refunded transactions
)
SELECT *
FROM ranked_purchases
WHERE rn = 2;


-- 8.How will you find the second transaction time per buyer (dont use min/max; assume there were more transactions per buyer in the table)

WITH ranked AS (
    SELECT buyer_id,
           purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT buyer_id, purchase_time AS second_transaction_time
FROM ranked
WHERE rn = 2;


