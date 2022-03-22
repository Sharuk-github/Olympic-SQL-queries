-- Creating Tables
DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY 
(
    id          INT,
    name        VARCHAR(100),
    sex         VARCHAR(10),
    age         VARCHAR(4),
    height      VARCHAR(4),
    weight      VARCHAR(4),
    team        VARCHAR(50),
    noc         VARCHAR(4),
    games       VARCHAR(20),
    year        INT,
    season      VARCHAR(8),
    city        VARCHAR(30),
    sport       VARCHAR(40),
    event       VARCHAR(100),
    medal       VARCHAR(8)
);

DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_regions;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_regions
(
    noc         VARCHAR(5),
    region      VARCHAR(40),
    notes       VARCHAR(35)
);

-- Import datasets 
/*
Our first dataset includes 270,349 imported rows with 15 different columns
Our second dateset have 3 columns and 230 rows
*/

/* Queries
1.	Fetch some basic information about our olympic data like year started, years held , total games held so far.
2.	List down all olympics games held so far.
3.	Mention the total no of nations who participated in each olympics game?
4.	Which year saw the highest and lowest no of countries participating in olympics?
5.	Which nation has participated in all of the olympic games?
6.	Identify the sport which was played in all summer olympics.
7.	Which Sports were just played only once in the olympics?
8.	Fetch the total no of sports played in each olympic games.
9.	Fetch details of the oldest athletes to win a gold medal.
10.	Find the Ratio of male and female athletes participated in all olympic games.
11.	Fetch the top 5 athletes who have won the most gold medals.
12.	Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
13.	Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
14.	List down total gold, silver and broze medals won by each country.
15.	List down total gold, silver and broze medals won by each country correspONding to each olympic games.
16.	Identify which country won the most gold, most silver and most bronze medals in each olympic games.
17.	Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
18.	Which countries have never won gold medal but have won silver/bronze medals?
19.	In which Sport/event, India has won highest medals.
20.	Break down all olympic games WHERE india won medal for Hockey and how many medals in each olympic games.
*/

-- 1. Fetch some basic information about our olympic data like year started, years held , total games held so far.
SELECT  MIN(year) started_on , MAX(year) end_year, 
		(MAX(year)-MIN(year)) years_span, COUNT(DISTINCT year) years_held, 
		COUNT(DISTINCT games) Total_games_held 
FROM olympics_history;

-- 2. List down all Olympics games held so far AND WHERE.
SELECT DISTINCT year, season, city 
FROM olympics_history 
ORDER BY games ASC;

-- 3. Mention the total no of nations who participated in each olympics game?
SELECT games, COUNT(DISTINCT nr.region) total_countries_participated
FROM olympics_history oh
JOIN olympics_history_noc_regions nr USING (noc) 
GROUP BY games;

-- 4. Which year saw the highest and lowest no of countries participating in olympics?
SELECT year, countries_participated FROM 
	(SELECT year , COUNT(DISTINCT nr.region) countries_participated, ROW_NUMBER() OVER() rn , COUNT(*) OVER() c 
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr USING (noc)
	GROUP BY year) x
WHERE x.rn= 1 or x.rn = c
ORDER BY countries_participated;

-- Alternate method with cte
WITH cte AS( 
		SELECT year,COUNT(DISTINCT nr.region) cnt FROM olympics_history oh
		JOIN olympics_history_noc_regions nr USING (noc)
		GROUP BY year)
SELECT year, cnt coutries_participated 
FROM cte 
JOIN (SELECT MAX(cnt) ma, MIN(cnt) mi FROM cte) x
ON x.ma=cte.cnt or x.mi=cte.cnt;

-- 5. Which nation has participated in all of the olympic games?
SELECT region Nations
FROM olympics_history
JOIN olympics_history_noc_regions USING(noc)
GROUP BY noc
HAVING COUNT(DISTINCT games)  =	(SELECT COUNT(DISTINCT games)
				FROM olympics_history);

