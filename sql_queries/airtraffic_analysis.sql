-- Use airtraffic Schema
USE airtraffic;

/********************************************** 
      Flights, Delays and Cancellations
***********************************************/
-- Total number of flights in 2018 and 2019
SELECT COUNT(*) 
FROM flights 
WHERE FlightDate BETWEEN '2018-01-01' AND '2018-12-31'; 
-- 3218653 Flights in 2018
SELECT COUNT(*) 
FROM flights 
WHERE FlightDate BETWEEN '2019-01-01' AND '2019-12-31'; 
-- 3302708 Flights in 2019
-- Total numbers of flights that were cancelled or departed late
SELECT COUNT(*) 
FROM flights 
WHERE ((DepDelay > 0) 
	OR (Cancelled > 0)) 
    AND (FlightDate BETWEEN '2018-01-01' AND '2019-12-31'); -- used Cancelled > 0 instead of Cancelled = 1, just in case the data isn't clean
-- 2633237 Flights Delayed or Cancelled in 2018 and 2019
-- Number of flights that were cancelled broken down by the reason for cancellation
SELECT CancellationReason, 
	COUNT(*) AS number_of_flights 
FROM flights 
WHERE CancellationReason IS NOT NULL -- Only show rows that have a Cancellation Reason
GROUP BY CancellationReason; 
-- Weather 50225, Carrier 34141, National Air System 7962, Security 35.
-- Total number of flights and percentage of flights cancelled in 2019
SELECT EXTRACT(MONTH FROM FlightDate) AS Month, -- Extracting month from date
	COUNT(*) AS number_of_flights, 
    ((SUM(
		CASE WHEN Cancelled > 0 THEN 1 
        ELSE 0 
        END)/COUNT(*)) * 100) AS PercentageCancelled  -- Calculating percentage by adding up the number of flights that were canceled, divide by total amount of flights and times 100.
FROM flights 
WHERE FlightDate BETWEEN '2019-01-01' AND '2019-12-31' -- Dictating time frame
GROUP BY Month -- Grouping data by month
ORDER BY Month ASC; -- Show month in an order that makes sense

/**************************************************
| Month | number_of_flights | PercentageCancelled |
|	1	|     	262165		|		2.2078		  |
|   2	|     	237896		|		2.3128		  |
|   3	|     	283648		|		2.4957		  |
|   4	|     	274115		|		2.7102		  |
|   5	|     	285094		|		2.4245		  |
|   6	|     	282653		|		2.1836		  |
|   7	|     	291955		|		1.5492		  |
|   8	|     	290493		|		1.2475		  |
|   9	|     	268625		|		1.2352		  |
|	10	|	  	283815		|		0.8072		  |
|	11	|	  	266878		|		0.5920		  |
|	12	|	  	275371		|		0.5073		  |
***************************************************/
/******************************************************************************************************************************************************************************************** 
Cancelation rate is higher during the first half of the year and then tapers off in the second half. We see a spike in travel in March, June, July, August, and October. We see some increase 
in April, amd December. The highest amount of flights is in July and August, while the lowest is in Feburary. This pattern allows us to make the following assumptions:
	1) Months with major holidays will have more flights.
	2) Februrary being the shortest month in a year, it have the least flight.
	3) Janurary to March are known to have bad weather, which could also lead to more cancelation from weather causes. We can further look into this via the query below
    4) Summer break for students is when there is the most air travel.
*********************************************************************************************************************************************************************************************/
SELECT EXTRACT(MONTH FROM FlightDate) AS Month, 
	COUNT(*) AS number_of_flights
FROM flights
WHERE (FlightDate BETWEEN '2019-01-01' AND '2019-12-31')
	AND CancellationReason = 'Weather' -- Choosing flights that 
GROUP BY Month 
ORDER BY number_of_flights DESC; -- Show months with the most weather cancellations first

/****************************
| Month | number_of_flights |
|	1	|		4672		|
|	4	|		3847		|
|	2	|		3136		|
|	5	|		2925		|
|	6	|		2636		|
|	9	|		2380		|
|	7	|		2184		|
|	8	|		1684		|
|	3	|		1560		|
|	10	|		1183		|
|	11	|		702			|
|	12	|		634			|
*****************************/
-- The query shows that the top 5 months with cancelation due to weather to be Janurary, April, Februrary, May, and June.

