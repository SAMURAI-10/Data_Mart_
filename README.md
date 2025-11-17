# Data Analysis of a Mart's Data

## Intoduction
A Client's company, "Data Mart," is an online supermarket selling fresh produce, and he needs help analyzing its sales performance after a major change was made in June 2020. This change involved switching to sustainable packaging for all products, and client wants to understand how this decision affected his business, looking at sales performance across different areas and deciding how to handle future updates to avoid disrupting sales. 

## Objective
The key business question client wanted me to help him answer were:

- What was the quantifiable impact of the changes introduced in June 2020?
- Which platform, region, segment and customer types were the most impacted by this change?
- What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?

### Schema
For this case study there is only a single table: **data_mart.weekly_sales**.
The Entity Relationship Diagram is shown below with the data types made clear.


The columns are pretty self-explanatory based on the column names but here are some further details about the dataset:


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

### What is the total sales for the 4 weeks before and after 2020-06-15? 
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
