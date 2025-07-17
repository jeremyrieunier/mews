---
title: Hotel Reservation Analysis
queries:
  - rates.sql
  - reservations.sql
---

# Executive Summary

# Assumptions

# Booking Rate Choices by Customer Segments

## Gender-Based Analysis

```sql gender_distribution
SELECT
  CASE
    WHEN gender = 0 then 'Unknown'
    WHEN gender = 1 then 'Male'
    WHEN gender = 2 then 'Female'
  END AS gender,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
  FROM ${reservations}
  GROUP BY gender
  ORDER BY total_bookings DESC
```
Our hotel serves a male-dominated customer base with significant unknown demographics:
<BarChart 
    data={gender_distribution}
    x=gender
    y=total_bookings
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    chartAreaHeight=350
/>

<DataTable data={gender_distribution} >
  <Column id=gender />
  <Column id=total_bookings />
  <Column id=percentage fmt=pct2 />
</DataTable>

### Rate Preferences by Gender

```sql gender_rate_preferences
SELECT
  CASE
    WHEN gender = 0 THEN 'Unknown'
    WHEN gender = 1 THEN 'Male'
    WHEN gender = 2 THEN 'Female'
  END AS gender,
  r.rate_name AS booking_rate,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY gender), 4) AS percentage_within_gender,
  DENSE_RANK() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY gender, booking_rate
ORDER BY gender DESC, rank
```
<Heatmap 
    data={gender_rate_preferences} 
    x=gender 
    y=booking_rate 
    value=percentage_within_gender 
    valueFmt=pct 
/>

Male guests prioritize flexibility, while female guests show more price sensitivity. Unknown guests follow entirely different booking patterns, likely representing corporate or agent bookings rather than individual travelers.

**Male Guests - Flexibility Focused**
- Fully Flexible rate dominates at 58.15% of male bookings
- Clear preference for maximum booking flexibility over discounts

**Female Guests - Balanced Approach**
- Fully Flexible rate leads at 46.94% but less dominant than males
- Non-Refundable rates at 18.33% - significantly higher than males (9.50%)
- More price-conscious, willing to accept restrictions for better rates

**Unknown Gender - Early Planning**
- Early-60 days rate dominates at 49.53% - dramatically different pattern
- Fully Flexible secondary at 27.07%
- Suggests advance corporate booking or travel agent reservations


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
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY age_group
ORDER BY age_group
```
**60.78% of bookings have unknown age data**, limiting the reliability of age-based insights. Among known ages:

<BarChart 
    data={age_distribution}
    x=age_group
    y=total_bookings
    sort=false
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={age_distribution} >
  <Column id=age_group />
  <Column id=total_bookings />
  <Column id=percentage fmt=pct2 />
</DataTable>


### Rate Preferences by Age

```sql age_rate_preferences
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
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.age_group), 4) as percentage_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.age_group ORDER BY COUNT(*) DESC) as rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.age_group, booking_rate 
ORDER BY res.age_group, rank
```

<Heatmap 
    data={age_rate_preferences} 
    x=age_group 
    y=booking_rate 
    value=percentage_within_age_group
    valueFmt=pct 
/>

While all age groups prioritize flexibility, younger travelers show highest price sensitivity, while older travelers prefer advance planning discounts. However, the large proportion of unknown age data (60.78%) limits the statistical reliability of these insights for business decision-making.

**Consistent Flexibility Preference Across All Ages**
- All age groups prefer Fully Flexible rates (44-55% within each group)
- Young travelers (0-25) most price-sensitive: 24.36% choose Non-Refundable rates
- Middle-aged travelers (25-45): Balanced between flexibility and discounts

**Statistical Reliability Limitations**
Age groups 55+ have insufficient sample sizes for reliable business insights:
- 55-65 group: Only 65 total bookings
- Over 65 group: Only 16 total bookings

Pattern suggestions for these groups (older travelers preferring early booking discounts) cannot be considered statistically reliable for business decision-making.

## Nationality Analysis
```sql nationality_distribution
SELECT
  CASE
    WHEN nationality_code = 'NULL' THEN 'Unknown'
    ELSE nationality_code
  END AS nationality_code,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY nationality_code
