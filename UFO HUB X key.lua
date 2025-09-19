--========================================================
-- UFO HUB X — KEY UI (Simple, 100% ready)
--========================================================

--=========== Services ===========
local TS   = game:GetService("TweenService")
local CG   = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

--=========== Theme ===========
local ACCENT  = Color3.fromRGB(0,255,140)
local BG      = Color3.fromRGB(12,12,12)
local FG      = Color3.fromRGB(235,235,235)
local SUB     = Color3.fromRGB(26,26,26)
local RED     = Color3.fromRGB(210,60,60)
local GREEN   = Color3.fromRGB(60,200,120)

--=========== Server bases (แก้เป็นของคุณ) ===========
local SERVER_BASES = {
    "http://127.0.0.1:3000",                     -- dev local
    -- "https://ufo-hub-x-key-umoq.onrender.com", -- prod
}

--=========== Defaults ===========
local DEFAULT_TTL_SECONDS = 48 * 3600

--=========== Helpers (HTTP/JSON) ===========
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

-- วนทีละ BASE + retry/backoff
local function json_get_with_failover(path_qs)
    local last_err = "no_servers"
    for _, base in ipairs(SERVER_BASES) do
        local url = (base..path_qs)
        for i=0,2 do                       -- 0s / 0.6s / 1.2s
            if i>0 then task.wait(0.6*i) end
            local ok, data, err = http_json_get(url)
            if ok and data then return true, data end
            last_err = err or "http_error"
        end
    end
    return false, nil, last_err
end

--=========== Verify ===========
local function verifyWithServer(k)
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local qs = string.format("/verify?key=%s&uid=%s&place=%s&format=json",
        HttpService:UrlEncode(k),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    local ok, data = json_get_with_failover(qs)
    if not ok or not data then return false, "server_unreachable", nil end

    local valid = (data.valid == true) or (data.ok == true and data.valid == true)
    if not valid then return false, tostring(data.reason or "invalid"), nil end

    local exp = tonumber(data.expires_at) or (os.time() + DEFAULT_TTL_SECONDS)
    return true, nil, exp
end

local function getKeyUrlForCurrentPlayer()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local base  = SERVER_BASES[1] or ""
    return string.format("%s/getkey?uid=%s&place=%s",
        base, HttpService:UrlEncode(uid), HttpService:UrlEncode(place))
end

--=========== UI Utils ===========
local function make(class, props, kids)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent=o end
    return o
end

local function tween(o, goal, t)
    TS:Create(o, TweenInfo.new(t or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function safeParent(gui)
    local ok=false
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end
    if gethui then ok = pcall(function() gui.Parent = gethui() end) end
    if not ok then gui.Parent = CG end
end

local function setClipboard(s) if setclipboard then pcall(setclipboard, s) end end

--=========== Build UI ===========
local gui = Instance.new("ScreenGui")
gui.Name = "UFOHubX_KeyUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn  = false
gui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
safeParent(gui)

local panel = make("Frame", {
    Parent=gui, Active=true, Draggable=true, BackgroundColor3=BG, BorderSizePixel=0,
    Size=UDim2.fromOffset(680, 360), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5)
},{
    make("UICorner",{CornerRadius=UDim.new(0,18)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.2})
})

local title = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Text="UFO HUB X — KEY SYSTEM",
    Font=Enum.Font.GothamBlack, TextSize=22, TextColor3=ACCENT,
    Size=UDim2.new(1,-24,0,34), Position=UDim2.new(0,12,0,12), TextXAlignment=Enum.TextXAlignment.Left
},{})

local L = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Text="ใส่คีย์เพื่อใช้งาน",
    Font=Enum.Font.Gotham, TextSize=16, TextColor3=FG, Size=UDim2.new(1,-24,0,24),
    Position=UDim2.new(0,12,0,54), TextXAlignment=Enum.TextXAlignment.Left
},{})

local keyStroke
local keyBox = make("TextBox",{
    Parent=panel, ClearTextOnFocus=false, PlaceholderText="insert your key here",
    Font=Enum.Font.Gotham, TextSize=16, Text="", TextColor3=FG, BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-24,0,40), Position=UDim2.new(0,12,0,84)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    (function() keyStroke = make("UIStroke",{Color=ACCENT, Transparency=0.6}); return keyStroke end)()
})

local btnSubmit = make("TextButton",{
    Parent=panel, Text="🔒  Submit Key", Font=Enum.Font.GothamBlack, TextSize=18,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false, BackgroundColor3=RED, BorderSizePixel=0,
    Size=UDim2.new(1,-24,0,46), Position=UDim2.new(0,12,0,134)
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)})
})

local btnGetKey = make("TextButton",{
    Parent=panel, Text="🔐  Get Key (copy link)", Font=Enum.Font.GothamBold, TextSize=16,
    TextColor3=ACCENT, AutoButtonColor=false, BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(1,-24,0,40), Position=UDim2.new(0,12,0,186)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})

