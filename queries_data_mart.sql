use data_mart;

			-- Data cleaning steps
select * from weekly_sales 
limit 10;


drop table if exists clean_weekly_sales;

create table clean_weekly_sales as
select 
str_to_date(week_date,'%d-%m-%y') as week_date ,
week(str_to_date(week_date,'%d-%m-%y')) as week_number,
month(str_to_date(week_date,'%d-%m-%y')) as month_number,
year(str_to_date(week_date,'%d-%m-%y')) as calendar_year,
region,
platform,
ifnull(segment, 'UNKNOWN') as segment,
ifnull(case when segment like '%1' then 'Young Adults'
	when segment like '%2' then 'Middle Aged'
	when segment like '%3' or segment like '%4' then 'Retirees' end , 'UNKNOWN') as age_band,
ifnull(case when segment like 'C%' then 'Couples'
	when segment like 'F%' then 'Families' end, 'UNKNOWN') as demographic,
customer_type,
transactions,
sales,
round(sales/transactions,2) as avg_transaction
from weekly_sales;

select * from clean_weekly_sales limit 10;

				-- Data Exploration

-- What day of the week is used for each week_date value?
select week_date, dayofweek(week_date) as day from clean_weekly_sales
group by week_date;


-- What range of week numbers are missing from the dataset?
select calendar_year,week_number
from clean_weekly_sales
group by calendar_year,week_number ;

-- How many total transactions were there for each year in the dataset?
select calendar_year , count(transactions)
from clean_weekly_sales
group by calendar_year;

-- What is the total sales for each region for each month?
select month_number , region, sum(sales) total_sales
from clean_weekly_sales
group by region, month_number ;

-- What is the total count of transactions for each platform
select platform , count(*)  as total_count
from clean_weekly_sales 
group by platform;

-- What is the percentage of sales for Retail vs Shopify for each month?
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
 
 -- What is the percentage of sales by demographic for each year in the dataset?
 with cte as (
 select calendar_year,sum(sales) as y_sales
 from clean_weekly_sales
 group by calendar_year )
 
 select cte.calendar_year,cws.demographic, 
		sum(cws.sales)*100/cte.y_sales as percentage
    from clean_weekly_sales cws
    join cte on cte.calendar_year = cws.calendar_year
    group by cws.demographic,cws.calendar_year
    order by calendar_year ,percentage desc ;
 
 -- Which age_band and demographic values contribute the most to Retail sales?
 select age_band,demographic ,sum(sales)
 from clean_weekly_sales
 where platform = 'Retail' 
 group by age_band,demographic
 order by sum(sales) desc;
 
 -- Can we use the avg_transaction column to find the average 
 -- transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
 
select calendar_year,platform, sum(sales)/sum(transactions)
from clean_weekly_sales
group by calendar_year,platform
order by calendar_year;

					-- Before and After Analysis
-- What is the total sales for the 4 weeks before and after 2020-06-15? 
-- What is the growth or reduction rate in actual values and percentage of sales?
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
,round((sales_after-sales_before) * 100/sales_before,2) growth_percentage
from cte1,cte2;

-- What about the entire 12 weeks before and after?
with cte1 as (
select sum(sales) as sales_before
from clean_weekly_sales
where week_date >= date_sub('2020-06-15', interval 12 week) and week_date <'2020-06-15'
)
, cte2 as (
select sum(sales) as sales_after
from clean_weekly_sales
where week_date < date_add('2020-06-15', interval 12 week) and week_date >='2020-06-15'
)
select sales_before,sales_after
,sales_after-sales_before as change_in_sales
,round((sales_after-sales_before) * 100/sales_before,2) growth_percentage
from cte1,cte2;

-- How do the sale metrics before and after compare with the previous years

with cte1 as (
select sum(sales) as sales_before
from clean_weekly_sales
where week_date >= date_sub('2019-06-15', interval 4 week) and week_date <'2019-06-15'
)
, cte2 as (
select sum(sales) as sales_after
from clean_weekly_sales
where week_date < date_add('2019-06-15', interval 4 week) and week_date >='2019-06-15'
)
select sales_before,sales_after
,sales_after-sales_before as change_in_sales
,round((sales_after-sales_before) * 100/sales_before,2) growth_percentage
from cte1,cte2;

-- percentage impact on age_band
with cte1 as (
select region,sum(sales) as sales_before
from clean_weekly_sales
where week_date >= date_sub('2020-06-15', interval 4 week) and week_date <'2020-06-15'
group by region
)
, cte2 as (
select region, sum(sales) as sales_after
from clean_weekly_sales
where week_date < date_add('2020-06-15', interval 4 week) and week_date >='2020-06-15'
group by region
)
select cte1.region,sales_before,sales_after
,sales_after-sales_before as change_in_sales
,round((sales_after-sales_before) * 100/sales_before,2) growth_percentage
from cte1 join cte2 on cte2.region = cte1.region
group by cte1.region
order by cte1.region;