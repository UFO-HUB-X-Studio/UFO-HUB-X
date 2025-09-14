-- UFO HUB X — Pure Roblox UI (Alien Green) by Max

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- ================= THEME =================
local C = {
    base      = Color3.fromRGB(8,12,8),     -- พื้นหลังหลัก
    panel     = Color3.fromRGB(16,26,18),    -- การ์ด/พาเนล
    hover     = Color3.fromRGB(28,42,34),    -- hover/กด
    text      = Color3.fromRGB(215,230,215),
    subtext   = Color3.fromRGB(160,188,168),
    accent    = Color3.fromRGB(57,255,20),   -- เขียวเรือง
    stroke    = Color3.fromRGB(40,80,50),
    shadowT   = 0.45
}

-- =============== ROOT GUI ===============
local gui = Instance.new("ScreenGui")
gui.Name = "UFOHubX_Pure"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = pg

local dim = Instance.new("Frame")
dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
dim.BackgroundTransparency = 0.4
dim.Size = UDim2.fromScale(1,1)
dim.Visible = true
dim.Parent = gui

-- หน้าต่างหลัก
local win = Instance.new("Frame")
win.Name = "Window"
win.AnchorPoint = Vector2.new(0.5,0.5)
win.Position = UDim2.fromScale(0.5,0.5)
win.Size = UDim2.fromOffset(720,420)
win.BackgroundColor3 = C.base
win.BorderSizePixel = 0
win.Parent = gui

local corner = Instance.new("UICorner", win)
corner.CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke", win)
stroke.Color = C.stroke
stroke.Thickness = 1
stroke.Transparency = 0.2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- เงา
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5,0.5)
shadow.Position = UDim2.fromScale(0.5,0.5)
shadow.Size = UDim2.new(1,40,1,40)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageTransparency = C.shadowT
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24,24,276,276)
shadow.ZIndex = 0
shadow.Parent = win

-- =============== TITLE BAR ===============
local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1,0,0,40)
top.BackgroundColor3 = C.base
top.BorderSizePixel = 0
top.Parent = win

local topStroke = Instance.new("UIStroke", top)
topStroke.Color = C.stroke
topStroke.Transparency = 0.2

local grad = Instance.new("UIGradient", top)
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120,255,200)),
    ColorSequenceKeypoint.new(1, C.base)
})
grad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.15),
    NumberSequenceKeypoint.new(1, 0.7)
})

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14,0)
title.Size = UDim2.new(1,-120,1,0)
title.Font = Enum.Font.GothamSemibold
title.Text = "UFO HUB X"
title.TextColor3 = Color3.fromRGB(190,255,200)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

-- ปุ่มย่อ/ขยาย และปิด
local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1,0.5)
closeBtn.Position = UDim2.new(1,-10,0.5,0)
closeBtn.Size = UDim2.fromOffset(28,28)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamSemibold
closeBtn.TextSize = 16
closeBtn.TextColor3 = C.text
closeBtn.BackgroundColor3 = C.panel
closeBtn.AutoButtonColor = false
closeBtn.Parent = top
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

local miniBtn = closeBtn:Clone()
miniBtn.Text = "–"
miniBtn.Position = UDim2.new(1,-46,0.5,0)
miniBtn.Parent = top

local function tween(o, props, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function hide()
    tween(win, {Size = UDim2.fromOffset(win.Size.X.Offset, 0)}, 0.16)
    tween(dim, {BackgroundTransparency = 1}, 0.16)
    task.wait(0.17)
    win.Visible = false
    dim.Visible = false
end
local function show()
    dim.Visible = true
    win.Visible = true
    local w = win.Size.X.Offset
    win.Size = UDim2.fromOffset(w, 0)
    tween(dim, {BackgroundTransparency = 0.4}, 0.16)
    tween(win, {Size = UDim2.fromOffset(w, 420)}, 0.18)
end

closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = C.hover}, 0.08) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = C.panel}, 0.08) end)
miniBtn.MouseEnter:Connect(function() tween(miniBtn, {BackgroundColor3 = C.hover}, 0.08) end)
miniBtn.MouseLeave:Connect(function() tween(miniBtn, {BackgroundColor3 = C.panel}, 0.08) end)
closeBtn.MouseButton1Click:Connect(hide)
miniBtn.MouseButton1Click:Connect(function()
    win.Visible = not win.Visible
    if win.Visible then show() else hide() end
end)

-- ลากได้ (drag by top bar)
do
    local dragging = false
    local dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    top.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =============== BODY LAYOUT ===============
local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.fromOffset(0,40)
body.Size = UDim2.new(1,0,1,-40)
body.BackgroundTransparency = 1
body.Parent = win

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.fromOffset(0,0)
sidebar.Size = UDim2.new(0,160,1,0)
sidebar.BackgroundColor3 = C.base
sidebar.BorderSizePixel = 0
sidebar.Parent = body
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)

