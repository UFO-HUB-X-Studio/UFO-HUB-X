--========================================================
-- UFO HUB X — KEY UI (v18+, full drop-in, enhanced)
-- - API JSON: /verify?key=&uid=&place=  และ  /getkey
-- - JSON parse ด้วย HttpService (failover หลายเซิร์ฟเวอร์ + retry)
-- - จำอายุคีย์ผ่าน _G.UFO_SaveKeyState (48 ชม. หรือ expires_at จาก server)
-- - ปุ่ม Get Key เดิม (คัดลอกลิงก์ API) + ปุ่ม Open UI จริง + ปุ่ม Copy API แยก
-- - Watchdog บังคับ UI ติดบนสุด + สถานะ Server (/status)
-- - Success: fade-out แล้ว Destroy (หรือซ่อน ถ้าตั้ง _G.UFOX_KEEP_UI=true)
--========================================================

-------------------- Services --------------------
local TS         = game:GetService("TweenService")
local CG         = game:GetService("CoreGui")
local HttpService= game:GetService("HttpService")
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer
local GuiService = game:GetService("GuiService")

-------------------- THEME / CONFIG --------------------
local LOGO_ID   = 112676905543996
local ACCENT    = Color3.fromRGB(0,255,140)
local BG_DARK   = Color3.fromRGB(10,10,10)
local FG        = Color3.fromRGB(235,235,235)
local SUB       = Color3.fromRGB(22,22,22)
local RED       = Color3.fromRGB(210,60,60)
local GREEN     = Color3.fromRGB(60,200,120)

local DISCORD_URL = "https://discord.gg/your-server"

-- ตัวหลัก (เอาโดเมน server จริงของคุณวางด้านบนสุด)
local SERVER_BASES = {
    "https://ufo-hub-x-key-umoq.onrender.com",     -- หลัก
    -- "https://ufo-hub-x-server-key2.onrender.com", -- สำรอง (เพิ่มได้)
}

-- หน้า UI จริง (index.html) – จะเปิดพร้อม uid/place
local UI_PAGE = (SERVER_BASES[1] or "") .. "/"

-- อายุคีย์เริ่มต้น (กรณี allow-list ภายในไฟล์นี้)
local DEFAULT_TTL_SECONDS = 48 * 3600 -- 48 ชั่วโมง

-- Debug / Behavior flags (เปลี่ยนได้ตอนรัน)
_G.UFOX_DEBUG         = (_G.UFOX_DEBUG ~= nil) and _G.UFOX_DEBUG or true
_G.UFOX_FORCE_TOPMOST = (_G.UFOX_FORCE_TOPMOST ~= nil) and _G.UFOX_FORCE_TOPMOST or true
_G.UFOX_KEEP_UI       = (_G.UFOX_KEEP_UI ~= nil) and _G.UFOX_KEEP_UI or false

local function log(...) if _G.UFOX_DEBUG then print("[UFO-HUB-X]", ...) end end

----------------------------------------------------------------
-- Allow-list คีย์พิเศษ (ผ่านแน่)
----------------------------------------------------------------
local ALLOW_KEYS = {
    ["JJJMAX"]                 = { reusable = true, ttl = DEFAULT_TTL_SECONDS },
    ["GMPANUPHONGARTPHAIRIN"]  = { reusable = true, ttl = DEFAULT_TTL_SECONDS },
}

----------------------------------------------------------------
-- Helpers (HTTP/JSON)
----------------------------------------------------------------
local function http_get(url)
    if http and http.request then
        local ok, res = pcall(http.request, {Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true, (res.Body or res.body) end
        return false, "executor_http_request_failed"
    end
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url=url, Method="GET"})
        if ok and res and (res.Body or res.body) then return true, (res.Body or res.body) end
        return false, "syn_request_failed"
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body then return true, body end
    return false, "roblox_httpget_failed"
end

local function http_json_get(url)
    local ok, body = http_get(url)
    if not ok or not body then return false, nil, "http_error" end
    local okj, data = pcall(function() return HttpService:JSONDecode(tostring(body)) end)
    if not okj then return false, nil, "json_error" end
    return true, data, nil
