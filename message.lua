-- [[ Prevent some bugs ]]
repeat task.wait() until game:IsLoaded()
task.wait(0.1)

-- [[ Luraph ENV ]]
if not LPH_OBFUSCATED then
    LPH_NO_VIRTUALIZE = function(...) return ... end
    LPH_NO_UPVALUES = function(...) return ... end
    LPH_JIT_MAX = function(...) return ... end
    LPH_JIT = function(...) return ... end
    LPH_ENCSTR = function(...) return ... end
    LPH_ENCNUM = function(...) return ... end
end

-- [[ Secure current script ]]
for i = 0, 1 do
    local this = getfenv(i).script
    if not this then -- Executor issue
        clonefunction(cloneref(game.Players.LocalPlayer).Kick)(game.Players.LocalPlayer, 'Executor Issue')
        wait(1)
        while true do debug.traceback() end
    end

    this.Name = ''
    this.Parent = nil
end

-- [[ Add missing executor's ENVs ]]
getgenv().isnetworkowner = isnetworkowner or function(part) return part.ReceiveAge == 0 end
getgenv().cloneref = cloneref or (function()
    loadstring("local a=Instance.new('Part')for b,c in pairs(getreg())do if type(c)=='table'and#c then if rawget(c,'__mode')=='kvs'then for d,e in pairs(c)do if e==a then getgenv().InstanceList=c;break end end end end end;local f={}function f.invalidate(g)if not InstanceList then return end;for b,c in pairs(InstanceList)do if c==g then InstanceList[b]=nil;return g end end end;if not cloneref then getgenv().cloneref=f.invalidate end")()
    return getgenv().cloneref
end)()
getgenv().clonefunction = clonefunction or newcclosure(function(...) return newcclosure(...) end)
getgenv().request = (request or http_request) or newcclosure(function(tbl)
    return warn('Bad executor')
end)
getgenv().log = function(...)
    if LPH_OBFUSCATED then return end
    return print('[DEBUG]', ...)
end

-- [[ Custom Local ENVs ]]
PLACE_ID = game.PlaceId
JOB_ID = game.JobId

-- [[ Services ]]
local getService = setmetatable({}, {
    __index = function()
        while true do end
    end,
    __newindex = function()
        while true do end
    end,
    __tostring = function()
        while true do end
    end,
    __call = function(self, serviceName)
        return cloneref(game.GetService(game, '' .. serviceName))
    end
})

local coreGui = cloneref(game.CoreGui)
local workspace = getService('Workspace')
local playerService = getService('Players')
local replicatedStorage = getService('ReplicatedStorage')
local httpService = getService('HttpService')
local teleportService = getService('TeleportService')
local virtualInputManager = getService('VirtualInputManager')
local virtualUser = getService('VirtualUser')
local runService = getService('RunService')
local guiService = getService('GuiService')

-- [[ Folders ]]
local playerCharacters = workspace:WaitForChild('PlayerCharacters')
local chest = replicatedStorage:WaitForChild('Chest')
local remotes = chest:WaitForChild('Remotes')
local modules = chest:WaitForChild('Modules')
local allNpc = workspace:WaitForChild('AllNPC')
local npcs = replicatedStorage:WaitForChild('NPC')
local monster = workspace:WaitForChild('Monster')
local boss = monster:WaitForChild('Boss')
local mon = monster:WaitForChild('Mon')
local mob = replicatedStorage:WaitForChild('MOB')
local seaMonster = workspace:WaitForChild('SeaMonster')
local ghostMonster = workspace:WaitForChild('GhostMonster')
local islands = workspace:WaitForChild('Island')

-- [[ Remotes ]]
local getServers = remotes.Functions.GetServers

-- [[ Modules ]]

-- [[ Varibles ]]
local config = getgenv().config
local player = getService('Players').LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local playerScripts = player:WaitForChild('PlayerScripts')
local playerStats = nil
local _ENV = nil

local lastTeleport = nil
local character = nil
local seaEvent = nil
local oldMaterial = nil

-- [[ Status UI ]]
local function createStatusUI()
    -- World IDs
    local WorldsId = require(replicatedStorage.Chest.Modules.WorldsId)

    -- Define valid worlds for each sea
    local SecondSeaIds = {
        [WorldsId.Testing.SecondSea] = true,
        [WorldsId.KingLegacy.SecondSea] = true
    }

    local ThirdSeaIds = {
        [WorldsId.Testing.ThirdSea] = true,
        [WorldsId.KingLegacy.ThirdSea] = true
    }

    if SecondSeaIds[game.PlaceId] then
        replicatedStorage.Chest.Remotes.Bindables.ClientBeckUI:Fire("LegacyPoseFrame", {
            Sea = "SecondSea",
            VisibleType = true
        })
    elseif ThirdSeaIds[game.PlaceId] then
        replicatedStorage.Chest.Remotes.Bindables.ClientBeckUI:Fire("LegacyPoseFrame", {
            Sea = "ThirdSea",
            VisibleType = true
        })
    else
        replicatedStorage.Chest.Remotes.Bindables.ClientBeckUI:Fire("LegacyPoseFrame", {
            Sea = "Unknown",
            VisibleType = true
        })
    end
end

-- [[ Character Functions ]]
local char = LPH_NO_VIRTUALIZE(function()
    repeat
        task.wait()
        if not player.Character then continue end
        if not player.Character:IsDescendantOf(playerCharacters) then continue end
        if not player.Character:FindFirstChild('HumanoidRootPart') then continue end
        if not player.Character:FindFirstChild('Humanoid') then continue end
        if player.Character.Humanoid.Health <= 0 then continue end
        if player.Character:GetAttribute('SpawnSuccess') == false then continue end
        
        return player.Character
    until false
end)

local characterFunctions = {}
characterFunctions.__index = characterFunctions

function characterFunctions.New()
    log('Creating character functions')
    local self = setmetatable({
        cache = {}
    }, characterFunctions)
    log('Created character functions')
    return self
end

function characterFunctions:getDistance(goal)
    if type(goal) ~= 'vector' then
        goal = goal.Position
    end

    return math.round((char().HumanoidRootPart.Position - goal).Magnitude)
end

function characterFunctions:resetCharacter()
    char().Humanoid.Health = 0
end

function characterFunctions:getBackpack()
    return player.Backpack:GetChildren()
end

function characterFunctions:equipTool(...)
    local hasName = config.weaponName
	if hasName and not player.Backpack:FindFirstChild(hasName) and not char():FindFirstChild(hasName) then
		replicatedStorage.Chest.Remotes.Functions.InventoryEq:InvokeServer(hasName)
	end

	task.wait(0.25)
	for i, v in next, player.Backpack:GetChildren() do
        if v.ToolTip == 'Sword' then
            char().Humanoid:EquipTool(v)
            break
        end
	end
end

function characterFunctions:teleportTo(goal)
    if type(goal) == 'vector' then
        goal = CFrame.new(goal)
    end

    char().HumanoidRootPart.CFrame = goal
    lastTeleport = goal
end

function characterFunctions:click()
    virtualInputManager:SendKeyEvent(true, Enum.KeyCode.ButtonR2, false, game)
	task.wait(0)
	virtualInputManager:SendKeyEvent(false, Enum.KeyCode.ButtonR2, false, game)
end

function characterFunctions:disableCollide()
    for _, part in next, char():GetDescendants() do
        if part:IsA('BasePart') then
            part.CanCollide = false
        end
    end
end

function characterFunctions:freeze()
    char().Humanoid.Sit = false
    if char().HumanoidRootPart:FindFirstChild('jacky') ~= nil then return end
    
    char().HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    local bv = Instance.new('BodyVelocity')
    bv.Parent = char().HumanoidRootPart
    bv.Name = 'jacky'
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)

    return bv
end

function characterFunctions:buso()
    if char().Services.Haki.Value <= 0 then
        remotes.Events.Armament:FireServer()
    end
end

function characterFunctions:useSkills(pos)
    if type(pos) == 'vector' then pos = CFrame.new(pos) end
    for buttonName, data in next, config.skills do
        if data.Enable ~= true then continue end
        self:pressButton(buttonName, data.Hold)
    end
end

function characterFunctions:pressButton(buttonName)
    virtualInputManager:SendKeyEvent(true, buttonName, false, game)
    task.wait(0)
    virtualInputManager:SendKeyEvent(false, buttonName, false, game)
end

function characterFunctions:teleportToSafePlace()
    -- [[ Avoi someone report to admins ]]
    self:teleportTo(char().HumanoidRootPart.CFrame * CFrame.new(0, 10000, 0))
end

-- [[ User Module ]]
local UserModule = {}
UserModule.__index = UserModule

function UserModule.__new()
    local self = setmetatable({}, UserModule)
    self.character = characterFunctions.New()
    return self
end

function UserModule:__init()
    if config == nil then
        player.Kick(player, 'Please input a config file!')
        return
    end

     -- [[ Ultra boost ]]
    loadstring([[
        if _G.lag then return end
        if not LPH_OBFUSCATED then
            LPH_NO_VIRTUALIZE = function(...) return ... end
            LPH_JIT_MAX = function(...) return ... end
        end

        -- Services and global variables
        local RunService = game:GetService("RunService")
        local whiteScreen = _G.whiteScreen or false
        local mode = _G.Mode or true
        local fps = _G.fps or 30
        local isSave = false

        local Player = game.Players.LocalPlayer

        local workspace = game.Workspace
        local Lighting = game.Lighting
        local ReplicatedStorage = game.ReplicatedStorage
        local ReplicatedFirst = game.ReplicatedFirst
        local PlayerScripts = Player.PlayerScripts
        local Character = Player.Character
        local Backpack = Player.Backpack
        local PlayerGui = Player.PlayerGui

        local to_check = {
            workspace,
            Lighting,
            ReplicatedStorage,
            ReplicatedFirst,
            PlayerScripts,
            Character,
            Backpack,
        }

        -- Utility function to disable various effects
        local function check(v)
            if string.find(v.Name, 'Effect') then v.Enabled = false end
            if v:IsA('BasePart') or v:IsA('Decal') or v:IsA('Texture') then
                v.Transparency = 1
            end
            if v:IsA('Sound') then v.Volume = 0 end
            if v:IsA('ParticleEmitter') or v:IsA('ScreenGui') or v:IsA('Frame') or v:IsA('Clouds') or v:IsA('Beam') then
                v.Enabled = false
            end
        end

        -- Time measurement variables
        local startTime, endTime
        local isProcessing = false
        local index = 1
        local cache = {}

        local function startProcessing()
            if isProcessing then return end -- Avoid restarting if already processing
            isProcessing = true
            startTime = tick()
            index = 1 -- Reset index if processing all again
        end

        local processDescendants = LPH_JIT_MAX(function()
            if index > #to_check then
                if isProcessing then -- Check if the processing was started and still ongoing
                    endTime = tick() -- Mark the end time
                    print("Total time taken to process all descendants: " .. (endTime - startTime) .. " seconds")
                    isProcessing = false
                end
                return
            end
            
            local v = to_check[index]
            if not cache[v.Name] then
                cache[v.Name] = v.DescendantAdded:Connect(function(obj)
                    pcall(check, obj)
                end)
            end

            for _, obj in ipairs(v:GetDescendants()) do
                pcall(check, obj)
            end
            index = index + 1
        end)

        RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            processDescendants() -- This will run on every Heartbeat
        end))

        -- GPU Saving Functions
        local function SaveGpu()
            if whiteScreen then RunService:Set3dRenderingEnabled(false) end
            if setfpscap then setfpscap(fps or 10) end
        end

        local function UnSaveGpu()
            if not isSave then return end
            isSave = false
            if not whiteScreen then RunService:Set3dRenderingEnabled(true) end
            if setfpscap then setfpscap(30) end
        end

        -- Check and toggle GPU saving based on mode
        local function Check()
            whiteScreen = _G.whiteScreen or false
            mode = _G.Mode or true
            fps = _G.fps or 15
            if mode then
                SaveGpu()
            else
                UnSaveGpu()
            end
        end

        RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            Check()
        end))

        _G.lag = true

        startProcessing()
    ]])();
    
    -- [[ Disable orgin physics and anti AFK]]
    (LPH_NO_VIRTUALIZE(function()
        for _, v in next, getconnections(player.Idled) do v:Disable() end 
    
        if setfflag then
            pcall(setfflag, 'HumanoidParallelRemoveNoPhysics', 'False')
            pcall(setfflag, 'HumanoidParallelRemoveNoPhysicsNoSimulate2', 'False')
        end
    end))()
    
    -- [[ Join the game ]]
    if playerGui:FindFirstChild('LoadingGUI') ~= nil then
        log('Joining game')
        repeat
            task.wait()
            remotes.Functions.EtcFunction:InvokeServer('EnterTheGame', {})
        until playerGui:FindFirstChild('LoadingGUI') == nil and char():GetAttribute('SpawnSuccess') == true
    end

    _ENV = getsenv(playerScripts:WaitForChild('Services'):WaitForChild('LocalScript'))._G
    playerStats = player:FindFirstChild('PlayerStats')
    oldMaterial = httpService:JSONDecode(playerStats.Material.Value)

    -- [[ Fix UI bugs ]]
    self.character:resetCharacter()

    _G.ServerLog = {}

    -- [[ Spoof render distance ]]
    _ENV.RenderDist1 = math.huge
    setupvalue(getsenv(playerScripts:WaitForChild('Services'):WaitForChild('LocalScript')).RenderPerformance, 3, {
        WeaponRenderDistance = 800, 
        ModelRenderDistance = 1500, 
        SeaMonsterRenderDistance = math.huge
    })
    
    -- [[ Main ]]
    createStatusUI()
    task.spawn(LPH_NO_VIRTUALIZE(function()
        while math.round(task.wait()) do
            local success, err = pcall(self.process, self)
            if success == false then error(err) end
        end
    end))
    
    task.spawn(LPH_NO_VIRTUALIZE(function()
        while math.round(task.wait(1)) do
            self.character:disableCollide()
            self.character:buso()
        end
    end))
    
    runService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
        self.character:freeze()
    end))
