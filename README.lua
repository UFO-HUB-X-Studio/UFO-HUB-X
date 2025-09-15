--========================================================
-- UFO HUB X — MAIN UI (Back-style + small draggable toggle)
-- โมดูลนี้ถูกออกแบบให้ใช้กับบู๊ตโหลดเดอร์เดิมของเพื่อน
-- API: return { show=…, hide=…, destroy=…, makeDraggable=… }
--========================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local lp           = Players.LocalPlayer
local pg           = lp:WaitForChild("PlayerGui")

-- ===== Theme =====
local ALIEN       = Color3.fromRGB(22,247,123)
local BG_MAIN     = Color3.fromRGB(19,21,24)
local BG_INNER    = Color3.fromRGB(26,28,32)
local TXT_MAIN    = Color3.fromRGB(230,238,245)
local TXT_SOFT    = Color3.fromRGB(165,175,185)
local WHITE_STK   = Color3.fromRGB(255,255,255)

-- ===== Assets =====
local ICON_ID     = "rbxassetid://106029438403666" -- ไอคอน UFO ที่เพื่อนเอามาใช้

-- ===== State (กันซ้ำ + จำตำแหน่ง) =====
_G.__UFOX_POS = _G.__UFOX_POS or { main = nil, toggle = nil }
if _G.__UFOX_UI_OBJ and _G.__UFOX_UI_OBJ.alive then
	-- กันซ้ำ
	return _G.__UFOX_UI_OBJ.api
end

-- ===== Utils =====
local function clampToViewport(guiObj)
	local cam = workspace.CurrentCamera
	if not (cam and guiObj) then return end
	local vp = cam.ViewportSize
	local p  = guiObj.AbsolutePosition
	local s  = guiObj.AbsoluteSize
	local nx = math.clamp(p.X, 6, math.max(6, vp.X - s.X - 6))
	local ny = math.clamp(p.Y, 6, math.max(6, vp.Y - s.Y - 6))
	guiObj.Position = UDim2.fromOffset(nx, ny)
end

local function smoothDrag(handle, target)
	local dragging, dragStart, startPos = false, nil, nil
	handle.Active = true
	handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true; dragStart=i.Position; startPos=target.Position
			i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
			local d = i.Position - dragStart
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
			TweenService:Create(target, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=newPos}):Play()
		end
	end)
end

local function fadeIn(gui)
	gui.Visible=true
	gui.BackgroundTransparency=1
	TweenService:Create(gui, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0}):Play()
end
local function fadeOut(gui, cb)
	local tw = TweenService:Create(gui, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency=1})
	tw.Completed:Connect(function() gui.Visible=false if cb then cb() end end)
	tw:Play()
end

-- ===== Build UI =====
local screen = Instance.new("ScreenGui")
screen.Name = "UFOX_UI"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 1000
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = pg

-- Toggle (เล็ก + ลากได้)
local toggle = Instance.new("ImageButton")
toggle.Name = "UFOX_Toggle"
toggle.Image = ICON_ID
toggle.BackgroundColor3 = BG_INNER
toggle.Size = UDim2.fromOffset(44,44)          -- << เล็กลงตามที่ขอ
toggle.AutoButtonColor = true
toggle.ImageColor3 = Color3.fromRGB(255,255,255)
toggle.Parent = screen
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,10)
local tStroke = Instance.new("UIStroke", toggle)
tStroke.Thickness = 1.6; tStroke.Color = WHITE_STK; tStroke.Transparency = 0.75

-- เริ่มตำแหน่ง toggle (จำตำแหน่งเดิมถ้ามี)
toggle.Position = _G.__UFOX_POS.toggle or UDim2.fromOffset(24, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720)/2 - 22)
smoothDrag(toggle, toggle)
toggle:GetPropertyChangedSignal("Position"):Connect(function()
	_G.__UFOX_POS.toggle = toggle.Position
end)

-- Main Window (สไตล์อันหลัง)
local main = Instance.new("Frame")
main.Name = "UFOX_Main"
main.Size = UDim2.fromOffset(880, 460)         -- กระชับลง
main.BackgroundColor3 = BG_MAIN
main.BorderSizePixel = 0
main.Parent = screen
Instance.new("UICorner", main).CornerRadius = UDim.new(0,16)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = WHITE_STK; mStroke.Thickness = 2; mStroke.Transparency = 0.82

-- Center หรือใช้ตำแหน่งเดิมที่จำไว้
if _G.__UFOX_POS.main then
	main.Position = _G.__UFOX_POS.main
else
	main.AnchorPoint = Vector2.new(0.5,0.5)
	main.Position    = UDim2.fromScale(0.5,0.5)
end

-- Title bar (ไว้ลากทั้งหน้าต่าง)
local title = Instance.new("Frame", main)
title.Size = UDim2.new(1,0,0,54)
title.BackgroundColor3 = BG_INNER
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0,16)

local nameLbl = Instance.new("TextLabel", title)
nameLbl.BackgroundTransparency = 1
nameLbl.Position = UDim2.new(0,60,0,0)
nameLbl.Size = UDim2.new(1,-120,1,0)
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 20
nameLbl.RichText = true
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Text = '<font color="#16F77B">UFO</font> HUB X'
nameLbl.TextColor3 = TXT_MAIN

local brand = Instance.new("ImageLabel", title)
brand.BackgroundTransparency = 1
brand.Image = ICON_ID
brand.Size = UDim2.fromOffset(36,36)
brand.Position = UDim2.new(0,14,0.5,-18)

