-- UFO HUB X — Alien UI Bootloader (UI-only + self-heal + hard diagnostics)
-- ใส่เป็น LocalScript ใน StarterPlayerScripts หรือ StarterGui

-- ===== Services =====
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local StarterGui    = game:GetService("StarterGui")

-- ===== Hard Checks (ถ้าไม่ใช่ LocalScript / ไม่มี LocalPlayer จะแจ้งบนจอ) =====
local lp = Players.LocalPlayer
if not lp then
	-- โผล่บนจอแรง ๆ
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title   = "UFO HUB X",
			Text    = "⚠️ ต้องใช้ LocalScript ใน StarterPlayerScripts / StarterGui",
			Duration= 8
		})
	end)
	warn("[UFO] ไม่พบ LocalPlayer — ใส่สคริปต์นี้เป็น LocalScript เท่านั้น")
	return
end

local playerGui = lp:WaitForChild("PlayerGui", 5)
if not playerGui then
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "UFO HUB X",
			Text  = "⚠️ ไม่พบ PlayerGui — ลองกด Play (F5) ไม่ใช่ Run",
			Duration = 8
		})
	end)
	warn("[UFO] ไม่พบ PlayerGui — ต้องกด Play (F5)")
	return
end

-- ===== Theme =====
local ALIEN_GREEN   = Color3.fromRGB(0,255,140)
local DARK_BG       = Color3.fromRGB(15,16,18)
local DARK_ELEM     = Color3.fromRGB(26,27,32)
local GRAY_ACCENT   = Color3.fromRGB(115,118,122)
local BLACK         = Color3.fromRGB(0,0,0)

local function styleText(txt: TextLabel|TextButton)
	txt.TextColor3 = ALIEN_GREEN
	txt.TextStrokeColor3 = BLACK
	txt.TextStrokeTransparency = 0.2
	txt.Font = Enum.Font.GothamBold
end

-- ===== Utils =====
local function clampToViewport(guiObj: GuiObject)
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
	local p  = guiObj.AbsolutePosition
	local s  = guiObj.AbsoluteSize
	local nx = math.clamp(p.X, 8, math.max(8, vp.X - s.X - 8))
	local ny = math.clamp(p.Y, 8, math.max(8, vp.Y - s.Y - 8))
	guiObj.Position = UDim2.fromOffset(nx, ny)
end

local function smoothDrag(btn: GuiObject, target: GuiObject)
	local dragging, dragStart, startPos = false, nil, nil
	btn.Active = true
	btn.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true; dragStart=i.Position; startPos=target.Position
			i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
			TweenService:Create(target, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=newPos}):Play()
		end
	end)
end

