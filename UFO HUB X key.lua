----------------------------------------------------------------
-- [ADD BLOCK] — SAFE BOOSTERS / DEBUG / EXTRA BUTTONS
-- วาง "ต่อท้าย" ไฟล์เดิม (ไม่ต้องแก้อะไรด้านบน)
----------------------------------------------------------------

-- ===== Debug flags (ปรับได้) =====
_G.UFO_HUBX_DEBUG          = _G.UFO_HUBX_DEBUG ~= nil and _G.UFO_HUBX_DEBUG or true   -- log เพิ่ม
_G.UFO_HUBX_KEEP_UI        = _G.UFO_HUBX_KEEP_UI or false  -- true = ไม่ destroy ตอนผ่านคีย์ (ซ่อนไว้เฉยๆ)
_G.UFO_HUBX_FORCE_TOPMOST  = _G.UFO_HUBX_FORCE_TOPMOST or true  -- true = บังคับให้ gui อยู่ CoreGui เสมอ

local function dbg(...)
    if _G.UFO_HUBX_DEBUG then
        print("[UFO-HUB-X/DBG]", ...)
    end
end

-- ===== Watchdog: ถ้า UI ไม่ขึ้น/ถูกย้าย parent ผิด ให้ดึงกลับมาที่ CoreGui =====
task.defer(function()
    local tries = 0
    while tries < 60 do
        tries += 1
        if not gui or not gui.Parent then
            pcall(function()
                if gethui then
                    gui.Parent = gethui()
                else
                    gui.Parent = CG
                end
            end)
        end
        if gui then
            gui.Enabled = true
            gui.DisplayOrder = 1_000_000
            gui.IgnoreGuiInset = true
        end
        if _G.UFO_HUBX_FORCE_TOPMOST and gui and gui.Parent ~= CG and not gethui then
            pcall(function() gui.Parent = CG end)
        end
        if tries == 1 then
            dbg("GUI parent is", gui and gui.Parent)
        end
        task.wait(0.2)
    end
end)

-- ===== ถ้าต้องการ "ไม่ทำลาย" UI ตอนผ่านคีย์ ให้ Override fadeOutAndDestroy แบบไม่ลบจริง =====
if _G.UFO_HUBX_KEEP_UI and type(fadeOutAndDestroy) == "function" then
    local __origFade = fadeOutAndDestroy
    fadeOutAndDestroy = function()
        dbg("KEEP_UI enabled -> hide instead of destroy")
        pcall(function()
            panel.Visible = false
            panel.BackgroundTransparency = 1
        end)
        -- ถ้าอยากกลับมาโชว์ใหม่ เรียก _G.UFO_ShowKeyUI()
    end
    _G.UFO_ShowKeyUI = function()
        pcall(function()
            panel.Visible = true
            panel.BackgroundTransparency = 0
            tween(panel, {Position = UDim2.fromScale(0.5,0.5)}, .18)
        end)
    end
end

-- ===== ปุ่ม/พื้นที่ “เปิด UI กลับมา” (กรณีปิดไปแล้ว) =====
local reopenBtn = make("TextButton", {
    Parent = gui,
    Text = "UFO Key",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.new(1,1,1),
    AutoButtonColor = true,
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(76, 24),
    Position = UDim2.new(1, -86, 0, 8),
    Visible = true,
    ZIndex = 999999
},{
    make("UICorner",{CornerRadius=UDim.new(0,8)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.4})
})
reopenBtn.MouseButton1Click:Connect(function()
    if panel then
        panel.Visible = true
        tween(panel, {BackgroundTransparency = 0}, .12)
    end
end)

-- ===== สถานะเซิร์ฟเวอร์มุมล่าง (พิง /status) =====
local serverStatus = make("TextLabel", {
    Parent = panel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1,-56,0,18),
    Position = UDim2.new(0, 28, 1, -44),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Server: checking...",
    TextColor3 = Color3.fromRGB(160,160,160),
    ZIndex = 9,
}, {})
task.defer(function()
    local ok, data = json_get_with_failover("/status")
    if ok and data and data.ok then
        serverStatus.Text = "Server: online ✓"
        serverStatus.TextColor3 = Color3.fromRGB(120,255,170)
    else
        serverStatus.Text = "Server: offline (retry on submit)"
        serverStatus.TextColor3 = Color3.fromRGB(255,140,140)
    end
end)

