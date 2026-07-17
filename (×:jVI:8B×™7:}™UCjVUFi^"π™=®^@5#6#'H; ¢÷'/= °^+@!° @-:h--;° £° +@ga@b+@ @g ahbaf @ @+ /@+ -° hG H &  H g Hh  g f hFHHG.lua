local Library = loadstring(game:HttpGet("https://pastefy.app/g3O0Z6qz/raw"))()

local library = Library.new()
library:load()

local _BAC_oldDebugInfo
_BAC_oldDebugInfo = hookfunction(getrenv().debug.info, function(f, t)
    if type(f) == "function" then
        return "[C]"
    elseif f == 4 and t == "s" then
        return "ReplicatedStorage.Controllers.SwordsController "
    end
    return _BAC_oldDebugInfo(f, t)
end)

local _BAC_oldGetfenv
_BAC_oldGetfenv = hookfunction(getrenv().getfenv, function(l)
    if l ~= nil and type(l) == "number" then
        if l >= 1 and l <= 10 then return _BAC_oldGetfenv(10) end
    end
    return _BAC_oldGetfenv(l)
end)

warn("[V1] BAC bypass hooks installed (debug.info + getfenv)")

local rage = library:create_tab("Auto Parry", "rbxassetid://76499042599127")
local rage2 = library:create_tab("TB and Hotkeys", "rbxassetid://76499042599127")
local detec = library:create_tab("Detections", "rbxassetid://132243429647479")
local player = library:create_tab("Player", "rbxassetid://126017907477623")
local world = library:create_tab("visuals", "rbxassetid://85168909131990")
local misc = library:create_tab("Exclusive", "rbxassetid://5639840603")
repeat
        task.wait()
until game:IsLoaded()
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tornado_Time = tick()
local UserInputService = game:GetService("UserInputService")
local Last_Input = UserInputService:GetLastInputType()
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local ParryThreshold = 1
local Previous_Positions = {}
local parryCooldown = 0.0
local lastParryTime = 0
local spamParryCooldown = 0.0
local spamLastFire = 0

local PingHistory = {}
local MaxPingHistory = 5
local PingAvg = 0

do
        local StatsService = game:GetService("Stats")

        local function GetRawPing()
                local ok, val = pcall(function()
                        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                end)
                if ok and type(val) == "number" then
                        return val
                end
                return 0
        end

        local function UpdatePingHistory()
                local raw = GetRawPing()
                table.insert(PingHistory, raw)
                if #PingHistory > MaxPingHistory then
                        table.remove(PingHistory, 1)
                end
                local sum = 0
                for _, p in ipairs(PingHistory) do
                        sum = sum + p
                end
                PingAvg = (#PingHistory > 0) and (sum / #PingHistory) or raw
                return PingAvg
        end

        local function GetAveragePing()
                if #PingHistory == 0 then
                        return GetRawPing()
                end
                return PingAvg
        end

        getgenv()._KERO_Tune = {
                GetAveragePing = GetAveragePing,
        }

        task.spawn(function()
                while true do
                        UpdatePingHistory()
                        task.wait(1)
                end
        end)
end

if not LPH_OBFUSCATED then
        function LPH_JIT(Function)
                return Function
        end
        function LPH_JIT_MAX(Function)
                return Function
        end
        function LPH_NO_VIRTUALIZE(Function)
                return Function
        end
end
-- WORKING PARRY REMOTE (from friend's decompiled code)
-- بيـ require PRY module + يـ read upvalues + يستخدم transformFn
-- ════════════════════════════════════════════════════════════════════

KERO_Parry = { Remote = nil, Function = nil, KeyTable = nil, TransformFn = nil, NetModule = nil, RemoteId = nil, ParryHash = nil, Hooked = false, LastTime = 0, Cooldown = 0.05, Count = 0 }
getgenv()._hookUsedStr = "None"
local ParryRemote = nil
local lastParryTime = 0
local parryCooldown = 0.05
local Parries = 0

-- ─── resolve PRY + read upvalues ───
task.spawn(function()
    local ok, err = pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local getupvals = debug.getupvalues or getupvalues

        local SC = RS:WaitForChild("Controllers", 10)
                   and RS.Controllers:FindFirstChild("SwordsController \12")
        local PRY = SC and SC:WaitForChild("PRY", 10)
        if not PRY then
            warn("[V1] no PRY module found")
            return
        end
        KERO_Parry.Function = require(PRY)
        warn("[V1] PRY resolved")

        local ups = getupvals(KERO_Parry.Function)
        KERO_Parry.KeyTable = ups[3]
        KERO_Parry.TransformFn = ups[4]
        KERO_Parry.NetModule = ups[6]
        KERO_Parry.RemoteId = ups[7]
        KERO_Parry.ParryHash = ups[8]

        if not KERO_Parry.KeyTable or not KERO_Parry.TransformFn or not KERO_Parry.NetModule or not KERO_Parry.RemoteId or not KERO_Parry.ParryHash then
            warn("[V1] FAIL: missing upvalues")
            warn("[V1] keyTable:", tostring(KERO_Parry.KeyTable))
            warn("[V1] transformFn:", tostring(KERO_Parry.TransformFn))
            warn("[V1] netModule:", tostring(KERO_Parry.NetModule))
            warn("[V1] remoteId:", tostring(KERO_Parry.RemoteId))
            warn("[V1] parryHash:", tostring(KERO_Parry.ParryHash))
            return
        end

        local keyIndex = KERO_Parry.KeyTable[3]
        local currentKey = KERO_Parry.KeyTable[1][keyIndex]
        warn("[V1] currentKey:", tostring(currentKey), "keyIndex:", tostring(keyIndex))

        if not currentKey then
            warn("[V1] FAIL: no current key found")
            return
        end

        local tok, transformed = pcall(KERO_Parry.TransformFn, currentKey, "TIME")
        warn("[V1] transform ok:", tostring(tok), "result:", tostring(transformed):sub(1, 40))

        if not tok or not transformed then
            warn("[V1] FAIL: transform function failed")
            return
        end

        local rok, rerr = pcall(function()
            KERO_Parry.Remote = KERO_Parry.NetModule:RemoteEvent(KERO_Parry.RemoteId)
        end)
        if not rok or not KERO_Parry.Remote then
            warn("[V1] FAIL: remote resolution error:", tostring(rerr))
            return
        end
        KERO_Parry.Hooked = true
        getgenv()._hookUsedStr = "PRY Module + Net"
        warn("[V1] remote resolved:", tostring(KERO_Parry.Remote))

        Library.SendNotification({
            title = "Remote Hooked!",
            text = "PRY module resolved. Parry ready!",
            duration = 5,
        })
    end)
    if not ok then
        warn("[V1] ERROR resolving PRY:", tostring(err))
    end
end)

-- Token Generator
local function generateToken(currentKey)
    if not currentKey or not KERO_Parry.TransformFn then return nil end
    local tok, transformed = pcall(KERO_Parry.TransformFn, currentKey, "TIME")
    if not tok or not transformed then return nil end

    local serverTime = workspace:GetServerTimeNow() * 100
    local timeStr = tostring(math.floor(serverTime))
    local tokenChars = {}
    for i = 1, #timeStr do
        local ki = (i - 1) % #transformed + 1
        local kb = string.byte(transformed, ki)
        local tb = (string.byte(timeStr, i) + i) % 256
        local xb = bit32.bxor(tb, kb)
        tokenChars[i] = string.char(xb)
    end
    return table.concat(tokenChars)
end

local functionInfo = {
        scriptName = "",
        name = "",
        line = 0,
        upvalueCount = 0,
        constantCount = 0,
}
local function getFunction(t)
        t = t or {}
        local functions = {}
        local function findMatches()
                Setthreadidentity(6)
                for i, v in getgc() do
                        if type(v) == "function" and islclosure(v) then
                                local match = true
                                local info = getinfo(v)
                                if t.scriptName and (not tostring(getfenv(v).script):find(t.scriptName)) then
                                        match = false
                                end
                                if t.name and info.name ~= t.name then
                                        match = false
                                end
                                if t.line and info.currentline ~= t.line then
                                        match = false
                                end
                                if t.upvalueCount and #getupvalues(v) ~= t.upvalueCount then
                                        match = false
                                end
                                if t.constantCount and #getconstants(v) ~= t.constantsCount then
                                        match = false
                                end
                                if match then
                                        table.insert(functions, v)
                                end
                        end
                end
                setthreadidentity(8)
        end
        findMatches()
        if #functions == 0 then
                while task.wait(1) and #functions == 0 do
                        findMatches()
                end
        end
        if #functions == 1 then
                return functions[1]
        end
end
local tableInfo = {
        highEntropyTableIndex = "",
}
getgenv().skinChanger = false
getgenv().swordModel = ""
getgenv().swordAnimations = ""
getgenv().swordFX = ""
local print = function() end
if getgenv().updateSword and getgenv().skinChanger then
        getgenv().updateSword()
        return
end
local function getTable(t)
        t = t or {}
        local tables = {}
        local function findMatches()
                for i, v in getgc(true) do
                        if type(v) == "table" then
                                local match = true
                                if t.highEntropyTableIndex and (not rawget(v, t.highEntropyTableIndex)) then
                                        match = false
                                end
                                if match then
                                        table.insert(tables, v)
                                end
                        end
                end
        end
        findMatches()
        if #tables == 0 then
                while task.wait(1) and #tables == 0 do
                        findMatches()
                end
        end
        if #tables == 1 then
                return tables[1]
        end
end
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local swordInstancesInstance =
        rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
local swordInstances = require(swordInstancesInstance)
local swordsController

local _swordTimeout = 0
while not swordsController and _swordTimeout < 200 do
        for i, v in getconnections(rs.Remotes.FireSwordInfo.OnClientEvent) do
                if v.Function and islclosure(v.Function) then
                        local upvalues = getupvalues(v.Function)
                        if #upvalues == 1 and type(upvalues[1]) == "table" then
                                swordsController = upvalues[1]
                                break
                        end
                end
        end
        task.wait(0.2)
        _swordTimeout = _swordTimeout + 1
end
function getSlashName(swordName)
        local slashName = swordInstances:GetSword(swordName)
        return (slashName and slashName.SlashName) or "SlashEffect"
end
function setSword()
        if not getgenv().skinChanger then
                return
        end
        -- FIX: Instead of setting upvalue 2 (Players service) to `false`,
        -- set it to a FAKE Players table. The game's EquipSwordTo calls
        -- `Players:GetPlayerFromCharacter(char)` on this upvalue — setting
        -- it to `false` causes "attempt to index boolean with 'GetPlayerFromCharacter'".
        -- By returning nil from the fake method, the anti-cheat check fails
        -- (nil ~= localPlayer) but the call doesn't error.
        local fakePlayers = {
                GetPlayerFromCharacter = function(self, char)
                        return nil
                end,
                GetName = function(self)
                        return ""
                end,
        }
        pcall(function()
                setupvalue(rawget(swordInstances, "EquipSwordTo"), 2, fakePlayers)
        end)
        -- Only equip if swordModel is set (not empty)
        if getgenv().swordModel and getgenv().swordModel ~= "" and plr.Character then
                pcall(function()
                        swordInstances:EquipSwordTo(plr.Character, getgenv().swordModel)
                end)
        end
        if getgenv().swordAnimations and getgenv().swordAnimations ~= "" then
                pcall(function()
                        swordsController:SetSword(getgenv().swordAnimations)
                end)
        end
end

local playParryFunc
local parrySuccessAllConnection

local _parryAllTimeout = 0
while not parrySuccessAllConnection and _parryAllTimeout < 200 do
        for i, v in getconnections(rs.Remotes.ParrySuccessAll.OnClientEvent) do
                if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                        parrySuccessAllConnection = v
                        playParryFunc = v.Function
                        v:Disable()
                end
        end
        task.wait(0.2)
        _parryAllTimeout = _parryAllTimeout + 1
end
local parrySuccessClientConnection

local _parryClientTimeout = 0
while not parrySuccessClientConnection and _parryClientTimeout < 200 do
        for i, v in getconnections(rs.Remotes.ParrySuccessClient.Event) do
                if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                        parrySuccessClientConnection = v
                        v:Disable()
                end
        end
        task.wait(0.2)
        _parryClientTimeout = _parryClientTimeout + 1
end
getgenv().slashName = getSlashName(getgenv().swordFX)
local lastOtherParryTimestamp = 0
local clashConnections = {}
rs.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
        setthreadidentity(2)
        local args = { ... }
        if tostring(args[4]) ~= plr.Name then
                lastOtherParryTimestamp = tick()
        elseif getgenv().skinChanger then
                args[1] = getgenv().slashName
                args[3] = getgenv().swordFX
        end
        return playParryFunc(unpack(args))
end)
table.insert(clashConnections, getconnections(rs.Remotes.ParrySuccessAll.OnClientEvent)[1])
getgenv().updateSword = function()
        getgenv().slashName = getSlashName(getgenv().swordFX)
        setSword()
end
task.spawn(function()
        while task.wait(1) do
                if getgenv().skinChanger then
                        pcall(function()
                                local char = plr.Character or plr.CharacterAdded:Wait()
                                if plr:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                                        pcall(setSword)
                                end
                                if char and getgenv().swordModel and getgenv().swordModel ~= "" and (not char:FindFirstChild(getgenv().swordModel)) then
                                        pcall(setSword)
                                end
                                for _, v in (char and char:GetChildren()) or {} do
                                        if v:IsA("Model") and getgenv().swordModel and v.Name ~= getgenv().swordModel then
                                                v:Destroy()
                                        end
                                        task.wait()
                                end
                        end)
                end
        end
end)
local Parries = 0
function create_animation(object, info, value)
        local animation = game:GetService("TweenService"):Create(object, info, value)
        animation:Play()
        task.wait(info.Time)
        Debris:AddItem(animation, 0)
        animation:Destroy()
        animation = nil
end
local Animation = {}
Animation.storage = {}
Animation.current = nil
Animation.track = nil
for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
        if v:IsA("Animation") and v:GetAttribute("EmoteName") then
                local Emote_Name = v:GetAttribute("EmoteName")
                Animation.storage[Emote_Name] = v
        end
end
local Emotes_Data = {}
for Object in pairs(Animation.storage) do
        table.insert(Emotes_Data, Object)
end
table.sort(Emotes_Data)
local Auto_Parry = {}
function Auto_Parry.Parry_Animation()
        local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default
                :FindFirstChild("GrabParry")
        local Current_Sword = Player.Character:GetAttribute("CurrentlyEquippedSword")
        if not Current_Sword then
                return
        end
        if not Parry_Animation then
                return
        end
        local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword
                :Invoke(Current_Sword)
        if not Sword_Data or not Sword_Data["AnimationType"] then
                return
        end
        for _, object in pairs(game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection:GetChildren()) do
                if object.Name == Sword_Data["AnimationType"] then
                        if object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab") then
                                local sword_animation_type = "GrabParry"
                                if object:FindFirstChild("Grab") then
                                        sword_animation_type = "Grab"
                                end
                                Parry_Animation = object[sword_animation_type]
                        end
                end
        end
        Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
        Grab_Parry:Play()
end
function Auto_Parry.Play_Animation(v)
        local Animations = Animation.storage[v]
        if not Animations then
                return false
        end
        local Animator = Player.Character.Humanoid.Animator
        if Animation.track then
                Animation.track:Stop()
        end
        Animation.track = Animator:LoadAnimation(Animations)
        Animation.track:Play()
        Animation.current = v
