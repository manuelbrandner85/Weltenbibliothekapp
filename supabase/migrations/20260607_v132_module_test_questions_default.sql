-- Fix: test_questions war NOT NULL ohne Default -> Modul-Werkstatt Accept/Save
-- schlug mit NOT-NULL-Verletzung fehl (Client sah HTTP 500).
ALTER TABLE vorhang_modules ALTER COLUMN test_questions SET DEFAULT '[]'::jsonb;
ALTER TABLE ursprung_modules ALTER COLUMN test_questions SET DEFAULT '[]'::jsonb;
UPDATE vorhang_modules SET test_questions = '[]'::jsonb WHERE test_questions IS NULL;
UPDATE ursprung_modules SET test_questions = '[]'::jsonb WHERE test_questions IS NULL;
