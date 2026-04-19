Overview

This project analyzes delivery operations data to identify the key factors affecting delivery time and overall efficiency.
The objective is to move beyond basic reporting and uncover actionable insights that can support better decision-making in logistics operations.
The project follows a real-world workflow by combining data cleaning and analysis in MySQL with interactive dashboarding in Power BI.

Tools & Technologies:
MySQL — data cleaning, transformation, and analysis
Power BI — dashboard creation and visualization

Dashboard Features:
KPI Overview:
Total Orders
Average Delivery Time
On-Time Delivery %
Average Agent Rating

Operational Analysis:
Impact of Traffic on delivery time
Weather conditions and their effect on performance
Vehicle efficiency comparison

Performance Insights:
Agent performance based on rating
Delivery performance across different areas

Interactivity:
Dynamic filtering by:
Traffic
Weather
Vehicle
Area

SQL Data Preparation & Analysis:
The dataset was cleaned and explored using MySQL before being visualized in Power BI.

Data Cleaning:
Adjusted column data types for consistency (numeric, text, time)
Replaced invalid 'NaN' values with NULL
Converted time-related fields into proper TIME format

Analytical Queries:
SQL was used to explore relationships between key variables and delivery performance:

Traffic vs Average Delivery Time
Vehicle Type vs Delivery Efficiency
Weather Conditions vs Delivery Time
Agent Rating vs Delivery Performance

Example Query:
SELECT
    traffic,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS avg_delivery_time
FROM deliveries
GROUP BY traffic
ORDER BY avg_delivery_time DESC;

Full SQL script available in:
Delivery-Performance-Logistics-Analysis/delivery_analysis_mysql.sql

Key Insights:

Traffic Impact:
Traffic congestion is the most influential factor affecting delivery time.
Orders under “Jam” conditions take significantly longer compared to low or medium traffic scenarios.

Weather Conditions:
Adverse weather (e.g., storms, fog) increases delivery duration, indicating that operations are sensitive to environmental conditions.

Vehicle Efficiency:
Vehicle type plays a role in performance, with some vehicles handling high-traffic conditions more efficiently than others.

Agent Performance:
Higher-rated agents consistently achieve faster and more reliable deliveries, showing a clear link between performance and efficiency.

Area-Based Performance:
Delivery times vary by area, with semi-urban regions experiencing longer delays, possibly due to infrastructure or distance factors.

Business Recommendations:
Optimize routing during peak traffic
Implement smarter route planning or time-based delivery scheduling
Leverage high-performing agents
Assign top-rated agents to time-sensitive deliveries
Use vehicle types strategically
Match vehicles to delivery conditions and traffic levels
Improve operations in semi-urban areas
Identify bottlenecks and enhance logistics planning
Prepare for weather disruptions
Introduce buffer times and contingency strategies

Key Takeaway
This project demonstrates how combining SQL and Power BI can transform raw operational data into clear insights and actionable business decisions.
It reflects a complete analytics workflow — from data preparation to insight generation and business recommendation.

Sourse of data: https://www.kaggle.com/datasets/sujalsuthar/amazon-delivery-dataset
