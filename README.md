# Data Analysis of a Mart's Data using SQL

## Intoduction
A Client's company, "Data Mart," is an online supermarket selling fresh produce, and he needs help analyzing its sales performance after a major change was made in June 2020. This change involved switching to sustainable packaging for all products, and client wants to understand how this decision affected his business, looking at sales performance across different areas and deciding how to handle such future updates to avoid disrupting sales. 

## Objective
The key business question client wanted me to help him answer were:

- What was the quantifiable impact of the changes introduced in June 2020?
- Which platform, region, segment and customer types were the most impacted by this change?
- What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?

### Schema
For this case study there is only a single table: **data_mart.weekly_sales**.
The Entity Relationship Diagram is shown below with the data types made clear.

<img width="153" height="203" alt="weekly sales" src="https://github.com/user-attachments/assets/925380ef-42d2-4cbd-af6f-d22f8d8f4af9" />

The columns are pretty self-explanatory based on the column names but here are some further details about the dataset:
<img width="435" height="123" alt="weekly_Sales table" src="https://github.com/user-attachments/assets/c69ebd94-157d-412d-9930-a2a137f4a59b" />


- Data Mart has international operations using a multi-_region_ strategy.
- Data Mart has both, a _retail_ and online platform in the form of a _Shopify_ store front to serve their customers.
- Customer segment and _customer_type_ data relates to personal age and _demographics_ information that is shared with Data Mart.
- _Transactions_ is the count of unique purchases made through Data Mart and _sales_ is the actual dollar amount of purchases.
- Each record in the dataset is related to a specific aggregated slice of the underlying sales data rolled up into a _week_date_ value which represents the start of the sales week.

## Case Study Questions
We need to clean this data before we can start answering important business questions.

### Data Cleaning
```sql 
create table clean_weekly_sales as                                      -- creating a new clean_weekly_sales table from the 
  select 
   str_to_date(week_date,'%d-%m-%y') as week_date ,                        -- Converted the week_date to a DATE format
   week(str_to_date(week_date,'%d-%m-%y')) as week_number,                 -- Added week_number,month_number and calendar_year columns
   month(str_to_date(week_date,'%d-%m-%y')) as month_number,    
   year(str_to_date(week_date,'%d-%m-%y')) as calendar_year,
   region,
   platform,
   ifnull(segment, 'UNKNOWN') as segment,                                  -- Replaced null with "unkonwn"
   ifnull(case when segment like '%1' then 'Young Adults'                    -- Added a new column age_band after the original segment column-
  	when segment like '%2' then 'Middle Aged'                                -- - using following mapping : 1 - Young Adults , 2- Middle Aged
  	when segment like '%3' or segment like '%4' then 'Retirees' end , 'UNKNOWN') as age_band,     -- and 3 or 4 - Retirees.
  ifnull(case when segment like 'C%' then 'Couples'
	when segment like 'F%' then 'Families' end, 'UNKNOWN') as demographic,    -- Add a new demographic column using the following mapping for the first letter in the segment column
  customer_type,                                                            -- C: Couples and F: Families
  transactions,
  sales,
  round(sales/transactions,2) as avg_transaction                            -- created avg_transaction column
from weekly_sales;
```

<img width="999" height="201" alt="clean weekly table" src="https://github.com/user-attachments/assets/289239d2-4b32-44ae-9d98-323780943f8a" />


## Data Exploration
### How many total transactions were there for each year in the dataset?
```sql
select calendar_year , count(transactions)
from clean_weekly_sales
group by calendar_year;
```
### What is the total sales for each region for each month?
```sql
select month_number , region, sum(sales) total_sales
from clean_weekly_sales
group by region, month_number ;
```
### What is the total count of transactions for each platform
```sql
select platform , count(*)  as total_count
from clean_weekly_sales 
group by platform;
```
### What is the percentage of sales for Retail vs Shopify for each month?
```sql
with cte as(
select month_number, sum(sales) platform_sales
 from clean_weekly_sales
 group by month_number)
 
 select cte.month_number, cws.platform, sum(cws.sales) * 100/cte.platform_sales as percentage
 from clean_weekly_sales cws
 join cte on cte.month_number=cws.month_number
 group by cws.month_number,cws.platform,cte.platform_sales
 order by cws.month_number
 ;       
```
###  What is the percentage of sales by demographic for each year in the dataset?
```sql
 with cte as (
 select calendar_year,sum(sales) as y_sales
 from clean_weekly_sales
 group by calendar_year )
 
 select cte.calendar_year,cws.demographic, 
		sum(cws.sales)*100/cte.y_sales as percentage
    from clean_weekly_sales cws
    join cte on cte.calendar_year = cws.calendar_year
    group by cws.demographic,cws.calendar_year
    ;
```
###  Which age_band and demographic values contribute the most to Retail sales?
```sql
select age_band,demographic ,sum(sales)
 from clean_weekly_sales
 where platform = 'Retail' 
 group by age_band,demographic
 order by sum(sales) desc;
```
## Before and After Analysis
Taking the week_date value of 2020-06-15 as the week where the Data Mart sustainable packaging changes came into effect.
I have included all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

