--========================================================
-- UFO HUB X — KEY UI (Full, Compatible with Boot Loader)
--========================================================

local Players      = game:GetService("Players")
local CG           = game:GetService("CoreGui")
local TS           = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")

pcall(function() if not game:IsLoaded() then game.Loaded:Wait() end end)
local LP = Players.LocalPlayer

-- ป้องกัน Parent หาย
local function SOFT_PARENT(gui)
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(gui) end) end
    local ok = false
    if gethui then ok = pcall(function() gui.Parent = gethui() end) end
    if (not ok) or (not gui.Parent) then ok = pcall(function() gui.Parent = CG end) end
    if (not ok) or (not gui.Parent) then
        local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 2)
        if pg then pcall(function() gui.Parent = pg end) end
    end
end

-- Theme
local ACCENT = Color3.fromRGB(0,255,140)
local BG_DARK = Color3.fromRGB(10,10,10)
local SUB     = Color3.fromRGB(22,22,22)
local RED     = Color3.fromRGB(210,60,60)
local GREEN   = Color3.fromRGB(60,200,120)

-- Server
local SERVER_BASES = {
    "https://ufo-hub-x-key-umoq.onrender.com"
}
local DEFAULT_TTL = 48*3600

-- Allow keys
local ALLOW_KEYS = {
    ["JJJMAX"] = { reusable=true, ttl=DEFAULT_TTL },
    ["GMPANUPHONGARTPHAIRIN"] = { reusable=true, ttl=DEFAULT_TTL },
}

local function normKey(s)
    return tostring(s or ""):gsub("%c",""):gsub("%s+",""):gsub("[^%w]",""):upper()
end

-- HTTP
local function http_get(url)
    if syn and syn.request then
        local ok,res = pcall(syn.request,{Url=url,Method="GET"})
        if ok and res and (res.Body or res.body) then return true,(res.Body or res.body) end
    end
    local ok,body = pcall(function() return game:HttpGet(url) end)
    if ok and body then return true,body end
    return false,nil
end

local function http_json_get(url)
    local ok,body = http_get(url)
    if not ok then return false,nil end
    local ok2,data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 then return false,nil end
    return true,data
end

local function verifyWithServer(k)
    local uid   = tostring(LP.UserId or "")
    local place = tostring(game.PlaceId or "")
    local qs = string.format("/verify?key=%s&uid=%s&place=%s",
        HttpService:UrlEncode(k), HttpService:UrlEncode(uid), HttpService:UrlEncode(place))
    for _,base in ipairs(SERVER_BASES) do
        local ok,data = http_json_get(base..qs)
        if ok and data and data.ok and data.valid then
            return true,data.expires_at or (os.time()+DEFAULT_TTL)
        end
    end
    return false,nil
end

-- UI utils
local function make(class, props, kids)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent=o end
    return o
end

-- สร้าง GUI
local gui = Instance.new("ScreenGui")
gui.Name="UFOHubX_KeyUI"
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SOFT_PARENT(gui)

local panel = make("Frame",{
    Parent=gui, Active=true, Draggable=true,
    Size=UDim2.fromOffset(600,300),
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    BackgroundColor3=BG_DARK
},{
    make("UICorner",{CornerRadius=UDim.new(0,20)})
})

local keyBox = make("TextBox",{
    Parent=panel, PlaceholderText="ใส่ Key ที่นี่",
    Size=UDim2.new(1,-40,0,40), Position=UDim2.new(0,20,0,100),
    BackgroundColor3=SUB, TextColor3=Color3.new(1,1,1), TextSize=18
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)})
})

local statusLabel = make("TextLabel",{
    Parent=panel, BackgroundTransparency=1,
    Size=UDim2.new(1,-40,0,24), Position=UDim2.new(0,20,0,150),
    Text="", TextColor3=Color3.new(1,1,1)
})

local btnSubmit = make("TextButton",{
    Parent=panel, Text="🔒 Submit Key",
    Size=UDim2.new(1,-40,0,40), Position=UDim2.new(0,20,0,190),
    BackgroundColor3=RED, TextColor3=Color3.new(1,1,1), TextSize=18
},{
    make("UICorner",{CornerRadius=UDim.new(0,12)})
})

-- Flow
local submitting=false
local function doSubmit()
    if submitting then return end
    submitting=true
    local k = normKey(keyBox.Text)
    if k=="" then statusLabel.Text="⚠️ โปรดใส่คีย์"; submitting=false; return end

    local meta = ALLOW_KEYS[k]
    local valid,exp = false,nil
    if meta then
        valid=true; exp=os.time()+(meta.ttl or DEFAULT_TTL)
    else
        valid,exp = verifyWithServer(k)
    end

    if not valid then
        statusLabel.Text="❌ คีย์ไม่ถูกต้อง"
        submitting=false
        return
    end

    statusLabel.Text="✅ Key Accepted!"
    _G.UFO_HUBX_KEY_OK = true
    _G.UFO_HUBX_KEY    = k
    if _G.UFO_SaveKeyState then pcall(_G.UFO_SaveKeyState,k,exp,false) end
    if _G.UFO_StartDownload then pcall(_G.UFO_StartDownload) end

    task.delay(0.3,function() if gui then gui:Destroy() end end)
end
btnSubmit.MouseButton1Click:Connect(doSubmit)

print("[UFO-HUB-X] Key UI Loaded.")
