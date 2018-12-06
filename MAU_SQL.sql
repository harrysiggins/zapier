
--Based on assumptions of activity and users, remove records with 0 tasks and aggregate users from source data--

CREATE VIEW tasks_used_da_cleaned AS
SELECT date,
       user_id,
       sum(sum_tasks_used) as sum_tasks_used
FROM source_data.tasks_used_da
GROUP BY date, user_id
HAVING sum(sum_tasks_used) > 0
ORDER BY user_id;

--Create list of every date in the study period--

CREATE VIEW cal_dt AS
SELECT distinct(date) as date
FROM tasks_used_da_cleaned
ORDER BY date;

--For each day, identify new users that have been added--

CREATE VIEW new_users_daily AS
SELECT start_date, count(user_id)
FROM (SELECT min(date) AS start_date, user_id
      FROM tasks_used_da_cleaned
      GROUP BY user_id
      ORDER BY start_date, user_id) t1
GROUP BY start_date
ORDER BY start_date;

-- Segment user list into cohorts. In this project, this will be the month at which they first became active--

CREATE VIEW cohorts AS
SELECT user_id,
       EXTRACT(MONTH FROM min(date)) as month_cohort,
       CASE
         WHEN EXTRACT(WEEK FROM min(date)) = 52 AND EXTRACT(MONTH FROM min(date)) = 1 THEN 1
         ELSE EXTRACT(WEEK FROM min(date))
         END AS week_cohort,
       min(date) AS day_cohort
FROM tasks_used_da_cleaned
GROUP BY user_id
ORDER BY user_id, month_cohort, week_cohort, day_cohort;

-- From the cleaned table, find the dates in which they have a record and what cohort they are part of--

CREATE VIEW user_log AS
SELECT t1.user_id AS user_id,
       t1.date AS date,
       t2.month_cohort AS month_cohort,
       t2.week_cohort AS week_cohort,
       t2.day_cohort AS day_cohort
FROM tasks_used_da_cleaned t1
       JOIN cohorts t2
            ON t1.user_id = t2.user_id
GROUP BY t1.user_id, t1.date, t2.month_cohort, t2.week_cohort,t2.day_cohort
ORDER BY t1.user_id, t1.date;


-- From each date where record is placed, create column showing following date in which a record is placed --

CREATE VIEW lead_date AS
SELECT user_id,
       month_cohort,
       week_cohort,
       day_cohort,
       date AS activity,
       lead(date, 1) OVER (PARTITION BY user_id ORDER BY user_id, date) AS next_activity
FROM user_log
ORDER BY user_id;

--Find delta in days between recorded activity--

CREATE VIEW activity_delta AS
SELECT user_id,
       month_cohort,
       week_cohort,
       day_cohort,
       activity,
       next_activity,
       next_activity - activity AS activity_delta
FROM lead_date
ORDER BY user_id;

-- Based on that delta, use the parameters of churn and activity to understand over a given period if the user has churned--
--Additionally, for a given period, what exact date ranges is the user considered to be active and churned--

CREATE VIEW activity_detail AS
SELECT user_id,
       month_cohort,
       week_cohort,
       day_cohort,
       activity,
       next_activity,
       activity_delta,
       CASE
         WHEN activity_delta <= 28 THEN 'Active'
         WHEN activity_delta > 28 THEN 'Churn'
         WHEN activity_delta IS NULL THEN 'EOL'
         END AS type,
       activity AS active_from,
       CASE
         WHEN type = 'Active' THEN next_activity
         WHEN type = 'Churn' THEN activity + 27
         WHEN type = 'EOL' THEN activity + 27
         END AS active_to,
       CASE
         WHEN type = 'Churn' or type = 'EOL' THEN activity + 28
         END AS churn_from,
       CASE
         WHEN type = 'Churn' THEN next_activity - 1
         WHEN type = 'EOL' THEN '9999-12-31'
         END AS churn_to,
       cal_dt.date,
       EXTRACT(MONTH FROM cal_dt.date) - month_cohort + 1 as rel_month,
       CASE
         WHEN EXTRACT(WEEK FROM cal_dt.date) = 52 THEN 1
         ELSE EXTRACT(WEEK FROM cal_dt.date) - week_cohort + 1 END AS rel_week,
       CASE
         WHEN (date >= active_from AND date < active_to)
         OR (date >= active_from AND date <= active_to AND type = 'Churn')
         OR (type = 'EOL' AND date = active_from) THEN 1 END AS active_count,
       CASE
         WHEN date >= churn_from AND date <= churn_to THEN 1
         END AS churn_count
FROM activity_delta,cal_dt
ORDER BY cal_dt.date;

--With that detail, we can aggregate the total count of active and churn users on a day--
--Churn will be null for the first 28 days given the definition of Churn--

CREATE VIEW activity_total_tracker AS
SELECT t3.date, t3.active_users, t3.churned_users, t3.new_users, sum(t4.sum_tasks_used)
FROM (
       SELECT t1.date,
              sum(t1.active_count) AS active_users,
              sum(t1.churn_count)  as churned_users,
              t2.count             as new_users
       FROM activity_detail t1
              JOIN new_users_daily t2
                   ON t1.date = t2.start_date
       GROUP BY t1.date, t2.count
       order by t1.date
     ) t3
       JOIN tasks_used_da_cleaned t4
            ON t3.date = t4.date
GROUP BY t3.date, t3.active_users, t3.churned_users, t3.new_users
ORDER BY t3.date;

--Create monthly and weekly cohort analysis--

CREATE VIEW month_cohort_breakdown AS
SELECT month_cohort AS month_cohort,
       rel_month,
       sum(active_count) AS active_users,
       sum(churn_count) AS churned_users
FROM activity_detail
GROUP BY month_cohort, rel_month
ORDER BY month_cohort, rel_month;

CREATE VIEW week_cohort_breakdown AS
SELECT week_cohort AS week_cohort,
       rel_week,
       sum(active_count) AS active_users,
       sum(churn_count) AS churned_users
FROM activity_detail
GROUP BY week_cohort, rel_week
ORDER BY week_cohort, rel_week;