### What is the total sales for the 4 weeks before and after changes came into effect? 
### What is the growth or reduction rate in actual values and percentage of sales?
```sql
with cte1 as (
select sum(sales) as sales_before
from clean_weekly_sales
where week_date >= date_sub('2020-06-15', interval 4 week) and week_date <'2020-06-15'
)
, cte2 as (
select sum(sales) as sales_after
from clean_weekly_sales
where week_date < date_add('2020-06-15', interval 4 week) and week_date >='2020-06-15'
)
select sales_before,sales_after
,sales_after-sales_before as change_in_sales
,(sales_after-sales_before) * 100/sales_before
from cte1,cte2;
```
<img width="419" height="61" alt="4weeks2020" src="https://github.com/user-attachments/assets/2c5690a9-f860-4ff9-b086-f8ade125c6bc" /> <br>
The total reduction in sales ammounted 26M % having growth percentage of -1.15%

### Output for the entire 12 weeks before and after the packaging changes.
<img width="421" height="61" alt="12weeks 2020" src="https://github.com/user-attachments/assets/7ba2de8a-d685-4335-a527-ed721b3e020e" /> <br>
The total sales ammount had a reduction of 152M $ making the reduction rate -2.14%. 

### How do the sale metrics for 4 weeks before and after compare with the previous years in 2018 and 2019?
#### Sales growth percentage for 4 weeks before and after 15th june 2019.
<img width="417" height="53" alt="4weeks 2019" src="https://github.com/user-attachments/assets/eb7bca02-d7f3-4b0b-b6cc-434000247e56" /> <br>
Both the previous years had some positive growth in sales.

#### For 2018
<img width="421" height="61" alt="4 weeks 2018 growth" src="https://github.com/user-attachments/assets/346f730c-e143-446c-b2a2-1645f05437a1" />

### Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

#### Region
<img width="519" height="147" alt="impact region" src="https://github.com/user-attachments/assets/01bbff3e-5ced-4f73-a7f5-a471a83fc834" /> <br>
Sales have declined in Asia and Oceania regions by -2.2% meanwhile europe had maximum growth percentage of 3.88%  

#### Platform
<img width="465" height="65" alt="impact platform" src="https://github.com/user-attachments/assets/3364334e-bbcf-4508-90cb-8453ccf7ceba" /> <br>
Both platforms witnessed decline in sales ammount 

#### Age_band
<img width="495" height="99" alt="impact age_band" src="https://github.com/user-attachments/assets/f520635e-8267-4f28-99ea-80bc9df62125" /> <br>
Middle aged age_band had most -2.1% and Young adults had the least -0.07% of reduction rate.

#### Demographic
<img width="507" height="75" alt="impact demographic" src="https://github.com/user-attachments/assets/22f9449c-5fc0-46c8-bcb9-d4aa37d99827" /> <br>
Families had most -1.7% and Couples had least -0.3% pf reduction rate.


#### Customer_type
<img width="553" height="85" alt="impact cust_Type" src="https://github.com/user-attachments/assets/c7ea4a34-dfe1-47ed-8a6d-c062dd1f48d3" /> <br>
Existing cutomers had most -1.3% and new customers had the least -0.6% reduction rate.

##   Conclusion
<ins>**Negative Impact**</ins> <br>
The introduction of sustainable packaging in June 2020 resulted in an immediate drop in sales (around 1.15% decline) when compared to sales during the same period in previous years (2019 and 2018).
The total decline in sales after 12 weeks of packaging change resulted in loss of 152 million $ . <br>
<ins>**Impact on different segments**</ins> <br>
Overall, the business is experiencing a general decline across most customer groups and platforms, with the sharpest drops seen in the Asia and Oceania region, middle-aged customers, families, and existing customers.
While Europe Canada and Africa shows positive growth, the downward trends in key demographics and regions indicate a need for strategic efforts to retain customers and rebuild performance. <br>
<ins>**Suggestions to handle such future updates**</ins> <br>
Conduct Pilot Testing Before Full Rollout: <br>
Test new packaging changes on a small region or customer group first. <br>
Monitor customer reaction, sales trends, operational issues,Customer complaints/returns,Delivery efficiency and adjust before scaling.<br>
Inform customers before the change takes effect.<br>
Highlight benefits such as Environmental impact, improved quality, and smoother process.
Many customers respond favorably when they understand the purpose and impact.
  
