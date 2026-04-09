local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local supportedMaps = {
	[121864768012064] = "Fish it"
}

local success, info = pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local mapName = success and info.Name or "Unknown"
local isSupported = supportedMaps[game.PlaceId] ~= nil

local ExHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/zerotheking152-png/bug.lua/refs/heads/main/buggy.lua"))()

local Window = ExHub.Build({
	Title = "Quantum HUB",
	Subtitle = "Fish It 1.0",
	Theme = "Matrix Green"
})

-- ==================== INFO TAB ====================
local TabInfo = Window:AddTab("Info", "")
TabInfo:AddLabel("Selamat datang di Quantum HUB")
TabInfo:AddInfoBox([[Tips Penggunaan:
• Gunakan tombol minimize untuk sembunyikan UI.
• Klik tab di sidebar untuk ganti halaman.
• Semua pengaturan tersimpan otomatis.
• Jika error, lapor ke Discord resmi kami.]])
TabInfo:AddDiscordLink("https://discord.gg/5HGPUxrU")

-- ==================== REMOTE SYSTEM (CORE) ====================
local net = ReplicatedStorage:WaitForChild("Packages", 10):WaitForChild("_Index", 10):WaitForChild("sleitnick_net@0.2.0", 10):WaitForChild("net", 10)
local allRemotes = net:GetChildren()

local function GetServerRemote(targetName)
	local allRemotes = net:GetChildren()
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
		ok = pcall(function(...) remote:InvokeServer(...) end, ...)
	elseif remote:IsA("RemoteEvent") then
		ok = pcall(function(...) remote:FireServer(...) end, ...)
	else
		ok = pcall(function(...) remote:InvokeServer(...) end, ...)
		if not ok then
			ok = pcall(function(...) remote:FireServer(...) end, ...)
		end
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

-- ==================== AUTO FISHING (INSTANT) ====================
local Config = {
	completeDelay = 0,
	cycleDelay = 0.001
}

local Engine = {
	Running = false,
	Worker = nil
}

local function now() return workspace:GetServerTimeNow() end
local function safeCall(func) pcall(func) end

local function equipRod()
	CallRemoteServer(Events.equip, 1)
end

local function castRod()
	safeCall(function()
		CallRemoteServer(Events.charge)
		CallRemoteServer(Events.startFish, -0.001001001001, -1.1, os.clock())
	end)
end

local function completeCatch()
	safeCall(function()
		CallRemoteServer(Events.completeFish)
	end)
end

local function burstCompled(times)
	for i = 1, times do
		completeCatch()
		if i < times then task.wait(0.0005) end
	end
end

local function startEngine()
	if Engine.Worker then return end
	Engine.Worker = task.spawn(function()
		equipRod()
		task.wait(0.05)
		local cycle = 0
		while true do
			if Engine.Running then
				cycle = cycle + 1
				castRod()
				task.wait(Config.completeDelay)
				task.spawn(function()
					burstCompled(3)
				end)
				task.wait(Config.cycleDelay)
			else
				task.wait(0.1)
			end
		end
	end)
end

-- ==================== FISHING TAB ====================
local TabMain = Window:AddTab("Main", "")

TabMain:AddToggle("Auto Fishing", function(state)
	Engine.Running = state
	if state then startEngine() end
end)

TabMain:AddInput("Complete Delay", function(val)
	local n = tonumber(val)
	if n and n >= 0 and n <= 1 then Config.completeDelay = n end
end, "0")

TabMain:AddInput("Cycle Delay", function(val)
	local n = tonumber(val)
	if n and n >= 0 and n <= 1 then Config.cycleDelay = n end
end, "0.001")

-- ==================== TELEPORT TAB ====================
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

-- Player Teleport (dynamic list)
local playerOptions = {}
for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		table.insert(playerOptions, {Name = plr.Name, Player = plr})
	end
end
TabTp:AddDropdown("Teleport to Player", function(selected)
	if selected and selected.Player then
		TeleportExec(selected.Player)
	end
end, playerOptions)

-- Island Teleports
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
	{Name = "Treasure Room", Pos = Vector3.new(-3564, -279, -1607)}
}

local function TeleportToPos(pos)
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

local islandList = {}
for _, v in pairs(TP_POS_LIST) do
	table.insert(islandList, {Name = v.Name, Pos = v.Pos})
end

TabTp:AddDropdown("Teleport Pulau", function(selected)
	if selected and selected.Pos then
		TeleportToPos(selected.Pos)
	end
end, islandList)

-- ==================== CPU OPTIMIZE TAB ====================
local TabCpu = Window:AddTab("Optimize", "")

local DisableAnim = false
TabCpu:AddToggle("Disable Animation", function(state)
	DisableAnim = state
	local char = LocalPlayer.Character
	if not char then return end
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("Animator") or v:IsA("AnimationTrack") then
			v:Destroy()
		end
	end
end)

local DisableFX = false
TabCpu:AddToggle("Disable Effects", function(state)
	DisableFX = state
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

TabCpu:AddToggle("Low Graphics Mode", function(state)
	settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
end)

TabCpu:AddToggle("Remove Shadows", function(state)
	Lighting.GlobalShadows = not state
end)

TabCpu:AddButton("Clean Map (Lag Reduce)", function()
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("Accessory") or v:IsA("Hat") then
			v:Destroy()
		end
	end
end)

local AutoPerf = false
TabCpu:AddToggle("Auto Performance Mode", function(state)
	AutoPerf = state
	task.spawn(function()
		while AutoPerf do
			local fps = workspace:GetRealPhysicsFPS()
			settings().Rendering.QualityLevel = (fps < 40) and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
			task.wait(2)
		end
	end)
end)

local HidePlayers = false
TabCpu:AddToggle("Hide Other Players", function(state)
	HidePlayers = state
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

-- Persistent hide for new players
Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then
		plr.CharacterAdded:Connect(function(char)
			task.wait(1)
			if HidePlayers then
				for _, v in pairs(char:GetDescendants()) do
					if v:IsA("BasePart") then v.Transparency = 1 end
				end
			end
		end)
	end
end)

TabCpu:AddToggle("Low CPU Mode", function(state)
	if state then
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		Lighting.GlobalShadows = false
		workspace.StreamingEnabled = true
	else
		settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
		Lighting.GlobalShadows = true
	end
end)

local LimitFPS = false
TabCpu:AddToggle("Limit FPS (Save CPU)", function(state)
	LimitFPS = state
	setfpscap(state and 30 or 0)
end)

local UltraLow = false
TabCpu:AddToggle("ULTRA LOW MODE (BRUTAL)", function(state)
	UltraLow = state
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
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
				v:Destroy()
			elseif v:IsA("MeshPart") then
				v.TextureID = ""
				v.Material = Enum.Material.SmoothPlastic
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

local CleanMode = false
TabCpu:AddToggle("Auto Clean Lag", function(state)
	CleanMode = state
	task.spawn(function()
		while CleanMode do
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
					v:Destroy()
				end
			end
			task.wait(3)
		end
	end)
end)

TabCpu:AddToggle("Disable All Animations", function(state)
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character then
			for _, v in pairs(plr.Character:GetDescendants()) do
				if v:IsA("Animator") then v:Destroy() end
			end
		end
	end
end)

-- ==================== SERVER TAB ====================
local TabSettings = Window:AddTab("Server", "")

-- Anti AFK (fixed & persistent)
local AntiAFK = false
LocalPlayer.Idled:Connect(function()
	if AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end
end)

TabSettings:AddToggle("Anti AFK", function(state)
	AntiAFK = state
end)

local Freeze = false
TabSettings:AddToggle("Freeze", function(state)
	Freeze = state
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = state end
end)

TabSettings:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

local function getServers(desc)
	local servers = {}
	local cursor = ""
	repeat
		local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. (desc and "Desc" or "Asc") .. "&limit=100&cursor=" .. cursor
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

-- ==================== INTRO ====================
Window:PlayIntro({
	IsSupported = isSupported,
	MapName = isSupported and supportedMaps[game.PlaceId] or mapName
})