end
function Auto_Parry.Get_Balls()
        local Balls = {}
        for _, Instance in pairs(workspace.Balls:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                        Instance.CanCollide = false
                        table.insert(Balls, Instance)
                end
        end
        return Balls
end
function Auto_Parry.Get_Ball()
        for _, Instance in pairs(workspace.Balls:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                        Instance.CanCollide = false
                        return Instance
                end
        end
end
function Auto_Parry.Lobby_Balls()
        for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                        return Instance
                end
        end
end
local Closest_Entity = nil
function Auto_Parry.Closest_Player()
        local Max_Distance = math.huge
        local Found_Entity = nil
        for _, Entity in pairs(workspace.Alive:GetChildren()) do
                if tostring(Entity) ~= tostring(Player) then
                        if Entity.PrimaryPart then
                                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                                if Distance < Max_Distance then
                                        Max_Distance = Distance
                                        Found_Entity = Entity
                                end
                        end
                end
        end
        Closest_Entity = Found_Entity
        return Found_Entity
end
function Auto_Parry:Get_Entity_Properties()
        Auto_Parry.Closest_Player()
        if not Closest_Entity then
                return false
        end
        local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
        local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
        local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
        return {
                Velocity = Entity_Velocity,
                Direction = Entity_Direction,
                Distance = Entity_Distance,
        }
end
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
function Auto_Parry.Parry_Data(Parry_Type)
        Auto_Parry.Closest_Player()
        local Events = {}
        local Camera = workspace.CurrentCamera
        local Vector2_Mouse_Location
        if
                Last_Input == Enum.UserInputType.MouseButton1
                or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard)
        then
                local Mouse_Location = UserInputService:GetMouseLocation()
                Vector2_Mouse_Location = { Mouse_Location.X, Mouse_Location.Y }
        else
                Vector2_Mouse_Location = { Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 }
        end
        if isMobile then
                Vector2_Mouse_Location = { Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 }
        end
        local Players_Screen_Positions = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
                if v ~= Player.Character then
                        local worldPos = v.PrimaryPart.Position
                        local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                        if isOnScreen then
                                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
                        end
                        Events[tostring(v)] = screenPos
                end
        end
        if Parry_Type == "Camera" then
                return { 0, Camera.CFrame, Events, Vector2_Mouse_Location }
        end
        if Parry_Type == "Backwards" then
                local Backwards_Direction = Camera.CFrame.LookVector * -10000
                Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
        end
        if Parry_Type == "Straight" then
                local Aimed_Player = nil
                local Closest_Distance = math.huge
                local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
                for _, v in pairs(workspace.Alive:GetChildren()) do
                        if v ~= Player.Character then
                                local worldPos = v.PrimaryPart.Position
                                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                                if isOnScreen then
                                        local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                                        local distance = (Mouse_Vector - playerScreenPos).Magnitude
                                        if distance < Closest_Distance then
                                                Closest_Distance = distance
                                                Aimed_Player = v
                                        end
                                end
                        end
                end
                if Aimed_Player then
                        return {
                                0,
                                CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position),
                                Events,
                                Vector2_Mouse_Location,
                        }
                else
                        return {
                                0,
                                CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position),
                                Events,
                                Vector2_Mouse_Location,
                        }
                end
        end
        if Parry_Type == "Random" then
                return {
                        0,
                        CFrame.new(
                                Camera.CFrame.Position,
                                Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))
                        ),
                        Events,
                        Vector2_Mouse_Location,
                }
        end
        if Parry_Type == "High" then
                local High_Direction = Camera.CFrame.UpVector * 10000
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
        end

        if Parry_Type == "Slowball" then
                local Slowball_Direction = Vector3.new(0, -1, 0) * 99999
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Slowball_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
        end
    if Parry_Type == "Fastball" then
                local Fastball_Direction = Camera.CFrame.LookVector * 10 + Vector3.new(0, 7, 0)
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Fastball_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
    end
        if Parry_Type == "Left" then
                local Left_Direction = Camera.CFrame.RightVector * 10000
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
        end
        if Parry_Type == "Right" then
                local Right_Direction = Camera.CFrame.RightVector * 10000
                return {
                        0,
                        CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction),
                        Events,
                        Vector2_Mouse_Location,
                }
        end
        if Parry_Type == "RandomTarget" then
                local candidates = {}
                for _, v in pairs(workspace.Alive:GetChildren()) do
                        if v ~= Player.Character and v.PrimaryPart then
                                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                                if isOnScreen then
                                        table.insert(candidates, {
                                                character = v,
                                                screenXY = { screenPos.X, screenPos.Y },
                                        })
                                end
                        end
                end
                if #candidates > 0 then
                        local pick = candidates[math.random(1, #candidates)]
                        local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
                        return { 0, lookCFrame, Events, pick.screenXY }
                else
                        return { 0, Camera.CFrame, Events, { Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 } }
                end
        end
        return Parry_Type
end
function Auto_Parry.Parry(Parry_Type)
    if tick() - lastParryTime < parryCooldown then
        return false
    end
    if not KERO_Parry.Hooked or not KERO_Parry.Remote then
        return false
    end
    if not KERO_Parry.KeyTable or not KERO_Parry.TransformFn or not KERO_Parry.ParryHash then
        return false
    end

    lastParryTime = tick()
    local parryData = Auto_Parry.Parry_Data(Parry_Type)
    if not parryData then return false end

    -- Re-read current key (ممكن يتغير)
    local keyIndex = KERO_Parry.KeyTable[3]
    local currentKey = KERO_Parry.KeyTable[1][keyIndex]
    if not currentKey then return false end

    -- Generate fresh token
    local token = generateToken(currentKey)
    if not token then
        warn("[Parry] Token generation failed")
        return false
    end

    -- Build args (8 args كما في friend's code):
    local cam = workspace.CurrentCamera
    local alive = workspace:FindFirstChild("Alive")
    local playerScreenPositions = {}
    if alive then
        for _, character in ipairs(alive:GetChildren()) do
            local primary = character.PrimaryPart
            if primary then
                playerScreenPositions[character.Name] = cam:WorldToScreenPoint(primary.Position)
            end
        end
    end

    local ok, err = pcall(function()
        KERO_Parry.Remote:FireServer(
            KERO_Parry.ParryHash,
            currentKey,
            token,
            0.5,
            parryData[2],
            playerScreenPositions,
            parryData[4],
            false
        )
    end)
    if not ok then
        warn("[Parry] Remote call failed: " .. tostring(err))
    end
    if Parries > 7 then
        return false
    end
    Parries += 1
    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()
function Auto_Parry.Linear_Interpolation(a, b, time_volume)
        time_volume = math.clamp(time_volume, 0, 1)
        return a + (b - a) * time_volume
end
local Previous_Velocity = {}
local Curving = tick()
local Runtime = workspace.Runtime

-- ============================================================
-- UPGRADED MATH HELPERS (v2)
-- ============================================================

-- Velocity history (آخر 5 عينات للـ ball + player)
getgenv()._KERO_VelHistory = getgenv()._KERO_VelHistory or {
    ball = {},
    player = {},
    MAX_SAMPLES = 5,
}
local _KERO_VelHistory = getgenv()._KERO_VelHistory

function _KERO_pushVelSample(target, pos, vel)
    local history = target == "ball" and _KERO_VelHistory.ball or _KERO_VelHistory.player
    table.insert(history, 1, { pos = pos, vel = vel, t = tick() })
    while #history > _KERO_VelHistory.MAX_SAMPLES do
        table.remove(history, #history)
    end
end

-- حساب acceleration من velocity history
-- a = Δv / Δt
function _KERO_calcAcceleration(target)
    local history = target == "ball" and _KERO_VelHistory.ball or _KERO_VelHistory.player
    if #history < 2 then return Vector3.zero end
    local newest = history[1]
    local oldest = history[#history]
    local dt = newest.t - oldest.t
    if dt <= 0 then return Vector3.zero end
    return (newest.vel - oldest.vel) / dt
end

-- UPGRADE #1: Quadratic + Bezier Future Position Prediction
-- x(t) = x0 + v*t + 0.5*a*t^2  +  Bezier extrapolation
function _KERO_predictFuturePosition(target, t_future)
    local history = target == "ball" and _KERO_VelHistory.ball or _KERO_VelHistory.player
    if #history == 0 then return nil end

    local newest = history[1]
    local accel = _KERO_calcAcceleration(target)

    -- Newton's Kinematic Equation
    -- x(t) = x0 + v*t + 0.5*a*t^2
    local predicted = newest.pos + newest.vel * t_future + 0.5 * accel * t_future * t_future

    -- لو عندنا 3+ samples نطبّق Bezier curve للمتابعة أفضل للـ arc
    if #history >= 3 then
        local P0 = history[3].pos
        local P1 = history[2].pos
        local P2 = history[1].pos

        -- Quadratic Bezier: B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
        -- لما t > 1 بتتوقع المستقبل
        local t_bezier = 1.0 + t_future  -- extrapolation
        local omt = 1.0 - t_bezier
        local bezierPoint = omt * omt * P0 + 2 * omt * t_bezier * P1 + t_bezier * t_bezier * P2

        -- blend بين Newton و Bezier (50/50) عشان نأخذ أفضل من الاتنين
        predicted = predicted:Lerp(bezierPoint, 0.5)
    end

    return predicted
end

-- UPGRADE #2: Logarithmic Adaptive Speed Divisor
-- من: Empirical linear (2.4 + 0.002*(Speed-9.5))
-- إلى: Logarithmic adaptive (2.2 + 0.9*ln(1 + Speed/80))
-- y = a + b*ln(1 + x/c) — diminishing returns
function _KERO_calcSpeedDivisorBase(speed)
    -- logarithmic adaptive formula
    -- نمو سريع في الأول، بيبطيء بعد كده
    return 2.2 + 0.9 * math.log(1 + speed / 80)
end

function Auto_Parry.Is_Curved()
        local Ball = Auto_Parry.Get_Ball()
        if not Ball then
                return false
        end
        local Zoomies = Ball:FindFirstChild("zoomies")
        if not Zoomies then
                return false
        end
        local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        local Velocity = Zoomies.VectorVelocity
        local Ball_Direction = Velocity.Unit
        local playerPos = Player.Character.PrimaryPart.Position
        local ballPos = Ball.Position
        local Direction = (playerPos - ballPos).Unit
        local Dot = Direction:Dot(Ball_Direction)
        local Speed = Velocity.Magnitude
        local Speed_Threshold = math.min(Speed / 100, 40)

        local Angle_Threshold = 40 * math.max(Dot, 0) * math.clamp(Speed / 300, 0.3, 1.5)
        local Distance = (playerPos - ballPos).Magnitude
        local Reach_Time = Distance / Speed - (Ping / 1000)
        local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold
        table.insert(Previous_Velocity, Velocity)
        if #Previous_Velocity > 4 then
                table.remove(Previous_Velocity, 1)
        end
        if Ball:FindFirstChild("AeroDynamicSlashVFX") then
                Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                Tornado_Time = tick()
        end
        if Runtime:FindFirstChild("Tornado") then
                if (tick() - Tornado_Time) < ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then
                        return true
                end
        end
        local Enough_Speed = Speed > 160
        if Enough_Speed and Reach_Time > (Ping / 10 + 0.03) then
                if Speed < 300 then
                        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 13, 13)
                elseif Speed <= 600 then
                        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
                elseif Speed <= 1000 then
                        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 17, 17)
                else
                        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 19, 19)
                end
        end
        if Distance < Ball_Distance_Threshold then
                return false
        end
        local adjustedReachTime = Reach_Time + 0.03
        if Speed < 300 then
                if (tick() - Curving) < (adjustedReachTime / 1.15) then
                        return true
                end
        elseif Speed < 450 then
                if (tick() - Curving) < (adjustedReachTime / 1.18) then
                        return true
                end
        elseif Speed < 600 then
                if (tick() - Curving) < (adjustedReachTime / 1.3) then
                        return true
                end
        else
                if (tick() - Curving) < (adjustedReachTime / 1.45) then
                        return true
                end
        end
        local Dot_Threshold = (0 - Ping / 1000)
        local Direction_Difference = (Ball_Direction - Velocity.Unit)
        local Direction_Similarity = Direction:Dot(Direction_Difference.Unit)
        local Dot_Difference = Dot - Direction_Similarity
        if Dot_Difference < Dot_Threshold then
                return true
        end
        local Clamped_Dot = math.clamp(Dot, -1, 1)
        local Radians = math.deg(math.asin(Clamped_Dot))
        Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)
        if Speed < 300 then
                if Lerp_Radians < 0.015 then
                        Last_Warping = tick()
                end
                if (tick() - Last_Warping) < (adjustedReachTime / 1.15) then
                        return true
                end
        else
                if Lerp_Radians < 0.012 then
                        Last_Warping = tick()
                end
                if (tick() - Last_Warping) < (adjustedReachTime / 1.45) then
                        return true
                end
        end
        if #Previous_Velocity == 4 then
                for i = 1, 2 do
                        local prevDir = (Ball_Direction - Previous_Velocity[i].Unit).Unit
                        local prevDot = Direction:Dot(prevDir)
                        if (Dot - prevDot) < Dot_Threshold then
                                return true
                        end
                end
        end
        local backwardsCurveDetected = false
        local backwardsAngleThreshold = 60
        local horizDirection = Vector3.new(playerPos.X - ballPos.X, 0, playerPos.Z - ballPos.Z)
        if horizDirection.Magnitude > 0 then
                horizDirection = horizDirection.Unit
        end
        local awayFromPlayer = -horizDirection
        local horizBallDir = Vector3.new(Ball_Direction.X, 0, Ball_Direction.Z)
        if horizBallDir.Magnitude > 0 then
                horizBallDir = horizBallDir.Unit
                local backwardsAngle = math.deg(math.acos(math.clamp(awayFromPlayer:Dot(horizBallDir), -1, 1)))
                if backwardsAngle < backwardsAngleThreshold then
                        backwardsCurveDetected = true
                end
        end
        return (Dot < Dot_Threshold) or backwardsCurveDetected
end
function Auto_Parry:Get_Ball_Properties()
        local Ball = Auto_Parry.Get_Ball()
        local Ball_Velocity = Vector3.zero
        local Ball_Origin = Ball
        local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
        local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
        local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)
        return {
                Velocity = Ball_Velocity,
                Direction = Ball_Direction,
                Distance = Ball_Distance,
                Dot = Ball_Dot,
        }
end
function Auto_Parry.Spam_Service(self)
        local Ball = Auto_Parry.Get_Ball()
        local Entity = Auto_Parry.Closest_Player()
        if not Ball then
                return false
        end
        if not Entity or not Entity.PrimaryPart then
                return false
        end
        local Spam_Accuracy = 0
        local Velocity = Ball.AssemblyLinearVelocity
        local Speed = Velocity.Magnitude
        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
        local Dot = Direction:Dot(Velocity.Unit)
        local Target_Position = Entity.PrimaryPart.Position
        local Target_Distance = Player:DistanceFromCharacter(Target_Position)

        -- From reference: Maximum_Spam_Distance = Ping + min(Speed/6, 95)
        -- Faster balls = larger spam distance (up to 95)
        local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)

        if self.Entity_Properties.Distance > Maximum_Spam_Distance then
                return Spam_Accuracy
        end
        if self.Ball_Properties.Distance > Maximum_Spam_Distance then
                return Spam_Accuracy
        end
        if Target_Distance > Maximum_Spam_Distance then
                return Spam_Accuracy
        end

        -- From reference: Maximum_Speed = 5 - min(Speed/5, 5)
        -- Faster balls = smaller adjustment (more precise)
        local Maximum_Speed = 5 - math.min(Speed / 5, 5)

        -- From reference: Maximum_Dot = clamp(Dot, -1, 0) * Maximum_Speed
        -- Only negative dots (ball moving away from player) contribute
        local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed

        -- From reference: Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot
        -- Subtracting negative = adding (increases accuracy when ball moving away)
        Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot
        return Spam_Accuracy
end
local Connections_Manager = {}
local Selected_Parry_Type = nil
local Parried = false
local Last_Parry = 0
local deathshit = false
ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
        if d then
                deathshit = true
        else
                deathshit = false
        end
end)
local Infinity = false
ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        if b then
                Infinity = true
        else
                Infinity = false
        end
end)
local timehole = false
ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(e, f)
        if f then
                timehole = true
        else
                timehole = false
        end
end)
local AutoParry = true
local Balls = workspace:WaitForChild("Balls")
local CurrentBall = nil
local InputTask = nil
local Cooldown = 0
local RunTime = workspace:FindFirstChild("Runtime")
local function GetBall()
        for _, Ball in ipairs(Balls:GetChildren()) do
                if Ball:FindFirstChild("ff") then
                        return Ball
                end
        end
        return nil
end
local function SpamInput(Label)
        if InputTask then
                return
        end
        InputTask = task.spawn(function()
                while AutoParry do
                        Auto_Parry.Parry(Selected_Parry_Type)
                        task.wait(Cooldown)
                end
                InputTask = nil
        end)
end
Balls.ChildAdded:Connect(function(Value)
        Value.ChildAdded:Connect(function(Child)
                if getgenv().SlashOfFuryDetection and Child.Name == "ComboCounter" then
                        local Sof_Label = Child:FindFirstChildOfClass("TextLabel")
                        if Sof_Label then
                                repeat
                                        local Slashes_Counter = tonumber(Sof_Label.Text)
                                        if Slashes_Counter and Slashes_Counter < 32 then
                                                Auto_Parry.Parry(Selected_Parry_Type)
                                        end
                                        task.wait()
                                until not Sof_Label.Parent or not Sof_Label
                        end
                end
        end)
end)
local Players = game:GetService("Players")
local player10239123 = Players.LocalPlayer
local RunService = game:GetService("RunService")
if not player10239123 then
        return
end
RunTime.ChildAdded:Connect(function(Object)
        local Name = Object.Name
        if getgenv().PhantomV2Detection then
                if Name == "maxTransmission" or Name == "transmissionpart" then
                        local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
                        if Weld then
                                local Character = player10239123.Character or player10239123.CharacterAdded:Wait()
                                if Character and Weld.Part1 == Character.HumanoidRootPart then
                                        CurrentBall = GetBall()
                                        Weld:Destroy()
                                        if CurrentBall then
                                                local FocusConnection
                                                FocusConnection = RunService.RenderStepped:Connect(function()
                                                        local Highlighted = CurrentBall:GetAttribute("highlighted")
                                                        if Highlighted == true then
                                                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                                                if HumanoidRootPart then
                                                                        local PlayerPosition = HumanoidRootPart.Position
                                                                        local BallPosition = CurrentBall.Position
                                                                        local PlayerToBall = (BallPosition - PlayerPosition).Unit
                                                                        game.Players.LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                                                end
                                                        elseif Highlighted == false then
                                                                FocusConnection:Disconnect()
                                                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                                                task.delay(3, function()
                                                                        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                                                end)
                                                                CurrentBall = nil
                                                        end
                                                end)
                                                task.delay(3, function()
                                                        if FocusConnection and FocusConnection.Connected then
                                                                FocusConnection:Disconnect()
                                                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                                                CurrentBall = nil
                                                        end
                                                end)
                                        end
                                end
                        end
                end
        end
end)
local player11 = game.Players.LocalPlayer
local PlayerGui = player11:WaitForChild("PlayerGui")
local playerGui = player11:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")
local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient
local function isCooldownInEffect1(uigradient)
        return uigradient.Offset.Y < 0.4
end
local function isCooldownInEffect2(uigradient)
        return uigradient.Offset.Y >= 0.45 and uigradient.Offset.Y <= 0.55
end
local function cooldownProtection()
        if isCooldownInEffect1(ParryCD) then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire() end)
                return true
        end
        return false
end

-- ============================================================
-- SMART AUTO ABILITY v3 — Per-ability unique cooldowns
-- Each ability fires at its OWN unique timing (not a fixed timer)
-- Uses remote-based firing (same technique as Auto Parry)
-- ============================================================
local AbilityRemote = nil
local AbilityRawFunc = nil
local abilityHooked = false

local AutoAbilityData = {
    Enabled = false,
    LastAbilityName = nil,
}
getgenv().KERO_AutoAbility = AutoAbilityData

-- Per-ability UNIQUE fire timing (when the ability should activate, in seconds)
local ABILITY_TIMINGS = {
    ["Raging Deflection"] = { cooldown = 15, fireAt = 0.5, trigger = "target" },
    ["Calming Deflection"] = { cooldown = 15, fireAt = 1.2, trigger = "target" },
    ["Rapture"]            = { cooldown = 20, fireAt = 2.0, trigger = "proximity" },
    ["Aerodynamic Slash"]  = { cooldown = 12, fireAt = 0.8, trigger = "target" },
    ["Fracture"]           = { cooldown = 18, fireAt = 1.5, trigger = "proximity" },
    ["Death Slash"]        = { cooldown = 25, fireAt = 3.0, trigger = "clash" },
}
getgenv().KERO_AbilityTimings = ABILITY_TIMINGS

local _abilityLastFire = {}

-- Hook the AbilityButtonPress remote
task.spawn(function()
    task.wait(2)
    pcall(function()
        local abilRemote = ReplicatedStorage:WaitForChild("Remotes", 5):FindFirstChild("AbilityButtonPress")
        if abilRemote then
            if abilRemote:IsA("RemoteEvent") then
                AbilityRemote = abilRemote
                AbilityRawFunc = abilRemote.FireServer
                abilityHooked = true
            elseif abilRemote:IsA("RemoteFunction") then
                AbilityRemote = abilRemote
                AbilityRawFunc = abilRemote.InvokeServer
                abilityHooked = true
            end
        end
    end)
end)

local function fireAbilityRemote()
    if not AbilityRemote or not AbilityRawFunc then
        pcall(function()
            ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
        end)
        return true
    end
    pcall(function()
        AbilityRawFunc(AbilityRemote)
    end)
    return true
end

local function isAbilityReady()
    if not AbilityCD then return true end
    local offset = AbilityCD.Offset.Y
    return offset >= 0.45 and offset <= 0.55
end

local function isAbilityOffCooldown(abilityName)
    local timing = ABILITY_TIMINGS[abilityName]
    if not timing then return true end
    local lastFire = _abilityLastFire[abilityName] or 0
    return (tick() - lastFire) >= timing.cooldown
end

local function getEquippedAbility()
    local char = Player.Character
    if not char then return nil end
    local abilities = char:FindFirstChild("Abilities")
    if not abilities then return nil end
    for name, _ in pairs(ABILITY_TIMINGS) do
        local abil = abilities:FindFirstChild(name)
        if abil and (abil:GetAttribute("Equipped") or abil.Enabled == true) then
            return name
        end
    end
    for _, abil in ipairs(abilities:GetChildren()) do
        if abil:GetAttribute("Equipped") or abil.Enabled == true then
            return abil.Name
        end
    end
    local first = abilities:GetChildren()[1]
    return first and first.Name or nil
end
getgenv().KERO_GetEquippedAbility = getEquippedAbility

local _lastBallTargetTime = 0
local _lastClashTime = 0

local function smartAutoAbility()
    if not AutoAbilityData.Enabled then return false end
    if not isAbilityReady() then return false end

    local abilityName = getEquippedAbility()
    if not abilityName then return false end

    local timing = ABILITY_TIMINGS[abilityName]
    if not timing then
        task.spawn(function()
            local fired = fireAbilityRemote()
            if fired then
                AutoAbilityData.LastAbilityName = abilityName
                _abilityLastFire[abilityName] = tick()
            end
        end)
        return false  -- NEVER block parry
    end

    if not isAbilityOffCooldown(abilityName) then return false end

    local ball = Auto_Parry.Get_Ball()
    if not ball then return false end

    local target = ball:GetAttribute("target")
    local isTargeting = (target == tostring(Player))

    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local ballDist = 999
    if hrp and ball.Parent then
        ballDist = (ball.Position - hrp.Position).Magnitude
    end

    local shouldFire = false
    if timing.trigger == "target" then
        if isTargeting then
            if (tick() - _lastBallTargetTime) >= timing.fireAt then
                shouldFire = true
            end
        end
    elseif timing.trigger == "proximity" then
        if isTargeting and ballDist <= 40 then
            if (tick() - _lastBallTargetTime) >= timing.fireAt then
                shouldFire = true
            end
        end
    elseif timing.trigger == "clash" then
        if (tick() - _lastClashTime) <= 2 and (tick() - _lastClashTime) >= timing.fireAt then
            shouldFire = true
        end
    end

    if not shouldFire then return false end

    -- Fire ability asynchronously (non-blocking) — parry ALWAYS continues
    task.spawn(function()
        local fired = fireAbilityRemote()
        if fired then
            AutoAbilityData.LastAbilityName = abilityName
            _abilityLastFire[abilityName] = tick()
        end
    end)
    return false  -- NEVER block parry
end
getgenv().KERO_SmartAutoAbility = smartAutoAbility

task.spawn(function()
    while true do
        task.wait(0.05)
        local ball = Auto_Parry.Get_Ball()
        if ball then
            local target = ball:GetAttribute("target")
            if target == tostring(Player) then
                _lastBallTargetTime = tick()
            end
        end
    end
end)

