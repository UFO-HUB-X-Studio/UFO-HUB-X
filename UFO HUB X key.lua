--========================================================
-- UFO HUB X — KEY UI (Server-Enabled, Web-only GET KEY)
-- - ใช้ /verify?key=&uid=&place= สำหรับตรวจคีย์
-- - ปุ่ม Get Key จะ "คัดลอกลิงก์หน้าเว็บ" เท่านั้น (ไม่เรียก /getkey ในเกม)
-- - ปลอดภัยต่อรายได้ฝั่งเว็บแน่นอน
--========================================================

-------------------- Safe Prelude --------------------
local Players     = game:GetService("Players")
local CG          = game:GetService("CoreGui")
local TS          = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

pcall(function() if not game:IsLoaded() then game.Loaded:Wait() end end)

local LP = Players.LocalPlayer
do
    local t0=os.clock()
    repeat
        LP = Players.LocalPlayer
        if LP then break end
        task.wait(0.05)
    until (os.clock()-t0)>12
end

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
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end
    local ok=false
    if gethui then ok=pcall(function() gui.Parent=gethui() end) end
    if (not ok) or (not gui.Parent) then ok=pcall(function() gui.Parent=CG end) end
    if (not ok) or (not gui.Parent) then
        local pg = PREP_PG or _getPG(4)
        if pg then pcall(function() gui.Parent=pg end) end
    end
end

-------------------- FORCE SERVER --------------------
-- ❗ เปลี่ยน URL ตรงนี้ถ้ามีฐานใหม่
_G.UFO_LAST_BASE = nil   -- เคลียร์ความจำเก่า
local FORCE_BASE = "https://ufo-hub-x-server-key-777.onrender.com"

local function sanitizeBase(b)
    b = tostring(b or ""):gsub("%s+","")
    return (b:gsub("[/]+$",""))
end
if type(FORCE_BASE)=="string" and #FORCE_BASE>0 then
    FORCE_BASE = sanitizeBase(FORCE_BASE)
    _G.UFO_SERVER_BASE = FORCE_BASE
    _G.UFO_LAST_BASE   = FORCE_BASE
end

-------------------- Theme --------------------
local LOGO_ID   = 112676905543996
local ACCENT    = Color3.fromRGB(0,255,140)
local BG_DARK   = Color3.fromRGB(10,10,10)
local FG        = Color3.fromRGB(235,235,235)
local SUB       = Color3.fromRGB(22,22,22)
local RED       = Color3.fromRGB(210,60,60)
local GREEN     = Color3.fromRGB(60,200,120)

-------------------- Links --------------------
local DISCORD_URL = "https://discord.gg/your-server"

-------------------- Allow-list (ผ่านแน่) --------------------
local DEFAULT_TTL_SECONDS = 48*3600
local ALLOW_KEYS = {
    ["JJJMAX"]                 = { reusable=true, ttl=DEFAULT_TTL_SECONDS },
    ["GMPANUPHONGARTPHAIRIN"]  = { reusable=true, ttl=DEFAULT_TTL_SECONDS },
}
local function normKey(s)
    s = tostring(s or ""):gsub("%c",""):gsub("%s+",""):gsub("[^%w]","")
    return string.upper(s)
end
local function isAllowedKey(k)
    local nk = normKey(k)
    local meta = ALLOW_KEYS[nk]
    if meta then return true, nk, meta end
    return false, nk, nil
end

