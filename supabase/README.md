# Supabase 项目配置说明

## 1. 初始化 Supabase CLI

```bash
# 安装 Supabase CLI (macOS)
brew install supabase/tap/supabase

# 登录
supabase login

# 链接到你的项目
supabase link --project-ref <your-project-ref>
```

## 2. 设置 Edge Function 环境变量

在 Supabase Dashboard → Settings → Edge Functions → 添加 Secret:

| Name | Value |
|------|-------|
| `GEMINI_API_KEY` | 你的 Gemini API Key |

或使用 CLI:
```bash
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

## 3. 部署 Edge Function

```bash
cd pawprint/supabase
supabase functions deploy gemini-api
```

## 4. 测试 Edge Function

```bash
curl -X POST 'https://<project-ref>.supabase.co/functions/v1/gemini-api' \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "generate_personality",
    "payload": {
      "imageBase64": "..."
    }
  }'
```

## 5. Storage Buckets 配置

在 Supabase Dashboard → Storage 创建以下 buckets:

### pet-avatars (公开)
```sql
-- 允许公开访问
CREATE POLICY "Public Access" ON storage.objects 
  FOR SELECT USING (bucket_id = 'pet-avatars');

-- 允许认证用户上传
CREATE POLICY "Authenticated users can upload" ON storage.objects 
  FOR INSERT WITH CHECK (
    bucket_id = 'pet-avatars' 
    AND auth.role() = 'authenticated'
  );

-- 允许用户删除自己上传的文件
CREATE POLICY "Users can delete own files" ON storage.objects 
  FOR DELETE USING (
    bucket_id = 'pet-avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

### pet-body-images (私有)
```sql
-- 只有文件所有者可以访问
CREATE POLICY "Owner access only" ON storage.objects 
  FOR ALL USING (
    bucket_id = 'pet-body-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

### 其他 buckets 类似配置...

## 6. 获取项目凭证

在 Supabase Dashboard → Settings → API 获取:

- **Project URL**: `https://<project-ref>.supabase.co`
- **Anon Key**: 用于客户端
- **Service Role Key**: 仅用于服务端（不要暴露给客户端）

这些值将配置到 Flutter 项目中。
