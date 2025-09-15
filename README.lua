--==============================================================
-- 👽 UFO HUB X — Pixel-Locked Grandmaster v5.0 (Delta X / KRNL)
--  • Boot 8s (ปรับได้)
--  • Toggle ลอย (ลากได้)  • หน้าต่างใหญ่ (ลากได้)
--  • TitleBar: โลโก้ข้างชื่อ "UFO HUB X", ปุ่ม X ขวา
--  • Tabs 6 ปุ่มครบ
--  • เปิด/ปิด = Fade-only (ไม่แตะ Position เลย) → ไม่เด้ง 100%
--  • ตำแหน่งเก็บเป็น "พิกเซลจริง" + Anchor(0,0) → ไม่วิ่งตาม, ไม่ไหลขึ้น
--  • กันซ้ำ, กันกดรัว, กันภาพ/ปุ่มหาย (cache transparency เดิม)
--==============================================================

-------------------- CONFIG --------------------
local BOOT_DURATION = 8.0   -- วินาที (อยากช้ากว่านี้ปรับได้)
local SHOW_DUR      = 0.28  -- วินาทีเฟดเข้า
local HIDE_DUR      = 0.20  -- วินาทีเฟดออก

local MAIN_W, MAIN_H = 720, 420
local TOGGLE_W, TOGGLE_H = 76, 76

-------------------- SERVICES --------------------
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UIS             = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- กันซ้ำ UI ก่อนสร้างใหม่
for _,v in ipairs(pg:GetChildren()) do
    if v:IsA("ScreenGui") and (v.Name=="UFO_UI" or v.Name=="UFO_BOOT") then v:Destroy() end
end

-------------------- THEME / ASSETS --------------------
local ALIEN   = Color3.fromRGB(0,255,140)
local BG      = Color3.fromRGB(15,16,18)
local ELEM    = Color3.fromRGB(26,27,32)
local MID     = Color3.fromRGB(20,22,25)
local WHITE   = Color3.new(1,1,1)
local BLACK   = Color3.new(0,0,0)

local UFO_ICON   = "rbxassetid://106029438403666"
local CLOSE_ICON = "rbxassetid://6031094678"

-------------------- GLOBAL STATE (ตำแหน่งจริงแบบพิกเซล) --------------------
local G = getgenv and getgenv() or _G
G.UFOX_POS_PX = G.UFOX_POS_PX or { x = math.huge, y = math.huge }  -- เริ่มยังไม่เคยเซฟ

local function viewport()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize else return Vector2.new(1280,720) end
end

local function centerStartPx()
    local vp = viewport()
    return math.floor((vp.X - MAIN_W)/2), math.floor((vp.Y - MAIN_H)/2)
end

local function ensureSavedPx(x, y)
    if G.UFOX_POS_PX.x == math.huge or G.UFOX_POS_PX.y == math.huge then
        G.UFOX_POS_PX.x, G.UFOX_POS_PX.y = x, y
    end
end

local function clampToViewportPx(px)
    local vp = viewport()
    px.x = math.clamp(px.x, 8, math.max(8, vp.X - MAIN_W - 8))
    px.y = math.clamp(px.y, 8, math.max(8, vp.Y - MAIN_H - 8))
    return px
end

-------------------- UTILS --------------------
local function stroke(gui, th, col)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Thickness = th or 1.6
    s.Color = col or WHITE
    s.Parent = gui
    return s
end

-- ลากแบบ “ตั้งค่าพิกเซลจริง” ไม่ใช้ tween → หนึบ ไม่แกว่ง
local function dragPixel(handle: GuiObject, target: Frame, onRelease)
    handle.Active = true; target.Active = true
    local dragging = false
    local startOffset = Vector2.new(0,0)
    local startMouse  = Vector2.new(0,0)

    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging = true
            startOffset = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
            startMouse  = Vector2.new(i.Position.X, i.Position.Y)
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then
                    dragging = false
                    if onRelease then onRelease() end
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local cur = Vector2.new(i.Position.X, i.Position.Y)
            local delta = cur - startMouse
            local nx = startOffset.X + delta.X
            local ny = startOffset.Y + delta.Y
            target.Position = UDim2.fromOffset(nx, ny)
        end
    end)
end

-- เก็บ transparency เดิม เพื่อลดบั๊ก “ปุ่ม/รูปหาย”
local function cacheTrans(root)
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            if d:GetAttribute("origTT")==nil then d:SetAttribute("origTT", d.TextTransparency or 0) end
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            if d:GetAttribute("origIT")==nil then d:SetAttribute("origIT", d.ImageTransparency or 0) end
        elseif d:IsA("Frame") then
            if d:GetAttribute("origBT")==nil then d:SetAttribute("origBT", d.BackgroundTransparency or 0) end
        end
    end
