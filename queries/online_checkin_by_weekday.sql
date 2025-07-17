SELECT
  DAYOFWEEK(created_utc) AS day_num,
  DAYNAME(created_utc) AS weekday,
  COUNT(*) as total_booking,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) as online_checkin_rate
FROM ${reservations}
GROUP BY day_num, weekday
ORDER BY day_num