/**************************************
       Airline Miles and Flights
***************************************/ 
-- Total miles traveled and number of flights broken down by airline for each year
CREATE TABLE 2019_flights_by_airlines -- Create working table
SELECT AirlineName, 
	COUNT(*) AS number_of_flights, 
    SUM(Distance) AS miles_traveled
FROM flights
WHERE FlightDate BETWEEN '2019-01-01' AND '2019-12-31'
GROUP BY AirlineName;

/*************************************************************
|      AirlineName      | number_of_flights | miles_traveled |
| Delta Air Lines Inc.  |		991986		|	 889277534	 |
| American Airlines Inc.|		946776		|	 938328443	 |
| Southwest Airlines Co.|		1363946		|	 1011583832	 |
**************************************************************/

CREATE TABLE 2018_flights_by_airlines
SELECT AirlineName, 
	COUNT(*) AS number_of_flights, 
	SUM(Distance) AS miles_traveled
FROM flights
WHERE FlightDate BETWEEN '2018-01-01' AND '2018-12-31'
GROUP BY AirlineName;

/*************************************************************
|      AirlineName      | number_of_flights | miles_traveled |
|  Delta Air Lines Inc.	|		949283		|	 842409169	 |
| American Airlines Inc.|		916818		|	 933094276	 |
| Southwest Airlines Co.|		1352552		|	 1012847097	 |
**************************************************************/

-- Year-over-year percent change in total flights and miles traveled for each airline
SELECT eightteen.AirlineName, 
	ROUND(((nineteen.number_of_flights - eightteen.number_of_flights)/eightteen.number_of_flights)*100,2) AS YOY_per_change_in_flights, -- Use rounding to make the numbers more readable
    ROUND(((nineteen.miles_traveled - eightteen.miles_traveled)/eightteen.miles_traveled)*100,2) AS YOY_per_change_in_miles_traveled -- Change in miles traveled between 2 years and times it by 100 to make it a percentage number
FROM 2018_flights_by_airlines eightteen
INNER JOIN 2019_flights_by_airlines nineteen -- Doesn't really matter which join is used here since there are no null values
	ON eightteen.AirlineName = nineteen.AirlineName;
    
/*********************************************************************************************************************************************************************** 
From the information received above I will recommend American Airlines for investment. Though Delta have the highest increase in flights, but they also have the highest 
increase in miles traveled. More miles on a plane means more costs. More costs means lesser profits. Though we see Southwest have a decrease in miles traveled, but it doesn't have
much of an increase in flight. American Airlines stradles a healthy level of increase in flights but not a significant increase in miles traveled.
*************************************************************************************************************************************************************************/

/************************************** 
       Destination Airport Usage
***************************************/
-- 10 most popular destination airports overall
SELECT airports.AirportName, 
	COUNT(*) AS number_of_flights 
FROM flights
LEFT JOIN airports -- Decided to use left join here in case of null values
	ON flights.DestAirportID = airports.AirportID
GROUP BY airports.AirportName
ORDER BY number_of_flights DESC -- Order by descending popularity
LIMIT 10; -- Have query only show the top 10 results

/***************************************************************************
|                     AirportName					   | number_of_flights |
|        Hartsfield-Jackson Atlanta International	   |	   595527	   |
|          Dallas/Fort Worth International			   |	   314423	   |
|          Phoenix Sky Harbor International			   |	   253697	   |
|          Los Angeles International				   |	   238092	   |
|          Charlotte Douglas International			   |	   216389	   |
|          Harry Reid International					   |	   200121	   |
|          Denver International	                       |	   184935	   |
| Baltimore/Washington International Thurgood Marshall |	   168334	   |
|          Minneapolis-St Paul International		   |	   165367	   |
|          Chicago Midway International				   |	   165007	   |
****************************************************************************/
/*******************************************************************************************************************************************************************************************************
Top 10 destination airports are Hartsfield-Jackson Atlanta International, Dallas/Forth Worth International, Phoenix Sky Harbor International, Los Angeles International, Charlotte Douglas International,
Harry Reid International, Denver International, Baltimore/Washington International Thurgood Marshall, Minneapolis-St Paul International, Chicaogo Midway International 
********************************************************************************************************************************************************************************************************/

-- Subquery optimization
SELECT a.AirportName, 
	number_of_flights
FROM
	(SELECT DestAirportID, 
		COUNT(*) AS number_of_flights -- Selecting only calculated columns and DestAirportID that is needed for joining
    FROM flights
    GROUP BY DestAirportID) AS f -- since DestAirportID matches up with AirportName, we can group in the subquery first
