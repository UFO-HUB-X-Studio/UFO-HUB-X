-- UFO HUB X — Bootloader (split modules)
local httpget = (syn and syn.request and function(u) return syn.request({Url=u, Method="GET"}).Body end)
              or (http_request and function(u) return http_request({Url=u, Method="GET"}).Body end)
              or (request and function(u) return request({Url=u, Method="GET"}).Body end)
              or function(u) return game:HttpGet(u) end

local function fetch(url)
    local ok, res = pcall(httpget, url)
    if not ok then error("HTTP fail: "..tostring(res)) end
    return res
end

local function loadModule(name, url)
    local src = fetch(url)
    local fn, err = loadstring(src, name)
    if not fn then error("loadstring "..name.." failed: "..tostring(err)) end
    local ok, mod = pcall(fn)
    if not ok then error("run "..name.." failed: "..tostring(mod)) end
    if type(mod) ~= "table" then error(name.." did not return a table") end
    return mod
end

-- === กำหนด URL ของแต่ละโมดูล (แนะนำใช้ลิงก์ raw ของ commit ที่ pin แล้ว) ===
local BASE = "https://raw.githubusercontent.com/UFO-HUB-X-Studio/UFO-HUB-X/refs/heads/main"
local URLs = {
    splash = BASE.."/splash.lua",
    key    = BASE.."/key.lua",
    ui     = BASE.."/core_ui.lua",
}

-- === โหลด splash ===
local Splash = loadModule("splash.lua", URLs.splash)
Splash.show{ logoId = 106029438403666, seconds = 1.2 } -- ปรับเวลาได้

-- === โหลดระบบคีย์ ===
local Key = loadModule("key.lua", URLs.key)
local ok, reason = Key.check{
    durationSec = 24*60*60,
    keySource = "remote",  -- "remote" = ตรวจกับลิสต์ใน key.lua / จะต่อ API ก็ได้
}
if not ok then
    -- ให้ key.lua แสดง UI ของมันเองจนกว่าจะผ่าน
    Key.prompt{
        getKeyLink   = "https://linkunlocker.com/ufo-hub-x-wKfUt",
        discordInvite= "https://discord.gg/JFHuVVVQ6D",
        onAccepted   = function() end, -- ผ่านแล้วจะปิด UI ภายใน key.lua เอง
    }
    repeat task.wait(0.1); ok = Key.isValid() until ok
end

-- === โหลด UI หลัก ===
local UI = loadModule("core_ui.lua", URLs.ui)
UI.start{
    title      = "UFO HUB X",
    logoId     = 106029438403666,
    accent     = Color3.fromRGB(22,247,123), -- เขียวเอเลี่ยน
    centerOpen = true,  -- เปิดทุกครั้งให้อยู่กลางเป๊ะ
    twoColumns = true,  -- แบ่ง 2 ซีก
}