local sbStroke = Instance.new("UIStroke", sidebar)
sbStroke.Color = C.stroke
sbStroke.Transparency = 0.2

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(168,0)
content.Size = UDim2.new(1,-176,1,0)
content.BackgroundColor3 = C.base
content.BorderSizePixel = 0
content.Parent = body

-- =============== Sidebar buttons factory ===============
local tabs = {}
local activeTab = nil

local function makeBtn(text, emoji)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-20,0,36)
    b.Position = UDim2.fromOffset(10, 10 + (#tabs)*44)
    b.BackgroundColor3 = C.panel
    b.TextColor3 = C.text
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = string.format("%s  %s", emoji or "•", text)
    b.Parent = sidebar

    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b); s.Color = C.stroke; s.Transparency = 0.25

    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = C.hover}, 0.08) end)
    b.MouseLeave:Connect(function()
        if activeTab ~= b then tween(b, {BackgroundColor3 = C.panel}, 0.08) end
    end)
    return b
end

local function makePage(titleText)
    local p = Instance.new("Frame")
    p.Visible = false
    p.Size = UDim2.fromScale(1,1)
    p.BackgroundColor3 = C.base
    p.Parent = content

    local card = Instance.new("Frame")
    card.Position = UDim2.fromOffset(0,0)
    card.Size = UDim2.new(1,0,1,0)
    card.BackgroundColor3 = C.base
    card.Parent = p
    Instance.new("UIStroke", card).Color = C.stroke
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,12)

    -- หัวข้อย่อย (การ์ดเทาเขียว)
    local head = Instance.new("Frame")
    head.Position = UDim2.fromOffset(16,16)
    head.Size = UDim2.new(1,-32,0,38)
    head.BackgroundColor3 = C.panel
    head.Parent = card
    Instance.new("UICorner", head).CornerRadius = UDim.new(0,10)
    local hs = Instance.new("UIStroke", head); hs.Color = C.stroke; hs.Transparency = 0.2

    local htxt = Instance.new("TextLabel")
    htxt.BackgroundTransparency = 1
    htxt.Size = UDim2.new(1,-16,1,0)
    htxt.Position = UDim2.fromOffset(12,0)
    htxt.Font = Enum.Font.GothamSemibold
    htxt.TextSize = 15
    htxt.TextXAlignment = Enum.TextXAlignment.Left
    htxt.TextColor3 = C.text
    htxt.Text = "• "..titleText
    htxt.Parent = head

    return p
end

local function addTab(name, emoji)
    local btn = makeBtn(name, emoji)
    local page = makePage(name)

    table.insert(tabs, btn)

    local function setActive(state)
        if state then
            activeTab = btn
            for _, b in ipairs(tabs) do
                if b ~= btn then tween(b, {BackgroundColor3 = C.panel}, 0.08) end
            end
            tween(btn, {BackgroundColor3 = C.hover}, 0.08)
            for _, pg in ipairs(content:GetChildren()) do
                if pg:IsA("Frame") then pg.Visible = false end
            end
            page.Visible = true
        end
    end

    btn.MouseButton1Click:Connect(function() setActive(true) end)
    if not activeTab then setActive(true) end
end

-- =============== Create Tabs ===============
addTab("Main",      "🏠")
addTab("Farm",      "🌱")
addTab("Stealer",   "🛰️")
addTab("Pet",       "🐾")
addTab("Macro",     "⚙️")
addTab("Shop",      "🛒")
addTab("Calculation","🧮")
addTab("Settings",  "🛠")

-- =============== Global Toggle Key ===============
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if win.Visible then hide() else show() end
    end
end)

-- =============== Mobile floating toggle ===============
do
    local mob = Instance.new("TextButton")
    mob.Name = "UFO_Toggle"
    mob.AnchorPoint = Vector2.new(1,0)
    mob.Position = UDim2.new(1,-12,0,12)
    mob.Size = UDim2.fromOffset(44,44)
    mob.Text = "👽"
    mob.Font = Enum.Font.GothamBold
    mob.TextSize = 18
    mob.TextColor3 = C.text
    mob.BackgroundColor3 = C.panel
    mob.Parent = gui
    Instance.new("UICorner", mob).CornerRadius = UDim.new(0,12)
    local ms = Instance.new("UIStroke", mob); ms.Color = C.accent; ms.Transparency = 0.15

    mob.MouseButton1Click:Connect(function()
        if win.Visible then hide() else show() end
    end)
end

-- เริ่มต้นโชว์ด้วยแอนิเมชันเล็กน้อย
show()
