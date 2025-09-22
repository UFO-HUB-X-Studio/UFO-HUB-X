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
-- ใช้ place ของเกมปัจจุบันเป็นหลักอยู่แล้ว แต่ถ้าอยาก "บังคับ" หรือ
-- มีหลายเกม ก็ใส่ในตารางนี้ได้ (จะใช้เฉพาะเวลา “คัดลอกลิงก์เว็บ/extend”)
_G.UFOX_PLACE_ALLOW = _G.UFOX_PLACE_ALLOW or {
    -- ["ชื่อเกมที่อยากแสดง"] = placeId,
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
    local HttpService = game:GetService("HttpService")
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

-- ===== Normalizer (ไม่แทนที่ของเดิม แค่ช่วยแปลงรูปแบบ) =====
local function normalizeKeyLua(s)
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
        -- ยิง /verify แบบเบา ๆ (ใช้ uid/place จริง)
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local uid   = tostring(LP and LP.UserId or "")
            local place = currentPlaceId()
            local kNorm = normalizeKeyLua(txt)
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

-- Hook doSubmit เดิม: แค่แทรก normalize ก่อนวิ่งต่อ (ไม่แก้ลอจิกเดิม)
do
    if type(doSubmit)=="function" and not _G.__UFOX_SUBMIT_HOOKED2 then
        _G.__UFOX_SUBMIT_HOOKED2 = true
        local orig = doSubmit
        doSubmit = function()
            if keyBox and keyBox.Text and #keyBox.Text>0 then
                keyBox.Text = normalizeKeyLua(keyBox.Text)
            end
            return orig()
        end
    end
end

-- ===== แผงควบคุมด้านล่าง (Status / Extend / Open Web) =====
local ctrlCard = (function()
    local y = 268+50+6+26+84+8 -- วางต่อจาก statusCard เดิม (ถ้ามี) หรือเลื่อนลง
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
    TextColor3=Color3.fromRGB(210,255,235), Text="Server: … | UID: … | Place: …"
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

-- เรียก /status จริง
local function fetchStatus()
    local HttpService = game:GetService("HttpService")
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
    local HttpService = game:GetService("HttpService")
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
    local HttpService = game:GetService("HttpService")
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

-- =========== (ออปชัน) รองรับหลาย PlaceId ใน UI (Label เล็ก ๆ มุมล่าง) ===========
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
-- (วางต่อท้ายไฟล์หลักได้เลย ไม่แก้ของเดิม)
----------------------------------------------------------------
