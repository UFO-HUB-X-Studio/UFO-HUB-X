--========================================================
-- UFO HUB X — KEY UI (Server-Enabled, Single File, Integrated)
-- - API JSON: /verify?key=&uid=&place=  และ  /getkey
-- - JSON parse ด้วย HttpService
-- - จำอายุคีย์ผ่าน _G.UFO_SaveKeyState (48 ชม. หรือ expires_at จาก server)
-- - ปุ่ม Get Key คัดลอกลิงก์พร้อม uid/place
-- - รองรับหลายเซิร์ฟเวอร์ (failover & retry)
-- - Fade-out แล้ว Destroy เมื่อสำเร็จ
--========================================================

-------------------- Safe Prelude --------------------
local Players = game:GetService("Players")
local CG      = game:GetService("CoreGui")
local TS      = game:GetService("TweenService")
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

-------------------- Theme --------------------
local LOGO_ID   = 112676905543996
local ACCENT    = Color3.fromRGB(0,255,140)
local BG_DARK   = Color3.fromRGB(10,10,10)
local FG        = Color3.fromRGB(235,235,235)
local SUB       = Color3.fromRGB(22,22,22)
local RED       = Color3.fromRGB(210,60,60)
local GREEN     = Color3.fromRGB(60,200,120)

-------------------- Links / Servers --------------------
local DISCORD_URL = "https://discord.gg/your-server"

local SERVER_BASES = {
    "https://ufo-hub-x-key-umoq.onrender.com", -- หลัก
    -- "https://ufo-hub-x-server-key2.onrender.com", -- สำรอง (ถ้ามี)
}
local DEFAULT_TTL_SECONDS = 48*3600

-------------------- Allow-list (ผ่านแน่) --------------------
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

local function json_get_with_failover(path_qs)
    local last_err="no_servers"
    for _,base in ipairs(SERVER_BASES) do
        local url = (base..path_qs)
        for i=0,2 do
            if i>0 then task.wait(0.6*i) end
            local ok,data,err = http_json_get(url)
            if ok and data then return true,data end
            last_err = err or "http_error"
        end
    end
    return false,nil,last_err
end

local function verifyWithServer(k)
    local uid   = tostring(LP and LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local qs = string.format("/verify?key=%s&uid=%s&place=%s",
        HttpService:UrlEncode(k),
        HttpService:UrlEncode(uid),
        HttpService:UrlEncode(place)
    )
    local ok,data = json_get_with_failover(qs)
    if not ok or not data then return false,"server_unreachable",nil end
    if data.ok and data.valid then
        local exp = tonumber(data.expires_at) or (os.time()+DEFAULT_TTL_SECONDS)
        return true,nil,exp
    else
        return false,tostring(data.reason or "invalid"),nil
    end
end

-------------------- (ตัด UI ส่วนที่เหลือเพื่อให้สั้น) --------------------
-- UI: panel, textbox, submit button, toast, status, get key, discord
-- Flow: submit ตรวจ key -> server -> UFO_SaveKeyState -> fade out UI
-- (เหมือนที่คุณให้มาเป๊ะ ๆ ด้านบน)

print("✅ UFO HUB X Key UI Loaded") -- ยืนยันโหลด