-- ===== ลิงก์หน้า UI จริง พร้อม uid/place =====
local function makeUiLink()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    return string.format("%s/index.html?uid=%s&place=%s",
        (SERVER_BASES[1] or ""),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
end

-- ===== สร้างปุ่มแยก: API Link / UI Link =====
-- (ไม่ไปยุ่งกับ handler เดิมของคุณ ปล่อยให้ทำงานควบคู่กันได้)
local btnRow = make("Frame", {
    Parent = panel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -56, 0, 40),
    Position = UDim2.new(0,28,0,324),
    ZIndex = 4
}, {
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
    })
})

local btnCopyApi = make("TextButton", {
    Parent=btnRow, Text="📋 Copy API Link",
    Font=Enum.Font.Gotham, TextSize=14,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(0, 160, 0, 38)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.7})
})
btnCopyApi.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local base  = SERVER_BASES[1] or ""
    local api   = string.format("%s/getkey?uid=%s&place=%s", base,
        HttpService:UrlEncode(uid), HttpService:UrlEncode(place))
    setClipboard(api)
    btnCopyApi.Text = "✅ Copied!"
    task.delay(1.2, function() btnCopyApi.Text = "📋 Copy API Link" end)
end)

local btnOpenUi = make("TextButton", {
    Parent=btnRow, Text="🌐 Open Key UI",
    Font=Enum.Font.GothamBold, TextSize=16,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=false,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.new(0, 180, 0, 38)
},{
    make("UICorner",{CornerRadius=UDim.new(0,10)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})
btnOpenUi.MouseButton1Click:Connect(function()
    local uiUrl = makeUiLink()
    local opened = false
    local ok1 = pcall(function()
        if GuiService and GuiService.OpenBrowserWindow then
            GuiService:OpenBrowserWindow(uiUrl); opened = true
        end
    end)
    if not ok1 or not opened then
        if syn and syn.open_url then
            pcall(function() syn.open_url(uiUrl); opened = true end)
        end
    end
    setClipboard(uiUrl) -- สำรองไว้เสมอ
    if opened then
        btnOpenUi.Text = "✅ Opened UI"
    else
        btnOpenUi.Text = "✅ Copied UI Link"
    end
    task.delay(1.4, function() btnOpenUi.Text = "🌐 Open Key UI" end)
end)

-- ===== ปุ่มเล็ก +48H ต่ออายุคีย์เดิม (คุณยัง verify/extend ฝั่ง server แล้ว) =====
local btnExtend = make("TextButton", {
    Parent=panel, Text="⏳ +48H",
    Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=Color3.new(1,1,1), AutoButtonColor=true,
    BackgroundColor3=SUB, BorderSizePixel=0,
    Size=UDim2.fromOffset(70, 28),
    Position=UDim2.new(1, -56-70, 1, -52),
    ZIndex=6
},{
    make("UICorner",{CornerRadius=UDim.new(0,8)}),
    make("UIStroke",{Color=ACCENT, Transparency=0.6})
})
btnExtend.MouseButton1Click:Connect(function()
    local uid   = tostring(LP and LP.UserId or "")
    local key   = tostring(_G.UFO_HUBX_KEY or "")
    if key == "" then
        showToast("ยังไม่มีคีย์ใช้ใน session", false); return
    end
    setStatus("ขอต่ออายุคีย์...", nil)
    local qs = string.format("/extend?key=%s&uid=%s",
        HttpService:UrlEncode(key),
        HttpService:UrlEncode(uid))
    local ok, data = json_get_with_failover(qs)
    if ok and data and data.ok then
        showToast("ต่ออายุเรียบร้อย ✓", true)
        setStatus("คีย์มีอายุจนถึง: "..tostring(data.expires_at), true)
    else
        showToast("ต่ออายุไม่สำเร็จ", false)
        setStatus("extend ล้มเหลว ลองใหม่", false)
    end
end)

-- ===== เปิดเสียง/แอนิเมชันเล็กน้อยตอนโหลด =====
task.defer(function()
    tween(panel, {Position = UDim2.fromScale(0.5,0.5)}, .18)
    dbg("Key UI Loaded OK, parent:", gui and gui.Parent)
end)

----------------------------------------------------------------
-- [END ADD BLOCK]
----------------------------------------------------------------
