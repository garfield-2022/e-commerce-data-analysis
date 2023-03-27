# 1. Monetization.

#Total revenue
select sum(total) as total_revenue
from orders;  

#Average revenue per customer
select round(1.0*sum(total)/count(distinct buyer_id),1)
  as revenue_per_customer
from orders;  

# Average order value (average amount a customer spends per order on your site)
select sum(total)/count(order_id) 
  as average_order_value
from orders;

# monthly revenue.
select  
  extract(year from created_at) as yy,
  extract(month from created_at) as mm,
  count(paid_at) as number_of_transaction,
  sum(total) as transaction_value
from orders
group by yy, mm
order by yy, mm;  

# Revenue by categories
select p.category, sum(total) as revenue
from products p inner join order_details od
  on p.product_id = od.product_id
  inner join orders o
  on od.order_id = o.order_id
group by 1
order by 2 desc;  
  
# Revenue by e-mail domains
select substring_index(u.email, '@', -1) as domain_name,
  sum(o.total) as revenue
from users u inner join orders o
  on u.kodepos = o.kodepos
group by 1
order by 2 desc


# 2. Users.

# Repeat customer rate (96.0%)
# (the percentage of customers who have purchased more than once in a specified time period)
with info_purchase as (
  select buyer_id, count(buyer_id) as purchase_time
  from orders
  group by 1 
  order by 2 desc
),
info_buyer as (
select count(buyer_id) as buyers_total, 
  sum(case when purchase_time > 1 then 1 else 0 end) as buyers_repeated
from info_purchase
)
select round(100.0*buyers_repeated/buyers_total,1) as repeat_customer_rate
from info_buyer

# monthly active users
select extract(year from created_at) as yy, 
  extract(month from created_at) as mm, 
  count(distinct buyer_id) as active_users
from orders
group by yy, mm
order by yy, mm;    

# Top 5 domains where buyers are from
select substring_index(u.email, '@', -1) as domain_name,
  count(o.buyer_id) as num_of_buyers
from users u inner join orders o
  on u.user_id = o.buyer_id
group by 1
order by 2 desc
limit 5;

# 3. Engagement

# Purchase frequency (4.2)
#(the average number of times a customer purchases from you in a set time period)
select round(1.0*count(order_id)/count(distinct buyer_id),1)
  as purchase_frequency
from orders;   

# Order abandonment rate 
# (percentage of customers who created orders but never purchase)

# creating new columns as order_status 
with info_orders as (
select *,
(case 
    when paid_at <> 'NA' and delivery_at <> 'NA' then 'Completed'
    when paid_at = 'NA' then 'Unpaid'
    when paid_at <> 'NA' and delivery_at = 'NA' then 'Paid & Undelivered'
    else 'None'
  end) as order_status  
from orders
),
stats_orders as (
select count(order_id) as num_total, 
  sum(case when order_status = 'Completed' then 1 else 0 end) as num_completed,
  sum(case when order_status = 'Unpaid' then 1 else 0 end) as num_unpaid,
  sum(case when order_status = 'Paid & Undelivered' then 1 else 0 end) 
    as num_paid_undelivered
from info_orders 
)
# 86.92% Completed, 6.74% Unpaid and 6.34% Paid&Undelivered
select round(100.0*num_completed/num_total,2) as percentage_completed,
  round(100.0*num_unpaid/num_total,2) as percentage_unpaid,
  round(100.0*num_paid_undelivered/num_total,2) as percentage_paid_undelivered
from stats_orders  
