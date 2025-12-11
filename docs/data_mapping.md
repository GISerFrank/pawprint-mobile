# PawPrint 数据结构映射

## 原 TypeScript 类型 → Supabase 表对照

### 1. PetProfile → `pets` + 关联表

| TypeScript 字段 | 数据库表/字段 | 说明 |
|----------------|--------------|------|
| `id` | `pets.id` | UUID |
| `name` | `pets.name` | |
| `species` | `pets.species` | |
| `breed` | `pets.breed` | |
| `age` | `pets.age_months` | |
| `gender` | `pets.gender` | |
| `weight` | `pets.weight_kg` | |
| `neutered` | `pets.is_neutered` | |
| `allergies` | `pets.allergies` | |
| `avatarImage` | `pets.avatar_url` | 存 Storage URL |
| `coins` | `pets.coins` | |
| `bodyPartImages` | `pet_body_images` 表 | 一对多关系 |
| `idCard` | `pet_id_cards` 表 | 一对一关系 |
| `collection` | `collectible_cards` 表 | 一对多关系 |

### 2. HealthRecord → `health_records`

| TypeScript 字段 | 数据库字段 |
|----------------|-----------|
| `id` | `id` |
| `date` | `record_date` |
| `type` | `record_type` |
| `value` | `value` |
| `note` | `note` |

### 3. AIAnalysisSession → `ai_analysis_sessions`

| TypeScript 字段 | 数据库字段 |
|----------------|-----------|
| `id` | `id` |
| `date` | `created_at` |
| `symptoms` | `symptoms` |
| `relatedBodyPart` | `body_part` |
| `imageBase64` | `image_url` (存 Storage URL) |
| `analysisResult` | `analysis_result` |

### 4. Reminder → `reminders`

| TypeScript 字段 | 数据库字段 |
|----------------|-----------|
| `id` | `id` |
| `title` | `title` |
| `date` | `scheduled_at` |
| `type` | `reminder_type` |
| `completed` | `is_completed` |

### 5. ForumPost → `forum_posts`

| TypeScript 字段 | 数据库字段 |
|----------------|-----------|
| `id` | `id` |
| `authorName` | `author_name` |
| `authorAvatar` | `author_avatar` |
| `title` | `title` |
| `content` | `content` |
| `category` | `category` |
| `likes` | `likes_count` (自动计算) |
| `comments` | `comments_count` (自动计算) |
| `date` | `created_at` |
| `isUserPost` | 前端根据 `user_id` 判断 |
| `replies` | `forum_comments` 表关联查询 |

### 6. Comment → `forum_comments`

| TypeScript 字段 | 数据库字段 |
|----------------|-----------|
| `id` | `id` |
| `authorName` | `author_name` |
| `text` | `content` |
| `date` | `created_at` |
| `isUserComment` | 前端根据 `user_id` 判断 |

---

## 枚举值约束

### BodyPart
- Eyes, Ears, Mouth & Teeth, Paws, Skin & Fur, Other

### HealthRecordType
- Weight, Vaccine, Symptom, Checkup, Activity, Medication, Grooming, Food

### ReminderType
- Medication, Appointment, Grooming, Other

### IDCardStyle
- Cute, Cool, Pixel

### Rarity
- Common, Rare, Epic, Legendary

### PackTheme
- Daily, Profile, Fun, Sticker

### ForumCategory
- Question, Tip, Story, Emergency

---

## Supabase Storage Buckets

需要创建以下存储桶：

| Bucket 名称 | 用途 | 访问权限 |
|------------|------|---------|
| `pet-avatars` | 宠物头像 | 公开读取 |
| `pet-body-images` | 身体部位基线照片 | 私有 |
| `pet-id-cards` | AI 生成的卡通头像 | 公开读取 |
| `collectible-cards` | 收藏卡牌图片 | 公开读取 |
| `ai-analysis-images` | AI 分析时上传的照片 | 私有 |

---

## 数据关系图

```
auth.users (Supabase 内置)
    │
    ├── 1:N ── pets
    │            │
    │            ├── 1:N ── pet_body_images
    │            ├── 1:1 ── pet_id_cards
    │            ├── 1:N ── collectible_cards
    │            ├── 1:N ── health_records
    │            ├── 1:N ── ai_analysis_sessions
    │            └── 1:N ── reminders
    │
    ├── 1:N ── forum_posts
    │            │
    │            ├── 1:N ── forum_comments
    │            └── 1:N ── forum_likes
    │
    └── 1:N ── forum_comments
```
