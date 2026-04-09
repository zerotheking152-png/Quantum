local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local supportedMaps = {
    [121864768012064] = "Fish it"
}

local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local mapName = success and info.Name or "Unknown"
local isSupported = supportedMaps[game.PlaceId] ~= nil

local ExHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/zerotheking152-png/bug.lua/main/buggy.lua"))()

local Window = ExHub.Build({
    Title = "Quantum HUB",
    Subtitle = "Fish It 1.0",
    Theme = "Matrix Green"
})

-- Tab Info
local TabInfo = Window:AddTab("Info", "")
TabInfo:AddLabel("Selamat datang Di Quantum HUB")
TabInfo:AddInfoBox([[
Tips Penggunaan :
• Gunakan tombol minimize untuk menyembunyikan UI.
• Klik tab di sidebar untuk berpindah halaman.
• Semua pengaturan tersimpan otomatis.
• Error? Report ke Discord resmi kami.
]])
TabInfo:AddDiscordLink("https://discord.gg/ez2tVr6a")

-- Remote Setup
local net = ReplicatedStorage:WaitForChild("Packages", 10):WaitForChild("_Index", 10):WaitForChild("sleitnick_net@0.2.0", 10):WaitForChild("net", 10)
local allRemotes = net:GetChildren()

local function GetServerRemote(targetName)
    for i, remote in ipairs(allRemotes) do
        if remote.Name == targetName then
            return allRemotes[i + 1]
        end
    end
    return nil
end

local function CallRemoteServer(remote, ...)
    if not remote then return false end
    local ok
    if remote:IsA("RemoteFunction") then
        ok = pcall(remote.InvokeServer, remote, ...)
    elseif remote:IsA("RemoteEvent") then
        ok = pcall(remote.FireServer, remote, ...)
    else
        ok = pcall(remote.InvokeServer, remote, ...)
        if not ok then ok = pcall(remote.FireServer, remote, ...) end
    end
    return ok
end

local remoteTargets = {
    equip = "RE/EquipToolFromHotbar",
    unequip = "RE/UnequipToolFromHotbar",
    equipItem = "RE/EquipItem",
    CancelFishingInputs = "RF/CancelFishingInputs",
    charge = "RF/ChargeFishingRod",
    startFish = "RF/RequestFishingMinigameStarted",
    completeFish = "RE/CatchFishCompleted"
}

local Events = {}
local missingRemotes = {}

for key, targetName in pairs(remoteTargets) do
    local remote = GetServerRemote(targetName)
    if remote then
        Events[key] = remote
    else
        table.insert(missingRemotes, key)
    end
end

if #missingRemotes > 0 then
    warn("Remote berikut TIDAK ditemukan:", table.concat(missingRemotes, ", "))
    print("Script tidak akan berjalan.")
    return
end

-- Improved Auto Fishing
local Config = {
    completeDelay = 0.008,
    cycleDelay = 0.015,
    jitter = true
}

local Engine = { Running = false, Worker = nil }

local function now() return workspace:GetServerTimeNow() end

local function safeCall(func)
    local success, err = pcall(func)
    if not success then warn("Error:", err) end
end

local function equipRod()
    CallRemoteServer(Events.equip, 1)
end

local function castRod()
    safeCall(function()
        CallRemoteServer(Events.charge)
        CallRemoteServer(Events.startFish, -001.001001001001, -1.1, os.clock())
    end)
end

local function completeCatch()
    safeCall(function()
        CallRemoteServer(Events.completeFish)
    end)
end

local function burstComplete(times)
    for i = 1, times do
        completeCatch()
        if i < times then task.wait(0.0005) end
    end
end

local function startEngine()
    if Engine.Worker then return end
    Engine.Worker = task.spawn(function()
        equipRod()
        task.wait(0.08)
        
        local cycle = 0
        while true do
            if Engine.Running then
                cycle = cycle + 1
                castRod()
                
                task.wait(Config.completeDelay)
                
                -- Burst complete dengan jitter anti-detect
                local burstCount = Config.jitter and math.random(2, 3) or 2
                task.spawn(burstComplete, burstCount)
                
                if Config.jitter then
                    task.wait(Config.cycleDelay + (math.random(-3, 3) / 1000))
                else
                    task.wait(Config.cycleDelay)
                end
            else
                task.wait(0.1)
            end
        end
    end)
end

-- Tab Main
local TabMain = Window:AddTab("Main", "")

TabMain:AddToggle("Auto Fishing", function(state)
    Engine.Running = state
    if state and not Engine.Worker then
        startEngine()
    end
end)

TabMain:AddInput("Complete Delay", function(val)
    local n = tonumber(val)
    if n and n >= 0.001 and n <= 0.5 then
        Config.completeDelay = n
    end
end, "0.008")

TabMain:AddInput("Cycle Delay", function(val)
    local n = tonumber(val)
    if n and n >= 0.005 and n <= 0.1 then
        Config.cycleDelay = n
    end
end, "0.015")

TabMain:AddToggle("Anti Detect Jitter", function(state)
    Config.jitter = state
end, true)

-- Tab Teleport
local TabTp = Window:AddTab("Teleport", "")

