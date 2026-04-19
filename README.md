Overview:
This project analyzes delivery operations data to identify the key factors that impact delivery time and overall efficiency.
The goal is to move beyond simple reporting and uncover actionable insights that can help improve logistics performance.
The project combines SQL for data preparation and Power BI for interactive visualization, following a real-world analytics workflow.

Tools & Technologies:
MySQL — data cleaning, transformation, and analysis
Power BI — dashboard creation and data visualization

Dashboard Features:
KPI Overview
Total Orders
Average Delivery Time
On-Time Delivery %
Average Agent Rating
Operational Analysis
Impact of Traffic on delivery time
Weather conditions and their effect on performance
Vehicle efficiency comparison
Performance Insights
Agent performance based on rating
Delivery performance across different areas
Interactivity
Dynamic filtering by Traffic, Weather, Vehicle, and Area

Key Insights:

Traffic Impact:
Traffic is the most significant factor affecting delivery performance.
Orders under “Jam” conditions show noticeably higher delivery times compared to low or medium traffic.

Weather Conditions:
Adverse weather such as storms and fog leads to longer delivery durations, indicating operational sensitivity to environmental factors.

Vehicle Efficiency:
Different vehicle types perform differently under varying conditions.
Certain vehicles show better efficiency, especially in high-traffic scenarios.

Agent Performance:
Higher-rated agents consistently achieve faster delivery times, suggesting a strong relationship between experience/performance and efficiency.

Area-Based Performance:
Delivery times vary by area, with semi-urban regions showing slower performance, possibly due to infrastructure or distance challenges.

Business Recommendations:
Optimize routing during peak traffic
Implement smarter route planning or time-based delivery scheduling to reduce delays.
Leverage high-performing agents strategically
Assign higher-rated agents to time-sensitive or high-priority deliveries.
Match vehicle type to delivery conditions
Use more efficient vehicles in congested or complex environments.
Improve operations in semi-urban areas
Investigate bottlenecks and adjust logistics strategies to reduce delays.
Prepare for weather disruptions
Introduce buffer times or contingency planning during extreme weather conditions.

Project Structure:
delivery-performance-dashboard.pbix → Power BI dashboard
SQL queries → Data cleaning and analysis


Key Takeaway:
This project demonstrates how combining SQL and Power BI can transform raw operational data into clear insights and actionable business decisions.

Sourse of data:
https://www.kaggle.com/datasets/sujalsuthar/amazon-delivery-dataset