pcall(function()
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
        if root and root.Parent and root.Parent ~= Player.Character then
            _lastClashTime = tick()
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        local abilityName = getEquippedAbility()
        if abilityName and isAbilityReady() and isAbilityOffCooldown(abilityName) then
            fireAbilityRemote()
            _abilityLastFire[abilityName] = tick()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if AutoAbilityData.Enabled then
            smartAutoAbility()
        end
    end
end)

        local module = rage:create_module({
                title = "Auto Parry",
                flag = "Auto_Parry",
                description = "Automatically parries ball",
                section = "left",
                callback = function(value)
                        if getgenv().AutoParryNotify then
                                if value then
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Auto Parry has been turned ON",
                                                duration = 3,
                                        })
                                else
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Auto Parry has been turned OFF",
                                                duration = 3,
                                        })
                                end
                        end
                        if value then
                                Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
                                        local One_Ball = Auto_Parry.Get_Ball()
                                        local Balls = Auto_Parry.Get_Balls()
                                        for _, Ball in pairs(Balls) do
                                                if not Ball then
                                                        return
                                                end
                                                local Zoomies = Ball:FindFirstChild("zoomies")
                                                if not Zoomies then
                                                        return
                                                end
                                                Ball:GetAttributeChangedSignal("target"):Once(function()
                                                        Parried = false
                                                end)
                                                if Parried then
                                                        return
                                                end
                                                local Ball_Target = Ball:GetAttribute("target")
                                                local One_Target = One_Ball:GetAttribute("target")
                                                local Velocity = Zoomies.VectorVelocity
                                                local Speed = Velocity.Magnitude
                                                local avgPing = (getgenv()._KERO_Tune and getgenv()._KERO_Tune.GetAveragePing()) or 0
                                                local pingSec = avgPing / 2000
                                                local pingStuds = avgPing / 10
                                                local playerPos = Player.Character.PrimaryPart.Position
                                                local ballPos = Ball.Position
                                                local playerVel = Player.Character.PrimaryPart.AssemblyLinearVelocity

                                                -- UPGRADE #1: Push velocity samples for Bezier/Quadratic prediction
                                                _KERO_pushVelSample("ball", ballPos, Velocity)
                                                _KERO_pushVelSample("player", playerPos, playerVel)

                                                -- UPGRADE #1: Quadratic + Bezier Future Position Prediction
                                                -- x(t) = x0 + v*t + 0.5*a*t^2 + Bezier extrapolation
                                                local Ball_Future_Position = _KERO_predictFuturePosition("ball", pingSec)
                                                local Player_Future_Position = _KERO_predictFuturePosition("player", pingSec)
                                                -- fallback لو الـ history لسه مش ممتلئة
                                                if not Ball_Future_Position then
                                                    Ball_Future_Position = ballPos + Velocity * pingSec
                                                end
                                                if not Player_Future_Position then
                                                    Player_Future_Position = playerPos + playerVel * pingSec
                                                end
                                                local Distance = (Player_Future_Position - Ball_Future_Position).Magnitude
                                                local Ping_Threshold = math.clamp(pingStuds / 8, 4, 25)

                                                -- UPGRADE #2: Logarithmic Adaptive Speed Divisor
                                                -- من: 2.4 + 0.002*(Speed-9.5)
                                                -- إلى: 2.2 + 0.9*ln(1 + Speed/80) — diminishing returns
                                                local speed_divisor_base = _KERO_calcSpeedDivisorBase(Speed)

                                                local effectiveMultiplier = Speed_Divisor_Multiplier
                                                if getgenv().RandomParryAccuracyEnabled then
                                                        if Speed < 200 then
                                                                effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                                                        else
                                                                effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                                                        end
                                                end
                                                local pingFactor = math.clamp(avgPing / 100, 0, 3.5)
                                                local pingDivisorAdjust = math.max(1.0 - 0.20 * pingFactor, 0.35)
                                                local speed_divisor = speed_divisor_base * effectiveMultiplier * pingDivisorAdjust
                                                local pingExtraStuds = pingFactor * 5
                                                local speedFactor = 1.0
                                                if Speed > 200 then
                                                        speedFactor = 1.0 + math.min((Speed - 200) / 1000, 0.3)
                                                end
                                                local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5) * speedFactor + pingExtraStuds
                                                if avgPing > 180 then
                                                        local safetyMult = 1.0 + math.min((avgPing - 180) / 350, 0.6)
                                                        Parry_Accuracy = Parry_Accuracy * safetyMult
                                                end
                                                local Curved = Auto_Parry.Is_Curved()
                                                if Ball:FindFirstChild("AeroDynamicSlashVFX") then
                                                        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                                                        Tornado_Time = tick()
                                                end
                                                if Runtime:FindFirstChild("Tornado") then
                                                        if
                                                                (tick() - Tornado_Time)
                                                                < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159
                                                        then
                                                                return
                                                        end
                                                end
                                                if One_Target == tostring(Player) and Curved then
                                                        return
                                                end
                                                if Ball:FindFirstChild("ComboCounter") then
                                                        return
                                                end
                                                local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild("SingularityCape")
                                                if Singularity_Cape then
                                                        return
                                                end
                                                if getgenv().InfinityDetection and Infinity then
                                                        return
                                                end
                                                if getgenv().DeathSlashDetection and deathshit then
                                                        return
                                                end
                                                if getgenv().TimeHoleDetection and timehole then
                                                        return
                                                end
                                                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                                                        if AutoAbilityData.Enabled and smartAutoAbility() then
                                                                return
                                                        end
                                                end
                                                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                                                        if getgenv().CooldownProtection and cooldownProtection() then
                                                                return
                                                        end
                                                        local Parry_Time = os.clock()
                                                        local Time_View = Parry_Time - Last_Parry
                                                        if Time_View > 0.5 then
                                                                Auto_Parry.Parry_Animation()
                                                        end
                                                        Auto_Parry.Parry(Selected_Parry_Type)
                                                        Last_Parry = Parry_Time
                                                        Parried = true
                                                end
                                                local Last_Parrys = tick()
                                                repeat
                                                        RunService.PreSimulation:Wait()
                                                until (tick() - Last_Parrys) >= 1 or not Parried
                                                Parried = false
                                        end
                                end)
                        else
                                if Connections_Manager["Auto Parry"] then
                                        Connections_Manager["Auto Parry"]:Disconnect()
                                        Connections_Manager["Auto Parry"] = nil
                                end
                        end
                end,
        })
        local parryTypeMap = {
                ["Camera"] = "Camera",
                ["Slowball"] = "Slowball",
        ["Fastball"] = "Fastball",
                ["Random"] = "Random",
                ["Backwards"] = "Backwards",
                ["Straight"] = "Straight",
                ["High"] = "High",
                ["Left"] = "Left",
                ["Right"] = "Right",
                ["Random Target"] = "RandomTarget",
        }
        local dropdown = module:create_dropdown({
                title = "Parry Type",
                flag = "Parry_Type",
                options = {
                        "Camera",
                        "Slowball",
            "Fastball",
                        "Random",
                        "Backwards",
                        "Straight",
                        "High",
                        "Left",
                        "Right",
                        "Random Target",
                },
                multi_dropdown = false,
                maximum_options = 8,
                callback = function(value)
                        Selected_Parry_Type = parryTypeMap[value] or value
                end,
        })
        local UserInputService = game:GetService("UserInputService")
        local parryOptions = {
                [Enum.KeyCode.One] = "Camera",
                [Enum.KeyCode.Two] = "Random",
                [Enum.KeyCode.Three] = "Backwards",
                [Enum.KeyCode.Four] = "Straight",
                [Enum.KeyCode.Five] = "High",
                [Enum.KeyCode.Six] = "Left",
                [Enum.KeyCode.Seven] = "Right",
                [Enum.KeyCode.Eight] = "Random Target",
                [Enum.KeyCode.Nine] = "Slowball",
        [Enum.KeyCode.Zero] = "Fastball",
        }
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then
                        return
                end
                if not getgenv().HotkeyParryType then
                        return
                end
                local newType = parryOptions[input.KeyCode]
                if newType then
                        Selected_Parry_Type = parryTypeMap[newType] or newType
                        dropdown:update(newType)
                        if getgenv().HotkeyParryTypeNotify then
                                Library.SendNotification({
                                        title = "Module Notification",
                                        text = "Parry Type changed to " .. newType,
                                        duration = 3,
                                })
                        end
                end
        end)
        module:create_slider({
                title = "Parry Accuracy",
                flag = "Parry_Accuracy",
                maximum_value = 100,
                minimum_value = -5,
                value = 100,
                round_number = true,
                callback = function(value)
                        Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
                end,
        })
        module:create_divider({})
        module:create_checkbox({
                title = "Randomized Parry Accuracy",
                flag = "Random_Parry_Accuracy",
                callback = function(value)
                        getgenv().RandomParryAccuracyEnabled = value
                        if value then
                                getgenv().RandomParryAccuracyEnabled = value
                        end
                end,
        })
        module:create_checkbox({
                title = "Anti Phantom",
                flag = "Anti_Phantom",
                callback = function(value)
                        getgenv().PhantomV2Detection = value
                end,
        })
        module:create_checkbox({
                title = "Auto Ability (Smart)",
                flag = "AutoAbility",
                callback = function(value)
                        AutoAbilityData.Enabled = value
                        getgenv().AutoAbility = value
                end,
        })
        module:create_checkbox({
                title = "Notify",
                flag = "Auto_Parry_Notify",
                callback = function(value)
                        getgenv().AutoParryNotify = value
                end,
        })
        module:create_checkbox({
                title = "Cooldown Protection",
                flag = "CooldownProtection",
                callback = function(value)
                        getgenv().CooldownProtection = value
                end,
        })
        local SpamParry = rage:create_module({
                title = "Auto Spam Parry",
                flag = "Auto_Spam_Parry",
                description = "Automatically spam parries ball",
                section = "right",
                callback = function(value)
                        if getgenv().AutoSpamNotify then
                                if value then
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Auto Spam Parry turned ON",
                                                duration = 3,
                                        })
                                else
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Auto Spam Parry turned OFF",
                                                duration = 3,
                                        })
                                end
                        end
                        if value then
                                Connections_Manager["Auto Spam"] = RunService.PreSimulation:Connect(function()
                                        local Ball = Auto_Parry.Get_Ball()
                                        if not Ball then
                                                return
                                        end
                                        local Zoomies = Ball:FindFirstChild("zoomies")
                                        if not Zoomies then
                                                return
                                        end
                                        Auto_Parry.Closest_Player()
                                        local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                                        local Ping_Threshold = math.clamp(Ping / 10, 1, 16)
                                        local Ball_Target = Ball:GetAttribute("target")
                                        local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                                        local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                                        local Spam_Accuracy = Auto_Parry.Spam_Service({
                                                Ball_Properties = Ball_Properties,
                                                Entity_Properties = Entity_Properties,
                                                Ping = Ping_Threshold,
                                        })
                                        local Target_Position = Closest_Entity.PrimaryPart.Position
                                        local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                                        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                                        local Ball_Direction = Zoomies.VectorVelocity.Unit
                                        local Dot = Direction:Dot(Ball_Direction)
                                        local Distance = Player:DistanceFromCharacter(Ball.Position)
                                        if not Ball_Target then
                                                return
                                        end
                                        if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                                                return
                                        end
                                        local Pulsed = Player.Character:GetAttribute("Pulsed")
                                        if Pulsed then
                                                return
                                        end
                                        if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                                                return
                                        end
                                        local threshold = ParryThreshold
                                        if Distance <= Spam_Accuracy and Parries > threshold then
                                                if Distance > Spam_Accuracy or Target_Distance > Spam_Accuracy then
                                                        return
                                                end
                                                if tick() - spamLastFire < spamParryCooldown then return end
                                                spamLastFire = tick()
                                                Auto_Parry.Parry(Selected_Parry_Type)
                                        end
                                end)
                        else
                                if Connections_Manager["Auto Spam"] then
                                        Connections_Manager["Auto Spam"]:Disconnect()
                                        Connections_Manager["Auto Spam"] = nil
                                end
                        end
                end,
        })
        local dropdown2 = SpamParry:create_dropdown({
                title = "Parry Type",
                flag = "Spam_Parry_Type",
                options = {
                        "Legit",
                        "Blatant",
                },
                multi_dropdown = false,
                maximum_options = 2,
                callback = function(value) end,
        })
        SpamParry:create_slider({
                title = "Parry Threshold",
                flag = "Parry_Threshold",
                maximum_value = 3,
                minimum_value = 1,
                value = 2.5,
                round_number = false,
                callback = function(value)
                        ParryThreshold = value
                end,
        })
        -- Spam Speed: controls the cooldown between parry attempts in Auto Spam
        SpamParry:create_slider({
                title = "Spam Speed (CPS Control)",
                flag = "Spam_Speed_CPS",
                maximum_value = 100,
                minimum_value = 1,
                value = 50,
                round_number = true,
                callback = function(value)
                        -- Higher value = faster (less cooldown). Convert to seconds.
                        -- 100 = ~0.01s cooldown (max speed), 1 = ~1s cooldown (slow)
                        spamParryCooldown = 1.0 / value
                end,
        })
        SpamParry:create_divider({})
        if not isMobile then
                local AnimationFix = SpamParry:create_checkbox({
                        title = "Animation Fix",
                        flag = "AnimationFix",
                        callback = function(value)
                                if value then
                                        Connections_Manager["Animation Fix"] = RunService.PreSimulation:Connect(function()
                                                local Ball = Auto_Parry.Get_Ball()
                                                if not Ball then
                                                        return
                                                end
                                                local Zoomies = Ball:FindFirstChild("zoomies")
                                                if not Zoomies then
                                                        return
                                                end
                                                Auto_Parry.Closest_Player()
                                                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                                                local Ping_Threshold = math.clamp(Ping / 10, 1, 16)
                                                local Ball_Target = Ball:GetAttribute("target")
                                                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                                                local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                                                local Spam_Accuracy = Auto_Parry.Spam_Service({
                                                        Ball_Properties = Ball_Properties,
                                                        Entity_Properties = Entity_Properties,
                                                        Ping = Ping_Threshold,
                                                })
                                                local Target_Position = Closest_Entity.PrimaryPart.Position
                                                local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                                                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                                                local Ball_Direction = Zoomies.VectorVelocity.Unit
                                                local Dot = Direction:Dot(Ball_Direction)
                                                local Distance = Player:DistanceFromCharacter(Ball.Position)
                                                if not Ball_Target then
                                                        return
                                                end
                                                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                                                        return
                                                end
                                                local Pulsed = Player.Character:GetAttribute("Pulsed")
                                                if Pulsed then
                                                        return
                                                end
                                                if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                                                        return
                                                end
                                                local threshold = ParryThreshold
                                                if Distance <= Spam_Accuracy and Parries > threshold then
                                                        if Distance > Spam_Accuracy or Target_Distance > Spam_Accuracy then
                                                                return
                                                        end
                                                        if tick() - (Last_Parry or 0) < 0.1 then
                                                                return
                                                        end
                                                        Last_Parry = tick()
                                                        Auto_Parry.Parry(Selected_Parry_Type)
                                                end
                                        end)
                                else
                                        if Connections_Manager["Animation Fix"] then
                                                Connections_Manager["Animation Fix"]:Disconnect()
                                                Connections_Manager["Animation Fix"] = nil
                                        end
                                end
                        end,
                })
                AnimationFix:change_state(true)
        end
        SpamParry:create_checkbox({
                title = "Notify",
                flag = "Auto_Spam_Parry_Notify",
                callback = function(value)
                        getgenv().AutoSpamNotify = value
                end,
        })
        local infinityDetectionModule = detec:create_module({
    title = "Infinity Detection",
    flag = "InfinityDetectionModule",
    description = "Toggle Infinity Ball detection",
    section = "left",
    callback = function(value)
        getgenv().InfinityDetection = value
    end,
})

local dribbleDetectionModule = detec:create_module({
    title = "Dribble Detection",
    flag = "DribbleDetectionModule",
    description = "Toggle Dribble Ball detection",
    section = "right",
    callback = function(value)
        getgenv().DribbleDetection = value
    end,
})

local deathSlashDetectionModule = detec:create_module({
    title = "Death Slash Detection",
    flag = "DeathSlashDetectionModule",
    description = "Toggle Death Slash detection",
    section = "left",
    callback = function(state)
    end
})

local timeHoleDetectionModule = detec:create_module({
    title = "Time Hole Detection",
    flag = "TimeHoleDetectionModule",
    description = "Toggle Time Hole detection",
    section = "right",
    callback = function(value)
        getgenv().TimeHoleDetection = value
    end,
})

local slashOfFuryDetectionModule = detec:create_module({
    title = "Slash Of Fury Detection",
    flag = "SlashOfFuryDetectionModule",
    description = "Toggle Slash Of Fury detection",
    section = "left",
    callback = function(value)
        getgenv().SlashOfFuryDetection = value
    end,
})
        local ManualSpam = rage:create_module({
                title = "Manual Spam Parry",
                flag = "Manual_Spam_Parry",
                description = "Manually Spams Parry",
                section = "right",
                callback = function(value)
                        if getgenv().ManualSpamNotify then
                                if value then
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Manual Spam Parry turned ON",
                                                duration = 3,
                                        })
                                else
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Manual Spam Parry turned OFF",
                                                duration = 3,
                                        })
                                end
                        end
                        if value then
                                Connections_Manager["Manual Spam"] = RunService.PreSimulation:Connect(function()
                                        if getgenv().spamui then
                                                return
                                        end
                                        Auto_Parry.Parry(Selected_Parry_Type)
                                end)
                        else
                                if Connections_Manager["Manual Spam"] then
                                        Connections_Manager["Manual Spam"]:Disconnect()
                                        Connections_Manager["Manual Spam"] = nil
                                end
                        end
                end,
        })

       ManualSpam:create_checkbox({
                title = "UI",
                flag = "Manual_Spam_UI",
                callback = function(value)
                        getgenv().spamui = value

                        if value then
                                local UIS = game:GetService("UserInputService")
                                local CoreGui = game:GetService("CoreGui")
                                
                                local Gui = Instance.new("ScreenGui")
                                Gui.Name = "ManualSpamGUI"
                                Gui.ResetOnSpawn = false
                                pcall(function()
                                        Gui.Parent = CoreGui
                                end)
                                
                                local Button = Instance.new("TextButton")
                                Button.Name = "ManualSpam"
                                Button.Parent = Gui
                                Button.Size = UDim2.new(0, 160, 0, 52)
                                Button.Position = UDim2.new(0.75, 0, 0.7, 0)
                                Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                                Button.BorderSizePixel = 0
                                Button.AutoButtonColor = false
                                Button.Text = "Manual Spam"
                                Button.TextColor3 = Color3.fromRGB(220, 220, 220)
                                Button.TextSize = 16
                                Button.Font = Enum.Font.GothamSemibold
                                
                                local Corner = Instance.new("UICorner")
                                Corner.CornerRadius = UDim.new(0, 10)
                                Corner.Parent = Button
                                
                                local Stroke = Instance.new("UIStroke")
                                Stroke.Parent = Button
                                Stroke.Color = Color3.fromRGB(60, 60, 60)
                                Stroke.Thickness = 1
                                
                                local dragging = false
                                local dragInput
                                local dragStart
                                local startPos
                                local touchStart = 0
                                local wasDragged = false
                                
                                local function update(input)
                                        local delta = input.Position - dragStart
                                        Button.Position = UDim2.new(
                                                startPos.X.Scale,
                                                startPos.X.Offset + delta.X,
                                                startPos.Y.Scale,
                                                startPos.Y.Offset + delta.Y
                                        )
                                end
                                
                                Button.InputBegan:Connect(function(input)
                                        if input.UserInputType == Enum.UserInputType.Touch
                                        or input.UserInputType == Enum.UserInputType.MouseButton1 then
                                                
                                                dragging = true
                                                dragStart = input.Position
                                                startPos = Button.Position
                                                touchStart = tick()
                                                wasDragged = false
                                                
                                                input.Changed:Connect(function()
                                                        if input.UserInputState == Enum.UserInputState.End then
                                                                dragging = false
                                                        end
                                                end)
                                        end
                                end)
                                
                                Button.InputChanged:Connect(function(input)
                                        if input.UserInputType == Enum.UserInputType.Touch
                                        or input.UserInputType == Enum.UserInputType.MouseMovement then
                                                dragInput = input
                                                
                                                if (tick() - touchStart) > 0.1 then
                                                        wasDragged = true
                                                end
                                        end
                                end)
                                
                                UIS.InputChanged:Connect(function(input)
                                        if dragging and input == dragInput then
                                                update(input)
                                        end
                                end)
                                
                                local uiEnabled = false
                                local cpsCounter = 0
                                local cpsTimer = tick()
                                
                                Button.MouseButton1Click:Connect(function()
                                        if wasDragged then
                                                return
                                        end
                                        
                                        uiEnabled = not uiEnabled
                                        
                                        if uiEnabled then
                                                Button.Text = "manual spam : ON"
                                                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                                                Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                                                
                                                cpsCounter = 0
                                                cpsTimer = tick()
                                                
                                                Connections_Manager["Manual Spam UI"] = game:GetService("RunService").Heartbeat:Connect(function()
                                                        Auto_Parry.Parry(Selected_Parry_Type)
                                                        
                                                        cpsCounter = cpsCounter + 1
                                                        if tick() - cpsTimer >= 1 then
                                                                cpsCounter = 0
                                                                cpsTimer = tick()
                                                        end
                                                end)
                                        else
                                                Button.Text = "Manual Spam"
                                                Button.TextColor3 = Color3.fromRGB(220, 220, 220)
                                                Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                                                
                                                if Connections_Manager["Manual Spam UI"] then
                                                        Connections_Manager["Manual Spam UI"]:Disconnect()
                                                        Connections_Manager["Manual Spam UI"] = nil
                                                end
                                                
                                                cpsCounter = 0
                                        end
                                end)
                                
                        else
                                local existingUI = CoreGui:FindFirstChild("ManualSpamGUI")
                                if existingUI then
                                        existingUI:Destroy()
                                end
                                if Connections_Manager["Manual Spam UI"] then
                                        Connections_Manager["Manual Spam UI"]:Disconnect()
                                        Connections_Manager["Manual Spam UI"] = nil
                                end
                        end
                end,
        })

if not isMobile then
        local AnimationFix = ManualSpam:create_checkbox({
                title = "Animation Fix",
                flag = "AnimationFix",
                callback = function(value)
                        if value then
                                Connections_Manager["Animation Fix"] = RunService.PreSimulation:Connect(function()
                                        local Ball = Auto_Parry.Get_Ball()
                                        if not Ball then
                                                return
                                        end
                                        local Zoomies = Ball:FindFirstChild("zoomies")
                                        if not Zoomies then
                                                return
                                        end
                                        Auto_Parry.Closest_Player()
                                        local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                                        local Ping_Threshold = math.clamp(Ping / 10, 1, 16)
                                        local Ball_Target = Ball:GetAttribute("target")
                                        local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                                        local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                                        local Spam_Accuracy = Auto_Parry.Spam_Service({
                                                Ball_Properties = Ball_Properties,
                                                Entity_Properties = Entity_Properties,
                                                Ping = Ping_Threshold,
                                        })
                                        local Target_Position = Closest_Entity.PrimaryPart.Position
                                        local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                                        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                                        local Ball_Direction = Zoomies.VectorVelocity.Unit
                                        local Dot = Direction:Dot(Ball_Direction)
                                        local Distance = Player:DistanceFromCharacter(Ball.Position)
                                        if not Ball_Target then
                                                return
                                        end
                                        if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                                                return
                                        end
                                        local Pulsed = Player.Character:GetAttribute("Pulsed")
                                        if Pulsed then
                                                return
                                        end
                                        if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                                                return
                                        end
                                        local threshold = ParryThreshold
                                        if Distance <= Spam_Accuracy and Parries > threshold then
                                                if Distance > Spam_Accuracy or Target_Distance > Spam_Accuracy then
                                                        return
                                                end
                                                if tick() - (Last_Parry or 0) < 0.1 then
                                                        return
                                                end
                                                Last_Parry = tick()
                                                Auto_Parry.Parry(Selected_Parry_Type)
                                        end
                                end)
                        else
                                if Connections_Manager["Animation Fix"] then
                                        Connections_Manager["Animation Fix"]:Disconnect()
                                        Connections_Manager["Animation Fix"] = nil
                                end
                        end
                end,
        })
        AnimationFix:change_state(true)
