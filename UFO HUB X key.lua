-- UFO HUB X — Key UI DIAG (Non-destructive)
-- Purpose: help when UI doesn't show up. Prints step-by-step and forces parenting/visibility.

local Players = game:GetService("Players")
local CG      = game:GetService("CoreGui")
local TS      = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UIS     = game:GetService("UserInputService")

local function log(...) print("[UFO-DIAG]", ...) end
pcall(function() if not game:IsLoaded() then log("waiting game:IsLoaded"); game.Loaded:Wait() end end)

local LP
do
    local t0=os.clock()
    repeat
        LP = Players.LocalPlayer
        if LP then break end
        task.wait(0.05)
    until (os.clock()-t0)>12
end
if not LP then log("LocalPlayer nil after wait"); end

local function _getPG(timeout)
    local t1=os.clock()
    repeat
        if LP then
            local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui",2)
            if pg then return pg end
        end
        task.wait(0.10)
    until (os.clock()-t1)>(timeout or 6)
end
local PREP_PG = _getPG(6)
if not PREP_PG then log("PlayerGui not found") else log("PlayerGui OK") end

local function SOFT_PARENT(gui)
    if not gui then return end
    pcall(function()
        if gui:IsA("ScreenGui") then
            gui.Enabled=true
            gui.DisplayOrder=999999
            gui.ResetOnSpawn=false
            gui.IgnoreGuiInset=true
            gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        end
    end)
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) log("syn.protect_gui OK") end) end
    local ok=false
    if gethui then ok=pcall(function() gui.Parent=gethui(); log("parented to gethui") end) end
    if (not ok) or (not gui.Parent) then ok=pcall(function() gui.Parent=CG; log("parented to CoreGui") end) end
    if (not ok) or (not gui.Parent) then
        local pg = PREP_PG or _getPG(4)
        if pg then pcall(function() gui.Parent=pg; log("parented to PlayerGui") end) else log("NO PARENT TARGET") end
    end
    if not gui.Parent then log("FAILED TO PARENT GUI") else log("PARENTED OK", tostring(gui.Parent)) end
end

-- Kill previous instance (disable only)
pcall(function()
    local old = CG:FindFirstChild("UFOHubX_KeyUI") or (PREP_PG and PREP_PG:FindFirstChild("UFOHubX_KeyUI"))
    if old and old:IsA("ScreenGui") then
        old.Enabled=false
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name="UFOHubX_KeyUI"
SOFT_PARENT(gui)

-- Panel (minimal)
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(400,240)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,16)

local title = Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Text = "UFO HUB X — KEY UI (DIAG)"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0,10,0,10)
title.Parent = panel

local info = Instance.new("TextLabel")
info.BackgroundTransparency=1
info.Text = "ถ้าคุณเห็นกล่องนี้ แปลว่า GUI แสดงผลได้ ✅"
info.TextWrapped=true
info.TextColor3 = Color3.fromRGB(210,210,210)
info.Font = Enum.Font.Gotham
info.TextSize = 16
info.Size = UDim2.new(1,-20,0,60)
info.Position = UDim2.new(0,10,0,50)
info.Parent = panel

local btn = Instance.new("TextButton")
btn.Text = "Force Show / Bring To Front"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Size = UDim2.new(1,-20,0,40)
btn.Position = UDim2.new(0,10,0,120)
btn.BackgroundColor3 = Color3.fromRGB(40,180,120)
btn.TextColor3 = Color3.new(0,0,0)
btn.Parent = panel
Instance.new("UICorner", btn).CornerRadius = UDim.new(0,12)

btn.MouseButton1Click:Connect(function()
    SOFT_PARENT(gui)
    gui.Enabled=true
    panel.Visible=true
    panel.BackgroundTransparency=0
    print("[UFO-DIAG] bring-to-front clicked")
end)

-- Hotkey: F8 to force show
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F8 then
        SOFT_PARENT(gui)
        gui.Enabled = true
        print("[UFO-DIAG] F8 force show")
    end
end)

print("[UFO-DIAG] ready. If you DON'T see the box, copy all [UFO-DIAG] logs for me.")