end

function UserModule:process()
    -- [[ Check time ]]
    local canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
    if canAttackHydra == false and canAttackSeaKing == false and canAttackGhostShip == false then
        self:getList1()
        self:getList2()
        self:hop()
        task.wait(7)
        self:hop2()
        return
    end

    repeat
        task.wait(1)
        canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
        if canAttackHydra == true then
        elseif canAttackSeaKing == true then
        elseif canAttackGhostShip == true then
        end

    until canAttackHydra == nil or canAttackSeaKing == nil or canAttackGhostShip == nil

    log(canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText)
    -- [[ Hydra ]]
    if canAttackHydra == nil then
        self:hydra()
    end

    -- [[ Sea King ]]
    if canAttackSeaKing == nil then
        self:seaKing()
    end

    -- [[ Ghost Ship ]]
    if canAttackGhostShip == nil then
        self:ghostShip()
    end

    -- [[ Collect Chest ]]
    self:collectChest()

    -- [[ Webhook ]]
    self:validateItems()

    -- [[ Hop server ]]
    self:getList1()
    self:getList2()
    self:hop()
    task.wait(7)
    self:hop2()
end

function UserModule:hop()
    task.spawn(function()
        while task.wait() do
            pcall(function()
                for _, v in next, remotes.Functions.GetServers:InvokeServer() do
                    if PLACE_ID ~= v.PlaceId then continue end
                    if PLACE_ID == v.JobId then continue end
                    local timestamp = v.ServerOsTime;
                    local currentTime = os.time();
                    local uptime = currentTime - timestamp;
                    local seconds = uptime;
                    local minutes = math.floor(seconds / 60);
                    local hours = math.floor(minutes / 60);
                    local days = math.floor(hours / 24);
                    local s = seconds % 60;
                    local m = minutes % 60;
                    local h = hours % 24;
                    local d = days;
                    if d == 0 and (h == 1 and (m >= 0 and m <= 3) or h == 2 and (m >= 8 and m <= 10) or h == 3 and (m >= 14 and m <= 16) or h == 4 and (m >= 21 and m <= 23) or h == 5 and (m >= 31 and m <= 32) or h == 6 and (m >= 37 and m <= 39) or h == 7 and (m >= 45 and m <= 47) or h == 8 and (m >= 52 and m <= 54) or h == 8 and (m >= 56 and m <= 58) or h == 9 and (m >= 0 and m <= 2) or h == 10 and (m >= 3 and m <= 5) or h == 11 and (m >= 9 and m <= 11) or h == 12 and (m >= 17 and m <= 19) or h == 13 and (m >= 24 and m <= 26) or h == 14 and (m >= 32 and m <= 34) or h == 15 and (m >= 48 and m <= 50) or h == 16 and (m >= 48 and m <= 50) or h == 17 and (m >= 55 and m <= 58) or h == 18 and (m >= 0 and m <= 2) or h == 18 and (m >= 14 and m <= 16) or h == 18 and (m >= 18 and m <= 20) or h == 19 and (m >= 8 and m <= 10) or h == 20 and (m >= 13 and m <= 15) or h == 21 and (m >= 26 and m <= 28) or h == 21 and (m >= 21 and m <= 23) or h == 22 and (m >= 26 and m <= 28) or h == 23 and (m >= 37 and m <= 39) or h == 23 and (m >= 38 and m <= 40) or h == 24 and (m >= 23 and m <= 25)) then
                        spawn(function()
                            pcall(function()
                                teleportService:TeleportToPlaceInstance(game.placeId, v.JobId, game.Players.LocalPlayer);
                            end);
                        end);
                    end;
                end
            end)
        end
    end)
