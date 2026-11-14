-- Fix Test Quiz tag to 'demo' instead of NULL (all tags)
-- Run this to make the test quiz only visible to users with tag 'demo'

UPDATE quiz
SET target_tag = 'demo'
WHERE title = 'Test Quiz: Cyber Security Intermediate';

-- Verify the change
SELECT id, title, target_tag FROM quiz WHERE title LIKE 'Test Quiz%';
