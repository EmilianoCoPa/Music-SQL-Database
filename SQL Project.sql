-- Questions
/* Question 1: Which countries have the most Invoices?
Use the Invoice table to determine the countries that have the most invoices.
Provide a table of BillingCountry and Invoices ordered by the number of invoices
for each country. The country with the most invoices should appear first. */

SELECT BillingCountry, COUNT(Invoiceid)
FROM Invoice
GROUP BY BillingCountry
ORDER BY 2 DESC;

/* Question 2: Which city has the best customers?
We want to throw a promotional Music Festival in the city we made the most money.
Write a query that returns the 1 city that has the highest sum of invoice totals.
Return both the city name and the sum of all invoice totals. */

SELECT BillingCity, SUM(Total)
FROM Invoice
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/* Question 3: Who is the best customer?
The customer who has spent the most money will be declared the best customer.
Build a query that returns the person who has spent the most money. I found the
solution by linking the following three: Invoice, InvoiceLine, and Customer
tables to retrieve this information, but you can probably do it with fewer! */

SELECT  SUM(i.Total), i.CustomerId, c.FirstName || ' '  || c.LastName AS FullName
FROM Invoice i
JOIN Customer c
ON c.CustomerId = i.CustomerId
GROUP BY 2
ORDER BY 1 DESC
LIMIT 1;

/* Question 4
Use your query to return the email, first name, last name, and Genre of all
Rock Music listeners (Rock & Roll would be considered a different category for
this exercise). Return your list ordered alphabetically by email address starting
with A. */

SELECT c.Email, c.FirstName, c.LastName, g.Name
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
JOIN Track t on t.TrackId = il.TrackId
JOIN Genre g on g.GenreId = t.GenreId
WHERE g.Name = 'Rock'
GROUP BY 1
ORDER BY 1 ASC;

/* Question 5: Who is writing the rock music?

Now that we know that our customers love rock music, we can decide which
musicians to invite to play at the concert.
Let's invite the artists who have written the most rock music in our dataset.
Write a query that returns the Artist name and total track count of the top 10
rock bands. */

SELECT a.Name, COUNT(t.TrackId) AS TotalTrackCount
FROM Artist a
JOIN Album al ON al.ArtistId = a.ArtistId
JOIN Track t ON t.AlbumId = al.AlbumId
JOIN Genre g on g.GenreId = t.GenreId
WHERE g.Name = 'Rock'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

/* Question 6

First, find which artist has earned the most according to the InvoiceLines?
Now use this artist to find which customer spent the most on this artist.
Notice, this one is tricky because the Total spent in the Invoice table might
not be on a single product, so you need to use the InvoiceLine table to find out
how many of each product was purchased, and then multiply this by the price for
each artist. */

SELECT a.Name, SUM(il.Quantity)*il.UnitPrice AS TotalTracksSold
FROM Artist a
JOIN Album al ON al.ArtistId = a.ArtistId
JOIN Track t ON t.AlbumId = al.AlbumId
JOIN InvoiceLine il ON il.TrackId = t.TrackId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

SELECT SUM(il.Quantity)*il.UnitPrice AS TotalTracksBought, c.CustomerId, c.FirstName || ' '  || c.LastName AS FullName
FROM Artist a
JOIN Album al ON al.ArtistId = a.ArtistId
JOIN Track t ON t.AlbumId = al.AlbumId
JOIN InvoiceLine il ON il.TrackId = t.TrackId
JOIN Invoice i ON i.InvoiceId = il.InvoiceId
JOIN Customer c ON c.CustomerId = i.CustomerId
WHERE a.Name = 'Iron Maiden'
GROUP BY 2
ORDER BY 1 DESC
LIMIT 1;

/* Question 7
We want to find out the most popular music Genre for each country. We determine
the most popular genre as the genre with the highest amount of purchases. Write
a query that returns each country along with the top Genre. For countries where
the maximum number of purchases is shared, return all Genres. */

WITH  GenreRank AS (
  SELECT g.Name AS Genre, i.BillingCountry AS Country, COUNT(g.Name) AS Purchases,
          DENSE_RANK() OVER(PARTITION BY  i.BillingCountry ORDER BY COUNT(g.Name) DESC) AS total_rank
        FROM Invoice i
        JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
        JOIN Track t on t.TrackId = il.TrackId
        JOIN Genre g on g.GenreId = t.GenreId
        GROUP BY 2,1
        ORDER BY 2,3 DESC)
SELECT *
FROM GenreRank
WHERE total_rank = 1

/* Question 8
Return all the track names that have a song length longer than the average song
length. Though you could perform this with two queries. Imagine you wanted your
query to update based on when new data is put in the database. Therefore, you do
not want to hard code the average into your query. You only need the Track table
to complete this query.

Return the Name and Milliseconds for each track. Order by the song length with
the longest songs listed first. */

