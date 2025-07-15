---
title: Hotel Reservation Analysis
queries:
  - rates.sql
  - reservations.sql
---

# Executive Summary

# Assumptions

# Booking Rate Popularity

## Gender Analysis

```sql gender_distribution
SELECT
  CASE
    WHEN gender = 0 then 'Unknown'
    WHEN gender = 1 then 'Male'
    WHEN gender = 2 then 'Female'
  END AS gender,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
  FROM ${reservations}
  GROUP BY gender
  ORDER BY booking_count DESC
```

<BarChart 
    data={gender_distribution}
    x=gender
    y=booking_count
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    chartAreaHeight=350
/>

<DataTable data={gender_distribution} >
  <Column id=gender />
  <Column id=booking_count />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql gender_window
SELECT
  CASE
    WHEN gender = 0 THEN 'Unknown'
    WHEN gender = 1 THEN 'Male'
    WHEN gender = 2 THEN 'Female'
  END AS gender,
  r.rate_name AS booking_rate,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY gender), 4) AS pct_within_gender,
  DENSE_RANK() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY gender, booking_rate
ORDER BY gender DESC, rank
```
<Heatmap 
    data={gender_window} 
    x=gender 
    y=booking_rate 
    value=pct_within_gender 
    valueFmt=pct 
/>


## Age Group Analysis

```sql age_distribution
SELECT
  CASE
    WHEN age_group = 0 THEN 'Unknown'
    WHEN age_group = 25 THEN '0-25'
    WHEN age_group = 35 THEN '25-35'
    WHEN age_group = 45 THEN '35-45'
    WHEN age_group = 55 THEN '45-55'
    WHEN age_group = 65 THEN '55-65'
    WHEN age_group = 100 THEN '> 65'
  END AS age_group,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY age_group
ORDER BY age_group
```

<BarChart 
    data={age_distribution}
    x=age_group
    y=booking_count
    seriesOrder={['Unknown','0-25','25-35','35-45','45-55','55-65','> 65']}
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    chartAreaHeight=350
/>

<DataTable data={age_distribution} >
  <Column id=age_group />
  <Column id=booking_count />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql age_window
SELECT
  CASE
    WHEN res.age_group = 0 THEN 'Unknowm'
    WHEN res.age_group = 25 THEN '0-25'
    WHEN res.age_group = 35 THEN '25-35'
    WHEN res.age_group = 45 THEN '35-45'
    WHEN res.age_group = 55 THEN '45-55'
    WHEN res.age_group = 65 THEN '55-65'
    WHEN res.age_group = 100 THEN '> 65'
  END AS age_group,
  r.rate_name AS booking_rate,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.age_group), 4) as pct_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.age_group ORDER BY COUNT(*) DESC) as rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.age_group, booking_rate 
ORDER BY res.age_group, rank
```

<Heatmap 
    data={age_window} 
    x=age_group 
    y=booking_rate 
    value=pct_within_age_group
    valueFmt=pct 
/>

## Nationality Analysis
```sql nationality_distribution
SELECT
  CASE
    WHEN nationality_code = 'NULL' THEN 'Unknown'
    ELSE nationality_code
  END AS nationality_code,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY nationality_code
ORDER BY booking_count DESC
LIMIT 10
```

<BarChart 
    data={nationality_distribution}
    x=nationality_code
    y=booking_count
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    chartAreaHeight=350
/>

<DataTable data={nationality_distribution} >
  <Column id=nationality_code />
  <Column id=booking_count />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql windows_nationality
WITH nationalities_above_40_booking AS (
  SELECT nationality_code
  FROM ${reservations}
  GROUP BY nationality_code
  HAVING COUNT(*) > 40
)
SELECT
  res.nationality_code,
  r.rate_name AS booking_rate,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.nationality_code), 4) as pct_within_nationality,
  DENSE_RANK() OVER (PARTITION BY res.nationality_code ORDER BY COUNT(*) DESC) as rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
JOIN nationalities_above_40_booking n
  ON res.nationality_code = n.nationality_code
GROUP BY res.nationality_code, booking_rate
ORDER BY SUM(COUNT(*)) OVER(PARTITION BY res.nationality_code) DESC, rank
```

<Heatmap 
    data={windows_nationality} 
    x=nationality_code
    y=booking_rate 
    value=pct_within_nationality
    valueFmt=pct 
/>

## Business Segment Analysis
```sql business_distribution
SELECT
  business_segment,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY business_segment
ORDER BY booking_count DESC
```

<BarChart 
    data={business_distribution}
    x=business_segment
    y=booking_count
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    chartAreaHeight=350
/>

<DataTable data={business_distribution} >
  <Column id=business_segment />
  <Column id=booking_count />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql business_window
SELECT
  res.business_segment,
  r.rate_name AS booking_rate,
  COUNT(*) AS booking_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.business_segment), 4) as pct_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.business_segment ORDER BY COUNT(*) DESC) as rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.business_segment, booking_rate 
ORDER BY res.business_segment, rank
```

<Heatmap 
    data={business_window} 
    x=business_segment
    y=booking_rate 
    value=pct_within_age_group
    valueFmt=pct 
/>


# Guest online checking

```sql revenue
SELECT 
    -- Define your guest segments
    CASE WHEN Gender = 1 THEN 'Male' WHEN Gender = 2 THEN 'Female' ELSE 'Unknown' END as gender,    
    -- Calculate revenue per capacity
    AVG(night_cost_sum / occupied_space_sum) as avg_revenue_per_capacity,
    COUNT(*) as bookings,
    SUM(night_cost_sum) as total_revenue
FROM ${reservations}
GROUP BY gender
ORDER BY avg_revenue_per_capacity DESC;
```


```sql hypotheses
SELECT 
    CASE WHEN Gender = 1 THEN 'Male' WHEN Gender = 2 THEN 'Female' ELSE 'Unknown' END as gender,
    res.business_segment,
    COUNT(*) as booking_count,
FROM ${reservations} res  
JOIN ${rates} r ON res.rate_id = r.rate_id
GROUP BY gender, res.business_segment
```
