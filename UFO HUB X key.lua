--========================================================
-- UFO KEY UI — MINIMAL SHOW TEST (ขึ้นชัวร์แบบสั้นที่สุด)
--========================================================

-- รอเกมโหลด + รอ LocalPlayer
pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)
local Players = game:GetService("Players")
local CG      = game:GetService("CoreGui")
local TS      = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local t0 = os.clock()
repeat
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.05)
until (os.clock() - t0) > 10

-- ฟังก์ชัน parent GUI ให้ทนทุก executor
local function safeParent(gui)
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end
    local ok=false
    if gethui then ok = pcall(function() gui.Parent = gethui() end) end
    if (not ok) or (not gui.Parent) then
        ok = pcall(function() gui.Parent = CG end)
    end
    if (not ok) or (not gui.Parent) then
        local pg = LP and (LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui",2))
        if pg then gui.Parent = pg end
    end
end

-- --------- เริ่มสร้าง UI (ชื่อ UFOHubX_KeyUI_Test) ---------
local existing = (gethui and gethui():FindFirstChild("UFOHubX_KeyUI_Test")) or CG:FindFirstChild("UFOHubX_KeyUI_Test")
if existing then pcall(function() existing:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "UFOHubX_KeyUI_Test"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParent(gui)

-- แถบ debug มุมซ้ายบน (เอาไว้ดูว่า UI ถูก mount จริง)
local dbg = Instance.new("TextLabel")
dbg.Name = "UFO_Debug"
dbg.BackgroundTransparency = 1
dbg.TextColor3 = Color3.new(1,1,1)
dbg.Font = Enum.Font.Gotham
dbg.TextSize = 14
dbg.Text = "[UFO TEST] UI mounted"
dbg.Position = UDim2.new(0,8,0,8)
dbg.Size = UDim2.fromOffset(260, 20)
dbg.Parent = gui

-- พาเนลหลัก
local PANEL_W, PANEL_H = 560, 360
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui

local corner = Instance.new("UICorner", panel) corner.CornerRadius = UDim.new(0,18)
local stroke = Instance.new("UIStroke", panel) stroke.Color = Color3.fromRGB(0,255,140) stroke.Transparency = 0.2

-- หัวข้อ
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 26
title.Text = "UFO KEY UI (TEST)"
title.TextColor3 = Color3.fromRGB(0,255,140)
title.Size = UDim2.new(1, -32, 0, 40)
title.Position = UDim2.new(0,16,0,16)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- ปุ่มปิด
local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.fromOffset(36,36)
btnClose.Position = UDim2.new(1,-52,0,16)
btnClose.BackgroundColor3 = Color3.fromRGB(210,35,50)
btnClose.TextColor3 = Color3.new(1,1,1)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 18
btnClose.Text = "X"
btnClose.Parent = panel
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0,10)
btnClose.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)

-- ป้ายสถานะ
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.Text = "สถานะ: รอกรอกคีย์ แล้วกด Submit"
status.TextColor3 = Color3.fromRGB(210,210,210)
status.Size = UDim2.new(1,-32,0,20)
status.Position = UDim2.new(0,16,0,64)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

-- ช่องกรอกคีย์
local keyBox = Instance.new("TextBox")
keyBox.PlaceholderText = "ใส่คีย์ที่นี่ (ทดสอบ)"
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 16
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(235,235,235)
keyBox.BackgroundColor3 = Color3.fromRGB(22,22,22)
keyBox.BorderSizePixel = 0
keyBox.Size = UDim2.new(1,-32,0,42)
keyBox.Position = UDim2.new(0,16,0,100)
keyBox.Parent = panel
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,10)
local keyStroke = Instance.new("UIStroke", keyBox) keyStroke.Color = Color3.fromRGB(0,255,140) keyStroke.Transparency = 0.6

-- ปุ่ม Submit
local btnSubmit = Instance.new("TextButton")
btnSubmit.Text = "🔒  Submit Key"
btnSubmit.Font = Enum.Font.GothamBlack
btnSubmit.TextSize = 18
btnSubmit.TextColor3 = Color3.new(1,1,1)
btnSubmit.AutoButtonColor = false
btnSubmit.BackgroundColor3 = Color3.fromRGB(210,60,60)
btnSubmit.BorderSizePixel = 0
btnSubmit.Size = UDim2.new(1,-32,0,46)
btnSubmit.Position = UDim2.new(0,16,0,152)
btnSubmit.Parent = panel
Instance.new("UICorner", btnSubmit).CornerRadius = UDim.new(0,12)

