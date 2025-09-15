--[[========================================================
  UFO HUB X — Main UI (README.lua)
  - Toggle ปุ่มลอยซ้ายจอ + หน้าต่างหลัก (เล็กลงนิดตามคำขอ)
  - โทน: เขียวเอเลี่ยน + เส้นขาว, กลาสนุ่ม, มุมมน
  - ลากได้ลื่น, เปิด/ปิดลื่น, ไม่เด้งตำแหน่ง, self-heal
  - รองรับ Bootloader (จะเรียก start/run/open ได้)
  - ใช้เดี่ยวก็ได้: loadstring(game:HttpGet(...))()
==========================================================]]

-- ========== Exec-safe checks ==========
local Players, TweenService, UIS, RunService =
      game:GetService("Players"),
      game:GetService("TweenService"),
      game:GetService("UserInputService"),
      game:GetService("RunService")

local lp = Players.LocalPlayer
local pgui = lp and lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")

-- ป้องกันซ้ำ
local ENV = (getgenv and getgenv()) or _G
if ENV.__UFOX_MAIN_ALIVE then
    return {start=function() end, run=function() end, open=function() end}
end
ENV.__UFOX_MAIN_ALIVE = true

-- ========== Theme ==========
local CFG = ENV.UFOX or {}
local ALIEN      = CFG.accent or Color3.fromRGB(22,247,123)
local BG_DARK    = Color3.fromRGB(12,14,16)
local PANEL      = Color3.fromRGB(18,21,24)
local FIELD      = Color3.fromRGB(25,29,33)
local WHITE      = Color3.fromRGB(255,255,255)
local TEXT_MAIN  = Color3.fromRGB(226,233,240)
local TEXT_SOFT  = Color3.fromRGB(160,168,176)
local LOGO_ID    = CFG.logoId or 106029438403666
local TITLE_TXT  = (CFG.title or "UFO HUB X")

-- ========== Utils ==========
local function corner(i,r) local c=Instance.new("UICorner",i); c.CornerRadius=UDim.new(0,r or 12); return c end
local function stroke(i,th,col,tr) local s=Instance.new("UIStroke",i); s.Thickness=th or 1; s.Color=col or WHITE; s.Transparency=tr or 0.82; return s end
local function lerp(a,b,t) return a + (b-a)*t end
local function clampToViewport(guiObj)
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280,720)
    local p  = guiObj.AbsolutePosition
    local s  = guiObj.AbsoluteSize
    local nx = math.clamp(p.X, 8, math.max(8, vp.X - s.X - 8))
    local ny = math.clamp(p.Y, 8, math.max(8, vp.Y - s.Y - 8))
    guiObj.Position = UDim2.fromOffset(nx, ny)
end

local function smoothDrag(handle, target)
    local dragging, start, base
    handle.Active = true; target.Active = true
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; start=i.Position; base=target.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d = i.Position - start
            local np = UDim2.new(base.X.Scale, base.X.Offset+d.X, base.Y.Scale, base.Y.Offset+d.Y)
            TweenService:Create(target, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=np}):Play()
        end
    end)
end

