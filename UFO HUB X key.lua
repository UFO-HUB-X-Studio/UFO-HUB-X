-- UFO HUB X key.lua (ตัวอย่าง UI ง่ายๆ)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- ป้องกันการซ้ำซ้อน: ถ้ามี UI เก่าให้ลบทิ้งก่อน
pcall(function()
    local existing = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("UFOHubX_KeyUI_Example")
    if existing then existing:Destroy() end
end)

-- สร้าง ScreenGui พื้นฐาน
local screen = Instance.new("ScreenGui")
screen.Name = "UFOHubX_KeyUI_Example"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0,420,0,180)
frame.Position = UDim2.new(0.5,-210,0.4,-90)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Name = "MainFrame"
frame.AnchorPoint = Vector2.new(0.5,0.5)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.Position = UDim2.new(0,0,0,0)
title.Text = "UFO HUB X — ENTER KEY"
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold

local txt = Instance.new("TextBox", frame)
txt.Size = UDim2.new(1,-40,0,44)
txt.Position = UDim2.new(0,20,0,52)
txt.PlaceholderText = "ใส่คีย์ที่นี่"
txt.ClearTextOnFocus = false
txt.Text = ""
txt.TextColor3 = Color3.fromRGB(240,240,240)
txt.BackgroundColor3 = Color3.fromRGB(35,35,35)
txt.TextScaled = false
txt.Font = Enum.Font.SourceSans
txt.TextSize = 20

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0,140,0,40)
btn.Position = UDim2.new(0.5,-70,0,112)
btn.Text = "ยืนยัน (Submit)"
btn.Font = Enum.Font.SourceSansBold
btn.TextScaled = true
btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.AutoButtonColor = true

local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1,-20,0,18)
info.Position = UDim2.new(0,10,0,150)
info.Text = "หากกดแล้วไม่มีผล ให้ตรวจสอบคอนโซล/การเชื่อมต่อ HTTP"
info.TextScaled = false
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(180,180,180)
info.Font = Enum.Font.SourceSansItalic
info.TextSize = 14

-- เมื่อกดปุ่ม ให้เรียก callback สากล (ถ้ามี) แล้วปิด UI
btn.MouseButton1Click:Connect(function()
    local key = tostring(txt.Text or ""):gsub("%s+","")
    if #key == 0 then
        btn.Text = "กรอกคีย์ก่อน"
        task.delay(1.0, function() if btn and btn.Parent then btn.Text = "ยืนยัน (Submit)" end end)
        return
    end
    -- ถ้ามีฟังก์ชัน UFO_SaveKeyState ให้เรียกเพื่อบันทึก
    if _G and type(_G.UFO_SaveKeyState)=="function" then
        -- ตัวอย่าง: บันทึกแบบ non-permanent, no expiry
        _G.UFO_SaveKeyState(key, nil, false)
        btn.Text = "✅ Key submitted"
        task.delay(0.6, function() if screen and screen.Parent then screen:Destroy() end end)
    else
        -- ถ้าไม่มี ให้แสดงข้อความ error (เพื่อ debug)
        btn.Text = "No SAVE FUNC"
        task.delay(1.2, function() if btn and btn.Parent then btn.Text = "ยืนยัน (Submit)" end end)
    end
end)