SELECT t.Name, t.Milliseconds
FROM Track t
WHERE Milliseconds > (SELECT AVG(Milliseconds) FROM Track)
ORDER BY 2 DESC

/* Question 9
Write a query that determines the customer that has spent the most on music for
each country. Write a query that returns the country along with the top customer
and how much they spent. For countries where the top amount spent is shared,
provide all customers who spent this amount. */

WITH CustomerRank AS (
    SELECT SUM(i.Total), c.CustomerId, c.FirstName || ' '  || c.LastName AS FullName,
    i.BillingCountry AS Country,
    DENSE_RANK() OVER(PARTITION BY  i.BillingCountry ORDER BY SUM(i.Total) DESC) AS total_rank
    FROM Invoice i
    JOIN Customer c ON c.CustomerId = i.CustomerId
    GROUP BY 2
    ORDER BY 4)
SELECT *
FROM CustomerRank
WHERE total_rank = 1

-- Project Questions

-- Top selling artist for Each Country

WITH ArtistRank AS
  (SELECT SUM(il.UnitPrice * il.Quantity) AS Sales,
          a.name AS Artist,
          i.BillingCountry AS Country,
          DENSE_RANK() OVER(PARTITION BY i.BillingCountry
                            ORDER BY SUM(i.Total) DESC) AS total_rank
   FROM Invoice i
   JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
   JOIN Track t ON t.TrackId = il.TrackId
   JOIN Album al ON al.AlbumId = t.AlbumId
   JOIN Artist a ON a.ArtistId = al.ArtistId
   GROUP BY 2
   ORDER BY 4)
SELECT Artist,
       Country,
       Sales
FROM ArtistRank
WHERE total_rank = 1
ORDER BY 3 DESC;

-- Best Selling album and Song for Top 10 Artist*

WITH t1 AS
  (SELECT a.Name AS Artist,
          SUM(il.Quantity*il.UnitPrice) AS TotalTracksSold
   FROM Artist a
   JOIN Album al ON al.ArtistId = a.ArtistId
   JOIN Track t ON t.AlbumId = al.AlbumId
   JOIN InvoiceLine il ON il.TrackId = t.TrackId
   GROUP BY 1
   ORDER BY 2 DESC
   LIMIT 10),

     TopArtist AS
  (SELECT Artist
   FROM t1),

     t2 AS
  (SELECT t.Name AS Song,
          SUM(il.Quantity*il.UnitPric) AS TopSongRevenue,
          a.Name AS Artist
   FROM Track t
   JOIN InvoiceLine il ON il.TrackId = t.TrackId
   JOIN Album al ON al.AlbumId = t.AlbumId
   JOIN Artist a ON a.ArtistId = al.ArtistId
   WHERE Artist IN TopArtist
   GROUP BY 1,3
   ORDER BY 2 DESC),

     RankingSongs AS
  (SELECT Artist,
          Song,
          TopSongRevenue,
          row_number() OVER(PARTITION BY Artist
                            ORDER BY TopSongRevenue DESC) AS ranking
   FROM t2),

     TopSongs AS
  (SELECT Artist,
          Song AS TopSong,
          TopSongRevenue
   FROM RankingSongs
   WHERE ranking = 1),

     t3 AS
  (SELECT al.Title AS Album,
          SUM(il.UnitPrice * il.Quantity) AS TopAlbumRevenue,
          a.Name AS Artist
   FROM Track t
   JOIN InvoiceLine il ON il.TrackId = t.TrackId
   JOIN Album al ON al.AlbumId = t.AlbumId
   JOIN Artist a ON a.ArtistId = al.ArtistId
   JOIN Invoice i ON i.InvoiceId = il.InvoiceId
   WHERE Artist IN TopArtist
   GROUP BY 1,3
   ORDER BY 2 DESC),

     RankingAlbum AS
  (SELECT Artist,
          Album,
          TopAlbumRevenue,
          row_number() OVER(PARTITION BY Artist
                            ORDER BY TopAlbumRevenue DESC) AS ranking
   FROM t3),

     TopAlbum AS
  (SELECT Artist,
          Album AS TopAlbum,
          TopAlbumRevenue
   FROM RankingAlbum
   WHERE ranking = 1)

SELECT ta.Artist,
       TopAlbum,
       TopAlbumRevenue,
       TopSong,
       TopSongRevenue
FROM TopAlbum ta
JOIN TopSongs ts ON ts.Artist = ta.Artist
ORDER BY 3 DESC;

-- Most used Media type

SELECT mt.Name AS MediaType,
       COUNT(t.TrackId) AS TimesUsed
FROM Track t
JOIN MediaType mt ON mt.MediaTypeId = t.MediaTypeId
GROUP BY 1
ORDER BY 2 DESC;

-- 10 Largest (GB) Album

SELECT al.Title,
       SUM(t.Bytes)/1000000000 AS SizeGb
FROM Album al
JOIN Track t ON t.AlbumId = al.AlbumId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
