# Neo4j Code

## Index

```         
// Index for Authors by id
CREATE INDEX author_id IF NOT EXISTS FOR (a:Author) ON (a.id);
```

```         
// Index for Subreddits by name
CREATE INDEX subreddit_name IF NOT EXISTS FOR (s:Subreddit) ON (s.name);
```

```         
// Index for Comments by id
CREATE INDEX comment_id IF NOT EXISTS FOR (c:Comment) ON (c.id);
```

```         
// Index for Comments by parent_id_small to facilitate parent-child relationships
CREATE INDEX comment_parent_id_small IF NOT EXISTS FOR (c:Comment) ON (c.parent_id_small);
```

```         
// Index for Sentiment by type
CREATE INDEX sentiment_type IF NOT EXISTS FOR (s:Sentiment) ON (s.type);
```

```
// Index for Theme by id (new index)
CREATE INDEX theme_id IF NOT EXISTS FOR (t:Theme) ON (t.id);
```

```
CREATE INDEX score_category IF NOT EXISTS FOR (s:Score) ON (s.category);
```

## Load Data

```         
// Step 1: Load Authors and Subreddits
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_v2.csv" AS row CALL {
    WITH row
    MERGE (:Author {id: row.author})
    MERGE (:Subreddit {name: row.subreddit})
} IN TRANSACTIONS OF 1000 ROWS;
```

```         
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_v2.csv" AS row CALL {
    WITH row
    MATCH (a:Author {id: row.author})
    MATCH (s:Subreddit {name: row.subreddit})
    MERGE (c:Comment {id: row.id})
        SET c.score = toInteger(row.score),
            c.body = row.body,
            c.display_name = row.display_name,
            c.length = toInteger(row.length),
            c.theme = toInteger(row.theme),
            c.matching_related_subreddits = row.matching_related_subreddits,
            c.sentiment_category = row.sentiment_category,  // Add sentiment_category
            c.score_category = row.score_category,          // Add score_category
            c.description = row.description                 // Add description
    MERGE (a)-[:POSTED]->(c)
    MERGE (c)-[:IN]->(s)
    // Link each comment to its Score based on score_category
    MERGE (score:Score {category: row.score_category})
    MERGE (c)-[:HAS_SCORE]->(score)  // Create relationship to Score node
} IN TRANSACTIONS OF 1000 ROWS;
```

```         
// Step 3: Create Sentiment nodes (only needs to be done once)
MERGE (:Sentiment {type: "extremely_positive"})
MERGE (:Sentiment {type: "somewhat_positive"})
MERGE (:Sentiment {type: "neutral"});
MERGE (:Sentiment {type: "somewhat_negative"});
MERGE (:Sentiment {type: "extremely_negative"});
```

```         
// Step 4: Link Comments to Sentiment nodes based on sentiment_category
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_v2.csv" AS row CALL {
    WITH row
    MATCH (c:Comment {id: row.id})
    MATCH (s:Sentiment {type: row.sentiment_category})
    MERGE (c)-[:HAS_SENTIMENT]->(s)
} IN TRANSACTIONS OF 1000 ROWS;
```

```
// Create Theme nodes for non-null and non-empty themes
MATCH (c:Comment)
WHERE c.theme IS NOT NULL AND c.theme <> ""  // Exclude null or empty themes
WITH DISTINCT c.theme AS theme_id
MERGE (:Theme {id: theme_id});
```

## Relationship
### Sentiment
#### Between `Comment` and `Sentiment` 

```         
MATCH (c:Comment), (s:Sentiment) WHERE toLower(c.sentiment_category) = toLower(s.type) MERGE (c)-[:HAS_SENTIMENT]->(s) 
```

### Theme
#### relationship theme-subreddit
``` 
// Link Themes to Subreddits based on comments
MATCH (c:Comment)-[:IN]->(s:Subreddit)
WHERE c.theme IS NOT NULL AND c.theme <> ""  // Exclude null or empty themes
WITH DISTINCT c.theme AS theme_id, s
MATCH (t:Theme {id: theme_id})  // Match the Theme node by theme_id
MERGE (t)-[:THEME_SUBREDDIT]->(s); 
 // Create the relationship between Theme and Subreddit
```

#### relationship theme-comment

```
// Link Comments to Themes, ensuring proper type matching
MATCH (c:Comment)
WHERE c.theme IS NOT NULL AND c.theme <> ""  // Exclude null or empty themes
WITH toInteger(c.theme) AS theme_id, c  // Convert theme to integer if necessary
MATCH (t:Theme {id: theme_id})  // Match the Theme node by theme_id
MERGE (c)-[:HAS_THEME]->(t);
// Create the relationship between Comment and Theme
```

#### relationship theme_authors

