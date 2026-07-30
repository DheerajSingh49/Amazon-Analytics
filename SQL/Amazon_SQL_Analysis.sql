#Database Overview

SELECT COUNT(*) 
FROM amazon.amzn;

SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema='Amazon'
AND table_name='amzn';

SELECT *
FROM amazon.amzn
LIMIT 10;


#Data Quality Checks

SELECT *
FROM amazon.amzn
WHERE product_id IS NULL;

SELECT product_id,
       COUNT(*) AS occurrences
FROM amazon.amzn
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

SELECT DISTINCT rating_count
FROM Amazon.amzn
LIMIT 20;

SELECT
    COUNT(*) FILTER (WHERE product_name IS NULL OR TRIM(product_name)='') AS product_name_missing,
    COUNT(*) FILTER (WHERE category IS NULL OR TRIM(category)='') AS category_missing,
    COUNT(*) FILTER (WHERE discounted_price IS NULL OR TRIM(discounted_price)='') AS discounted_price_missing,
    COUNT(*) FILTER (WHERE actual_price IS NULL OR TRIM(actual_price)='') AS actual_price_missing,
    COUNT(*) FILTER (WHERE rating IS NULL OR TRIM(rating)='') AS rating_missing,
    COUNT(*) FILTER (WHERE rating_count IS NULL OR TRIM(rating_count)='') AS rating_count_missing
FROM Amazon.amzn;


#Data Cleaning

CREATE TABLE Amazon.amazon_clean AS
SELECT
    product_id,
    product_name,
    category,
    REPLACE(REPLACE(discounted_price,'₹',''),',','')::NUMERIC AS discounted_price,
    REPLACE(REPLACE(actual_price,'₹',''),',','')::NUMERIC AS actual_price,
    REPLACE(discount_percentage,'%','')::NUMERIC AS discount_percentage,
    CASE
        WHEN rating ~ '^[0-9]+(\.[0-9]+)?$'
        THEN rating::NUMERIC
        ELSE NULL
    END AS rating,
    REPLACE(rating_count,',','')::INTEGER AS rating_count,
    about_product,
    user_id,
    user_name,
    review_id,
    review_title,
    review_content,
    img_link,
    product_link
FROM Amazon.amzn;

SELECT COUNT(*)
FROM Amazon.amazon_clean
WHERE rating IS NULL;

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema='Amazon'
AND table_name='amazon_clean'
ORDER BY ordinal_position;


#Feature Engineering

ALTER TABLE Amazon.amazon_clean
ADD COLUMN main_category TEXT;

UPDATE Amazon.amazon_clean
SET main_category = SPLIT_PART(category,'|',1);

SELECT DISTINCT main_category
FROM Amazon.amazon_clean
ORDER BY main_category;

SELECT
    main_category,
    COUNT(*) AS total_products
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY total_products DESC;


#Dataset Summary

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT category) AS total_categories,
    COUNT(DISTINCT main_category) AS total_main_categories,
    ROUND(AVG(rating),2) AS avg_rating,
    ROUND(AVG(discount_percentage),2) AS avg_discount,
    ROUND(AVG(discounted_price),2) AS avg_selling_price
FROM Amazon.amazon_clean;


#Category Analysis

SELECT
    category,
    COUNT(*) AS total_products
FROM Amazon.amazon_clean
GROUP BY category
ORDER BY total_products DESC;

SELECT
    main_category,
    COUNT(*) AS total_products
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY total_products DESC;

SELECT
    category,
    ROUND(AVG(rating),2) AS avg_rating
FROM Amazon.amazon_clean
GROUP BY category
ORDER BY avg_rating DESC;

SELECT
    main_category,
    ROUND(AVG(rating),2) AS avg_rating
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY avg_rating DESC;

SELECT
    category,
    ROUND(AVG(discount_percentage),2) AS avg_discount
FROM Amazon.amazon_clean
GROUP BY category
ORDER BY avg_discount DESC;


#Product Analysis

SELECT
    product_name,
    rating
FROM Amazon.amazon_clean
ORDER BY rating DESC
LIMIT 10;

SELECT
    product_name,
    rating_count
FROM Amazon.amazon_clean
ORDER BY rating_count DESC
LIMIT 10;

SELECT
    product_name,
    actual_price,
    discounted_price,
    discount_percentage
FROM Amazon.amazon_clean
ORDER BY discount_percentage DESC
LIMIT 10;

SELECT
    LEFT(product_name,20) AS product_name,
    actual_price,
    discounted_price,
    actual_price-discounted_price AS savings
FROM Amazon.amazon_clean
ORDER BY savings DESC
LIMIT 10;


#Customer Rating Analysis

SELECT
    rating,
    COUNT(*) AS total_products
FROM Amazon.amazon_clean
GROUP BY rating
ORDER BY rating;

SELECT
    product_name,
    category,
    rating,
    rating_count
FROM Amazon.amazon_clean
WHERE rating >= 4.5
AND rating_count < 500
ORDER BY rating DESC,
rating_count DESC;


#Window Functions

WITH ranked_products AS
(
SELECT
    category,
    product_name,
    rating,
    rating_count,
    ROW_NUMBER() OVER
    (
        PARTITION BY category
        ORDER BY rating DESC,
                 rating_count DESC
    ) AS rn
FROM Amazon.amazon_clean
)

SELECT *
FROM ranked_products
WHERE rn <= 3;

SELECT
    product_name,
    discount_percentage,
    RANK() OVER
    (
        ORDER BY discount_percentage DESC
    ) AS discount_rank
FROM Amazon.amazon_clean;

SELECT
    category,
    COUNT(*) AS products,
    ROUND
    (
        COUNT(*)*100.0/
        SUM(COUNT(*)) OVER(),
        2
    ) AS percentage
FROM Amazon.amazon_clean
GROUP BY category
ORDER BY percentage DESC;


#Business Insights

SELECT
    main_category,
    ROUND(AVG(discounted_price),2) AS avg_price,
    ROUND(AVG(discount_percentage),2) AS avg_discount,
    ROUND(AVG(rating),2) AS avg_rating
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY avg_rating DESC;

SELECT
    main_category,
    MAX(discount_percentage) AS highest_discount,
    MIN(discount_percentage) AS lowest_discount
FROM Amazon.amazon_clean
GROUP BY main_category;

SELECT
    main_category,
    SUM(rating_count) AS total_reviews
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY total_reviews DESC;

SELECT
    main_category,
    ROUND(AVG(actual_price-discounted_price),2) AS avg_savings
FROM Amazon.amazon_clean
GROUP BY main_category
ORDER BY avg_savings DESC;

#Power BI KPI Queries

SELECT COUNT(*) AS Total_Products
FROM Amazon.amazon_clean;

SELECT COUNT(DISTINCT main_category) AS Total_Categories
FROM Amazon.amazon_clean;

SELECT ROUND(AVG(rating),2) AS Average_Rating
FROM Amazon.amazon_clean;

SELECT ROUND(AVG(discount_percentage),2) AS Average_Discount
FROM Amazon.amazon_clean;

SELECT ROUND(AVG(discounted_price),2) AS Average_Selling_Price
FROM Amazon.amazon_clean;