-------------------- HTTP helpers --------------------
local function http_get(url)
    if http and http.request then
        local ok,res = pcall(http.request,{Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true,(res.Body or res.body) end
        return false,"executor_http_request_failed"
    end
    if syn and syn.request then
        local ok,res = pcall(syn.request,{Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true,(res.Body or res.body) end
        return false,"syn_request_failed"
    end
    local ok,body = pcall(function() return game:HttpGet(url) end)
    if ok and body then return true,body end
    return false,"roblox_httpget_failed"
end

local function http_json_get(url)
    local ok,body = http_get(url)
    if not ok or not body then return false,nil,"http_error" end
    local okj,data = pcall(function() return HttpService:JSONDecode(tostring(body)) end)
    if not okj then return false,nil,"json_error" end
    return true,data,nil
end

local function json_get_forced(path_qs)
    local base = sanitizeBase(_G.UFO_SERVER_BASE or FORCE_BASE)
    local url  = base..path_qs
    local ok,data,err = http_json_get(url)
    if ok and data then
        _G.UFO_LAST_BASE = base
        return true,data,base
    end
    return false,nil,err
end

local function verifyWithServer(k)
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local qs = string.format("/verify?key=%s&uid=%s&place=%s",
        HttpService:UrlEncode(k),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    local ok,data = json_get_forced(qs)
    if not ok or not data then return false,"server_unreachable",nil end
    if data.ok and data.valid then
        local exp = tonumber(data.expires_at) or (os.time()+DEFAULT_TTL_SECONDS)
        return true,nil,exp
    else
        return false,tostring(data.reason or "invalid"),nil
    end
end

-------------------- UI utils --------------------
local function make(class, props, kids)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent=o end
    return o
end
local function tween(o, goal, t)
    TS:Create(o, TweenInfo.new(t or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end
local function setClipboard(s) if setclipboard then pcall(setclipboard, s) end end

-------------------- Root GUI --------------------
pcall(function()
    local old = CG:FindFirstChild("UFOHubX_KeyUI")
    if old and old:IsA("ScreenGui") then
        SOFT_PARENT(old)
        old.Enabled = false
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name="UFOHubX_KeyUI"
gui.IgnoreGuiInset=true
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SOFT_PARENT(gui)

task.spawn(function()
    while gui do
        if not gui.Parent then SOFT_PARENT(gui) end
        if gui.Enabled==false then pcall(function() gui.Enabled=true end) end
        task.wait(0.25)
    end
end)

-------------------- Panel --------------------
local PANEL_W,PANEL_H = 740, 430
local panel = make("Frame",{
    Parent=gui, Active=true, Draggable=true,
    Size=UDim2.fromOffset(PANEL_W,PANEL_H),
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    BackgroundColor3=BG_DARK, BorderSizePixel=0, ZIndex=1
},{
    make("UICorner",{CornerRadius=UDim.new(0,22)}),
    make("UIStroke",{Color=ACCENT, Thickness=2, Transparency=0.1})
})

-- close
local btnClose = make("TextButton",{
    Parent=panel, Text="X", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.new(1,1,1),
    AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(210,35,50),
    Size=UDim2.new(0,38,0,38), Position=UDim2.new(1,-50,0,14), ZIndex=50
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)})
})
btnClose.MouseButton1Click:Connect(function()
    pcall(function() if gui and gui.Parent then gui:Destroy() end end)
end)

-- header
local head = make("Frame",{
    Parent=panel, BackgroundTransparency=0.15, BackgroundColor3=Color3.fromRGB(14,14,14),
    Size=UDim2.new(1,-28,0,68), Position=UDim2.new(0,14,0,14), ZIndex=5
},{
    make("UICorner",{CornerRadius=UDim.new(0,16)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.85})
})
make("ImageLabel",{
    Parent=head, BackgroundTransparency=1, Image="rbxassetid://"..LOGO_ID,
    Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,16,0,17), ZIndex=6
},{})
make("TextLabel",{
    Parent=head, BackgroundTransparency=1, Position=UDim2.new(0,60,0,18),
    Size=UDim2.new(0,200,0,32), Font=Enum.Font.GothamBold, TextSize=20,
    Text="KEY SYSTEM", TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6
},{})

-- title
local titleGroup = make("Frame",{Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,102), Size=UDim2.new(1,-56,0,76)},{})
make("UIListLayout",{
    Parent=titleGroup, FillDirection=Enum.FillDirection.Vertical,
    HorizontalAlignment=Enum.HorizontalAlignment.Left, VerticalAlignment=Enum.VerticalAlignment.Top,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)
},{})
make("TextLabel",{
    Parent=titleGroup, LayoutOrder=1, BackgroundTransparency=1, Size=UDim2.new(1,0,0,32),
    Font=Enum.Font.GothamBlack, TextSize=30, Text="Welcome to the,", TextColor3=FG,
    TextXAlignment=Enum.TextXAlignment.Left
},{})
local titleLine2 = make("Frame",{Parent=titleGroup, LayoutOrder=2, BackgroundTransparency=1, Size=UDim2.new(1,0,0,36)},{})
make("UIListLayout",{
    Parent=titleLine2, FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left, VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)
},{})
make("TextLabel",{Parent=titleLine2, LayoutOrder=1, BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack, TextSize=32, Text="UFO", TextColor3=ACCENT, AutomaticSize=Enum.AutomaticSize.X},{})
make("TextLabel",{Parent=titleLine2, LayoutOrder=2, BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack, TextSize=32, Text="HUB X", TextColor3=Color3.new(1,1,1), AutomaticSize=Enum.AutomaticSize.X},{})

-- key input
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

-- submit
local btnSubmit = make("TextButton",{
    Parent=panel, Text="🔒  Submit Key", Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false, BackgroundColor3=RED, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,50), Position=UDim2.new(0,28,0,268)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)})
})