end

-- ลองทีละ SERVER_BASE + retry/backoff เผื่อ Render ตื่นช้า
local function json_get_with_failover(path_qs)
    local last_err = "no_servers"
    for _, base in ipairs(SERVER_BASES) do
        local url = (base..path_qs)
        -- 3 รอบต่อเซิร์ฟเวอร์: 0s / 0.5s / 1.0s
        for i=0,2 do
            if i>0 then task.wait(0.5*i) end
            local ok, data, err = http_json_get(url)
            if ok and data then return true, data end
            last_err = err or "http_error"
        end
    end
    return false, nil, last_err
end

----------------------------------------------------------------
-- Normalize & Allow check
----------------------------------------------------------------
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

----------------------------------------------------------------
-- ตรวจคีย์กับ Server (JSON)
-- server ตอบ: { ok:true, valid:true/false, expires_at:<unix>, reason:"..." }
----------------------------------------------------------------
local function verifyWithServer(k)
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local qs = string.format("/verify?key=%s&uid=%s&place=%s",
        HttpService:UrlEncode(k),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    local ok, data = json_get_with_failover(qs)
    if not ok or not data then
        return false, "server_unreachable", nil
    end
    if data.ok and data.valid then
        local exp = tonumber(data.expires_at) or (os.time() + DEFAULT_TTL_SECONDS)
        return true, nil, exp
    else
        return false, tostring(data.reason or "invalid"), nil
    end
end

----------------------------------------------------------------
-- UI Helpers
----------------------------------------------------------------
local function safeParent(gui)
    local ok=false
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end
    if gethui then ok = pcall(function() gui.Parent = gethui() end) end
    if not ok then gui.Parent = CG end
end

local function make(class, props, kids)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent=o end
    return o
end

local function tween(o, goal, t)
    TS:Create(o, TweenInfo.new(t or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function setClipboard(s) if setclipboard then pcall(setclipboard, s) end end

-- เปิดเบราว์เซอร์อย่างปลอดภัย / fallback เป็นการคัดลอก
local function openExternal(url)
    local ok = false
    if GuiService and GuiService.OpenBrowserWindow then
        ok = pcall(function() GuiService:OpenBrowserWindow(url) end) or false
    end
    if (not ok) and syn and syn.open_url then
        ok = pcall(function() syn.open_url(url) end) or false
    end
    if not ok then setClipboard(url) end
    return ok
end

-- ลิงก์หน้า UI จริงพร้อม uid/place
local function makeUiLink()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    return string.format("%sindex.html?uid=%s&place=%s",
        (SERVER_BASES[1] or ""),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
end

-------------------- ROOT --------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UFOHubX_KeyUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParent(gui)

-------------------- PANEL --------------------
local PANEL_W, PANEL_H = 740, 430
local panel = make("Frame", {
    Parent=gui, Active=true, Draggable=true,
    Size=UDim2.fromOffset(PANEL_W, PANEL_H),
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    BackgroundColor3=BG_DARK, BorderSizePixel=0, ZIndex=1
},{
    make("UICorner",{CornerRadius=UDim.new(0,22)}),
    make("UIStroke",{Color=ACCENT, Thickness=2, Transparency=0.1})
})

-- ปุ่มปิด (แค่ปิด UI)
local btnClose = make("TextButton", {
    Parent=panel, Text="X", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.new(1,1,1),
    AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(210,35,50),
    Size=UDim2.new(0,38,0,38), Position=UDim2.new(1,-50,0,14), ZIndex=50
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)})
})
btnClose.MouseButton1Click:Connect(function() gui:Destroy() end)

-------------------- HEADER --------------------
local head = make("Frame", {
    Parent=panel, BackgroundTransparency=0.15, BackgroundColor3=Color3.fromRGB(14,14,14),
    Size=UDim2.new(1,-28,0,68), Position=UDim2.new(0,14,0,14), ZIndex=5
},{
    make("UICorner",{CornerRadius=UDim.new(0,16)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.85})
})
make("ImageLabel", {
    Parent=head, BackgroundTransparency=1, Image="rbxassetid://"..LOGO_ID,
    Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,16,0,17), ZIndex=6
},{})
make("TextLabel", {
    Parent=head, BackgroundTransparency=1, Position=UDim2.new(0,60,0,18),
    Size=UDim2.new(0,200,0,32), Font=Enum.Font.GothamBold, TextSize=20,
    Text="KEY SYSTEM", TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6
}, {})