end

local function fadeTree(root, hide, dur)
    dur = dur or 0.22
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local orig = d:GetAttribute("origTT") or 0
            local to = hide and 1 or orig
            TweenService:Create(d, TweenInfo.new(dur, Enum.EasingStyle.Quad, hide and Enum.EasingDirection.In or Enum.EasingDirection.Out),
                {TextTransparency = to}):Play()
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            local orig = d:GetAttribute("origIT") or 0
            local to = hide and 1 or orig
            TweenService:Create(d, TweenInfo.new(dur, Enum.EasingStyle.Quad, hide and Enum.EasingDirection.In or Enum.EasingDirection.Out),
                {ImageTransparency = to}):Play()
        elseif d:IsA("Frame") then
            local orig = d:GetAttribute("origBT") or 0
            local to = hide and 1 or orig
            TweenService:Create(d, TweenInfo.new(dur, Enum.EasingStyle.Quad, hide and Enum.EasingDirection.In or Enum.EasingDirection.Out),
                {BackgroundTransparency = to}):Play()
        end
    end
end

-------------------- BOOT --------------------
local function BuildBoot()
    local boot = Instance.new("ScreenGui")
    boot.Name="UFO_BOOT"; boot.IgnoreGuiInset=true; boot.ResetOnSpawn=false
    boot.DisplayOrder=2000; boot.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    boot.Parent = pg

    local box = Instance.new("Frame", boot)
    box.AnchorPoint = Vector2.new(0.5,0.5)
    box.Position    = UDim2.fromScale(0.5,0.5)
    box.Size        = UDim2.new(0,420,0,200)
    box.BackgroundColor3 = BG
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,16)
    stroke(box,2)

    local logo = Instance.new("ImageLabel", box)
    logo.BackgroundTransparency=1
    logo.AnchorPoint=Vector2.new(0.5,0)
    logo.Position=UDim2.new(0.5,0,0,20)
    logo.Size=UDim2.new(0,68,0,68)
    logo.Image=UFO_ICON
    logo.ImageColor3=ALIEN

    local ttl = Instance.new("TextLabel", box)
    ttl.BackgroundTransparency=1
    ttl.AnchorPoint=Vector2.new(0.5,0)
    ttl.Position=UDim2.new(0.5,0,0,96)
    ttl.Size=UDim2.new(1,-40,0,34)
    ttl.Font=Enum.Font.GothamBold
    ttl.TextSize=26
    ttl.RichText=true
    ttl.TextColor3=WHITE
    ttl.Text = '<font color="#00FF8C">UFO</font> <font color="#FFFFFF">HUB X</font>'

    local bar = Instance.new("Frame", box)
    bar.AnchorPoint=Vector2.new(0.5,0)
    bar.Position=UDim2.new(0.5,0,0,138)
    bar.Size=UDim2.new(1,-48,0,16)
    bar.BackgroundColor3=ELEM
    Instance.new("UICorner", bar).CornerRadius=UDim.new(0,9)
    stroke(bar,1.5)

    local fill = Instance.new("Frame", bar)
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=ALIEN
    Instance.new("UICorner", fill).CornerRadius=UDim.new(0,9)

    local pct = Instance.new("TextLabel", box)
    pct.BackgroundTransparency=1
    pct.AnchorPoint=Vector2.new(0.5,0)
    pct.Position=UDim2.new(0.5,0,0,162)
    pct.Size=UDim2.new(1,-40,0,22)
    pct.Font=Enum.Font.Gotham
    pct.TextSize=17
    pct.TextColor3=WHITE
    pct.Text = "กำลังเตรียมพร้อม... 0%"

    pcall(function() ContentProvider:PreloadAsync({logo}) end)

    local start = tick()
    local hb; hb=RunService.Heartbeat:Connect(function()
        local t = math.clamp((tick()-start)/BOOT_DURATION,0,1)
        fill.Size = UDim2.new(t,0,1,0)
        pct.Text = ("กำลังเตรียมพร้อม... %d%%"):format(math.floor(t*100+0.5))
        if t>=1 then hb:Disconnect(); boot:Destroy() end
    end)
end