end

        ManualSpam:create_checkbox({
                title = "Notify",
                flag = "Manual_Spam_Parry_Notify",
                callback = function(value)
                        getgenv().ManualSpamNotify = value
                end,
        })
        local Triggerbot = rage2:create_module({
                title = "Triggerbot",
                flag = "Triggerbot",
                description = "Instantly hits ball when targeted",
                section = "left",
                callback = function(value)
                        if getgenv().TriggerbotNotify then
                                if value then
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Triggerbot turned ON",
                                                duration = 3,
                                        })
                                else
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Triggerbot turned OFF",
                                                duration = 3,
                                        })
                                end
                        end
                        if value then
                                Connections_Manager["Triggerbot"] = RunService.PreSimulation:Connect(function()
                                        local Balls = Auto_Parry.Get_Balls()
                                        for _, Ball in pairs(Balls) do
                                                if not Ball then
                                                        return
                                                end
                                                Ball:GetAttributeChangedSignal("target"):Once(function()
                                                        TriggerbotParried = false
                                                end)
                                                if TriggerbotParried then
                                                        return
                                                end
                                                local Ball_Target = Ball:GetAttribute("target")
                                                local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild("SingularityCape")
                                                if Singularity_Cape then
                                                        return
                                                end
                                                if getgenv().TriggerbotInfinityDetection and Infinity then
                                                        return
                                                end
                                                if Ball_Target == tostring(Player) then
                                                        Auto_Parry.Parry(Selected_Parry_Type)
                                                        TriggerbotParried = true
                                                end
                                                local Triggerbot_Last_Parrys = tick()
                                                repeat
                                                        RunService.PreSimulation:Wait()
                                                until (tick() - Triggerbot_Last_Parrys) >= 1 or not TriggerbotParried
                                                TriggerbotParried = false
                                        end
                                end)
                        else
                                if Connections_Manager["Triggerbot"] then
                                        Connections_Manager["Triggerbot"]:Disconnect()
                                        Connections_Manager["Triggerbot"] = nil
                                end
                        end
                end,
        })
        Triggerbot:create_checkbox({
                title = "Notify",
                flag = "TriggerbotNotify",
                callback = function(value)
                        getgenv().TriggerbotNotify = value
                end,
        })
        local parryTypeList = {
                "Camera",
                "Random",
                "Backwards",
                "Straight",
                "High",
                "Left",
                "Right",
                "Random Target",
                "Slowball",
                "Fastball",
        }
        local currentIndex = 1
        local HotkeyParryType = rage2:create_module({
                title = "Hotkey Parry Type [PC]",
                flag = "HotkeyParryType",
                description = "Allows Hotkey Parry Type",
                section = "right",
                callback = function(value)
                        getgenv().HotkeyParryType = value
                end,
        })
        HotkeyParryType:create_checkbox({
                title = "Notify",
                flag = "HotkeyParryTypeNotify",
                callback = function(value)
                        getgenv().HotkeyParryTypeNotify = value
                end,
        })
        local SetCurveModule = rage2:create_module({
                title = "Button select curve",
                flag = "SetCurveModule",
                description = "Enable UI to click and change parry type",
                section = "left",
                callback = function(value)
                        if value then
                                local gui = Instance.new("ScreenGui")
                                gui.Name = "SetCurveUI"
                                gui.ResetOnSpawn = false
                                gui.Parent = game.CoreGui
                                local frame = Instance.new("Frame")
                                frame.Name = "MainFrame"
                                frame.Position = UDim2.new(0, 20, 0, 20)
                                frame.Size = UDim2.new(0, 200, 0, 100)
                                frame.BackgroundColor3 = Color3.fromRGB(140, 25, 25)
                                frame.BackgroundTransparency = 0.25
                                frame.BorderSizePixel = 0
                                frame.Active = true
                                frame.Draggable = true
                                frame.Parent = gui
                                local uiCorner = Instance.new("UICorner")
                                uiCorner.CornerRadius = UDim.new(0, 12)
                                uiCorner.Parent = frame
                                local uiStroke = Instance.new("UIStroke")
                                uiStroke.Thickness = 2
                                uiStroke.Color = Color3.fromRGB(200, 50, 50)
                                uiStroke.Transparency = 0.2
                                uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                uiStroke.Parent = frame
                                local uiGradient = Instance.new("UIGradient")
                                uiGradient.Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 40, 40)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 5, 5)),
                                })
                                uiGradient.Rotation = 0
                                uiGradient.Parent = frame
                                local button = Instance.new("TextButton")
                                button.Name = "SetCurveButton"
                                button.Text = "Set Curve"
                                button.Size = UDim2.new(0, 160, 0, 40)
                                button.Position = UDim2.new(0.5, -80, 0.5, -20)
                                button.BackgroundTransparency = 1
                                button.BorderSizePixel = 0
                                button.Font = Enum.Font.GothamSemibold
                                button.TextColor3 = Color3.fromRGB(255, 80, 80)
                                button.TextSize = 22
                                button.Parent = frame
                                button.MouseButton1Click:Connect(function()
                                        currentIndex += 1
                                        if currentIndex > #parryTypeList then
                                                currentIndex = 1
                                        end
                                        local newType = parryTypeList[currentIndex]
                                        Selected_Parry_Type = parryTypeMap and parryTypeMap[newType] or newType
                                        if dropdown and dropdown.update then
                                                dropdown:update(newType)
                                        end
                                        button.Text = newType
                                        if getgenv().HotkeyParryTypeNotify then
                                                Library.SendNotification({
                                                        title = "Module Notification",
                                                        text = "Parry Type changed to " .. newType,
                                                        duration = 3,
                                                })
                                        end
                                end)
                        else
                                local existing = game.CoreGui:FindFirstChild("SetCurveUI")
                                if existing then
                                        existing:Destroy()
                                end
                        end
                end,
        })
        local LobbyAP = rage:create_module({
                title = "Lobby AP",
                flag = "Lobby_AP",
                description = "Auto parries ball in lobby",
                section = "right",
                callback = function(state)
                        if getgenv().LobbyAPNotify then
                                if state then
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Lobby AP has been turned ON",
                                                duration = 3,
                                        })
                                else
                                        Library.SendNotification({
                                                title = "Module Notification",
                                                text = "Lobby AP has been turned OFF",
                                                duration = 3,
                                        })
                                end
                        end
                        if state then
                                Connections_Manager["Lobby AP"] = RunService.PreSimulation:Connect(function()
                                        local Ball = Auto_Parry.Lobby_Balls()
                                        if not Ball then
                                                return
                                        end
                                        local Zoomies = Ball:FindFirstChild("zoomies")
                                        if not Zoomies then
                                                return
                                        end
                                        Ball:GetAttributeChangedSignal("target"):Once(function()
                                                Training_Parried = false
                                        end)
                                        if Training_Parried then
                                                return
                                        end
                                        local Ball_Target = Ball:GetAttribute("target")
                                        local Velocity = Zoomies.VectorVelocity
                                        local Speed = Velocity.Magnitude
                                        local avgPing = (getgenv()._KERO_Tune and getgenv()._KERO_Tune.GetAveragePing()) or 0
                                        local pingSec = avgPing / 2000
                                        local pingStuds = avgPing / 10
                                        local playerPos = Player.Character.PrimaryPart.Position
                                        local ballPos = Ball.Position
                                        local playerVel = Player.Character.PrimaryPart.AssemblyLinearVelocity

                                        -- UPGRADE #1: Push velocity samples for Bezier/Quadratic prediction
                                        _KERO_pushVelSample("ball", ballPos, Velocity)
                                        _KERO_pushVelSample("player", playerPos, playerVel)

                                        -- UPGRADE #1: Quadratic + Bezier Future Position Prediction
                                        local Ball_Future_Position = _KERO_predictFuturePosition("ball", pingSec)
                                        local Player_Future_Position = _KERO_predictFuturePosition("player", pingSec)
                                        if not Ball_Future_Position then
                                            Ball_Future_Position = ballPos + Velocity * pingSec
                                        end
                                        if not Player_Future_Position then
                                            Player_Future_Position = playerPos + playerVel * pingSec
                                        end
                                        local Distance = (Player_Future_Position - Ball_Future_Position).Magnitude

                                        -- UPGRADE #2: Logarithmic Adaptive Speed Divisor
                                        local LobbyAPspeed_divisor_base = _KERO_calcSpeedDivisorBase(Speed)

                                        local LobbyAPeffectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier
                                        if getgenv().LobbyAPRandomParryAccuracyEnabled then
                                                LobbyAPeffectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                                        end
                                        local pingFactor = math.clamp(avgPing / 100, 0, 3.5)
                                        local pingDivisorAdjust = math.max(1.0 - 0.20 * pingFactor, 0.35)
                                        local LobbyAPspeed_divisor = LobbyAPspeed_divisor_base * LobbyAPeffectiveMultiplier * pingDivisorAdjust
                                        local pingExtraStuds = pingFactor * 5
                                        local speedFactor = 1.0
                                        if Speed > 200 then
                                                speedFactor = 1.0 + math.min((Speed - 200) / 1000, 0.3)
                                        end
                                        local LobbyAPParry_Accuracys = pingStuds + math.max(Speed / LobbyAPspeed_divisor, 9.5) * speedFactor + pingExtraStuds
                                        if avgPing > 180 then
                                                local safetyMult = 1.0 + math.min((avgPing - 180) / 350, 0.6)
                                                LobbyAPParry_Accuracys = LobbyAPParry_Accuracys * safetyMult
                                        end
                                        local LobbyIsCurved = false
                                        if Speed > 100 then
                                                local ballDir = Velocity.Unit
                                                local toPlayer = (playerPos - ballPos).Unit
                                                local dot = ballDir:Dot(toPlayer)
                                                if dot < -0.1 then
                                                        LobbyIsCurved = true
                                                end
                                                if #Previous_Velocity >= 2 then
                                                        local prevVel = Previous_Velocity[#Previous_Velocity]
                                                        local prevDir = prevVel.Unit
                                                        local dirChange = (ballDir - prevDir).Magnitude
                                                        if dirChange > 0.05 then
                                                                LobbyIsCurved = true
                                                        end
                                                end
                                        end
                                        table.insert(Previous_Velocity, Velocity)
                                        if #Previous_Velocity > 4 then
                                                table.remove(Previous_Velocity, 1)
                                        end
                                        if LobbyIsCurved then
                                                local curveReduction = 38
                                                if Speed > 600 then curveReduction = 58
                                                elseif Speed > 300 then curveReduction = 48 end
                                                LobbyAPParry_Accuracys = math.max(LobbyAPParry_Accuracys - curveReduction, 5)
                                        end
                                        if Speed > 50 then
                                                local Approach_Dot = (playerPos - ballPos).Unit:Dot(Velocity.Unit)
                                                if Approach_Dot < -0.3 then
                                                        return
                                                end
                                        end
                                        if Ball_Target == tostring(Player) and Distance <= LobbyAPParry_Accuracys then
                                                local Parry_Time = os.clock()
                                                local Time_View = Parry_Time - Last_Parry
                                                if Time_View > 0.4 then
                                                        Auto_Parry.Parry_Animation()
                                                end
                                                Auto_Parry.Parry(Selected_Parry_Type)
                                                Last_Parry = Parry_Time
                                                Training_Parried = true
                                        end
                                        local Last_Parrys = tick()
                                        repeat
                                                RunService.PreSimulation:Wait()
                                        until (tick() - Last_Parrys) >= 1 or not Training_Parried
                                        Training_Parried = false
                                end)
                        else
                                if Connections_Manager["Lobby AP"] then
                                        Connections_Manager["Lobby AP"]:Disconnect()
                                        Connections_Manager["Lobby AP"] = nil
                                end
                        end
                end,
        })
        LobbyAP:create_slider({
                title = "Parry Accuracy",
                flag = "Parry_Accuracy",
                maximum_value = 100,
                minimum_value = -5,
                value = 100,
                round_number = true,
                callback = function(value)
                        LobbyAP_Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.325 / 99)
                end,
        })
        LobbyAP:create_divider({})
        LobbyAP:create_checkbox({
                title = "Randomized Parry Accuracy",
                flag = "Random_Parry_Accuracy",
                callback = function(value)
                        getgenv().LobbyAPRandomParryAccuracyEnabled = value
                end,
        })
        LobbyAP:create_checkbox({
                title = "Notify",
                flag = "Lobby_AP_Notify",
                callback = function(value)
                        getgenv().LobbyAPNotify = value
                end,
        })
        local StrafeSpeed = 36
        local Strafe = player:create_module({
                title = "Speed",
                flag = "Speed",
                description = "Changes character speed",
                section = "left",
                callback = function(value)
                        if value then
                                Connections_Manager["Strafe"] = game:GetService("RunService").PreSimulation:Connect(function()
                                        local character = game.Players.LocalPlayer.Character
                                        if character and character:FindFirstChild("Humanoid") then
                                                character.Humanoid.WalkSpeed = StrafeSpeed
                                        end
                                end)
                        else
                                local character = game.Players.LocalPlayer.Character
                                if character and character:FindFirstChild("Humanoid") then
                                        character.Humanoid.WalkSpeed = 36
                                end
                                if Connections_Manager["Strafe"] then
                                        Connections_Manager["Strafe"]:Disconnect()
                                        Connections_Manager["Strafe"] = nil
                                end
                        end
                end,
        })
        Strafe:create_slider({
                title = "Strafe Speed",
                flag = "Strafe_Speed",
                minimum_value = 36,
                maximum_value = 200,
                value = 36,
                round_number = true,
                callback = function(value)
                        StrafeSpeed = value
                end,
        })
        local Spinbot = player:create_module({
                title = "Spinbot",
                flag = "Spinbot",
                description = "Spins Player",
                section = "right",
                callback = function(value)
                        getgenv().Spinbot = value
                        if value then
                                getgenv().spin = true
                                getgenv().spinSpeed = getgenv().spinSpeed or 1
                                local Players = game:GetService("Players")
                                local RunService = game:GetService("RunService")
                                local Client = Players.LocalPlayer
                                local function spinCharacter()
                                        while getgenv().spin do
                                                RunService.PreSimulation:Wait()
                                                local char = Client.Character
                                                local funcHRP = char and char:FindFirstChild("HumanoidRootPart")
                                                if char and funcHRP then
                                                        funcHRP.CFrame *= CFrame.Angles(0, getgenv().spinSpeed, 0)
                                                end
                                        end
                                end
                                if not getgenv().spinThread then
                                        getgenv().spinThread = coroutine.create(spinCharacter)
                                        coroutine.resume(getgenv().spinThread)
                                end
                        else
                                getgenv().spin = false
                                if getgenv().spinThread then
                                        getgenv().spinThread = nil
                                end
                        end
                end,
        })
        Spinbot:create_slider({
                title = "Spinbot Speed",
                flag = "Spinbot_Speed",
                maximum_value = 100,
                minimum_value = 1,
                value = 1,
                round_number = true,
                callback = function(value)
                        getgenv().spinSpeed = math.rad(value)
                end,
        })
        local CameraToggle = player:create_module({
                title = "Field of View",
                flag = "Field_Of_View",
                description = "Changes Camera POV",
                section = "left",
                callback = function(value)
                        getgenv().CameraEnabled = value
                        local Camera = game:GetService("Workspace").CurrentCamera
                        if value then
                                getgenv().CameraFOV = getgenv().CameraFOV or 70
                                Camera.FieldOfView = getgenv().CameraFOV
                                if not getgenv().FOVLoop then
                                        getgenv().FOVLoop = game:GetService("RunService").RenderStepped:Connect(function()
                                                if getgenv().CameraEnabled then
                                                        Camera.FieldOfView = getgenv().CameraFOV
                                                end
                                        end)
                                end
                        else
                                Camera.FieldOfView = 70
                                if getgenv().FOVLoop then
                                        getgenv().FOVLoop:Disconnect()
                                        getgenv().FOVLoop = nil
                                end
                        end
                end,
        })
        CameraToggle:create_slider({
                title = "Camera FOV",
                flag = "Camera_FOV",
                maximum_value = 120,
                minimum_value = 50,
                value = 70,
                round_number = true,
                callback = function(value)
                        getgenv().CameraFOV = value
                        if getgenv().CameraEnabled then
                                game:GetService("Workspace").CurrentCamera.FieldOfView = value
                        end
                end,
        })
        local Animations = player:create_module({
                title = "Emotes",
                flag = "Emotes",
                description = "Custom Emotes",
                section = "right",
                callback = function(value)
                        getgenv().Animations = value
                        if value then
                                Connections_Manager["Animations"] = RunService.PreSimulation:Connect(function()
                                        if not Player.Character or not Player.Character.PrimaryPart then
                                                return
                                        end
                                        local Speed = Player.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude
                                        if Speed > 30 then
                                                if Animation.track and not getgenv().LoopEmote then
                                                        Animation.track:Stop()
                                                        Animation.track:Destroy()
                                                        Animation.track = nil
                                                end
                                        else
                                                if not Animation.track and Animation.current then
                                                        Auto_Parry.Play_Animation(Animation.current)
                                                end
                                        end
                                end)
                        else
                                if Animation.track then
                                        Animation.track:Stop()
                                        Animation.track:Destroy()
                                        Animation.track = nil
                                end
                                if Connections_Manager["Animations"] then
                                        Connections_Manager["Animations"]:Disconnect()
                                        Connections_Manager["Animations"] = nil
                                end
                        end
                end,
        })
        Animations:create_checkbox({
                title = "Loop Emote",
                flag = "Loop_Emote",
                default = false,
                callback = function(value)
                        getgenv().LoopEmote = value
                end,
        })
        local selected_animation = Emotes_Data[1]
        local AnimationChoice = Animations:create_dropdown({
                title = "Animation Type",
                flag = "Selected_Animation",
                options = Emotes_Data,
                multi_dropdown = false,
                maximum_options = #Emotes_Data,
                callback = function(value)
                        selected_animation = value
                        if getgenv().Animations then
                                Auto_Parry.Play_Animation(value)
                        end
                end,
        })
        AnimationChoice:update(selected_animation)
        _G.PlayerCosmeticsCleanup = {}
        local PlayerCosmetics = player:create_module({
                title = "Player Cosmetics",
                flag = "Player_Cosmetics",
                description = "Apply headless and korblox",
                section = "left",
                callback = function(value)
                        local players = game:GetService("Players")
                        local lp = players.LocalPlayer
                        local function applyKorblox(character)
                                local rightLeg = character:FindFirstChild("RightLeg") or character:FindFirstChild("Right Leg")
                                if not rightLeg then
                                        warn("Right leg not found on character")
                                        return
                                end
                                for _, child in pairs(rightLeg:GetChildren()) do
                                        if child:IsA("SpecialMesh") then
                                                child:Destroy()
                                        end
                                end
                                local specialMesh = Instance.new("SpecialMesh")
                                specialMesh.MeshId = "rbxassetid://101851696"
                                specialMesh.TextureId = "rbxassetid://115727863"
                                specialMesh.Scale = Vector3.new(1, 1, 1)
                                specialMesh.Parent = rightLeg
                        end
                        local function saveRightLegProperties(char)
                                if char then
                                        local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                                        if rightLeg then
                                                local originalMesh = rightLeg:FindFirstChildOfClass("SpecialMesh")
                                                if originalMesh then
                                                        _G.PlayerCosmeticsCleanup.originalMeshId = originalMesh.MeshId
                                                        _G.PlayerCosmeticsCleanup.originalTextureId = originalMesh.TextureId
                                                        _G.PlayerCosmeticsCleanup.originalScale = originalMesh.Scale
                                                else
                                                        _G.PlayerCosmeticsCleanup.hadNoMesh = true
                                                end
                                                _G.PlayerCosmeticsCleanup.rightLegChildren = {}
                                                for _, child in pairs(rightLeg:GetChildren()) do
                                                        if child:IsA("SpecialMesh") then
                                                                table.insert(_G.PlayerCosmeticsCleanup.rightLegChildren, {
                                                                        ClassName = child.ClassName,
                                                                        Properties = {
                                                                                MeshId = child.MeshId,
                                                                                TextureId = child.TextureId,
                                                                                Scale = child.Scale,
                                                                        },
                                                                })
                                                        end
                                                end
                                        end
                                end
                        end
                        local function restoreRightLeg(char)
                                if char then
                                        local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                                        if rightLeg and _G.PlayerCosmeticsCleanup.rightLegChildren then
                                                for _, child in pairs(rightLeg:GetChildren()) do
                                                        if child:IsA("SpecialMesh") then
                                                                child:Destroy()
                                                        end
                                                end
                                                if _G.PlayerCosmeticsCleanup.hadNoMesh then
                                                        return
                                                end
                                                for _, childData in ipairs(_G.PlayerCosmeticsCleanup.rightLegChildren) do
                                                        if childData.ClassName == "SpecialMesh" then
                                                                local newMesh = Instance.new("SpecialMesh")
                                                                newMesh.MeshId = childData.Properties.MeshId
                                                                newMesh.TextureId = childData.Properties.TextureId
                                                                newMesh.Scale = childData.Properties.Scale
                                                                newMesh.Parent = rightLeg
                                                        end
                                                end
                                        end
                                end
                        end
                        if value then
                                CosmeticsActive = true
                                getgenv().Config = {
                                        Headless = true,
                                }
                                if lp.Character then
                                        local head = lp.Character:FindFirstChild("Head")
                                        if head and getgenv().Config.Headless then
                                                _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                                                local decal = head:FindFirstChildOfClass("Decal")
                                                if decal then
                                                        _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
                                                        _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
                                                end
                                        end
                                        saveRightLegProperties(lp.Character)
                                        applyKorblox(lp.Character)
                                end
                                _G.PlayerCosmeticsCleanup.characterAddedConn = lp.CharacterAdded:Connect(function(char)

                                 local head = char:WaitForChild("Head", 5)
                        if head and getgenv().Config.Headless then
                        _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                         local decal = head:FindFirstChildOfClass("Decal")
                 if decal then
            _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
            _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
         end
        end


                                local rightLeg = char:WaitForChild("RightLeg", 0.1) or char:WaitForChild("Right Leg", 0.1)
                                        if rightLeg then
                                applyKorblox(char)
                                else
                                warn("RightLeg not found after respawn!")
                                end
                        end)
                                if getgenv().Config.Headless then
                                        headLoop = task.spawn(function()
                                                while CosmeticsActive do
                                                        local char = lp.Character
                                                        if char then
                                                                local head = char:FindFirstChild("Head")
                                                                if head then
                                                                        head.Transparency = 1
                                                                        local decal = head:FindFirstChildOfClass("Decal")
                                                                        if decal then
                                                                                decal:Destroy()
                                                                        end
                                                                end
                                                        end
                                                        task.wait(0.1)
                                                end
                                        end)
                                end
                        else
                                CosmeticsActive = false
                                if _G.PlayerCosmeticsCleanup.characterAddedConn then
                                        _G.PlayerCosmeticsCleanup.characterAddedConn:Disconnect()
                                        _G.PlayerCosmeticsCleanup.characterAddedConn = nil
                                end
                                if headLoop then
                                        task.cancel(headLoop)
                                        headLoop = nil
                                end
                                local char = lp.Character
                                if char then
                                        local head = char:FindFirstChild("Head")
                                        if head and _G.PlayerCosmeticsCleanup.headTransparency ~= nil then
                                                head.Transparency = _G.PlayerCosmeticsCleanup.headTransparency
                                                if _G.PlayerCosmeticsCleanup.faceDecalId then
                                                        local newDecal = head:FindFirstChildOfClass("Decal") or Instance.new("Decal", head)
                                                        newDecal.Name = _G.PlayerCosmeticsCleanup.faceDecalName or "face"
                                                        newDecal.Texture = _G.PlayerCosmeticsCleanup.faceDecalId
                                                        newDecal.Face = Enum.NormalId.Front
                                                end
                                        end
                                        restoreRightLeg(char)
                                end
                                _G.PlayerCosmeticsCleanup = {}
                        end
                end,
        })
        local fly = player:create_module({
                title = "Fly",
                flag = "Fly",
                description = "Allows the player to fly",
                section = "right",
                callback = function(value)
                        if value then
                                getgenv().FlyEnabled = true
                                local char = Player.Character or Player.CharacterAdded:Wait()
                                local hrp = char:WaitForChild("HumanoidRootPart")
                                local humanoid = char:WaitForChild("Humanoid")
                                getgenv().OriginalStateType = humanoid:GetState()
                                getgenv().RagdollHandler = humanoid.StateChanged:Connect(function(oldState, newState)
                                        if getgenv().FlyEnabled then
                                                if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
                                                        task.defer(function()
                                                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                                                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                                        end)
                                                end
                                        end
                                end)
                                local bodyGyro = Instance.new("BodyGyro")
                                bodyGyro.P = 90000
                                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                                bodyGyro.Parent = hrp
                                local bodyVelocity = Instance.new("BodyVelocity")
                                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                                bodyVelocity.Parent = hrp
                                humanoid.PlatformStand = true
                                getgenv().ResetterConnection = RunService.PreSimulation:Connect(function()
                                        if not getgenv().FlyEnabled then
                                                return
                                        end
                                        if bodyGyro and bodyGyro.Parent then
                                                bodyGyro.P = 90000
                                                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                                        end
                                        if bodyVelocity and bodyVelocity.Parent then
                                                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                                        end
                                        humanoid.PlatformStand = true
                                        if not bodyGyro.Parent or not bodyVelocity.Parent then
                                                if bodyGyro then
                                                        bodyGyro:Destroy()
                                                end
                                                if bodyVelocity then
                                                        bodyVelocity:Destroy()
                                                end
                                                bodyGyro = Instance.new("BodyGyro")
                                                bodyGyro.P = 90000
                                                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                                                bodyGyro.Parent = hrp
                                                bodyVelocity = Instance.new("BodyVelocity")
                                                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                                                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                                                bodyVelocity.Parent = hrp
                                        end
                                end)
                                getgenv().FlyConnection = RunService.RenderStepped:Connect(function()
                                        if not getgenv().FlyEnabled then
                                                return
                                        end
                                        local camCF = workspace.CurrentCamera.CFrame
                                        local moveDir = Vector3.new(0, 0, 0)
                                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                                moveDir = moveDir + camCF.LookVector
                                        end
                                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                                moveDir = moveDir - camCF.LookVector
                                        end
                                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                                                moveDir = moveDir - camCF.RightVector
                                        end
                                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                                                moveDir = moveDir + camCF.RightVector
                                        end
                                        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                                                moveDir = moveDir + Vector3.new(0, 1, 0)
                                        end
                                        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                                                moveDir = moveDir - Vector3.new(0, 1, 0)
                                        end
                                        if moveDir.Magnitude > 0 then
                                                moveDir = moveDir.Unit
                                        end
                                        bodyVelocity.Velocity = moveDir * (getgenv().FlySpeed or 50)
                                        bodyGyro.CFrame = camCF
                                end)
                        else
                                getgenv().FlyEnabled = false
                                if getgenv().FlyConnection then
                                        getgenv().FlyConnection:Disconnect()
                                        getgenv().FlyConnection = nil
                                end
                                if getgenv().RagdollHandler then
                                        getgenv().RagdollHandler:Disconnect()
                                        getgenv().RagdollHandler = nil
                                end
                                if getgenv().ResetterConnection then
                                        getgenv().ResetterConnection:Disconnect()
                                        getgenv().ResetterConnection = nil
                                end
                                local char = Player.Character
                                if char then
                                        local hrp = char:FindFirstChild("HumanoidRootPart")
                                        local humanoid = char:FindFirstChild("Humanoid")
                                        if humanoid then
                                                humanoid.PlatformStand = false
                                                if getgenv().OriginalStateType then
                                                        humanoid:ChangeState(getgenv().OriginalStateType)
                                                end
                                        end
                                        if hrp then
                                                for _, v in ipairs(hrp:GetChildren()) do
                                                        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then
                                                                v:Destroy()
                                                        end
                                                end
                                        end
                                end
                        end
                end,
        })
        fly:create_slider({
                title = "Fly Speed",
                flag = "Fly_Speed",
                minimum_value = 10,
                maximum_value = 200,
                value = 50,
                round_number = true,
                callback = function(value)
                        getgenv().FlySpeed = value
                end,
        })
        local localPlayer = Players.LocalPlayer
        local SelectedPlayerFollow = nil
        local followDropdown
        local function getPlayerNames()
                local names = {}
                for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= localPlayer then
                                table.insert(names, player.Name)
                        end
                end
                return names
        end
        local function updateFollowTarget()
                local availablePlayers = getPlayerNames()
                if #availablePlayers > 0 then
                        SelectedPlayerFollow = availablePlayers[1]
                        if followDropdown then
                                followDropdown:update(SelectedPlayerFollow)
                        end
                else
                        SelectedPlayerFollow = nil
                end
        end
        local PlayerFollow = player:create_module({
                title = "Player Follow",
                flag = "Player_Follow",
                description = "Follows the selected player",
                section = "left",
                callback = function(value)
                        if value then
                                getgenv().PlayerFollowEnabled = true
                                getgenv().PlayerFollowConnection = RunService.PreSimulation:Connect(function()
                                        if not SelectedPlayerFollow then
                                                return
                                        end
                                        local targetPlayer = Players:FindFirstChild(SelectedPlayerFollow)
                                        if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
                                                local char = localPlayer.Character
                                                if char then
                                                        local humanoid = char:FindFirstChild("Humanoid")
                                                        if humanoid then
                                                                humanoid:MoveTo(targetPlayer.Character.PrimaryPart.Position)
                                                        end
                                                end
                                        end
                                end)
                        else
                                getgenv().PlayerFollowEnabled = false
                                if getgenv().PlayerFollowConnection then
                                        getgenv().PlayerFollowConnection:Disconnect()
                                        getgenv().PlayerFollowConnection = nil
                                end
                        end
                end,
        })
        local initialOptions = getPlayerNames()
        if #initialOptions > 0 then
                followDropdown = PlayerFollow:create_dropdown({
                        title = "Follow Target",
                        flag = "Follow_Target",
                        options = initialOptions,
                        multi_dropdown = false,
                        maximum_options = #initialOptions,
                        callback = function(value)
                                if value then
                                        SelectedPlayerFollow = value
                                        if getgenv().FollowNotifyEnabled then
                                                Library.SendNotification({
                                                        title = "Module Notification",
                                                        text = "Now following: " .. value,
                                                        duration = 3,
                                                })
                                        end
                                end
                        end,
                })
                SelectedPlayerFollow = initialOptions[1]
                followDropdown:update(SelectedPlayerFollow)
                getgenv().FollowDropdown = followDropdown
        else
                SelectedPlayerFollow = nil
        end
        local lastOptionsString = table.concat(initialOptions, ",")
        local updateTimer = 0
        RunService.Heartbeat:Connect(function(dt)
                updateTimer = updateTimer + dt
                if updateTimer >= 10 then
                        local newOptions = getPlayerNames()
                        table.sort(newOptions)
                        local newOptionsString = table.concat(newOptions, ",")
                        if newOptionsString ~= lastOptionsString then
                                if followDropdown then
                                        if #newOptions > 0 then
                                                if followDropdown.set_options then
                                                        followDropdown:set_options(newOptions)
                                                else
                                                        followDropdown.maximum_options = #newOptions
                                                end
                                                if not table.find(newOptions, SelectedPlayerFollow) then
                                                        SelectedPlayerFollow = newOptions[1]
                                                        followDropdown:update(SelectedPlayerFollow)
                                                end
                                        else
                                                SelectedPlayerFollow = nil
                                        end
                                end
                                lastOptionsString = newOptionsString
                        end
                        updateTimer = 0
                end
        end)
        PlayerFollow:create_checkbox({
                title = "Notify",
                flag = "Follow_Notify",
                default = false,
                callback = function(value)
                        getgenv().FollowNotifyEnabled = value
                end,
        })
        local HitSounds = player:create_module({
                title = "Hit Sounds",
                flag = "Hit_Sounds",
                description = "Toggles hit sounds",
                section = "right",
                callback = function(value)
                        hit_Sound_Enabled = value
                end,
        })
        local Folder = Instance.new("Folder")
        Folder.Name = "Useful Utility"
        Folder.Parent = workspace
        local hit_Sound = Instance.new("Sound", Folder)
        hit_Sound.Volume = 6
        local hitSoundOptions = {
                "Medal",
                "Fatality",
                "Skeet",
                "Switches",
                "Rust Headshot",
                "Neverlose Sound",
                "Bubble",
                "Laser",
                "Steve",
                "Call of Duty",
                "Bat",
                "TF2 Critical",
                "Saber",
                "Bameware",
        }
        local hitSoundIds = {
                Medal = "rbxassetid://6607336718",
                Fatality = "rbxassetid://6607113255",
                Skeet = "rbxassetid://6607204501",
                Switches = "rbxassetid://6607173363",
                ["Rust Headshot"] = "rbxassetid://138750331387064",
                ["Neverlose Sound"] = "rbxassetid://110168723447153",
                Bubble = "rbxassetid://6534947588",
                Laser = "rbxassetid://7837461331",
                Steve = "rbxassetid://4965083997",
                ["Call of Duty"] = "rbxassetid://5952120301",
                Bat = "rbxassetid://3333907347",
                ["TF2 Critical"] = "rbxassetid://296102734",
                Saber = "rbxassetid://8415678813",
                Bameware = "rbxassetid://3124331820",
        }
        HitSounds:create_slider({
                title = "Volume",
                flag = "HitSoundVolume",
                minimum_value = 1,
                maximum_value = 10,
                value = 5,
                callback = function(value)
                        hit_Sound.Volume = value
                end,
        })
        HitSounds:create_dropdown({
                title = "Hit Sound Type",
                flag = "hit_sound_type",
                options = hitSoundOptions,
                maximum_options = #hitSoundOptions,
                multi_dropdown = false,
                callback = function(selectedOption)
                        if hitSoundIds[selectedOption] then
                                hit_Sound.SoundId = hitSoundIds[selectedOption]
                        else
                                warn("Invalid hit sound selection: " .. tostring(selectedOption))
                        end
                end,
        })
        ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
                if hit_Sound_Enabled then
                        hit_Sound:Play()
                end
        end)
        local soundOptions = {
                ["Eeyuh"] = "rbxassetid://16190782181",
                ["Sweep"] = "rbxassetid://103508936658553",
                ["Bounce"] = "rbxassetid://134818882821660",
                ["Everybody Wants To Rule The World"] = "rbxassetid://87209527034670",
                ["Missing Money"] = "rbxassetid://134668194128037",
                ["Sour Grapes"] = "rbxassetid://117820392172291",
                ["Erwachen"] = "rbxassetid://124853612881772",
                ["Grasp the Light"] = "rbxassetid://89549155689397",
                ["Beyond the Shadows"] = "rbxassetid://120729792529978",
                ["Rise to the Horizon"] = "rbxassetid://72573266268313",
                ["Echoes of the Candy Kingdom"] = "rbxassetid://103040477333590",
                ["Speed"] = "rbxassetid://125550253895893",
                ["Lo-fi Chill A"] = "rbxassetid://9043887091",
                ["Lo-fi Ambient"] = "rbxassetid://129775776987523",
                ["Tears in the Rain"] = "rbxassetid://129710845038263",
        }
        local currentSound = Instance.new("Sound")
        currentSound.Volume = 3
        currentSound.Looped = false
        currentSound.Parent = game:GetService("SoundService")
        local soundModule
        local function playSoundById(soundId)
                currentSound:Stop()
                currentSound.SoundId = soundId
                currentSound:Play()
        end
        local selectedSound = "Eeyuh"
        local soundModule = world:create_module({
                title = "Sound Controller",
                flag = "sound_controller",
                description = "Control background music and sounds",
                section = "left",
                callback = function(value)
                        getgenv().soundmodule = value
                        if value then
                                playSoundById(soundOptions[selectedSound])
                        else
                                currentSound:Stop()
                        end
                end,
        })
        soundModule:create_checkbox({
                title = "Loop Song",
                flag = "LoopSong",
                callback = function(value)
                        currentSound.Looped = value
                end,
        })
        soundModule:create_slider({
                title = "Volume",
                flag = "HitSoundVolume",
                minimum_value = 1,
                maximum_value = 10,
                value = 3,
                callback = function(value)
                        currentSound.Volume = value
                end,
        })
        soundModule:create_divider({})
        soundModule:create_dropdown({
                title = "Select Sound",
                flag = "sound_selection",
                options = {
                        "Eeyuh",
                        "Sweep",
                        "Bounce",
                        "Everybody Wants To Rule The World",
                        "Missing Money",
                        "Sour Grapes",
                        "Erwachen",
                        "Grasp the Light",
                        "Beyond the Shadows",
                        "Rise to the Horizon",
                        "Echoes of the Candy Kingdom",
                        "Speed",
                        "Lo-fi Chill A",
                        "Lo-fi Ambient",
                        "Tears in the Rain",
                },
                multi_dropdown = false,
                maximum_options = 15,
                callback = function(value)
                        selectedSound = value
                        if getgenv().soundmodule then
                                playSoundById(soundOptions[value])
                        end
                end,
        })
        local WorldFilter = world:create_module({
                title = "Filter",
                flag = "Filter",
                description = "Toggles custom world filter effects",
                section = "right",
                callback = function(value)
                        getgenv().WorldFilterEnabled = value
                        if not value then
                                if game.Lighting:FindFirstChild("CustomAtmosphere") then
                                        game.Lighting.CustomAtmosphere:Destroy()
                                end
                                game.Lighting.FogEnd = 100000
                                game.Lighting.ColorCorrection.TintColor = Color3.new(1, 1, 1)
                                game.Lighting.ColorCorrection.Saturation = 0
                        end
                end,
        })
        WorldFilter:create_checkbox({
                title = "Enable Atmosphere",
                flag = "World_Filter_Atmosphere",
                callback = function(value)
                        getgenv().AtmosphereEnabled = value
                        if value then
                                if not game.Lighting:FindFirstChild("CustomAtmosphere") then
                                        local atmosphere = Instance.new("Atmosphere")
                                        atmosphere.Name = "CustomAtmosphere"
                                        atmosphere.Parent = game.Lighting
                                end
                        else
                                if game.Lighting:FindFirstChild("CustomAtmosphere") then
                                        game.Lighting.CustomAtmosphere:Destroy()
                                end
                        end
                end,
        })
        WorldFilter:create_slider({
                title = "Atmosphere Density",
                flag = "World_Filter_Atmosphere_Slider",
                minimum_value = 0,
                maximum_value = 1,
                value = 0.5,
                callback = function(value)
                        if getgenv().AtmosphereEnabled and game.Lighting:FindFirstChild("CustomAtmosphere") then
                                game.Lighting.CustomAtmosphere.Density = value
                        end
                end,
        })
        WorldFilter:create_checkbox({
                title = "Enable Fog",
                flag = "World_Filter_Fog",
                callback = function(value)
                        getgenv().FogEnabled = value
                        if not value then
                                game.Lighting.FogEnd = 100000
                        end
                end,
        })
        WorldFilter:create_slider({
                title = "Fog Distance",
                flag = "World_Filter_Fog_Slider",
                minimum_value = 50,
                maximum_value = 10000,
                value = 1000,
                callback = function(value)
                        if getgenv().FogEnabled then
                                game.Lighting.FogEnd = value
                        end
                end,
        })
        WorldFilter:create_checkbox({
                title = "Enable Saturation",
                flag = "World_Filter_Saturation",
                callback = function(value)
                        getgenv().SaturationEnabled = value
                        if not value then
                                game.Lighting.ColorCorrection.Saturation = 0
                        end
                end,
        })
        WorldFilter:create_slider({
                title = "Saturation Level",
                flag = "World_Filter_Saturation_Slider",
                minimum_value = -1,
                maximum_value = 1,
                value = 0,
                callback = function(value)
                        if getgenv().SaturationEnabled then
                                game.Lighting.ColorCorrection.Saturation = value
                        end
                end,
        })
        WorldFilter:create_checkbox({
                title = "Enable Hue",
                flag = "World_Filter_Hue",
                callback = function(value)
                        getgenv().HueEnabled = value
                        if not value then
                                game.Lighting.ColorCorrection.TintColor = Color3.new(1, 1, 1)
                        end
                end,
        })
        WorldFilter:create_slider({
                title = "Hue Shift",
                flag = "World_Filter_Hue_Slider",
                minimum_value = -1,
                maximum_value = 1,
                value = 0,
                callback = function(value)
                        if getgenv().HueEnabled then
                                game.Lighting.ColorCorrection.TintColor = Color3.fromHSV(value, 1, 1)
                        end
                end,
        })
        local BallTrail = world:create_module({
                title = "Ball Trail",
                flag = "Ball_Trail",
                description = "Toggles ball trail effects",
                section = "left",
                callback = function(value)
                        getgenv().BallTrailEnabled = value
                end,
        })
        BallTrail:create_slider({
                title = "Ball Trail Hue",
                flag = "Ball_Trail_Hue",
                minimum_value = 0,
                maximum_value = 360,
                value = 0,
                round_number = true,
                callback = function(value)
                        if not getgenv().BallTrailRainbowEnabled then
                                local newColor = Color3.fromHSV(value / 360, 1, 1)
                                getgenv().BallTrailColor = newColor
                        end
                end,
        })
        BallTrail:create_checkbox({
                title = "Rainbow Trail",
                flag = "Ball_Trail_Rainbow",
                callback = function(value)
                        getgenv().BallTrailRainbowEnabled = value
                end,
        })
        BallTrail:create_checkbox({
                title = "Particle Emitter",
                flag = "Ball_Trail_Particle",
                callback = function(value)
                        getgenv().BallTrailParticleEnabled = value
                end,
        })
        BallTrail:create_checkbox({
                title = "Glow Effect",
                flag = "Ball_Trail_Glow",
                callback = function(value)
                        getgenv().BallTrailGlowEnabled = value
                end,
        })
        local hue = 0
        local trackedBalls = {}
        local function clearEffects(ball)
                local trail = ball:FindFirstChild("Trail")
                if trail then
                        trail:Destroy()
                end
                local emitter = ball:FindFirstChild("ParticleEmitter")
                if emitter then
                        emitter:Destroy()
                end
                local glow = ball:FindFirstChild("BallGlow")
                if glow then
                        glow:Destroy()
                end
                local att0 = ball:FindFirstChild("Attachment0")
                if att0 then
                        att0:Destroy()
                end
                local att1 = ball:FindFirstChild("Attachment1")
                if att1 then
                        att1:Destroy()
                end
        end
        local function applyEffects(ball)
                if not getgenv().BallTrailEnabled then
                        if trackedBalls[ball] then
                                clearEffects(ball)
                                trackedBalls[ball] = nil
                        end
                        return
                end
                if trackedBalls[ball] then
                        local trail = ball:FindFirstChild("Trail")
                        if trail then
                                if getgenv().BallTrailRainbowEnabled then
                                        local color = Color3.fromHSV(hue / 360, 1, 1)
                                        trail.Color = ColorSequence.new(color)
                                        getgenv().BallTrailColor = color
                                else
                                        trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
                                end
                        end
                        return
                end
                trackedBalls[ball] = true
                local trail = Instance.new("Trail")
                trail.Name = "Trail"
                local att0 = Instance.new("Attachment")
                att0.Name = "Attachment0"
                att0.Position = Vector3.new(0, ball.Size.Y / 2, 0)
                att0.Parent = ball
                local att1 = Instance.new("Attachment")
                att1.Name = "Attachment1"
                att1.Position = Vector3.new(0, -ball.Size.Y / 2, 0)
                att1.Parent = ball
                trail.Attachment0 = att0
                trail.Attachment1 = att1
                trail.Lifetime = 0.4
                trail.WidthScale = NumberSequence.new(0.5)
                trail.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                })
                trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
                trail.Parent = ball
                if getgenv().BallTrailParticleEnabled then
                        local emitter = Instance.new("ParticleEmitter")
                        emitter.Name = "ParticleEmitter"
                        emitter.Rate = 100
                        emitter.Lifetime = NumberRange.new(0.5, 1)
                        emitter.Speed = NumberRange.new(0, 1)
                        emitter.Size = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0.5),
                                NumberSequenceKeypoint.new(1, 0),
                        })
                        emitter.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(1, 1),
                        })
                        emitter.Parent = ball
                end
                if getgenv().BallTrailGlowEnabled then
                        local glow = Instance.new("PointLight")
                        glow.Name = "BallGlow"
                        glow.Range = 15
                        glow.Brightness = 2
                        glow.Parent = ball
                end
        end
        game:GetService("RunService").PreSimulation:Connect(function()
                hue = (hue + 1) % 360
                for _, ball in pairs(Auto_Parry.Get_Balls()) do
                        applyEffects(ball)
                end
        end)
        local billboardLabels = {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local plr = Players.LocalPlayer
        getgenv().AbilityESP = true
        local billboardLabels = {}
        function qolPlayerNameVisibility()
                local function createBillboardGui(p)
                        local character = p.Character
                        while not (character and character.Parent) do
                                task.wait()
                                character = p.Character
                        end
                        local head = character:WaitForChild("Head")
                        local billboardGui = Instance.new("BillboardGui")
                        billboardGui.Name = "AbilityBillboard"
                        billboardGui.Adornee = head
                        billboardGui.Size = UDim2.new(0, 200, 0, 25)
                        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
                        billboardGui.AlwaysOnTop = true
                        billboardGui.Parent = head
                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
                        textLabel.TextSize = 12
                        textLabel.Font = Enum.Font.SourceSansSemibold
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextWrapped = false
                        textLabel.TextTruncate = Enum.TextTruncate.AtEnd
                        textLabel.TextXAlignment = Enum.TextXAlignment.Center
                        textLabel.TextYAlignment = Enum.TextYAlignment.Center
                        textLabel.TextScaled = false
                        textLabel.Text = ""
                        textLabel.Parent = billboardGui
                        billboardLabels[p] = textLabel
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid then
                                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                        RunService.Heartbeat:Connect(function()
                                if not character or not character.Parent then
                                        billboardGui:Destroy()
                                        billboardLabels[p] = nil
                                        return
                                end
                                if getgenv().AbilityESP then
                                        textLabel.Visible = true
                                        local abilityName = p:GetAttribute("EquippedAbility")
                                        if abilityName then
                                                textLabel.Text = p.DisplayName .. " [" .. tostring(abilityName) .. "]"
                                        else
                                                textLabel.Text = p.DisplayName .. " [???]"
                                        end
                                else
                                        textLabel.Visible = false
                                end
                        end)
                end
                for _, p in Players:GetPlayers() do
                        if p ~= plr then
                                p.CharacterAdded:Connect(function()
                                        createBillboardGui(p)
                                end)
                                createBillboardGui(p)
                        end
                end
                Players.PlayerAdded:Connect(function(newPlayer)
                        newPlayer.CharacterAdded:Connect(function()
                                createBillboardGui(newPlayer)
                        end)
                end)
        end
        qolPlayerNameVisibility()
        local AbilityESP = world:create_module({
                title = "Ability ESP",
                flag = "AbilityESP",
                description = "Displays Player Abilities",
                section = "right",
                callback = function(value)
                        getgenv().AbilityESP = value
                        for _, label in pairs(billboardLabels) do
                                label.Visible = value
                        end
                end,
        })
        local CustomSky = world:create_module({
                title = "Custom Sky",
                flag = "Custom_Sky",
                description = "Toggles a custom skybox",
                section = "right",
                callback = function(value)
                        local Lighting = game.Lighting
                        local Sky = Lighting:FindFirstChildOfClass("Sky")
                        if value then
                                if not Sky then
                                        Sky = Instance.new("Sky", Lighting)
                                end
                        else
                                if Sky then
                                        local defaultSkyboxIds =
                                                { "591058823", "591059876", "591058104", "591057861", "591057625", "591059642" }
                                        local skyFaces = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }
                                        for index, face in ipairs(skyFaces) do
                                                Sky[face] = "rbxassetid://" .. defaultSkyboxIds[index]
                                        end
                                        Lighting.GlobalShadows = true
                                end
                        end
                end,
        })
        CustomSky:create_dropdown({
                title = "Select Sky",
                flag = "custom_sky_selector",
                options = {
                        "Default",
                        "Vaporwave",
                        "Redshift",
                        "Desert",
                        "DaBaby",
                        "Minecraft",
                        "SpongeBob",
                        "Skibidi",
                        "Blaze",
                        "Pussy Cat",
                        "Among Us",
                        "Space Wave",
                        "Space Wave2",
                        "Turquoise Wave",
                        "Dark Night",
                        "Bright Pink",
                        "White Galaxy",
                        "Blue Galaxy",
                },
                multi_dropdown = false,
                maximum_options = 18,
                callback = function(selectedOption)
                        local skyboxData = nil
                        if selectedOption == "Default" then
                                skyboxData = { "591058823", "591059876", "591058104", "591057861", "591057625", "591059642" }
                        elseif selectedOption == "Vaporwave" then
                                skyboxData = { "1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643" }
                        elseif selectedOption == "Redshift" then
                                skyboxData = { "401664839", "401664862", "401664960", "401664881", "401664901", "401664936" }
                        elseif selectedOption == "Desert" then
                                skyboxData = { "1013852", "1013853", "1013850", "1013851", "1013849", "1013854" }
                        elseif selectedOption == "DaBaby" then
                                skyboxData = { "7245418472", "7245418472", "7245418472", "7245418472", "7245418472", "7245418472" }
                        elseif selectedOption == "Minecraft" then
                                skyboxData = { "1876545003", "1876544331", "1876542941", "1876543392", "1876543764", "1876544642" }
                        elseif selectedOption == "SpongeBob" then
                                skyboxData = { "7633178166", "7633178166", "7633178166", "7633178166", "7633178166", "7633178166" }
                        elseif selectedOption == "Skibidi" then
                                skyboxData =
                                        { "14952256113", "14952256113", "14952256113", "14952256113", "14952256113", "14952256113" }
                        elseif selectedOption == "Blaze" then
                                skyboxData = { "150939022", "150939038", "150939047", "150939056", "150939063", "150939082" }
                        elseif selectedOption == "Pussy Cat" then
                                skyboxData =
                                        { "11154422902", "11154422902", "11154422902", "11154422902", "11154422902", "11154422902" }
                        elseif selectedOption == "Among Us" then
                                skyboxData = { "5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190" }
                        elseif selectedOption == "Space Wave" then
                                skyboxData =
                                        { "16262356578", "16262358026", "16262360469", "16262362003", "16262363873", "16262366016" }
                        elseif selectedOption == "Space Wave2" then
                                skyboxData = { "1233158420", "1233158838", "1233157105", "1233157640", "1233157995", "1233159158" }
                        elseif selectedOption == "Turquoise Wave" then
                                skyboxData = { "47974894", "47974690", "47974821", "47974776", "47974859", "47974909" }
                        elseif selectedOption == "Dark Night" then
                                skyboxData = { "6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635" }
                        elseif selectedOption == "Bright Pink" then
                                skyboxData = { "271042516", "271077243", "271042556", "271042310", "271042467", "271077958" }
                        elseif selectedOption == "White Galaxy" then
                                skyboxData = { "5540798456", "5540799894", "5540801779", "5540801192", "5540799108", "5540800635" }
                        elseif selectedOption == "Blue Galaxy" then
                                skyboxData =
                                        { "14961495673", "14961494492", "14961492844", "14961491298", "14961490439", "14961489508" }
                        end
                        if not skyboxData then
                                warn("Sky option not found: " .. tostring(selectedOption))
                                return
                        end
                        local Lighting = game.Lighting
                        local Sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
                        local skyFaces = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }
                        for index, face in ipairs(skyFaces) do
                                Sky[face] = "rbxassetid://" .. skyboxData[index]
                        end
                        Lighting.GlobalShadows = false
                end,
        })
        local AbilityExploit = world:create_module({
                title = "Ability Exploit",
                flag = "AbilityExploit",
                description = "Ability Exploit",
                section = "right",
                callback = function(value)
                        getgenv().AbilityExploit = value
                end,
        })
        AbilityExploit:create_checkbox({
                title = "Thunder Dash No Cooldown",
                flag = "ThunderDashNoCooldown",
                callback = function(value)
                        getgenv().ThunderDashNoCooldown = value
                        if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then
                                local thunderModule = game:GetService("ReplicatedStorage")
                                        :WaitForChild("Shared")
                                        :WaitForChild("Abilities")
                                        :WaitForChild("Thunder Dash")
                                local mod = require(thunderModule)
                                mod.cooldown = 0
                                mod.cooldownReductionPerUpgrade = 0
                        end
                end,
        })
        AbilityExploit:create_checkbox({
                title = "Continuity Zero Exploit",
                flag = "ContinuityZeroExploit",
                callback = function(value)
                        getgenv().ContinuityZeroExploit = value
                        if getgenv().AbilityExploit and getgenv().ContinuityZeroExploit then
                                local ContinuityZeroRemote =
                                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseContinuityPortal")
                                local oldNamecall
                                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                        local method = getnamecallmethod()
                                        if self == ContinuityZeroRemote and method == "FireServer" then
                                                local ok, result = pcall(function()
                                                        return oldNamecall(
                                                                self,
                                                                CFrame.new(9e17, 9e16, 9e15, 9e14, 9e13, 9e12, 9e11, 9e10, 9e9, 9e8, 9e7, 9e6),
                                                                player.Name
                                                        )
                                                end)
                                                if ok then return result end
                                        end
                                        return oldNamecall(self, ...)
                                end)
                        end
                end,
        })
        -- ═════════════════════════════════════════════════════════════════
        -- MADE IN HEAVEN — Time acceleration lighting effect
        -- ═════════════════════════════════════════════════════════════════
        local MadeInHeaven = {
            Enabled = false,
            SkySpeed = 0.5,
            MaxSkySpeed = 900000,
            Acceleration = 180,
            CurrentTime = 12,
            Connection = nil,
        }

        function MadeInHeaven:activate()
            if self.Enabled then return end
            self.Enabled = true
            self.SkySpeed = 0.5
            self.CurrentTime = 12
            local lighting = game:GetService("Lighting")
            lighting.Brightness = 1.2
            lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 255)
            lighting.FogColor = Color3.fromRGB(100, 100, 200)
            lighting.FogEnd = 10000
            self.Connection = RunService.RenderStepped:Connect(function()
                if not self.Enabled then return end
                if self.SkySpeed < self.MaxSkySpeed then
                    self.SkySpeed = math.min(self.SkySpeed + (self.Acceleration * RunService.RenderStepped:Wait()), self.MaxSkySpeed)
                end
                local hoursPerSecond = (self.SkySpeed / 360) * 24
                local timeIncrement = hoursPerSecond * RunService.RenderStepped:Wait()
                self.CurrentTime = (self.CurrentTime + timeIncrement) % 24
                lighting.ClockTime = self.CurrentTime
                local speedRatio = self.SkySpeed / self.MaxSkySpeed
                lighting.Brightness = 1 + (0.8 * speedRatio)
                local blueValue = 150 + (105 * speedRatio)
                local redGreenValue = 150 + (50 * speedRatio)
                lighting.OutdoorAmbient = Color3.fromRGB(redGreenValue, redGreenValue, blueValue)
                if speedRatio > 0.3 then
                    lighting.FogStart = 50 * speedRatio
                    lighting.FogEnd = 5000 + (5000 * speedRatio)
                end
            end)
        end

        function MadeInHeaven:deactivate()
            if not self.Enabled then return end
            self.Enabled = false
            self.SkySpeed = 0
            local lighting = game:GetService("Lighting")
            lighting.Brightness = 1
            lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            lighting.FogColor = Color3.new()
            lighting.FogEnd = 100000
            if self.Connection then
                self.Connection:Disconnect()
                self.Connection = nil
            end
        end
        getgenv().KERO_MadeInHeaven = MadeInHeaven

        local MadeInHeavenModule = world:create_module({
                title = "Made in Heaven",
                flag = "Made_In_Heaven",
                description = "Time really does speed up. (Lighting effect)",
                section = "right",
                callback = function(value)
                        if value then
                            MadeInHeaven:activate()
                        else
                            MadeInHeaven:deactivate()
                        end
                end,
        })
    local immortality = misc:create_module({
    title = "Semi Immortality !BETA!",
    flag = "Immortal",
    description = "Let's you hold the ball NOT FOREVER!",
    section = "",
    callback = function(value)
       local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


if PlayerGui:FindFirstChild("Kero-Hub") then
    PlayerGui["Kero-Hub"]:Destroy()
end
if PlayerGui:FindFirstChild("ToggleGui") then
    PlayerGui["ToggleGui"]:Destroy()
end


local SemiImmortality = Instance.new("ScreenGui")
SemiImmortality.Name = "SemiImmortality"
SemiImmortality.Parent = PlayerGui
SemiImmortality.ResetOnSpawn = True
SemiImmortality.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Immortality = Instance.new("Frame")
Immortality.Name = "Immortality"
Immortality.Parent = SemiImmortality
Immortality.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Immortality.BackgroundTransparency = 0.3
Immortality.BorderSizePixel = 0
Immortality.Position = UDim2.new(0.057, 0, 0.078, 0)
Immortality.Size = UDim2.new(0, 139, 0, 89)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Immortality

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = Immortality
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(0, 139, 0, 29)
Title.Font = Enum.Font.SourceSans
Title.Text = "Semi Immortal"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextWrapped = true

local Promotion = Instance.new("TextLabel")
Promotion.Name = "Promotion"
Promotion.Parent = Immortality
Promotion.BackgroundTransparency = 1
Promotion.Position = UDim2.new(0, 0, -0.325, 0)
Promotion.Size = UDim2.new(0, 139, 0, 29)
Promotion.Font = Enum.Font.SourceSans
Promotion.Text = "https://discord.gg/8hjETGDnVE"
Promotion.TextColor3 = Color3.fromRGB(0, 0, 0)
Promotion.TextScaled = true
Promotion.TextWrapped = true

local Activation = Instance.new("TextButton")
Activation.Name = "Activation"
Activation.Parent = Immortality
Activation.BackgroundTransparency = 1
Activation.Position = UDim2.new(0, 0, 0.326, 0)
Activation.Size = UDim2.new(0, 139, 0, 60)
Activation.Font = Enum.Font.SourceSans
Activation.Text = "OFF"
Activation.TextColor3 = Color3.fromRGB(255, 0, 0)
Activation.TextScaled = true
Activation.TextWrapped = true


local isActive = false
local function toggle()
    isActive = not isActive
    if isActive then
        Activation.Text = "ON"
        Activation.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        Activation.Text = "OFF"
        Activation.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end
Activation.MouseButton1Click:Connect(toggle)


do
    local TweenService = game:GetService("TweenService")
                                local UserInputService = game:GetService("UserInputService")

                                local function makeDraggable(frame)
                                        local dragging = false
                                        local dragInput, dragStart, startPos

                                        local function update(input)
                                                local delta = input.Position - dragStart
                                                local newPos = UDim2.new(
                                                        startPos.X.Scale,
                                                        startPos.X.Offset + delta.X,
                                                        startPos.Y.Scale,
                                                        startPos.Y.Offset + delta.Y
                                                )
                                                
                                                TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                                        Position = newPos
                                                }):Play()
                                        end

                                        frame.Active = true
                                        frame.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                                        dragging = true
                                                        dragStart = input.Position
                                                        startPos = frame.Position

                                                        input.Changed:Connect(function()
                                                                if input.UserInputState == Enum.UserInputState.End then
                                                                        dragging = false
                                                                end
                                                        end)
                                                end
                                        end)

                                        frame.InputChanged:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseMovement then
                                                        dragInput = input
                                                end
                                        end)

                                        UserInputService.InputChanged:Connect(function(input)
                                                if input == dragInput and dragging then
                                                        update(input)
                                                end
                                        end)
                                end

                                
                                makeDraggable(Immortality)
                        end


