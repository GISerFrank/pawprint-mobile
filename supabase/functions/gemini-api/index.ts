// Supabase Edge Function: Gemini API 中转
// 部署命令: supabase functions deploy gemini-api

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.1.3"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 从环境变量获取 Gemini API Key
const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') || '')

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { action, payload } = await req.json()

    let result: any

    switch (action) {
      case 'analyze_health':
        result = await analyzeHealth(payload)
        break
      case 'generate_personality':
        result = await generatePersonality(payload)
        break
      case 'generate_cartoon':
        result = await generateCartoon(payload)
        break
      case 'generate_collectible_card':
        result = await generateCollectibleCard(payload)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(
      JSON.stringify({ success: true, data: result }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// ============================================
// AI 功能实现
// ============================================

const HEALTH_SYSTEM_INSTRUCTION = `
You are PetGuard AI, a compassionate and knowledgeable veterinary assistant AI. 
Your goal is to help pet owners understand their pet's health based on provided details and images.

Guidance:
1. Analyze the provided image (if any) specifically looking for signs of inflammation, infection, injury, or parasites related to the specified body part.
2. Correlate visual findings with the described symptoms.
3. Provide a structured response:
   - **Observation**: What you see in the image and understand from the text.
   - **Potential Causes**: List 2-3 possible reasons (e.g., allergies, infection, trauma).
   - **Recommendation**: Immediate home care steps (if safe) and when to see a vet (e.g., "Monitor for 24h" vs "Emergency").
4. **Tone**: Calm, professional, but empathetic.
5. **Disclaimer**: ALWAYS end with: "Disclaimer: I am an AI, not a veterinarian. This analysis is for informational purposes only and does not replace professional veterinary advice."
`

interface HealthPayload {
  symptoms: string
  bodyPart: string
  currentImageBase64?: string
  baselineImageBase64?: string
}

async function analyzeHealth(payload: HealthPayload): Promise<string> {
  const { symptoms, bodyPart, currentImageBase64, baselineImageBase64 } = payload

  const model = genAI.getGenerativeModel({ 
    model: "gemini-2.5-flash",
    systemInstruction: HEALTH_SYSTEM_INSTRUCTION
  })

  const parts: any[] = []

  let promptText = `Analyze the health of a pet's ${bodyPart}.\n\nSymptoms described: ${symptoms}`

  if (baselineImageBase64) {
    promptText += `\n\nI have provided two images. The first image is the BASELINE (healthy) image from their profile. The second image is the CURRENT condition. Please compare them if possible to identify changes.`
    parts.push({
      inlineData: {
        mimeType: "image/jpeg",
        data: baselineImageBase64.replace(/^data:image\/\w+;base64,/, '')
      }
    })
  }

  if (currentImageBase64) {
    parts.push({
      inlineData: {
        mimeType: "image/jpeg",
        data: currentImageBase64.replace(/^data:image\/\w+;base64,/, '')
      }
    })
  } else {
    promptText += `\n\n(No current image provided, please analyze based on text description only.)`
  }

  parts.push({ text: promptText })

  const result = await model.generateContent(parts)
  const response = await result.response
  return response.text() || "Sorry, I could not generate an analysis at this time."
}

interface PersonalityPayload {
  imageBase64: string
}

async function generatePersonality(payload: PersonalityPayload): Promise<{ tags: string[], description: string }> {
  const { imageBase64 } = payload

  const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })

  const result = await model.generateContent([
    {
      inlineData: {
        mimeType: "image/jpeg",
        data: imageBase64.replace(/^data:image\/\w+;base64,/, '')
      }
    },
    {
      text: `Analyze this pet's appearance and generate a fun, whimsical personality profile.
      
      Return a JSON object with:
      - tags: array of 3 short, fun personality adjectives (e.g. 'Sassy', 'Cuddly', 'Speedster')
      - description: a short, 1-sentence whimsical description of this pet's vibe
      
      Return ONLY valid JSON, no markdown.`
    }
  ])

  const response = await result.response
  const text = response.text() || '{}'
  
  try {
    // 清理可能的 markdown 标记
    const cleanJson = text.replace(/```json\n?|\n?```/g, '').trim()
    return JSON.parse(cleanJson)
  } catch {
    return {
      tags: ["Mystery", "Cute", "Unknown"],
      description: "A mysterious and lovely friend."
    }
  }
}

interface CartoonPayload {
  imageBase64: string
  style: 'Cute' | 'Cool' | 'Pixel'
}

async function generateCartoon(payload: CartoonPayload): Promise<string | null> {
  const { imageBase64, style } = payload

  let stylePrompt = ""
  switch (style) {
    case 'Cool':
      stylePrompt = "cyberpunk character, cool neon lighting, sunglasses, bold vector art"
      break
    case 'Pixel':
      stylePrompt = "pixel art character, 8-bit retro game style, blocky, vibrant colors"
      break
    case 'Cute':
    default:
      stylePrompt = "adorable disney pixar style 3d character, soft lighting, cute big eyes"
      break
  }

  const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-preview-native-audio-dialog" })

  try {
    const result = await model.generateContent([
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBase64.replace(/^data:image\/\w+;base64,/, '')
        }
      },
      {
        text: `Turn this image into a ${stylePrompt}. Maintain the fur color and breed characteristics. High quality, solid background.`
      }
    ])

    const response = await result.response
    
    for (const part of response.candidates?.[0]?.content?.parts || []) {
      if (part.inlineData) {
        return `data:image/png;base64,${part.inlineData.data}`
      }
    }
    return null
  } catch (error) {
    console.error("Cartoon generation error:", error)
    return null
  }
}