-- toast
local toast = make("TextLabel",{
    Parent=panel, BackgroundTransparency=0.15, BackgroundColor3=Color3.fromRGB(30,30,30),
    Size=UDim2.fromOffset(0,32), Position=UDim2.new(0.5,0,0,16),
    AnchorPoint=Vector2.new(0.5,0), Visible=false, Font=Enum.Font.GothamBold,
    TextSize=14, Text="", TextColor3=Color3.new(1,1,1), ZIndex=100
},{
    make("UIPadding",{PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14)}),
    make("UICorner",{CornerRadius=UDim.new(0,10)})
})
local function showToast(msg, ok)
    toast.Text = msg
    toast.BackgroundColor3 = ok and Color3.fromRGB(20,120,60) or Color3.fromRGB(150,35,35)
    toast.Size = UDim2.fromOffset(math.max(160,(#msg*8)+28),32)
    toast.Visible = true
    toast.BackgroundTransparency = 0.15
    tween(toast,{BackgroundTransparency=0.05},.08)
    task.delay(1.1,function()
        tween(toast,{BackgroundTransparency=1},.15)
        task.delay(.15,function() toast.Visible=false end)
    end)
end

-- status line
local statusLabel = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,268+50+6),
    Size=UDim2.new(1,-56,0,24), Font=Enum.Font.Gotham, TextSize=14, Text="",
    TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
},{})
local function setStatus(txt, ok)
    statusLabel.Text = txt or ""
    if ok==nil then
        statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
    elseif ok then
        statusLabel.TextColor3 = Color3.fromRGB(120,255,170)
    else
        statusLabel.TextColor3 = Color3.fromRGB(255,120,120)
    end
end

-- error fx
local function flashInputError()
    if keyStroke then
        local old=keyStroke.Color
        tween(keyStroke,{Color=Color3.fromRGB(255,90,90), Transparency=0},.05)
        task.delay(0.22,function() tween(keyStroke,{Color=old, Transparency=0.75},.12) end)
    end
    local p0=btnSubmit.Position
    TS:Create(btnSubmit, TweenInfo.new(0.05),{Position=p0+UDim2.fromOffset(-5,0)}):Play()
    task.delay(0.05,function()
        TS:Create(btnSubmit, TweenInfo.new(0.05),{Position=p0+UDim2.fromOffset(5,0)}):Play()
        task.delay(0.05,function()
            TS:Create(btnSubmit, TweenInfo.new(0.05),{Position=p0}):Play()
        end)
    end)
end

-- fade destroy
local function fadeOutAndDestroy()
    for _,d in ipairs(panel:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=1}):Play()
                if d:IsA("TextBox") or d:IsA("TextButton") then
                    TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency=1, BackgroundTransparency=1}):Play()
            elseif d:IsA("Frame") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
            elseif d:IsA("UIStroke") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency=1}):Play()
            end
        end)
    end
    TS:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
    task.delay(0.22,function() if gui and gui.Parent then gui:Destroy() end end)
