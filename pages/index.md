---
title: Hotel Reservation Analysis
queries:
  - rates.sql
  - reservations.sql
  - gender_distribution.sql
  - gender_rate_preferences.sql
  - age_distribution.sql
  - age_rate_preferences.sql
  - nationality_distribution.sql
  - nationality_rate_preferences.sql
  - business_segment_distribution.sql
  - business_segment_rate_preferences.sql
  - online_checkin_overall.sql
  - online_checkin_by_business_segment.sql
  - online_checkin_by_gender.sql
  - online_checkin_by_gender_age.sql
  - online_checkin_by_weekday.sql
  - revenue_per_capacity_by_gender.sql
  - revenue_per_capacity_by_gender_business.sql
---

# Executive Summary
## Booking Rate Preferences
- Male guests prioritize flexibility (58% choose Fully Flexible rates)
- Female guests are more price-conscious (higher non-refundable rate adoption)
- Business segments show stronger patterns than demographics

## Online Check-in Challenge
- Critically low adoption at 5.92% 
- OTA guests most likely to adopt (9% rate) vs. corporate guests (2% rate)
- Unknown guests never use online check-in (0% adoption)

## Profitability Insights
- Female Leisure travelers most profitable ($63.46 per night per capacity)
- Unknown FIT travelers occupy significant space with minimal returns ($13.47 per capacity)

________

# Assumptions and Limitations
- All reservation states included: Analysis includes cancelled reservations under the assumption that booking intent existed regardless of cancellation reason
- No duplicate validation performed: Assumes dataset has been pre-cleaned by data platform/engineering team with no booking ID duplicates
- Nationality analysis limited: Only included countries with 40+ bookings for reliability

________

# Booking Rate Choices by Customer Segments

## Gender-Based Analysis
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

<Details title="SQL query used for the rate preferences by gender">

```sql
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

</Details>

## Age Group Analysis
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

<Details title="SQL query used for the age group distribution analysis">

```sql
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

</Details>

### Rate Preferences by Age

<Heatmap 
    data={age_rate_preferences} 
    x=age_group 
    y=booking_rate 
    value=percentage_within_age_group
    valueFmt=pct 
/>

While all age groups prioritize flexibility, younger travelers show highest price sensitivity, while older travelers prefer advance planning discounts. However, the large proportion of unknown age data (60.78%) limits the reliability of these insights for business decision-making.

**Consistent Flexibility Preference Across All Ages**
- All age groups prefer Fully Flexible rates (44-55% within each group)
- Young travelers (0-25) most price-sensitive: 24.36% choose Non-Refundable rates
- Middle-aged travelers (25-45): Balanced between flexibility and discounts

**Data Reliability Limitations**
Age groups 55+ have insufficient sizes for reliable business insights:
- 55-65 group: Only 65 total bookings
- Over 65 group: Only 16 total bookings

Pattern suggestions for these groups (older travelers preferring early booking discounts) cannot be considered reliable for business decision-making.

<Details title="SQL query used for the rate preferences by age">

```sql
SELECT
  CASE
    WHEN res.age_group = 0 THEN 'Unknown'
    WHEN res.age_group = 25 THEN '0-25'
    WHEN res.age_group = 35 THEN '25-35'
    WHEN res.age_group = 45 THEN '35-45'
    WHEN res.age_group = 55 THEN '45-55'
    WHEN res.age_group = 65 THEN '55-65'
    WHEN res.age_group = 100 THEN '> 65'
  END AS age_group,
  r.rate_name AS booking_rate,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.age_group), 4)  percentage_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.age_group ORDER BY COUNT(*) DESC) AS rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.age_group, booking_rate 
ORDER BY res.age_group, rank
```

</Details>


## Nationality Analysis
Our hotel attracts a diverse international clientele, though 43.82% have unknown nationality:

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

<Details title="SQL query used for the nationality distribution analysis">

```sql
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

</Details>

### Rate Preferences by Nationality

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

<Details title="SQL query used for the rate preferences by nationality">

```sql
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
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.nationality_code), 4) AS percentage_within_nationality,
  DENSE_RANK() OVER (PARTITION BY res.nationality_code ORDER BY COUNT(*) DESC) AS rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
JOIN nationalities_above_40_booking n
  ON res.nationality_code = n.nationality_code
GROUP BY res.nationality_code, booking_rate
ORDER BY SUM(COUNT(*)) OVER(PARTITION BY res.nationality_code) DESC, rank
```

</Details>


## Business Segment Analysis
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

<Details title="SQL query used for the business segment distribution">

```sql
SELECT
  business_segment,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage
FROM ${reservations}
GROUP BY business_segment
ORDER BY total_bookings DESC
```

</Details>

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

<Details title="SQL query used for the rate preferences by business segment">

```sql
SELECT
  res.business_segment,
  r.rate_name AS booking_rate,
  COUNT(*) AS total_bookings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY res.business_segment), 4) AS percentage_within_age_group,
  DENSE_RANK() OVER (PARTITION BY res.business_segment ORDER BY COUNT(*) DESC) AS rank
FROM ${reservations} res
JOIN ${rates} r
  ON res.rate_id = r.rate_id
GROUP BY res.business_segment, booking_rate 
ORDER BY res.business_segment, rank
```

</Details>

________

# Online Check-in Analysis
## Overall Adoption Challenge
Online check-in adoption is critically low at just 5.92%, indicating significant barriers to digital adoption or limited system availability:

<DataTable data={online_checkin_overall} >
  <Column id=total_booking />
  <Column id=online_checkins />
  <Column id=online_checkins_rate fmt=pct2 />
</DataTable>

<Details title="SQL query used for the overall online check-in analysis">

```sql
SELECT 
  COUNT(*) AS total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkins_rate
FROM ${reservations}
```

</Details>

## By Business Segment

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

**OTA Channels Lead Digital Adoption**
- OTAs: 9.07% online check-in rate (562 total bookings)
- OTA Netto: 7.80% online check-in rate (551 total bookings)
- Leisure: 8.42% online check-in rate (499 total bookings)

**Traditional Channels Show Resistance**
- Direct Business: 2.20% online check-in rate (318 total bookings)
- FIT: 0.97% online check-in rate (516 total bookings) - surprisingly lowest
- Film: 0% online check-in rate (55 total bookings)

<Details title="SQL query used for the online check-in analysis by business segment">

```sql
SELECT
  business_segment,
  COUNT(*) as total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
GROUP BY business_segment
ORDER BY total_booking DESC
```

</Details>

## By Gender
There's a consistent low adoption accross genders:

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

<Details title="SQL query used for the online check-in analysis by gender">

```sql
SELECT
  CASE
    WHEN gender = 0 THEN 'Unknown'
    WHEN gender = 1 THEN 'Male'
    WHEN gender = 2 THEN 'Female'
  END AS gender,
  COUNT(*) AS total_booking,
  SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) AS online_checkins,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
