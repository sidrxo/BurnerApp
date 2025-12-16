-- Clean up venues table from Firebase migration artifacts
-- This script removes stringified JSON and converts Firebase timestamps

-- First, let's see what we're working with
SELECT id, name, address, city, created_at FROM venues LIMIT 5;

-- Clean up stringified empty strings and convert to NULL
UPDATE venues SET
  address = CASE
    WHEN address IN ('""', 'null', '\"\"') THEN NULL
    WHEN address LIKE '"%"' THEN trim(both '"' from address)
    ELSE address
  END,
  city = CASE
    WHEN city IN ('""', 'null', '\"\"') THEN NULL
    WHEN city LIKE '"%"' THEN trim(both '"' from city)
    ELSE city
  END,
  website = CASE
    WHEN website IN ('""', 'null', '\"\"') THEN NULL
    WHEN website LIKE '"%"' THEN trim(both '"' from website)
    ELSE website
  END,
  contactEmail = CASE
    WHEN contactEmail IN ('""', 'null', '\"\"') THEN NULL
    WHEN contactEmail LIKE '"%"' THEN trim(both '"' from contactEmail)
    ELSE contactEmail
  END;

-- Convert capacity from string '0' to actual number or NULL
UPDATE venues SET
  capacity = CASE
    WHEN capacity::text = '0' THEN NULL
    WHEN capacity::text = 'null' THEN NULL
    ELSE capacity
  END;

-- Convert imageUrl 'null' strings to actual NULL
UPDATE venues SET
  imageUrl = CASE
    WHEN imageUrl = 'null' THEN NULL
    ELSE imageUrl
  END;

-- You'll need to manually fix the Firebase timestamp objects in created_at
-- They look like: {"_seconds": 1760808801, "_nanoseconds": 287000000}
-- Convert to proper timestamps:
-- Example: to_timestamp(1760808801) would convert the seconds

-- Check the results
SELECT id, name, address, city, capacity, website, contactEmail, imageUrl FROM venues;