end

-- submit button state
local submitting=false
local function refreshSubmit()
    if submitting then return end
    local hasText = (keyBox.Text and #keyBox.Text>0)
    if hasText then
        tween(btnSubmit,{BackgroundColor3=GREEN},.08)
        btnSubmit.Text="🔓  Submit Key"
        btnSubmit.TextColor3=Color3.new(0,0,0)
    else
        tween(btnSubmit,{BackgroundColor3=RED},.08)
        btnSubmit.Text="🔒  Submit Key"
        btnSubmit.TextColor3=Color3.new(1,1,1)
    end
end
keyBox:GetPropertyChangedSignal("Text"):Connect(function() setStatus("",nil); refreshSubmit() end)
refreshSubmit()
keyBox.FocusLost:Connect(function(enter) if enter then btnSubmit:Activate() end end)

-------------------- Submit Flow --------------------
local function forceErrorUI(mainText, toastText)
    tween(btnSubmit,{BackgroundColor3=Color3.fromRGB(255,80,80)},.08)
    btnSubmit.Text = mainText or "❌ Invalid Key"
    btnSubmit.TextColor3 = Color3.new(1,1,1)
    setStatus(toastText or "กุญแจไม่ถูกต้อง ลองอีกครั้ง", false)
    showToast(toastText or "รหัสไม่ถูกต้อง", false)
    flashInputError()
    keyBox.Text = ""
    task.delay(0.02,function() keyBox:CaptureFocus() end)
    task.delay(1.2,function() submitting=false; btnSubmit.Active=true; refreshSubmit() end)
end

-- เพิ่มตัวช่วย normalize ให้คีย์เข้ารูป UFO-XXXX-48H อัตโนมัติ
local function normalizeKeyLua(s)
    s = tostring(s or ""):upper():gsub("%s+","")
    if s ~= "" then
        if not s:match("^UFO%-") then s = "UFO-"..(s:gsub("^%-+","")) end
        if not s:match("%-48H$") then s = s:gsub("%-48H$","").."-48H" end
    end
    return s
end

local function verifyWithAllowedOrServer(k)
    local allowed,_,meta = isAllowedKey(k)
    if allowed then
        local exp = os.time() + (tonumber(meta.ttl) or DEFAULT_TTL_SECONDS)
        return true,nil,exp
    end
    return verifyWithServer(k)
end

local function doSubmit()
    if submitting then return end
    submitting=true; btnSubmit.AutoButtonColor=false; btnSubmit.Active=false

    local k = keyBox.Text or ""
    if k=="" then forceErrorUI("🚫 Please enter a key","โปรดใส่รหัสก่อนนะ"); return end

    -- normalize ก่อนยิงเซิร์ฟเวอร์ (แก้เพิ่มให้)
    k = normalizeKeyLua(k)
    keyBox.Text = k

    setStatus("กำลังตรวจสอบคีย์...", nil)
    tween(btnSubmit,{BackgroundColor3=Color3.fromRGB(70,170,120)},.08)
    btnSubmit.Text="⏳ Verifying..."

    local valid,reason,expires_at = verifyWithAllowedOrServer(k)

    if not valid then
        if reason=="server_unreachable" then
            forceErrorUI("❌ Invalid Key","เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่หรือตรวจเน็ต")
        else
            forceErrorUI("❌ Invalid Key","กุญแจไม่ถูกต้อง ลองอีกครั้ง")
        end
        return
    end

    -- ผ่าน ✅
    tween(btnSubmit,{BackgroundColor3=Color3.fromRGB(120,255,170)},.10)
    btnSubmit.Text="✅ Key accepted"
    btnSubmit.TextColor3=Color3.new(0,0,0)
    setStatus("ยืนยันคีย์สำเร็จ พร้อมใช้งาน!", true)
    showToast("ยืนยันสำเร็จ", true)

    _G.UFO_HUBX_KEY_OK = true
    _G.UFO_HUBX_KEY    = k
    if _G.UFO_SaveKeyState and expires_at then
        pcall(_G.UFO_SaveKeyState, k, tonumber(expires_at) or (os.time()+DEFAULT_TTL_SECONDS), false)
    end

    task.delay(0.15, function() fadeOutAndDestroy() end)
end
btnSubmit.MouseButton1Click:Connect(doSubmit)
btnSubmit.Activated:Connect(doSubmit)

-------------------- GET KEY (คัดลอกลิงก์เว็บเท่านั้น) --------------------
local function showLinkPopup(urlText)
    local pop = make("Frame",{
        Parent=panel, BackgroundColor3=Color3.fromRGB(18,18,18), BackgroundTransparency=0.1,
        Size=UDim2.new(1,-56,0,86), Position=UDim2.new(0,28,0,324+50+12), ZIndex=80
    },{
        make("UICorner",{CornerRadius=UDim.new(0,12)}),
        make("UIStroke",{Color=ACCENT, Transparency=0.5}),
    })
    local tb = make("TextBox",{
        Parent=pop, ClearTextOnFocus=false, Text=urlText, Font=Enum.Font.Gotham,
        TextSize=14, TextColor3=FG, BackgroundColor3=SUB, BorderSizePixel=0,
        Size=UDim2.new(1,-108,0,36), Position=UDim2.new(0,12,0,12)
    },{
        make("UICorner",{CornerRadius=UDim.new(0,8)}),
        make("UIStroke",{Color=ACCENT, Transparency=0.75})
    })
    local btnCopy = make("TextButton",{
        Parent=pop, Text="Copy", Font=Enum.Font.GothamBold, TextSize=14,
        TextColor3=Color3.new(0,0,0), AutoButtonColor=false, BackgroundColor3=ACCENT, BorderSizePixel=0,
        Size=UDim2.new(0,80,0,36), Position=UDim2.new(1,-92,0,12)
    },{
        make("UICorner",{CornerRadius=UDim.new(0,8)})
    })
    btnCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, urlText)
            showToast("คัดลอกแล้ว", true)
            btnCopy.Text = "Copied!"
            task.delay(1.2,function() if btnCopy then btnCopy.Text="Copy" end end)
        else
            showToast("ก็อปจากช่องด้านซ้ายได้เลย", true)
        end
    end)
    make("TextLabel",{
        Parent=pop, BackgroundTransparency=1,
        Text="เปิดลิงก์นี้ในเว็บเพื่อทำขั้นตอนรับคีย์",
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(180,180,180),
        Size=UDim2.new(1,-24,0,20), Position=UDim2.new(0,12,0,52)
    },{})
