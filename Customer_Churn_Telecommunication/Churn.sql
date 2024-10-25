-- Lets see the data
select * from PortfolioProject..telecom_churn

--DATA CLEANING
-- Per the data dictionary, there are a few nulls that should be changed to different values. Lets fix those:
UPDATE PortfolioProject..telecom_churn SET [Avg Monthly Long Distance Charges] = 0 WHERE [Avg Monthly Long Distance Charges] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Internet Type] = 'None' WHERE [Internet Type] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Multiple Lines] = 'No' WHERE [Multiple Lines] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Avg Monthly GB Download] = '0' WHERE [Avg Monthly GB Download] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Online Security] = 'No' WHERE [Online Security] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Online Backup] = 'No' WHERE [Online Backup] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Device Protection Plan] = 'No' WHERE [Device Protection Plan] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Premium Tech Support] = 'No' WHERE [Premium Tech Support] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Streaming TV] = 'No' WHERE [Streaming TV] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Streaming Movies] = 'No' WHERE [Streaming Movies] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Streaming Music] = 'No' WHERE [Streaming Music] IS NULL
UPDATE PortfolioProject..telecom_churn SET [Unlimited Data] = 'No' WHERE [Unlimited Data] IS NULL
 
 -- Age is a Float, there are no decimals so lets change it to int
 Alter Table portfolioproject..telecom_churn
 Alter Column Age INT

 -- Number of dependents is a Float, there are no decimals needed so lets change it to int
 Alter Table portfolioproject..telecom_churn
 Alter Column [Number of Dependents] INT

  -- Zip Code is a Float, there are no decimals needed so lets change it to int
 Alter Table portfolioproject..telecom_churn
 Alter Column [Zip Code] INT

-- How many customers joined the company during the last quarter?
Select Count ([customer ID]) 
From portfolioproject..telecom_churn
Where [Customer Status] = 'Joined' and [Tenure in Months] < 3 -- (assuming 3 months in a quarter)

-- How many customers churned during the last quarter?
Select Count ([customer ID]) 
From portfolioproject..telecom_churn
Where [Customer Status] = 'Churned' and [Tenure in Months] < 3

-- What is the net $ retention of the customers this month?

SELECT Churned_Revenue
     , Non_Churned_Revenue 
     , Non_Churned_Revenue - Churned_Revenue AS Net_Retention
  FROM ( SELECT SUM(CASE WHEN [Customer Status] IN ('Joined','Stayed')
                         THEN [monthly charge] END) AS Non_Churned_Revenue 
              , SUM(CASE WHEN [Customer Status] = 'Churned' 
                         THEN [monthly charge] END) AS Churned_Revenue
           FROM portfolioproject..telecom_churn ) AS d


-- What percent of our customer base has churned?

SELECT Total_Customers
     , Churned_Customers 
     , 100.0 * Churned_Customers / Total_Customers AS Percent_Churned
  FROM ( SELECT COUNT(CASE WHEN [Customer Status] IN ('Joined','Stayed', 'Churned')
                         THEN [customer ID] END) AS Total_Customers
              , COUNT(CASE WHEN [Customer Status] = 'Churned' 
                         THEN [Customer ID] END) AS Churned_Customers
           FROM portfolioproject..telecom_churn ) AS d

-- Making a temp table of all churned customers so we can query off it and more about them and maybe find some patterns --
CREATE TABLE #Churned (
	Customer_ID nvarchar(255),
	Gender nvarchar(255),
	Age int,
	Married nvarchar(255),
	Number_Of_Dependents int,
	City nvarchar(255),
	Zip_Code int,
	Number_Of_Referrals float,
	Tenure_In_Months float,
	Offer nvarchar(255),
	Phone_Service nvarchar(255),
	Average_Monthly_Long_Distance_Charges float,
	Multiple_Lines nvarchar(255),
	Internet_Service nvarchar(255),
	Internet_Type nvarchar(255),
	Average_Monthly_GB_Download float,
	Premium_Tech_Support nvarchar(255),
	Streaming_TV nvarchar(255),
	Streaming_Music nvarchar(255),
	Streaming_Movies nvarchar(255),
	Unlimited_Data nvarchar(255),
	Contract_Length nvarchar(255),
	Paperless_Billing nvarchar(255),
	Payment_Method nvarchar(255),
	Monthly_Charge money,
	Total_Charges money,
	Total_Refunds money,
	Total_Extra_Data_Charges money,
	Total_Revenue money,
	Customer_Status nvarchar(255),
	Churn_Category nvarchar(255),
	Churn_Reason nvarchar(255),
	[Population] nvarchar (255)
	)