-- [ADD] server status pill (มุมขวาเฮดเดอร์)
local statusPill = make("TextLabel", {
    Parent=head, BackgroundTransparency=0.2, BackgroundColor3=Color3.fromRGB(26,26,26),
    Size=UDim2.new(0,140,0,26), Position=UDim2.new(1,-150,0,21),
    Font=Enum.Font.Gotham, TextSize=14, Text="• checking…", TextColor3=Color3.fromRGB(220,220,220),
    ZIndex=6
},{
    make("UICorner",{CornerRadius=UDim.new(0,8)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.7})
})

-------------------- TITLE --------------------
local titleGroup = make("Frame", {
    Parent=panel, BackgroundTransparency=1,
    Position=UDim2.new(0,28,0,102), Size=UDim2.new(1,-56,0,76)
}, {})
make("UIListLayout", {
    Parent = titleGroup,
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0,6)
}, {})
make("TextLabel", {
    Parent = titleGroup, LayoutOrder = 1, BackgroundTransparency = 1, Size=UDim2.new(1,0,0,32),
    Font=Enum.Font.GothamBlack, TextSize=30, Text="Welcome to the,", TextColor3=FG,
    TextXAlignment=Enum.TextXAlignment.Left
}, {})
local titleLine2 = make("Frame", {
    Parent = titleGroup, LayoutOrder = 2, BackgroundTransparency = 1, Size=UDim2.new(1,0,0,36)
}, {})
make("UIListLayout", {
    Parent=titleLine2, FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left, VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)
},{})
make("TextLabel", { Parent=titleLine2, LayoutOrder=1, BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack, TextSize=32, Text="UFO", TextColor3=ACCENT, AutomaticSize=Enum.AutomaticSize.X }, {})
make("TextLabel", { Parent=titleLine2, LayoutOrder=2, BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack, TextSize=32, Text="HUB X", TextColor3=Color3.new(1,1,1), AutomaticSize=Enum.AutomaticSize.X }, {})

-------------------- KEY INPUT --------------------
make("TextLabel", {
    Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,188),
    Size=UDim2.new(0,60,0,22), Font=Enum.Font.Gotham, TextSize=16,
    Text="Key", TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
}, {})
local keyStroke
local keyBox = make("TextBox", {
    Parent=panel, ClearTextOnFocus=false, PlaceholderText="insert your key here",
    Font=Enum.Font.Gotham, TextSize=16, Text="", TextColor3=FG,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,40), Position=UDim2.new(0,28,0,214)
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)}),
    (function() keyStroke = make("UIStroke",{Color=ACCENT, Transparency=0.75}); return keyStroke end)()
})

-------------------- SUBMIT BUTTON --------------------
local btnSubmit = make("TextButton", {
    Parent=panel, Text="🔒  Submit Key", Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=RED, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,50), Position=UDim2.new(0,28,0,268)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)})
})