local function fadeShow(frame: GuiObject)
	frame.Visible = true
	frame.BackgroundTransparency = 1
	local from = frame.Position - UDim2.new(0,0,0,20)
	frame.Position = from
	TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = from + UDim2.new(0,0,0,20), BackgroundTransparency = 0}):Play()
	for _,d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			d.TextTransparency = 1
			TweenService:Create(d, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
		elseif d:IsA("Frame") or d:IsA("ImageLabel") then
			if d.BackgroundTransparency ~= nil then
				local bt = d.BackgroundTransparency
				d.BackgroundTransparency = 1
				TweenService:Create(d, TweenInfo.new(0.2), {BackgroundTransparency = bt or 0}):Play()
			end
		end
	end
end

local function fadeHide(frame: GuiObject)
	local to = frame.Position - UDim2.new(0,0,0,20)
	local tw = TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = to, BackgroundTransparency = 1})
	tw:Play()
	for _,d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			TweenService:Create(d, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
		elseif d:IsA("Frame") or d:IsA("ImageLabel") then
			if d.BackgroundTransparency ~= nil then
				TweenService:Create(d, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
			end
		end
	end
	task.delay(0.18, function() frame.Visible = false end)
end

-- ===== Build UI (self-heal ถ้าหาย) =====
local screen : ScreenGui
local main   : Frame
local titleBar: Frame
local toggleBtn: TextButton
local closeBtn : TextButton

local function buildOnce()
	if screen and screen.Parent then return end

	screen = Instance.new("ScreenGui")
	screen.Name = "UFO_UI"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 1000
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui

	-- Floating button
	toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UFO_Toggle"
	toggleBtn.Size = UDim2.new(0, 96, 0, 96)
	toggleBtn.Position = UDim2.new(0, 24, 0.5, -48)
	toggleBtn.BackgroundColor3 = DARK_ELEM
	toggleBtn.Text = "เมนู"
	toggleBtn.TextSize = 18
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextColor3 = ALIEN_GREEN
	toggleBtn.AutoButtonColor = true
	toggleBtn.Parent = screen
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)
	local tStroke = Instance.new("UIStroke", toggleBtn); tStroke.Thickness = 2; tStroke.Color = GRAY_ACCENT
	smoothDrag(toggleBtn, toggleBtn)

	-- Main window
	main = Instance.new("Frame")
	main.Name = "MainWindow"
	main.Size = UDim2.new(0, 640, 0, 430)
	main.Position = UDim2.new(0.5, -320, 0.5, -215)
	main.BackgroundColor3 = DARK_BG
	main.BorderSizePixel = 0
	main.Visible = true
	main.Parent = screen
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	local mainStroke = Instance.new("UIStroke", main); mainStroke.Thickness = 2; mainStroke.Color = GRAY_ACCENT

	-- Title bar
	titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 44)
	titleBar.BackgroundColor3 = DARK_ELEM
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 1, 0)
	title.Position = UDim2.new(0, 45, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "👽 UFO HUB X — Alien Edition"
	title.TextSize = 20
	title.Parent = titleBar
	styleText(title)

	-- Close (X) — ขวามือ
	closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseX"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
	closeBtn.BackgroundColor3 = DARK_ELEM
	closeBtn.Text = "X"
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = ALIEN_GREEN
	closeBtn.AutoButtonColor = true
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	local xStroke = Instance.new("UIStroke", closeBtn); xStroke.Thickness = 1.5; xStroke.Color = GRAY_ACCENT

	-- Tabs bar
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Size = UDim2.new(1, -16, 0, 38)
	tabsBar.Position = UDim2.new(0, 8, 0, 54)
	tabsBar.BackgroundColor3 = DARK_ELEM
	tabsBar.Parent = main
	Instance.new("UICorner", tabsBar).CornerRadius = UDim.new(0, 8)

	-- Layout ปุ่มแท็บ
	local list = Instance.new("UIListLayout", tabsBar)
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.Padding = UDim.new(0, 8)

	-- Content
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -16, 1, -108)
	content.Position = UDim2.new(0, 8, 0, 100)
	content.BackgroundColor3 = DARK_ELEM
	content.Parent = main
	Instance.new("UICorner", content).CornerRadius = UDim.new(0, 10)

	-- Tabs + Pages (UI เท่านั้น)
	local TAB_ORDER = {"หน้าหลัก","ผู้เล่น","ภาพ/แสง","เทเลพอร์ต","ตั้งค่า","เครดิต"}
	local tabBtns, pages = {}, {}
	local function mkTab(name: string)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 96, 1, 0)
		b.BackgroundColor3 = DARK_BG
		b.Text = name
		b.TextSize = 15
		b.AutoButtonColor = true
		b.Parent = tabsBar
		styleText(b)
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		local s = Instance.new("UIStroke", b); s.Thickness = 1.2; s.Color = GRAY_ACCENT
		return b
	end
	local function mkPage(name: string)
		local p = Instance.new("Frame")
		p.Name = "Page_"..name
		p.Size = UDim2.new(1, -16, 1, -16)
		p.Position = UDim2.new(0, 8, 0, 8)
		p.BackgroundTransparency = 1
		p.Visible = false
		p.Parent = content
		local lbl = Instance.new("TextLabel", p)
		lbl.Size = UDim2.new(1, 0, 0, 26)
		lbl.BackgroundTransparency = 1
		lbl.Text = "หน้านี้คือ: "..name
		lbl.TextSize = 18
		styleText(lbl)
		return p
	end

	for _, n in ipairs(TAB_ORDER) do
		tabBtns[n] = mkTab(n)
		pages[n]   = mkPage(n)
	end

	local current
	local function switchTo(n)
		if current then pages[current].Visible = false end
		current = n
		pages[n].Visible = true
	end
	for n, b in pairs(tabBtns) do
		b.MouseButton1Click:Connect(function() switchTo(n) end)
	end
	switchTo("หน้าหลัก")

	-- Drag ทั้งกรอบ (จับที่ TitleBar; ถ้าพลาด Frame ก็ลากได้)
	local function enableDrag(frame: GuiObject, handle: GuiObject?)
		handle = handle or frame
		frame.Active = true
		if handle ~= frame then handle.Active = true end
		frame.Draggable = false
		local dragging, dragStart, startPos = false
		handle.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dragging=true; dragStart=i.Position; startPos=frame.Position
				i.Changed:Connect(function()
					if i.UserInputState==Enum.UserInputState.End then dragging=false end
				end)
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
			end
		end)
	end
	enableDrag(main, titleBar)

	-- ปุ่มลอย: โชว์/ซ่อน UI หลัก
	local function showMain()
		clampToViewport(main)
		fadeShow(main)
	end
	local function hideMain()
		fadeHide(main)
	end
	toggleBtn.MouseButton1Click:Connect(function()
		if main.Visible then hideMain() else showMain() end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		if main.Visible then hideMain() end
	end)

	-- แจ้งเตือนขึ้นจอ (ให้รู้ว่าโหลดสำเร็จ)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "UFO HUB X",
			Text  = "UI โหลดแล้ว • ถ้าไม่เห็นให้กดปุ่ม “เมนู” ซ้ายจอ",
			Duration = 6
		})
	end)
end

-- สร้างทันที + ถ้าหายจะสร้างใหม่ให้อัตโนมัติ
buildOnce()
RunService.RenderStepped:Connect(function()
	if not screen or not screen.Parent then
		warn("[UFO] screen หลุดจาก PlayerGui → สร้างใหม่")
		buildOnce()
	end
end)
