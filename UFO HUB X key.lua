--========================================================
-- UFO HUB X — KEY UI (v17) : Success = auto fade-out & destroy (keep all previous features)
--========================================================

-------------------- Services --------------------
local TS   = game:GetService("TweenService")
local CG   = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService") -- ใช้เชื่อม Server

-------------------- CONFIG --------------------
local LOGO_ID   = 112676905543996
local ACCENT    = Color3.fromRGB(0,255,140)
local BG_DARK   = Color3.fromRGB(10,10,10)
local FG        = Color3.fromRGB(235,235,235)
local SUB       = Color3.fromRGB(22,22,22)

local DISCORD_URL = "https://discord.gg/your-server"
local GETKEY_URL  = "https://ufo-hub-x-key-umoq.onrender.com"  -- server จริง

-- เรียกใช้ตอนกด Submit (ค่อยผูกระบบจริงทีหลัง)
local function OnSubmitKey(key)
    print("[KEY SUBMIT] =>", key)
end

----------------------------------------------------------------
-- Allow-list คีย์พิเศษ (ผ่านแน่)
----------------------------------------------------------------
local ALLOW_KEYS = {
    ["JJJMAX"]                 = { permanent = true, reusable = true }, -- คีย์ทดลอง
    ["GMPANUPHONGARTPHAIRIN"]  = { permanent = true, reusable = true }, -- คีย์ถาวร
}

----------------------------------------------------------------
-- Normalize แข็งแรงขึ้น
----------------------------------------------------------------
local function normKey(s)
    s = tostring(s or "")
    s = s:gsub("%c",""):gsub("%s+",""):gsub("[^%w]","")
    s = string.upper(s)
    return s
end

local function isAllowedKey(k)
    local nk = normKey(k)
    if ALLOW_KEYS[nk] then
        return true, nk
    end
    return false, nk
end

----------------------------------------------------------------
-- ตรวจสอบคีย์กับ server (ทนทานขึ้น + ส่งสาเหตุกลับ)
----------------------------------------------------------------
local function http_get(url)
    if http and http.request then
        local ok, res = pcall(http.request, {Url=url, Method="GET"})
        if ok and res and res.Body then return true, res.Body end
        return false, "executor_http_request_failed"
    end
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url=url, Method="GET"})
        if ok and res and res.Body then return true, res.Body end
        return false, "syn_request_failed"
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body then return true, body end
    return false, "roblox_httpget_failed"
end

local function verifyWithServer(k)
    local url = GETKEY_URL.."/verify?key="..HttpService:UrlEncode(k)
    local ok, res = http_get(url)
    if ok and res then
        local low = tostring(res):lower()
        if low:find("valid") or low:find('"valid"%s*:%s*true') or low:find("ok") or low:find("true") then
            return true, nil
        else
            return false, "server_said_invalid"
        end
    end
    return false, "server_unreachable"
end

-------------------- Helpers (UI) --------------------
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

-- ปุ่มปิด (คงไว้)
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

-- Line 1
make("TextLabel", {
    Parent = titleGroup, LayoutOrder = 1,
    BackgroundTransparency = 1, Size=UDim2.new(1,0,0,32),
    Font=Enum.Font.GothamBlack, TextSize=30,
    Text="Welcome to the,", TextColor3=FG,
    TextXAlignment=Enum.TextXAlignment.Left
}, {})

-- Line 2 : UFO HUB X
local titleLine2 = make("Frame", {
    Parent = titleGroup, LayoutOrder = 2,
    BackgroundTransparency = 1, Size=UDim2.new(1,0,0,36)
}, {})
make("UIListLayout", {
    Parent=titleLine2,
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,6)
},{})
make("TextLabel", {
    Parent=titleLine2, LayoutOrder=1,
    BackgroundTransparency=1, Font=Enum.Font.GothamBlack, TextSize=32,
    Text="UFO", TextColor3=ACCENT, AutomaticSize=Enum.AutomaticSize.X
}, {})
make("TextLabel", {
    Parent=titleLine2, LayoutOrder=2,
    BackgroundTransparency=1, Font=Enum.Font.GothamBlack, TextSize=32,
    Text="HUB X", TextColor3=Color3.new(1,1,1), AutomaticSize=Enum.AutomaticSize.X
}, {})

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
    (function()
        keyStroke = make("UIStroke",{Color=ACCENT, Transparency=0.75})
        return keyStroke
    end)()
})