-- ========== Build ==========
local gui, toggleBtn, main, titleBar

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = "UFOX_MAIN_UI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1200
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pgui

    -- ปุ่มลอย (เล็กลงนิด)
    toggleBtn = Instance.new("Frame")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.fromOffset(88,88)
    toggleBtn.Position = UDim2.new(0, 24, 0.25, -44) -- สูงขึ้นตามรูปตัวอย่าง
    toggleBtn.BackgroundColor3 = PANEL
    toggleBtn.Parent = gui
    corner(toggleBtn, 16); stroke(toggleBtn, 2, WHITE, 0.65)

    local togBtn = Instance.new("TextButton", toggleBtn)
    togBtn.BackgroundTransparency = 1
    togBtn.Size = UDim2.fromScale(1,1)
    togBtn.Text = ""
    local togIcon = Instance.new("ImageLabel", toggleBtn)
    togIcon.BackgroundTransparency = 1
    togIcon.Size = UDim2.fromScale(1,1)
    togIcon.Image = "rbxthumb://type=Asset&id="..tostring(LOGO_ID).."&w=150&h=150"
    togIcon.ScaleType = Enum.ScaleType.Fit

    smoothDrag(toggleBtn, toggleBtn)

    -- หน้าต่างหลัก (ย่อเล็กกว่าก่อนหน้าและกึ่งกลาง)
    main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.Size = UDim2.new(0, 820, 0, 420)   -- เล็กลงเล็กน้อย
    main.Position = UDim2.fromScale(0.5,0.5)
    main.BackgroundColor3 = PANEL
    main.Visible = false
    main.Parent = gui
    corner(main, 14); stroke(main, 2, WHITE, 0.7)

    -- เงานุ่ม
    local shadow = Instance.new("ImageLabel", main)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24,24,276,276)
    shadow.Size = UDim2.new(1,40,1,40)
    shadow.Position = UDim2.new(0,-20,0,-20)

    -- แถบหัว
    titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1,0,0,52)
    titleBar.BackgroundColor3 = BG_DARK
    corner(titleBar, 14); stroke(titleBar, 1, WHITE, 0.85)

    local logo = Instance.new("ImageLabel", titleBar)
    logo.BackgroundTransparency = 1
    logo.Size = UDim2.fromOffset(36,36)
    logo.Position = UDim2.new(0, 12, 0.5, -18)
    logo.Image = "rbxthumb://type=Asset&id="..tostring(LOGO_ID).."&w=150&h=150"

    local title = Instance.new("TextLabel", titleBar)
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 56, 0, 0)
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.RichText = true
    -- UFO เขียว / HUB X ขาว
    title.Text = ('<font color="#%02X%02X%02X">UFO</font> HUB X')
        :format(ALIEN.R*255, ALIEN.G*255, ALIEN.B*255)
    title.TextColor3 = TEXT_MAIN
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeX = Instance.new("TextButton", titleBar)
    closeX.Size = UDim2.fromOffset(32,32)
    closeX.Position = UDim2.new(1, -44, 0.5, -16)
    closeX.Text = "✕"
    closeX.Font = Enum.Font.GothamBold
    closeX.TextSize = 18
    closeX.TextColor3 = TEXT_MAIN
    closeX.BackgroundColor3 = FIELD
    corner(closeX, 8); stroke(closeX, 1, WHITE, 0.85)

    -- ปุ่มแท็บ (กรอบขาว เขียวอ่อน)
    local tabs = Instance.new("Frame", main)
    tabs.Name = "Tabs"
    tabs.BackgroundColor3 = BG_DARK
    tabs.Position = UDim2.new(0,12,0,66)
    tabs.Size = UDim2.new(1,-24,0,40)
    corner(tabs,10); stroke(tabs,1,WHITE,0.85)

    local list = Instance.new("UIListLayout", tabs)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0,8)
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function mkTab(txt)
        local b = Instance.new("TextButton", tabs)
        b.Size = UDim2.new(0, 120, 1, -8)
        b.Position = UDim2.new(0,0,0,4)
        b.BackgroundColor3 = FIELD
        b.Text = txt
        b.TextColor3 = TEXT_MAIN
        b.TextSize = 16
        b.Font = Enum.Font.GothamSemibold
        corner(b,10); stroke(b,1,WHITE,0.9)
        b.AutoButtonColor = true
        return b
    end

    local T = {
        mkTab("หน้าหลัก"),
        mkTab("ผู้เล่น"),
        mkTab("ภาพ/แสง"),
        mkTab("เทเลพอร์ต"),
        mkTab("ตั้งค่า"),
        mkTab("เครดิต"),
    }

    -- พื้นที่เนื้อหาแบบ “สองซีก”
    local content = Instance.new("Frame", main)
    content.Name = "Content"
    content.BackgroundColor3 = BG_DARK
    content.Position = UDim2.new(0,12,0,114)
    content.Size = UDim2.new(1,-24,1,-(114+12))
    corner(content,10); stroke(content,1,WHITE,0.85)

    local left = Instance.new("Frame", content)
    left.Size = UDim2.new(0.5,-8,1,-12)
    left.Position = UDim2.new(0,6,0,6)
    left.BackgroundColor3 = PANEL
    corner(left,10); stroke(left,1,WHITE,0.85)

    local right = Instance.new("Frame", content)
    right.Size = UDim2.new(0.5,-8,1,-12)
    right.Position = UDim2.new(0.5,2,0,6)
    right.BackgroundColor3 = PANEL
    corner(right,10); stroke(right,1,WHITE,0.85)

    -- ตัวอย่างหัวข้อ (placeholder เอาออกได้)
    local function addTitle(parent, text)
        local l = Instance.new("TextLabel", parent)
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -16, 0, 24)
        l.Position = UDim2.new(0, 8, 0, 8)
        l.Font = Enum.Font.GothamSemibold
        l.TextSize = 16
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = ALIEN
        l.Text = "• "..text
        return l
    end
    addTitle(left,  "ฝั่งซ้าย (ใส่เมนู/สวิตช์/สไลเดอร์)")
    addTitle(right, "ฝั่งขวา (สถานะ/ลิสต์/อื่น ๆ)")

    -- Drag ทั้งกรอบ
    smoothDrag(titleBar, main)

    -- แอนิเมชันเปิด/ปิด + ตำแหน่งนิ่ง
    local isShowing, animLock = false, false
    local function showMain()
        if animLock or isShowing then return end
        animLock=true; isShowing=true
        clampToViewport(main)
        main.Visible=true
        main.BackgroundTransparency = 1
        main.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset+16)
        TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency=0, Position=UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset-16)}
        ):Play()
        task.delay(0.18, function() animLock=false end)
    end
    local function hideMain()
        if animLock or not isShowing then return end
        animLock=true; isShowing=false
        TweenService:Create(main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency=1, Position=UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset+16)}
        ):Play()
        task.delay(0.16, function() main.Visible=false; animLock=false end)
    end

    -- คลิกปุ่ม
    togBtn.MouseButton1Click:Connect(function()
        if main.Visible then hideMain() else showMain() end
    end)
    closeX.MouseButton1Click:Connect(function() hideMain() end)

    -- self-heal: ถ้าหายจาก PlayerGui ให้สร้างใหม่
    RunService.RenderStepped:Connect(function()
        if not gui or not gui.Parent then
            ENV.__UFOX_MAIN_ALIVE = false
            build()
        end
    end)
end

build()

-- ====== Public API (รองรับบูทโหลดเดอร์) ======
local M = {}
function M.start(_) if not (gui and gui.Parent) then build() end end
function M.run(_)   if not (gui and gui.Parent) then build() end end
function M.open(_)  if not (gui and gui.Parent) then build() end end
return M
