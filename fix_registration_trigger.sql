-- 徹底修復註冊問題：完整重建 profiles 表和 trigger
-- 這個腳本會檢查並修復所有可能的問題

-- ========================================
-- 第一部分：檢查現有結構
-- ========================================

-- 檢查 profiles 表是否存在以及其結構
DO $$ 
BEGIN
    -- 如果 profiles 表不存在，創建它
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        CREATE TABLE public.profiles (
            id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
            username TEXT,
            display_name TEXT,
            avatar_url TEXT,
            bio TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- 啟用 RLS
        ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
        
        -- 創建 RLS 政策
        CREATE POLICY "Users can view their own profile" 
            ON public.profiles FOR SELECT 
            USING (auth.uid() = id);
        
        CREATE POLICY "Users can update their own profile" 
            ON public.profiles FOR UPDATE 
            USING (auth.uid() = id);
            
        RAISE NOTICE '✅ profiles 表已創建';
    ELSE
        -- 表存在，確保欄位結構正確
        -- 移除 username 的 NOT NULL 限制（如果有的話）
        BEGIN
            ALTER TABLE public.profiles ALTER COLUMN username DROP NOT NULL;
            RAISE NOTICE '✅ username 欄位 NOT NULL 限制已移除';
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE '⚠️ username 欄位可能已經允許 NULL';
        END;
        
        -- 設置預設值
        ALTER TABLE public.profiles ALTER COLUMN created_at SET DEFAULT NOW();
        ALTER TABLE public.profiles ALTER COLUMN updated_at SET DEFAULT NOW();
        
        RAISE NOTICE '✅ profiles 表結構已更新';
    END IF;
END $$;

-- ========================================
-- 第二部分：刪除舊的 trigger 和函數
-- ========================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- ========================================
-- 第三部分：創建新的 trigger 函數
-- ========================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- 記錄日誌（調試用）
    RAISE LOG 'Creating profile for new user: %', NEW.id;
    
    -- 創建 profile（使用 INSERT ... ON CONFLICT 避免重複）
    INSERT INTO public.profiles (
        id,
        username,
        display_name,
        avatar_url,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            NEW.raw_user_meta_data->>'preferred_username',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'name',
            NEW.raw_user_meta_data->>'full_name'
        ),
        NEW.raw_user_meta_data->>'avatar_url',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        updated_at = NOW();
    
    -- 如果 user_stats 表存在，也初始化統計數據
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_stats') THEN
        INSERT INTO public.user_stats (
            user_id,
            total_play_count,
            total_duration,
            favorite_songs_count,
            favorite_artists_count,
            favorite_albums_count,
            last_active_at
        )
        VALUES (
            NEW.id,
            0,
            0,
            0,
            0,
            0,
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN others THEN
        -- 記錄錯誤但不阻止用戶創建
        RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- ========================================
-- 第四部分：創建 trigger
-- ========================================

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 第五部分：修復現有用戶（補上缺失的 profiles）
-- ========================================

INSERT INTO public.profiles (id, username, display_name, avatar_url, created_at, updated_at)
SELECT 
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'username',
        au.raw_user_meta_data->>'preferred_username',
        split_part(au.email, '@', 1)
    ),
    COALESCE(
        au.raw_user_meta_data->>'display_name',
        au.raw_user_meta_data->>'name',
        au.raw_user_meta_data->>'full_name'
    ),
    au.raw_user_meta_data->>'avatar_url',
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- 完成通知
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '✅ 所有修復完成！';
    RAISE NOTICE '📊 現有用戶數: %', (SELECT COUNT(*) FROM auth.users);
    RAISE NOTICE '📊 Profiles 數: %', (SELECT COUNT(*) FROM public.profiles);
END $$;