-- ปุ่ม Get Key (คัดลอกลิงก์)
local btnGetKey = Instance.new("TextButton")
btnGetKey.Text = "🔐  Get Key (Copy Link)"
btnGetKey.Font = Enum.Font.GothamBold
btnGetKey.TextSize = 16
btnGetKey.TextColor3 = Color3.new(1,1,1)
btnGetKey.AutoButtonColor = false
btnGetKey.BackgroundColor3 = Color3.fromRGB(32,32,32)
btnGetKey.BorderSizePixel = 0
btnGetKey.Size = UDim2.new(1,-32,0,40)
btnGetKey.Position = UDim2.new(0,16,0,206)
btnGetKey.Parent = panel
Instance.new("UICorner", btnGetKey).CornerRadius = UDim.new(0,10)
local btnGetStroke = Instance.new("UIStroke", btnGetKey) btnGetStroke.Color = Color3.fromRGB(0,255,140) btnGetStroke.Transparency = 0.5

-- Toast เล็กๆ
local toast = Instance.new("TextLabel")
toast.BackgroundColor3 = Color3.fromRGB(30,30,30)
toast.TextColor3 = Color3.new(1,1,1)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.Text = ""
toast.Visible = false
toast.AnchorPoint = Vector2.new(0.5,0)
toast.Position = UDim2.new(0.5,0,0,12)
toast.Size = UDim2.fromOffset(160,30)
toast.Parent = panel
Instance.new("UICorner", toast).CornerRadius = UDim.new(0,10)

local function showToast(msg, ok)
    toast.Text = msg
    toast.Visible = true
    toast.BackgroundColor3 = ok and Color3.fromRGB(20,120,60) or Color3.fromRGB(150,35,35)
    toast.Size = UDim2.fromOffset(math.max(160,(#msg*8)+28), 30)
    TS:Create(toast, TweenInfo.new(0.08), {BackgroundTransparency=0.05}):Play()
    task.delay(1.1, function()
        TS:Create(toast, TweenInfo.new(0.15), {BackgroundTransparency=1}):Play()
        task.delay(0.16, function() toast.Visible=false toast.BackgroundTransparency=0.15 end)
    end)
end

-- แอนิเมชันเปิด
panel.Position = UDim2.fromScale(0.5,0.5) + UDim2.fromOffset(0,14)
TS:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.fromScale(0.5,0.5)}):Play()

-- ปุ่ม Get Key: แค่คัดลอกลิงก์ตัวอย่าง (ถ้า executor ไม่อนุญาต setclipboard จะ print ให้แทน)
local SERVER_BASE = "https://ufo-hub-x-key-umoq.onrender.com"
btnGetKey.MouseButton1Click:Connect(function()
    local uid = tostring(LP and LP.UserId or "")
    local url = string.format("%s/getkey?uid=%s", SERVER_BASE, HttpService:UrlEncode(uid))
    local copied=false
    if setclipboard then copied = pcall(setclipboard, url) end
    if copied then
        btnGetKey.Text = "✅ Link copied!"
        showToast("คัดลอกลิงก์แล้ว", true)
        task.delay(1.4, function() btnGetKey.Text = "🔐  Get Key (Copy Link)" end)
    else
        print("[UFO TEST] GetKey URL:", url)
        showToast("ดูลิงก์ใน Output", true)
    end
end)

-- ปุ่ม Submit: ทดสอบเฉยๆ ให้ผ่านถ้ากรอกไม่ว่าง
btnSubmit.MouseButton1Click:Connect(function()
    local k = (keyBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if k == "" then
        status.Text = "สถานะ: กรุณาใส่คีย์ก่อน"
        showToast("ยังไม่ใส่คีย์", false)
        TS:Create(btnSubmit, TweenInfo.new(0.06), {Position = btnSubmit.Position + UDim2.fromOffset(-6,0)}):Play()
        task.wait(0.06)
        TS:Create(btnSubmit, TweenInfo.new(0.06), {Position = btnSubmit.Position + UDim2.fromOffset(12,0)}):Play()
        task.wait(0.06)
        TS:Create(btnSubmit, TweenInfo.new(0.06), {Position = btnSubmit.Position + UDim2.fromOffset(-6,0)}):Play()
        return
    end
    -- ผ่านทดสอบ
    btnSubmit.BackgroundColor3 = Color3.fromRGB(120,255,170)
    btnSubmit.TextColor3 = Color3.new(0,0,0)
    btnSubmit.Text = "✅ Key accepted (TEST)"
    status.Text = "สถานะ: ทดสอบผ่าน — UI โผล่เรียบร้อย"
    showToast("ยืนยันสำเร็จ (TEST)", true)
end)

-- watchdog บังคับให้ GUI มองเห็นเสมอ
task.spawn(function()
    while gui do
        if not gui.Parent then safeParent(gui) end
        if gui.Enabled == false then gui.Enabled = true end
        task.wait(0.3)
    end
end)

print("[UFO TEST] Ready. หากไม่เห็น UI ให้ดูใน CoreGui / gethui ว่ามี 'UFOHubX_KeyUI_Test' หรือไม่")
