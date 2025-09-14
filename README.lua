-- ✅ ห้ามลบ/ห้ามแก้: โค้ดต้นฉบับของคุณ
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("UFO HUB X", "DarkTheme")

-- 🎨 ธีมกำหนดเอง: เทาเข้มสุภาพ (แทนทุกจุดที่เคยเป็นแดง)
local GrayTheme = {
    SchemeColor  = Color3.fromRGB(120,120,125), -- สีเน้น (แทนแดงทั้งหมด)
    Background   = Color3.fromRGB(15,15,17),
    Header       = Color3.fromRGB(15,15,17),
    TextColor    = Color3.fromRGB(210,255,210), -- เขียวอ่อนอ่านง่าย (ยังโทนเอเลี่ยน)
    ElementColor = Color3.fromRGB(26,26,30)
}

-- 👽 ใช้ธีมเทา
local AlienUI = Library.CreateLib("UFO HUB X  👽  ALIEN EDITION", GrayTheme)

-- ========== MAIN TAB ==========
local TabMain   = AlienUI:NewTab("Main")
local SecMain   = TabMain:NewSection("👽 Alien Controls")
SecMain:NewToggle("UFO Mode","",function(s) print(s and "[UFO] ON" or "[UFO] OFF") end)
SecMain:NewButton("Hyper Boost","",function() print("[UFO] Boost") end)
SecMain:NewSlider("Energy Level","",100,0,function(v) print("[UFO] Energy:",v) end)

-- ========== PLAYER TAB ==========
local TabPlayer = AlienUI:NewTab("Player")
local SecPlayer = TabPlayer:NewSection("🧬 Player Tweaks")
SecPlayer:NewSlider("WalkSpeed","",100,16,function(v) pcall(function() game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=v end) end)
SecPlayer:NewSlider("JumpPower","",150,50,function(v) pcall(function() game.Players.LocalPlayer.Character.Humanoid.JumpPower=v end) end)
SecPlayer:NewToggle("NoClip","",function(state)
    local lp=game.Players.LocalPlayer; if not lp.Character then return end
    getgenv()._UFO_NOCLIP=state
    if state and not getgenv()._UFO_NC_CONN then
        getgenv()._UFO_NC_CONN=game:GetService("RunService").Stepped:Connect(function()
            pcall(function() for _,p in ipairs(lp.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end)
        end)
    elseif not state and getgenv()._UFO_NC_CONN then
        getgenv()._UFO_NC_CONN:Disconnect(); getgenv()._UFO_NC_CONN=nil
        pcall(function() for _,p in ipairs(lp.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end)
    end
end)

-- ========== VISUAL / TELEPORT / SETTINGS / CREDITS ==========
local TabVisual = AlienUI:NewTab("Visual")
local SecVisual = TabVisual:NewSection("🌌 Visual FX")
SecVisual:NewToggle("Night Vision","",function(on)
    local l=game.Lighting
    if on then getgenv()._UFO_LIGHTING_BACKUP={Brightness=l.Brightness,ClockTime=l.ClockTime}; l.Brightness=3; l.ClockTime=0
    else if getgenv()._UFO_LIGHTING_BACKUP then l.Brightness=getgenv()._UFO_LIGHTING_BACKUP.Brightness; l.ClockTime=getgenv()._UFO_LIGHTING_BACKUP.ClockTime end end
end)
SecVisual:NewButton("Alien Scan Pulse","",function() print("[UFO] Scan") end)

local TabTP=AlienUI:NewTab("Teleport")
local SecTP=TabTP:NewSection("🛰️ Quick Teleports")
for name,cf in pairs({["Spawn"]=CFrame.new(0,10,0),["Alpha Site"]=CFrame.new(100,25,-50),["Beta Site"]=CFrame.new(-120,30,140)}) do
    SecTP:NewButton(name,"",function() local lp=game.Players.LocalPlayer; if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.CFrame=cf end end)
end

local TabSet=AlienUI:NewTab("Settings")
local SecSet=TabSet:NewSection("⚙️ UI Settings")
SecSet:NewKeybind("Toggle UI","",Enum.KeyCode.RightControl,function() Library:ToggleUI() end)
SecSet:NewDropdown("Theme","",{"Sentinel","Midnight","Synapse","GrapeTheme","BloodTheme","Ocean","LightTheme","DarkTheme"},function(t) print("[UFO] Theme requested:",t) end)

local TabCred=AlienUI:NewTab("Credits")
local SecCred=TabCred:NewSection("🛸 About / Credits")
SecCred:NewLabel("UFO HUB X — Alien Edition")
SecCred:NewLabel("Design: Alien Green • Clean • Modern")
SecCred:NewLabel("Made by: แม็ก")

pcall(function() if Library and Library.Notify then Library:Notify("UFO HUB X","Alien UI (Gray Accents) Loaded",5) end end)

-- =========================================================
-- 🧩 บังคับ “ข้อความกึ่งกลางจริง ๆ” ด้วย Overlay (ไม่เปลี่ยนขนาดเดิม)
--   - ซ่อนข้อความเดิมของ Kavo แล้วซ้อน Label ใหม่กึ่งกลาง 100%
--   - ใส่ขอบตัวหนังสือให้คมชัด
--   - ใช้กับทุก TextLabel/TextButton ในหน้าต่าง UFO HUB X เท่านั้น
-- =========================================================
local CoreGui = game:GetService("CoreGui")

local function isUfoRoot(gui)
    return gui:IsA("ScreenGui") and gui.Name:lower():find("kavo") ~= nil
end

local function findUfoGui()
    -- หา ScreenGui ของ Kavo ที่มีข้อความหัว "UFO HUB X"
    for _,d in ipairs(CoreGui:GetDescendants()) do
        if d:IsA("TextLabel") and typeof(d.Text)=="string" and d.Text:find("UFO HUB X") then
            return d:FindFirstAncestorOfClass("ScreenGui") or CoreGui
        end
    end
    return CoreGui
end

local function centerOverlayFor(lbl)
    if not (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) then return end
    if lbl:GetAttribute("_UFO_CENTERED") then return end
    lbl:SetAttribute("_UFO_CENTERED", true)

    -- เว้นที่ด้านซ้ายกันไอคอนทับ (14px)
    lbl.TextTransparency = 1
    local overlay = Instance.new("TextLabel")
    overlay.Name = "UFO_CenterText"
    overlay.AnchorPoint = Vector2.new(0.5, 0.5)
    overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
    overlay.Size = UDim2.new(1, -14, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = (lbl.ZIndex or 1) + 1

    overlay.Font = lbl.Font
    overlay.TextSize = lbl.TextSize
    overlay.RichText = lbl.RichText
    overlay.Text = lbl.Text
    overlay.TextColor3 = lbl.TextColor3
    overlay.TextXAlignment = Enum.TextXAlignment.Center
    overlay.TextYAlignment = Enum.TextYAlignment.Center
    overlay.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    overlay.TextStrokeTransparency = 0.2

    overlay.Parent = lbl
end

local function applyToTree(root)
    for _,o in ipairs(root:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") then
            centerOverlayFor(o)
        end
    end
    root.DescendantAdded:Connect(function(o)
        task.defer(function() centerOverlayFor(o) end)
    end)
end

task.delay(0.25, function()
    local root = findUfoGui()
    applyToTree(root)
end)
