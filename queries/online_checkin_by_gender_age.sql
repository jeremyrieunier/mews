SELECT
 CASE
   WHEN gender = 0 THEN 'Unknown'
   WHEN gender = 1 THEN 'Male'
   WHEN gender = 2 THEN 'Female'
 END || ' ' || 
 CASE 
   WHEN age_group = 0 THEN 'Unknown'
   WHEN age_group <= 25 THEN '0-25'
   WHEN age_group <= 35 THEN '25-35'
   WHEN age_group <= 45 THEN '35-45'
   WHEN age_group <= 55 THEN '45-55'
   WHEN age_group <= 65 THEN '55-65'
   ELSE '65+'
 END AS gender_age_segment,
 COUNT(*) AS total_bookings,
 SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
 ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
WHERE gender_age_segment NOT IN ('Male Unknown', 'Unknown Unknown')
GROUP BY gender_age_segment
HAVING COUNT(*) >= 5
ORDER BY total_bookings DESC;