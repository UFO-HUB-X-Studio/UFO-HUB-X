----------------------------------------------------------------
-- [ADD BLOCK : APPEND-ONLY]  — วาง "ต่อท้ายไฟล์" เท่านั้น
-- ไม่ลบ/ไม่แก้ของเดิม มีแต่เพิ่ม และห่อ/เสริมด้วย wrapper ที่ถอดออกได้
----------------------------------------------------------------

-- ===== FLAGS / DEBUG =====
_G.UFOX_DEBUG         = (_G.UFOX_DEBUG ~= nil) and _G.UFOX_DEBUG or true
_G.UFOX_FORCE_TOPMOST = (_G.UFOX_FORCE_TOPMOST ~= nil) and _G.UFOX_FORCE_TOPMOST or true
_G.UFOX_KEEP_UI       = (_G.UFOX_KEEP_UI ~= nil) and _G.UFOX_KEEP_UI or false  -- true = ซ่อนแทนทำลายหลังผ่านคีย์

local function log(...) if _G.UFOX_DEBUG then print("[UFO-HUB-X/ADD]", ...) end end

-- ===== Failover server list (อิง GETKEY_URL ตัวหลัก) =====
local SERVER_BASES = {
    tostring(GETKEY_URL or "https://ufo-hub-x-key.onrender.com"),
    -- "https://ufo-hub-x-key-backup.onrender.com", -- เพิ่มสำรองได้
}

-- ===== Mini JSON helpers แยกชื่อ (ไม่ชนของเดิม) =====
local function http_json_get_add(url)
    local ok, body = http_get(url)
    if not ok or not body then return false, nil, "http_error" end
    local okj, data = pcall(function() return HttpService:JSONDecode(tostring(body)) end)
    if not okj then return false, nil, "json_error" end
    return true, data, nil
end

local function json_get_with_failover_add(path_qs)
    local last_err = "no_servers"
    for _, base in ipairs(SERVER_BASES) do
        local url = (base .. path_qs)
        for i=0,2 do
            if i>0 then task.wait(0.5*i) end
            local ok, data, err = http_json_get_add(url)
            if ok and data then return true, data end
            last_err = err or "http_error"
        end
    end
    return false, nil, last_err
end

-- ===== เปิดเบราว์เซอร์แบบปลอดภัย (มี fallback = คัดลอกลิงก์) =====
local GuiService = game:GetService("GuiService")
local function openExternal_add(url)
    local opened = false
    if GuiService and GuiService.OpenBrowserWindow then
        opened = pcall(function() GuiService:OpenBrowserWindow(url) end) or opened
    end
    if (not opened) and syn and syn.open_url then
        opened = pcall(function() syn.open_url(url) end) or opened
    end
    if not opened and setclipboard then pcall(setclipboard, url) end
    return opened
end

-- ===== สร้างลิงก์หน้า UI จริง พร้อม uid/place =====
local function makeUiLink_add()
    local Players = game:GetService("Players")
    local uid   = tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or "")
    local place = tostring(game.PlaceId or "")
    return string.format("%s/index.html?uid=%s&place=%s",
        (SERVER_BASES[1] or ""),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
end

-- ===== Wrapper: verifyWithServer แบบ JSON เต็ม (เพิ่มเฉย ๆ) =====
do
    local __orig_verify = verifyWithServer
    local function verifyWithServer_json(key)
        local Players = game:GetService("Players")
        local uid   = tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or "")
        local place = tostring(game.PlaceId or "")
        local qs = string.format("/verify?key=%s&uid=%s&place=%s",
            HttpService:UrlEncode(key), HttpService:UrlEncode(uid), HttpService:UrlEncode(place))
        local ok, data, err = json_get_with_failover_add(qs)
        if not ok or not data then
            return false, "server_unreachable", nil
        end
        if data.ok and data.valid then
            local exp = tonumber(data.expires_at) or (os.time() + 48*3600)
            return true, nil, exp
        else
            return false, tostring(data.reason or "invalid"), nil
        end
    end
    -- เปลี่ยนชื่อของเดิมเป็น backup แล้วใส่ตัวใหม่ที่ฉลาดขึ้น
    if type(__orig_verify) == "function" then
        _G.UFOX_VerifyLegacy = __orig_verify
        verifyWithServer = function(key)
            -- ลอง JSON เต็มก่อน
            local ok, reason, exp = verifyWithServer_json(key)
            if ok ~= nil then
                return ok, reason, exp
            end
            -- ไม่งั้น fallback ของเดิม
            local ok2, rs2 = _G.UFOX_VerifyLegacy(key)
            return ok2, rs2, nil
        end
    else
        verifyWithServer = function(key)
            local ok, reason, exp = verifyWithServer_json(key)
            return ok, reason, exp
        end
    end
end