local statusLabel = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1, Text="", Font=Enum.Font.Gotham, TextSize=14,
    TextColor3=Color3.fromRGB(200,200,200), Size=UDim2.new(1,-24,0,22), Position=UDim2.new(0,12,0,236),
    TextXAlignment=Enum.TextXAlignment.Left
},{})

local toast = make("TextLabel",{
    Parent=panel, BackgroundColor3=Color3.fromRGB(30,30,30), BackgroundTransparency=.15,
    Text="", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.new(1,1,1),
    Size=UDim2.fromOffset(0,30), Position=UDim2.new(0.5,0,0,12), AnchorPoint=Vector2.new(0.5,0), Visible=false
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
})

local function showToast(msg, ok)
    toast.Text = msg
    toast.BackgroundColor3 = ok and Color3.fromRGB(20,120,60) or Color3.fromRGB(150,35,35)
    toast.Size = UDim2.fromOffset(math.max(160, (#msg*8)+24), 30)
    toast.Visible = true
    tween(toast, {BackgroundTransparency = 0.05}, .08)
    task.delay(1.1, function()
        tween(toast, {BackgroundTransparency = 1}, .12)
        task.delay(.12, function() toast.Visible=false end)
    end)
end

local function setStatus(txt, ok)
    statusLabel.Text = txt or ""
    statusLabel.TextColor3 = ok==nil and Color3.fromRGB(200,200,200)
        or (ok and Color3.fromRGB(120,255,170) or Color3.fromRGB(255,120,120))
end

--=========== Interactions ===========
local submitting = false
local function refreshSubmit()
    if submitting then return end
    local has = (keyBox.Text and #keyBox.Text>0)
    btnSubmit.Text = has and "🔓  Submit Key" or "🔒  Submit Key"
    btnSubmit.BackgroundColor3 = has and GREEN or RED
    btnSubmit.TextColor3 = has and Color3.new(0,0,0) or Color3.new(1,1,1)
end
keyBox:GetPropertyChangedSignal("Text"):Connect(function() setStatus("", nil); refreshSubmit() end)
refreshSubmit()

local function flashError()
    if keyStroke then
        local old = keyStroke.Color
        tween(keyStroke, {Color = Color3.fromRGB(255,90,90), Transparency = 0}, .05)
        task.delay(.22, function() tween(keyStroke, {Color = old, Transparency = 0.6}, .1) end)
    end
end

local function fadeOutAndDestroy()
    for _,d in ipairs(panel:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                TS:Create(d, TweenInfo.new(.15), {TextTransparency=1}):Play()
            end
            if d:IsA("GuiObject") then
                TS:Create(d, TweenInfo.new(.15), {BackgroundTransparency=1}):Play()
            end
        end)
    end
    TS:Create(panel, TweenInfo.new(.15), {BackgroundTransparency=1}):Play()
    task.delay(.18, function() if gui and gui.Parent then gui:Destroy() end end)
end

local function doSubmit()
    if submitting then return end
    submitting = true; btnSubmit.Active=false
    local k = keyBox.Text or ""
    if k == "" then
        setStatus("โปรดใส่รหัสก่อนนะ", false); showToast("Please enter a key", false); flashError()
        submitting=false; btnSubmit.Active=true; return
    end

    setStatus("กำลังตรวจสอบคีย์...", nil)
    btnSubmit.Text = "⏳ Verifying..."

    local ok, reason, exp = verifyWithServer(k)
    if not ok then
        if reason == "server_unreachable" then
            setStatus("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่", false); showToast("Server unreachable", false)
        else
            setStatus("กุญแจไม่ถูกต้อง ลองอีกครั้ง", false); showToast("Invalid key", false)
        end
        flashError(); keyBox.Text=""; submitting=false; btnSubmit.Active=true; refreshSubmit()
        return
    end

    btnSubmit.Text = "✅ Key accepted"
    setStatus("ยืนยันคีย์สำเร็จ พร้อมใช้งาน!", true)
    showToast("ยืนยันสำเร็จ", true)
    _G.UFO_HUBX_KEY_OK = true
    _G.UFO_HUBX_KEY    = k
    if _G.UFO_SaveKeyState and exp then pcall(_G.UFO_SaveKeyState, k, tonumber(exp) or (os.time()+DEFAULT_TTL_SECONDS), false) end
    task.delay(.15, fadeOutAndDestroy)
end
btnSubmit.MouseButton1Click:Connect(doSubmit)
keyBox.FocusLost:Connect(function(enter) if enter then doSubmit() end end)

btnGetKey.MouseButton1Click:Connect(function()
    local link = getKeyUrlForCurrentPlayer()
    setClipboard(link)
    btnGetKey.Text = "✅ Link copied!"
    task.delay(1.2, function() btnGetKey.Text="🔐  Get Key (copy link)" end)
end)
