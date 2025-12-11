-- PawPrint 数据库表结构
-- 用于 Supabase PostgreSQL

-- ============================================
-- 1. 用户宠物档案表
-- ============================================
CREATE TABLE pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,  -- Dog, Cat, Bird, Rabbit, Fish, Other
    breed VARCHAR(100) DEFAULT 'Unknown',
    age_months INTEGER DEFAULT 0,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female')),
    weight_kg DECIMAL(5,2) DEFAULT 0,
    is_neutered BOOLEAN DEFAULT FALSE,
    allergies TEXT,
    avatar_url TEXT,  -- 存储在 Supabase Storage 的 URL
    coins INTEGER DEFAULT 200,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 每个用户可以有多个宠物，创建索引加速查询
CREATE INDEX idx_pets_user_id ON pets(user_id);

-- ============================================
-- 2. 宠物身体部位基线照片表
-- ============================================
CREATE TABLE pet_body_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
    body_part VARCHAR(50) NOT NULL,  -- Eyes, Ears, Mouth & Teeth, Paws, Skin & Fur, Other
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pet_id, body_part)  -- 每个部位只保存一张基线照片
);

CREATE INDEX idx_pet_body_images_pet_id ON pet_body_images(pet_id);

-- ============================================
-- 3. 宠物 ID 卡片表
-- ============================================
CREATE TABLE pet_id_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL UNIQUE,
    style VARCHAR(20) CHECK (style IN ('Cute', 'Cool', 'Pixel')),
    cartoon_image_url TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',  -- PostgreSQL 数组类型
    description TEXT,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. 收藏卡牌表
-- ============================================
CREATE TABLE collectible_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(100) NOT NULL,
    image_url TEXT NOT NULL,
    description TEXT,
    rarity VARCHAR(20) CHECK (rarity IN ('Common', 'Rare', 'Epic', 'Legendary')),
    theme VARCHAR(20) CHECK (theme IN ('Daily', 'Profile', 'Fun', 'Sticker')),
    tags TEXT[] DEFAULT '{}',
    obtained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_collectible_cards_pet_id ON collectible_cards(pet_id);

-- ============================================
-- 5. 健康记录表
-- ============================================
CREATE TABLE health_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
    record_type VARCHAR(50) NOT NULL,  -- Weight, Vaccine, Symptom, Checkup, Activity, Medication, Grooming, Food
    record_date DATE NOT NULL,
    value VARCHAR(100),  -- 体重数值、食物量等
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_health_records_pet_id ON health_records(pet_id);
CREATE INDEX idx_health_records_date ON health_records(record_date DESC);

-- ============================================
-- 6. AI 分析会话表
-- ============================================
CREATE TABLE ai_analysis_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
    symptoms TEXT NOT NULL,
    body_part VARCHAR(50) NOT NULL,
    image_url TEXT,  -- 可选的当前症状图片
    analysis_result TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ai_sessions_pet_id ON ai_analysis_sessions(pet_id);

-- ============================================
-- 7. 提醒/预约表
-- ============================================
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(200) NOT NULL,
    reminder_type VARCHAR(50) CHECK (reminder_type IN ('Medication', 'Appointment', 'Grooming', 'Other')),
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_reminders_pet_id ON reminders(pet_id);
CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_at);

-- ============================================
-- 8. 论坛帖子表
-- ============================================
CREATE TABLE forum_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    author_avatar VARCHAR(10),  -- emoji 头像
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Question', 'Tip', 'Story', 'Emergency')),
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_forum_posts_user_id ON forum_posts(user_id);
CREATE INDEX idx_forum_posts_category ON forum_posts(category);
CREATE INDEX idx_forum_posts_created ON forum_posts(created_at DESC);

-- ============================================
-- 9. 论坛评论表
-- ============================================
CREATE TABLE forum_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_forum_comments_post_id ON forum_comments(post_id);

-- ============================================
-- 10. 帖子点赞表 (防止重复点赞)
-- ============================================
CREATE TABLE forum_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- ============================================
-- 触发器：自动更新 updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pets_updated_at 
    BEFORE UPDATE ON pets 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 触发器：自动更新帖子的评论数和点赞数
-- ============================================
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE forum_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE forum_posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_comments_count
    AFTER INSERT OR DELETE ON forum_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_post_comments_count();

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE forum_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE forum_posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_likes_count
    AFTER INSERT OR DELETE ON forum_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

-- ============================================
-- Row Level Security (RLS) 策略
-- 确保用户只能访问自己的数据
-- ============================================

-- 启用 RLS
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_body_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_id_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE collectible_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_analysis_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_likes ENABLE ROW LEVEL SECURITY;

-- Pets: 用户只能操作自己的宠物
CREATE POLICY "Users can view own pets" ON pets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own pets" ON pets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own pets" ON pets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own pets" ON pets FOR DELETE USING (auth.uid() = user_id);

-- Pet Body Images: 通过 pet_id 关联到用户
CREATE POLICY "Users can manage own pet body images" ON pet_body_images 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- Pet ID Cards
CREATE POLICY "Users can manage own pet id cards" ON pet_id_cards 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- Collectible Cards
CREATE POLICY "Users can manage own collectible cards" ON collectible_cards 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- Health Records
CREATE POLICY "Users can manage own health records" ON health_records 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- AI Analysis Sessions
CREATE POLICY "Users can manage own ai sessions" ON ai_analysis_sessions 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- Reminders
CREATE POLICY "Users can manage own reminders" ON reminders 
    FOR ALL USING (pet_id IN (SELECT id FROM pets WHERE user_id = auth.uid()));

-- Forum Posts: 所有人可以查看，只有作者可以修改/删除
CREATE POLICY "Anyone can view forum posts" ON forum_posts FOR SELECT USING (true);
CREATE POLICY "Users can insert own posts" ON forum_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON forum_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON forum_posts FOR DELETE USING (auth.uid() = user_id);

-- Forum Comments: 所有人可以查看，只有作者可以修改/删除
CREATE POLICY "Anyone can view comments" ON forum_comments FOR SELECT USING (true);
CREATE POLICY "Users can insert own comments" ON forum_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON forum_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON forum_comments FOR DELETE USING (auth.uid() = user_id);

-- Forum Likes: 所有人可以查看，用户只能管理自己的点赞
CREATE POLICY "Anyone can view likes" ON forum_likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON forum_likes FOR ALL USING (auth.uid() = user_id);
