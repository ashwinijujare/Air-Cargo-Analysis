create database aircargo;
use aircargo;

CREATE TABLE customer (
  customer_id int,
  first_name varchar(100) NOT NULL,
  last_name varchar(100) DEFAULT NULL,
  date_of_birth date NOT NULL,
  gender varchar(1) NOT NULL,
  PRIMARY KEY (customer_id)
);

CREATE TABLE routes (
  route_id int NOT NULL,
  flight_num int NOT NULL,
  origin_airport varchar(3) NOT NULL,
  destination_airport varchar(100) NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  distance_miles int NOT NULL,
  PRIMARY KEY (route_id),
  CONSTRAINT Flight_number_check CHECK ((substr(flight_num,1,2) = 11)),
  CONSTRAINT routes_chk_1 CHECK ((distance_miles > 0))
);

CREATE TABLE passenger_of_flights (
  customer_id int NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  route_id int NOT NULL,
  depart varchar(3) NOT NULL,
  arrival varchar(3) NOT NULL,
  seat_num varchar(10) DEFAULT NULL,
  class_id varchar(100) DEFAULT NULL,
  travel_date date DEFAULT NULL,
  flight_num int NOT NULL,
  KEY customer_id (customer_id),
  KEY route (route_id),
  CONSTRAINT customer_fk_1 FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
  CONSTRAINT route_fk_2 FOREIGN KEY (route_id) REFERENCES routes (route_id) 
);

CREATE TABLE ticket_details (
  p_date date NOT NULL,
  customer_id int NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  class_id varchar(100) DEFAULT NULL,
  no_of_tickets int DEFAULT NULL,
  a_code varchar(3) DEFAULT NULL,
  Price_per_ticket int DEFAULT NULL,
  brand varchar(100) DEFAULT NULL,
  KEY customer_id (customer_id),
  CONSTRAINT ticket_details_fk_1 FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
  CONSTRAINT ticket_details_fk_2 FOREIGN KEY (customer_id) REFERENCES passenger_of_flights (customer_id)
);

#customer table has date column and does not use valid format in all rows causing importing issue
#check the local infile is ON, if is OFF then set to ON
#handling - Error Code: 3948. Loading local data is disabled; this must be enabled on both the client and server sides
SHOW VARIABLES LIKE "local_infile";
SET GLOBAL local_infile = 'ON';
#Error Code: 2068. LOAD DATA LOCAL INFILE file request rejected due to restrictions on access. ---- version 8.0 does not allow LOCAL anymore

#check the path that allows to load files & copy your csv t o this path to load it into table
SHOW VARIABLES LIKE "secure_file_priv";
#to allow valid dates - handling - Error Code: 1411. Incorrect datetime value: '12/1/1989' for function str_to_date
SET @@SESSION.sql_mode='ALLOW_INVALID_DATES';

#use below to load data manually with desired date format
delete from passenger_of_flights where travel_date = null;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer.csv'  
INTO TABLE `customer` 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, first_name, last_name,@date_of_birth, gender)
SET `date_of_birth` = STR_TO_DATE(@date_of_birth,  '%m/%d/%Y');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/passengers_on_flights.csv'  
INTO TABLE `passenger_of_flights` 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, aircraft_id, route_id, depart, arrival, seat_num, class_id, @travel_date, flight_num)
SET `travel_date` = STR_TO_DATE(@travel_date,  '%m/%d/%Y');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ticket_details.csv'  
INTO TABLE `ticket_details` 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@p_date, customer_id, aircraft_id, class_id, no_of_tickets, a_code, Price_per_ticket,  brand)
SET `p_date` = STR_TO_DATE(@p_date,  '%m/%d/%Y');

#Q1. Create an ER diagram for the given airlines database.
#Steps -- from Menu -> Database -> Reverse Engineer -> provide required password -> select database (airCargo) -> Click Next, Next -> Execute

#Q2. Write a query to create route_details table using suitable data types for the fields, such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles. 
# Implement the check constraint for the flight number and unique constraint for the route_id fields. 
#Also, make sure that the distance miles field is greater than 0 ---> already created above.

#Q3. Write a query to display all the passengers (customers) who have travelled in routes 01 to 25. Take data  from the passengers_on_flights table.
Select p.customer_id, concat(c.first_name, ' ', c.last_name) as Name, p.route_id
from passenger_of_flights p inner join customer c on p.customer_id = c.customer_id
where p.route_id between 01 and 25
order by p.route_id;

#Q4. Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.
select if(grouping (class_id), 'Total', class_id) as Class, 
count(*) as Total_No_of_Passengers, sum(no_of_tickets*price_per_ticket) as Total_Revenue
from ticket_details
group by class_id with rollup
having class_id = 'Bussiness';

#Q5. Write a query to display the full name of the customer by extracting the first name and last name from the customer table.
Select concat(first_name, ' ', last_name) as Full_Name
from customer;