-- 6. Identify the sport which was played in all summer olympics.
SELECT sport
FROM olympics_history
WHERE season='summer'
GROUP BY sport
HAVING COUNT(DISTINCT games)  =	(SELECT COUNT(DISTINCT games)
				FROM olympic
				WHERE season='summer');

-- 7. Which Sports were just played only once in the olympics and in which year it took place?
SELECT sport, games 
FROM olympics_history
GROUP BY sport
HAVING COUNT(DISTINCT games)=1;

-- 8. Fetch the total no of sports played in each olympic games.
SELECT games, COUNT(DISTINCT sport) 'No. of sports' 
FROM olympics_history
GROUP BY games;
                            
-- 9. Fetch details of the oldest athletes to win a gold medal.
SELECT * 
FROM olympics_history
WHERE medal='gold' AND age=(SELECT MAX(age)
			    FROM olympic
                            WHERE medal= 'Gold');

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
WITH male AS (
			SELECT sex, COUNT(*) mc 
			FROM olympics_history 
			WHERE sex='M'),
	female AS ( 
			SELECT sex, COUNT(*) fc 
			FROM olympics_history 
			WHERE sex= 'F')
SELECT CONCAT(1 ,' : ',mc/fc) ratio FROM male, female;

-- Alternate method
SELECT CONCAT(1,':', ROUND(MAX(cnt)/MIN(cnt),2)) male_to_female_ratio
FROM 	
	(SELECT sex, COUNT(*) cnt
	FROM olympics_history
	GROUP BY sex) x;


-- 11.	Fetch the top 5 athletes who have won the most gold medals.
-- Using Rank
SELECT Name ,cnt 'No. of medals', rnk 'Rank'
FROM
	(SELECT name,COUNT(Medal) cnt, RANK() OVER(ORDER BY COUNT(Medal) DESC) rnk
	FROM olympics_history
	WHERE Medal='gold'
        GROUP BY Name) x
WHERE rnk<=5;

-- Using Dense rank
SELECT Name ,cnt 'No. of medals', rnk 'Rank'
FROM
	(SELECT name,COUNT(Medal) cnt, DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) rnk
	FROM olympics_history
	WHERE Medal='gold'
        GROUP BY Name) x
WHERE rnk<=5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT Name, cnt 'No. of medals', rnk 'Rank'
FROM
	(SELECT name,COUNT(Medal) cnt, DENSE_RANK() OVER(ORDER BY COUNT(Medal) DESC) rnk
	FROM olympics_history
	WHERE Medal IS NOT NULL AND Medal<> 'NA'
        GROUP BY Name) x
WHERE rnk<=5;

-- 13.	Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
SELECT region, COUNT(medal) Total_medals
FROM olympics_history 
JOIN olympics_history_noc_regions USING (noc)
WHERE medal <> 'NA'
GROUP BY region
ORDER BY total_medals DESC
limit 5;

-- 14. List down total gold, silver and broze medals won by each country.
SELECT region,
	SUM(CASE medal WHEN 'gold' THEN 1 ELSE 0 END) total_gold,
    SUM(CASE medal WHEN 'silver' THEN 1 ELSE 0 END) total_silver,
    SUM(CASE medal WHEN 'bronze' THEN 1 ELSE 0 END) total_bronze
FROM olympics_history
JOIN olympics_history_noc_regions USING (noc)
WHERE medal<>'NA'
GROUP BY region
ORDER BY region;


-- 15.	List down total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT games, region country,
	SUM( CASE WHEN medal = 'gold' then 1 else 0 end ) Total_gold,
	SUM( CASE WHEN medal = 'silver' then 1 else 0 end ) Total_silver,
	SUM( CASE WHEN medal = 'bronze' then 1 else 0 end ) Total_bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr USING (noc)
