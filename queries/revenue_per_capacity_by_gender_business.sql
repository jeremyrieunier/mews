SELECT 
   CASE WHEN Gender = 1 THEN 'Male' WHEN Gender = 2 THEN 'Female' ELSE 'Unknown' END || ' ' || BusinessSegment as gender_business_segment,
   COUNT(*) as total_bookings,
   ROUND(AVG((NightCost_Sum / NightCount) / NULLIF(OccupiedSpace_Sum, 0)), 2) as avg_night_revenue_per_capacity,
   ROUND(SUM(NightCost_Sum), 2) as total_revenue
FROM reservations
WHERE OccupiedSpace_Sum > 0 AND NightCount > 0
GROUP BY gender_business_segment
ORDER BY avg_night_revenue_per_capacity DESC;