local function TeleportExec(targetPos)
    local tp = type(targetPos) == "table" and targetPos.Pos or targetPos
    if typeof(tp) == "Instance" and tp:IsA("Player") then
        local char = tp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then tp = hrp.Position else return end
    end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHRP and tp then
        myHRP.CFrame = CFrame.new(tp + Vector3.new(0, 3, 0))
    end
end

local TP_POS_LIST = {
    {Name = "Crater Island", Pos = Vector3.new(1025, 3, 5012)},
    {Name = "Planetary Observatory", Pos = Vector3.new(343, 4, 2092)},
    {Name = "Ocean", Pos = Vector3.new(-1497, 3, 1914)},
    {Name = "Sisphus Statue", Pos = Vector3.new(-3736, -135, -1011)},
    {Name = "Coral Reefs", Pos = Vector3.new(-3273, 2, 2232)},
    {Name = "Esoteric Depths", Pos = Vector3.new(3265, -1302, 1372)},
    {Name = "Kohana", Pos = Vector3.new(-652, 17, 451)},
    {Name = "Kohano Volcano", Pos = Vector3.new(-541, 19, 171)},
    {Name = "Sacred Temple", Pos = Vector3.new(1478, -22, -660)},
    {Name = "Ancient Jungle", Pos = Vector3.new(1470, 4, -319)},
    {Name = "Easter Island", Pos = Vector3.new(1131, 5, 2743)},
    {Name = "Tropical Grove", Pos = Vector3.new(-2158, 53, 3669)},
    {Name = "Treasure Room", Pos = Vector3.new(-3564, -279, -1607)},
}

TabTp:AddDropdown("Teleport ke Player", function(selected)
    TeleportExec(selected)
end, {})

local function TeleportToPos(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

TabTp:AddDropdown("Teleport Pulau", function(selected)
    TeleportToPos(selected.Pos)
end, (function()
    local list = {}
    for _, v in pairs(TP_POS_LIST) do
        table.insert(list, {Name = v.Name, Pos = v.Pos})
    end
    return list
end)())

-- Tab Optimize
local TabCpu = Window:AddTab("Optimize", "")

TabCpu:AddToggle("Disable Animation", function(state)
    for _, v in pairs(LocalPlayer.Character and LocalPlayer.Character:GetDescendants() or {}) do
        if v:IsA("Animator") or v:IsA("AnimationTrack") then
            v:Destroy()
        end
    end
end)

TabCpu:AddToggle("Disable Effects", function(state)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Explosion") or v:IsA("Fire") or v:IsA("Smoke") then
            v:Destroy()
        end
    end
end)

TabCpu:AddToggle("FPS Boost", function(state)
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.CastShadow = false
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 1
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

TabCpu:AddToggle("Low Graphics", function(state)
    settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
end)

TabCpu:AddToggle("Remove Shadows", function(state)
    Lighting.GlobalShadows = not state
end)

TabCpu:AddButton("Clean Map", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Accessory") or v:IsA("Hat") then
            v:Destroy()
        end
    end
end)

TabCpu:AddToggle("Auto Performance", function(state)
    task.spawn(function()
        while state do
            local fps = workspace:GetRealPhysicsFPS()
            settings().Rendering.QualityLevel = (fps < 40) and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            task.wait(2)
        end
    end)
end)

TabCpu:AddToggle("Hide Other Players", function(state)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _, v in pairs(plr.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Transparency = state and 1 or 0
                end
            end
        end
    end
end)

TabCpu:AddToggle("Low CPU Mode", function(state)
    settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    Lighting.GlobalShadows = not state
    workspace.StreamingEnabled = state
end)

TabCpu:AddToggle("Limit FPS", function(state)
    setfpscap(state and 30 or 0)
end)

TabCpu:AddToggle("ULTRA LOW MODE", function(state)
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.Transparency = 0
                for _, d in pairs(v:GetChildren()) do
                    if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
                end
            elseif v:IsA("MeshPart") then
                v.TextureID = ""
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                v:Destroy()
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 0
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v:Destroy() end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end)

TabCpu:AddToggle("Auto Clean Lag", function(state)
    task.spawn(function()
        while state do
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                    v:Destroy()
                end
            end
            task.wait(3)
        end
    end)
end)

-- Tab Server
local TabSettings = Window:AddTab("Server", "")

local AntiAFKConn
TabSettings:AddToggle("Anti AFK", function(state)
    if state then
        if not AntiAFKConn then
            AntiAFKConn = LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    else
        if AntiAFKConn then
            AntiAFKConn:Disconnect()
            AntiAFKConn = nil
        end
    end
end)

TabSettings:AddToggle("Freeze Character", function(state)
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = state end
    end
end)

TabSettings:AddButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

local function getServers(desc)
    local servers = {}
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder="..(desc and "Desc" or "Asc").."&limit=100&cursor="..cursor
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, v in pairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v)
            end
        end
        cursor = data.nextPageCursor or ""
    until cursor == ""
    return servers
end

TabSettings:AddButton("Cari Server Sepi", function()
    local servers = getServers(false)
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    end
end)

TabSettings:AddButton("Cari Server Ramai", function()
    local servers = getServers(true)
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    end
end)

-- Intro
Window:PlayIntro({
    IsSupported = isSupported,
    MapName = isSupported and supportedMaps[game.PlaceId] or mapName
})