end

local btnGetKey = make("TextButton",{
    Parent=panel, Text="🔐  Get Key", Font=Enum.Font.GothamBold, TextSize=18,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false, BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,44), Position=UDim2.new(0,28,0,324)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})

btnGetKey.MouseButton1Click:Connect(function()
    -- บังคับใช้ฐานที่กำหนดทุกครั้ง (กันจำฐานเก่า)
    _G.UFO_LAST_BASE   = FORCE_BASE
    _G.UFO_SERVER_BASE = FORCE_BASE

    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")

    -- ลิงก์หน้า UI บนเว็บ (ไม่ใช่ API) → ให้ผู้ใช้ไปทำขั้นตอนในเว็บ
    local qs_ui  = string.format("/?uid=%s&place=%s",
        HttpService:UrlEncode(uid), HttpService:UrlEncode(place)
    )
    local base   = sanitizeBase(_G.UFO_SERVER_BASE or FORCE_BASE)
    local ui_url = base .. qs_ui

    -- ❌ ไม่เรียก /getkey ที่นี่ (เพื่อให้สร้างคีย์เฉพาะบนเว็บเท่านั้น)
    if setclipboard then
        pcall(setclipboard, ui_url)
        showToast("คัดลอกลิงก์หน้าเว็บแล้ว", true)
        setStatus("เปิดลิงก์ในเว็บเพื่อรับคีย์ แล้วค่อยนำมากรอกที่นี่", true)
    else
        showLinkPopup(ui_url)
        showToast("ก็อปจากกล่องลิงก์ได้เลย", true)
    end

    -- เอฟเฟ็กต์ปุ่มเล็กน้อย แล้วคืนค่า
    btnGetKey.Text = "✅ Link copied!"
    task.delay(1.6, function()
        if btnGetKey and btnGetKey.Parent then
            btnGetKey.Text = "🔐  Get Key"
        end
    end)
end)

