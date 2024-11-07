# Neo4j Code

## To be ran Once
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

## Load Data

```
// Step 1: Load Authors and Subreddits
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_cleaned_NOBODY.csv" AS row CALL {
    WITH row
    MERGE (:Author {id: row.author})
    MERGE (:Subreddit {name: row.subreddit})
} IN TRANSACTIONS OF 1000 ROWS;
```

```
// Step 2: Load Comments and link them to Authors and Subreddits
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_cleaned_NOBODY.csv" AS row CALL {
    WITH row
    MATCH (a:Author {id: row.author})
    MATCH (s:Subreddit {name: row.subreddit})
    MERGE (c:Comment {id: row.id})
        SET c.score = toInteger(row.score),
            c.created_utc = row.created_utc,
            c.controversiality = toInteger(row.controversiality),
            c.gilded = toInteger(row.gilded),
            c.edited = row.edited,
            c.parent_id = row.parent_id,
            c.parent_id_small = row.parent_id_small
    MERGE (a)-[:POSTED]->(c)
    MERGE (c)-[:IN]->(s)
} IN TRANSACTIONS OF 1000 ROWS;
```

```
// Step 3: Create relationships between parent and child comments if parent_id is present
:auto LOAD CSV WITH HEADERS FROM "file:///reddit_comments_15k_cleaned_NOBODY.csv" AS row CALL {
    WITH row
    MATCH (c:Comment {id: row.id})
    MATCH (p:Comment {id: row.parent_id_small})
    MERGE (p)-[:REPLIED_TO]->(c)
} IN TRANSACTIONS OF 1000 ROWS;
```

## Graphs