GROUP BY gender
ORDER BY total_booking DESC
```

</Details>

## Online Check-in by Gender and Age
The gender × age segmentation reveals actionable patterns that pure demographic analysis missed, with Male 25-55 segments showing highest digital adoption: 

<BubbleChart 
    data={online_checkin_by_gender_age}
    x=total_bookings
    y=online_checkin_rate
    yFmt=pct
    series=gender_age_segment
    size=online_checkins
    scaleTo=1.2
    xMin=0
    yMin=0
    chartAreaHeight=350
  >
  <ReferenceArea 
    xMin=120 
    xMax=200 
    yMin=0.15
    yMax=0.23
    label="Male Tech-Savvy" 
    color="positive"
    border={true}
    labelPosition="center"
  />

    <ReferenceArea 
    xMin=40 
    xMax=110 
    yMin=0.04
    yMax=0.11
    label="Female/Senior Low Adoption" 
    color="info"
    border={true}
    labelPosition="center"
  />

</BubbleChart>

- Male 25-55 age range shows highest digital adoption across all segments
- Female guests consistently less likely to use online check-in regardless of age
- Sample sizes for 55+ segments too small for reliable targeting (11-54 bookings)






## Online Check-in by Weekday
Saturday shows the highest online check-in adoption rate at 12.33%, though this is based on a small denominator of only 146 total bookings.

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

<Details title="SQL query used for the online check-in analysis by weekday">

```sql
SELECT
  DAYOFWEEK(created_utc) AS day_num,
  DAYNAME(created_utc) AS weekday,
  COUNT(*) AS total_booking,
  ROUND(SUM(CASE WHEN is_online_checkin = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS online_checkin_rate
FROM ${reservations}
GROUP BY day_num, weekday
ORDER BY day_num
```

</Details>


_______

# Average Night Revenue per Occupied Capacity Analysis
## Methodology
Average night revenue per occupied capacity calculated as:
> (night_cost_sum / night_count) / occupied_space_sum

This metric provides the average night revenue per single occupied capacity unit (bed/space), normalizing for both stay length and room capacity to enable true profitability comparison across guest segments.

## By Gender

<DataTable data={revenue_per_capacity_by_gender} >
  <Column id=gender />
  <Column id=avg_night_revenue_per_occupied_capacity />
  <Column id=total_booking />
  <Column id=percentage_booking fmt=pct />
</DataTable>

While female guests show the highest revenue per capacity, they represent only 14.4% of total bookings (360 out of 2,501), making this the smallest size among the 3 gender segments. Male guests drive volume with 51.8% of bookings, while Unknown guests represent 33.8% with significantly lower profitability.

<Details title="SQL query used for the average night revenue per occupied capacity analysis by gender">

```sql
SELECT 
    CASE
      WHEN gender = 1 THEN 'Male'
      WHEN gender = 2 THEN 'Female'
      WHEN gender = 0 THEN 'Unknown'
    END AS gender,    
    ROUND(AVG((night_cost_sum / night_count) / (occupied_space_sum)), 2) AS avg_night_revenue_per_occupied_capacity,
    COUNT(*) AS total_booking,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage_booking,
    SUM(night_cost_sum) AS total_revenue
FROM ${reservations}
GROUP BY gender, 
ORDER BY avg_night_revenue_per_occupied_capacity DESC;
```

</Details>

## Cross-Segment Analysis: Gender × Business Segment

<BubbleChart 
    data={revenue_per_capacity_by_gender_business}
    x=total_bookings
    y=avg_night_revenue_per_occupied_capacity
    yFmt=usd0
    series=gender_business_segment
    size=total_revenue
    scaleTo=1.2
    xMin=0
    chartAreaHeight=350
/>

 - Male OTAs and Male OTA Nette appear as the largest bubbles in the high-volume, high-profitability quadrant.
 - Female guests consistently outperform across all business segments despite representing smaller booking volumes.
 - Unknown segments systematically underperform, particularly in FIT and Film channels.

<Details title="SQL query used for the cross-segment analysis">

```sql
SELECT 
   CASE 
      WHEN gender = 1 THEN 'Male' 
      WHEN gender = 2 THEN 'Female' 
      WHEN gender = 0 THEN 'Unknown'
   END || ' ' || business_segment AS gender_business_segment,
   COUNT(*) AS total_bookings,
   ROUND(AVG((night_cost_sum / night_count) / (occupied_space_sum)), 2) AS avg_night_revenue_per_occupied_capacity,
   ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS percentage_booking,
   ROUND(SUM(night_cost_sum), 2) AS total_revenue
FROM ${reservations}
WHERE occupied_space_sum > 0 AND night_count > 0
GROUP BY gender_business_segment
ORDER BY avg_night_revenue_per_occupied_capacity DESC
```

</Details>



### Most Profitable Guest Segments
- **Female Leisure travelers**: $63.46 per night per capacity (72 bookings, 2.88% of total bookings, $38.7K total revenue)
- **Female OTA guests**: $62.82 per night per capacity (77 bookings, 3.08% of total bookings, $41K total revenue)
- **Male OTA guests**: $59.24 per night per capacity (477 bookings, 19.07% of total bookings, $282K total revenue)

### Least Profitable Guest Segments
- **Unknown Film segment**: $4.18 per night per capacity (16 bookings, 0.64% of total bookings, $18.3K total revenue)
- **Unknown FIT travelers**: $13.47 per night per capacity (340 bookings, 13.59% of total bookings, $68.3K total revenue)
___________

# Conclusions and Recommendations

## Data Quality Improvements
- Improve demographic data collection: 34% unknown gender, 61% unknown age limits analysis reliability
- Enhance nationality capture: 44% unknown nationality prevents market-specific strategies
- Focus on business segment data. Most reliable and actionable for decision-making

## Online Check-in Priority Investigation
- System usability review required: 5.92% adoption suggests fundamental barriers
- Partner with OTA platforms for promotion (highest current adoption at 9%)
- Target Male 25-55 segments for online check-in promotion campaigns
- Investigate female resistance to digital check-in across all age groups
- Investigate corporate booking processes - Unknown guests represent 34% of bookings but 0% online check-in

## Revenue Optimization Strategy
- Target Female Leisure segment for premium offerings (highest profitability)
- Reevaluate FIT channel strategy - 21% of bookings but lowest revenue per capacity
- Optimize OTA partnerships - balance volume (Male OTAs) with profitability (Female segments)

___________

I've made this app using [Evidence.dev](https://evidence.dev/). Code is on [GitHub](https://github.com/jeremyrieunier/mews). And this is mon [Linkedin profile](https://www.linkedin.com/in/jeremyrieunier/).