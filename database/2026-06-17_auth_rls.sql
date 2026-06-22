-- CyberKids Auth + RLS foundation.
-- Run after restoring the legacy public tables.

-- Link app records to Supabase Auth users.
ALTER TABLE public.children
  ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.parents
  ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS children_auth_user_id_key
  ON public.children(auth_user_id)
  WHERE auth_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS parents_auth_user_id_key
  ON public.parents(auth_user_id)
  WHERE auth_user_id IS NOT NULL;

-- Role/profile table for authenticated users.
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role IN ('child', 'parent', 'teacher', 'admin')),
  created_at timestamptz DEFAULT now()
);

-- Resolve child emails without exposing the children table.
CREATE OR REPLACE FUNCTION public.resolve_child_email(child_email text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT email
  FROM public.children
  WHERE lower(email) = lower(NULLIF(child_email, ''))
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.child_account_exists(child_email text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.resolve_child_email(child_email) IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.child_account_exists(text) TO anon, authenticated;

-- Create app rows automatically when a Supabase Auth user signs up.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requested_role text := COALESCE(new.raw_user_meta_data ->> 'role', 'child');
  child1_email text;
  child2_email text;
BEGIN
  IF requested_role NOT IN ('child', 'parent') THEN
    requested_role := 'child';
  END IF;

  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, lower(new.email), requested_role)
  ON CONFLICT (id) DO UPDATE
  SET email = excluded.email,
      role = excluded.role;

  IF requested_role = 'child' THEN
    INSERT INTO public.children (
      auth_user_id,
      "firstName",
      "lastName",
      email,
      age,
      progress,
      points
    )
    VALUES (
      new.id,
      COALESCE(NULLIF(new.raw_user_meta_data ->> 'firstName', ''), 'Child'),
      COALESCE(new.raw_user_meta_data ->> 'lastName', ''),
      lower(new.email),
      NULLIF(new.raw_user_meta_data ->> 'age', '')::integer,
      '{"gamesCompleted": 0, "quizzesCompleted": 0, "lessonsCompleted": 0}'::jsonb,
      0
    )
    ON CONFLICT (email) DO UPDATE
    SET auth_user_id = excluded.auth_user_id,
        "firstName" = excluded."firstName",
        "lastName" = excluded."lastName",
        age = excluded.age;
  ELSIF requested_role = 'parent' THEN
    child1_email := public.resolve_child_email(new.raw_user_meta_data ->> 'childEmail');
    child2_email := public.resolve_child_email(new.raw_user_meta_data ->> 'childEmail2');

    IF child1_email IS NULL THEN
      RAISE EXCEPTION 'child_email_not_found';
    END IF;

    INSERT INTO public.parents (
      auth_user_id,
      email,
      "childEmail",
      "childAge",
      childemail2,
      childage2,
      last_seen_progress
    )
    VALUES (
      new.id,
      lower(new.email),
      child1_email,
      NULLIF(new.raw_user_meta_data ->> 'childAge', '')::integer,
      child2_email,
      NULLIF(new.raw_user_meta_data ->> 'childAge2', '')::integer,
      '{}'::jsonb
    )
    ON CONFLICT (email) DO UPDATE
    SET auth_user_id = excluded.auth_user_id,
        "childEmail" = excluded."childEmail",
        "childAge" = excluded."childAge",
        childemail2 = excluded.childemail2,
        childage2 = excluded.childage2;
  END IF;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Helper used by RLS to avoid children <-> parents policy recursion.
CREATE OR REPLACE FUNCTION public.current_user_is_linked_parent(child_email text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.parents p
    WHERE p.auth_user_id = auth.uid()
      AND (lower(p."childEmail") = lower(child_email) OR lower(p.childemail2) = lower(child_email))
  );
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
CREATE POLICY "Users can read their own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid() AND role IN ('child', 'parent'));

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- Lock app tables behind authenticated RLS.
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.play_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE
  public.admins,
  public.children,
  public.content_library,
  public.game_ideas,
  public.profiles,
  public.parents,
  public.play_logs,
  public.teachers
FROM anon;

REVOKE ALL ON TABLE
  public.admins,
  public.children,
  public.content_library,
  public.game_ideas,
  public.profiles,
  public.parents,
  public.play_logs,
  public.teachers
FROM authenticated;

GRANT SELECT, INSERT ON TABLE public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.children TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.parents TO authenticated;
GRANT SELECT, INSERT ON TABLE public.play_logs TO authenticated;
GRANT SELECT, UPDATE ON TABLE public.content_library TO authenticated;
GRANT SELECT, INSERT ON TABLE public.game_ideas TO authenticated;
GRANT SELECT, INSERT, DELETE ON TABLE public.teachers TO authenticated;

GRANT USAGE, SELECT ON SEQUENCE
  public.children_id_seq,
  public.parents_id_seq,
  public.play_logs_id_seq,
  public.game_ideas_id_seq
TO authenticated;

-- Children can manage their own row. Parents can read linked child rows.
DROP POLICY IF EXISTS "Children can insert their own record" ON public.children;
CREATE POLICY "Children can insert their own record"
  ON public.children FOR INSERT
  TO authenticated
  WITH CHECK (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Children and linked parents can read child records" ON public.children;
CREATE POLICY "Children and linked parents can read child records"
  ON public.children FOR SELECT
  TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR public.current_user_is_linked_parent(children.email)
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('teacher', 'admin')
    )
  );