-------------------- SUBMIT BUTTON --------------------
local RED   = Color3.fromRGB(210,60,60)
local GREEN = Color3.fromRGB(60,200,120)

local btnSubmit = make("TextButton", {
    Parent=panel,
    Text="🔒  Submit Key",
    Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=RED, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,50), Position=UDim2.new(0,28,0,268)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)})
})

-- Toast แจ้งผล
local toast = make("TextLabel", {
    Parent = panel, BackgroundTransparency = 0.15,
    BackgroundColor3 = Color3.fromRGB(30,30,30),
    Size = UDim2.fromOffset(0,32), Position = UDim2.new(0.5,0,0,16),
    AnchorPoint = Vector2.new(0.5,0), Visible = false,
    Font = Enum.Font.GothamBold, TextSize = 14, Text = "",
    TextColor3 = Color3.new(1,1,1), ZIndex = 100
},{
    make("UIPadding",{PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14)}),
    make("UICorner",{CornerRadius=UDim.new(0,10)})
})
local function showToast(msg, ok)
    toast.Text = msg
    toast.TextColor3 = Color3.new(1,1,1)
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

-- สถานะใต้ปุ่ม
local statusLabel = make("TextLabel", {
    Parent=panel, BackgroundTransparency=1,
    Position=UDim2.new(0,28,0,268+50+6),
    Size=UDim2.new(1,-56,0,24),
    Font=Enum.Font.Gotham, TextSize=14, Text="",
    TextColor3=Color3.fromRGB(200,200,200),
    TextXAlignment=Enum.TextXAlignment.Left
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

-- เอฟเฟกต์แจ้งเตือนตอนผิด: กระพริบขอบแดง + เขย่าเล็กน้อย
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

-- [ADD] ฟังก์ชันเฟดทั้ง UI แล้วปิดทิ้ง
local function fadeOutAndDestroy()
    -- ทำให้ทุก element ค่อย ๆ โปร่งใส
    for _, d in ipairs(panel:GetDescendants()) do
        local ok,_ = pcall(function()
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
        if gui and gui.Parent then
            gui:Destroy()
        end
    end)
end

local submitting = false  -- debounce

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
    setStatus("", nil)
    refreshSubmit()
end)
refreshSubmit()

-- รองรับกด Enter เพื่อ Submit
keyBox.FocusLost:Connect(function(enter)
    if enter then
        btnSubmit:Activate()
    end
end)

----------------------------------------------------------------
-- ฟังก์ชันสถานะผิดแบบรวม
----------------------------------------------------------------
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
        submitting = false
        btnSubmit.Active = true
        refreshSubmit()
    end)
end

local function doSubmit()
    if submitting then return end
    submitting = true
    btnSubmit.AutoButtonColor = false
    btnSubmit.Active = false

    local k = keyBox.Text or ""
    if k == "" then
        forceErrorUI("🚫 Please enter a key", "โปรดใส่รหัสก่อนนะ")
        return
    end

    setStatus("กำลังตรวจสอบคีย์...", nil)
    tween(btnSubmit, {BackgroundColor3 = Color3.fromRGB(70,170,120)}, .08)
    btnSubmit.Text = "⏳ Verifying..."

    local valid, reason = false, nil
    local allowed, nk = isAllowedKey(k)
    if allowed then
        valid = true
        print("[UFO-HUB-X] allowed key matched:", nk)
    else
        valid, reason = verifyWithServer(k)
        if valid then
            print("[UFO-HUB-X] server verified key:", k)
        else
            print("[UFO-HUB-X] key invalid:", k, "reason:", tostring(reason))
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
    _G.UFO_HUBX_KEY     = k

    OnSubmitKey(k)

    -- [NEW] ซ่อน UI ทั้งหมดหลังสำเร็จ
    task.delay(0.15, function()
        fadeOutAndDestroy()
    end)
end

-- คงของเดิมไว้ + เพิ่ม Activated ให้เรียก flow เดียวกัน
btnSubmit.MouseButton1Click:Connect(doSubmit)
btnSubmit.Activated:Connect(doSubmit)