local function RandomNumberRange(a)
    return math.random(-a * 90000009292929399949949496000, a * -1e9) / 5e8
end
local function RandomVectorRange(a, b, c)
    return Vector3.new(RandomNumberRange(a), RandomNumberRange(b), RandomNumberRange(c))
end


local DesyncTypes = {}


RunService.Stepped:Connect(function()
    if isActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart:SetNetworkOwner(LocalPlayer)
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if isActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        DesyncTypes[1] = LocalPlayer.Character.HumanoidRootPart.CFrame
        DesyncTypes[2] = LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity

        local SpoofThis = LocalPlayer.Character.HumanoidRootPart.CFrame
        local horizontalOscillation = math.sin(tick() * 60) * 55
        local verticalOscillation = math.sin(tick() * 25) * 15
        SpoofThis = SpoofThis * CFrame.new(horizontalOscillation, verticalOscillation, 0) * CFrame.Angles(
            math.rad(RandomNumberRange(1000)),
            math.rad(RandomNumberRange(1000)),
            math.rad(RandomNumberRange(1000))
        )

        LocalPlayer.Character.HumanoidRootPart.CFrame = SpoofThis
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = DesyncTypes[2] + Vector3.new(
            math.cos(tick() * 8) * 6000,
            math.cos(tick() * 8) * 6000,
            0
        )

        RunService.RenderStepped:Wait()

        LocalPlayer.Character.HumanoidRootPart.CFrame = DesyncTypes[1]
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = DesyncTypes[2]
    end
end)


