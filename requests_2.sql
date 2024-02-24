create table customers (
  customer_id varchar primary key,
  first_name varchar,
  last_name varchar,
  gender varchar,
  DOB varchar,
  job_title varchar,
  job_industry_category varchar,
  wealth_segment varchar,
  deceased_indicator varchar,
  owns_car varchar,
  address varchar,
  postcode varchar,
  state varchar,
  country varchar,
  property_valuation int8
);

create table transactions (
  transaction_id varchar primary key,
  product_id varchar,
  customer_id varchar,
  transaction_date varchar,
  online_order varchar,
  order_status varchar,
  brand varchar,
  product_line varchar,
  product_class varchar,
  product_size varchar,
  list_price float,
  standard_cost float
);

--N1
select job_industry_category, count(*) as amount
from customers
group by job_industry_category
order by amount desc;

--N2
select extract(month from transaction_date::date) as month_num, job_industry_category, sum(list_price) as total
from transactions
left join (select customer_id, job_industry_category
		   from customers) as job_categories on transactions.customer_id = job_categories.customer_id
group by month_num, job_industry_category
order by month_num, job_industry_category;

--N3
select brand, count(*) as amount
from transactions
where customer_id in (select customer_id
					  from customers
					  where job_industry_category = 'IT') and order_status = 'Approved'
group by brand
order by amount desc;

--N4.1
select customer_id,
	   sum(list_price) as total,
	   max(list_price) as max_price,
	   min(list_price) as min_price,
	   count(list_price) as amount
from transactions
group by customer_id
order by total desc, amount desc;

--N4.2
select customer_id,
	   sum(list_price) over(partition by customer_id) as total,
	   max(list_price) over(partition by customer_id) as max_price,
	   min(list_price) over(partition by customer_id) as min_price,
	   count(list_price) over(partition by customer_id) as amount
from transactions
order by total desc, amount desc;

--N5
with total_price as (select customer_id, sum(list_price) as tp
					 from transactions
					 group by customer_id),
	 customers_max_total_price as (select customer_id
	 							   from total_price
	 							   where tp = (select max(tp) from total_price)),
	 customers_min_total_price as (select customer_id
	 							   from total_price
	 							   where tp = (select min(tp) from total_price))

select customer_id, first_name, last_name
from customers
where customer_id in (select * from customers_max_total_price) or customer_id in (select * from customers_min_total_price);

--N6
with first_dates as (select transaction_id,
							transaction_date::date,
							first_value(transaction_date::date) over(partition by customer_id order by transaction_date::date) as first_date
					 from transactions)

select *
from transactions
where transaction_id in (select transaction_id
						 from first_dates
						 where transaction_date = first_date);

--N7
with lag_dates as (select customer_id,
						  transaction_id,
						  transaction_date::date,
						  lag(transaction_date::date) over(partition by customer_id order by transaction_date::date) as lag_date
				   from transactions),
	 duration as (select customer_id, transaction_date - lag_date as duration_days
	 			  from lag_dates),
	 max_duration as (select customer_id, max(duration_days) as max_duration_days
	 				  from duration
	 				  group by customer_id)

select customer_id, first_name, last_name, job_title, job_industry_category
from customers
where customer_id in (select customer_id
					  from max_duration
					  where max_duration_days = (select max(max_duration_days)
					  							 from max_duration));