----------------------------------------------------------------
-- [ADD-ON v2] UFO HUB X — Server Reader, Multi-Place, Live Preview
-- ✨ เพิ่มฟีเจอร์ โดย "ไม่ลบ/ไม่แก้ของเดิม" ─ วางต่อท้ายไฟล์เดิมได้เลย
----------------------------------------------------------------

if _G.__UFOX_ADDON_V2 then return end
_G.__UFOX_ADDON_V2 = true

local function getBase()
    local b = (_G.UFO_SERVER_BASE or FORCE_BASE or "")
    b = tostring(b):gsub("%s+","")
    return (b:gsub("[/]+$",""))
end

-- ===== Multi-Place (เพิ่มได้ ไม่ทับของเดิม) =====
_G.UFOX_PLACE_ALLOW = _G.UFOX_PLACE_ALLOW or {
    -- ["Garden"] = 126884695634066,   -- ตัวอย่าง
}

local function currentPlaceId()
    if type(_G.UFO_FORCE_PLACE) == "string" or type(_G.UFO_FORCE_PLACE) == "number" then
        return tostring(_G.UFO_FORCE_PLACE)
    end
    return tostring(game.PlaceId or "")
end

-- ===== Helpers =====
local function buildQS(t)
    local parts = {}
    for k,v in pairs(t or {}) do
        table.insert(parts, string.format("%s=%s", k, HttpService:UrlEncode(tostring(v or ""))))
    end
    return (#parts>0) and ("?"..table.concat(parts,"&")) or ""
end

local function hms(sec)
    sec = math.max(0, tonumber(sec) or 0)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = math.floor(sec%60)
    local function pad(x) x=tostring(x); return (#x<2) and ("0"..x) or x end
    return string.format("%s:%s:%s", pad(h), pad(m), pad(s))
end

-- ป้องกันยิง API ถี่เกินไป
local lastCallAt = 0
local function rateOK(minGap)
    local t = os.clock()
    if (t - lastCallAt) < (minGap or 0.6) then return false end
    lastCallAt = t
    return true
end

-- ===== Normalizer (สำรอง ใช้แล้วด้านบนมีด้วย แต่ไม่ลบทิ้ง) =====
local function normalizeKeyLua2(s)
    s = tostring(s or ""):upper():gsub("%s+","")
    if s ~= "" then
        if not s:match("^UFO%-") then s = "UFO-"..(s:gsub("^%-+","")) end
        if not s:match("%-48H$") then s = s:gsub("%-48H$","").."-48H" end
    end
    return s
end

-- ===== Live Preview (ตรวจเบา ๆ ตอนพิมพ์คีย์) =====
local previewLabel = (function()
    local lab = Instance.new("TextLabel")
    lab.Name = "UFOX_Preview"
    lab.Parent = panel
    lab.BackgroundTransparency = 1
    lab.Position = UDim2.new(0, 28, 0, 214 + 40 + 6)
    lab.Size = UDim2.new(1, -56, 0, 20)
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 13
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.TextColor3 = Color3.fromRGB(190,220,210)
    lab.Text = ""
    return lab
end)()

local previewConn
local function startLivePreview()
    if previewConn then previewConn:Disconnect() end
    previewConn = keyBox:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = tostring(keyBox.Text or ""):gsub("%s+","")
        if #txt < 4 then
            previewLabel.Text = ""
            return
        end
        if not rateOK(0.7) then return end
        task.spawn(function()
            local uid   = tostring(LP and LP.UserId or "")
            local place = currentPlaceId()
            local kNorm = normalizeKeyLua2(txt)
            local url   = getBase().."/verify"..buildQS({ key=kNorm, uid=uid, place=place })
            local ok,data,_ = http_json_get(url)
            if ok and data and data.ok then
                if data.valid then
                    local left = math.max(0, (tonumber(data.expires_at) or 0) - os.time())
                    previewLabel.Text = "✅ น่าจะถูกต้อง • เหลือเวลา " .. hms(left)
                    previewLabel.TextColor3 = Color3.fromRGB(120,255,170)
                else
                    local rs = tostring(data.reason or "invalid")
                    if rs=="expired" then
                        previewLabel.Text = "⏰ คีย์หมดอายุแล้ว"
                    elseif rs=="invalid_or_mismatch" then
                        previewLabel.Text = "❌ ไม่ตรงกับ UID/Place นี้"
                    else
                        previewLabel.Text = "❌ ไม่ถูกต้อง"
                    end
                    previewLabel.TextColor3 = Color3.fromRGB(255,150,150)
                end
            else
                previewLabel.Text = "⚠ เซิร์ฟเวอร์ไม่ตอบ ลองใหม่อีกครั้ง"
                previewLabel.TextColor3 = Color3.fromRGB(255,220,140)
            end
        end)
    end)
end
startLivePreview()

-- Hook doSubmit เดิม (ป้องกันซ้อน)
do
    if type(doSubmit)=="function" and not _G.__UFOX_SUBMIT_HOOKED2 then
        _G.__UFOX_SUBMIT_HOOKED2 = true
        local orig = doSubmit
        doSubmit = function()
            if keyBox and keyBox.Text and #keyBox.Text>0 then
                keyBox.Text = normalizeKeyLua2(keyBox.Text)
            end
            return orig()
        end
    end
end

-- ===== แผงควบคุมด้านล่าง (Status / Extend / Open Web) =====
local ctrlCard = (function()
    local y = 268+50+6+26+84+8
    local f = Instance.new("Frame")
    f.Name = "UFOX_ControlBar"
    f.Parent = panel
    f.BackgroundColor3 = Color3.fromRGB(16,16,16)
    f.BackgroundTransparency = 0.1
    f.Position = UDim2.new(0,28,0,y)
    f.Size = UDim2.new(1,-56,0,90)
    f.ZIndex = 2
    make("UICorner",{CornerRadius=UDim.new(0,10), Parent=f})
    make("UIStroke",{Color=ACCENT, Transparency=0.75, Parent=f})
    return f
end)()

local row2 = make("Frame",{
    Parent=ctrlCard, BackgroundTransparency=1,
    Size=UDim2.new(1,-20,0,60), Position=UDim2.new(0,10,0,10)
},{})
make("UIListLayout",{
    Parent=row2, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8),
    HorizontalAlignment=Enum.HorizontalAlignment.Left, VerticalAlignment=Enum.VerticalAlignment.Center
},{})