local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if isActive and not checkcaller() then
        if key == "CFrame" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if self == LocalPlayer.Character.HumanoidRootPart then
                return DesyncTypes[1] or CFrame.new()
            elseif self == LocalPlayer.Character:FindFirstChild("Head") then
                return DesyncTypes[1] and DesyncTypes[1] + Vector3.new(0, LocalPlayer.Character.HumanoidRootPart.Size.Y / 2 + 0.5, 0) or CFrame.new()
            end
        end
    end
    return oldIndex(self, key)
end))
    end,
})
local immortalityv2 = misc:create_module({
    title = "Semi Immortality V2 !BETA!",
    flag = "Immortalv2",
    description = "Let's you hold the ball NOT FOREVER!",
    section = "right",
    callback = function(value)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        local workspace = game:GetService("Workspace")
        local mapFolder = workspace:FindFirstChild("Map")
        if not mapFolder then
            mapFolder = Instance.new("Folder")
            mapFolder.Name = "Map"
            mapFolder.Parent = workspace
        end

     
        local playerPart = workspace:FindFirstChild("PlayerMapPart")

        local function enableMap()
            for _, obj in pairs(mapFolder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Transparency = 0.5
                    obj.CanCollide = false
                end
            end

            if not playerPart or not playerPart.Parent then
                playerPart = Instance.new("Part")
                playerPart.Name = "PlayerMapPart"
                playerPart.Size = Vector3.new(500, 1, 500)
                playerPart.Position = humanoidRootPart.Position - Vector3.new(0, 20, 0)
                playerPart.Anchored = true
                playerPart.Material = Enum.Material.SmoothPlastic
                playerPart.Color = Color3.fromRGB(255, 255, 255)
                playerPart.Parent = workspace
            end
        end

        local function disableMap()
            for _, obj in pairs(mapFolder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Transparency = 0
                    obj.CanCollide = true
                end
            end

            if playerPart and playerPart.Parent then
                playerPart:Destroy()
            end
        end

       
        if value then
            enableMap()
        else
            disableMap()
        end
    end,
})

        local SkinChanger = misc:create_module({
                title = "Skin Changer",
                flag = "SkinChanger",
                description = "Skin Changer",
                section = "left",
                callback = function(value)
                        getgenv().skinChanger = value
                        if value and getgenv().updateSword then
                                pcall(getgenv().updateSword)
                        end
                end,
        })
        SkinChanger:change_state(false)
        SkinChanger:create_paragraph({
                title = "Everyone can see animations",
                text = "",
        })
        local skinchangertextbox = SkinChanger:create_textbox({
                title = "￬ Skin Name (Case Sensitive) ￬",
                placeholder = "Enter Sword Skin Name... ",
                flag = "SkinChangerTextbox",
                callback = function(text)
                        getgenv().swordModel = text
                        getgenv().swordAnimations = text
                        getgenv().swordFX = text
                        if getgenv().skinChanger and getgenv().updateSword then
                                pcall(getgenv().updateSword)
                        end
                end,
        })
        local AutoPlayModule = {}
        AutoPlayModule.CONFIG = {
                DEFAULT_DISTANCE = 30,
                MULTIPLIER_THRESHOLD = 70,
                TRAVERSING = 25,
                DIRECTION = 1,
                JUMP_PERCENTAGE = 50,
                DOUBLE_JUMP_PERCENTAGE = 50,
                JUMPING_ENABLED = false,
                MOVEMENT_DURATION = 0.8,
                OFFSET_FACTOR = 0.7,
                GENERATION_THRESHOLD = 0.25,
        }
        AutoPlayModule.ball = nil
        AutoPlayModule.lobbyChoice = nil
        AutoPlayModule.animationCache = nil
        AutoPlayModule.doubleJumped = false
        AutoPlayModule.ELAPSED = 0
        AutoPlayModule.CONTROL_POINT = nil
        AutoPlayModule.LAST_GENERATION = 0
        AutoPlayModule.signals = {}
        do
                local getServiceFunction = game.GetService
                local function getClonerefPermission()
                        local permission = cloneref(getServiceFunction(game, "ReplicatedFirst"))
                        return permission
                end
                AutoPlayModule.clonerefPermission = getClonerefPermission()
                if not AutoPlayModule.clonerefPermission then
                        warn("cloneref is not available on your executor! There is a risk of getting detected.")
                end
                function AutoPlayModule.findCachedService(self, name)
                        for index, value in self do
                                if value.Name == name then
                                        return value
                                end
                        end
                        return
                end
                function AutoPlayModule.getService(self, name)
                        local cachedService = AutoPlayModule.findCachedService(self, name)
                        if cachedService then
                                return cachedService
                        end
                        local service = getServiceFunction(game, name)
                        if AutoPlayModule.clonerefPermission then
                                service = cloneref(service)
                        end
                        table.insert(self, service)
                        return service
                end
                AutoPlayModule.customService = setmetatable({}, {
                        __index = AutoPlayModule.getService,
                })
        end
        AutoPlayModule.playerHelper = {
                isAlive = function(player)
                        local character = nil
                        if player and player:IsA("Player") then
                                character = player.Character
                        end
                        if not character then
                                return false
                        end
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChild("Humanoid")
                        if not rootPart or not humanoid then
                                return false
                        end
                        return humanoid.Health > 0
                end,
                inLobby = function(character)
                        if not character then
                                return false
                        end
                        return character.Parent == AutoPlayModule.customService.Workspace.Dead
                end,
                onGround = function(character)
                        if not character then
                                return false
                        end
                        return character.Humanoid.FloorMaterial ~= Enum.Material.Air
                end,
        }
        function AutoPlayModule.isLimited()
                local passedTime = tick() - AutoPlayModule.LAST_GENERATION
                return passedTime < AutoPlayModule.CONFIG.GENERATION_THRESHOLD
        end
        function AutoPlayModule.percentageCheck(limit)
                if AutoPlayModule.isLimited() then
                        return false
                end
                local percentage = math.random(100)
                AutoPlayModule.LAST_GENERATION = tick()
                return limit >= percentage
        end
        AutoPlayModule.ballUtils = {
                getBall = function()
                        for _, object in AutoPlayModule.customService.Workspace.Balls:GetChildren() do
                                if object:GetAttribute("realBall") then
                                        AutoPlayModule.ball = object
                                        return
                                end
                        end
                        AutoPlayModule.ball = nil
                end,
                getDirection = function()
                        if not AutoPlayModule.ball then
                                return
                        end
                        local direction = (
                                AutoPlayModule.customService.Players.LocalPlayer.Character.HumanoidRootPart.Position
                                - AutoPlayModule.ball.Position
                        ).Unit
                        return direction
                end,
                getVelocity = function()
                        if not AutoPlayModule.ball then
                                return
                        end
                        local zoomies = AutoPlayModule.ball:FindFirstChild("zoomies")
                        if not zoomies then
                                return
                        end
                        return zoomies.VectorVelocity
                end,
                getSpeed = function()
                        local velocity = AutoPlayModule.ballUtils.getVelocity()
                        if not velocity then
                                return
                        end
                        return velocity.Magnitude
                end,
                isExisting = function()
                        return AutoPlayModule.ball ~= nil
                end,
        }
        AutoPlayModule.lerp = function(start, finish, alpha)
                return start + (finish - start) * alpha
        end
        AutoPlayModule.quadratic = function(start, middle, finish, alpha)
                local firstLerp = AutoPlayModule.lerp(start, middle, alpha)
                local secondLerp = AutoPlayModule.lerp(middle, finish, alpha)
                return AutoPlayModule.lerp(firstLerp, secondLerp, alpha)
        end
        AutoPlayModule.getCandidates = function(middle, theta, offsetLength)
                local firstCanditateX = math.cos(theta + math.pi / 2)
                local firstCanditateZ = math.sin(theta + math.pi / 2)
                local firstCandidate = middle + Vector3.new(firstCanditateX, 0, firstCanditateZ) * offsetLength
                local secondCanditateX = math.cos(theta - math.pi / 2)
                local secondCanditateZ = math.sin(theta - math.pi / 2)
                local secondCandidate = middle + Vector3.new(secondCanditateX, 0, secondCanditateZ) * offsetLength
                return firstCandidate, secondCandidate
        end
        AutoPlayModule.getControlPoint = function(start, finish)
                local middle = (start + finish) * 0.5
                local difference = start - finish
                if difference.Magnitude < 5 then
                        return finish
                end
                local theta = math.atan2(difference.Z, difference.X)
                local offsetLength = difference.Magnitude * AutoPlayModule.CONFIG.OFFSET_FACTOR
                local firstCandidate, secondCandidate = AutoPlayModule.getCandidates(middle, theta, offsetLength)
                local dotValue = start - middle
                if (firstCandidate - middle):Dot(dotValue) < 0 then
                        return firstCandidate
                else
                        return secondCandidate
                end
        end
        AutoPlayModule.getCurve = function(start, finish, delta)
                AutoPlayModule.ELAPSED = AutoPlayModule.ELAPSED + delta
                local timeElapsed = math.clamp(AutoPlayModule.ELAPSED / AutoPlayModule.CONFIG.MOVEMENT_DURATION, 0, 1)
                if timeElapsed >= 1 then
                        local distance = (start - finish).Magnitude
                        if distance >= 10 then
                                AutoPlayModule.ELAPSED = 0
                        end
                        AutoPlayModule.CONTROL_POINT = nil
                        return finish
                end
                if not AutoPlayModule.CONTROL_POINT then
                        AutoPlayModule.CONTROL_POINT = AutoPlayModule.getControlPoint(start, finish)
                end
                assert(AutoPlayModule.CONTROL_POINT, "CONTROL_POINT: Vector3 expected, got nil")
                return AutoPlayModule.quadratic(start, AutoPlayModule.CONTROL_POINT, finish, timeElapsed)
        end
        AutoPlayModule.map = {
                getFloor = function()
                        local floor = AutoPlayModule.customService.Workspace:FindFirstChild("FLOOR")
                        if not floor then
                                for _, part in pairs(AutoPlayModule.customService.Workspace:GetDescendants()) do
                                        if part:IsA("MeshPart") or part:IsA("BasePart") then
                                                local size = part.Size
                                                if size.X > 50 and size.Z > 50 and part.Position.Y < 5 then
                                                        return part
                                                end
                                        end
                                end
                        end
                        return floor
                end,
        }
        AutoPlayModule.getRandomPosition = function()
                local floor = AutoPlayModule.map.getFloor()
                if not floor or not AutoPlayModule.ballUtils.isExisting() then
                        return
                end
                local ballDirection = AutoPlayModule.ballUtils.getDirection() * AutoPlayModule.CONFIG.DIRECTION
                local ballSpeed = AutoPlayModule.ballUtils.getSpeed()
                local speedThreshold = math.min(ballSpeed / 10, AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD)
                local speedMultiplier = AutoPlayModule.CONFIG.DEFAULT_DISTANCE + speedThreshold
                local negativeDirection = ballDirection * speedMultiplier
                local currentTime = os.time() / 1.2
                local sine = math.sin(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
                local cosine = math.cos(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
                local traversing = Vector3.new(sine, 0, cosine)
                local finalPosition = floor.Position + negativeDirection + traversing
                return finalPosition
        end
        AutoPlayModule.lobby = {
                isChooserAvailable = function()
                        return AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options.Visible
                end,
                updateChoice = function(choice)
                        AutoPlayModule.lobbyChoice = choice
                end,
                getMapChoice = function()
                        local choice = AutoPlayModule.lobbyChoice or math.random(1, 3)
                        local collider =
                                AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.Colliders:FindFirstChild(choice)
                        return collider
                end,
                getPadPosition = function()
                        if not AutoPlayModule.lobby.isChooserAvailable() then
                                AutoPlayModule.lobbyChoice = nil
                                return
                        end
                        local choice = AutoPlayModule.lobby.getMapChoice()
                        if not choice then
                                return
                        end
                        return choice.Position, choice.Name
                end,
        }
        AutoPlayModule.movement = {
                removeCache = function()
                        if AutoPlayModule.animationCache then
                                AutoPlayModule.animationCache = nil
                        end
                end,
                createJumpVelocity = function(player)
                        local maxForce = math.huge
                        local velocity = Instance.new("BodyVelocity")
                        velocity.MaxForce = Vector3.new(maxForce, maxForce, maxForce)
                        velocity.Velocity = Vector3.new(0, 80, 0)
                        velocity.Parent = player.Character.HumanoidRootPart
                        AutoPlayModule.customService.Debris:AddItem(velocity, 0.001)
                        pcall(function()
                                AutoPlayModule.customService.ReplicatedStorage.Remotes.DoubleJump:FireServer()
                        end)
                end,
                playJumpAnimation = function(player)
                        if not AutoPlayModule.animationCache then
                                local doubleJumpAnimation =
                                        AutoPlayModule.customService.ReplicatedStorage.Assets.Tutorial.Animations.DoubleJump
                                AutoPlayModule.animationCache = player.Character.Humanoid.Animator:LoadAnimation(doubleJumpAnimation)
                        end
                        if AutoPlayModule.animationCache then
                                AutoPlayModule.animationCache:Play()
                        end
                end,
                doubleJump = function(player)
                        if AutoPlayModule.doubleJumped then
                                return
                        end
                        if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE) then
                                return
                        end
                        AutoPlayModule.doubleJumped = true
                        AutoPlayModule.movement.createJumpVelocity(player)
                        AutoPlayModule.movement.playJumpAnimation(player)
                end,
                jump = function(player)
                        if not AutoPlayModule.CONFIG.JUMPING_ENABLED then
                                return
                        end
                        if not AutoPlayModule.playerHelper.onGround(player.Character) then
                                AutoPlayModule.movement.doubleJump(player)
                                return
                        end
                        if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.JUMP_PERCENTAGE) then
                                return
                        end
                        AutoPlayModule.doubleJumped = false
                        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end,
                move = function(player, playerPosition)
                        player.Character.Humanoid:MoveTo(playerPosition)
                end,
                stop = function(player)
                        local playerPosition = player.Character.HumanoidRootPart.Position
                        player.Character.Humanoid:MoveTo(playerPosition)
                end,
        }
        AutoPlayModule.signal = {
                connect = function(name, connection, callback)
                        if not name then
                                name = AutoPlayModule.customService.HttpService:GenerateGUID()
                        end
                        AutoPlayModule.signals[name] = connection:Connect(callback)
                        return AutoPlayModule.signals[name]
                end,
                disconnect = function(name)
                        if not name or not AutoPlayModule.signals[name] then
                                return
                        end
                        AutoPlayModule.signals[name]:Disconnect()
                        AutoPlayModule.signals[name] = nil
                end,
                stop = function()
                        for name, connection in pairs(AutoPlayModule.signals) do
                                if typeof(connection) ~= "RBXScriptConnection" then
                                        continue
                                end
                                connection:Disconnect()
                                AutoPlayModule.signals[name] = nil
                        end
                end,
        }
        AutoPlayModule.findPath = function(inLobby, delta)
                local rootPosition = AutoPlayModule.customService.Players.LocalPlayer.Character.HumanoidRootPart.Position
                if inLobby then
                        local padPosition, padNumber = AutoPlayModule.lobby.getPadPosition()
                        local choice = tonumber(padNumber)
                        if choice then
                                AutoPlayModule.lobby.updateChoice(choice)
                                if getgenv().AutoVote then
                                        pcall(function()
                                                game:GetService("ReplicatedStorage")
                                                        :WaitForChild("Packages")
                                                        :WaitForChild("_Index")
                                                        :WaitForChild("sleitnick_net@0.1.0")
                                                        :WaitForChild("net")
                                                        :WaitForChild("RE/UpdateVotes")
                                                        :FireServer("FFA")
                                        end)
                                end
                        end
                        if not padPosition then
                                return
                        end
                        return AutoPlayModule.getCurve(rootPosition, padPosition, delta)
                end
                local randomPosition = AutoPlayModule.getRandomPosition()
                if not randomPosition then
                        return
                end
                return AutoPlayModule.getCurve(rootPosition, randomPosition, delta)
        end
        AutoPlayModule.followPath = function(delta)
                if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then
                        AutoPlayModule.movement.removeCache()
                        return
                end
                local inLobby = AutoPlayModule.customService.Players.LocalPlayer.Character.Parent
                        == AutoPlayModule.customService.Workspace.Dead
                local path = AutoPlayModule.findPath(inLobby, delta)
                if not path then
                        AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer)
                        return
                end
                AutoPlayModule.movement.move(AutoPlayModule.customService.Players.LocalPlayer, path)
                AutoPlayModule.movement.jump(AutoPlayModule.customService.Players.LocalPlayer)
        end
        AutoPlayModule.finishThread = function()
                AutoPlayModule.signal.disconnect("auto-play")
                AutoPlayModule.signal.disconnect("synchronize")
                if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then
                        return
                end
                AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer)
        end
        AutoPlayModule.runThread = function()
                AutoPlayModule.signal.connect(
                        "auto-play",
                        AutoPlayModule.customService.RunService.PostSimulation,
                        AutoPlayModule.followPath
                )
                AutoPlayModule.signal.connect(
                        "synchronize",
                        AutoPlayModule.customService.RunService.PostSimulation,
                        AutoPlayModule.ballUtils.getBall
                )
        end

        local AutoPlay = player:create_module({
                title = "Auto Play",
                flag = "AutoPlay",
                description = "Automatically Plays Game",
                section = "left",
                callback = function(value)
                        if value then
                                AutoPlayModule.runThread()
                        else
                                AutoPlayModule.finishThread()
                        end
                end,
        })
        local AntiAFK = AutoPlay:create_checkbox({
                title = "Anti AFK",
                flag = "AutoPlayAntiAFK",
                callback = function(value)
                        if value then
                                local GC = getconnections or get_signal_cons
                                if GC then
                                        for i, v in pairs(GC(Players.LocalPlayer.Idled)) do
                                                if v["Disable"] then
                                                        v["Disable"](v)
                                                elseif v["Disconnect"] then
                                                        v["Disconnect"](v)
                                                end
                                        end
                                else
                                        local VirtualUser = cloneref(game:GetService("VirtualUser"))
                                        Players.LocalPlayer.Idled:Connect(function()
                                                VirtualUser:CaptureController()
                                                VirtualUser:ClickButton2(Vector2.new())
                                        end)
                                end
                        end
                end,
        })
        AntiAFK:change_state(true)
        AutoPlay:create_checkbox({
                title = "Enable Jumping",
                flag = "jumping_enabled",
                callback = function(value)
                        AutoPlayModule.CONFIG.JUMPING_ENABLED = value
                end,
        })
        AutoPlay:create_checkbox({
                title = "Auto Vote",
                flag = "AutoVote",
                callback = function(value)
                        getgenv().AutoVote = value
                end,
        })
        AutoPlay:create_divider({})
        AutoPlay:create_slider({
                title = "Distance From Ball",
                flag = "default_distance",
                maximum_value = 100,
                minimum_value = 5,
                value = AutoPlayModule.CONFIG.DEFAULT_DISTANCE,
                round_number = true,
                callback = function(value)
                        AutoPlayModule.CONFIG.DEFAULT_DISTANCE = value
                end,
        })
        AutoPlay:create_slider({
                title = "Speed Multiplier",
                flag = "multiplier_threshold",
                maximum_value = 200,
                minimum_value = 10,
                value = AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD,
                round_number = true,
                callback = function(value)
                        AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD = value
                end,
        })
        AutoPlay:create_slider({
                title = "Transversing",
                flag = "traversing",
                maximum_value = 100,
                minimum_value = 0,
                value = AutoPlayModule.CONFIG.TRAVERSING,
                round_number = true,
                callback = function(value)
                        AutoPlayModule.CONFIG.TRAVERSING = value
                end,
        })
        AutoPlay:create_slider({
                title = "Direction",
                flag = "Direction",
                maximum_value = 1,
                minimum_value = -1,
                value = AutoPlayModule.CONFIG.DIRECTION,
                round_number = false,
                callback = function(value)
                        AutoPlayModule.CONFIG.DIRECTION = value
                end,
        })
        AutoPlay:create_slider({
                title = "Offset Factor",
                flag = "OffsetFactor",
                maximum_value = 1,
                minimum_value = 0.1,
                value = AutoPlayModule.CONFIG.OFFSET_FACTOR,
                round_number = false,
                callback = function(value)
                        AutoPlayModule.CONFIG.OFFSET_FACTOR = value
                end,
        })
        AutoPlay:create_slider({
                title = "Movement Duration",
                flag = "MovementDuration",
                maximum_value = 1,
                minimum_value = 0.1,
                value = AutoPlayModule.CONFIG.MOVEMENT_DURATION,
                round_number = false,
                callback = function(value)
                        AutoPlayModule.CONFIG.MOVEMENT_DURATION = value
                end,
        })
        AutoPlay:create_slider({
                title = "Generation Threshold",
                flag = "GenerationThreshold",
                maximum_value = 0.5,
                minimum_value = 0.1,
                value = AutoPlayModule.CONFIG.GENERATION_THRESHOLD,
                round_number = false,
                callback = function(value)
                        AutoPlayModule.CONFIG.GENERATION_THRESHOLD = value
                end,
        })
        AutoPlay:create_slider({
                title = "Jump Chance",
                flag = "jump_percentage",
                maximum_value = 100,
                minimum_value = 0,
                value = AutoPlayModule.CONFIG.JUMP_PERCENTAGE,
                round_number = true,
                callback = function(value)
                        AutoPlayModule.CONFIG.JUMP_PERCENTAGE = value
                end,
        })
        AutoPlay:create_slider({
                title = "Double Jump Chance",
                flag = "double_jump_percentage",
                maximum_value = 100,
                minimum_value = 0,
                value = AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE,
                round_number = true,
                callback = function(value)
                        AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE = value
                end,
        })