LEFT JOIN
	airports AS a
	ON a.AirportID = f.DestAirportID
ORDER BY number_of_flights DESC
LIMIT 10;

/*********************************************************************************************************************************************************************************** 
Traditional Joint took about 19.328 seconds while the subquery took 4.313 seconds. The subquery is faster because it isn't trying to join two large tables together, but was joining
a table to another table that only contains data we care about 
************************************************************************************************************************************************************************************/
SELECT f.AirlineName,
	a.AirportName,
	number_of_flights
FROM
	(SELECT AirlineName,
		DestAirportID, 
		COUNT(*) AS number_of_flights 
    FROM flights
    GROUP BY AirlineName, DestAirportID) AS f
LEFT JOIN
	airports AS a
	ON a.AirportID = f.DestAirportID
ORDER BY number_of_flights DESC
LIMIT 10;

/****************************************************************************************************************************************************************************************************************************
When we factor in airlines with the above query we can see that not all airlines use each airport equally. For example Hartsfield have 595527 total amount of incoming flights, but Delta represents 489092 of those flights, 
which is around 82% of the flights. This is to infer that each airline have their preferred airports where they have a larger marketshare.
*****************************************************************************************************************************************************************************************************************************/

/*************************** 
      Operating Costs
****************************/

-- Number of unique aircrafts each airline operated in total between 2018-2019
SELECT AirlineName, 
	COUNT(DISTINCT(Tail_Number)) AS number_of_planes -- User count distinct to make sure we are only counting unique tail numbers
FROM flights
WHERE FlightDate BETWEEN '2018-01-01' AND '2019-12-31'
GROUP BY AirlineName
ORDER BY number_of_planes DESC;

/********************************************
|       AirlineName      | number_of_planes |
| American Airlines Inc. |		993			|
|  Delta Air Lines Inc.	 |		988			|
| Southwest Airlines Co. |		754			|
*********************************************/
-- American Airlines Inc. have the most planes, while Southwest Airlines Co. have the least.

-- Average distance traveled per aircraft for each of the three airlines
SELECT AirlineName, 
	ROUND((SUM(Distance)/(COUNT(DISTINCT(Tail_Number)))), 2) AS avg_miles_per_plane -- Using the same way to count unique tail numbers and intergrating into a distance per plane calculation
FROM flights
WHERE FlightDate BETWEEN '2018-01-01' AND '2019-12-31' -- reinforcing the time frame just in case data isn't clean
GROUP BY AirlineName
ORDER BY avg_miles_per_plane DESC;

/************************************************
|       AirlineName      |	avg_miles_per_plane |
| Southwest Airlines Co. |		2684921.66		|
| American Airlines Inc. |		1884615.02		|
|  Delta Air Lines Inc.  |		1752719.34		|
*************************************************/
-- Southwest flies the most miles per plane, while Delta flies the least

/*************************************************************************************************************************************************************************************************************************** 
From the aggregation we can see that Southwest spends the least on equipment cost, but the most on fuel cost. American Airlines spends the most on equipment cost and medium amount
on fuel, while Delta spends medium amount on equipment and the least on fuel. To have a better insight we will need to put some numbers on it. Lets assume all planes are 747s and are 
new in 2018. 
Technically we know that in 2019 alot of these airlines retired some planes and bought some new planes in 2019, for example American Airlines have a total of 993 distinct planes, but
they were only running in 968 in 2018 and 978 in 2019. Meaning most likely some planes were retired in 2018 and the airline bought some new planes in 2019, but to make life easier we will just
assume all planes were bought in 2018, which would make the average price of each plane be $418.4 million. 
However airlines don't bear the full price up front, for tax purposes, according to NBAA, planes get amortized over a 6 or 8 year schedule. Let's assume they use the 6 years schedule, which 
means 20% of the plane's cost is reported for 2018 ($83.64 million), while 32% of the plane cost is reported for 2019 ($133.89 million). Which means a total inccured cost of
$217.53 million per plane for the first two years. 
We also know that a 747 burns about 5 gallons of fuel per mile. According to the US Energy Information Administration, the average jet fuel price per gallon in 2018 to 2019 is 
about $1.9483 per gallon. This means each mile of plane travel costs $9.74167 in fuel. When these numbers are factored in, Southwest became the airline with the lowest operating cost since equipment cost is so high that 
the extra almost 1 million miles per plane that Southwest flies over Delta doesn't cost as much as the extra 234 planes that Delta have.
****************************************************************************************************************************************************************************************************************************/

