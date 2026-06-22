CREATE OR REPLACE FUNCTION public.admin_create_teacher_account(
  teacher_email text,
  teacher_password text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  normalized_email text := lower(trim(teacher_email));
  teacher_user_id uuid;
  admin_ok boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  )
  INTO admin_ok;

  IF NOT admin_ok THEN
    RAISE EXCEPTION 'Only admins can create teacher accounts.';
  END IF;

  IF normalized_email IS NULL OR normalized_email = '' THEN
    RAISE EXCEPTION 'Teacher email is required.';
  END IF;

  IF teacher_password IS NULL OR length(teacher_password) < 4 THEN
    RAISE EXCEPTION 'Teacher password must be at least 4 characters.';
  END IF;

  SELECT id
  INTO teacher_user_id
  FROM auth.users
  WHERE lower(email) = normalized_email
  LIMIT 1;

  IF teacher_user_id IS NULL THEN
    RAISE EXCEPTION 'Teacher auth user was not created yet.';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(teacher_password, gen_salt('bf', 10)),
      email_confirmed_at = COALESCE(email_confirmed_at, now()),
      confirmation_token = COALESCE(confirmation_token, ''),
      recovery_token = COALESCE(recovery_token, ''),
      email_change_token_new = COALESCE(email_change_token_new, ''),
      email_change_token_current = COALESCE(email_change_token_current, ''),
      phone_change = COALESCE(phone_change, ''),
      phone_change_token = COALESCE(phone_change_token, ''),
      reauthentication_token = COALESCE(reauthentication_token, ''),
      raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
      raw_user_meta_data = jsonb_build_object('role', 'teacher'),
      updated_at = now()
  WHERE id = teacher_user_id;

  UPDATE auth.identities
  SET identity_data = identity_data || jsonb_build_object(
        'email_verified', true,
        'role', 'teacher'
      ),
      updated_at = now()
  WHERE user_id = teacher_user_id
    AND provider = 'email';

  INSERT INTO public.profiles (id, email, role)
  VALUES (teacher_user_id, normalized_email, 'teacher')
  ON CONFLICT (id) DO UPDATE
  SET email = excluded.email,
      role = 'teacher';

  DELETE FROM public.children
  WHERE auth_user_id = teacher_user_id
     OR lower(email) = normalized_email;

  INSERT INTO public.teachers (email, password)
  VALUES (normalized_email, teacher_password)
  ON CONFLICT (email) DO UPDATE
  SET password = excluded.password;

  RETURN jsonb_build_object('email', normalized_email, 'role', 'teacher');
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_teacher_account(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_teacher_account(text, text) TO authenticated;
