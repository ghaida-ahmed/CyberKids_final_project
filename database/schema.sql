-- ================================================================
-- Cyber Kids Academy - Database Update Script
-- ================================================================
-- هذا الملف يحتوي على جميع التعديلات المطلوبة لقاعدة البيانات
-- نفذ هذه الأوامر في Supabase SQL Editor
-- ================================================================

-- ================================================================
-- 1. تعديل جدول parents لدعم طفلين
-- ================================================================

-- إضافة عمود للطفل الثاني (البريد الإلكتروني)
ALTER TABLE parents 
ADD COLUMN IF NOT EXISTS childEmail2 TEXT NULL;

-- إضافة عمود لعمر الطفل الثاني
ALTER TABLE parents 
ADD COLUMN IF NOT EXISTS childAge2 INT NULL;

-- إضافة تعليق توضيحي للأعمدة الجديدة
COMMENT ON COLUMN parents.childEmail2 IS 'Email of second child (optional)';
COMMENT ON COLUMN parents.childAge2 IS 'Age of second child (optional)';

-- ================================================================
-- 2. إنشاء جدول admins لإدارة المسؤولين
-- ================================================================

CREATE TABLE IF NOT EXISTS admins (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- إضافة تعليق للجدول
COMMENT ON TABLE admins IS 'Administrator accounts for managing the platform';

-- Add an initial admin account.
-- Replace these placeholders before running the script in Supabase.
INSERT INTO admins (email, password) 
VALUES ('your-admin-email@example.com', 'replace-with-a-strong-password')
ON CONFLICT (email) DO NOTHING;

-- ================================================================
-- 3. إنشاء جدول game_ideas لتخزين أفكار الألعاب والكويزات
-- ================================================================

CREATE TABLE IF NOT EXISTS game_ideas (
  id BIGSERIAL PRIMARY KEY,
  idea_type TEXT NOT NULL CHECK (idea_type IN ('game', 'quiz', 'lesson')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  submitted_by TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'implemented')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- إضافة تعليقات للأعمدة
COMMENT ON TABLE game_ideas IS 'Educational content ideas submitted by admins';
COMMENT ON COLUMN game_ideas.idea_type IS 'Type of content: game, quiz, or lesson';
COMMENT ON COLUMN game_ideas.title IS 'Title of the proposed content';
COMMENT ON COLUMN game_ideas.description IS 'Detailed description of the idea';
COMMENT ON COLUMN game_ideas.submitted_by IS 'Email of the admin who submitted the idea';
COMMENT ON COLUMN game_ideas.status IS 'Current status: pending, approved, rejected, or implemented';

-- إنشاء index للبحث الأسرع
CREATE INDEX IF NOT EXISTS idx_game_ideas_type ON game_ideas(idea_type);
CREATE INDEX IF NOT EXISTS idx_game_ideas_status ON game_ideas(status);
CREATE INDEX IF NOT EXISTS idx_game_ideas_submitted_by ON game_ideas(submitted_by);

-- ================================================================
-- 4. إعدادات Row Level Security (RLS) - معطلة للتطوير
-- ================================================================

-- تعطيل RLS للجداول الجديدة (للتطوير فقط)
ALTER TABLE admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE game_ideas DISABLE ROW LEVEL SECURITY;

-- ملاحظة: في الإنتاج، يجب تفعيل RLS مع سياسات مناسبة:
-- ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE game_ideas ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- 5. إضافة constraints للبيانات الموجودة
-- ================================================================

-- التأكد من صحة البريد الإلكتروني للطفل الثاني
ALTER TABLE parents 
ADD CONSTRAINT check_childEmail2_format 
CHECK (childEmail2 IS NULL OR childEmail2 ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- التأكد من صحة عمر الطفل الثاني
ALTER TABLE parents 
ADD CONSTRAINT check_childAge2_range 
CHECK (childAge2 IS NULL OR (childAge2 >= 5 AND childAge2 <= 18));

-- ================================================================
-- 6. إنشاء views مفيدة (اختياري)
-- ================================================================

-- View لعرض جميع الوالدين مع أطفالهم
CREATE OR REPLACE VIEW parents_with_children AS
SELECT 
  p.id,
  p.email AS parent_email,
  c1.firstName AS child1_firstname,
  c1.lastName AS child1_lastname,
  c1.email AS child1_email,
  c1.age AS child1_age,
  c1.points AS child1_points,
  c2.firstName AS child2_firstname,
  c2.lastName AS child2_lastname,
  c2.email AS child2_email,
  c2.age AS child2_age,
  c2.points AS child2_points,
  p.dailylimit
FROM parents p
LEFT JOIN children c1 ON p.childEmail = c1.email
LEFT JOIN children c2 ON p.childEmail2 = c2.email;

-- ================================================================
-- 7. بيانات تجريبية (اختياري - للتجربة فقط)
-- ================================================================

-- إضافة أفكار تجريبية
INSERT INTO game_ideas (idea_type, title, description, submitted_by, status)
VALUES 
  ('game', 'Social Media Safety Game', 'A game that teaches children about privacy settings and what to share online. Players navigate through different social media scenarios and make decisions about what information is safe to share.', 'your-admin-email@example.com', 'pending'),
  ('quiz', 'Password Security Quiz', 'An interactive quiz that tests children understanding of strong passwords, two-factor authentication, and password management best practices.', 'your-admin-email@example.com', 'pending'),
  ('lesson', 'Cyberbullying Awareness', 'A lesson that teaches children about cyberbullying, how to recognize it, and what steps to take if they encounter it online.', 'your-admin-email@example.com', 'pending')
ON CONFLICT DO NOTHING;

-- ================================================================
-- 8. Functions مساعدة (اختياري)
-- ================================================================

-- Function لحساب إجمالي نقاط الطفل
CREATE OR REPLACE FUNCTION get_child_total_points(child_email TEXT)
RETURNS INTEGER AS $$
DECLARE
  total_points INTEGER;
BEGIN
  SELECT COALESCE(points, 0) INTO total_points
  FROM children
  WHERE email = child_email;
  
  RETURN total_points;
END;
$$ LANGUAGE plpgsql;

-- Function لحساب إجمالي نقاط أطفال الوالد
CREATE OR REPLACE FUNCTION get_parent_children_total_points(parent_email TEXT)
RETURNS INTEGER AS $$
DECLARE
  total_points INTEGER := 0;
  child1_email TEXT;
  child2_email TEXT;
BEGIN
  SELECT childEmail, childEmail2 INTO child1_email, child2_email
  FROM parents
  WHERE email = parent_email;
  
  -- جمع نقاط الطفل الأول
  IF child1_email IS NOT NULL THEN
    total_points := total_points + get_child_total_points(child1_email);
  END IF;
  
  -- جمع نقاط الطفل الثاني
  IF child2_email IS NOT NULL THEN
    total_points := total_points + get_child_total_points(child2_email);
  END IF;
  
  RETURN total_points;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 9. تحديث البيانات الموجودة (إذا لزم الأمر)
-- ================================================================

-- تحديث القيم الافتراضية للنقاط للأطفال الموجودين
UPDATE children 
SET points = 0 
WHERE points IS NULL;

-- ================================================================
-- 10. التحقق من نجاح التعديلات
-- ================================================================

-- عرض بنية جدول parents المحدث
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'parents'
ORDER BY ordinal_position;

-- عرض بنية جدول admins
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'admins'
ORDER BY ordinal_position;

-- عرض بنية جدول game_ideas
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'game_ideas'
ORDER BY ordinal_position;

-- عد الأدمنز
SELECT COUNT(*) AS total_admins FROM admins;

-- عد الأفكار المقترحة
SELECT 
  idea_type,
  COUNT(*) AS count
FROM game_ideas
GROUP BY idea_type;

-- ================================================================
-- انتهى - جميع التعديلات نفذت بنجاح! ✅
-- ================================================================

-- ملاحظات مهمة:
-- 1. Replace the admin email and password placeholders before running this script
-- 2. في الإنتاج، فعّل RLS مع سياسات أمان مناسبة
-- 3. احفظ نسخة احتياطية من قاعدة البيانات قبل التنفيذ
-- 4. اختبر جميع الميزات بعد التعديلات
