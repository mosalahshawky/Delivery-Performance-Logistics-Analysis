Create Database amazon_delivery;
USE amazon_delivery;

-- alter the type of data --
alter table deliveries
modify order_ID varchar(50),
modify Agent_Age int,
modify Agent_rating float,
modify Store_Latitude float,
MODIFY store_longitude FLOAT,
MODIFY drop_latitude FLOAT,
MODIFY drop_longitude FLOAT,
MODIFY order_date VARCHAR(20),
MODIFY order_time VARCHAR(20),
MODIFY pickup_time VARCHAR(20),
MODIFY weather VARCHAR(50),
MODIFY traffic VARCHAR(50),
MODIFY vehicle VARCHAR(50),
MODIFY area VARCHAR(50),
MODIFY delivery_time INT,
MODIFY category VARCHAR(50);

-- as some fields have 'NaN' as a text we need to clean it --
update deliveries
set Order_time = null
where order_time = 'NaN ';
update deliveries
set weather = null
where weather = 'NaN';
update deliveries
set traffic = null
where traffic = 'NaN ';

-- Convert back time fields --
alter table deliveries
modify order_time time,
MODIFY pickup_time time;

-- finding the relation between Traffic and Average delivery time --
select
	traffic,
    count(*) as total_orders,
    round(avg(delivery_time), 2) as avg_delivery_time
from deliveries
group by traffic
order by avg_delivery_time desc;

-- finding the relation between Vehicle type and amount of orderes and average delivery time --
select
	vehicle,
    count(*) as total_orders,
    round(avg(delivery_time), 2) as avg_delivery_time
from deliveries
group by vehicle
order by avg_delivery_time desc;
-- finding the relation between weather condidion and average delivery time --
select weather,
	count(*) as total_orders,
    round(avg(delivery_time), 2) as avg_delivery_time
from deliveries
group by weather
order by avg_delivery_time desc;

-- finding the relation between agent rating and average delivery time --
select Agent_rating,
	count(*) as total_orders,
    round(avg(delivery_time), 2) as avg_delivery_time
from deliveries
group by agent_rating
order by agent_rating desc;

