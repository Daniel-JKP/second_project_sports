# creating the database holding the tables which are imported with wizard
CREATE DATABASE sports;

USE sports;

#First check of missing data for each table 
SELECT *
FROM brands;

SELECT * 
FROM finance;

SELECT *
FROM info;

SELECT * 
FROM reviews;

SELECT *
FROM traffic;

#Blank values are found in all tables, so we convert to null, so they do not get confused with the value of 0.
UPDATE brands
SET brand = NULL
WHERE brand = '';

UPDATE finance
SET listing_price = NULL, sale_price = NULL, discount = NULL, revenue = NULL
WHERE listing_price = 0 AND sale_price = 0 AND discount = 0 AND revenue = 0; 

UPDATE info
SET product_name = NULL, description = NULL
WHERE product_name = '' AND description = '';

UPDATE reviews
SET rating = NULL, reviews = NULL
WHERE rating = 0 AND reviews = 0;

UPDATE traffic
SET last_visited = NULL
WHERE last_visited = '';

#Check to confirm succesful update
SELECT * 
FROM info;


#Looking for potential missing values in the data and counting these.
SELECT 
    COUNT(*) as TOTAL_ROWS, COUNT(I.DESCRIPTION) as COUNT_DESCRIPTION,
    COUNT(F.LISTING_PRICE) as COUNT_LISTING_PRICE, 
    COUNT(T.LAST_VISITED) as COUNT_LAST_VISITED
FROM INFO as I
JOIN FINANCE as F
ON I.PRODUCT_ID = F.PRODUCT_ID
JOIN TRAFFIC as T
ON T.PRODUCT_ID = F.PRODUCT_ID;

#Some missing values across the board. Last_visited ~ 8 % missing values.

#Question: How does the prices of Nike's and Adidas' differ? 	

SELECT B.BRAND, (F.LISTING_PRICE), COUNT(F.PRODUCT_ID)
FROM BRANDS as B
JOIN FINANCE as F
ON B.PRODUCT_ID = F.PRODUCT_ID
WHERE F.LISTING_PRICE > 0
GROUP BY BRAND, F.LISTING_PRICE
ORDER BY LENGTH(F.LISTING_PRICE), F.LISTING_PRICE;

#77 diferent prices with a range of 291. 

#It does make a further comparison cumbersome but we can group the prices points for better understanding.

SELECT B.BRAND, COUNT(F.PRODUCT_ID), ROUND(SUM(F.REVENUE), 0) as TOTAL_REVENUE, CASE 
	WHEN F.LISTING_PRICE < 42 THEN 'Budget'
    WHEN F.LISTING_PRICE >= 42 AND F.LISTING_PRICE < 74 THEN 'Average'
    WHEN F.LISTING_PRICE >= 74 AND F.LISTING_PRICE < 129 THEN 'Expensive'
    ELSE 'Elite' 
END AS PRICE_CATEGORY
FROM FINANCE AS F
JOIN BRANDS AS B
    ON F.PRODUCT_ID = B.PRODUCT_ID
WHERE B.BRAND IS NOT NULL
GROUP BY B.BRAND, PRICE_CATEGORY
ORDER BY TOTAL_REVENUE DESC;

#Let's find the average discunt by brand
SELECT B.BRAND, ROUND((AVG(F.DISCOUNT) * 100), 1) AS AVERAGE_DISCOUNT
FROM BRANDS AS B
JOIN FINANCE AS F
ON B.PRODUCT_ID = F.PRODUCT_ID
WHERE BRAND IS NOT NULL
GROUP BY BRAND;

#Not much discount on average for Nike customers

#Correlation between revenue and reviews
SELECT CORR(REVIEWS, REVENUE) AS REVIEW_REVENUE_CORR
FROM FINANCE AS F
JOIN REVIEWS AS R
ON F.PRODUCT_ID = R.PRODUCT_ID;

# Ratings and reviews by product description length
#Perhaps the length of a product's description might influence a product's rating and reviews —
# if so, the company can produce content guidelines for listing products on their website and test if this influences revenue. 
# Let's check this out!

SELECT TRUNCATE(LENGTH(I.DESCRIPTION), -2) as DESCRIPTION_LENGTH, ROUND(AVG(R.RATING), 2) as AVERAGE_RATING
FROM INFO AS I
JOIN REVIEWS AS R
    ON I.PRODUCT_ID = R.PRODUCT_ID
WHERE DESCRIPTION IS NOT NULL
GROUP BY DESCRIPTION_LENGTH
ORDER BY DESCRIPTION_LENGTH;

#Reviews by month and brand
SELECT B.BRAND, DATE_PART('month', T.LAST_VISITED) as MONTH, COUNT(R.REVIEWS) as NUM_REVIEWS
FROM BRANDS AS B
JOIN REVIEWS AS R
    ON B.PRODUCT_ID = R.PRODUCT_ID
JOIN TRAFFIC AS T
    ON R.PRODUCT_ID = T.PRODUCT_ID
GROUP BY B.BRAND, MONTH
HAVING B.BRAND IS NOT NULL 
    AND DATE_PART('month', T.LAST_VISITED) IS NOT NULL
ORDER BY B.BRAND, MONTH;


#Footwear product performance 

WITH FOOTWEAR as
(
    SELECT I.DESCRIPTION, F.REVENUE
    FROM INFO as I
    INNER JOIN FINANCE as F 
        ON I.PRODUCT_ID = F.PRODUCT_ID
    WHERE I.DESCRIPTION ILIKE '%shoe%'
        OR I.DESCRIPTION ILIKE '%trainer%'
        OR I.DESCRIPTION ILIKE '%foot%'
        AND I.DESCRIPTION IS NOT NULL
)

SELECT COUNT(*) as NUM_FOOTWEAR_PRODUCTS, 
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY REVENUE) as MEDIAN_FOOTWEAR_REVENUE
FROM FOOTWEAR;

#Clothing product performance
WITH FOOTWEAR as
(
    SELECT I.DESCRIPTION, F.REVENUE
    FROM INFO as I
    JOIN FINANCE as F
        ON I.PRODUCT_ID = F.PRODUCT_ID
    WHERE I.DESCRIPTION ILIKE '%shoe%'
        OR I.DESCRIPTION ILIKE '%trainer%'
        OR I.DESCRIPTION ILIKE '%foot%'
        AND I.DESCRIPTION IS NOT NULL
)

SELECT COUNT(i.PRODUCT_ID) as NUM_CLOTHING_PRODUCTS, 
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.revenue) as MEDIAN_CLOTHING_REVENUE
FROM INFO as I
INNER JOIN FINANCE as F 
    ON I.PRODUCT_ID = F.PRODUCT_ID
WHERE I.DESCRIPTION NOT IN (SELECT DESCRIPTION FROM FOOTWEAR);