-- ===== Fix fadeOut (ไม่แก้ของเดิม แต่ override แบบปลอดภัย) =====
do
    local __orig_fade = fadeOutAndDestroy
    fadeOutAndDestroy = function()
        if _G.UFOX_KEEP_UI then
            log("KEEP_UI active: hide instead of destroy")
            pcall(function()
                if panel then
                    for _, d in ipairs(panel:GetDescendants()) do
                        pcall(function()
                            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                                d.TextTransparency = 1
                                if d:IsA("TextBox") or d:IsA("TextButton") then d.BackgroundTransparency = 1 end
                            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                                d.ImageTransparency, d.BackgroundTransparency = 1, 1
                            elseif d:IsA("Frame") then
                                d.BackgroundTransparency = 1
                            elseif d:IsA("UIStroke") then
                                d.Transparency = 1
                            end
                        end)
                    end
                    panel.Visible = false
                end
            end)
            return
        end
        -- ถ้าเดิมมี ให้เรียกของเดิมก่อน
        if type(__orig_fade) == "function" then
            local ok = pcall(__orig_fade)
            if ok then return end
        end
        -- ถ้าของเดิมพัง/ไม่มี ใช้ safe fade
        pcall(function()
            if not panel then return end
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
            task.delay(0.22, function() if gui and gui.Parent then gui:Destroy() end end)
        end)
    end
end

-- ===== Watchdog: ยืนยันว่ามี UI เสมอ และ Topmost =====
task.defer(function()
    for _=1,80 do
        if gui then
            if not gui.Parent then
                pcall(function()
                    if gethui then gui.Parent = gethui() else gui.Parent = CG end
                end)
            end
            gui.Enabled = true
            gui.DisplayOrder = 999999
            gui.IgnoreGuiInset = true
            if _G.UFOX_FORCE_TOPMOST and gui.Parent ~= CG and not gethui then
                pcall(function() gui.Parent = CG end)
            end
        end
        task.wait(0.2)
    end
    log("watchdog done; parent:", gui and gui.Parent)
end)

-- ===== Ping server status (/status) แสดงใต้ปุ่ม =====
local srvStatus = make("TextLabel", {
    Parent = panel, BackgroundTransparency = 1, ZIndex=8,
    Size = UDim2.new(1,-56,0,18), Position = UDim2.new(0,28,1,-44),
    Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Server: checking...", TextColor3 = Color3.fromRGB(160,160,160)
},{})
task.defer(function()
    local ok, data = json_get_with_failover_add("/status")
    if ok and data and data.ok then
        srvStatus.Text = "Server: online ✓"
        srvStatus.TextColor3 = Color3.fromRGB(120,255,170)
    else
        srvStatus.Text = "Server: offline (จะลองใหม่ตอนยืนยัน/กดปุ่ม)"
        srvStatus.TextColor3 = Color3.fromRGB(255,150,150)
    end
end)

-- ===== ปุ่มเพิ่ม: เปิดหน้า UI จริง + ปุ่มคัดลอก API link แยก =====
local extraRow = make("Frame", {
    Parent=panel, BackgroundTransparency=1, ZIndex=5,
    Size=UDim2.new(1,-56,0,40), Position=UDim2.new(0,28,0,324+44+8)
},{
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0,10)
    })
})

local btnOpenUi = make("TextButton", {
    Parent=extraRow, Text="🌐 Open Key UI", ZIndex=6,
    Font=Enum.Font.GothamBold, TextSize=16,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0, Size=UDim2.new(0,180,0,38)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.55})
})
btnOpenUi.MouseButton1Click:Connect(function()
    local url = makeUiLink_add()
    local opened = openExternal_add(url)
    if not opened then setClipboard(url) end
    btnOpenUi.Text = opened and "✅ Opened UI" or "✅ Copied UI Link"
    task.delay(1.4, function() btnOpenUi.Text = "🌐 Open Key UI" end)
end)

local btnCopyApi = make("TextButton", {
    Parent=extraRow, Text="📋 Copy API Link", ZIndex=6,
    Font=Enum.Font.Gotham, TextSize=14,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0, Size=UDim2.new(0,160,0,38)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.7})
})
btnCopyApi.MouseButton1Click:Connect(function()
    local Players = game:GetService("Players")
    local uid   = tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or "")
    local place = tostring(game.PlaceId or "")
    local base  = SERVER_BASES[1] or tostring(GETKEY_URL or "")
    local api   = string.format("%s/getkey?uid=%s&place=%s",
        base, HttpService:UrlEncode(uid), HttpService:UrlEncode(place))
    setClipboard(api)
    btnCopyApi.Text = "✅ Copied!"
    task.delay(1.2, function() btnCopyApi.Text = "📋 Copy API Link" end)
end)

-- ===== ปุ่มลอยเล็กไว้เรียก UI กลับ ถ้าเผลอปิด =====
local reopen = make("TextButton", {
    Parent = gui, ZIndex = 999999,
    Text = "UFO Key", Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = Color3.new(1,1,1), AutoButtonColor = true,
    BackgroundColor3 = Color3.fromRGB(25,25,25), BorderSizePixel = 0,
    Size = UDim2.fromOffset(76,24), Position = UDim2.new(1,-86,0,8)
},{
    make("UICorner",{CornerRadius=UDim.new(0,8)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.4})
})
reopen.MouseButton1Click:Connect(function()
    if panel then
        panel.Visible = true
        TS:Create(panel, TweenInfo.new(.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    end
end)

log("Add-block loaded OK; gui parent:", gui and gui.Parent)
----------------------------------------------------------------
-- [END ADD BLOCK]
----------------------------------------------------------------