/*******************************
       On-Time Performance
********************************/
SELECT AirlineName, 
	COUNT(*) AS number_of_early_or_on_time_flights
FROM flights 
WHERE (DepDelay <= 0) -- DepDelay with negative values are early and 0 is on time
	AND (FlightDate BETWEEN '2018-01-01' AND '2019-12-31')
GROUP BY AirlineName
ORDER BY number_of_early_or_on_time_flights DESC; 
/******************************************************************
|     AirlineName            | number_of_early_or_on_time_flights |
| Southwest Airlines Co.     |           1380895				  |
|   Delta Air Lines Inc.     |           1346770				  |
| American Airlines Inc.     |           1161063				  |
*******************************************************************/
-- Southwest had the most early or on-time flights while American Airlines had the least.

-- Average departure delay for each time-of-day
SELECT 
	CASE
		WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN "1-morning"
		WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN "2-afternoon"
		WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN "3-evening"
		ELSE "4-night"
	END AS "time_of_day", -- Label out time of day
    AVG(IF(DepDelay < 0, 0, DepDelay)) AS average_delay
FROM flights
GROUP BY time_of_day
ORDER BY time_of_day ASC;

/*******************************
|  time_of_day | average_delay |
|  1-morning   |     5.3301    |
| 2-afternoon  |    11.6877    |
|  3-evening   |    16.4113    |
|    4-night   |     4.9229    |
********************************/
/****************************************************************************************************************************************************************************** 
From the query we can see that evening flights have the longest delays while night flights on average have the shortest. Afternoon delays are also quite long, while morning is 
also quite short. We can't really see "why" this is the case, so we could only make assumptions. A possible assumption we could make is that airports tend to be less busy
in the morning and night, which results in less delays. 
*******************************************************************************************************************************************************************************/

-- Average departure delay for each airport and time-of-day.
SELECT 
	airports.AirportName,
    CASE
		WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN "1-morning"
		WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN "2-afternoon"
		WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN "3-evening"
		ELSE "4-night"
	END AS "time_of_day", 
    AVG(IF(DepDelay < 0, 0, DepDelay)) AS average_delay
FROM flights
LEFT JOIN airports 
	ON flights.DestAirportID = airports.AirportID
GROUP BY airports.AirportName, time_of_day; -- Group by Airport then Time of Day

-- Average departure delay in the mornings per airports with at least 10,000 flights
SELECT 
	airports.AirportName,
    COUNT(*) AS number_of_flights,
    CASE
		WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN "1-morning"
		WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN "2-afternoon"
		WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN "3-evening"
		ELSE "4-night"
	END AS "time_of_day",
    AVG(IF(DepDelay < 0, 0, DepDelay)) AS average_delay
FROM flights
LEFT JOIN airports 
	ON flights.DestAirportID = airports.AirportID
GROUP BY airports.AirportName, time_of_day
HAVING number_of_flights >= 10000 AND time_of_day = "1-morning"; -- Using Having to filter Group By results

-- Top-10 airports with the highest average morning delay and their cities
SELECT 
	airports.AirportName, 
    airports.city,
    COUNT(*) AS number_of_flights,
    CASE
		WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN "1-morning"
		WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN "2-afternoon"
		WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN "3-evening"
		ELSE "4-night"
	END AS "time_of_day",
    AVG(IF(DepDelay < 0, 0, DepDelay)) AS average_delay
FROM flights
LEFT JOIN airports 
	ON flights.DestAirportID = airports.AirportID
GROUP BY airports.AirportName, airports.city, time_of_day
HAVING number_of_flights >= 10000 AND time_of_day = "1-morning"
ORDER BY average_delay DESC -- Show delay in decreasing order
LIMIT 10; -- Limit to see only top 10