-- Toast
local toast = make("TextLabel", {
    Parent = panel, BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(30,30,30),
    Size = UDim2.fromOffset(0,32), Position = UDim2.new(0.5,0,0,16),
    AnchorPoint = Vector2.new(0.5,0), Visible = false, Font = Enum.Font.GothamBold,
    TextSize = 14, Text = "", TextColor3 = Color3.new(1,1,1), ZIndex = 100
},{
    make("UIPadding",{PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14)}),
    make("UICorner",{CornerRadius=UDim.new(0,10)})
})
local function showToast(msg, ok)
    toast.Text = msg
    toast.BackgroundColor3 = ok and Color3.fromRGB(20,120,60) or Color3.fromRGB(150,35,35)
    toast.Size = UDim2.fromOffset(math.max(160, (#msg*8)+28), 32)
    toast.Visible = true
    toast.BackgroundTransparency = 0.15
    tween(toast, {BackgroundTransparency = 0.05}, .08)
    task.delay(1.1, function()
        tween(toast, {BackgroundTransparency = 1}, .15)
        task.delay(.15, function() toast.Visible = false end)
    end)
end

-- Status text
local statusLabel = make("TextLabel", {
    Parent=panel, BackgroundTransparency=1, Position=UDim2.new(0,28,0,268+50+6),
    Size=UDim2.new(1,-56,0,24), Font=Enum.Font.Gotham, TextSize=14, Text="",
    TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Left
}, {})
local function setStatus(txt, ok)
    statusLabel.Text = txt or ""
    if ok == nil then
        statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
    elseif ok then
        statusLabel.TextColor3 = Color3.fromRGB(120,255,170)
    else
        statusLabel.TextColor3 = Color3.fromRGB(255,120,120)
    end
end

-- Error effect
local function flashInputError()
    if keyStroke then
        local old = keyStroke.Color
        tween(keyStroke, {Color = Color3.fromRGB(255,90,90), Transparency = 0}, .05)
        task.delay(.22, function()
            tween(keyStroke, {Color = old, Transparency = 0.75}, .12)
        end)
    end
    local p0 = btnSubmit.Position
    local dx = 5
    TS:Create(btnSubmit, TweenInfo.new(0.05), {Position = p0 + UDim2.fromOffset(-dx,0)}):Play()
    task.delay(0.05, function()
        TS:Create(btnSubmit, TweenInfo.new(0.05), {Position = p0 + UDim2.fromOffset(dx,0)}):Play()
        task.delay(0.05, function()
            TS:Create(btnSubmit, TweenInfo.new(0.05), {Position = p0}):Play()
        end)
    end)
end

-- Fade-out UI
local function fadeOutAndDestroy()
    for _, d in ipairs(panel:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
                if d:IsA("TextBox") or d:IsA("TextButton") then
                    TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
            elseif d:IsA("Frame") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            elseif d:IsA("UIStroke") then
                TS:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
            end
        end)
    end
    TS:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    task.delay(0.22, function()
        if _G.UFOX_KEEP_UI then
            gui.Enabled = false
        else
            if gui and gui.Parent then gui:Destroy() end
        end
    end)
end

-- Submit states
local submitting = false
local function refreshSubmit()
    if submitting then return end
    local hasText = keyBox.Text and (#keyBox.Text > 0)
    if hasText then
        tween(btnSubmit, {BackgroundColor3 = GREEN}, .08)
        btnSubmit.Text = "🔓  Submit Key"
        btnSubmit.TextColor3 = Color3.new(0,0,0)
    else
        tween(btnSubmit, {BackgroundColor3 = RED}, .08)
        btnSubmit.Text = "🔒  Submit Key"
        btnSubmit.TextColor3 = Color3.new(1,1,1)
    end
end
keyBox:GetPropertyChangedSignal("Text"):Connect(function()
    setStatus("", nil); refreshSubmit()
end)
refreshSubmit()
keyBox.FocusLost:Connect(function(enter) if enter then btnSubmit:Activate() end end)

-- รวม error
local function forceErrorUI(mainText, toastText)
    tween(btnSubmit, {BackgroundColor3 = Color3.fromRGB(255,80,80)}, .08)
    btnSubmit.Text = mainText or "❌ Invalid Key"
    btnSubmit.TextColor3 = Color3.new(1,1,1)
    setStatus(toastText or "กุญแจไม่ถูกต้อง ลองอีกครั้ง", false)
    showToast(toastText or "รหัสไม่ถูกต้อง", false)
    flashInputError()
    keyBox.Text = ""
    task.delay(0.02, function() keyBox:CaptureFocus() end)
    task.delay(1.2, function()
        submitting=false; btnSubmit.Active=true; refreshSubmit()
    end)
end

----------------------------------------------------------------
-- Submit flow
----------------------------------------------------------------
local function doSubmit()
    if submitting then return end
    submitting = true; btnSubmit.AutoButtonColor = false; btnSubmit.Active = false

    local k = keyBox.Text or ""
    if k == "" then
        forceErrorUI("🚫 Please enter a key", "โปรดใส่รหัสก่อนนะ"); return
    end

    setStatus("กำลังตรวจสอบคีย์...", nil)
    tween(btnSubmit, {BackgroundColor3 = Color3.fromRGB(70,170,120)}, .08)
    btnSubmit.Text = "⏳ Verifying..."

    local valid, reason, expires_at = false, nil, nil
    local allowed, nk, meta = isAllowedKey(k)
    if allowed then
        valid = true
        expires_at = os.time() + (tonumber(meta.ttl) or DEFAULT_TTL_SECONDS)
        log("allowed key:", nk, "exp:", expires_at)
    else
        valid, reason, expires_at = verifyWithServer(k)
        if valid then
            log("server verified key:", k, "exp:", expires_at)
        else
            log("key invalid:", k, "reason:", tostring(reason))
        end
    end

    if not valid then
        if reason == "server_unreachable" then
            forceErrorUI("❌ Invalid Key", "เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่หรือตรวจเน็ต")
        else
            forceErrorUI("❌ Invalid Key", "กุญแจไม่ถูกต้อง ลองอีกครั้ง")
        end
        return
    end

    -- ผ่าน ✅
    tween(btnSubmit, {BackgroundColor3 = Color3.fromRGB(120,255,170)}, .10)
    btnSubmit.Text = "✅ Key accepted"
    btnSubmit.TextColor3 = Color3.new(0,0,0)
    setStatus("ยืนยันคีย์สำเร็จ พร้อมใช้งาน!", true)
    showToast("ยืนยันสำเร็จ", true)

    _G.UFO_HUBX_KEY_OK = true
    _G.UFO_HUBX_KEY    = k

    -- ส่งให้ Boot Loader บันทึก state (เพื่อข้าม Key UI จนหมดอายุ)
    if _G.UFO_SaveKeyState and expires_at then
        pcall(_G.UFO_SaveKeyState, k, tonumber(expires_at) or (os.time()+DEFAULT_TTL_SECONDS), false)
    end

    task.delay(0.15, function()
        fadeOutAndDestroy()
    end)
end
btnSubmit.MouseButton1Click:Connect(doSubmit)
btnSubmit.Activated:Connect(doSubmit)

-------------------- GET KEY (ลิงก์พร้อม uid/place) --------------------
local btnGetKey = make("TextButton", {
    Parent=panel, Text="🔐  Get Key", Font=Enum.Font.GothamBold, TextSize=18,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,44), Position=UDim2.new(0,28,0,324)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})

-- Handler เดิม: คัดลอกลิงก์ API (คงไว้)
btnGetKey.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local base  = SERVER_BASES[1] or ""
    local link  = string.format("%s/getkey?uid=%s&place=%s",
        base,
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    setClipboard(link)
    btnGetKey.Text = "✅ Link copied!"
    task.delay(1.5, function() btnGetKey.Text = "🔐  Get Key" end)
end)

-- [ADD] ปุ่มเสริม: เปิดหน้า UI จริง + ปุ่ม Copy API แยก
    local extraRow = make("Frame", {
        Parent = panel, BackgroundTransparency = 1, ZIndex = 5,
        Size = UDim2.new(1, -56, 0, 40), Position = UDim2.new(0, 28, 0, 324+44+8)
    },{})

    make("UIListLayout", {
        Parent = extraRow,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10)
    },{})

    -- ปุ่มเปิดหน้า UI จริง (จะต่อพารามิเตอร์ uid/place ให้เอง)
    local btnOpenUi = make("TextButton", {
        Parent = extraRow, ZIndex = 6,
        Text = "🌐  Open Key UI", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Color3.new(1,1,1), AutoButtonColor = false,
        BackgroundColor3 = SUB, BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 0, 36)
    },{
        make("UICorner",{CornerRadius = UDim.new(0, 12)}),
        make("UIStroke",{Color = ACCENT, Transparency = 0.55})
    })

    btnOpenUi.MouseButton1Click:Connect(function()
        local url = makeUiLink()
        local opened = openExternal(url) -- พยายามเปิดเบราว์เซอร์; ถ้าเปิดไม่ได้จะคัดลอกให้
        if opened then
            btnOpenUi.Text = "✅ UI opened!"
        else
            btnOpenUi.Text = "📋 Copied UI link!"
        end
        task.delay(1.6, function() btnOpenUi.Text = "🌐  Open Key UI" end)
    end)

    -- ปุ่มคัดลอก API link แยกต่างหาก
    local btnCopyApi = make("TextButton", {
        Parent = extraRow, ZIndex = 6,
        Text = "📋  Copy API Link", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Color3.new(1,1,1), AutoButtonColor = false,
        BackgroundColor3 = SUB, BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 0, 36)
    },{
        make("UICorner",{CornerRadius = UDim.new(0, 12)}),
        make("UIStroke",{Color = ACCENT, Transparency = 0.55})
    })

    btnCopyApi.MouseButton1Click:Connect(function()
        local uid   = tostring(LP and LP.UserId or "")
        local place = tostring(game.PlaceId or "")
        local base  = SERVER_BASES[1] or ""
        local link  = string.format("%s/getkey?uid=%s&place=%s",
            base,
            HttpService:UrlEncode(uid),
            HttpService:UrlEncode(place)
        )
        setClipboard(link)
        btnCopyApi.Text = "✅ Copied!"
        task.delay(1.4, function() btnCopyApi.Text = "📋  Copy API Link" end)
    end)

    -------------------- SUPPORT --------------------
    local supportRow = make("Frame", {
        Parent = panel, AnchorPoint = Vector2.new(0.5,1),
        Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(1, -56, 0, 24),
        BackgroundTransparency = 1
    },{})

    make("UIListLayout", {
        Parent = supportRow,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8)
    },{})

    make("TextLabel", {
        Parent = supportRow, LayoutOrder = 1, BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 16, Text = "Need support?",
        TextColor3 = Color3.fromRGB(200,200,200), AutomaticSize = Enum.AutomaticSize.X
    },{})

    local btnDiscord = make("TextButton", {
        Parent = supportRow, LayoutOrder = 2, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 16, Text = "Join the Discord",
        TextColor3 = ACCENT, AutomaticSize = Enum.AutomaticSize.X
    },{})
    btnDiscord.MouseButton1Click:Connect(function()
        setClipboard(DISCORD_URL)
        btnDiscord.Text = "✅ Link copied!"
        task.delay(1.5, function() btnDiscord.Text = "Join the Discord" end)
    end)

    -------------------- WATCHDOG: ติดบนสุด / อยู่ใน CoreGui --------------------
    task.spawn(function()
        while gui and gui.Parent do
            pcall(function()
                if _G.UFOX_FORCE_TOPMOST then
                    gui.DisplayOrder = 999999
                    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                end
                if gui.Parent ~= CG then
                    safeParent(gui)
                end
            end)
            task.wait(2)
        end
    end)

    -------------------- STATUS PING (/status) --------------------
    local function setPill(text, good)
        statusPill.Text = text
        if good == nil then
            statusPill.TextColor3 = Color3.fromRGB(220,220,220)
            statusPill.BackgroundColor3 = Color3.fromRGB(26,26,26)
        elseif good then
            statusPill.TextColor3 = Color3.fromRGB(170,255,190)
            statusPill.BackgroundColor3 = Color3.fromRGB(22,40,26)
        else
            statusPill.TextColor3 = Color3.fromRGB(255,180,180)
            statusPill.BackgroundColor3 = Color3.fromRGB(45,22,22)
        end
    end

    local function pingStatus()
        local ok, data = json_get_with_failover("/status")
        if ok and data and data.ok then
            setPill("• online", true)
        else
            setPill("• offline", false)
        end
    end

    -- เรียกทันทีและวนทุก 15 วินาที
    task.spawn(function()
        pingStatus()
        while gui and gui.Parent do
            task.wait(15)
            pingStatus()
        end
    end)

    -------------------- Open Animation --------------------
    panel.Position = UDim2.fromScale(0.5,0.5) + UDim2.fromOffset(0,14)
    tween(panel, {Position = UDim2.fromScale(0.5,0.5)}, .18)