-------------------- GET KEY --------------------
local btnGetKey = make("TextButton", {
    Parent=panel, Text="🔐  Get Key", Font=Enum.Font.GothamBold, TextSize=18,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-56,0,44), Position=UDim2.new(0,28,0,324)
},{
    make("UICorner",{CornerRadius=UDim.new(0,14)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})
btnGetKey.MouseButton1Click:Connect(function()
    setClipboard(GETKEY_URL)
    btnGetKey.Text = "✅ Link copied!"
    task.delay(1.5,function() btnGetKey.Text="🔐  Get Key" end)
end)

-------------------- SUPPORT --------------------
local supportRow = make("Frame", {
    Parent=panel, AnchorPoint = Vector2.new(0.5,1),
    Position = UDim2.new(0.5,0,1,-18), Size = UDim2.new(1,-56,0,24),
    BackgroundTransparency = 1
}, {})

make("UIListLayout", {
    Parent = supportRow,
    FillDirection = Enum.FillDirection.HORIZONTAL,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment   = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0,6)
}, {})

make("TextLabel", {
    Parent=supportRow, LayoutOrder=1, BackgroundTransparency=1,
    Font=Enum.Font.Gotham, TextSize=16, Text="Need support?",
    TextColor3=Color3.fromRGB(200,200,200), AutomaticSize=Enum.AutomaticSize.X
}, {})

local btnDiscord = make("TextButton", {
    Parent=supportRow, LayoutOrder=2, BackgroundTransparency=1,
    Font=Enum.Font.GothamBold, TextSize=16, Text="Join the Discord",
    TextColor3=ACCENT, AutomaticSize=Enum.AutomaticSize.X
},{})
btnDiscord.MouseButton1Click:Connect(function()
    setClipboard(DISCORD_URL)
    btnDiscord.Text = "✅ Link copied!"
    task.delay(1.5,function() btnDiscord.Text="Join the Discord" end)
end)

-------------------- Open Animation --------------------
panel.Position = UDim2.fromScale(0.5,0.5) + UDim2.fromOffset(0,14)
tween(panel, {Position = UDim2.fromScale(0.5,0.5)}, .18)

-- ==================== [ADD-ONLY PATCH] UFO HUB X — Strict Server Verify, Retry, & Safe Rollback ====================
-- ใส่ต่อท้ายไฟล์เดิมทั้งก้อนได้เลย (ไม่แก้/ไม่ลบของเดิม)

-- รองรับหลายเบส (ตัวแรกคือ GETKEY_URL เดิมของคุณ) — จะลองทีละอัน + retry/backoff
local _UFOX_SERVER_BASES = { GETKEY_URL }
-- ถ้ามีโดเมนสำรอง ค่อยๆ เติมได้ เช่น:
-- table.insert(_UFOX_SERVER_BASES, "https://ufo-hub-x-key-backup.onrender.com")

-- ผูก uid/place ไปกับทุกคำขอ ให้เซิร์ฟเวอร์รู้ว่าใคร/จากไหน
local function _ufox_uid_place_qs()
    local plr = game:GetService("Players").LocalPlayer
    local uid   = tostring(plr and plr.UserId or "")
    local place = tostring(game.PlaceId or "")
    return ("&uid="..HttpService:UrlEncode(uid).."&place="..HttpService:UrlEncode(place))
end

-- JSON GET (เข้มงวด) + failover + retry/backoff (0s / 0.4s / 0.8s)
local function _ufox_json_get_failover(path_qs, timeoutSec)
    timeoutSec = tonumber(timeoutSec) or 8
    local lastErr = "no_servers"
    for _,base in ipairs(_UFOX_SERVER_BASES) do
        local url = tostring(base or "") .. tostring(path_qs or "")
        for i=0,2 do
            if i>0 then task.wait(0.4*i) end
            local done, okOut, dataOut, errOut = false, false, nil, "timeout"
            task.spawn(function()
                local ok, body = http_get(url)
                if ok and body then
                    local okj, data = pcall(function() return HttpService:JSONDecode(tostring(body)) end)
                    if okj and type(data)=="table" then
                        okOut, dataOut, errOut = true, data, nil
                    else
                        okOut, errOut = false, "json_error"
                    end
                else
                    okOut, errOut = false, (body or "http_error")
                end
                done = true
            end)
            local t0 = os.clock()
            while not done and (os.clock()-t0) < timeoutSec do task.wait(0.03) end
            if done and okOut then return true, dataOut, nil end
            lastErr = errOut or "http_error"
        end
    end
    return false, nil, lastErr
end

-- ตรวจแบบ “เข้มงวดจริง”: ต้องได้ { ok=true, valid=true, expires_at:number > now }
local function _ufox_verify_strict(key)
    local qs = "/verify?key="..HttpService:UrlEncode(key).._ufox_uid_place_qs()
    local ok, j, err = _ufox_json_get_failover(qs, 8)
    if not ok or not j then return false, (err or "http_error"), nil end
    if j.ok == true and j.valid == true then
        local exp = tonumber(j.expires_at)
        if exp and exp > os.time() then
            return true, nil, exp
        else
            return false, "bad_expires_at", nil
        end
    end
    return false, tostring(j.reason or "invalid"), nil
end

-- บังคับ “ตรวจซ้ำ” หลัง flow เดิมกดยืนยันสำเร็จ
-- ถ้า strict ไม่ผ่าน → ย้อน UI เป็น error (กันเคส “ใส่อะไรก็ผ่าน”)
if not _UFOX_STRICT_WRAPPED then
    _UFOX_STRICT_WRAPPED = true
    local _orig_doSubmit = doSubmit
    doSubmit = function()
        if submitting then return end
        local k = (keyBox and keyBox.Text) or ""
        _orig_doSubmit()

        task.defer(function()
            -- เดิมผ่านแล้ว? ตรวจซ้ำด้วย strict
            if _G and _G.UFO_HUBX_KEY_OK == true and _G.UFO_HUBX_KEY == k and k ~= "" then
                local ok, reason, exp = _ufox_verify_strict(k)
                if ok and exp then
                    if _G.UFO_SaveKeyState then pcall(_G.UFO_SaveKeyState, k, exp, false) end
                    -- ผ่านจริง เงียบ ๆ ไป (UI เดิมอาจกำลัง fade-out อยู่แล้ว)
                else
                    -- ไม่ผ่านจริง → rollback UI ให้เห็นชัด
                    _G.UFO_HUBX_KEY_OK = false
                    setStatus("เซิร์ฟเวอร์ปฏิเสธคีย์: "..tostring(reason or "invalid"), false)
                    showToast("❌ Key rejected by server", false)
                    submitting = false
                    if btnSubmit then
                        btnSubmit.Active = true
                        TS:Create(btnSubmit, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(210,60,60)}):Play()
                        btnSubmit.Text = "🔒  Submit Key"
                        btnSubmit.TextColor3 = Color3.new(1,1,1)
                    end
                    if keyStroke then
                        local old = keyStroke.Color
                        TS:Create(keyStroke, TweenInfo.new(0.05), {Color = Color3.fromRGB(255,90,90), Transparency = 0}):Play()
                        task.delay(.22, function()
                            TS:Create(keyStroke, TweenInfo.new(0.12), {Color = old, Transparency = 0.75}):Play()
                        end)
                    end
                end
            end
        end)
    end
end

-- เสริม log สถานะเซิร์ฟเวอร์ (ถ้ามี /status)
task.spawn(function()
    local ok, j = _ufox_json_get_failover("/status", 5)
    if ok and j and j.ok then
        print("[UFO-HUB-X] Server status: ONLINE")
    else
        print("[UFO-HUB-X] Server status: OFFLINE or Unreachable")
    end
end)

-- ปุ่ม Get Key (เพิ่มความฉลาด — ไม่ลบของเดิม): copy /getkey?uid=&place=
if not _UFOX_GETKEY_AUGMENTED and btnGetKey then
    _UFOX_GETKEY_AUGMENTED = true
    btnGetKey.MouseButton1Click:Connect(function()
        local plr = game:GetService("Players").LocalPlayer
        local uid   = tostring(plr and plr.UserId or "")
        local place = tostring(game.PlaceId or "")
        local link = GETKEY_URL.."/getkey?uid="..HttpService:UrlEncode(uid).."&place="..HttpService:UrlEncode(place)
        setClipboard(link)
        btnGetKey.Text = "✅ Link copied!"
        task.delay(1.5, function() btnGetKey.Text="🔐  Get Key" end)
    end)
end

-- ป้องกัน spam verify (debounce ภายใน 900ms) — ไม่แตะ flow เดิม แค่กันคลิกเร็วเกิน
if not _UFOX_CLICK_GUARD_APPLIED and btnSubmit then
    _UFOX_CLICK_GUARD_APPLIED = true
    local last = 0
    btnSubmit.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - last < 0.9 then
            return
        end
        last = now
    end)