ORDER BY total_bookings DESC
LIMIT 10
```
Our hotel attracts a diverse international clientele, though 43.82% have unknown nationality :

<BarChart 
    data={nationality_distribution}
    x=nationality_code
    y=total_bookings
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={nationality_distribution} >
  <Column id=nationality_code />
  <Column id=total_bookings />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql nationality_rate_preferences
WITH nationalities_above_40_booking AS (
  SELECT nationality_code
  FROM ${reservations}
  GROUP BY nationality_code
  HAVING COUNT(*) > 40
)
SELECT
  res.nationality_code,
  r.rate_name AS booking_rate,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.nationality_code), 4) as percentage_within_nationality,
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
    data={nationality_rate_preferences} 
    x=nationality_code
    y=booking_rate 
    value=percentage_within_nationality
    valueFmt=pct 
/>

With 43.82% unknown nationality data and several countries having small sample sizes (46-72 bookings), insights for smaller markets should be considered preliminary. Business decisions should focus on the larger markets (US, GB and DE).

**European Guests -  Flexibility Seekers**
- German guests lead flexibility preference at 71.43% Fully Flexible (154 bookings)
- Czech guests at 76.12% (67 bookings) and Slovak guests at 63.89% (72 bookings) Fully Flexible
- British guests show high flexibility demand at 65.24% (187 bookings)

**US Guests - Balanced Value Approach**
- Fully Flexible preferred at 44.86% but significantly lower than Europeans
- Higher price sensitivity: 16.05% choose Non-Refundable rates
- Unique preference for Direct Booking rates at 7.82% (highest among all nationalities)


## Business Segment Analysis
```sql business_segment_distribution
SELECT
  business_segment,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY business_segment
ORDER BY total_bookings DESC
```
Business segments are relatively balanced across our hotel's distribution channels:

<BarChart 
    data={business_segment_distribution}
    x=business_segment
    y=total_bookings
    y2SeriesType=line
    y2=percentage
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={business_segment_distribution} >
  <Column id=business_segment />
  <Column id=total_bookings />
  <Column id=percentage fmt=pct2 />
</DataTable>

```sql business_segment_rate_preferences
SELECT
  res.business_segment,
  r.rate_name AS booking_rate,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.business_segment), 4) as percentage_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.business_segment ORDER BY COUNT(*) DESC) as rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.business_segment, booking_rate 
ORDER BY res.business_segment, rank
```

### Rate Preferences by Business Segment

<Heatmap 
    data={business_segment_rate_preferences} 
    x=business_segment
    y=booking_rate 
    value=percentage_within_age_group
    valueFmt=pct 
/>

- OTA channels drive flexibility demand - guests pay premium when unable to contact hotel directly
- FIT travelers most price-sensitive - plan ahead for discounts
- Corporate segments balance flexibility with advance planning
- Leisure travelers show most diverse booking patterns

# Online Check-in Analysis
## Overall Adoption Challenge

```sql online_checkin_overall
SELECT 
  COUNT(*) AS total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) as online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) as online_checkins_rate
FROM ${reservations}
```

Online check-in adoption is critically low at just 5.92%, indicating significant barriers to digital adoption or limited system availability:

<DataTable data={online_checkin_overall} >
  <Column id=total_booking />
  <Column id=online_checkins />
  <Column id=online_checkins_rate fmt=pct2 />
</DataTable>

## By Business Segment

```sql online_checkin_by_business_segment
SELECT
  business_segment,
  COUNT(*) as total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
GROUP BY business_segment
ORDER BY total_booking DESC
```

<BarChart 
    data={online_checkin_by_business_segment}
    x=business_segment
    y=total_booking
    y2SeriesType=line
    y2=online_checkin_rate
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={online_checkin_by_business_segment} >
  <Column id=business_segment />
  <Column id=total_booking />
  <Column id=online_checkin_rate fmt=pct2 />
</DataTable>

OTA Channels Lead Digital Adoption:
- OTAs: 9.07% online check-in rate (562 total bookings)
- OTA Netto: 7.80% online check-in rate (551 total bookings)
- Leisure: 8.42% online check-in rate (499 total bookings)

Traditional Channels Show Resistance:

- Direct Business: 2.20% online check-in rate (318 total bookings)
- FIT: 0.97% online check-in rate (516 total bookings) - surprisingly lowest
- Film: 0% online check-in rate (55 total bookings)

## By Gender
There's a consistent low adoption accross genders:
```sql online_checkin_by_gender
SELECT
  CASE
    WHEN gender = 0 THEN 'Unknown'
    WHEN gender = 1 THEN 'Male'
    WHEN gender = 2 THEN 'Female'
  END AS gender,
  COUNT(*) as total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