interface CollectibleCardPayload {
  imageBase64: string
  theme: 'Daily' | 'Profile' | 'Fun' | 'Sticker'
  species: string
}

async function generateCollectibleCard(payload: CollectibleCardPayload): Promise<{
  name: string
  description: string
  rarity: string
  tags: string[]
  image: string | null
} | null> {
  const { imageBase64, theme, species } = payload

  // 1. 生成元数据
  const textModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })

  const textPrompt = `Generate a creative collectible card metadata for a ${species} in a "${theme}" theme.
  Themes:
  - Daily: Slice of life, cozy.
  - Profile: Heroic, best angle.
  - Fun: Silly, costumes, playing.
  - Sticker: Pop art, bold outlines.
  
  Return a JSON object with:
  - name: Creative card title
  - description: Fun flavor text
  - rarity: One of 'Common', 'Rare', 'Epic', 'Legendary'
  - tags: Array of 2-3 short tags
  
  Return ONLY valid JSON, no markdown.`

  const metadataResult = await textModel.generateContent(textPrompt)
  const metadataText = (await metadataResult.response).text() || '{}'
  
  let metadata: any
  try {
    const cleanJson = metadataText.replace(/```json\n?|\n?```/g, '').trim()
    metadata = JSON.parse(cleanJson)
  } catch {
    metadata = {
      name: `${theme} Card`,
      description: "A special card for your collection.",
      rarity: "Common",
      tags: []
    }
  }

  // 2. 生成卡牌图片
  let artPrompt = ""
  switch(theme) {
    case 'Daily': 
      artPrompt = `Turn this image into a cute illustration of the ${species} in a cozy, daily life setting (e.g. sleeping on a cloud, eating). Soft pastel colors, heartwarming style.`
      break
    case 'Fun': 
      artPrompt = `Turn this image into a funny cartoon of the ${species} doing something silly (e.g. wearing a hat, playing). Vibrant colors, joyful expression.`
      break
    case 'Sticker': 
      artPrompt = `Turn this image into a pop-art sticker design of the ${species}. Bold thick white outline, bright flat colors, simple background.`
      break
    case 'Profile': 
    default: 
      artPrompt = `Turn this image into an epic, heroic portrait of the ${species}. Cinematic lighting, detailed digital art, majestic pose.`
      break
  }

  try {
    const imageModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash-preview-native-audio-dialog" })
    
    const imageResult = await imageModel.generateContent([
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBase64.replace(/^data:image\/\w+;base64,/, '')
        }
      },
      { text: artPrompt }
    ])

    const imageResponse = await imageResult.response
    let cardImage: string | null = null

    for (const part of imageResponse.candidates?.[0]?.content?.parts || []) {
      if (part.inlineData) {
        cardImage = `data:image/png;base64,${part.inlineData.data}`
      }
    }

    return {
      name: metadata.name,
      description: metadata.description,
      rarity: metadata.rarity,
      tags: metadata.tags || [],
      image: cardImage
    }
  } catch (error) {
    console.error("Card image generation error:", error)
    return null
  }
}
