-- 簡化版本：只創建 profiles 表數據
-- 這些假人帳號需要先在 Supabase Dashboard 手動註冊，或使用下面的腳本

-- 方法 1：透過 Supabase Dashboard 手動註冊
-- 前往 Authentication > Users，點擊 "Add user"
-- 為每個假人創建帳號：
-- Email: maya_music@dummy.test, Password: dummy_password
-- Email: nell_astral@dummy.test, Password: dummy_password
-- Email: tairitsu_dark@dummy.test, Password: dummy_password
-- Email: ayu_desire@dummy.test, Password: dummy_password
-- Email: luna_singularity@dummy.test, Password: dummy_password
-- Email: eto_fast@dummy.test, Password: dummy_password

-- 方法 2：如果 profiles 表有 ON INSERT trigger 自動創建，可以直接插入
-- 否則需要先在 auth.users 創建後，再執行以下更新

-- 更新 profiles 表（假設用戶已在 auth.users 中）
-- 注意：請先在 Supabase Dashboard 註冊這些 email，然後取得他們的真實 UUID
-- 然後更新他們的 profile 資訊

-- 示範：取得已註冊用戶的 ID 並更新 profile
-- 執行前請先在 Authentication > Users 註冊上述 6 個 email

-- 建立查詢來找出這些用戶的 ID
SELECT id, email FROM auth.users 
WHERE email IN (
    'maya_music@dummy.test',
    'nell_astral@dummy.test', 
    'tairitsu_dark@dummy.test',
    'ayu_desire@dummy.test',
    'luna_singularity@dummy.test',
    'eto_fast@dummy.test'
);

-- 之後手動更新 profiles 表：
-- UPDATE public.profiles SET username = 'maya_music', display_name = 'Maya', bio = 'Loves Abstruse Dilemma 🎵' WHERE email = 'maya_music@dummy.test';
-- UPDATE public.profiles SET username = 'nell_astral', display_name = 'Nell', bio = 'Astral Quantization fan 🌌' WHERE email = 'nell_astral@dummy.test';
-- UPDATE public.profiles SET username = 'tairitsu_dark', display_name = 'Tairitsu', bio = 'Grevious Lady enthusiast 🖤' WHERE email = 'tairitsu_dark@dummy.test';
-- UPDATE public.profiles SET username = 'ayu_desire', display_name = 'Ayu', bio = 'Dancing to Désive 💃' WHERE email = 'ayu_desire@dummy.test';
-- UPDATE public.profiles SET username = 'luna_singularity', display_name = 'Luna', bio = 'Singularity seeker 🌙' WHERE email = 'luna_singularity@dummy.test';
-- UPDATE public.profiles SET username = 'eto_fast', display_name = 'Eto', bio = 'Live Fast Die Young 🏃‍♀️' WHERE email = 'eto_fast@dummy.test';
