-- UFO HUB X — Key UI Launcher (minimal)
-- Purpose: Force-display the Key UI by fetching your official UI script.
-- Usage: run this with your executor (supports loadstring + HttpGet).

-- 1) Wait game is loaded (safer across executors)
pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)

-- 2) Safer HttpGet
local function SafeHttpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res then return res end
    -- fallback for some executors exposing http.request
    if http and http.request then
        local ok2, r2 = pcall(http.request, {Url=url, Method="GET"})
        if ok2 and r2 and (r2.Body or r2.body) then
            return (r2.Body or r2.body)
        end
    end
    error("HttpGet failed for: "..tostring(url))
end

-- 3) Key UI URL (official repo you shared)
local KEY_UI_URL = "https://raw.githubusercontent.com/UFO-HUB-X-Studio/UFO-HUB-X/refs/heads/main/UFO%20HUB%20X%20key.lua"

-- 4) Load & run Key UI
local src = SafeHttpGet(KEY_UI_URL)
local f = loadstring(src)
if type(f) == "function" then
    f()
else
    warn("[UFO] Failed to compile UI script")
end
