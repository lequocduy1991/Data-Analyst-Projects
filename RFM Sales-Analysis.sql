-- Inspecting Data
select * from [dbo].[sales_data_sample]

-- Checking unique values
select distinct status from [dbo].[sales_data_sample]
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]
select distinct COUNTRY from [dbo].[sales_data_sample] -- 19 countries
select distinct DEALSIZE from [dbo].[sales_data_sample]
select distinct TERRITORY from [dbo].[sales_data_sample]

-- ANALYSIS
-- Let's start by grouping sales by productline 
select PRODUCTLINE, SUM(sales) Revenue from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, SUM(sales) Revenue from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

-- what was the best month for sales in a specific year? How much was earn that month?
select month_id,sum(sales) Revenue,count(ordernumber) Frequency
from dbo.sales_data_sample
where YEAR_ID = 2004 -- change year to see the rest
group by MONTH_ID
order by 2 desc

-- November seems to be the month, what product do they sell in November? Classice, i belive
select month_id, productline, sum(sales) Revenue,count(ordernumber) Frequency
from dbo.sales_data_sample
where year_id = 2004 and month_id = 11 -- change year to see the rest
group by month_id,productline
order by 3 desc

-- who is the best customer	(this could be best answered with RFM)

DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select
		customername,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ordernumber) Frequency,
		max(orderdate) last_order_date,
		(select max(orderdate) from dbo.sales_data_sample) max_order_date,
		datediff(dd,max(orderdate),(select max(orderdate) from dbo.sales_data_sample)) Recency
	from dbo.sales_data_sample
	group by customername
),
rfm_cal as
(
	select r.*,
		NTILE(4) over (order by Recency) rfm_recency,
		NTILE(4) over (order by Frequency) rfm_frequency,
		NTILE(4) over (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_cal c

select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monetary,
case 
	when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers'
	when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away, cannot lose'
	when rfm_cell_string in (311,411,331) then 'new customers'
	when rfm_cell_string in (222,223,233,322) then 'potential churners'
	when rfm_cell_string in (323,333,321,422,332,432) then 'active' -- customers who buy often & recently, but at low price points
	when rfm_cell_string in (433,434,443,444) then 'loyal'
end rfm_segment
from #rfm

--what products are most often sold together?
--select * from dbo.sales_data_sample where ordernumber = 10125
select distinct ordernumber,stuff( 
	(select ',' + PRODUCTCODE --(1)
	from dbo.sales_data_sample p
	where ordernumber in 
	(
		select ordernumber
		from (
		select ordernumber, count(*) rn
		from dbo.sales_data_sample 
		where status = 'Shipped'
		group by ordernumber
		)m
		where rn = 2
	)
	and p.ORDERNUMBER = s.ORDERNUMBER -- (3)
	for xml path('')),1,1,'') Productcodes -- (2)
from dbo.sales_data_sample s
order by 2 desc 

---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from dbo.sales_data_sample
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from dbo.sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc