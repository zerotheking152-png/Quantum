local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local supportedMaps = {[121864768012064] = "Fish it"}
local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
local mapName = success and info.Name or "Unknown"
local isSupported = supportedMaps[game.PlaceId] ~= nil

local ExHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/zerotheking152-png/bug.lua/main/buggy.lua"))()
local Window = ExHub.Build({Title = "Quantum HUB", Subtitle = "Fish It 1.0", Theme = "Matrix Green"})

local net = ReplicatedStorage:WaitForChild("Packages", 10):WaitForChild("_Index", 10):WaitForChild("sleitnick_net@0.2.0", 10):WaitForChild("net", 10)

local function GetServerRemote(targetName)
    for _, remote in ipairs(net:GetChildren()) do
        if remote.Name == targetName then
            for i = 1, #net:GetChildren() do
                local candidate = net:GetChildren()[i]
                if candidate:IsA("RemoteEvent") or candidate:IsA("RemoteFunction") then
                    return candidate
                end
            end
        end
    end
    return nil
end

local remoteTargets = {
    equip = "RE/EquipToolFromHotbar",
    charge = "RF/ChargeFishingRod",
    startFish = "RF/RequestFishingMinigameStarted",
    completeFish = "RE/CatchFishCompleted"
}

local Events = {}
local missing = {}
for key, name in pairs(remoteTargets) do
    local remote = GetServerRemote(name)
    if remote then
        Events[key] = remote
    else
        table.insert(missing, key)
    end
end

if #missing > 0 then
    warn("❌ Remote tidak ditemukan:", table.concat(missing, ", "))
    return
end

local Config = {
    completeDelay = 0.02,
    cycleDelay = 0.05,
    burstCount = 2
}

local Engine = {Running = false, Worker = nil}

local function CallRemote(remote, ...)
    if not remote then return false end
    local ok = pcall(function(...) 
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        else
            remote:FireServer(...)
        end
    end, ...)
    return ok
end

local function equipRod()
    CallRemote(Events.equip, 1)
end

local function castRod()
    CallRemote(Events.charge)
    CallRemote(Events.startFish, -001.001001001001, -1.1, os.clock())
end

local function completeCatch()
    CallRemote(Events.completeFish)
end

local function burstComplete()
    for i = 1, Config.burstCount do
        completeCatch()
        if i < Config.burstCount then task.wait(0.001) end
    end
end

local function startEngine()
    if Engine.Worker then return end
    Engine.Worker = task.spawn(function()
        equipRod()
        task.wait(0.1)
        while true do
            if Engine.Running then
                castRod()
                task.wait(Config.completeDelay)
                burstComplete()
                task.wait(Config.cycleDelay)
            else
                task.wait(0.1)
            end
        end
    end)
end

local TabInfo = Window:AddTab("Info","")
TabInfo:AddLabel("Selamat datang di Quantum HUB")
TabInfo:AddInfoBox([[
Tips:
• Minimize untuk sembunyikan UI
• Semua setting tersimpan otomatis
• Report bug ke Discord jika error
]])
TabInfo:AddDiscordLink("https://discord.gg/ez2tVr6a")

local TabMain = Window:AddTab("Main", "")

TabMain:AddToggle("Auto Fishing", function(state)
    Engine.Running = state
    if state and not Engine.Worker then
        startEngine()
    end
end)

TabMain:AddInput("Complete Delay", function(val)
    local n = tonumber(val)
    if n and n >= 0.001 and n <= 1 then Config.completeDelay = n end
end, "0.02")

TabMain:AddInput("Cycle Delay", function(val)
    local n = tonumber(val)
    if n and n >= 0.001 and n <= 1 then Config.cycleDelay = n end
end, "0.05")

TabMain:AddInput("Burst Count", function(val)
    local n = tonumber(val)
    if n and n >= 1 and n <= 10 then Config.burstCount = math.floor(n) end
end, "2")

local TabTp = Window:AddTab("Teleport","")

local function TeleportTo(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and pos then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, {Name = plr.Name, Pos = plr})
        end
    end
    return list
end

local playerDropdown = TabTp:AddDropdown("Teleport to Player", function(selected)
    if selected and selected.Pos then
        local char = selected.Pos.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then TeleportTo(hrp.Position) end
    end
end, getPlayerList())

TabTp:AddButton("Refresh Player List", function()
    playerDropdown:Refresh(getPlayerList())
end)

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

local islandList = {}
for _, v in ipairs(TP_POS_LIST) do
    table.insert(islandList, {Name = v.Name, Pos = v.Pos})
end

TabTp:AddDropdown("Teleport Pulau", function(selected)
    if selected and selected.Pos then TeleportTo(selected.Pos) end
end, islandList)

local TabCpu = Window:AddTab("Performance", "")

TabCpu:AddToggle("Disable Animation", function(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("Animator") or v:IsA("AnimationTrack") then v:Destroy() end
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
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

TabCpu:AddToggle("Low Graphics Mode", function(state)
    settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
end)

TabCpu:AddToggle("Remove Shadows", function(state)
    Lighting.GlobalShadows = not state
end)

TabCpu:AddToggle("Hide Other Players", function(state)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = state and 1 or 0
                end
            end
        end
    end
end)

TabCpu:AddToggle("Limit FPS (30)", function(state)
    setfpscap(state and 30 or 0)
end)

TabCpu:AddToggle("ULTRA LOW MODE", function(state)
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                for _, d in pairs(v:GetChildren()) do
                    if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
                end
            elseif v:IsA("MeshPart") then
                v.TextureID = ""
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v:Destroy()
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end)

TabCpu:AddButton("Clean Map (Lag Reduce)", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
    end
end)

local TabServer = Window:AddTab("Server", "")

TabServer:AddToggle("Anti AFK", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
        end)
    end
end)

TabServer:AddToggle("Freeze Character", function(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = state end
end)

TabServer:AddButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

TabServer:AddButton("Cari Server Sepi", function()
    local cursor, servers = "", {}
    repeat
        local data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100&cursor="..cursor))
        for _, v in ipairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v)
            end
        end
        cursor = data.nextPageCursor or ""
    until cursor == ""
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    end
end)

TabServer:AddButton("Cari Server Ramai", function()
    local cursor, servers = "", {}
    repeat
        local data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100&cursor="..cursor))
        for _, v in ipairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v)
            end
        end
        cursor = data.nextPageCursor or ""
    until cursor == ""
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    end
end)

Window:PlayIntro({
    IsSupported = isSupported,
    MapName = isSupported and supportedMaps[game.PlaceId] or mapName
})
