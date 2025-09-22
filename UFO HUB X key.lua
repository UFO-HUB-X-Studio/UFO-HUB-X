-- UFO HUB X — Simple Key UI (HMAC verify server)
-- วางใน LocalScript (Client). เปลี่ยน BASE_URL ให้ตรงกับเซิร์ฟเวอร์ของคุณ

local BASE_URL = "https://ufo-hub-x-server-key-777.onrender.com"  -- <<< แก้เป็นของคุณ
local DEFAULT_EXTEND_SEC = 5*60*60

-- ===== Services =====
local Players = game:GetService("Players")
local CG      = game:GetService("CoreGui")
local TS      = game:GetService("TweenService")
local HS      = game:GetService("HttpService")

local LP=Players.LocalPlayer
local function getPG(t)
    t=t or 6
    local t0=os.clock()
    repeat
        local pg = LP and (LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui",1))
        if pg then return pg end
        task.wait(0.1)
    until (os.clock()-t0)>t
end

-- ===== HTTP =====
local function http_get(url)
    if syn and syn.request then
        local ok,res = pcall(syn.request,{Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true,(res.Body or res.body) end
        return false,"syn_request_failed"
    end
    if http and http.request then
        local ok,res = pcall(http.request,{Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true,(res.Body or res.body) end
        return false,"executor_http_request_failed"
    end
    local ok,body = pcall(function() return game:HttpGet(url) end)
    if ok and body then return true,body end
    return false,"roblox_httpget_failed"
end

local function json_get(url)
    for i=1,2 do
        local ok,body = http_get(url)
        if ok and body then
            local okj,data = pcall(function() return HS:JSONDecode(tostring(body)) end)
            if okj then return true,data end
        end
        task.wait(0.25)
    end
    return false,nil
end

local function buildQS(t)
    local parts={}
    for k,v in pairs(t) do
        table.insert(parts, string.format("%s=%s", k, HS:UrlEncode(tostring(v))))
    end
    return (#parts>0) and ("?"..table.concat(parts,"&")) or ""
end

-- ===== UI (แบบเดิม) =====
local function make(class, props, kids)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent=o end
    return o
end

local gui = Instance.new("ScreenGui")
gui.Name="UFOHubX_KeyUI"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local ok = pcall(function() gui.Parent = gethui() end)
if not ok then gui.Parent = CG end
if not gui.Parent then
    local pg = getPG(6)
    if pg then gui.Parent = pg else gui.Parent = CG end
end

local PANEL_W,PANEL_H = 740, 430
local ACCENT = Color3.fromRGB(0,255,140)
local BG     = Color3.fromRGB(10,10,10)
local SUB    = Color3.fromRGB(22,22,22)
local FG     = Color3.fromRGB(235,235,235)

local panel = make("Frame",{
    Parent=gui, Active=true, Draggable=true,
    Size=UDim2.fromOffset(PANEL_W,PANEL_H),
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    BackgroundColor3=BG, BorderSizePixel=0, ZIndex=1
},{
    make("UICorner",{CornerRadius=UDim.new(0,22)}),
    make("UIStroke",{Color=ACCENT, Thickness=2, Transparency=0.1})
})
local head = make("Frame",{
    Parent=panel, BackgroundTransparency=0.15, BackgroundColor3=Color3.fromRGB(14,14,14),
    Size=UDim2.new(1,-28,0,68), Position=UDim2.new(0,14,0,14), ZIndex=5
},{
    make("UICorner",{CornerRadius=UDim.new(0,16)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.85})
})
make("TextLabel",{
    Parent=head, BackgroundTransparency=1, Position=UDim2.new(0,20,0,18),
    Size=UDim2.new(0,240,0,32), Font=Enum.Font.GothamBold, TextSize=20,
    Text="KEY SYSTEM", TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6
},{})

-- Key label + box
make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,188),
    Size=UDim2.new(0,60,0,22), Font=Enum.Font.Gotham, TextSize=16,
    Text="Key", TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
},{})

local keyStroke
local keyBox = make("TextBox",{
    Parent=panel, ClearTextOnFocus=false, PlaceholderText="insert your key here",
    Font=Enum.Font.Gotham, TextSize=16, Text="", TextColor3=FG,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,40), Position=UDim2.new(0,28,0,214)
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)}),
    (function() keyStroke=make("UIStroke",{Color=ACCENT, Transparency=0.75}); return keyStroke end)()
})

local btnSubmit = make("TextButton",{
    Parent=panel, Text="🔒  Submit Key", Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(210,60,60), BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,50), Position=UDim2.new(0,28,0,268)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)})
})

