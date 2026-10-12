
-- 🚀 SETUP INSTRUCTIONS (MUST DO FIRST)
-- ==============================================================
-- Before solving this project, make sure you create and load the dataset.
--
-- STEP 1: Open your SQL client (MySQL Workbench, DBeaver, or SQLite Studio).
-- STEP 2: Run the provided dataset file:
--         social_media_analytics_dataset.sql
--
-- This script will:
--   ✅ Create a new database named `Social_Media`
--   ✅ Create all 7 tables (users, posts, comments, likes, followers, hashtags, post_hashtags)
--   ✅ Insert ~7,000 synthetic rows for analysis
--
-- STEP 3: After successful execution, Your Code the database:
--         USE Social_Media;
--
-- STEP 4: Verify the tables:
--         SHOW TABLES;
--         Your Code COUNT(*) FROM users;
--         Your Code COUNT(*) FROM posts;
--
-- Once you confirm the data is loaded, you can proceed to attempt all project queries.
-- ==============================================================

USE Social_Media;

-- ==============================================================
-- IMPORTANT: BEFORE USING GenAI FOR QUERY GENERATION
-- ==============================================================
-- To help the AI generate accurate SQL, you MUST first share your schema.
-- Paste the following context into ChatGPT (or any GenAI tool) BEFORE you ask your prompts:

/*
You are an expert SQL assistant.  
Before answering any question, refer strictly to the database schema provided below.  
All SQL queries, joins, and analyses must be based ONLY on this schema — table names, column names, and relationships mentioned here.  
Do not assume any extra tables or columns unless explicitly stated.  
If a question is ambiguous, clarify it using the schema context rather than inventing new fields.  
Once you understand the schema, wait for my analytical question and generate the most accurate SQL query for it.

Tables and Key Columns:
  1. users(user_id, username, join_date, country)
  2. posts(post_id, user_id, content, created_at)
  3. comments(comment_id, post_id, user_id, comment_text, created_at)
  4. likes(like_id, post_id, user_id, created_at)
  5. followers(follower_id, user_id, follower_user_id, follow_date)
  6. hashtags(hashtag_id, tag_name, category)
  7. post_hashtags(id, post_id, hashtag_id)

Relationships:
  • Each user can create multiple posts.
  • Each post can have multiple likes and comments.
  • Users can follow each other (self-join in followers table).
  • Posts can be tagged with multiple hashtags (many-to-many via post_hashtags).
*/

-- Once you paste the schema, THEN use prompts like:
--   "Generate SQL to find top 10 active users combining posts and comments."
--   "Find trending hashtags used in more than 20 posts."
-- ==============================================================




-- ==============================================================
-- Q1. Most Active Users (Posts + Comments)
-- ==============================================================
-- Objective : Find top 10 users based on combined number of posts and comments.
-- Example GenAI Prompt :
--   "Write SQL to find top 10 active users combining posts and comments count."
-- Write your query below 👇
-- --------------------------------------------------------------
-- Your Code ...

SELECT user_id,username,
    COUNT(DISTINCT posts.post_id) AS total_posts,
    COUNT(DISTINCT comments.comment_id) AS total_comments,
    COUNT(DISTINCT posts.post_id) + COUNT(DISTINCT comments.comment_id) AS total_activity
FROM users
LEFT JOIN posts
using(user_id)
LEFT JOIN comments
using(user_id)
GROUP BY users.user_id, users.username
ORDER BY total_activity DESC
LIMIT 10;

-- Solution Summary -- 
/*
These users drive both content creation and conversation — not just passive scrolling. 
They're strong candidates for ambassador programs or beta feature testing.
Track this list over time: if a regular top performer drops off, treat it as an early churn signal worth a re-engagement nudge
*/


-- ==============================================================
-- Q2. Most Liked Posts and Creators
-- ==============================================================
-- Objective : Identify posts with maximum likes along with their creator.
-- Example GenAI Prompt :
--   "Show top 10 posts with most likes and username."
-- --------------------------------------------------------------
-- Your Code ...
SELECT p.post_id,p.content,u.user_id,u.username,COUNT(l.like_id) AS total_likes
FROM posts p
JOIN users u 
using(user_id)
LEFT JOIN likes l 
using(post_id)
GROUP BY p.post_id, p.content, u.user_id, u.username
ORDER BY total_likes DESC
LIMIT 10;


-- Solution Summary -- 
-- Top-liked posts reveal what content resonates most — 
-- useful for identifying winning formats, topics, and tones to replicate.
-- Creators who repeat on this list are high-value accounts worth featuring
 -- or partnering with. Cross-reference their hashtags to spot what's driving virality right now.
 