getgenv()._KERO_SetupBallStatsVisualiserQuantum = function()
local VelocityGui
local updateConn
local peakVelocity = 0

local BallStats = misc:create_module({
    title = "Ball Stats",
    flag = "ballStats",
    description = "Displays the current ball speed and peak velocity",
    section = "left",
    callback = function(value)
        if value then
            if not VelocityGui then
                local player = game.Players.LocalPlayer


                VelocityGui = Instance.new("ScreenGui")
                local VelocityFrame = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local UIGradient = Instance.new("UIGradient")
                local ImageButton = Instance.new("ImageButton")
                local UICorner_2 = Instance.new("UICorner")
                local PeakVelocity = Instance.new("TextLabel")
                local Velocity = Instance.new("TextLabel")

                VelocityGui.Name = "VelocityGui"
                VelocityGui.Parent = player:WaitForChild("PlayerGui")
                VelocityGui.ResetOnSpawn = false

                VelocityFrame.Name = "VelocityFrame"
                VelocityFrame.Parent = VelocityGui
                VelocityFrame.BackgroundColor3 = Color3.fromRGB(25, 8, 8)
                VelocityFrame.BackgroundTransparency = 0.3
                VelocityFrame.Size = UDim2.new(0, 200, 0, 100)
                VelocityFrame.Position = UDim2.new(0.2, 0, 0.18, 0)
                UICorner.Parent = VelocityFrame

                                UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 8, 8)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 8, 8))}
                                UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 1.00)}
                                UIGradient.Parent = VelocityFrame

                                ImageButton.Parent = VelocityFrame
                                ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                ImageButton.BackgroundTransparency = 1.000
                                ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                ImageButton.BorderSizePixel = 0
                                ImageButton.Size = UDim2.new(0, 200, 0, 100)
                                ImageButton.Image = "rbxassetid://10149736886"
                                ImageButton.Active = false

                                local stroke = Instance.new("UIStroke")
                                stroke.Parent = ImageButton
                                stroke.Color = Color3.fromRGB(0, 0, 0)
                                stroke.Thickness = 3
                                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                                UICorner_2.Parent = ImageButton

                                PeakVelocity.Name = "PeakVelocity"
                                PeakVelocity.Parent = ImageButton
                                PeakVelocity.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                PeakVelocity.BackgroundTransparency = 1.000
                                PeakVelocity.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                PeakVelocity.BorderSizePixel = 0
                                PeakVelocity.Position = UDim2.new(0, 0, 0.5, 0)
                                PeakVelocity.Size = UDim2.new(0, 200, 0, 50)
                                PeakVelocity.Font = Enum.Font.SourceSans
                                PeakVelocity.Text = "Peak Velocity:"
                                PeakVelocity.TextColor3 = Color3.fromRGB(0, 0, 0)
                                PeakVelocity.TextScaled = true
                                PeakVelocity.TextSize = 14.000
                                PeakVelocity.TextWrapped = true

                                Velocity.Name = "Velocity"
                                Velocity.Parent = ImageButton
                                Velocity.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                Velocity.BackgroundTransparency = 1.000
                                Velocity.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                Velocity.BorderSizePixel = 0
                                Velocity.Size = UDim2.new(0, 200, 0, 50)
                                Velocity.Font = Enum.Font.SourceSans
                                Velocity.Text = "Velocity"
                                Velocity.TextColor3 = Color3.fromRGB(0, 0, 0)
                                Velocity.TextScaled = true
                                Velocity.TextSize = 14.000
                                Velocity.TextWrapped = true

                local TweenService = game:GetService("TweenService")
                                local UserInputService = game:GetService("UserInputService")

                                local function makeDraggable(frame)
                                        local dragging = false
                                        local dragInput, dragStart, startPos

                                        local function update(input)
                                                local delta = input.Position - dragStart
                                                local newPos = UDim2.new(
                                                        startPos.X.Scale,
                                                        startPos.X.Offset + delta.X,
                                                        startPos.Y.Scale,
                                                        startPos.Y.Offset + delta.Y
                                                )

                                                TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                                        Position = newPos
                                                }):Play()
                                        end

                                        frame.Active = true
                                        frame.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                                        dragging = true
                                                        dragStart = input.Position
                                                        startPos = frame.Position

                                                        input.Changed:Connect(function()
                                                                if input.UserInputState == Enum.UserInputState.End then
                                                                        dragging = false
                                                                end
                                                        end)
                                                end
                                        end)

                                        frame.InputChanged:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseMovement then
                                                        dragInput = input
                                                end
                                        end)

                                        UserInputService.InputChanged:Connect(function(input)
                                                if input == dragInput and dragging then
                                                        update(input)
                                                end
                                        end)
                                end


                                makeDraggable(ImageButton)


                updateConn = game:GetService("RunService").RenderStepped:Connect(function()
                    local Balls = Auto_Parry.Get_Balls() or {}
                    local speedShown = false
                    for _, Ball in ipairs(Balls) do
                        local zoomies = Ball:FindFirstChild("zoomies")
                        if zoomies then
                            local speed = zoomies.VectorVelocity.Magnitude
                            Velocity.Text = ("Velocity: %.2f"):format(speed)
                            if speed > peakVelocity then
                                peakVelocity = speed
                                PeakVelocity.Text = ("Peak Velocity: %.2f"):format(peakVelocity)
                            end
                            speedShown = true
                            break
                        end
                    end
                    if not speedShown then
                        Velocity.Text = "Velocity: 0.0"
                    end
                end)
            end
        else
            if updateConn then
                updateConn:Disconnect()
                updateConn = nil
            end
            if VelocityGui then
                VelocityGui:Destroy()
                VelocityGui = nil
            end
            peakVelocity = 0
        end
    end,
})

        local visualPart
        local Visualiser = misc:create_module({
                title = "Visualiser",
                flag = "Visualiser",
                description = "Parry Range Visualiser",
                section = "right",
                callback = function(value)
                        if value then
                                if not visualPart then
                                        visualPart = Instance.new("Part")
                                        visualPart.Name = "VisualiserPart"
                                        visualPart.Shape = Enum.PartType.Ball
                                        visualPart.Material = Enum.Material.ForceField
                                        visualPart.Color = Color3.fromRGB(255, 255, 255)
                                        visualPart.Transparency = 0
                                        visualPart.CastShadow = false
                                        visualPart.Anchored = true
                                        visualPart.CanCollide = false
                                        visualPart.Parent = workspace
                                end
                                Connections_Manager["Visualiser"] = game:GetService("RunService").RenderStepped:Connect(function()
                                        local character = Player.Character
                                        local HumanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                                        if HumanoidRootPart and visualPart then
                                                visualPart.CFrame = HumanoidRootPart.CFrame
                                        end
                                        if getgenv().VisualiserRainbow then
                                                local hue = (tick() % 5) / 5
                                                visualPart.Color = Color3.fromHSV(hue, 1, 1)
                                        else
                                                local hueVal = getgenv().VisualiserHue or 0
                                                visualPart.Color = Color3.fromHSV(hueVal / 360, 1, 1)
                                        end
                                        local speed = 0
                                        local maxSpeed = 350
                                        local Balls = Auto_Parry.Get_Balls()
                                        for _, Ball in pairs(Balls) do
                                                if Ball and Ball:FindFirstChild("zoomies") then
                                                        local Velocity = Ball.AssemblyLinearVelocity
                                                        speed = math.min(Velocity.Magnitude, maxSpeed) / 6.5
                                                        break
                                                end
                                        end
                                        local size = math.max(speed, 6.5)
                                        if visualPart then
                                                visualPart.Size = Vector3.new(size, size, size)
                                        end
                                end)
                        else
                                if Connections_Manager["Visualiser"] then
                                        Connections_Manager["Visualiser"]:Disconnect()
                                        Connections_Manager["Visualiser"] = nil
                                end
                                if visualPart then
                                        visualPart:Destroy()
                                        visualPart = nil
                                end
                        end
                end,
        })
        Visualiser:create_checkbox({
                title = "Rainbow",
                flag = "VisualiserRainbow",
                callback = function(value)
                        getgenv().VisualiserRainbow = value
                end,
        })
        Visualiser:create_slider({
                title = "Color Hue",
                flag = "VisualiserHue",
                minimum_value = 0,
                maximum_value = 360,
                value = 0,
                callback = function(value)
                        getgenv().VisualiserHue = value
                end,
        })
        local DisableQuantumEffects = world:create_module({
                title = "Disable Quantum Arena Effects",
                flag = "NoQuantumEffects",
                description = "Disables Quantum Arena effects.",
                section = "left",
                callback = function(value)
                        getgenv().NoQuantumEffects = value
                        if value then

                        task.spawn(function()
                                        local quantumfx
                                        local _quantumTimeout = 0
                                        while getgenv().NoQuantumEffects and not quantumfx and _quantumTimeout < 50 do
                                                for _, v in getconnections(ReplicatedStorage.Remotes.QuantumArena.OnClientEvent) do
                                                        quantumfx = v
                                                        v:Disable()
                                                end
                                                task.wait(0.2)
                                                _quantumTimeout = _quantumTimeout + 1
                                        end
                                end)
                        end
                end,
        })
