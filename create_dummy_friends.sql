-- 創建假人好友帳號
-- 這些是用於測試好友系統的示範帳號

-- 首先，需要在 auth.users 中創建這些假用戶（這部分需要透過 Supabase Dashboard 或 Auth API）
-- 這裡我們假設已經有這些 user IDs，直接插入到 profiles 表

-- 為了測試，我們先創建一些隨機的 UUID
-- 實際使用時，這些應該是真實註冊用戶的 auth.users ID

-- 在 auth.users 中創建假用戶（需要 service_role 權限）
INSERT INTO auth.users (
    id, 
    instance_id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    created_at, 
    updated_at, 
    raw_app_meta_data, 
    raw_user_meta_data,
    aud,
    role
)
VALUES 
    ('11111111-1111-1111-1111-111111111111'::uuid, '00000000-0000-0000-0000-000000000000', 'maya_music@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
    ('22222222-2222-2222-2222-222222222222'::uuid, '00000000-0000-0000-0000-000000000000', 'nell_astral@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
    ('33333333-3333-3333-3333-333333333333'::uuid, '00000000-0000-0000-0000-000000000000', 'tairitsu_dark@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
    ('44444444-4444-4444-4444-444444444444'::uuid, '00000000-0000-0000-0000-000000000000', 'ayu_desire@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
    ('55555555-5555-5555-5555-555555555555'::uuid, '00000000-0000-0000-0000-000000000000', 'luna_singularity@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
    ('66666666-6666-6666-6666-666666666666'::uuid, '00000000-0000-0000-0000-000000000000', 'eto_fast@dummy.test', crypt('dummy_password', gen_salt('bf')), NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- 現在插入到 profiles 表
INSERT INTO public.profiles (id, email, username, display_name, avatar_url, bio, created_at, updated_at)
VALUES 
    -- Maya
    ('11111111-1111-1111-1111-111111111111'::uuid, 'maya_music@dummy.test', 'maya_music', 'Maya', 'assets/friend_pfp/Ellipse 54.png', 'Loves Abstruse Dilemma 🎵', NOW(), NOW()),
    
    -- Nell
    ('22222222-2222-2222-2222-222222222222'::uuid, 'nell_astral@dummy.test', 'nell_astral', 'Nell', 'assets/friend_pfp/Ellipse 54-1.png', 'Astral Quantization fan 🌌', NOW(), NOW()),
    
    -- Tairitsu
    ('33333333-3333-3333-3333-333333333333'::uuid, 'tairitsu_dark@dummy.test', 'tairitsu_dark', 'Tairitsu', 'assets/friend_pfp/Ellipse 54-2.png', 'Grevious Lady enthusiast 🖤', NOW(), NOW()),
    
    -- Ayu
    ('44444444-4444-4444-4444-444444444444'::uuid, 'ayu_desire@dummy.test', 'ayu_desire', 'Ayu', 'assets/friend_pfp/Ellipse 54-3.png', 'Dancing to Désive 💃', NOW(), NOW()),
    
    -- Luna
    ('55555555-5555-5555-5555-555555555555'::uuid, 'luna_singularity@dummy.test', 'luna_singularity', 'Luna', 'assets/friend_pfp/Ellipse 54-4.png', 'Singularity seeker 🌙', NOW(), NOW()),
    
    -- Eto
    ('66666666-6666-6666-6666-666666666666'::uuid, 'eto_fast@dummy.test', 'eto_fast', 'Eto', 'assets/friend_pfp/Ellipse 54-5.png', 'Live Fast Die Young 🏃‍♀️', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url,
    bio = EXCLUDED.bio,
    updated_at = NOW();

-- 創建好友關係表（如果還沒有的話）
CREATE TABLE IF NOT EXISTS public.friendships (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, accepted, rejected
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id) -- 不能加自己為好友
);

-- 啟用 RLS
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- 刪除舊的 policies（如果存在）
DROP POLICY IF EXISTS "Users can view their friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can create friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can update received friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete their friendships" ON public.friendships;

-- 創建 RLS 政策：用戶可以查看與自己相關的好友關係
CREATE POLICY "Users can view their friendships" 
    ON public.friendships FOR SELECT 
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- 用戶可以創建好友請求
CREATE POLICY "Users can create friendships" 
    ON public.friendships FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- 用戶可以更新自己收到的好友請求
CREATE POLICY "Users can update received friendships" 
    ON public.friendships FOR UPDATE 
    USING (auth.uid() = friend_id);

-- 用戶可以刪除自己的好友關係
CREATE POLICY "Users can delete their friendships" 
    ON public.friendships FOR DELETE 
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- 創建索引以提高查詢效能
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- 創建假人帳號的自動接受好友邀請功能
-- 當有人向假人帳號發送好友邀請時，自動接受
CREATE OR REPLACE FUNCTION auto_accept_dummy_friend_requests()
RETURNS TRIGGER AS $$
DECLARE
    dummy_ids UUID[] := ARRAY[
        '11111111-1111-1111-1111-111111111111'::uuid,
        '22222222-2222-2222-2222-222222222222'::uuid,
        '33333333-3333-3333-3333-333333333333'::uuid,
        '44444444-4444-4444-4444-444444444444'::uuid,
        '55555555-5555-5555-5555-555555555555'::uuid,
        '66666666-6666-6666-6666-666666666666'::uuid
    ];
BEGIN
    -- 如果 friend_id 是假人帳號，自動接受
    IF NEW.friend_id = ANY(dummy_ids) AND NEW.status = 'pending' THEN
        NEW.status := 'accepted';
        RAISE NOTICE '✅ 假人帳號自動接受好友邀請：% -> %', NEW.user_id, NEW.friend_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建 trigger（如果已存在則先刪除）
DROP TRIGGER IF EXISTS trigger_auto_accept_dummy_friends ON public.friendships;

CREATE TRIGGER trigger_auto_accept_dummy_friends
    BEFORE INSERT ON public.friendships
    FOR EACH ROW
    EXECUTE FUNCTION auto_accept_dummy_friend_requests();

-- 顯示成功訊息
DO $$ 
BEGIN
    RAISE NOTICE '✅ 假人好友帳號已創建！';
    RAISE NOTICE '✅ 自動接受好友邀請功能已啟用！';
    RAISE NOTICE '';
    RAISE NOTICE '帳號 ID 列表：';
    RAISE NOTICE 'Maya: 11111111-1111-1111-1111-111111111111';
    RAISE NOTICE 'Nell: 22222222-2222-2222-2222-222222222222';
    RAISE NOTICE 'Tairitsu: 33333333-3333-3333-3333-333333333333';
    RAISE NOTICE 'Ayu: 44444444-4444-4444-4444-444444444444';
    RAISE NOTICE 'Luna: 55555555-5555-5555-5555-555555555555';
    RAISE NOTICE 'Eto: 66666666-6666-6666-6666-666666666666';
    RAISE NOTICE '';
    RAISE NOTICE '提示：在應用中使用這些 username 來搜尋好友：';
    RAISE NOTICE 'maya_music, nell_astral, tairitsu_dark, ayu_desire, luna_singularity, eto_fast';
    RAISE NOTICE '';
    RAISE NOTICE '💡 這些假人帳號會自動接受所有好友邀請！';
END $$;
