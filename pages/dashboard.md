---
title: Dashboard
queries:
  - rates.sql
  - reservations.sql
  - dates.sql
---


<DateInput
    name=date_filter
    data={dates}
    dates=booking_date
    title='Date Range'
    presetRanges=none
    range
/>

```sql key
SELECT 
   created_utc::DATE AS booking_date,
   COUNT(*) AS total_bookings,
   SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) as online_checkins,
   ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as online_checkin_rate,
   ROUND(AVG((night_cost_sum / night_count) / NULLIF(occupied_space_sum, 0)), 2) as avg_night_revenue_per_occupied_capacity,
   SUM(night_cost_sum) as total_revenue
FROM ${reservations}
WHERE booking_date > '${inputs.date_filter.start}' AND booking_date < '${inputs.date_filter.end}'
GROUP BY 1
```



<BigValue 
  data={key} 
  value=total_bookings
  sparkline=booking_date
  comparison=order_growth

/>

<LineChart
    data={key}
    x=booking_date
    y=total_bookings
/>