GROUP BY gender
ORDER BY total_booking DESC
```

<BarChart 
    data={online_checkin_by_gender}
    x=gender
    y=total_booking
    y2SeriesType=line
    y2=online_checkin_rate
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={online_checkin_by_gender} >
  <Column id=gender />
  <Column id=total_booking />
  <Column id=online_checkin_rate fmt=pct2 />
</DataTable>

Unknown guests never use online check-in, likely representing corporate bookings or travel agent reservations where end guests handle their own check-in.



## Weekday Creation Analysis

Saturday shows the highest online check-in adoption rate at 12.33%, though this is based on a small denominator of only 146 total bookings.

```sql online_checkin_by_weekday
SELECT
  DAYOFWEEK(created_utc) AS day_num,
  DAYNAME(created_utc) AS weekday,
  COUNT(*) as total_booking,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) as online_checkin_rate
FROM ${reservations}
GROUP BY day_num, weekday
ORDER BY day_num
```

<BarChart 
    data={online_checkin_by_weekday}
    x=weekday
    y=total_booking
    y2SeriesType=line
    y2=online_checkin_rate
    sort=false
    y2Fmt=pct2
    y2Max=1
    y2Min=0
    chartAreaHeight=350
/>

<DataTable data={online_checkin_by_weekday} >
  <Column id=weekday />
  <Column id=total_booking />
  <Column id=online_checkin_rate fmt=pct2 />
</DataTable>

The small denominator (148 total online check-ins) makes detailed analysis unreliable:
- Saturday's high rate based on only 18 online check-ins
- Daily variations likely represent statistical noise rather than meaningful patterns
- Not enough data for confident business decisions

# Average Night Revenue per Occupied Capacity Analysis

## Methodology
Average night revenue per occupied capacity calculated as:
> (night_cost_sum / night_count) / occupied_space_sum

This metric provides the average night revenue per single occupied capacity unit (bed/space), normalizing for both stay length and room capacity to enable true profitability comparison across guest segments.

## By Gender

```sql revenue_per_capacity_by_gender
SELECT 
    CASE
      WHEN gender = 1 THEN 'Male'
      WHEN gender = 2 THEN 'Female'
      WHEN gender = 0 THEN 'Unknown'
    END AS gender,    
    ROUND(AVG((night_cost_sum / night_count) / (occupied_space_sum)), 2) AS avg_night_revenue_per_occupied_capacity,
    COUNT(*) as bookings,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage_booking,
    SUM(night_cost_sum) as total_revenue
FROM ${reservations}
GROUP BY gender, 
ORDER BY avg_night_revenue_per_occupied_capacity DESC;
```
<DataTable data={revenue_per_capacity_by_gender} >
  <Column id=gender />
  <Column id=avg_night_revenue_per_occupied_capacity />
  <Column id=bookings />
  <Column id=percentage_booking fmt=pct />
</DataTable>

While female guests show the highest revenue per capacity, they represent only 14.4% of total bookings (360 out of 2,501), making this the smallest size among the three gender segments. Male guests drive volume with 51.8% of bookings, while Unknown guests represent 33.8% with significantly lower profitability.

## Cross-Segment Analysis: Gender × Business Segment


```sql revenue_per_capacity_by_gender_business
SELECT 
   CASE WHEN Gender = 1 THEN 'Male' WHEN Gender = 2 THEN 'Female' ELSE 'Unknown' END || ' ' || BusinessSegment as gender_business_segment,
   COUNT(*) as total_bookings,
   ROUND(AVG((NightCost_Sum / NightCount) / NULLIF(OccupiedSpace_Sum, 0)), 2) as avg_night_revenue_per_capacity,
   ROUND(SUM(NightCost_Sum), 2) as total_revenue
FROM reservations
WHERE OccupiedSpace_Sum > 0 AND NightCount > 0
GROUP BY gender_business_segment
ORDER BY avg_night_revenue_per_capacity DESC;
```

<BubbleChart 
    data={revenue_per_capacity_by_gender_business}
    x=total_bookings
    y=avg_night_revenue_per_capacity
    yFmt=usd0
    series=gender_business_segment
    size=total_revenue
    scaleTo=1.2
    xMin=0
    chartAreaHeight=350
/>

>