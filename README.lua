-- UFO HUB X - MAIN UI (README.lua) - short & safe
local Players = game:GetService("Players")
local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
local g = Instance.new("ScreenGui"); g.Name="UFOX_MAIN"; g.ResetOnSpawn=false; g.IgnoreGuiInset=true; g.DisplayOrder=8000; g.Parent=pgui

local main = Instance.new("Frame", g)
main.AnchorPoint=Vector2.new(0.5,0.5); main.Position=UDim2.fromScale(0.5,0.5)
main.Size=UDim2.fromOffset(820,420); main.BackgroundColor3=Color3.fromRGB(18,21,24)
local c=Instance.new("UICorner",main); c.CornerRadius=UDim.new(0,14)
local s=Instance.new("UIStroke",main); s.Thickness=2; s.Color=Color3.fromRGB(255,255,255); s.Transparency=0.75

local bar = Instance.new("Frame", main); bar.Size=UDim2.new(1,0,0,52); bar.BackgroundColor3=Color3.fromRGB(12,14,16)
local cb=Instance.new("UICorner",bar); cb.CornerRadius=UDim.new(0,14)
local sb=Instance.new("UIStroke",bar); sb.Thickness=1; sb.Color=Color3.fromRGB(255,255,255); sb.Transparency=0.85

local title = Instance.new("TextLabel", bar)
title.BackgroundTransparency=1; title.Position=UDim2.new(0,16,0,0); title.Size=UDim2.new(1,-70,1,0)
title.Font=Enum.Font.GothamBlack; title.TextSize=20; title.RichText=true
title.Text='<font color="#16F77B">UFO</font> HUB X'; title.TextColor3=Color3.fromRGB(230,238,245); title.TextXAlignment=Enum.TextXAlignment.Left

local close = Instance.new("TextButton", bar)
close.Size=UDim2.fromOffset(32,32); close.Position=UDim2.new(1,-44,0.5,-16)
close.Text="✕"; close.Font=Enum.Font.GothamBold; close.TextSize=18
close.BackgroundColor3=Color3.fromRGB(25,29,33); local cc=Instance.new("UICorner",close); cc.CornerRadius=UDim.new(0,8)
local sc=Instance.new("UIStroke",close); sc.Thickness=1; sc.Color=Color3.fromRGB(255,255,255); sc.Transparency=0.85

-- สองซีก
local content = Instance.new("Frame", main)
content.Position=UDim2.new(0,12,0,66); content.Size=UDim2.new(1,-24,1,-78); content.BackgroundColor3=Color3.fromRGB(12,14,16)
local co=Instance.new("UICorner",content); co.CornerRadius=UDim.new(0,10); local so=Instance.new("UIStroke",content); so.Thickness=1; so.Color=Color3.fromRGB(255,255,255); so.Transparency=0.85
local left = Instance.new("Frame", content); left.Size=UDim2.new(0.5,-8,1,-12); left.Position=UDim2.new(0,6,0,6); left.BackgroundColor3=Color3.fromRGB(18,21,24); local cl=Instance.new("UICorner",left); cl.CornerRadius=UDim.new(0,10); local sl=Instance.new("UIStroke",left); sl.Thickness=1; sl.Color=Color3.fromRGB(255,255,255); sl.Transparency=0.85
local right= Instance.new("Frame", content); right.Size=UDim2.new(0.5,-8,1,-12); right.Position=UDim2.new(0.5,2,0,6); right.BackgroundColor3=Color3.fromRGB(18,21,24); local cr=Instance.new("UICorner",right); cr.CornerRadius=UDim.new(0,10); local sr=Instance.new("UIStroke",right); sr.Thickness=1; sr.Color=Color3.fromRGB(255,255,255); sr.Transparency=0.85

-- ปุ่มลอยเปิด/ปิด
local tog = Instance.new("Frame", g)
tog.Size=UDim2.fromOffset(88,88); tog.Position=UDim2.new(0,24,0.25,-44); tog.BackgroundColor3=Color3.fromRGB(18,21,24)
local ct=Instance.new("UICorner",tog); ct.CornerRadius=UDim.new(0,16); local st=Instance.new("UIStroke",tog); st.Thickness=2; st.Color=Color3.fromRGB(255,255,255); st.Transparency=0.65
local ib=Instance.new("ImageLabel", tog); ib.BackgroundTransparency=1; ib.Size=UDim2.fromScale(1,1); ib.Image="rbxthumb://type=Asset&id=106029438403666&w=150&h=150"
local tb=Instance.new("TextButton", tog); tb.BackgroundTransparency=1; tb.Size=UDim2.fromScale(1,1); tb.Text=""

local UIS = game:GetService("UserInputService"); local TweenService=game:GetService("TweenService")
local dragging, start, base
tog.Active=true; tog.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; start=i.Position; base=tog.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
  local d=i.Position-start; TweenService:Create(tog, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.new(base.X.Scale, base.X.Offset+d.X, base.Y.Scale, base.Y.Offset+d.Y)}):Play()
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

local showing=false; main.Visible=false
local function show() if showing then return end showing=true; main.Visible=true; main.BackgroundTransparency=1; main.Position=UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset+16)
  TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0, Position=UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset-16)}):Play()
end
local function hide() if not showing then return end showing=false
  TweenService:Create(main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency=1, Position=UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset+16)}):Play()
  task.delay(0.16,function() main.Visible=false end)
end
tb.MouseButton1Click:Connect(function() if main.Visible then hide() else show() end end)
close.MouseButton1Click:Connect(hide)

return { start=function() end, run=function() end, open=function() end }