-------------------- MAIN UI --------------------
local function BuildMain()
    local screen = Instance.new("ScreenGui")
    screen.Name="UFO_UI"; screen.IgnoreGuiInset=true; screen.ResetOnSpawn=false
    screen.DisplayOrder=1000; screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    screen.Parent = pg

    -- ปุ่มลอย (Anchor 0,0 + พิกเซลจริง)
    local toggle = Instance.new("ImageButton", screen)
    toggle.Name="UFO_Toggle"
    toggle.AnchorPoint = Vector2.new(0,0)
    toggle.Size = UDim2.fromOffset(TOGGLE_W, TOGGLE_H)
    toggle.Position = UDim2.fromOffset(96, 120)
    toggle.BackgroundColor3 = ELEM
    toggle.AutoButtonColor = true
    toggle.Image = UFO_ICON
    toggle.ImageColor3 = ALIEN
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,12)
    stroke(toggle,2)
    dragPixel(toggle, toggle, function() -- clamp หลังปล่อย
        local px = { x = toggle.Position.X.Offset, y = toggle.Position.Y.Offset }
        local vp = viewport()
        px.x = math.clamp(px.x, 8, math.max(8, vp.X - TOGGLE_W - 8))
        px.y = math.clamp(px.y, 8, math.max(8, vp.Y - TOGGLE_H - 8))
        toggle.Position = UDim2.fromOffset(px.x, px.y)
    end)

    -- คำนวณตำแหน่งเริ่มต้นของ main แบบ “พิกเซลจริง”
    do
        local sx, sy = centerStartPx()
        ensureSavedPx(sx, sy)
        clampToViewportPx(G.UFOX_POS_PX)
    end

    -- หน้าต่างใหญ่ (Anchor 0,0 + พิกเซลจริง)
    local main = Instance.new("Frame", screen)
    main.Name="MainWindow"
    main.AnchorPoint = Vector2.new(0,0)
    main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
    main.Position = UDim2.fromOffset(G.UFOX_POS_PX.x, G.UFOX_POS_PX.y)
    main.BackgroundColor3 = BG
    main.Visible = false
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
    stroke(main,2)

    -- TitleBar (ตัวจับลาก)
    local title = Instance.new("Frame", main)
    title.Name="TitleBar"
    title.AnchorPoint = Vector2.new(0,0)
    title.Position = UDim2.fromOffset(0,0)
    title.Size = UDim2.new(1,0,0,44)
    title.BackgroundColor3 = ELEM
    Instance.new("UICorner", title).CornerRadius = UDim.new(0,12)
    stroke(title,1.5)

    -- โลโก้ + ชื่อ
    local brandWrap = Instance.new("Frame", title)
    brandWrap.Name="BrandWrap"
    brandWrap.BackgroundTransparency=1
    brandWrap.AnchorPoint = Vector2.new(0,0.5)
    brandWrap.Position = UDim2.fromOffset(12, 22)
    brandWrap.Size = UDim2.fromOffset(220, 24)

    local layout = Instance.new("UIListLayout", brandWrap)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding = UDim.new(0,8)

    local logo = Instance.new("ImageLabel", brandWrap)
    logo.BackgroundTransparency=1
    logo.Size=UDim2.fromOffset(24,24)
    logo.Image=UFO_ICON
    logo.ImageColor3=ALIEN

    local brand = Instance.new("TextLabel", brandWrap)
    brand.BackgroundTransparency=1
    brand.Size = UDim2.fromOffset(180,24)
    brand.Font=Enum.Font.GothamBold
    brand.TextSize=20
    brand.RichText=true
    brand.TextColor3=WHITE
    brand.Text = '<font color="#00FF8C">UFO</font> <font color="#FFFFFF">HUB X</font>'
    brand.TextXAlignment = Enum.TextXAlignment.Left

    -- ปุ่ม X
    local close = Instance.new("ImageButton", title)
    close.Name="CloseX"
    close.AnchorPoint = Vector2.new(1,0.5)
    close.Position = UDim2.new(1,-12,0.5,0)
    close.Size = UDim2.fromOffset(32,32)
    close.BackgroundColor3 = ELEM
    close.AutoButtonColor = true
    close.Image = CLOSE_ICON
    close.ImageColor3 = WHITE
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,6)
    stroke(close,1.6)

    -- Tabs
    local tabs = Instance.new("Frame", main)
    tabs.Name="TabsBar"
    tabs.AnchorPoint = Vector2.new(0,0)
    tabs.Position = UDim2.fromOffset(8, 54)
    tabs.Size = UDim2.fromOffset(MAIN_W-16, 40)
    tabs.BackgroundColor3 = ELEM
    Instance.new("UICorner", tabs).CornerRadius = UDim.new(0,8)
    stroke(tabs,1)

    local TAB_TITLES = {"หน้าหลัก","ผู้เล่น","ภาพ/แสง","เทเลพอร์ต","ตั้งค่า","เครดิต"}

    -- Content
    local content = Instance.new("Frame", main)
    content.Name="Content"
    content.AnchorPoint = Vector2.new(0,0)
    content.Position = UDim2.fromOffset(8, 100)
    content.Size = UDim2.fromOffset(MAIN_W-16, MAIN_H-108)
    content.BackgroundColor3 = ELEM
    Instance.new("UICorner", content).CornerRadius = UDim.new(0,10)
    stroke(content,1)

    -- Pages + Buttons (วางแบบคงที่จาก MAIN_W → ไม่แกว่ง)
    local pages = {}
    local function makePage(name)
        local p = Instance.new("Frame", content)
        p.Name = "Page_"..name
        p.BackgroundTransparency = 1
        p.AnchorPoint = Vector2.new(0,0)
        p.Position = UDim2.fromOffset(8,8)
        p.Size = UDim2.fromOffset(MAIN_W-32, MAIN_H-124)
        p.Visible = false
        local lbl = Instance.new("TextLabel", p)
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromOffset(p.Size.X.Offset, 26)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 18
        lbl.TextColor3 = ALIEN
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "หน้านี้คือ: "..name
        return p
    end

    for _,n in ipairs(TAB_TITLES) do pages[n] = makePage(n) end

    local function switchTo(n)
        for k,v in pairs(pages) do v.Visible = (k==n) end
    end
    switchTo("หน้าหลัก")

    local eachW = math.max(90, math.floor((MAIN_W - 16 - 8*(#TAB_TITLES-1)) / #TAB_TITLES))
    local xoff = 0
    for _,n in ipairs(TAB_TITLES) do
        local b = Instance.new("TextButton", tabs)
        b.Size = UDim2.fromOffset(eachW, 40)
        b.Position = UDim2.fromOffset(xoff, 0)
        xoff = xoff + eachW + 8
        b.Text = n
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.TextColor3 = ALIEN
        b.BackgroundColor3 = BG
        b.AutoButtonColor = true
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        stroke(b,1.5)
        b.MouseEnter:Connect(function() b.BackgroundColor3 = MID end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = BG end)
        b.MouseButton1Click:Connect(function() switchTo(n) end)
    end

    -- ลากหน้าต่างใหญ่ → เซฟพิกเซลจริง
    dragPixel(title, main, function()
        G.UFOX_POS_PX.x = main.Position.X.Offset
        G.UFOX_POS_PX.y = main.Position.Y.Offset
        clampToViewportPx(G.UFOX_POS_PX)
        main.Position = UDim2.fromOffset(G.UFOX_POS_PX.x, G.UFOX_POS_PX.y)
    end)

    -- ถ้าขนาดจอเปลี่ยน ค่อย “clamp อย่างเดียว” (ไม่ย้ายตำแหน่งด้วยตัวเอง)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            clampToViewportPx(G.UFOX_POS_PX)
            main.Position = UDim2.fromOffset(G.UFOX_POS_PX.x, G.UFOX_POS_PX.y)
        end)
    end

    --------------- Fade-only Animator (ไม่แตะ Position) ---------------
    cacheTrans(main)
    local busy, wantOpen = false, false

    local function openUI()
        if busy then return end
        busy = true; wantOpen = true
        main.Visible = true
        fadeTree(main, false, SHOW_DUR)
        task.delay(SHOW_DUR + 0.03, function()
            busy = false
            if not wantOpen then closeUI() end
        end)
    end

    function closeUI()
        if busy then return end
        busy = true; wantOpen = false
        fadeTree(main, true, HIDE_DUR)
        task.delay(HIDE_DUR + 0.02, function()
            main.Visible = false
            busy = false
            if wantOpen then openUI() end
        end)
    end

    -- Debounce click กันกดรัว
    local cd = false
    local function clickWrap(fn)
        if cd then return end
        cd = true; fn(); task.delay(0.12, function() cd=false end)
    end

    toggle.MouseButton1Click:Connect(function()
        clickWrap(function()
            if main.Visible then closeUI() else openUI() end
        end)
    end)
    close.MouseButton1Click:Connect(function()
        clickWrap(function()
            if main.Visible then closeUI() end
        end)
    end)

    -- เปิดเองหลังบูตนิดหน่อย
    task.delay(0.2, openUI)
end

-------------------- RUN --------------------
pcall(function() ContentProvider:PreloadAsync({UFO_ICON}) end)
BuildBoot()
task.delay(BOOT_DURATION + 0.2, function()
    -- กันซ้ำช่วงสลับเฟส
    for _,v in ipairs(pg:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name=="UFO_UI" then v:Destroy() end
    end
    BuildMain()
end)