#Q6. Write a query to extract the customers who have registered and booked a ticket. Use data from the customer and ticket_details tables.
Select distinct t.customer_id, concat(c.first_name, ' ',c.last_name) as Customer
from ticket_details t left join customer c on t.customer_id = c.customer_id
order by t.customer_id;

#Q7. Write a query to identify the customer’s first name and last name based on their customer ID and brand (Emirates) from the ticket_details table.
Select distinct concat(c.first_name, ' ' ,c.last_name) as Customer_name, t.brand
from ticket_details t join customer c on t.customer_id = c.customer_id
where t.brand = 'Emirates\r';

#Q8. Write a query to identify the customers who have travelled by Economy Plus class using Group By and Having clause on the passengers_on_flights table.
Select c.first_name, p.class_id
from customer c join passenger_of_flights p
on c.customer_id = p.customer_id
group by c.first_name,  p.class_id
having p.class_id = "Economy Plus";

#Q9. Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.
Select sum(Price_per_ticket) as Revenue ,if(sum(Price_per_ticket) > 10000, 'Revenue crossed 10000', 'Revenue below 10000') as CrossedTenThousand
from ticket_details;

#Q10. Write a query to create and grant access to a new user to perform operations on a database.
GRANT
ALL ON *.* TO 'root'@'localhost';

#Q11. Write a query to find the maximum ticket price for each class using window functions on the ticket_details table.
Select distinct class_id, max(Price_per_ticket) over (partition by class_id) as Max_ticket_price
from ticket_details;

#Q12. Write a query to extract the passengers whose route ID is 4 by improving the speed and performance of the passengers_on_flights table.
Create index routeIndex on passenger_of_flights (route_id);
Select customer_id, route_id from passenger_of_flights where route_id = 4;

#Q13. For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.
Explain Analyze
Select customer_id, route_id from passenger_of_flights where route_id = 4;

#Q14. Write a query to calculate the total price of all tickets booked by a customer across different aircraft IDs using rollup function.
Select if(grouping(p.customer_id), 'Total', p.customer_id) as customerId, sum(t.Price_per_ticket) as Total_Price 
from passenger_of_flights p join ticket_details t 
on p.customer_id = t.customer_id
group by p.customer_id with rollup;

#Q15. Write a query to create a view with only business class customers along with the brand of airlines.
Create view business_class_details as
Select distinct c.customer_id, concat(c.first_name, ' ',c.last_name) as Customer, t.brand, t.class_id
from customer c join ticket_details t
on c.customer_id = t.customer_id
where t.class_id = 'Bussiness';
Select * from business_class_details order by customer_id;

#Q16. Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist.
 Delimiter //
 Create procedure passenger_details (Min_route int, Max_route int)
 Begin
 Select * from passenger_of_flights
 where route_id between Min_route and Max_route;
 End //
 Delimiter ;
call passenger_details(1,4);

#Q17. Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.
Delimiter //
 Create procedure travelled_distance (dist int)
 Begin
 Select * from routes
 where distance_miles > dist;
 End //
 Delimiter ;
call travelled_distance(2000);

#Q18. Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500.
Delimiter //
Create procedure flight_travelled_distance (flight_no int, out info varchar(100))
 Begin
 declare dist int;
 Select distance_miles into dist from routes
 where flight_num = flight_no;
 if dist >= 0 and dist <= 2000 then set info = 'short distance travel';
 elseif dist > 2000 and dist <= 6500 then set info = 'intermediate distance travel';
 elseif dist > 6500 then set info = 'long-distance travel';
 end if;
 End //
Delimiter ;
call flight_travelled_distance(1111, @information);
Select @information as status;

#Q19. Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class using a stored function in stored procedure on the ticket_details table.
#Condition: If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No
Delimiter //
Create function complimentary_services(class varchar(100)) Returns varchar(3) deterministic
Begin
Declare comp_Services varchar(3);
 if class = 'Bussiness' or class = 'Economy Plus' then set comp_Services = 'Yes';
 else set comp_Services = 'No';
 End if;
 Return comp_Services;
End //
Delimiter ;
 
Select customer_id, p_date, class_id, complimentary_services(class_id) as Complimentary_services
from ticket_details
order by customer_id;

#Q20. Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.
Drop table if exists Scott_customers;
Create temporary table Scott_customers (
customerid int not null, firstname varchar(100), lastname varchar(100), dateofbirth date, gender varchar(1));  

Delimiter //
Create procedure Get_customer ()
 Begin
 declare done int default 0;
 declare customerid int;
 declare firstname, lastname varchar(100);
 declare dateofbirth date;
 declare gender varchar(1);
 declare get_cust Cursor for Select distinct * from customer where last_name like '%Scott';
 declare continue handler for not found set done = 1;
 open get_cust;
 label: loop
 Fetch get_cust into customerid, firstname, lastname, dateofbirth, gender;
 Insert into Scott_customers values(customerid, firstname, lastname, dateofbirth, gender);
 If done = 1 then leave label;
 end if;
 end loop;
 close get_cust;
 End //
Delimiter ;

call Get_customer;
Select * from Scott_customers