local lab2 = make("TextLabel",{
    Parent=row2, BackgroundTransparency=1, Size=UDim2.new(1, -360, 1, 0),
    Font=Enum.Font.Gotham, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(210,255,235), Text = "Server: … | UID: … | Place: …"
},{})

local btnStatus = make("TextButton",{
    Parent=row2, Text="🔄 Check Status", Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=Color3.new(0,0,0), AutoButtonColor=false, BackgroundColor3=ACCENT,
    Size=UDim2.new(0,130,0,34)
},{ make("UICorner",{CornerRadius=UDim.new(0,8)}) })

local btnExtend = make("TextButton",{
    Parent=row2, Text="⏩ Copy Extend +5h", Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=Color3.new(0,0,0), AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(120,255,170),
    Size=UDim2.new(0,160,0,34)
},{ make("UICorner",{CornerRadius=UDim.new(0,8)}) })

local btnOpenWeb = make("TextButton",{
    Parent=row2, Text="🌐 Open Web UI", Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=Color3.new(0,0,0), AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(90,200,255),
    Size=UDim2.new(0,130,0,34)
},{ make("UICorner",{CornerRadius=UDim.new(0,8)}) })

local function refreshHeaderLine()
    local uid   = tostring(LP and LP.UserId or "")
    local place = currentPlaceId()
    lab2.Text = string.format("Server: %s | UID: %s | Place: %s", getBase(), uid, place)