end

-- ==================== [END OF ADD-ONLY PATCH] ====================

-- ==================== [ADD-ONLY GATE] Strict Verify Overlay (no removal) ====================
-- ไอเดีย: สร้างปุ่มโปร่งใสซ้อนบนปุ่มเดิม เพื่อ intercept คลิกทุกครั้ง
-- - ตรวจคีย์แบบเข้มด้วย JSON { ok=true, valid=true, expires_at > now } จากเซิร์ฟเวอร์
-- - ถ้าไม่ผ่าน: โชว์ error และ "ไม่ปล่อย" ให้ปุ่มเดิมทำงาน
-- - ถ้าผ่าน: เปิดทางชั่วคราว แล้วสั่ง btnSubmit:Activate() ให้ flow เดิมทำงานตามปกติ
-- - รองรับกด Enter ด้วย (ดักจาก TextBox)

-- รายการเซิร์ฟเวอร์ (ตัวแรกใช้ GETKEY_URL เดิมของคุณ)
local _UFOX_SERVER_BASES = { GETKEY_URL }
-- เพิ่มสำรองได้ (เฉพาะ "เพิ่ม" เท่านั้น)
-- table.insert(_UFOX_SERVER_BASES, "https://ufo-hub-x-key-backup.onrender.com")

-- uid/place สำหรับส่งไปให้เซิร์ฟเวอร์รู้ว่าใคร จากไหน
local function _ufox_uid_place_qs()
    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer
    local uid   = tostring(plr and plr.UserId or "")
    local place = tostring(game.PlaceId or "")
    return ("&uid="..HttpService:UrlEncode(uid).."&place="..HttpService:UrlEncode(place))
end

-- JSON GET + failover + retry/backoff (0s / 0.4s / 0.8s)
local function _ufox_json_get_failover(path_qs, timeoutSec)
    timeoutSec = tonumber(timeoutSec) or 8
    local lastErr = "no_servers"
    for _,base in ipairs(_UFOX_SERVER_BASES) do
        local url = tostring(base or "") .. tostring(path_qs or "")
        for i=0,2 do
            if i>0 then task.wait(0.4*i) end
            local done, okOut, dataOut, errOut = false, false, nil, "timeout"
            task.spawn(function()
                local ok, body = http_get(url) -- ใช้ฟังก์ชันเดิมของคุณ (ไม่แก้/ไม่ลบ)
                if ok and body then
                    local okj, data = pcall(function() return HttpService:JSONDecode(tostring(body)) end)
                    if okj and type(data)=="table" then
                        okOut, dataOut, errOut = true, data, nil
                    else
                        okOut, errOut = false, "json_error"
                    end
                else
                    okOut, errOut = false, (body or "http_error")
                end
                done = true
            end)
            local t0 = os.clock()
            while not done and (os.clock()-t0) < timeoutSec do task.wait(0.03) end
            if done and okOut then return true, dataOut, nil end
            lastErr = errOut or "http_error"
        end
    end
    return false, nil, lastErr
end

-- ตรวจแบบเข้มจริง: ต้องได้ JSON { ok=true, valid=true, expires_at:number > now }
local function _ufox_verify_strict(key)
    local qs = "/verify?key="..HttpService:UrlEncode(key).._ufox_uid_place_qs()
    local ok, j, err = _ufox_json_get_failover(qs, 8)
    if not ok or not j then return false, (err or "http_error"), nil end
    if j.ok == true and j.valid == true then
        local exp = tonumber(j.expires_at)
        if exp and exp > os.time() then
            return true, nil, exp
        else
            return false, "bad_expires_at", nil
        end
    end
    return false, tostring(j.reason or "invalid"), nil
end

-- ------------ สร้าง Gate ปุ่มโปร่งใสซ้อนบน btnSubmit ------------
local overlay -- ปุ่มโปร่งใส
local function _ufox_make_overlay()
    if not panel or not btnSubmit then return end
    if overlay and overlay.Parent then overlay:Destroy() end
    overlay = Instance.new("TextButton")
    overlay.Name = "UFOX_SubmitOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.ZIndex = (btnSubmit.ZIndex or 1) + 1
    overlay.Size = btnSubmit.Size
    overlay.Position = btnSubmit.Position
    overlay.AnchorPoint = btnSubmit.AnchorPoint
    overlay.Parent = panel