WHERE medal <> 'NA'
GROUP BY region, games
ORDER BY games, region  ASC;

-- 16.	Identify which country won the most gold, most silver and most bronze medals in each olympic games. 
WITH cte AS(
			SELECT games, region,
				SUM( CASE WHEN medal = 'gold' then 1 else 0 end ) Total_gold,
				SUM( CASE WHEN medal = 'silver' then 1 else 0 end ) Total_silver,
				SUM( CASE WHEN medal = 'bronze' then 1 else 0 end ) Total_bronze
			FROM olympics_history oh
			JOIN olympics_history_noc_regions nr USING (noc)
			WHERE medal <> 'NA'
			GROUP BY region, games
			ORDER BY games, region  ASC)
SELECT DISTINCT games, 
	CONCAT(FIRST_VALUE(Total_gold) OVER( PARTITION BY games ORDER BY Total_gold DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_gold DESC)) gold ,
	CONCAT(FIRST_VALUE(Total_silver) OVER( PARTITION BY games ORDER BY Total_silver DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_silver DESC))silver ,
	CONCAT(FIRST_VALUE(Total_bronze) OVER( PARTITION BY games ORDER BY Total_bronze DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_bronze DESC)) bronze
FROM cte; 

-- 17.	Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH cte AS(
			SELECT games, region,
				SUM( CASE WHEN medal = 'gold' then 1 else 0 end ) Total_gold,
				SUM( CASE WHEN medal = 'silver' then 1 else 0 end ) Total_silver,
				SUM( CASE WHEN medal = 'bronze' then 1 else 0 end ) Total_bronze,
				SUM( CASE WHEN medal <> 'NA' then 1 else 0 end ) Total_medals
			FROM olympics_history oh
			JOIN olympics_history_noc_regions nr USING (noc)
			WHERE medal <> 'NA'
			GROUP BY region, games
			ORDER BY games, region  ASC)
SELECT DISTINCT games, 
	CONCAT(FIRST_VALUE(Total_gold) OVER( PARTITION BY games ORDER BY Total_gold DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_gold DESC)) gold ,
	CONCAT(FIRST_VALUE(Total_silver) OVER( PARTITION BY games ORDER BY Total_silver DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_silver DESC))silver ,
	CONCAT(FIRST_VALUE(Total_bronze) OVER( PARTITION BY games ORDER BY Total_bronze DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_bronze DESC)) bronze,
	CONCAT(FIRST_VALUE(Total_medals) OVER( PARTITION BY games ORDER BY Total_medals DESC) ,' - ', FIRST_VALUE(region) OVER( PARTITION BY games ORDER BY Total_medals DESC)) OVERall_medals
FROM cte; 

-- 18.	Which countries have never won gold medal but have won silver/bronze medals?
WITH cte AS
		(SELECT region,
			SUM( CASE WHEN medal = 'gold' then 1 else 0 end ) Total_gold,
			SUM( CASE WHEN medal = 'silver' then 1 else 0 end ) Total_silver,
			SUM( CASE WHEN medal = 'bronze' then 1 else 0 end ) Total_bronze
		FROM olympics_history oh
		JOIN olympics_history_noc_regions nr USING (noc)
		WHERE medal <> 'NA'
		GROUP BY region
		ORDER BY region  ASC)
SELECT region, Total_gold, Total_silver, total_bronze FROM cte
WHERE Total_gold = 0 AND (Total_silver <> 0 or Total_bronze <> 0);

-- 19.	In which Sport/event, India has won highest medals.
SELECT sport,event, COUNT(*) Total_medals
FROM olympics_history
WHERE noc='ind' AND medal<> 'NA'
GROUP BY event
ORDER BY Total_medals DESC;

-- 20.	Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
SELECT games, COUNT(medal) cnt
FROM olympics_history
WHERE noc='ind' AND medal<>'NA' AND sport='hockey'
GROUP BY games
ORDER BY games;