local statusLabel = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,268+50+6),
    Size=UDim2.new(1,-56,0,24), Font=Enum.Font.Gotham, TextSize=14, Text="",
    TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
},{})

local function setStatus(t, ok)
    statusLabel.Text = t or ""
    if ok==nil then
        statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
    elseif ok then
        statusLabel.TextColor3 = Color3.fromRGB(120,255,170)
    else
        statusLabel.TextColor3 = Color3.fromRGB(255,120,120)
    end
end

local function hms(sec)
    sec=math.max(0, tonumber(sec) or 0)
    local h=math.floor(sec/3600); local m=math.floor((sec%3600)/60); local s=math.floor(sec%60)
    local function pad(x) x=tostring(x); return (#x<2) and ("0"..x) or x end
    return string.format("%s:%s:%s", pad(h),pad(m),pad(s))
end

-- Normalize คีย์ (ยอมรับทั้งมี/ไม่มี UFO- และ -48H)
local function normalizeKeyLua(s)
    local v = tostring(s or ""):gsub("%s+","")
    if v=="" then return v end
    v = v:gsub("^ufo%-","UFO-")
    v = v:gsub("%-48[hH]$","-48H")
    if not v:match("^UFO%-") then v = "UFO-"..v end
    if not v:match("%-48H$") then v = v.."-48H" end
    return v
end

-- Submit flow
local submitting=false
local function refreshSubmit()
    if submitting then return end
    if keyBox.Text~="" then
        btnSubmit.BackgroundColor3 = Color3.fromRGB(60,200,120)
        btnSubmit.TextColor3 = Color3.new(0,0,0)
        btnSubmit.Text = "🔓  Submit Key"
    else
        btnSubmit.BackgroundColor3 = Color3.fromRGB(210,60,60)
        btnSubmit.TextColor3 = Color3.new(1,1,1)
        btnSubmit.Text = "🔒  Submit Key"
    end
end
keyBox:GetPropertyChangedSignal("Text"):Connect(function() refreshSubmit(); setStatus("",nil) end)
refreshSubmit()

local function verifyKey(k)
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local url = BASE_URL.."/verify"..buildQS({ key=k, uid=uid, place=place })
    return json_get(url)
end

local function doSubmit()
    if submitting then return end
    local k = keyBox.Text or ""
    if k=="" then setStatus("โปรดใส่คีย์ก่อน", false); return end
    submitting=true; btnSubmit.Active=false
    k = normalizeKeyLua(k); keyBox.Text = k
    setStatus("กำลังตรวจสอบคีย์...", nil)

    local ok,data = verifyKey(k)
    if not ok or not data then
        setStatus("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่อีกครั้ง", false)
        submitting=false; btnSubmit.Active=true; refreshSubmit()
        return
    end
    if data.ok and data.valid then
        setStatus("ยืนยันคีย์สำเร็จ เหลือเวลา: "..hms((tonumber(data.expires_at) or 0) - os.time()), true)
        _G.UFO_HUBX_KEY_OK = true
        _G.UFO_HUBX_KEY    = k
        submitting=false; btnSubmit.Active=true; refreshSubmit()
        -- TODO: เรียกเปิด UI หลัก/สคริปต์หลักของแกต่อจากนี้ได้เลย
    else
        local r = tostring(data.reason or "invalid")
        if r=="expired" then setStatus("คีย์หมดอายุแล้ว", false)
        elseif r=="mismatch" then setStatus("คีย์ไม่ตรงกับ UID/Place นี้", false)
        elseif r=="signature" then setStatus("ลายเซ็นคีย์ไม่ถูกต้อง", false)
        else setStatus("คีย์ไม่ถูกต้อง", false) end
        submitting=false; btnSubmit.Active=true; refreshSubmit()
    end
end

btnSubmit.MouseButton1Click:Connect(doSubmit)
btnSubmit.Activated:Connect(doSubmit)

-- GET KEY (copy link)
local btnGetKey = make("TextButton",{
    Parent=panel, Text="🔐  Get Key", Font=Enum.Font.GothamBold, TextSize=18,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false, BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,44), Position=UDim2.new(0,28,0,324)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})

local function copy(s) if setclipboard then pcall(setclipboard, s) end end

btnGetKey.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local url = BASE_URL .. "/" .. buildQS({ uid=uid, place=place })
    copy(url)
    setStatus("คัดลอกลิงก์หน้าเว็บแล้ว เปิดในเบราว์เซอร์เพื่อรับคีย์", true)
    btnGetKey.Text = "✅ Link copied!"
    task.delay(1.4, function() if btnGetKey and btnGetKey.Parent then btnGetKey.Text="🔐  Get Key" end end)
end)
