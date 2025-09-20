--========================================================
-- UFO HUB X — Key Expiry Watcher (ADD-ONLY module)
-- Purpose:
--   - Monitor key expiry time.
--   - When expired, clear flags/state and re-open the Key UI for re-auth.
--   - Non-destructive: does NOT modify or remove existing code; only uses globals/APIs if present.
--========================================================
local HttpService = game:GetService("HttpService")

local log = function(...) print("[UFO-EXPIRY]", ...) end

-- ============= Config via getgenv() (optional) =============
local POLL_SEC    = (getgenv and tonumber(getgenv().UFO_EXPIRY_POLL_SEC)) or 5     -- how frequently to check
local GRACE_SEC   = (getgenv and tonumber(getgenv().UFO_KEY_RENEW_GRACE)) or 0     -- seconds before expiry to trigger renew UI
local STATE_DIR   = (getgenv and getgenv().UFO_STATE_DIR) or "UFOHubX"             -- fallback state path
local STATE_FILE  = (getgenv and getgenv().UFO_STATE_FILE) or (STATE_DIR.."/key_state.json")

-- ============= Helpers for optional FS persistence =========
local function _ensureDir()
    if isfolder then
        if not isfolder(STATE_DIR) then pcall(makefolder, STATE_DIR) end
    end
end
_ensureDir()

local function _readState()
    if not (isfile and readfile and isfile(STATE_FILE)) then return nil end
    local ok, data = pcall(readfile, STATE_FILE)
    if not ok or not data or #data==0 then return nil end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if ok2 then return decoded end
    return nil
end

local function _writeState(tbl)
    if not (writefile and HttpService and tbl) then return end
    local ok, json = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok then pcall(writefile, STATE_FILE, json) end
end

local function _deleteState()
    if isfile and isfile(STATE_FILE) and delfile then pcall(delfile, STATE_FILE) end
end

-- ============= Expiry Resolution ===========================
local function _now() return os.time() end

local function _getSavedKey()
    -- Try multiple sources without modifying them
    if _G and _G.UFO_Key then return _G.UFO_Key end
    if _G and _G.UFO_HUBX_KEY then return _G.UFO_HUBX_KEY end
    if _G and _G.UFO and _G.UFO.state and _G.UFO.state.saved_key then return _G.UFO.state.saved_key end
    local st = _readState()
    if st and st.key then return st.key end
    return nil
end

local function _getExpiresAt()
    -- Prefer explicit globals if present
    if _G and _G.UFO_KeyExpiresAt and tonumber(_G.UFO_KeyExpiresAt) then return tonumber(_G.UFO_KeyExpiresAt) end
    if _G and _G.UFO and _G.UFO.state and tonumber(_G.UFO.state.expires_at) then return tonumber(_G.UFO.state.expires_at) end
    -- Fallback to state file
    local st = _readState()
    if st and tonumber(st.expires_at) then return tonumber(st.expires_at) end
    return nil
end

local function _isPermanent()
    if _G and _G.UFO_HUBX_KEY_PERM == true then return true end
    local st = _readState()
    if st and st.permanent==true then return true end
    return false
end

-- ============= Re-open Key UI on Expiry ====================
local function _openKeyUI()
    -- Use public APIs if available; otherwise fallback to URL loader
    if _G and _G.UFO and type(_G.UFO.ShowKeyUI)=="function" then
        return _G.UFO.ShowKeyUI()
    end
    if type(_G.UFO_RequestOpenKeyUI)=="function" then
        return _G.UFO_RequestOpenKeyUI()
    end
    local url = rawget(_G, "UFO_KEY_UI_URL")
    if type(url)=="string" and #url>0 then
        local ok, body
        if http and http.request then
            local resOk, res = pcall(http.request, {Url=url, Method="GET"})
            if resOk and res and (res.Body or res.body) then ok, body = true, (res.Body or res.body) end
        end
        if (not ok) and syn and syn.request then
            local resOk, res = pcall(syn.request, {Url=url, Method="GET"})
            if resOk and res and (res.Body or res.body) then ok, body = true, (res.Body or res.body) end
        end
        if (not ok) then
            local got, b = pcall(function() return game:HttpGet(url) end)
            if got and b then ok, body = true, b end
        end
        if ok and body then
            local f, e = loadstring(body, "UFO_Key_Compat")
            if f then pcall(f) else warn("[UFO-EXPIRY] load compat failed:", e) end
        else
            warn("[UFO-EXPIRY] fetch compat failed, set _G.UFO_KEY_UI_URL properly")
        end
    else
        warn("[UFO-EXPIRY] No way to open Key UI (set _G.UFO_KEY_UI_URL or provide UFO.ShowKeyUI)")
    end
end

local function _clearFlags()
    if _G then
        _G.UFO_HUBX_KEY_OK = false
        _G.UFO_KEY_OK      = false
        _G.UFOX_KEY_OK     = false
        -- don't nuke saved key text; only mark invalid
        _G.UFO_KeyExpiresAt = nil
    end
end

local _RUN = true
local function _loop()
    while _RUN do
        task.wait(POLL_SEC)
        if _isPermanent() then
            -- Permanent key: nothing to do
            goto continue
        end
        local exp = _getExpiresAt()
        if exp and type(exp)=="number" then
            local now = _now()
            local threshold = exp - (GRACE_SEC or 0)
            if now >= threshold then
                log("Key expired (or in grace) → re-open Key UI")
                -- Broadcast "expired" event if present
                if _G and _G.UFO_KeyEvent and _G.UFO_KeyEvent.Fire then
                    pcall(function() _G.UFO_KeyEvent:Fire("expired", _getSavedKey(), exp) end)
                end
                _clearFlags()
                -- Delete state file to force re-auth
                _deleteState()
                -- Ensure UI appears
                _G.UFO_ForceKeyUI = true
                task.defer(_openKeyUI)
            end
        end
        ::continue::
    end
end

-- ============= Public Controls ============================
_G.UFO_StartExpiryWatcher = _G.UFO_StartExpiryWatcher or function()
    if _G.__UFO_EXPIRY_ACTIVE then return end
    _G.__UFO_EXPIRY_ACTIVE = true
    _RUN = true
    task.spawn(_loop)
    log(("started (poll=%ss, grace=%ss)"):format(tostring(POLL_SEC), tostring(GRACE_SEC)))
end

_G.UFO_StopExpiryWatcher = _G.UFO_StopExpiryWatcher or function()
    _RUN = false
    _G.__UFO_EXPIRY_ACTIVE = false
    log("stopped")
end

-- Auto-start by default (can be disabled by setting getgenv().UFO_DISABLE_EXPIRY_WATCHER=true before load)
if not (getgenv and getgenv().UFO_DISABLE_EXPIRY_WATCHER) then
    _G.UFO_StartExpiryWatcher()
end
--========================================================