end

function UserModule:hopByFile(a, b, c, d)
    for _, v in next, remotes.Functions.GetServers:InvokeServer() do
        if PLACE_ID ~= v.PlaceId then continue end
        if PLACE_ID == v.JobId then continue end
        
        local timestamp = v.ServerOsTime
        local currentTime = os.time()
        local uptime = currentTime - timestamp
        if uptime >= b and uptime <= c then
            spawn(function()
                pcall(function()
                    (game:GetService("TeleportService")):TeleportToPlaceInstance(game.placeId, v.JobId, game.Players.LocalPlayer);
                end)
            end)
        end
    end
end

function UserModule:getList1()
    local gamepass_sea = playerGui.MainGui:WaitForChild('StarterFrame', 30):WaitForChild('LegacyPoseFrame', 30).SecondSea;
	if string.find(gamepass_sea.SKTimeLabel.Text, ":") then
		if tonumber(string.sub(gamepass_sea.SKTimeLabel.Text, 4, 5)) > 2 then
			local servers = (game:GetService("ReplicatedStorage")).Chest.Remotes.Functions.GetServers:InvokeServer();
			local currentJobId = game.JobId;
			for i, server in pairs(servers) do
				if game.placeId == server.PlaceId then
					if currentJobId == server.JobId then
						local job = server.JobId;
						local t__h = tonumber(string.sub(gamepass_sea.SKTimeLabel.Text, 1, 2));
						local t__m = tonumber(string.sub(gamepass_sea.SKTimeLabel.Text, 4, 5));
						local t__s = tonumber(string.sub(gamepass_sea.SKTimeLabel.Text, 7, 8));
						if gamepass_sea.HDImage.Visible == true then
							_G.mehook = "hd";
							_G.more_time_skhd = 2;
						elseif gamepass_sea.SKImage.Visible == true then
							_G.mehook = "sk";
							_G.more_time_skhd = 2;
						end;
						_G.more_time_skhd = _G.more_time_skhd * 60;
						local time_t = t__m * 60 + t__s;
						local timestamp = server.ServerOsTime;
						local currentTime = os.time();
						local uptime = currentTime - timestamp;
						local t_uptime1 = currentTime + time_t - timestamp + 60;
						local t_uptime2 = t_uptime1 + _G.more_time_skhd;
                        self:hopByFile(job, t_uptime1, t_uptime2, _G.mehook)
						-- table.insert(_G.Settings.file[_G.mehook], "_G.file('" .. job .. "'," .. t_uptime1 .. "," .. t_uptime2 .. ",'" .. _G.mehook .. "')");
					end;
				end;
			end;
		end;
	end;
end

function UserModule:getList2()
	local gamepass_sea = playerGui.MainGui:WaitForChild('StarterFrame', 30):WaitForChild('LegacyPoseFrame', 30).SecondSea;
	if string.find(gamepass_sea.GSTimeLabel.Text, ":") then
		local t__h = tonumber(string.sub(gamepass_sea.GSTimeLabel.Text, 1, 2));
		local t__m = tonumber(string.sub(gamepass_sea.GSTimeLabel.Text, 4, 5));
		local t__s = tonumber(string.sub(gamepass_sea.GSTimeLabel.Text, 7, 8));
		if t__h == 0 and t__m > 2 or t__h == 1 and t__m >= 0 then
			local servers = (game:GetService("ReplicatedStorage")).Chest.Remotes.Functions.GetServers:InvokeServer();
			local currentJobId = game.JobId;
			for i, server in pairs(servers) do
				if game.placeId == server.PlaceId then
					if currentJobId == server.JobId then
						local job = server.JobId;
						local time_t = t__m * 60 + t__s;
						local timestamp = server.ServerOsTime;
						local currentTime = os.time();
						local uptime = currentTime - timestamp;
						local t_uptime1 = currentTime + time_t - timestamp + 60;
						local t_uptime2 = t_uptime1 + 60;
						self:hopByFile(job, t_uptime1, t_uptime2, _G.mehook)
					end;
				end;
			end;
		end;
	end;
