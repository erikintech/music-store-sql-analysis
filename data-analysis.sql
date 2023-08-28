/*
	- Music Store Data Analysis With SQL
	@Date: 2023-08-13
	@Author: Erik Carcelen
	source: https://youtu.be/VFIuIjswMKM
*/

-- Revew all tables
SELECT * FROM album;
SELECT * FROM artist;
SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM genre;
SELECT * FROM invoice;
SELECT * FROM invoice_line;
SELECT * FROM media_type;
SELECT * FROM playlist;
SELECT * FROM playlist_track;
SELECT * FROM track;

-- QUETIONS:

/* Q1: Who is the senior most employee based on job title? */
SELECT first_name, last_name, title 
FROM employee
ORDER BY levels DESC
LIMIT 1;
-- Mohan Madan is the Senior General Manager in the Music Store


/* Q2: Which countries have the most Invoices? */
SELECT billing_country AS country, 
	ROUND( CAST( SUM(total) as NUMERIC ), 2 ) total_invoice
FROM invoice
GROUP BY billing_country
ORDER BY total_invoice DESC;
-- USA, Canada, Brazil, France and Germany are in the top 5 with most invoices


/* Q3: What are top 3 values of total invoice? */
SELECT billing_city, billing_country, total
FROM invoice
ORDER BY total DESC
LIMIT 3;
-- Prague is the best city with $273.24

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return the city name, sum of all invoice totals and customer name */
SELECT billing_city AS city,
	ROUND( CAST( SUM( total ) AS NUMERIC ), 2 ) AS total_invoice
FROM invoice 
GROUP BY 1
ORDER BY total_invoice DESC
LIMIT 1;
-- Prague has the best customers with a total invoice of $273.24K

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT 
	customer.customer_id,
	customer.first_name || ' ' || customer.last_name AS customer_fulll_name,
	ROUND( CAST( SUM( total ) AS NUMERIC ), 2 ) AS total_spent
FROM invoice
INNER JOIN customer ON invoice.customer_id = customer.customer_id
GROUP BY 1
ORDER BY total_spent DESC
LIMIT 1;
-- R Madhav is the customer who spent more in the music store


/* Q6: Write query to return the email, first name, last name, & 
Genre of all Rock Music listeners.Return your list ordered 
alphabetically by email starting with A. */
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name
FROM customer c
INNER JOIN invoice i
	ON c.customer_id = i.customer_id
INNER JOIN invoice_line il
	ON il.invoice_id = i.invoice_id
INNER JOIN track t
	ON il.track_id = t.track_id
INNER JOIN genre g
	ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY email;


/* Q7: Let's invite the artists who have written the most rock music in our 
dataset.Write a query that returns the Artist name and total 
track count of the top 10 rock bands. */
SELECT a.name, COUNT(a.artist_id) AS num_of_songs
FROM artist a
INNER JOIN album al
	ON al.artist_id = a.artist_id
INNER JOIN track t
	ON t.album_id = al.album_id
INNER JOIN genre g
	ON g.genre_id = t.genre_id
WHERE t.track_id IN ( SELECT t.track_id FROM track
					INNER JOIN genre g ON t.genre_id = g.genre_id
					WHERE g.name LIKE 'Rock')
GROUP BY a.name
ORDER BY num_of_songs DESC
LIMIT 10;

/* Q8: Return all the track names that have a song length longer than the average
song length. Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first. */
SELEct track.name, track.milliseconds AS song_length
FROM track
WHERE milliseconds > ( 
	SELECT AVG(track.milliseconds) FROM track
)
ORDER BY song_length DESC ;



/* Q9: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */

SELECT CONCAT( customer.first_name, ' ', customer.last_name ) AS customer_name,
	artist.name AS artist_name,
	ROUND( CAST(SUM( invoice_line.unit_price * invoice_line.quantity ) AS NUMERIC), 2) AS total_spent
FROM customer
INNER JOIN invoice ON invoice.customer_id = customer.customer_id
INNER JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
INNER JOIN track ON track.track_id = invoice_line.track_id
INNER JOIN album ON album.album_id = track.album_id
INNER JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 1, artist_name
ORDER BY total_spent DESC;




/* Q10: We want to find out the most popular music Genre for 
each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that 
returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS (
	SELECT customer.country, genre.name,
	ROW_NUMBER() OVER( PARTITION BY customer.country ORDER BY COUNT( invoice_line.quantity ) DESC ) AS rowno,
	COUNT( invoice_line.quantity ) AS purchases
	FROM invoice_line
	INNER JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	INNER JOIN customer ON customer.customer_id = invoice.customer_id
	INNER JOIN track ON track.track_id = invoice_line.track_id
	INNER JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 1, 2
	ORDER BY 1 ASC, 4 DESC
)
SELECT country, name, purchases FROM popular_genre
WHERE rowno <=1;


 


/* Q11: Write a query that determines the customer that has spent the 
most on music for each country.Write a query that returns the 
country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide 
all customers who spent this amount. */

WITH best_customer AS (
	SELECT CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
		customer.country,
		ROW_NUMBER()OVER( PARTITION BY customer.country ORDER BY SUM( il.unit_price * il.quantity ) DESC ) AS rowno,
		SUM( il.unit_price * il.quantity ) AS total_spent
	FROM invoice_line il
	INNER JOIN invoice ON invoice.invoice_id = il.invoice_id
	INNER JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1, 2
	ORDER BY 2 ASC, 4 DESC
)
SELECT customer_name, country, total_spent FROM best_customer
WHERE rowno <=1;
 

/*Q12: Wich country spent more in music*/
SELECT customer.country,
	SUM( invoice_line.unit_price * invoice_line.quantity ) AS total_spent
FROM customer
INNER JOIN invoice ON invoice.customer_id = customer.customer_id
INNER JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
GROUP BY customer.country
ORDER BY total_spent DESC
LIMIT 1;

/*Q13: Wich country spent less in music*/
SELECT customer.country,
	SUM( invoice_line.unit_price * invoice_line.quantity ) AS total_spent
FROM customer
INNER JOIN invoice ON invoice.customer_id = customer.customer_id
INNER JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
GROUP BY customer.country
ORDER BY total_spent 
LIMIT 1;