-- ==============================================================
-- Q3. Top Countries by Average Engagement
-- ==============================================================
-- Objective : Find countries with the highest average likes per post.
-- Example GenAI Prompt :
--   "Which countries have highest average likes per post?"
-- --------------------------------------------------------------
-- Your Code ...
SELECT u.country,COUNT(DISTINCT p.post_id) AS total_posts,COUNT(l.like_id) AS total_likes,
ROUND(COUNT(l.like_id) / COUNT(DISTINCT p.post_id), 2) AS avg_likes_per_post
FROM users u
JOIN posts p 
using(user_id)
LEFT JOIN likes l 
using(post_id)
GROUP BY u.country
ORDER BY avg_likes_per_post DESC
LIMIT 10;

-- Solution Summary -- 
#These markets show the highest engagement relative to content volume — 
#not the loudest countries, but where content actually resonates.
#Prioritize ad spend and localized content toward these regions, and investigate
#  low-average countries for content-fit, timing, or platform-maturity issues.

-- ==============================================================
-- Q4. Trending Hashtags (Used in >20 Posts)
-- ==============================================================
-- Objective : Find hashtags that appear in more than 20 posts.
-- Example GenAI Prompt :
--   "Find hashtags used in more than 20 posts."
-- --------------------------------------------------------------
-- Your Code ...
SELECT h.hashtag_id,h.tag_name,h.category,COUNT(ph.post_id) AS post_count
FROM hashtags h
JOIN post_hashtags ph 
using (hashtag_id)
GROUP BY h.hashtag_id, h.tag_name, h.category
HAVING COUNT(ph.post_id) > 20
ORDER BY post_count DESC;
-- Solution Summary -- 
#On this synthetic 1,000-row sample, the busiest hashtag appears in only 5 posts —
 #so the >20 threshold returns zero rows. The query logic (HAVING COUNT > 20) is correct and production-ready;
 #it simply needs a larger dataset to trigger.
#Ranked by volume instead, #population and #so lead — useful early signal for the content calendar.

-- ==============================================================
-- Q5. Top Influencers (Users with Most Followers)
-- ==============================================================
-- Objective : List users with the highest follower count.
-- Example GenAI Prompt :
--   "Find users with maximum followers."
-- --------------------------------------------------------------
-- Your Code ...
 SELECT  u.user_id,
    u.username,
    COUNT(f.follower_id) AS total_followers
FROM users u
JOIN followers f
    ON u.user_id = f.follower_id
GROUP BY u.user_id, u.username
ORDER BY total_followers DESC
LIMIT 1;


-- Solution Summary -- 
#Follower count identifies reach — the accounts best positioned to amplify 
#announcements or sponsored content.
#Combine this with the Top Active Users list (Q1): influencers who also post
 #and comment frequently are the highest-leverage partnership candidates.

-- ==============================================================
-- Q6. Followers Who Never Interacted
-- ==============================================================
-- Objective : Identify users who follow others but have never liked or commented.
-- Example GenAI Prompt :
--   "Show users who follow others but never interacted."
-- --------------------------------------------------------------
-- Your Code ...
SELECT DISTINCT u.user_id, u.username
FROM users u
JOIN followers f
    ON u.user_id = f.follower_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM likes l 
    WHERE l.user_id = u.user_id
)
AND NOT EXISTS (
    SELECT 1 
    FROM comments c 
    WHERE c.user_id = u.user_id
);
-- Solution Summary -- 
#Lurkers with intent — they've already opted in by following. A well-timed prompt
 #(“like your first post”, notification nudge) can convert passive followers into 
 #active participants at low cost.

-- ==============================================================
-- Q7. Hashtags with Highest Engagement
-- ==============================================================
-- Objective : Calculate total engagement (likes + comments) for each hashtag.
-- Example GenAI Prompt :
--   "Calculate engagement score per hashtag."
-- --------------------------------------------------------------
-- Your Code ...
select h.hashtag_id, h.tag_name,
count(like_id) + count(comment_id) as total_engagement
from hashtags as h
join post_hashtags as p on h.hashtag_id = p.hashtag_id
left join likes as i 
on p.post_id = i.post_id
left join comments as c
on p.post_id = c.post_id
group by h.hashtag_id , h.tag_name
order by total_engagement desc;
-- Solution Summary -- 
#Volume (Q4) and engagement quality (Q7) don't always agree — a hashtag used often
# isn't always the one sparking conversation.
#Use the Q4 list to plan reach, and this list to plan resonance: pair high-reach tags with high-engagement themes in campaign briefs.

