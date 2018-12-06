# Monthly Active User Analysis
Submitted by: Harry Siggins

This analysis was conducted to better understand the relationship between Monthly Active Users and churn from 01-01-2017 to 06-01-2017. This analysis required the use of SQL and one vizualization tool (details in Prerequisites below).

## Getting Started

**The repository consists of:**

- README.md - a full description of the analysis from setup to findings.
- MAU_SQL - the full set of SQL queries needed to explore and transform the original dataset, with commentary on specific queries.
- Dashboard Images - screenshots from the dashboard I created for vizualization. Access to this dashboard in an interactive setting is described below.

### Prerequisites and Tools

Below are the tools I used to conduct this analysis and a short description on why each tool was used:

- For data exploration and transformation, **DataGrip**. The tool is currently used within the Zapier organization and I have used it a handful of times before in prior analyses. The UI is clean and simple, and the integration into the data warehousing structure used for this analysis was fast.

- For vizualization, **AWS QuickSight**. Given the intergration with the data warehouse structure used in the analysis, the setup was quick and the vizualizations were manageable. Other tools required long setups with slow interfaces, while AWS QuickSight was simple and ready to use out of the box.

### Analysis

In this section I dive into 1) key parameters for the analysis, 2) how I explored and transformed the data and 3) analyzed and vizualized my findings. Further insights on my SQL queries can be found in the MAU_SQL file, and the interactive dashboard access is listed below.

#### Part 1: Key Parameters and Assumptions

**Below are some key parameters to know:**

1. A user is considered active on any day where they have at least one task executed in the prior 28 days.
2. A user is considered to be churn the 28 days following their last being considered active. After that point, they are considered to be churn.
3. A user is no longer part of churn if they become active again.
4. The data provided shows each day in which a task was executed by a certain user in the format below.

<table>
  <tr>
    <th>date</th>
    <th>tasks_used_per_day</th>
    <th>user_id</th>
    <th>account_id</th>
  </tr>
  <tr>
    <td>Date</td>
    <td># of tasks used that day</td>
    <td>The ID of the user which relates to this event</td>
    <td>The ID of the billing account</td>
  </tr>
</table>

**Key assumptions that were made:**

1. Records were removed in which the number of tasks on that record was 0, per parameter 1.
2. Some user_id's reflected more than one account_id, and some account_id's reflected more than one user_id. Given the analysis is looking at user_id's, records were aggregated on a user_id basis.

#### Part 2: Data Exploration and Transformation

Exploration and transformation was handled in DataGrip. Steps for this procedure are below and detailed query explanation is at MAU_SQL:

1. Create tasks_used_da_cleaned view to transfrom data based on key assumptions 1 and 2 above.
2. Segment users into monthly and weekly cohorts. This will provide structure on how user bases interacted with the product over time.
3. Identify how many new users were added on a daily basis. This can give us insights into how new users interactions are changing over time.
4. Transform table to show dates of the latest activity and following activity in the same row. This was done to show a date range for each user between each activity gap.
5. Identify the number of days between each record of activity. Given our definition of activity, this gives us a column to see exactly which time periods the user was active or churn.
5. For each activity gap, identify which are active, churn, or the last activity on record. If considered churn, calculate how many days within that activity gap would be considered churn.
6. For each churn activity gap, present a date range of when the user would be considered churn.
7. For each date in the study period, identify whether the user was active or churn on that day.
8. Finally, aggregate the active and churn counts to see how many users were active and churn on a given day.

All of this occured on the activity_detail view. This view was then aggregated to the activity_total_tracker view which shows totals of active, churn, and new users on a daily basis. Additionally, the month_cohort_breakdown and week_cohort_breakdown were created from activity_detail.

#### Part 3: Analysis and Visualization

At this stage, I connected the datawarehouse to AWS Quicksight and dove into two aspects of the analysis. First, I looked at the general trend of active and churn users over time. Second, I went one step further and looked at the activity of users by cohorts over time.