insert into #churned
Select [Customer ID], Gender, Age, Married, [Number of Dependents], City, a.[Zip Code], [Number of Referrals], [Tenure in Months], Offer, [Phone Service], [Avg Monthly Long Distance Charges], [Multiple Lines], [Internet Service], [Internet Type], [Avg Monthly GB Download], [Premium Tech Support], [Streaming TV], [Streaming Music], [Streaming Movies], [Unlimited Data], [Contract], [Paperless Billing], [Payment Method], [Monthly Charge], [Total Charges], [Total Refunds], [Total Extra Data Charges], [Total Revenue], [Customer Status], [Churn Category], [Churn Reason], [Population]
from PortfolioProject..telecom_churn as a
join PortfolioProject..zip_code_churn as b
on a.[Zip Code] = b.[Zip Code]
where [Customer Status] = 'Churned'


-- What is the average monthly charge for someone who churned?
select avg(monthly_charge) as AVG_CHURN_MONTHLY_FEE
from #Churned

-- What is the breakdown for churn category? how many churned customers fall into each category

select count(customer_id) as Number_Of_Customers_Lost, Churn_Category
from #churned
group by Churn_Category

-- What is the amount of revenue lost by each of these categories? Which one might be most important to address
select count(customer_id) as Number_Of_Customers_Lost, Churn_Category, sum(monthly_charge) as money_lost
from #churned
group by Churn_Category
order by money_lost desc

-- Which of our marketing offers (A, B, C, D, E) was least successful in keeping customers?
select count(customer_id) as Number_Of_Customers_Lost, Offer
from #churned
group by offer
order by Number_Of_Customers_Lost desc
-- it looks like offers E and D were the least successful. these customers were given an offer, but didn't stay. Customers who didn't recieve an offer were more likely to churn. Maybe more marketing offers similar to A will help!

-- this data might be biased because it doesn't take into account how many people were offered each offer. Lets find the rate at which each offer resulted in churn:

select offer, sum(case when [Customer Status] = 'Churned' then 1.0 else 0 end)/count([Customer ID]) as Churn_Rate from PortfolioProject..telecom_churn
group by offer
order by offer desc

-- E is clearly the worst marketing offer we have. A is really good.


-- When people churn, when do they typically leave?
select count(customer_id) as Number_Of_Customers_Lost, Tenure_in_Months
from #Churned
group by Tenure_In_Months
order by Number_Of_Customers_Lost desc
-- it looks like we have a really hard time keeping customers after 1 month. 

-- Which one of our services needs a little more polish? (how many people churn after using each service)
select count(customer_id) as Number_Of_Customers_Lost, Streaming_Movies, Streaming_Music, Streaming_TV
from #Churned
group by Streaming_Movies, Streaming_Music, Streaming_TV
order by Number_Of_Customers_Lost desc
-- the majority of people who churn dont stream movies, music, or tv. We should maybe focus our efforts on adding free month long trials of these things. especially if people are most likely to leave in month 1,2

-- lets see how the amount of dependents affects churn. should we try a family plan?
select count(customer_id) as Number_Of_Customers_Lost, Number_Of_Dependents
from #Churned
group by Number_Of_Dependents
order by Number_Of_Customers_Lost desc
-- another interesting find. most people who churn do not have any dependents. maybe young adults? lets find out!
select count(customer_id) as Number_Of_Customers_Lost, Age
from #Churned
group by Age
order by Number_Of_Customers_Lost desc
-- I was wrong. Looks to be pretty spread out amongst adults.

-- Lets build a profile of the most 'At Risk' customers
select count(customer_id) as Number_Of_Customers_Lost, Married, Age
from #Churned
group by Married, Age
order by Number_Of_Customers_Lost desc
-- it looks like our most at-risk demographic is unmarried 30-70 year olds.

-- What are the most common churn reasons?

select count(customer_id) as Number_Of_Customers_Lost, Churn_Reason
from #Churned
group by Churn_Reason
order by Number_Of_Customers_Lost desc
-- Looks like our competitor is kicking our a** and our support team needs training on how to handle customers

-- Lets see the average monthly payment for someone who doesnt churn vs someone who does

select avg([monthly charge]) as Avg_Monthly_Price, [Customer Status]
from PortfolioProject..telecom_churn
group by [Customer Status]

-- maybe charging people over 70$ is too much

-- are certain payment methods suceptible to churning?
select count([Customer ID]) as Number_Of_Customers_Lost, [Payment Method], [Customer Status]
from PortfolioProject..telecom_churn
group by [Customer Status], [Payment Method]
order by [Customer Status]
 -- a lot more people stayed when they used credit cards




-- Finally, lets see where geographically our churn is located. Is there more churn in highly populated areas or rural areas. Maybe we need to get a stronger signal somewhere or focus our marketing efforts.

select * 
from PortfolioProject..telecom_churn
inner join PortfolioProject..zip_code_churn
on telecom_churn.[zip code] = zip_code_churn.[Zip Code]

-- Lets join it onto our temp table of churn and see where the churn is located
select * from #Churned
join PortfolioProject..zip_code_churn
on #Churned.Zip_Code = zip_code_churn.[Zip Code]



select count(customer_id) as Number_Of_Customers_Lost, Zip_Code
from #Churned
group by Zip_Code
order by Number_Of_Customers_Lost desc

















	