end
_KERO_SetupBallStatsVisualiserQuantum()

-- ============================================================
-- 5. AVATAR CHANGER — Change your avatar to look like anyone
-- ============================================================
getgenv()._KERO_SetupAvatarChanger = function()
    local AvatarChanger = {
        Enabled = false,
        _desc = nil,
        _originalDesc = nil,
        _conn = nil,
        _loopConn = nil,
        _name = "",
    }
    getgenv().KERO_AvatarChanger = AvatarChanger

    -- Save original description
    pcall(function()
        AvatarChanger._originalDesc = game.Players:GetHumanoidDescriptionFromUserId(Player.UserId)
    end)

    AvatarChanger._apply = function(char)
        if not char or not AvatarChanger._desc then return end
        local hum = char:WaitForChild("Humanoid", 3)
        if not hum then return end
        Player:ClearCharacterAppearance()
        hum:ApplyDescriptionClientServer(AvatarChanger._desc)
    end

    AvatarChanger._start = function()
        if AvatarChanger._conn then AvatarChanger._conn:Disconnect() end
        if AvatarChanger._loopConn then AvatarChanger._loopConn:Disconnect() end

        AvatarChanger._conn = Player.CharacterAdded:Connect(function(char)
            task.wait(1)
            if AvatarChanger.Enabled then AvatarChanger._apply(char) end
        end)

        local lastApply = 0
        AvatarChanger._loopConn = RunService.Heartbeat:Connect(function()
            if not AvatarChanger.Enabled or not AvatarChanger._desc then return end
            if (tick() - lastApply) < 2 then return end
            lastApply = tick()
            pcall(function()
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                local current = hum:GetAppliedDescription()
                if current and current.Face ~= AvatarChanger._desc.Face then
                    Player:ClearCharacterAppearance()
                    hum:ApplyDescriptionClientServer(AvatarChanger._desc)
                end
            end)
        end)

        -- Apply immediately
        if Player.Character then AvatarChanger._apply(Player.Character) end
    end

    AvatarChanger._stop = function()
        if AvatarChanger._conn then AvatarChanger._conn:Disconnect(); AvatarChanger._conn = nil end
        if AvatarChanger._loopConn then AvatarChanger._loopConn:Disconnect(); AvatarChanger._loopConn = nil end
        AvatarChanger._desc = nil
        pcall(function()
            local char = Player.Character
            if char and AvatarChanger._originalDesc then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    Player:ClearCharacterAppearance()
                    hum:ApplyDescriptionClientServer(AvatarChanger._originalDesc)
                end
            end
        end)
    end

    local avatarModule = world:create_module({
        title = "Avatar Changer",
        flag = "AvatarChanger",
        description = "Changes your avatar to look like another player (by username or userId). Auto-reapplies on respawn.",
        section = "right",
        callback = function(state)
            AvatarChanger.Enabled = state
            if state then
                if AvatarChanger._name and AvatarChanger._name ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local userId
                            local asNum = tonumber(AvatarChanger._name)
                            if asNum then
                                userId = asNum
                            else
                                userId = game.Players:GetUserIdFromNameAsync(AvatarChanger._name)
                            end
                            if userId then
                                AvatarChanger._desc = game.Players:GetHumanoidDescriptionFromUserId(userId)
                                AvatarChanger._start()
                            end
                        end)
                    end)
                end
            else
                AvatarChanger._stop()
            end
        end,
    })

    local avatarTextbox = avatarModule:create_textbox({
        title = "￬ Username or UserId ￬",
        placeholder = "Enter username or userId...",
        flag = "AvatarChangerTextbox",
        callback = function(text)
            AvatarChanger._name = text
            if AvatarChanger.Enabled and text ~= "" then
                task.spawn(function()
                    pcall(function()
                        local userId
                        local asNum = tonumber(text)
                        if asNum then
                            userId = asNum
                        else
                            userId = game.Players:GetUserIdFromNameAsync(text)
                        end
                        if userId then
                            AvatarChanger._desc = game.Players:GetHumanoidDescriptionFromUserId(userId)
                            AvatarChanger._start()
                        end
                    end)
                end)
            end
        end,
    })

    local No_Render = misc:create_module({
                title = "No Render",
                flag = "No_Render",
                description = "Disables rendering of effects",
                section = "right",
                callback = function(state)
                        Player.PlayerScripts.EffectScripts.ClientFX.Disabled = state
                        if state then
                                Connections_Manager["No Render"] = workspace.Runtime.ChildAdded:Connect(function(Value)
                                        Debris:AddItem(Value, 0)
                                end)
                        else
                                if Connections_Manager["No Render"] then
                                        Connections_Manager["No Render"]:Disconnect()
                                        Connections_Manager["No Render"] = nil
                                end
                        end
                end,
        })
        local CustomAnnouncer = misc:create_module({
                title = "Custom Announcer",
                flag = "Custom_Announcer",
                description = "Customize the game announcements",
                section = "right",
                callback = function(value)
                        if value then
                                local Announcer = Player.PlayerGui:WaitForChild("announcer")
                                local Winner = Announcer:FindFirstChild("Winner")
                                if Winner then
                                        Winner.Text = Library._config._flags["announcer_text"] or "https://discord.gg/KHPMBbtDUF"
                                end
                                Announcer.ChildAdded:Connect(function(Value)
                                        if Value.Name == "Winner" then
                                                Value.Changed:Connect(function(Property)
                                                        if Property == "Text" and Library._config._flags["Custom_Announcer"] then
                                                                Value.Text = Library._config._flags["announcer_text"] or "https://discord.gg/KHPMBbtDUF"
                                                        end
                                                end)
                                                if Library._config._flags["Custom_Announcer"] then
                                                        Value.Text = Library._config._flags["announcer_text"] or "https://discord.gg/KHPMBbtDUF"
                                                end
                                        end
                                end)
                        end
                end,
        })
        CustomAnnouncer:create_textbox({
                title = "Custom Announcement Text",
                placeholder = "Enter custom announcer text... ",
                flag = "announcer_text",
                callback = function(text)
                        Library._config._flags["announcer_text"] = text
                        if Library._config._flags["Custom_Announcer"] then
                                local Announcer = Player.PlayerGui:WaitForChild("announcer")
                                local Winner = Announcer:FindFirstChild("Winner")
                                if Winner then
                                        Winner.Text = text
                                end
                        end
                end,
        })
end
_KERO_SetupAvatarChanger()
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
        if root.Parent and root.Parent ~= Player.Character then
                if root.Parent.Parent ~= workspace.Alive then
                        return
                end
        end
        Auto_Parry.Closest_Player()
        local Ball = Auto_Parry.Get_Ball()
        if not Ball then
                return
        end
        local Target_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
        local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
        local Dot = Direction:Dot(Ball.AssemblyLinearVelocity.Unit)
        local Curve_Detected = Auto_Parry.Is_Curved()
        if Target_Distance < 15 and Distance < 15 and Dot > 0 then
                if Curve_Detected then
                        Auto_Parry.Parry(Selected_Parry_Type)
                end
        end
        if not Grab_Parry then
                return
        end
        Grab_Parry:Stop()
end)
ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if Player.Character.Parent ~= workspace.Alive then
                return
        end
        if not Grab_Parry then
                return
        end
        Grab_Parry:Stop()
end)
workspace.Balls.ChildAdded:Connect(function()
        Parried = false
end)
workspace.Balls.ChildRemoved:Connect(function(Value)
        Parries = 0
        Parried = false
        if Connections_Manager["Target Change"] then
                Connections_Manager["Target Change"]:Disconnect()
                Connections_Manager["Target Change"] = nil
        end
end)

function SendMessageEMBED(url, embed)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                }
            }
        }
    }
    local body = http:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

getgenv()._KERO_ApplyTheme = function()
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local BallsGui = CoreGui:WaitForChild("KeroHub", 60)

if not BallsGui then
    warn("Could not find the 'KeroHub' GUI. The original script may have failed to load.")
    return
end

local Container = BallsGui:WaitForChild("Container", 30)

if not Container then
    warn("Could not find the 'Container' frame. The original script may have failed to load.")
    return
end

-- Transparent + eye-friendly theme
local THEME = {
    -- Soft dark background (transparent, easy on eyes)
    BACKGROUND = Color3.fromRGB(18, 18, 22),
    BACKGROUND_TRANSPARENCY = 0.45,
    -- Soft white text (not harsh pure white)
    TEXT = Color3.fromRGB(225, 225, 228),
    -- Soft red accent (not aggressive)
    ACCENT = Color3.fromRGB(180, 45, 45),
    STROKE = Color3.fromRGB(120, 35, 35)
}

-- Apply transparency to main container
pcall(function()
    Container.BackgroundTransparency = THEME.BACKGROUND_TRANSPARENCY
    Container.BackgroundColor3 = THEME.BACKGROUND

    -- Soft glass border
    local existingStroke = Container:FindFirstChildOfClass("UIStroke")
    if not existingStroke then
        local glassStroke = Instance.new("UIStroke")
        glassStroke.Name = "KERO_GlassStroke"
        glassStroke.Color = THEME.STROKE
        glassStroke.Thickness = 1
        glassStroke.Transparency = 0.4
        glassStroke.Parent = Container
    end
end)

local function applyTheme(object)

    if object.Name == "BrandBar" or object.Name == "Icon" or object.Name == "ClientName" then
        return
    end

    local ancestor = object.Parent
    while ancestor do
        if ancestor.Name == "BrandBar" then return end
        ancestor = ancestor.Parent
    end

    -- Skip our own elements
    if object.Name == "KERO_GlassStroke" then return end

    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        local isRedAccent = object.TextColor3.R > 0.5 and object.TextColor3.G < 0.4 and object.TextColor3.B < 0.4
        if not isRedAccent then
            object.TextColor3 = THEME.TEXT
        end
        object.TextTransparency = 0
    end

    if object:IsA("Frame") or object:IsA("ScrollingFrame") then
        if object.BackgroundTransparency < 1 then
            local bg = object.BackgroundColor3
            local isRedAccent = bg.R > 0.4 and bg.G < 0.4 and bg.B < 0.4
            if not isRedAccent then
                object.BackgroundColor3 = THEME.BACKGROUND
            end
        end
    end

    if object:IsA("UIStroke") then
        object.Color = THEME.STROKE
        object.Thickness = 1
    end

    if object:IsA("ImageLabel") or object:IsA("ImageButton") then
        object.ImageColor3 = THEME.TEXT
    end
end

for _, descendant in ipairs(Container:GetDescendants()) do
    pcall(applyTheme, descendant)
end

Container.DescendantAdded:Connect(function(descendant)
    pcall(applyTheme, descendant)
end)
end
getgenv()._KERO_ApplyTheme()

-- ═══════════════════════════════════════════════════════════════════
-- EXTRA FEATURES
-- Anti Phantom, Ability ESP, Korblox+Headless, Ball Stats, Avatar Changer
-- ═══════════════════════════════════════════════════════════════════

-- ============================================================
-- 1. ANTI PHANTOM — Detects Phantom ability and dodges behind ball
-- ============================================================
getgenv()._KERO_SetupAntiPhantom = function()
    local AntiPhantom = {
        Enabled = false,
        _active = false,
        _conn = nil,
    }
    getgenv().KERO_AntiPhantom = AntiPhantom

    local antiPhantomModule = misc:create_module({
        title = "Anti Phantom",
        flag = "AntiPhantom",
        description = "Detects Phantom ability (maxTransmission/transmissionpart) and tweens you behind the ball to dodge it.",
        section = "left",
        callback = function(state)
            AntiPhantom.Enabled = state
            if state then
                AntiPhantom._conn = workspace.Runtime.ChildAdded:Connect(function(part)
                    pcall(function()
                        local character = Player.Character
                        if not character then return end
                        local partName = part.Name:lower()
                        if partName ~= "maxtransmission" and part.Name ~= "transmissionpart" then return end
                        local weld = part:FindFirstChildWhichIsA("WeldConstraint")
                        if not weld then return end
                        for _, ball in workspace.Balls:GetChildren() do
                            if not ball:FindFirstChild("zoomies") then continue end
                            if AntiPhantom._active then continue end
                            AntiPhantom._active = true
                            local cancelled = false
                            task.spawn(function()
                                local startTime = tick()
                                while tick() - startTime < 1 and ball.Parent and not cancelled do
                                    task.wait()
                                    local tweenService = game:GetService("TweenService")
                                    tweenService:Create(
                                        character.HumanoidRootPart,
                                        TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                                        { CFrame = ball.CFrame * CFrame.new(0, 0, -3) }
                                    ):Play()
                                end
                                AntiPhantom._active = false
                            end)
                            ball:GetAttributeChangedSignal("target"):Once(function()
                                cancelled = true
                                AntiPhantom._active = false
                            end)
                        end
                    end)
                end)
            else
                if AntiPhantom._conn then
                    AntiPhantom._conn:Disconnect()
                    AntiPhantom._conn = nil
                end
                AntiPhantom._active = false
            end
        end,
    })
end
getgenv()._KERO_SetupAntiPhantom()

-- ============================================================
-- 3. KORBLOX + HEADLESS — Makes head + right leg transparent
-- ============================================================
getgenv()._KERO_SetupKorblox = function()
    local KorbloxHeadless = {
        Enabled = false,
        _conn = nil,
        _respawnConn = nil,
    }
    getgenv().KERO_KorbloxHeadless = KorbloxHeadless

    KorbloxHeadless._KorbloxHeadless._R15_PARTS = {"RightUpperLeg", "RightLowerLeg", "RightFoot"}

    KorbloxHeadless._update = function()
        local character = Player.Character
        if not character then return end
        -- Headless
        local head = character:FindFirstChild("Head")
        if head then
            if head.Transparency ~= 1 then head.Transparency = 1 end
            local face = head:FindFirstChild("face")
            if face and face:IsA("Decal") then
                if face.Transparency ~= 1 then face.Transparency = 1 end
            end
        end
        -- Korblox R15
        for _, partName in ipairs(KorbloxHeadless._R15_PARTS) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                if part.Transparency ~= 1 then part.Transparency = 1 end
            end
        end
        -- Korblox R6
        local r6Part = character:FindFirstChild("Right Leg")
        if r6Part and r6Part:IsA("BasePart") then
            if r6Part.Transparency ~= 1 then r6Part.Transparency = 1 end
        end
    end

    KorbloxHeadless._restore = function()
        local character = Player.Character
        if not character then return end
        local head = character:FindFirstChild("Head")
        if head then
            head.Transparency = 0
            local face = head:FindFirstChild("face")
            if face and face:IsA("Decal") then face.Transparency = 0 end
        end
        for _, partName in ipairs(KorbloxHeadless._R15_PARTS) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then part.Transparency = 0 end
        end
        local r6Part = character:FindFirstChild("Right Leg")
        if r6Part and r6Part:IsA("BasePart") then r6Part.Transparency = 0 end
    end

    KorbloxHeadless._apply = function(enable)
        if enable then
            if not KorbloxHeadless._conn then
                KorbloxHeadless._conn = RunService.RenderStepped:Connect(KorbloxHeadless._update)
            end
            if not KorbloxHeadless._respawnConn then
                KorbloxHeadless._respawnConn = Player.CharacterAdded:Connect(function(char)
                    task.wait(1)
                    if KorbloxHeadless.Enabled then KorbloxHeadless._update() end
                end)
            end
        else
            if KorbloxHeadless._conn then
                KorbloxHeadless._conn:Disconnect()
                KorbloxHeadless._conn = nil
            end
            KorbloxHeadless._restore()
        end
    end

    local korbloxModule = misc:create_module({
        title = "Korblox + Headless",
        flag = "KorbloxHeadless",
        description = "Makes your head + right leg transparent (Korblox + Headless look). R15 & R6 supported.",
        section = "right",
        callback = function(state)
            KorbloxHeadless.Enabled = state
            task.spawn(function()
                KorbloxHeadless._apply(state)
            end)
        end,
    })
end
getgenv()._KERO_SetupKorblox()