end
refreshHeaderLine()

local function fetchStatus()
    local uid   = tostring(LP and LP.UserId or "")
    local place = currentPlaceId()
    local url   = getBase().."/status"..buildQS({uid=uid, place=place})
    return http_json_get(url)
end

btnStatus.MouseButton1Click:Connect(function()
    if not rateOK(0.6) then return end
    btnStatus.Text = "⏳ Checking..."
    local ok,data,_ = fetchStatus()
    if ok and data and data.ok then
        local left = tonumber(data.remaining or 0) or 0
        setStatus(("เหลือเวลา: %s"):format(hms(left)), true)
        showToast("✔ อัปเดตสถานะแล้ว", true)
    else
        setStatus("เชื่อมต่อสถานะไม่ได้", false)
        showToast("เชื่อมต่อสถานะไม่ได้", false)
    end
    task.delay(0.8, function()
        if btnStatus and btnStatus.Parent then btnStatus.Text = "🔄 Check Status" end
    end)
end)

btnExtend.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local place = currentPlaceId()
    local url   = string.format("%s/extend?uid=%s&place=%s",
        getBase(),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    if setclipboard then
        pcall(setclipboard, url)
        showToast("คัดลอกลิงก์ Extend +5h แล้ว", true)
        setStatus("เปิดลิงก์ในเว็บเพื่อยืดเวลาอีก 5 ชั่วโมง", true)
    else
        showLinkPopup(url)
        showToast("ก็อปจากกล่องลิงก์ได้เลย", true)
    end
end)

btnOpenWeb.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local place = currentPlaceId()
    local uiURL = string.format("%s/?uid=%s&place=%s",
        getBase(),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    if setclipboard then
        pcall(setclipboard, uiURL)
        showToast("คัดลอกลิงก์หน้าเว็บแล้ว", true)
        setStatus("เปิดลิงก์ในเว็บเพื่อทำขั้นตอนรับคีย์", true)
    else
        showLinkPopup(uiURL)
        showToast("ก็อปจากกล่องลิงก์ได้เลย", true)
    end
end)

-- โหลดสถานะรอบแรกแบบเงียบ ๆ
task.delay(0.3, function()
    local ok,data,_ = fetchStatus()
    if ok and data and data.ok then
        setStatus(("เหลือเวลา: %s"):format(hms(tonumber(data.remaining or 0) or 0)), true)
    end
end)

-- =========== (ออปชัน) Footer รายชื่อ Place ที่รองรับ ===========
local function showPlacesFooter()
    if not (_G.UFOX_PLACE_ALLOW and next(_G.UFOX_PLACE_ALLOW)) then return end
    local ft = Instance.new("TextLabel")
    ft.Name = "UFOX_Places_Footer"
    ft.Parent = panel
    ft.BackgroundTransparency = 1
    ft.AnchorPoint = Vector2.new(1,1)
    ft.Position = UDim2.new(1,-16,1,-14)
    ft.Size = UDim2.new(0, math.min(PANEL_W-80, 560), 0, 18)
    ft.Font = Enum.Font.Gotham
    ft.TextSize = 12
    ft.TextXAlignment = Enum.TextXAlignment.Right
    ft.TextColor3 = Color3.fromRGB(180,220,210)
    local parts = {}
    for name,pid in pairs(_G.UFOX_PLACE_ALLOW) do
        table.insert(parts, string.format("%s:%s", tostring(name), tostring(pid)))
    end
    table.sort(parts)
    ft.Text = "Places: "..table.concat(parts, "  |  ")
end
showPlacesFooter()

-- footer เสร็จสิ้น
----------------------------------------------------------------
-- UFO HUB X Add-on v2 จบ
----------------------------------------------------------------