DROP POLICY IF EXISTS "Children can update their own progress" ON public.children;
CREATE POLICY "Children can update their own progress"
  ON public.children FOR UPDATE
  TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- Parents can manage only their own parent row.
DROP POLICY IF EXISTS "Parents can insert their own record" ON public.parents;
CREATE POLICY "Parents can insert their own record"
  ON public.parents FOR INSERT
  TO authenticated
  WITH CHECK (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Parents can read their own record" ON public.parents;
CREATE POLICY "Parents can read their own record"
  ON public.parents FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Children can read linked parent limits" ON public.parents;
CREATE POLICY "Children can read linked parent limits"
  ON public.parents FOR SELECT
  TO authenticated
  USING (
    lower(auth.jwt() ->> 'email') = lower(parents."childEmail")
    OR lower(auth.jwt() ->> 'email') = lower(parents.childemail2)
  );

DROP POLICY IF EXISTS "Parents can update their own record" ON public.parents;
CREATE POLICY "Parents can update their own record"
  ON public.parents FOR UPDATE
  TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- Visible content can be read by signed-in users.
DROP POLICY IF EXISTS "Signed in users can read visible content" ON public.content_library;
CREATE POLICY "Signed in users can read visible content"
  ON public.content_library FOR SELECT
  TO authenticated
  USING (
    isvisible = true
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('teacher', 'admin')
    )
  );

DROP POLICY IF EXISTS "Teachers and admins can update content" ON public.content_library;
CREATE POLICY "Teachers and admins can update content"
  ON public.content_library FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('teacher', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('teacher', 'admin')
    )
  );

-- Parents and children can read or write play logs for linked children.
DROP POLICY IF EXISTS "Children can insert their own play logs" ON public.play_logs;
CREATE POLICY "Children can insert their own play logs"
  ON public.play_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.children c
      WHERE c.auth_user_id = auth.uid()
        AND c.email = play_logs.childemail
    )
  );

DROP POLICY IF EXISTS "Families can read linked play logs" ON public.play_logs;
CREATE POLICY "Families can read linked play logs"
  ON public.play_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.children c
      WHERE c.auth_user_id = auth.uid()
        AND c.email = play_logs.childemail
    )
    OR EXISTS (
      SELECT 1
      FROM public.parents p
      WHERE p.auth_user_id = auth.uid()
        AND (p."childEmail" = play_logs.childemail OR p.childemail2 = play_logs.childemail)
    )
  );

-- Admin/teacher-oriented tables stay closed until those roles are migrated.
DROP POLICY IF EXISTS "Admins can create game ideas" ON public.game_ideas;
CREATE POLICY "Admins can create game ideas"
  ON public.game_ideas FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can read game ideas" ON public.game_ideas;
CREATE POLICY "Admins can read game ideas"
  ON public.game_ideas FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can manage teachers" ON public.teachers;
CREATE POLICY "Admins can manage teachers"
  ON public.teachers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  );

-- Narrow read-only view for leaderboards without opening full child records.
CREATE OR REPLACE VIEW public.child_leaderboard AS
SELECT
  "firstName",
  "lastName",
  points
FROM public.children
ORDER BY points DESC NULLS LAST;

GRANT SELECT ON public.child_leaderboard TO authenticated;
