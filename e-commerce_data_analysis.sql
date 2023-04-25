# monthly revenue.
select  
  extract(year from created_at) as yy,
  extract(month from created_at) as mm,
  count(paid_at) as number_of_transaction,
  sum(total) as transaction_value
from orders
group by yy, mm
order by yy, mm;  

  
# Revenue by e-mail domains top 3
# gmail.com, yahoo.com, hotmail.com
select substring_index(u.email, '@', -1) as domain_name,
  sum(o.total) as revenue
from users u inner join orders o
  on u.kodepos = o.kodepos
group by 1
order by 2 desc
limit 3;


# revenue from those three domains make up about 1/3 of total revenue.
# 33.7%
with revenue_top_3 as (
select substring_index(u.email, '@', -1) as domain_name,
  sum(o.total) as revenue
from users u inner join orders o
  on u.kodepos = o.kodepos
group by 1
order by 2 desc
limit 3)
select round(100*sum(revenue)/(select sum(total) from orders),1)
from revenue_top_3


# monthly active users
select extract(year from created_at) as yy, 
  extract(month from created_at) as mm, 
  count(distinct buyer_id) as active_users
from orders
group by yy, mm
order by yy, mm;    


# Top 3 domains where buyers are from
# gmail.com, yahoo.com, hotmail.com
select substring_index(u.email, '@', -1) as domain_name,
  count(o.buyer_id) as num_of_buyers
from users u inner join orders o
  on u.user_id = o.buyer_id
group by 1
order by 2 desc
limit 3;


# buyers from top 3 domains make up about half of total buyers
# 50.1%
with buyers_top_3 as (
select substring_index(u.email, '@', -1) as domain_name,
  count(o.buyer_id) as num_of_buyers
from users u inner join orders o
  on u.user_id = o.buyer_id
group by 1
order by 2 desc
limit 3
)
select round(100*sum(num_of_buyers)/(select count(buyer_id) from orders),1)
from buyers_top_3


# Order complete rate 
# (percentage of customers who created orders but never purchase)
# creating new columns as order_status 
with orders_info as (
select *,
(case 
    when paid_at <> 'NA' and delivery_at <> 'NA' then 'Completed'
    when paid_at = 'NA' then 'Unpaid'
    when paid_at <> 'NA' and delivery_at = 'NA' then 'Paid & Undelivered'
    else 'None'
  end) as order_status  
from orders
),
# 86.92% Completed, 6.74% Unpaid and 6.34% Paid&Undelivered
orders_completion_rate as (
select  
  round(100.0*sum(case when order_status = 'Completed' then 1 else 0 end)/count(order_id),2)
  as completed,
  round(100.0*sum(case when order_status = 'Unpaid' then 1 else 0 end)/count(order_id),2)
  as unpaid,
  round(100.0*sum(case when order_status = 'Paid & Undelivered' then 1 else 0 end)/count(order_id),2)
  as paid_undelivered
from orders_info 
)
select distinct order_status,
  (case when order_status = 'Completed' then (select completed from orders_completion_rate) 
        when order_status = 'Unpaid' then (select unpaid from orders_completion_rate)
        when order_status = 'Paid & Undelivered' then (select paid_undelivered from orders_completion_rate)
   end) as order_percentage
from orders_info)
