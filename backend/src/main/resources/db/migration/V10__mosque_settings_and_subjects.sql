-- The mosque Maktab is built for: Jamiyat Tabligh UL Islam, in the UK. Fees are in pounds, dates follow UK time.
UPDATE organisation
SET name = 'Jamiyat Tabligh UL Islam', time_zone = 'Europe/London', currency = 'GBP', updated_at = now()
WHERE id = '00000000-0000-0000-0000-000000000001';

ALTER TABLE organisation ALTER COLUMN time_zone SET DEFAULT 'Europe/London';
ALTER TABLE organisation ALTER COLUMN currency SET DEFAULT 'GBP';

-- The mosque's own absence reasons. Earlier values are mapped to the nearest new one; a reason that was only
-- "other" is cleared rather than guessed.
ALTER TABLE lesson_attendance DROP CONSTRAINT lesson_attendance_absence_reason_check;

UPDATE lesson_attendance SET absence_reason = 'AUTHORISED' WHERE absence_reason = 'FAMILY_REASON';
UPDATE lesson_attendance SET absence_reason = 'UNAUTHORISED' WHERE absence_reason = 'UNKNOWN';
UPDATE lesson_attendance SET absence_reason = NULL WHERE absence_reason = 'OTHER';

ALTER TABLE lesson_attendance ADD CONSTRAINT ck_lesson_attendance_absence_reason
    CHECK (absence_reason IN ('AUTHORISED', 'UNAUTHORISED', 'SICK', 'HOLIDAY', 'NOT_READING'));

-- Every topic belongs to one subject of the teaching list. Topics written before subjects existed have none until
-- their period is next edited.
ALTER TABLE lesson_topic ADD COLUMN subject varchar(30)
    CHECK (subject IN ('QURAN_RECITATION', 'ISLAMIC_STUDIES', 'NAMAZ_AND_DUAS', 'ARABIC', 'NAATS_AND_SPEECHES'));