```
// Link Themes to Authors based on comments
MATCH (c:Comment)<-[:POSTED]-(a:Author)
WHERE c.theme IS NOT NULL AND c.theme <> ""  // Exclude null or empty themes
WITH c.theme AS theme_id, a
MATCH (t:Theme {id: theme_id})  // Match the Theme node by theme_id
MERGE (t)-[:THEME_AUTHORS]->(a);  
// Create the relationship between Theme and Author
```

## Graph
### Sentiment-Comment

```
MATCH (s:Sentiment) CALL {     
    WITH s     
    MATCH (s)<-[:HAS_SENTIMENT]-(c:Comment)     
    RETURN c     
    LIMIT 10  
    // Adjust the limit as needed 
} 
RETURN s, c
```

### Theme-Comment

```
// Query to show all Themes with their associated Comments (limited to 10 per theme)
MATCH (c:Comment)-[:HAS_THEME]->(t:Theme)
WITH t, COLLECT(c)[0..10] AS limited_comments  // Limit to 10 comments per theme
RETURN t, limited_comments;
```

### Sentiment AND Theme

```
// Query to show both Sentiment and Theme graphs linked to Comments
MATCH (c:Comment)
OPTIONAL MATCH (c)-[:HAS_THEME]->(t:Theme)  // Match Theme node linked to Comment
OPTIONAL MATCH (c)-[:HAS_SENTIMENT]->(s:Sentiment)  // Match Sentiment node linked to Comment
RETURN c, t, s
LIMIT 100;
// Limit the result to avoid too many nodes in case of large dataset
```

### Sentiment AND Score AND Theme

```
// Query to show Sentiment, Theme, and Score graphs linked to Comments
MATCH (c:Comment)
OPTIONAL MATCH (c)-[:HAS_THEME]->(t:Theme)       // Match Theme node linked to Comment
OPTIONAL MATCH (c)-[:HAS_SENTIMENT]->(s:Sentiment)  // Match Sentiment node linked to Comment
OPTIONAL MATCH (c)-[:HAS_SCORE]->(sc:Score)     // Match Score node linked to Comment
RETURN c, t, s, sc
LIMIT 100;
```

### Sentiment AND Score AND Theme AND Authors

```
// Query to show Sentiment, Theme, and Score graphs linked to Comments
MATCH (c:Comment)
// Query to show Sentiment, Theme, Score, and Author graphs linked to Comments
MATCH (c:Comment)
OPTIONAL MATCH (c)-[:HAS_THEME]->(t:Theme)       // Match Theme node linked to Comment
OPTIONAL MATCH (c)-[:HAS_SENTIMENT]->(s:Sentiment)  // Match Sentiment node linked to Comment
OPTIONAL MATCH (c)-[:HAS_SCORE]->(sc:Score)     // Match Score node linked to Comment
OPTIONAL MATCH (a:Author)-[:POSTED]->(c)        // Match Author node linked to Comment
RETURN c, t, s, sc, a
LIMIT 100;
```

### load leo dataset (lighter)
```
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_leo.csv" AS row CALL {
WITH row
MATCH (s1:Subreddit {name: row.subreddit}) // Match the primary subreddit
WITH s1, SPLIT(row.matching_related_subreddits, ",") AS related_subreddits // Split the related subreddits by comma
UNWIND related_subreddits AS related_name // Break down the list into individual subreddit names
WITH s1, TRIM(related_name) AS trimmed_name // Remove extra spaces
MATCH (s2:Subreddit {name: trimmed_name}) // Match related subreddit nodes
MERGE (s1)-[:RELATED_TO]->(s2) // Create a relationship between the subreddits
} IN TRANSACTIONS OF 1000 ROWS;
```

### graph related sub 
```
MATCH (s1:Subreddit)-[:RELATED_TO]->(s2:Subreddit)
RETURN s1, s2
LIMIT 300;
```

### table top 20
```
MATCH (s1:Subreddit)-[:RELATED_TO]->(s2:Subreddit)
RETURN s1.name AS subreddit, COUNT(s2) AS related_count
ORDER BY related_count DESC
LIMIT 10;
```

### related sub and sentiment
```
MATCH (c:Comment)-[:IN]->(s:Subreddit)
MATCH (c)-[:HAS_SENTIMENT]->(sent:Sentiment)
MERGE (s)-[:HAS_SENTIMENT]->(sent);
```

### graph related sub and sentiment
```
MATCH (c:Comment)-[:IN]->(s:Subreddit)
MATCH (c)-[:HAS_SENTIMENT]->(sent:Sentiment)
MERGE (s)-[:HAS_SENTIMENT]->(sent);
```

### related sub with top 20
```
MATCH (s:Subreddit)-[:RELATED_TO]->(:Subreddit)
WITH s, COUNT(*) AS related_count
ORDER BY related_count DESC
LIMIT 20
SET s:TopSubreddit;
// Add a label for the top 20 subreddits
```

### graph related sub with top 20
```
MATCH (s1:Subreddit)-[:RELATED_TO]->(s2:Subreddit)
RETURN s1, s2;
```

