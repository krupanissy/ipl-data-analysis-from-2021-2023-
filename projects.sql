create database pros;
use pros;
CREATE TABLE fact_bating_summary_with_season AS 
SELECT b.*,
    CASE 
        WHEN m.matchdate LIKE '%2021' THEN 'Season 14'
        WHEN m.matchdate LIKE '%2022' THEN 'Season 15'
        WHEN m.matchdate LIKE '%2023' THEN 'Season 16'
        ELSE 'NA' 
    END AS season,
    m.winner,
    m.margin 
FROM new_schema.fact_bating_summary AS b 
JOIN new_schema.dim_match_summary AS m ON b.match_id = m.match_id;

CREATE TABLE fact_bowling_summary_with_season AS 
SELECT b.*,
    CASE 
        WHEN m.matchdate LIKE '%2021' THEN 'Season 14'
        WHEN m.matchdate LIKE '%2022' THEN 'Season 15'
        WHEN m.matchdate LIKE '%2023' THEN 'Season 16'
        ELSE 'NA' 
    END AS season,
    m.winner,
    m.margin 
FROM new_schema.fact_bowling_summary AS b 
JOIN new_schema.dim_match_summary AS m ON b.match_id = m.match_id;

/* 
--Primary Insights
--1. Top 10 batsmen based on past 3 years total runs scored. */

select 
batsmanName as name,
SUM(runs) as total_runs
from new_schema.fact_bating_summary
group by batsmanName
order by total_runs desc
limit 10;


/*  Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in each season)
	--Batsman who has played at least 60 balls in each season
*/
SELECT 
    batsmanName,
    ROUND(SUM(runs) / SUM(CASE WHEN `out/not_out` = 'out' THEN 1 END), 2) AS batting_avg
FROM
    fact_bating_summary_with_season 
WHERE 
    season IN ('Season 14', 'Season 15', 'Season 16') 
GROUP BY 
    batsmanName
HAVING 
    SUM(CASE WHEN season = 'Season 14' THEN balls END) >= 60
    AND SUM(CASE WHEN season = 'Season 15' THEN balls END) >= 60
    AND SUM(CASE WHEN season = 'Season 16' THEN balls END) >= 60
ORDER BY 
    batting_avg DESC
LIMIT 10;


/*# Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each season) */

SELECT 
    batsmanName,
    ROUND(SUM(runs) / SUM(balls)*100, 2) AS strike_rate
FROM
    fact_bating_summary_with_season 
WHERE 
    season IN ('Season 14', 'Season 15', 'Season 16') 
GROUP BY 
    batsmanName
HAVING 
    SUM(CASE WHEN season = 'Season 14' THEN balls END) >= 60
    AND SUM(CASE WHEN season = 'Season 15' THEN balls END) >= 60
    AND SUM(CASE WHEN season = 'Season 16' THEN balls END) >= 60
ORDER BY 
    strike_rate DESC
LIMIT 10;


/*#Top 10 bowlers based on past 3 years total wickets taken */
SELECT 
    bowlerName,
    SUM(wickets) AS total_wickets
FROM 
    new_schema.fact_bowling_summary
GROUP BY 
    bowlerName
ORDER BY 
    total_wickets DESC
LIMIT 10;

/* #Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in each season) */
select bowlerName as name,
ROUND(sum(runs) /sum(wickets),2) as bowling_avg
from fact_bowling_summary_with_season
WHERE
    season IN ('Season 14', 'Season 15', 'Season 16')
GROUP BY 
    bowlerName
HAVING 
    SUM(CASE WHEN season = 'Season 14' THEN FLOOR(overs) * 6 + (overs - FLOOR(overs)) * 10 END) >= 60
    AND SUM(CASE WHEN season = 'Season 15' THEN FLOOR(overs) * 6 + (overs - FLOOR(overs)) * 10 END) >= 60
    AND SUM(CASE WHEN season = 'Season 16' THEN FLOOR(overs) * 6 + (overs - FLOOR(overs)) * 10 END) >= 60
ORDER BY 
    bowling_avg ASC
LIMIT 10;


#Top 5 batsmen based on past 3 years boundary % (fours and sixes).
SELECT 
    batsmanName,
    ROUND((SUM(4s) * 4 + SUM(6s) * 6) / SUM(runs) * 100, 2) AS boundary_percentage
FROM 
    new_schema.fact_bating_summary
GROUP BY 
    batsmanName
HAVING
    SUM(runs) > 500
ORDER BY 
    boundary_percentage DESC
LIMIT 5;

#Top 5 bowlers based on past 3 years dot ball %.
WITH cte AS (
    SELECT 
        bowlerName,
        ROUND(SUM(overs), 1) AS total_overs,
        SUM(0s) AS dot_balls,
        SUM(FLOOR(overs) * 6 + ((overs - FLOOR(overs)) * 10)) AS total_balls
    FROM 
        new_schema.fact_bowling_summary 
    GROUP BY 
        bowlerName
    HAVING
        SUM(FLOOR(overs) * 6 + ((overs - FLOOR(overs)) * 10)) > 500 -- Filter for bowlers who have bowled more than 500 balls
)
SELECT 
    bowlerName,
    total_balls,
    dot_balls,
    ROUND((dot_balls / total_balls) * 100, 2) AS dot_balls_percentage
FROM 
    cte
ORDER BY
    dot_balls_percentage DESC
LIMIT 5;

# Top 4 teams based on past 3 years winning %
WITH TeamMatches AS (
    SELECT Team1 AS Team, Winner FROM new_schema.dim_match_summary
    UNION ALL
    SELECT Team2 AS Team, Winner FROM new_schema.dim_match_summary
)

SELECT 
    Team,
    ROUND(SUM(Winner = Team) * 100.0 / COUNT(*), 2) AS Win_Percentage
FROM TeamMatches
GROUP BY Team
ORDER BY Win_Percentage desc
LIMIT 4;