local closeX = Instance.new("TextButton", title)
closeX.Text = "✕"
closeX.Font = Enum.Font.GothamBold
closeX.TextSize = 18
closeX.TextColor3 = TXT_MAIN
closeX.Size = UDim2.fromOffset(34,34)
closeX.Position = UDim2.new(1,-46,0.5,-17)
closeX.BackgroundColor3 = BG_INNER
Instance.new("UICorner", closeX).CornerRadius = UDim.new(0,10)
local cStroke = Instance.new("UIStroke", closeX)
cStroke.Color = WHITE_STK; cStroke.Transparency = 0.85; cStroke.Thickness = 1.2

-- Tabs (เส้นเรียบสไตล์อันหลัง)
local tabs = Instance.new("Frame", main)
tabs.Position = UDim2.new(0,12,0,64)
tabs.Size     = UDim2.new(1,-24,0,40)
tabs.BackgroundTransparency = 1
local list = Instance.new("UIListLayout", tabs)
list.FillDirection = Enum.FillDirection.Horizontal
list.Padding = UDim.new(0,10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.VerticalAlignment = Enum.VerticalAlignment.Center

local function pill(name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(136,40)
	b.Text = name
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 16
	b.TextColor3 = TXT_MAIN
	b.BackgroundColor3 = BG_INNER
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
	local s = Instance.new("UIStroke", b)
	s.Color = WHITE_STK; s.Transparency = 0.8; s.Thickness = 1.2
	b.AutoButtonColor = true
	b.Parent = tabs
	return b
end

local tabOrder = {"หน้าหลัก","ผู้เล่น","ภาพ/แสง","เทเลพอร์ต","ตั้งค่า","เครดิต"}
local pages = {}
local content = Instance.new("Frame", main)
content.Position = UDim2.new(0,12,0,112)
content.Size     = UDim2.new(1,-24,1,-124)
content.BackgroundColor3 = BG_INNER
Instance.new("UICorner", content).CornerRadius = UDim.new(0,12)
local cs = Instance.new("UIStroke", content)
cs.Color = WHITE_STK; cs.Transparency = 0.85; cs.Thickness = 1.6

-- โครงสองฝั่ง (แบ่งครึ่ง)
local left  = Instance.new("Frame", content)
left.BackgroundTransparency = 1
left.Position = UDim2.new(0,12,0,12)
left.Size = UDim2.new(0.5,-18,1,-24)

local right = Instance.new("Frame", content)
right.BackgroundTransparency = 1
right.Position = UDim2.new(0.5,6,0,12)
right.Size = UDim2.new(0.5,-18,1,-24)

local function makePage(name)
	local p = Instance.new("Frame")
	p.Visible=false; p.BackgroundTransparency=1
	p.Size=UDim2.new(1,0,1,0)
	-- ตัวอย่างหัวข้อแต่ปล่อยโล่งให้เพื่อนใส่เองภายหลัง
	local ltitle = Instance.new("TextLabel", left)
	ltitle.BackgroundColor3 = BG_INNER
	ltitle.Size = UDim2.new(1,0,0,36)
	ltitle.TextXAlignment = Enum.TextXAlignment.Left
	ltitle.Text = "• "..name.." (ซ้าย)"
	ltitle.Font = Enum.Font.GothamSemibold
	ltitle.TextSize=16; ltitle.TextColor3 = ALIEN
	Instance.new("UICorner", ltitle).CornerRadius = UDim.new(0,8)
	local ls = Instance.new("UIStroke", ltitle); ls.Color=WHITE_STK; ls.Transparency=0.85; ls.Thickness=1

	local rtitle = ltitle:Clone()
	rtitle.Parent = right
	rtitle.Text = "• "..name.." (ขวา)"
	return p
end

local currentName
local function switchTo(n)
	for k,pg in pairs(pages) do pg.Visible=false end
	if not pages[n] then
		pages[n] = makePage(n)
	end
	pages[n].Visible = true
	currentName = n
end

for _,n in ipairs(tabOrder) do
	local b = pill(n)
	b.MouseButton1Click:Connect(function()
		switchTo(n)
	end)
end
switchTo("หน้าหลัก")

-- ลากทั้งหน้าต่างได้ (จับที่ Title bar)
smoothDrag(title, main)
main:GetPropertyChangedSignal("Position"):Connect(function()
	_G.__UFOX_POS.main = main.Position
end)

-- ปุ่มเปิด/ปิด
local function showMain()
	main.Visible=true
	clampToViewport(main)
	TweenService:Create(main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0}):Play()
end
local function hideMain()
	TweenService:Create(main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency=0.02}):Play()
	main.Visible=false
end
toggle.MouseButton1Click:Connect(function()
	if main.Visible then hideMain() else showMain() end
end)
closeX.MouseButton1Click:Connect(function() hideMain() end)

-- เริ่มต้นโชว์
showMain()

-- ===== API =====
local api = {}
function api.show() showMain() end
function api.hide() hideMain() end
function api.destroy()
	if screen then screen:Destroy() end
	if _G.__UFOX_UI_OBJ then _G.__UFOX_UI_OBJ.alive=false end
end
function api.makeDraggable()
	-- (เผื่อบูตโหลดเดอร์เรียก) — เราทำไว้แล้ว แต่ให้เรียกซ้ำก็ไม่เป็นไร
end

_G.__UFOX_UI_OBJ = { alive=true, api=api }
return api