end

_ufox_make_overlay()
-- ถ้าปรับขนาด/ตำแหน่งปุ่มเดิมทีหลัง ก็ sync overlay ให้ตาม
task.spawn(function()
    while panel and panel.Parent do
        if overlay and btnSubmit then
            overlay.Size = btnSubmit.Size
            overlay.Position = btnSubmit.Position
            overlay.AnchorPoint = btnSubmit.AnchorPoint
            overlay.ZIndex = math.max((btnSubmit.ZIndex or 1)+1, 99)
        end
        task.wait(0.15)
    end
end)

-- ปิดการ Activate ของปุ่มเดิมไว้ตลอด (กันเคส keyBox กด Enter แล้วเรียก :Activate() เข้าปุ่มเดิมทันที)
-- เราจะ “เปิดทางชั่วคราว” เองตอนที่ผ่าน strict เท่านั้น
if btnSubmit then btnSubmit.Active = false end

-- ฟังก์ชัน Gate หลัก
local _gateRunning = false
local function _ufox_gate_submit()
    if _gateRunning then return end
    _gateRunning = true

    local key = (keyBox and keyBox.Text or "") or ""
    key = tostring(key)
    if key == "" then
        forceErrorUI("🚫 Please enter a key", "โปรดใส่รหัสก่อนนะ")
        _gateRunning = false
        return
    end

    setStatus("กำลังตรวจสอบกับเซิร์ฟเวอร์ (strict)…", nil)
    if btnSubmit then TS:Create(btnSubmit, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(70,170,120)}):Play() end

    -- ตรวจเข้ม
    local ok, reason, exp = _ufox_verify_strict(key)

    if not ok then
        -- ไม่ผ่าน → ไม่ปล่อยให้ปุ่มเดิมทำงาน
        if reason == "server_unreachable" then
            forceErrorUI("❌ Invalid Key", "เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่หรือตรวจเน็ต")
        else
            forceErrorUI("❌ Invalid Key", "กุญแจไม่ถูกต้อง ลองอีกครั้ง")
        end
        _gateRunning = false
        return
    end

    -- ผ่านจริง → เปิดทางชั่วคราว แล้วสั่งปุ่มเดิมทำงาน
    showToast("ยืนยัน strict ผ่าน กำลังเข้าสู่ระบบเดิม…", true)
    if _G and _G.UFO_SaveKeyState and exp then pcall(_G.UFO_SaveKeyState, key, exp, false) end

    -- เปิดปุ่มเดิมชั่วคราว เพื่อให้ doSubmit เดิมวิ่ง
    if btnSubmit then
        btnSubmit.Active = true
        -- ซ่อน overlay ชั่วคราว เพื่อกันไม่ให้บัง self-Activate
        if overlay then overlay.Visible = false end
        task.wait() -- 1 frame
        pcall(function() btnSubmit:Activate() end)
        task.wait(0.05)
        if overlay then overlay.Visible = true end
        btnSubmit.Active = false
    end

    _gateRunning = false
end

-- คลิกที่ overlay = วิ่งผ่าน Gate
if overlay then
    overlay.MouseButton1Click:Connect(_ufox_gate_submit)
    overlay.Activated:Connect(_ufox_gate_submit)
end

-- รองรับกด Enter ที่ keyBox (แทนที่จะให้ไปเรียก :Activate ของปุ่มเดิมโดยตรง)
if keyBox then
    keyBox.FocusLost:Connect(function(enter)
        if enter then
            _ufox_gate_submit()
        end
    end)
end

-- กัน spam คลิกเร็ว ๆ ที่ overlay
local _lastClick = 0
if overlay then
    overlay.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - _lastClick < 0.8 then return end
        _lastClick = now
    end)
end

-- ตัวช่วย debug สถานะ server (ไม่ยุ่ง UI เดิม)
task.spawn(function()
    local ok, j = _ufox_json_get_failover("/status", 5)
    if ok and j and j.ok then
        print("[UFO-HUB-X] Server status: ONLINE")
    else
        print("[UFO-HUB-X] Server status: OFFLINE or Unreachable")
    end
end)
-- ==================== [END ADD-ONLY GATE] ====================
