-- 檢查假人帳號是否存在的查詢

-- 1. 檢查 profiles 表中的假人帳號
SELECT id, email, username, display_name, bio 
FROM public.profiles 
WHERE username IN (
    'maya_music',
    'nell_astral', 
    'tairitsu_dark',
    'ayu_desire',
    'luna_singularity',
    'eto_fast'
)
ORDER BY username;

-- 2. 檢查 auth.users 表中的假人帳號（需要 service_role 權限）
SELECT id, email, email_confirmed_at, created_at
FROM auth.users 
WHERE email IN (
    'maya_music@dummy.test',
    'nell_astral@dummy.test', 
    'tairitsu_dark@dummy.test',
    'ayu_desire@dummy.test',
    'luna_singularity@dummy.test',
    'eto_fast@dummy.test'
)
ORDER BY email;

-- 3. 檢查現有的 friendships
SELECT 
    f.id,
    f.status,
    u1.username as user_username,
    u2.username as friend_username,
    f.created_at
FROM public.friendships f
LEFT JOIN public.profiles u1 ON f.user_id = u1.id
LEFT JOIN public.profiles u2 ON f.friend_id = u2.id
ORDER BY f.created_at DESC
LIMIT 20;

-- 4. 檢查 trigger 是否存在
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_accept_dummy_friends';