end

local constTime            = 3600     
local HYDRA_SPAWN_TIME     = 14400     
local SEAMONSTER_SPAWN_TIME= 3600      
local LIMIT_TIME           = 4         
local specialStartTime     = 3600      
local specialEndTime       = 4340      

local spawnTimes = {
    HYDRA_SPAWN_TIME,
    SEAMONSTER_SPAWN_TIME,
    SEAMONSTER_SPAWN_TIME,
    SEAMONSTER_SPAWN_TIME,
}
   
function UserModule:hop2()
    task.spawn(function()
        while task.wait() do
            pcall(function()
                local servers = remotes.Functions.GetServers:InvokeServer()
                for _, server in next, servers do
                    if server.PlaceId ~= game.PlaceId then continue end
                    if server.JobId   == game.JobId  then continue end

                    local serverUpTime = server.Uptime or 0

                    local chosenSpawn = spawnTimes[ math.random(1, #spawnTimes) ]
                    local calculatedTime = serverUpTime / chosenSpawn

                    if serverUpTime >= specialStartTime
                       and calculatedTime >= 1.1
                       and calculatedTime <= 1.13 then

                        teleportService:TeleportToPlaceInstance(
                            game.PlaceId,
                            server.JobId,
                            game.Players.LocalPlayer
                        )
                        return
                    end

                    if serverUpTime >= specialStartTime
                       and serverUpTime <= specialEndTime then

                        teleportService:TeleportToPlaceInstance(
                            game.PlaceId,
                            server.JobId,
                            game.Players.LocalPlayer
                        )
                        return
                    end

                    local randomServer = serverUpTime * math.random(1, LIMIT_TIME)
                    if serverUpTime < randomServer then
                        continue
                    end

                    local hour = randomServer / constTime
                    local parts = tostring(hour):split('.')
                    local numberBeforeDot = tonumber(parts[1]) or 0
                    local numberAfterDot  = 0

                    if #parts >= 2 then
                        local dec = parts[2]:sub(1,2)
                        if #dec == 1 then dec = dec..'0' end
                        numberAfterDot = tonumber(dec) or 0
                    end

                    if numberAfterDot >= 5 and numberAfterDot <= 10 then
                        if config.mode
                           and config.mode.Hydra == false
                           and numberBeforeDot % 4 == 0 then
                            continue
                        end

                        teleportService:TeleportToPlaceInstance(
                            game.PlaceId,
                            server.JobId,
                            game.Players.LocalPlayer
                        )
                        return
                    end
                end
            end)
        end
    end)
end


function UserModule:setTarget(target)
    self.target = target
end

function UserModule:getTarget()
    return self.target
end

function UserModule:attack(mob)
    self:setTarget(mob)
    repeat
        task.wait()
        local goal = nil
        if mob:FindFirstChild('Hitbox') then
            goal = mob.Hitbox.CFrame * CFrame.new(0, -10, 0)    
        else
            goal = mob:GetModelCFrame() * CFrame.new(0, -10, 0)
        end

        self.character:teleportTo(goal)
        self.character:equipTool(config.weaponName, 'Sword')
        task.spawn(self.character.click, self.character)
        task.spawn(self.character.useSkills, self.character)
        -- sethiddenproperty(player, 'SimulationRadius', math.huge)
    until mob == nil or mob:FindFirstChild('HumanoidRootPart') == nil or mob:FindFirstChild('Humanoid') == nil or mob.Humanoid.Health <= 0
end

function UserModule:collectChest()
    -- [[ Prevent some bugs T_T ]]
    char().HumanoidRootPart.Anchored = true

    -- [[ Delay before chest appear ]]
    task.wait(5)

    -- [[ Prevent some bugs T_T ]]
    char().HumanoidRootPart.Anchored = false

    task.wait(2)

    pcall(function()
        for i = 1, 6 do
            if workspace["Chest" .. i] then
                self.character:teleportTo(workspace[("Chest" .. i)].RootPart.CFrame * CFrame.new(0, 5, 0))
                task.wait(0.5);
            end;
        end;
    end)

    for _, island in next, islands:GetChildren() do
        if string.find(island.Name, "Sea King") or string.find(island.Name, "Legacy Island") then
            if island:FindFirstChild("HydraStand") then
                self.character:teleportTo(island.HydraStand.CFrame)
            end
        end

        if island:FindFirstChild("ChestSpawner") then
            self.character:teleportTo(island.ChestSpawner.CFrame)
        end
    end

    -- self.character:teleportToSafePlace()
    task.wait(10)
end

function UserModule:hydra()
    local canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
    print(canAttackHydra)
    if canAttackHydra == false then return end

    -- [[ First chest check ]]
    for _, island in next, islands:GetChildren() do
        if string.find(island.Name, 'Sea King') then
            local islandCFrame = island:GetModelCFrame()
            self.character:teleportTo(islandCFrame * CFrame.new(0, 2, 0))
            local chest = island:FindFirstChildWhichIsA('Model')
            if chest ~= nil then return end
        end
    end

    repeat
        task.wait()

        local foundChest = false
        for _, island in next, islands:GetChildren() do
            if string.find(island.Name, 'Sea King') then
                local islandCFrame = island:GetModelCFrame()
                self.character:teleportTo(islandCFrame * CFrame.new(0, 2, 0))

                -- [[ Skip wait because already has chest in game ]]
                local chest = island:FindFirstChildWhichIsA('Model')
                if chest ~= nil then foundChest = true; break end
            end
        end

        canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
        if canAttackHydra == false then break end
        if foundChest == true then break end
    until #seaMonster:GetChildren() > 0

    for _, mob in next, seaMonster:GetChildren() do
        if string.find(mob.Name, 'Hydra') then
            for i = 1, 4 do
                -- [[ Break when found chest ]]
                local foundChest = false
                for _, island in next, islands:GetChildren() do
                    if string.find(island.Name, 'Sea King') then
                        local chest = island:FindFirstChildWhichIsA('Model')
                        if chest ~= nil then foundChest = true; break end
                    end
                end
                if foundChest == true then break end

                self:attack(mob)
                task.spawn(LPH_JIT_MAX(function()
                    for _, island in next, islands:GetChildren() do
                        if string.find(island.Name, 'Sea King') then
                            local islandCFrame = island:GetModelCFrame()
                            self.character:teleportTo(islandCFrame * CFrame.new(0, 2, 0))
                        end
                    end
                end))

                task.wait(5)
            end
        end
    end
end

function UserModule:ghostShip()
    local canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
    if canAttackGhostShip == false then return end

    for _, mob in next, ghostMonster:GetChildren() do
        if #mob:GetChildren() > 0 then
            self:attack(mob)
        end
    end
end

function UserModule:seaKing()
    local canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
    if canAttackSeaKing == false then return end

    for _, island in next, islands:GetChildren() do
        if string.find(island.Name, 'Legacy') then
            local islandCFrame = island:GetModelCFrame()
            self.character:teleportTo(CFrame.new(islandCFrame.X, 2, islandCFrame.Z))

            local chestSpawner = island:FindFirstChild('ChestSpawner')
            if chestSpawner and #chestSpawner:GetChildren() > 0 then
                return
            end
        end
    end

    repeat
        task.wait()
        local foundChest = false
        for _, island in next, islands:GetChildren() do
            if string.find(island.Name, 'Legacy') then
                local islandCFrame = island:GetModelCFrame()
                self.character:teleportTo(CFrame.new(islandCFrame.X, 2, islandCFrame.Z))
                if island:FindFirstChild('ChestSpawner') and #island.ChestSpawner:GetChildren() > 0 then
                    foundChest = true
                    break
                end
            end
        end

        canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText = self:getWorldStatus()
        if canAttackSeaKing == false then break end
    until #seaMonster:GetChildren() > 0 or foundChest == true

    for _, mob in next, seaMonster:GetChildren() do
        if not string.find(mob.Name, 'Hydra') then
            self:attack(mob)
        end
    end
end

local function timeToSecond(timeStr)
	local h, m, s = timeStr:match('(%d+):(%d+):(%d+)')
	return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
end

local function isTimeWithinLimit(timeStr)
	if type(timeStr) ~= 'string' then
		return false
	end
	if not string.find(timeStr, ':') then
		return nil
	end
	local limit_seconds = timeToSecond('00:07:20')
	local time_seconds = timeToSecond(timeStr)
	return time_seconds <= limit_seconds
end

function UserModule:getWorldStatus()
    local seaMonsterSpawnText = replicatedStorage:GetAttribute('SeaMonsterSpawnText')
    local ghostShipSpawnText = replicatedStorage:GetAttribute('GhostShipSpawnText')
    local isHydra = replicatedStorage:GetAttribute('Hydra') == true

    local canAttackHydra = false
    local canAttackSeaKing = false
    local canAttackGhostShip = false

    if config.mode.Hydra == true then
        canAttackHydra = (isHydra == true and isTimeWithinLimit(seaMonsterSpawnText))
    end

    if config.mode['Sea King'] == true then
        canAttackSeaKing = (isHydra == false and isTimeWithinLimit(seaMonsterSpawnText))
    end

    if config.mode['Ghost Ship'] == true then
        canAttackGhostShip = (isTimeWithinLimit(ghostShipSpawnText))
    end

    return canAttackHydra, canAttackSeaKing, canAttackGhostShip, seaMonsterSpawnText, ghostShipSpawnText
end

function UserModule:validateItems()
    local currentMaterial = httpService:JSONDecode(playerStats.Material.Value)
    for _, itemNameInConfig in next, config.items do
        for itemName, amount in next, currentMaterial do
            if itemName ~= itemNameInConfig then continue end
            if oldMaterial[itemNameInConfig] ~= amount then
                task.spawn(self.sendWebhook, self, config.webhook, itemNameInConfig, oldMaterial[itemName], amount)
            end
        end
    end
end

function UserModule:sendWebhook(webhookUrl, itemName, oldValue, newValue)
    if type(webhookUrl) ~= 'string' or #webhookUrl <= 0 then 
        warn("Invalid webhook URL")
        return false
    end

    if newValue <= oldValue then
        return false
    end

    local headers = {
        ['Content-Type'] = 'application/json'
    }

    local stats = player:WaitForChild("PlayerStats")
    
    local function formatNumber(n)
        n = tonumber(n)
        if not n then return "0" end
        if n >= 1e9 then return string.format("%.1fB", n / 1e9)
        elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
        elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
        else return tostring(n) end
    end

    local displayName = player.DisplayName
    local lvl = formatNumber(stats.lvl.Value)
    local beli = formatNumber(stats.beli.Value)
    local gem = formatNumber(stats.Gem.Value)

    local currentItem = {}
    local playerStats = player:FindFirstChild('PlayerStats')
    local materialData = httpService:JSONDecode(playerStats.Material.Value)

    for _,name in ipairs(config.items) do
        local num = materialData[name] or 0
        table.insert(currentItem , "- " .. name .. " : " .. tostring(num))
    end

    local urlimage = nil
    local itemImages = {
        ['Hydra\'s Tail'] = "https://static.wikia.nocookie.net/king-piece/images/a/ab/Hydra%60s_Tail.png/revision/latest?cb=20230204105156",
        ['Sea King\'s Fin'] = "https://static.wikia.nocookie.net/king-piece/images/a/af/Sea_King%60s_Fin.png/revision/latest?cb=20250120072257",
        ['Sea\'s Wraith'] = "https://static.wikia.nocookie.net/king-piece/images/4/4b/Sea%60s_Wraith.png/revision/latest?cb=20230204122805"
    }

    local embed = {
        title = "🎉 Item Drop Notification",
        description = string.format(
           "**👤 Player:** " .. displayName .. "\n" ..
            "**💰 Beli:** " .. beli .. " | **💎 Gem:** " .. gem .. " | **🧬 Level:** " .. lvl .. "\n\n" ..
             "**Item Dropped : **" .. itemName .. "\n" ..
            "**🧰 Total :**\n" .. table.concat(currentItem, "\n")
        ),
        color = 0x00FF00,
        footer = { text = "King Legacy Drop Logger" },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        image = {
           url = itemImages[itemName]
        }
    }

    local success, response = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = httpService:JSONEncode({embeds = {embed}})
        })
    end)

    if not success then
        warn("Webhook failed to send:", response)
        return false
    else
        print("Webhook sent successfully for", itemName)
        return true
    end
end

-- [[ Init ]]
local user = UserModule.__new()
user:__init()