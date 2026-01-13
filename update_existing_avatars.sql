-- 更新現有用戶的頭像（從 auth.users 的 raw_user_meta_data 提取）
-- 這會更新所有 avatar_url 為 NULL 的用戶

UPDATE public.profiles p
SET 
  avatar_url = COALESCE(
    u.raw_user_meta_data->>'avatar_url',
    u.raw_user_meta_data->>'picture',
    u.raw_user_meta_data->>'photo_url'
  ),
  updated_at = NOW()
FROM auth.users u
WHERE p.id = u.id
  AND p.avatar_url IS NULL
  AND (
    u.raw_user_meta_data->>'avatar_url' IS NOT NULL OR
    u.raw_user_meta_data->>'picture' IS NOT NULL OR
    u.raw_user_meta_data->>'photo_url' IS NOT NULL
  );

-- 顯示更新結果
SELECT 
  email,
  username,
  display_name,
  avatar_url
FROM public.profiles
WHERE avatar_url IS NOT NULL
ORDER BY created_at DESC;