/************************************************************************************************************
|           AirportName            |       city            | number_of_flights  | time_of_day | average_delay
| -------------------------------- | --------------------- | ------------------ | ----------- | -------------
| Newark Liberty International     | Newark, NJ            | 13353              | 1-morning   | 14.5337
| San Francisco International      | San Francisco, CA     | 31747              | 1-morning   | 12.5008
| John F. Kennedy International    | New York, NY          | 34571              | 1-morning   | 9.0263
| Dallas/Fort Worth International  | Dallas/Fort Worth, TX | 103726             | 1-morning   | 8.1533
| Chicago O'Hare International     | Chicago, IL           | 57578              | 1-morning   | 8.0441
| LaGuardia                        | New York, NY          | 37325              | 1-morning   | 7.7512
| Philadelphia International       | Philadelphia, PA      | 41142              | 1-morning   | 7.5286
| Seattle/Tacoma International     | Seattle, WA           | 31388              | 1-morning   | 6.5227
| Miami International              | Miami, FL             | 37916              | 1-morning   | 6.4135
| Logan International              | Boston, MA            | 34553              | 1-morning   | 5.9388
**************************************************************************************************************/
/********************************************************************************************************************************************************************************
Top 10 Airports that have the highest average morning delays are Newwark Liberty International, San Francisco International, John F. Kennedy International,
Dallas/Fort Worth International, Chicago O'Hare International, LaGuardia, Philadelphia International, Seattle/Tacoma International, Miami International, and Logan International.
They are located in Newark, San Francisco, New York Dallas/Fort Worth, Chicago, Philadelphia, Seatle, Miami and Boston.
*********************************************************************************************************************************************************************************/
SELECT 
    airports.AirportName,
    airports.city,
    COUNT(*) AS number_of_flights,
    AirlineName,
    CASE
        WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN '1-morning'
        WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN '2-afternoon'
        WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN '3-evening'
        ELSE '4-night'
    END AS 'time_of_day',
    AVG(IF(DepDelay < 0, 0, DepDelay)) AS average_delay
FROM
    flights
        LEFT JOIN
    airports ON flights.DestAirportID = airports.AirportID
GROUP BY airports.AirportName , airports.city , time_of_day , AirlineName
HAVING number_of_flights >= 10000
    AND time_of_day = '1-morning'
ORDER BY average_delay DESC
LIMIT 10;
/************************************************************************************************************************************
          AirportName            |        city          | number_of_flights |        AirlineName        | time_of_day | average_delay
---------------------------------|----------------------|-------------------|---------------------------|-------------|--------------
San Francisco International      | San Francisco, CA    | 12422             | Delta Air Lines Inc.      | 1-morning   | 10.5956
John F. Kennedy International    | New York, NY         | 12533             | American Airlines Inc.    | 1-morning   | 10.2598
John F. Kennedy International    | New York, NY         | 22038             | Delta Air Lines Inc.      | 1-morning   | 8.3334
Dallas/Fort Worth International  | Dallas/Fort Worth, TX| 97577             | American Airlines Inc.    | 1-morning   | 8.2069
Philadelphia International       | Philadelphia, PA     | 30446             | American Airlines Inc.    | 1-morning   | 8.0041
Chicago O'Hare International     | Chicago, IL          | 48943             | American Airlines Inc.    | 1-morning   | 7.8202
Miami International              | Miami, FL            | 30239             | American Airlines Inc.    | 1-morning   | 7.2695
LaGuardia                        | New York, NY         | 13476             | American Airlines Inc.    | 1-morning   | 7.1922
Los Angeles International        | Los Angeles, CA      | 24638             | Southwest Airlines Co.    | 1-morning   | 6.9475
Logan International              | Boston, MA           | 10855             | Delta Air Lines Inc.      | 1-morning   | 6.9449
**************************************************************************************************************************************/
/********** 
When we include Airline markers to the data we can see that within the cities that have the higest delays, American Airlines and Delta consistently have the highest average delay.
When factoring in all of what we discovered, I would recommend Southwest Airlines and maybe Delta to a certain extent, but American Airlines would be considered the worst option. 
Southwest have the least delays and possibily the least in operating and equipment cost. The only concern I have is that their lesser amount of flights could indicate they 
have less routes. Which could suggest they don't capture as large of a market share. While Delta sits in the middle on most of the data analysis except it sits number one on having the most flights and
miles traveled, which would suggest it have a higher market share. With a higher market share they can take advantage of economy of scale to reduce costs. 

Cross referencing real world data, our estimate where American Airlines have the highest operating costs while Southwest had the least is true. In 2019 American Airlines's operating cost was 35.38 billion,
Delta's was 34.98 billion, while Southwest was only 16.45 billion. When factoring gross operating profits our hypothesis that Delta could be a better airline to invest in holds true, since in 2019 Delta had the highest (12 billion)
operating profit out of the 3 while Southwest had the least (5.98 billion). This goes to show that, despite Delta had higher cost than Southwest, its larger amount of flights mean larger marketshare, which translates to revenue
that is high enough to offset their operating costs. 
************************/