-- ==============================================================
-- Q8. Busiest Posting Hours or Days
-- ==============================================================
-- Objective : Find which hour/day sees most posting activity.
-- Example GenAI Prompt :
--   "Write SQL to show which hour or weekday sees most posts."
-- --------------------------------------------------------------
-- Your Code ...
select Dayname(created_at) as Posting_day,
count(post_id) as total_posts
from posts 
group by Dayname(created_at)
order by total_posts DESC;

-- ==============================================================
-- Q9. Inactive Users
-- ==============================================================
-- Objective : Find users who have never posted, liked, or commented.
-- Example GenAI Prompt :
--   "Find users who have never posted, liked, or commented."
-- --------------------------------------------------------------
-- Your Code ...
SELECT
    u.user_id,
    u.username
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM posts    p WHERE p.user_id = u.user_id)
  AND NOT EXISTS (SELECT 1 FROM likes    l WHERE l.user_id = u.user_id)
  AND NOT EXISTS (SELECT 1 FROM comments c WHERE c.user_id = u.user_id)
ORDER BY u.user_id;

-- Solution Summary -- 
#Registered but dormant — a churn/onboarding risk. Segment by join_date: recent 
#signups need onboarding nudges, while long-dormant accounts need a win-back
# campaign or removal from active-user reporting.


-- ==============================================================
-- Q10. Top Countries with Most Influencers
-- ==============================================================
-- Objective : Identify countries with the highest number of influencers.
-- Example GenAI Prompt :
--   "Generate SQL to find countries that have the most followed users."
-- --------------------------------------------------------------
-- Your Code ...
WITH follower_counts AS (
    SELECT
        user_id,
        COUNT(*) AS follower_count
    FROM followers
    GROUP BY user_id
),
influencers AS (
    SELECT
        u.user_id,
        u.country
    FROM users u
    JOIN follower_counts fc ON fc.user_id = u.user_id
    WHERE fc.follower_count >= 3   -- "influencer" threshold, scaled to this dataset (max ~6 followers/user)
)
SELECT
    country,
    COUNT(*) AS influencer_count
FROM influencers
GROUP BY country
ORDER BY influencer_count DESC
LIMIT 5;



-- Solution Summary -- 
#Countries with more influencers per capita are natural launch markets for 
#creator partnerships and localized campaigns.
#Combined with Q3 (engagement by country), this identifies markets that are both
# well-connected and highly engaged — the strongest expansion candidates.


-- ==============================================================
-- BONUS CHALLENGES
-- ==============================================================
-- 1. Engagement rate = (likes + comments) / posts
SELECT p.user_id,
 (COUNT(l.like_id) + COUNT(c.comment_id)/COUNT(distinct p.post_id) )as engagement_rate
FROM posts as p
 JOIN likes as l
on p.post_id=l.post_id
JOIN comments as c
on p.post_id=c.post_id
GROUP BY p.user_id;

-- 2. Mutual followers
SELECT
    f1.user_id,
    f2.follower_user_id
FROM followers as f1
JOIN followers as f2
ON f1.user_id = f2.follower_user_id
AND f1.follower_user_id = f2.user_id;

-- 3. Most used hashtags by top 5 influencers
SELECT h.hashtag_id,
       h.tag_name,
       h.category,
       COUNT(ph.post_id) AS usage_count
FROM hashtags h
JOIN post_hashtags ph USING(hashtag_id)
JOIN posts p USING(post_id)
WHERE p.user_id IN (
    SELECT user_id
    FROM followers
    GROUP BY user_id
    ORDER BY COUNT(follower_user_id) DESC
    LIMIT 5
)
GROUP BY h.hashtag_id, h.tag_name, h.category
ORDER BY usage_count DESC;

-- 4. Country-wise engagement leaderboard
SELECT u.country,
       COUNT(DISTINCT p.post_id) AS total_posts,
       COUNT(DISTINCT l.like_id) AS total_likes,
       COUNT(DISTINCT c.comment_id) AS total_comments,
       (COUNT(DISTINCT l.like_id)+COUNT(DISTINCT c.comment_id)) AS total_engagement
FROM users u
JOIN posts p USING(user_id)
LEFT JOIN likes l USING(post_id)
LEFT JOIN comments c USING(post_id)
GROUP BY u.country
ORDER BY total_engagement DESC;
-- --------------------------------------------------------------

