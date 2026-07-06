local Library = loadstring(game:HttpGet("https://pastefy.app/g3O0Z6qz/raw"))()

local library = Library.new()
library:load()

local AutoparryTab = library:create_tab("Main", "rbxassetid://76499042599127")
local DetectionTab = library:create_tab("Detection", "rbxassetid://126017907477623")
local MiscTab = library:create_tab("Misc", "rbxassetid://126017907477623")

local function Notify(settings)
    Library.SendNotification({ 
        title = settings.Title or settings.title or "Notification",
        text = settings.Content or settings.text or settings.Content or "No message",
        duration = settings.Duration or settings.duration or 3 
    })
end

local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local Stats = cloneref(game:GetService('Stats'))
local Players = cloneref(game:GetService('Players'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local RunService = cloneref(game:GetService('RunService'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))
local TweenService = cloneref(game:GetService('TweenService'))
local Workspace = cloneref(game:GetService('Workspace'))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

if not LocalPlayer or not LocalPlayer.Character then
    if LocalPlayer then LocalPlayer.CharacterAdded:Wait() end
end

local Alive = Workspace:FindFirstChild("Alive") or Workspace:WaitForChild("Alive")
local Runtime = Workspace.Runtime

local System = {
    __properties = {
        __autoparry_enabled = false,
        __manual_spam_enabled = false,
        __auto_spam_enabled = false,
        __curve_mode = 1,
        __accuracy = 1,
        __divisor_multiplier = 1.1,
        __parried = false,
        __training_parried = false,
        __spam_threshold = 1.5,
        __parries = 0,
        __parry_key = nil,
        __grab_animation = nil,
        __tornado_time = tick(),
        __first_parry_done = false,
        __connections = {},
        __reverted_remotes = {},
        __spam_accumulator = 0,
        __spam_rate = 350,
        __randomized_accuracy_enabled = false,
        __is_mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
        __mobile_guis = {},
        __cps_counter = 0,
        __cps_timer = tick(),
        __cps_display = 0,
        __manual_spam_cps = 350,
        __manual_spam_running = false
    },
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High', 'RandomTarget', 'Left', 'Right'},
        __detections = {
            
        }
    },
    
}

getgenv().AutoParryMode = getgenv().AutoParryMode or "Remote"
getgenv().AutoParryNotify = getgenv().AutoParryNotify or false
getgenv().CooldownProtection = getgenv().CooldownProtection or false
getgenv().AutoAbility = getgenv().AutoAbility or false
getgenv().ManualSpamNotify = getgenv().ManualSpamNotify or false
getgenv().ManualSpamMode = getgenv().ManualSpamMode or "Remote"
getgenv().ManualSpamAnimationFix = getgenv().ManualSpamAnimationFix or false
getgenv().AutoSpamNotify = getgenv().AutoSpamNotify or false
getgenv().AutoSpamMode = getgenv().AutoSpamMode or "Remote"
getgenv().AutoSpamAnimationFix = getgenv().AutoSpamAnimationFix or false
getgenv().AbilityESP = getgenv().AbilityESP or false
getgenv().HeadlessKorbloxEnabled = getgenv().HeadlessKorbloxEnabled or false

local revertedRemotes = {}
local Parry_Key = nil
local PF = nil
local SC = nil

local remote, f_raw = nil, nil
local c = {nil, nil, nil, nil, nil, nil, nil}
local remoteHooked = false

local function isValidRemoteArgs_wh(args)
    return #args >= 4 and typeof(args[4]) == "CFrame"
end

pcall(function()
    local hookfn = hookfunction or (getgenv and getgenv().hookfunction) or (getgenv and getgenv().hookfunc)
    local newcc = newcclosure or (getgenv and getgenv().newcclosure) or function(f) return f end
    if hookfn and newcc then
        pcall(function()
            local dE = Instance.new("RemoteEvent")
            local dF = Instance.new("RemoteFunction")
            local origFS
            origFS = hookfn(dE.FireServer, newcc(function(self, ...)
                local args = {...}
                if isValidRemoteArgs_wh(args) then
                    if not remoteHooked then
                        remoteHooked = true
                        remote = self
                        f_raw = origFS
                        for i = 1, 7 do c[i] = args[i] end
                    else
                        for i = 1, 7 do c[i] = args[i] end
                    end
                end
                local curveCF = System and System.curve and System.curve.get_cframe and System.curve.get_cframe()
                if curveCF then args[4] = curveCF end
                return origFS(self, unpack(args))
            end))
            local origIS
            origIS = hookfn(dF.InvokeServer, newcc(function(self, ...)
                local args = {...}
                if isValidRemoteArgs_wh(args) then
                    if not remoteHooked then
                        remoteHooked = true
                        remote = self
                        f_raw = origIS
                        for i = 1, 7 do c[i] = args[i] end
                    else
                        for i = 1, 7 do c[i] = args[i] end
                    end
                end
                local curveCF = System and System.curve and System.curve.get_cframe and System.curve.get_cframe()
                if curveCF then args[4] = curveCF end
                return origIS(self, unpack(args))
            end))
            getgenv()._hookUsedStr = "HookFunction (Deep Bypass)"
            pcall(function()
                if Library and Library.SendNotification then
                    Library.SendNotification({ title = "Parry Hook", text = "HookFunction deep bypass installed", duration = 2 })
                else
                    print("Parry Hook: HookFunction deep bypass installed")
                end
            end)
        end)
    end
end)

-- metatable fallback to capture remote calls (best-effort)
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__index
    setreadonly(mt, false)
    mt.__index = function(self, key)
        if key == "FireServer" or key == "InvokeServer" then
            return function(instance, ...)
                local args = {...}
                if isValidRemoteArgs_wh(args) then
                    if not remoteHooked then
                        remoteHooked = true
                        remote = instance
                        f_raw = old(instance, "FireServer")
                        for i = 1, 7 do c[i] = args[i] end
                    else
                        for i = 1, 7 do c[i] = args[i] end
                    end
                end
                return old(self, key)(instance, ...)
            end
        end
        return old(self, key)
    end
    setreadonly(mt, true)
end)

local function fireParry_wh()
    if not (remote and f_raw) then return end
    local cam = workspace.CurrentCamera
    local char = LocalPlayer.Character
    if not char then return end
    local curveCF = System.curve.get_cframe()
    c[3] = curveCF and curveCF.LookVector or workspace.CurrentCamera.CFrame.LookVector
    c[4] = curveCF or workspace.CurrentCamera.CFrame
    c[5] = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok, sp = pcall(function() return cam:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if ok then c[5][tostring(entity)] = sp end
            end
        end
    end
    local vp = cam.ViewportSize
    c[6] = {vp.X/2, vp.Y/2}
    pcall(function() f_raw(remote, unpack(c)) end)
end

if ReplicatedStorage:FindFirstChild("Controllers") then
    for _, child in ipairs(ReplicatedStorage.Controllers:GetChildren()) do
        if child.Name:match("^SwordsController%s*$") then
            SC = child
        end
    end
end

local function update_divisor()
    -- Use Zen-style mapping so slider values match zen.lua behavior
    System.__properties.__divisor_multiplier = 0.7 + (System.__properties.__accuracy - 1) * 0.0035353535353535
end

local function update_randomized_accuracy()
    if not System.__properties.__randomized_accuracy_enabled then return end
    local ping_str = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    local ping = tonumber(ping_str:match("%d+")) or 0
    local new_accuracy
    if ping >= 90 then
        new_accuracy = 4
    elseif ping <= 50 then
        new_accuracy = math.random(70, 100)
    else
        new_accuracy = System.__properties.__accuracy
    end
    if new_accuracy then
        System.__properties.__accuracy = new_accuracy
        update_divisor()
    end
end

task.spawn(function()
    while task.wait(1) do
        if System.__properties.__randomized_accuracy_enabled then
            pcall(update_randomized_accuracy)
        end
    end
end)

local DualBypassSystem = {
    __properties = {
        __captured_data = nil,
        __first_parry_done = false,
        __test_bypass_enabled = true,
        __use_virtual_input_once = true,
        __virtual_input_used = false,
        __original_metatables = {},
        __active_hooks = {}
    }
}

function DualBypassSystem.isValidRemoteArgs(args)
    return #args == 7 and
        type(args[2]) == "string" and
        type(args[3]) == "number" and
        typeof(args[4]) == "CFrame" and
        type(args[5]) == "table" and
        type(args[6]) == "table" and
        type(args[7]) == "boolean"
end

function DualBypassSystem.hookRemote(remote)
    if not DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] then
        DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] = true
        local meta = getrawmetatable(remote)
        setreadonly(meta, false)

        local oldIndex = meta.__index
        meta.__index = function(self, key)
            if (key == "FireServer" and self:IsA("RemoteEvent")) or
               (key == "InvokeServer" and self:IsA("RemoteFunction")) then
                return function(obj, ...)
                    local args = {...}
                    if DualBypassSystem.isValidRemoteArgs(args) and not DualBypassSystem.__properties.__captured_data then
                        DualBypassSystem.__properties.__captured_data = {
                            remote = obj,
                            args = args
                        }
                    end
                    if DualBypassSystem.isValidRemoteArgs(args) and not revertedRemotes[obj] then
                        revertedRemotes[obj] = args
                        Parry_Key = args[2]
                    end
                    return oldIndex(self, key)(obj, unpack(args))
                end
            end
            return oldIndex(self, key)
        end
        setreadonly(meta, true)
    end
end

for _, remote in pairs(ReplicatedStorage:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        DualBypassSystem.hookRemote(remote)
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        DualBypassSystem.hookRemote(child)
    end
end)

function DualBypassSystem.execute_test_bypass()
    if not DualBypassSystem.__properties.__captured_data or not DualBypassSystem.__properties.__test_bypass_enabled then
        return
    end
    local captured = DualBypassSystem.__properties.__captured_data
    local remote = captured.remote
    local original_args = captured.args
    local camera = workspace.CurrentCamera
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local success, screen_point = pcall(function()
                    return camera:WorldToScreenPoint(entity.PrimaryPart.Position)
                end)
                if success then
                    event_data[entity.Name] = screen_point
                end
            end
        end
    end
    local is_mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local final_aim_target
    if is_mobile then
        local viewport = camera.ViewportSize
        final_aim_target = {viewport.X / 2, viewport.Y / 2}
    else
        local success, mouse = pcall(function()
            return UserInputService:GetMouseLocation()
        end)
        if success then
            final_aim_target = {mouse.X, mouse.Y}
        else
            final_aim_target = {0, 0}
        end
    end
    local modified_args = {
        original_args[1],
        original_args[2],
        original_args[3],
        camera.CFrame,
        event_data,
        final_aim_target,
        original_args[7]
    }
    pcall(function()
        if remote:IsA('RemoteEvent') then
            remote:FireServer(unpack(modified_args))
        elseif remote:IsA('RemoteFunction') then
            remote:InvokeServer(unpack(modified_args))
        end
    end)
end

System.animation = {}

function System.animation.play_grab_parry()
    -- Play animation feature removed per user request (no-op)
    return
end

System.ball = {}

function System.ball.get()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

function System.ball.get_all()
    local balls_table = {}
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return balls_table end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            table.insert(balls_table, ball)
        end
    end
    return balls_table
end

System.player = {}

local Closest_Entity = nil

function System.player.get_closest()
    local max_distance = math.huge
    local closest_entity = nil
    if not Alive then return nil end
    for _, entity in pairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character then
            if entity.PrimaryPart then
                local distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
                if distance < max_distance then
                    max_distance = distance
                    closest_entity = entity
                end
            end
        end
    end
    Closest_Entity = closest_entity
    return closest_entity
end

function System.player.get_closest_to_cursor()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        return nil
    end
    local closest_player = nil
    local minimal_dot = -math.huge
    local camera = workspace.CurrentCamera
    if not Alive then return nil end
    local success, mouse_location = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not success then return nil end
    local ray = camera:ScreenPointToRay(mouse_location.X, mouse_location.Y)
    local pointer = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
    for _, player in pairs(Alive:GetChildren()) do
        if player == LocalPlayer.Character then continue end
        if not player:FindFirstChild('HumanoidRootPart') then continue end
        local direction = (player.HumanoidRootPart.Position - camera.CFrame.Position).Unit
        local dot = pointer.LookVector:Dot(direction)
        if dot > minimal_dot then
            minimal_dot = dot
            closest_player = player
        end
    end
    return closest_player
end

System.curve = {}

function System.curve.get_cframe()
    local camera = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return camera.CFrame end
    local targetPart
    local closest = System.player.get_closest_to_cursor()
    if closest and closest:FindFirstChild('HumanoidRootPart') then
        targetPart = closest.HumanoidRootPart
    end
    local target_pos = targetPart and targetPart.Position or (root.Position + camera.CFrame.LookVector * 100)
    local curve_functions = {
        function() return camera.CFrame end,
        function()
            local direction = (target_pos - root.Position).Unit
            local random_offset
            local attempts = 0
            repeat
                random_offset = Vector3.new(
                    math.random(-4000, 4000),
                    math.random(-4000, 4000),
                    math.random(-4000, 4000)
                )
                local curve_direction = (target_pos + random_offset - root.Position).Unit
                local dot = direction:Dot(curve_direction)
                attempts = attempts + 1
            until dot < 0.95 or attempts > 10
            return CFrame.new(root.Position, target_pos + random_offset)
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0))
        end,
        function()
            local direction = (root.Position - target_pos).Unit
            local backwards_pos = root.Position + direction * 10000 + Vector3.new(0, 1000, 0)
            return CFrame.new(camera.CFrame.Position, backwards_pos)
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0))
        end,
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0))
        end,
        -- RandomTarget: aim at a random alive player (excluding local player)
        function()
            local candidates = {}
            if Alive then
                for _, pl in pairs(Alive:GetChildren()) do
                    if pl ~= LocalPlayer.Character and pl.PrimaryPart then
                        table.insert(candidates, pl)
                    end
                end
            end
            if #candidates > 0 then
                local choice = candidates[math.random(1, #candidates)]
                return CFrame.new(root.Position, choice.PrimaryPart.Position)
            end
            return camera.CFrame
        end,
        -- Left: aim far to the left
        function()
            local left_vec = -camera.CFrame.RightVector * 10000
            return CFrame.new(root.Position, root.Position + left_vec)
        end,
        -- Right: aim far to the right
        function()
            local right_vec = camera.CFrame.RightVector * 10000
            return CFrame.new(root.Position, root.Position + right_vec)
        end
    }
    return curve_functions[System.__properties.__curve_mode]()
end

System.parry = {}

function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end
    local camera = workspace.CurrentCamera
    local success, mouse = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not success then return end
    local vec2_mouse = {mouse.X, mouse.Y}
    local is_mobile = System.__properties.__is_mobile
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local success2, screen_point = pcall(function()
                    return camera:WorldToScreenPoint(entity.PrimaryPart.Position)
                end)
                if success2 then
                    event_data[entity.Name] = screen_point
                end
            end
        end
    end
    local curve_cframe = System.curve.get_cframe()
    if not System.__properties.__first_parry_done then
        for _, connection in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
            connection:Fire()
        end
        System.__properties.__first_parry_done = true
        return
    end
    local final_aim_target
    if is_mobile then
        local viewport = camera.ViewportSize
        final_aim_target = {viewport.X / 2, viewport.Y / 2}
    else
        final_aim_target = vec2_mouse
    end
    -- Prefer WHA-style raw call when available for compatibility
    if getgenv().AutoParryMode == "Remote" and (remote and f_raw) then
        local ok, _ = pcall(fireParry_wh)
        if not ok then
            -- fallback to revertedRemotes behavior below
            for remote, original_args in pairs(revertedRemotes) do
                local modified_args = {
                    original_args[1],
                    original_args[2],
                    original_args[3],
                    curve_cframe,
                    event_data,
                    final_aim_target,
                    original_args[7]
                }
                pcall(function()
                    if remote:IsA('RemoteEvent') then
                        remote:FireServer(unpack(modified_args))
                    elseif remote:IsA('RemoteFunction') then
                        remote:InvokeServer(unpack(modified_args))
                    end
                end)
            end
        end
    else
        for remote, original_args in pairs(revertedRemotes) do
            local modified_args = {
                original_args[1],
                original_args[2],
                original_args[3],
                curve_cframe,
                event_data,
                final_aim_target,
                original_args[7]
            }
            pcall(function()
                if remote:IsA('RemoteEvent') then
                    remote:FireServer(unpack(modified_args))
                elseif remote:IsA('RemoteFunction') then
                    remote:InvokeServer(unpack(modified_args))
                end
            end)
        end
    end
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then
            System.__properties.__parries = System.__properties.__parries - 1
        end
    end)
end

function System.parry.keypress()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end
    if PF then pcall(PF) end
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then
            System.__properties.__parries = System.__properties.__parries - 1
        end
    end)
end

function System.parry.execute_action()
    System.animation.play_grab_parry()
    System.parry.execute()
end

local function linear_predict(a, b, time_volume)
    return a + (b - a) * time_volume
end

System.detection = {
    __ball_properties = {
        __aerodynamic_time = tick(),
        __last_warping = tick(),
        __lerp_radians = 0,
        __curving = tick()
    }
}

function System.detection.is_curved()
    local ball_properties = System.detection.__ball_properties
    local ball = System.ball.get()
    if not ball then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    local zoomies = ball:FindFirstChild('zoomies')
    if not zoomies then return false end
    local velocity = zoomies.VectorVelocity or Vector3.new()
    local speed = velocity.Magnitude
    if speed == 0 then return false end
    local ball_direction = velocity.Unit
    local direction_vector = LocalPlayer.Character.PrimaryPart.Position - ball.Position
    if direction_vector.Magnitude == 0 then return false end
    local direction = direction_vector.Unit
    local dot = direction:Dot(ball_direction)
    local speed_threshold = math.min(speed / 100, 40)
    local direction_difference = ball_direction - velocity
    local direction_similarity = 0
    if direction_difference.Magnitude > 0 then
        direction_similarity = direction:Dot(direction_difference.Unit)
    end
    local dot_difference = dot - direction_similarity
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
    local dot_threshold = 0.5 - (ping / 1000)
    local reach_time = distance / speed - (ping / 1000)
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.rad(math.asin(clamped_dot))
    ball_properties.__lerp_radians = linear_predict(ball_properties.__lerp_radians, radians, 0.8)
    if speed > 0 and reach_time > ping / 10 then
        ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
    end
    if distance < ball_distance_threshold then return false end
    if dot_difference < dot_threshold then return true end
    if ball_properties.__lerp_radians < 0.018 then
        ball_properties.__last_warping = tick()
    end
    if (tick() - ball_properties.__last_warping) < (reach_time / 1.5) then
        return true
    end
    if (tick() - ball_properties.__curving) < (reach_time / 1.5) then
        return true
    end
    return dot < dot_threshold
end

-- DeathBall remote handler removed (module/logic deleted)

 
-- TimeHole remote handlers removed (module/logic deleted)

-- Slashes Of Fury remote handlers removed (module/logic deleted)

-- Phantom runtime handler removed (module/logic deleted)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if root.Parent and root.Parent ~= LocalPlayer.Character then
        if not Alive or root.Parent.Parent ~= Alive then
            return
        end
    end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return
    end
    local closest = System.player.get_closest()
    local ball = System.ball.get()
    if not ball or not closest or not closest.PrimaryPart then return end
    local target_distance = (LocalPlayer.Character.PrimaryPart.Position - closest.PrimaryPart.Position).Magnitude
    local direction_vector = LocalPlayer.Character.PrimaryPart.Position - ball.Position
    if direction_vector.Magnitude == 0 then return end
    local distance = direction_vector.Magnitude
    local direction = direction_vector.Unit
    local ball_velocity = ball.AssemblyLinearVelocity or Vector3.new()
    if ball_velocity.Magnitude == 0 then return end
    local dot = direction:Dot(ball_velocity.Unit)
    local curve_detected = System.detection.is_curved()
    if target_distance < 15 and distance < 15 and dot > -0.25 then
        if curve_detected then
            System.parry.execute_action()
        end
    end
    if System.__properties.__grab_animation then
        System.__properties.__grab_animation:Stop()
    end
end)

-- End core System logic

-- Dribble detection scanner removed

-- Sword controller, parry connection discovery, and skin changer helpers
local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
local swordInstances = nil
pcall(function() swordInstances = require(swordInstancesInstance) end)

local swordsController

local function findSwordsController()
    while task.wait() and (not swordsController) do
        for _, v in pairs(getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent)) do
            if v.Function and islclosure and islclosure(v.Function) then
                local ok, upvalues = pcall(function() return getupvalues(v.Function) end)
                if ok and upvalues and #upvalues == 1 and type(upvalues[1]) == "table" then
                    swordsController = upvalues[1]
                    break
                end
            end
        end
    end
end

task.spawn(findSwordsController)

function getSlashName(swordName)
    if not swordInstances then return "SlashEffect" end
    local slashName = swordInstances:GetSword(swordName)
    return (slashName and slashName.SlashName) or "SlashEffect"
end

-- skin changer setSword removed

local playParryFunc
local parrySuccessAllConnection

local function findParryConnections()
    while task.wait() and not parrySuccessAllConnection do
        for _, v in pairs(getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)) do
            if v.Function and getinfo and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessAllConnection = v
                playParryFunc = v.Function
                pcall(function() v:Disable() end)
            end
        end
    end
end

task.spawn(findParryConnections)

local parrySuccessClientConnection
local function findClientConnection()
    while task.wait() and not parrySuccessClientConnection do
        for _, v in pairs(getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event)) do
            if v.Function and getinfo and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessClientConnection = v
                pcall(function() v:Disable() end)
            end
        end
    end
end

task.spawn(findClientConnection)

getgenv().slashName = "SlashEffect"

local lastOtherParryTimestamp = 0
local clashConnections = {}

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    if not playParryFunc then return end
    local args = {...}
    if tostring(args[4]) ~= LocalPlayer.Name then
        lastOtherParryTimestamp = tick()
    end
    return playParryFunc(unpack(args))
end)


-- default getgenv flags
getgenv().AutoParryMode = getgenv().AutoParryMode or "Remote"
getgenv().AutoParryNotify = getgenv().AutoParryNotify or false
getgenv().CooldownProtection = getgenv().CooldownProtection or false
getgenv().AutoAbility = getgenv().AutoAbility or false
getgenv().ManualSpamNotify = getgenv().ManualSpamNotify or false
getgenv().ManualSpamMode = getgenv().ManualSpamMode or "Remote"
getgenv().ManualSpamAnimationFix = getgenv().ManualSpamAnimationFix or false
getgenv().AutoSpamNotify = getgenv().AutoSpamNotify or false
getgenv().AutoSpamMode = getgenv().AutoSpamMode or "Remote"
getgenv().AutoSpamAnimationFix = getgenv().AutoSpamAnimationFix or false
getgenv().AutoStop = getgenv().AutoStop or false
getgenv().Walkablesemiimortal = getgenv().Walkablesemiimortal or false
getgenv().WalkablesemiimortalNotify = getgenv().WalkablesemiimortalNotify or false
getgenv().AutoVote = getgenv().AutoVote or false


System.manual_spam = {}

function System.manual_spam.start()
    if System.__properties.__manual_spam_running then
        System.manual_spam.stop()
    end
    
    System.__properties.__manual_spam_running = true
    local cps = System.__properties.__manual_spam_cps or 350
    local interval = 1 / cps
    
    System.__properties.__connections.__manual_spam = RunService.Heartbeat:Connect(function()
        if not System.__properties.__manual_spam_enabled then
            System.manual_spam.stop()
            return
        end
        if not LocalPlayer.Character then return end
        
        if getgenv().AutoParryMode == "Keypress" then
            System.parry.keypress()
        else
            System.parry.execute_action()
        end
        
        task.wait(interval)
    end)
end

function System.manual_spam.stop()
    System.__properties.__manual_spam_running = false
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
        System.__properties.__connections.__manual_spam = nil
    end
end

System.auto_spam = {}

function System.auto_spam:get_entity_properties()
    System.player.get_closest()
    if not Closest_Entity or not Closest_Entity.PrimaryPart then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    local entity_velocity = Closest_Entity.PrimaryPart.Velocity
    local entity_direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local entity_distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    return {
        Velocity = entity_velocity,
        Direction = entity_direction,
        Distance = entity_distance
    }
end

function System.auto_spam:get_ball_properties()
    local ball = System.ball.get()
    if not ball then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    local ball_velocity = ball.AssemblyLinearVelocity or Vector3.new()
    local ball_origin = ball
    local ball_direction_vector = LocalPlayer.Character.PrimaryPart.Position - ball_origin.Position
    local ball_distance = ball_direction_vector.Magnitude
    local ball_direction = Vector3.new()
    local ball_dot = 0
    if ball_distance > 0 then
        ball_direction = ball_direction_vector.Unit
        if ball_velocity.Magnitude > 0 then
            ball_dot = ball_direction:Dot(ball_velocity.Unit)
        end
    end
    return {
        Velocity = ball_velocity,
        Direction = ball_direction,
        Distance = ball_distance,
        Dot = ball_dot
    }
end

function System.auto_spam.spam_service(self)
    -- Adapted from zen.lua I5.Spam_Service (safe, no executor-only APIs)
    local ball = System.ball.get()
    local entity = System.player.get_closest()
    if not ball or not entity or not entity.PrimaryPart then
        return false
    end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return false
    end

    -- default fallback
    local D = 5

    local velocity = ball.AssemblyLinearVelocity or Vector3.new()
    local n = velocity.Magnitude
    if n == 0 then
        return D
    end

    local to_ball = (LocalPlayer.Character.PrimaryPart.Position - ball.Position)
    if to_ball.Magnitude == 0 then
        return D
    end

    local r = to_ball.Unit
    local t = 0
    if n > 0 and velocity.Magnitude > 0 then
        t = r:Dot(velocity.Unit)
    end

    local target_pos = entity.PrimaryPart.Position
    local X = LocalPlayer:DistanceFromCharacter(target_pos)

    local E = 1
    local Fmove = Vector3.new()
    local success, humanoid = pcall(function()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    end)
    if success and humanoid and humanoid.MoveDirection then
        Fmove = humanoid.MoveDirection
    end

    local N = (target_pos - LocalPlayer.Character.PrimaryPart.Position)
    if N.Magnitude > 0 then N = N.Unit else N = Vector3.new() end
    local lmove = Vector3.new()
    if entity then
        local ehum = entity:FindFirstChildOfClass('Humanoid')
        if ehum and ehum.MoveDirection then lmove = ehum.MoveDirection end
    end

    -- close contact heuristic (local state preserved in globals similar to zen.lua)
    _G.Last_Close_Contact = _G.Last_Close_Contact or 0
    _G.In_Close_Contact = _G.In_Close_Contact or false
    local now = tick()
    if X <= 3 then
        _G.In_Close_Contact = true
    end
    if _G.In_Close_Contact and X > 3.3 then
        _G.In_Close_Contact = false
        _G.Last_Close_Contact = now
    end
    local u = (not _G.In_Close_Contact) and (now - (_G.Last_Close_Contact or 0) >= 1.5)
    if u and (Fmove.Magnitude > 0.2 and Fmove:Dot(N) < -0.4) then
        E = 10
    end
    if u and (lmove.Magnitude > 0.2 and lmove:Dot(-N) < -0.4) then
        E = 10
    end

    -- Ping/ball-speed based base threshold
    local B = (self.Ping or 50) * 0.7 + math.min(n / (E * 1.2), 80)

    -- if entity/ball/target farther than base threshold return default
    if (self.Entity_Properties and self.Entity_Properties.Distance or math.huge) > B then
        return D
    end
    if (self.Ball_Properties and self.Ball_Properties.Distance or math.huge) > B then
        return D
    end
    if X > B then
        return D
    end

    local U = math.clamp(-t, 0, 1)
    local q = math.clamp(U * (n / 40), 0, 4)
    D = B - q
    return D
end

function System.auto_spam.start()
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
    end
    System.__properties.__auto_spam_enabled = true
    System.__properties.__connections.__auto_spam = RunService.PreSimulation:Connect(function()
        local ball = System.ball.get()
        if not ball then return end
        local zoomies = ball:FindFirstChild('zoomies')
        if not zoomies then return end
        System.player.get_closest()
        local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
        local ping_threshold = math.clamp(ping / 10, 1, 16)
        local ball_target = ball:GetAttribute('target')
        local ball_properties = System.auto_spam:get_ball_properties()
        local entity_properties = System.auto_spam:get_entity_properties()
        if not ball_properties or not entity_properties then return end
        local spam_accuracy = System.auto_spam.spam_service({
            Ball_Properties = ball_properties,
            Entity_Properties = entity_properties,
            Ping = ping_threshold
        })
        local target_position = Closest_Entity.PrimaryPart.Position
        local target_distance = LocalPlayer:DistanceFromCharacter(target_position)
        if zoomies.VectorVelocity.Magnitude == 0 then return end
        local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
        local ball_direction = zoomies.VectorVelocity.Unit
        local dot = direction:Dot(ball_direction)
        local distance = LocalPlayer:DistanceFromCharacter(ball.Position)
        if not ball_target then return end
        if target_distance > spam_accuracy or distance > spam_accuracy then return end
        local pulsed = LocalPlayer.Character:GetAttribute('Pulsed')
        if pulsed then return end
        if ball_target == LocalPlayer.Name and target_distance > 30 and distance > 30 then return end
        if distance <= spam_accuracy and System.__properties.__parries > System.__properties.__spam_threshold then
            if getgenv().AutoSpamMode == "Keypress" then
                if PF then PF() end
            else
                System.parry.execute()
                if getgenv().AutoSpamAnimationFix and PF then
                    PF()
                end
            end
        end
    end)
end

function System.auto_spam.stop()
    System.__properties.__auto_spam_enabled = false
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
        System.__properties.__connections.__auto_spam = nil
    end
end

System.autoparry = {}

function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or 
           not LocalPlayer.Character.PrimaryPart then
            return
        end
        local balls = System.ball.get_all()
        local one_ball = System.ball.get()
        local training_ball = nil
        if workspace:FindFirstChild("TrainingBalls") then
            for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                    training_ball = Instance
                    break
                end
            end
        end
        for _, ball in pairs(balls) do
            if getgenv().BallVelocityAbove800 then return end
            if not ball then continue end
            local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then continue end
            ball:GetAttributeChangedSignal('target'):Once(function()
                System.__properties.__parried = false
            end)
            if System.__properties.__parried then continue end
            local ball_target = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
            local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            local curved = System.detection.is_curved()
            if ball:FindFirstChild('AeroDynamicSlashVFX') then
                ball.AeroDynamicSlashVFX:Destroy()
                System.__properties.__tornado_time = tick()
            end
            if Runtime:FindFirstChild('Tornado') then
                if (tick() - System.__properties.__tornado_time) < 
                   (Runtime.Tornado:GetAttribute('TornadoTime') or 1) + 0.314159 then
                    continue
                end
            end
            if one_ball and one_ball:GetAttribute('target') == LocalPlayer.Name and curved then
                continue
            end
            if ball:FindFirstChild('ComboCounter') then continue end
            if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            
            
            
            
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().CooldownProtection then
                    local ParryCD = LocalPlayer.PlayerGui.Hotbar.Block.UIGradient
                    if ParryCD.Offset.Y < 0.4 then
                        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                        continue
                    end
                end
                if getgenv().AutoAbility then
                    local AbilityCD = LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient
                    if AbilityCD.Offset.Y == 0.5 then
                        if LocalPlayer.Character.Abilities:FindFirstChild("Raging Deflection") and LocalPlayer.Character.Abilities["Raging Deflection"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Rapture") and LocalPlayer.Character.Abilities["Rapture"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Calming Deflection") and LocalPlayer.Character.Abilities["Calming Deflection"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Aerodynamic Slash") and LocalPlayer.Character.Abilities["Aerodynamic Slash"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Fracture") and LocalPlayer.Character.Abilities["Fracture"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Death Slash") and LocalPlayer.Character.Abilities["Death Slash"].Enabled then
                            System.__properties.__parried = true
                            ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                            task.wait(2.432)
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
                            continue
                        end
                    end
                end
            end
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().AutoParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute_action()
                end
                System.__properties.__parried = true
            end
            local last_parrys = tick()
            repeat
                RunService.Stepped:Wait()
            until (tick() - last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
        end
        if training_ball then
            local zoomies = training_ball:FindFirstChild('zoomies')
            if zoomies then
                training_ball:GetAttributeChangedSignal('target'):Once(function()
                    System.__properties.__training_parried = false
                end)
                if not System.__properties.__training_parried then
                    local ball_target = training_ball:GetAttribute('target')
                    local velocity = zoomies.VectorVelocity
                    local distance = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local speed = velocity.Magnitude
                    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
                    local ping_threshold = math.clamp(ping / 10, 5, 17)
                    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
                    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
                    local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
                    if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                        if getgenv().AutoParryMode == "Keypress" then
                            System.parry.keypress()
                        else
                            System.parry.execute_action()
                        end
                        System.__properties.__training_parried = true
                        local last_parrys = tick()
                        repeat
                            RunService.Stepped:Wait()
                        until (tick() - last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried = false
                    end
                end
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end

-- Autoparry module (migrated from ha.lua)
local autoparry_module = AutoparryTab:create_module({
    title = "Auto Parry",
    description = "Auto Parry Settings",
    flag = "AutoParryModule",
    section = "left",
    callback = function(state)
        if System then
            System.__properties.__autoparry_enabled = state
            if state then
                if System.autoparry and System.autoparry.start then pcall(System.autoparry.start)
                end
                if getgenv().AutoParryNotify then
                    Library.SendNotification({ title = "Auto Parry", text = "ON", duration = 2 })
                end
                -- Mobile button support for Auto Parry (from zen-style touch handlers)
                if System.__properties.__is_mobile and not System.__properties.__mobile_guis.autoparry then
                    local success, autoparry_mobile = pcall(function()
                        return create_mobile_button('AutoParry', 0.6, Color3.fromRGB(100, 180, 255))
                    end)
                    if success and autoparry_mobile then
                        System.__properties.__mobile_guis.autoparry = autoparry_mobile

                        local touch_start = 0
                        local was_dragged = false

                        autoparry_mobile.button.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch then
                                touch_start = tick()
                                was_dragged = false
                            end
                        end)

                        autoparry_mobile.button.InputChanged:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch then
                                if (tick() - touch_start) > 0.1 then
                                    was_dragged = true
                                end
                            end
                        end)

                        autoparry_mobile.button.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch and not was_dragged then
                                if System then
                                    System.__properties.__autoparry_enabled = not System.__properties.__autoparry_enabled
                                    if System.autoparry and System.autoparry.start and System.autoparry.stop then
                                        if System.__properties.__autoparry_enabled then
                                            pcall(System.autoparry.start)
                                        else
                                            pcall(System.autoparry.stop)
                                        end
                                    end
                                end

                                if System and System.__properties and System.__properties.__autoparry_enabled then
                                    autoparry_mobile.text.Text = "ON"
                                    autoparry_mobile.text.TextColor3 = Color3.fromRGB(100, 180, 255)
                                else
                                    autoparry_mobile.text.Text = "AutoParry"
                                    autoparry_mobile.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                                end

                                if getgenv().AutoParryNotify then
                                    Library.SendNotification({ title = "Auto Parry", text = System and System.__properties and System.__properties.__autoparry_enabled and "ON" or "OFF", duration = 2 })
                                end
                            end
                        end)
                    end
                end
            else
                if System.autoparry and System.autoparry.stop then pcall(System.autoparry.stop)
                end
                if getgenv().AutoParryNotify then
                    Library.SendNotification({ title = "Auto Parry", text = "OFF", duration = 2 })
                end
                -- destroy mobile GUI when disabling
                if System.__properties.__mobile_guis.autoparry then
                    destroy_mobile_gui(System.__properties.__mobile_guis.autoparry)
                    System.__properties.__mobile_guis.autoparry = nil
                end
            end
        end
    end
})

-- Hotkeys module (Main tab)
local mode_curve_dropdown = nil

autoparry_module:create_slider({
    title = "Parry Accuracy",
    flag = "ParryAccuracy",
    maximum_value = 100,
    minimum_value = 1,
    value = 100,
    round_number = true,
    callback = function(value)
        if System then
            System.__properties.__accuracy = value
            if update_divisor then pcall(update_divisor) end
        end
    end
})

autoparry_module:create_divider({})

autoparry_module:create_dropdown({
    title = "Parry Mode",
    flag = "ParryMode",
    options = {"Remote", "Keypress"},
    maximum_options = 10,
    callback = function(value)
        getgenv().AutoParryMode = value
    end
})

mode_curve_dropdown = autoparry_module:create_dropdown({
    title = "Mode curve",
    flag = "ModeCurve",
    options = (System and System.__config and System.__config.__curve_names) or {"Camera", "Random", "Accelerated", "Backwards", "Slow", "High"},
    maximum_options = 10,
    callback = function(value)
        if System and System.__config and System.__config.__curve_names then
            for i, name in ipairs(System.__config.__curve_names) do
                if name == value then
                    System.__properties.__curve_mode = i
                    break
                end
            end
        end
    end
})

autoparry_module:create_divider({})

autoparry_module:create_checkbox({
    title = "Randomize Accuracy",
    flag = "RandomizeAccuracy",
    callback = function(value)
        if System then
            System.__properties.__randomized_accuracy_enabled = value
            if value and update_randomized_accuracy then pcall(update_randomized_accuracy) end
        end
    end
})

-- Play Animation option removed per user request

autoparry_module:create_checkbox({
    title = "Cooldown Protection",
    flag = "CooldownProtection",
    callback = function(value)
        getgenv().CooldownProtection = value
    end
})

autoparry_module:create_checkbox({
    title = "Auto Ability",
    flag = "AutoAbility",
    callback = function(value)
        getgenv().AutoAbility = value
    end
})

autoparry_module:create_checkbox({
    title = "Notify",
    flag = "AutoParryNotify",
    callback = function(value)
        getgenv().AutoParryNotify = value
    end
})

-- Mobile button helper (migrated from ha.lua)
local function create_mobile_button(name, position_y, color)
    local gui = Instance.new('ScreenGui')
    gui.Name = 'Sigma' .. name .. 'Mobile'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local button = Instance.new('TextButton')
    button.Size = UDim2.new(0, 140, 0, 50)
    button.Position = UDim2.new(0.5, -70, position_y, 0)
    button.BackgroundTransparency = 1
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Draggable = true
    button.AutoButtonColor = false
    button.ZIndex = 2

    local bg = Instance.new('Frame')
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.Parent = button

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg

    local stroke = Instance.new('UIStroke')
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = bg

    local text = Instance.new('TextLabel')
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.ZIndex = 3
    text.Parent = button

    button.Parent = gui
    gui.Parent = CoreGui

    return {gui = gui, button = button, text = text, bg = bg}
end


local function destroy_mobile_gui(gui_data)
    if gui_data and gui_data.gui then
        gui_data.gui:Destroy()
    end
end

 
-- Detection modules
-- Death Slash Detection module removed

-- Time Hole Detection module removed
-- Slashes Of Fury Detection module removed

-- Dribble Detection module removed

-- Phantom Detection module removed

-- Spam modules
local manual_spam_module = AutoparryTab:create_module({
    title = "Manual Spam",
    description = "Manual spam parries with adjustable CPS",
    flag = "ManualSpamModule",
    section = "right",
    callback = function(state)
        if System then
            System.__properties.__manual_spam_enabled = state
            if state then
                if System.manual_spam and System.manual_spam.start then 
                    pcall(System.manual_spam.start)
                end
                if getgenv().AutoSpamNotify then
                    Library.SendNotification({ title = "Manual Spam", text = "ON - " .. System.__properties.__manual_spam_cps .. " CPS", duration = 2 })
                end
                if System.__properties.__is_mobile and not System.__properties.__mobile_guis.manual_spam then
                    local success, manual_mobile = pcall(function()
                        return create_mobile_button('ManualSpam', 0.75, Color3.fromRGB(128, 128, 128))
                    end)
                    if success and manual_mobile then
                        System.__properties.__mobile_guis.manual_spam = manual_mobile
                        
                        local touch_start = 0
                        local was_dragged = false
                        
                        manual_mobile.button.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch then
                                touch_start = tick()
                                was_dragged = false
                            end
                        end)
                        
                        manual_mobile.button.InputChanged:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch then
                                if (tick() - touch_start) > 0.1 then
                                    was_dragged = true
                                end
                            end
                        end)
                        
                        manual_mobile.button.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch and not was_dragged then
                                if System then
                                    System.__properties.__manual_spam_enabled = not System.__properties.__manual_spam_enabled
                                    if System.manual_spam and System.manual_spam.start and System.manual_spam.stop then
                                        if System.__properties.__manual_spam_enabled then
                                            pcall(System.manual_spam.start)
                                        else
                                            pcall(System.manual_spam.stop)
                                        end
                                    end
                                end
                                
                                if System and System.__properties and System.__properties.__manual_spam_enabled then
                                    manual_mobile.text.Text = "ON " .. System.__properties.__manual_spam_cps .. "CPS"
                                    manual_mobile.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                                else
                                    manual_mobile.text.Text = "ManualSpam"
                                    manual_mobile.text.TextColor3 = Color3.fromRGB(200, 200, 200)
                                end
                                
                                if getgenv().AutoSpamNotify then
                                    Library.SendNotification({ title = "Manual Spam", text = System and System.__properties and System.__properties.__manual_spam_enabled and "ON - " .. System.__properties.__manual_spam_cps .. " CPS" or "OFF", duration = 2 })
                                end
                            end
                        end)
                    end
                end
            else
                if System.manual_spam and System.manual_spam.stop then 
                    pcall(System.manual_spam.stop)
                end
                if getgenv().AutoSpamNotify then
                    Library.SendNotification({ title = "Manual Spam", text = "OFF", duration = 2 })
                end
                if System.__properties.__mobile_guis.manual_spam then
                    destroy_mobile_gui(System.__properties.__mobile_guis.manual_spam)
                    System.__properties.__mobile_guis.manual_spam = nil
                end
            end
        end
    end
})

manual_spam_module:create_slider({
    title = "Spam Manual Threshold",
    flag = "ManualSpamThreshold",
    maximum_value = 600,
    minimum_value = 100,
    value = 350,
    round_number = true,
    callback = function(value)
        if System then
            System.__properties.__manual_spam_cps = value
            if System.__properties.__manual_spam_enabled then
                if System.manual_spam and System.manual_spam.start then
                    pcall(System.manual_spam.start)
                end
                if System.__properties.__mobile_guis.manual_spam then
                    pcall(function()
                        System.__properties.__mobile_guis.manual_spam.text.Text = "ON " .. value .. "CPS"
                    end)
                end
            end
        end
    end
})

local auto_spam_module = AutoparryTab:create_module({
    title = "Auto Spam",
    description = "Automatically spam parries ball",
    flag = "AutoSpamModule",
    section = "right",
    callback = function(state)
        if System and System.auto_spam then
            System.__properties.__auto_spam_enabled = state
            if state then
                if System.auto_spam and System.auto_spam.start then pcall(System.auto_spam.start) end
                if getgenv().AutoSpamNotify then
                    Library.SendNotification({ title = "Auto Spam", text = "ON", duration = 2 })
                end
            else
                if System.auto_spam and System.auto_spam.stop then pcall(System.auto_spam.stop) end
                if getgenv().AutoSpamNotify then
                    Library.SendNotification({ title = "Auto Spam", text = "OFF", duration = 2 })
                end
            end
        end
    end
})

auto_spam_module:create_checkbox({
    title = "Notify",
    flag = "AutoSpamNotify",
    callback = function(value)
        getgenv().AutoSpamNotify = value
    end
})
auto_spam_module:create_dropdown({
    title = "Mode",
    flag = "AutoSpamMode",
    options = {"Remote", "Keypress"},
    maximum_options = 10,
    callback = function(Value)
        getgenv().AutoSpamMode = Value
    end
})
auto_spam_module:create_checkbox({
    title = "Animation Fix",
    flag = "AutoSpamAnimationFix",
    callback = function(value)
        getgenv().AutoSpamAnimationFix = value
    end
})
auto_spam_module:create_slider({
    title = "Parry Threshold",
    flag = "ParryThreshold",
    maximum_value = 10,
    minimum_value = 0,
    value = 2.5,
    round_number = true,
    callback = function(value)
        if System then System.__properties.__spam_threshold = value end
    end
})
auto_spam_module:create_slider({
    title = "Distance Multiplier",
    flag = "DistanceMultiplier",
    maximum_value = 3.0,
    minimum_value = 0.3,
    value = 0.3,
    round_number = true,
    callback = function(value)
        if System then System.__properties.__auto_spam_distance_multiplier = value end
    end
})

local WalkableSemiImmortal = {}

local state = {
    enabled = false,
    notify = false,
    heartbeatConnection = nil
}

local desyncData = {
    originalCFrame = nil,
    originalVelocity = nil
}

local cache = {
    character = nil,
    hrp = nil,
    head = nil,
    headOffset = Vector3.new(0, 0, 0),
    aliveFolder = nil
}

local hooks = {
    oldIndex = nil
}

local constants = {
    emptyCFrame = CFrame.new(),
    radius = 25,
    baseHeight = 5,
    riseHeight = 30,
    cycleSpeed = 11.9,
    velocity = Vector3.new(1, 1, 1)
}

local function updateCache()
    local character = LocalPlayer.Character
    if character ~= cache.character then
        cache.character = character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            cache.hrp = hrp
            cache.head = head
            cache.aliveFolder = workspace:FindFirstChild("Alive")
            if hrp then
                cache.headOffset = Vector3.new(0, hrp.Size.Y * 0.5 + 0.5, 0)
            end
        else
            cache.hrp = nil
            cache.head = nil
            cache.aliveFolder = nil
        end
    end
end

local function isInAliveFolder()
    return cache.aliveFolder and cache.character and cache.character.Parent == cache.aliveFolder
end

local function calculateOrbitPosition(hrp)
    local angle = math.random() * 2 * math.pi
    local cycle = math.floor(tick() * constants.cycleSpeed) % 2
    local yOffset = cycle == 0 and 0 or constants.riseHeight
    
    local pos = hrp.Position
    local yBase = pos.Y - hrp.Size.Y * 0.5 + constants.baseHeight + yOffset
    
    return CFrame.new(
        pos.X + math.cos(angle) * constants.radius,
        yBase,
        pos.Z + math.sin(angle) * constants.radius
    )
end

local function performDesync()
    updateCache()
    
    if not state.enabled or not cache.hrp or not isInAliveFolder() then
        return
    end
    
    local hrp = cache.hrp
    desyncData.originalCFrame = hrp.CFrame
    desyncData.originalVelocity = hrp.AssemblyLinearVelocity
    
    hrp.CFrame = calculateOrbitPosition(hrp)
    hrp.AssemblyLinearVelocity = constants.velocity
    
    task.wait()
    
    if hrp and hrp.Parent then
        hrp.CFrame = desyncData.originalCFrame
        hrp.AssemblyLinearVelocity = desyncData.originalVelocity
    end
end

local function sendNotification(text)
    if state.notify and Library then
        Library.SendNotification({
            title = "Walkable Semi-Immortal",
            text = text
        })
    end
end

function WalkableSemiImmortal.toggle(enabled)
    if state.enabled == enabled then return end
    
    state.enabled = enabled
    getgenv().Walkablesemiimortal = enabled
    
    if enabled then
        if not state.heartbeatConnection then
            state.heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(performDesync)
        end
    else
        if state.heartbeatConnection then
            state.heartbeatConnection:Disconnect()
            state.heartbeatConnection = nil
        end
        desyncData.originalCFrame = nil
        desyncData.originalVelocity = nil
    end
    
    sendNotification(enabled and "ON" or "OFF")
end

function WalkableSemiImmortal.setNotify(enabled)
    state.notify = enabled
    getgenv().WalkablesemiimortalNotify = enabled
end

function WalkableSemiImmortal.setRadius(value)
    constants.radius = value
end

function WalkableSemiImmortal.setHeight(value)
    constants.riseHeight = value
end

local function onCharacterRemoving()
    cache.character = nil
    cache.hrp = nil
    cache.head = nil
    cache.aliveFolder = nil
    desyncData.originalCFrame = nil
    desyncData.originalVelocity = nil
end

LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)

if hooks.oldIndex == nil then
    hooks.oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if not state.enabled or checkcaller() or key ~= "CFrame" then
            return hooks.oldIndex(self, key)
        end
        
        if not cache.hrp or not isInAliveFolder() then
            return hooks.oldIndex(self, key)
        end
        
        if self == cache.hrp then
            return desyncData.originalCFrame or constants.emptyCFrame
        elseif self == cache.head and desyncData.originalCFrame then
            return desyncData.originalCFrame + cache.headOffset
        end
        
        return hooks.oldIndex(self, key)
    end))
end

local walkableModule = DetectionTab:create_module({
    title = "Walkable Semi-Immortal [BLATANT!]",
    description = "Desync to become semi-immortal",
    flag = "Walkable_Semi_Immortal",
    section = "left",
    callback = WalkableSemiImmortal.toggle
})

walkableModule:create_checkbox({
    title = "Notify",
    flag = "WalkableSemi_Imortal_Notify",
    callback = WalkableSemiImmortal.setNotify
})

walkableModule:create_slider({
    title = 'Immortal Radius',
    flag = 'Immortal_Radius',
    maximum_value = 100,
    minimum_value = 0,
    value = 25,
    round_number = true,
    callback = WalkableSemiImmortal.setRadius
})

walkableModule:create_slider({
    title = 'Immortal Height',
    flag = 'Walkable_Immortal_Height',
    maximum_value = 60,
    minimum_value = 0,
    value = 30,
    round_number = true,
    callback = WalkableSemiImmortal.setHeight
})

DetectionTab:create_module({
    title = 'Infinity Detection',
    flag = 'Infinity',
    description = 'Detect Infinity ball',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__infinity = value
    end
})

DetectionTab:create_module({
    title = 'Death Slash Detection',
    flag = 'Death_Slash',
    description = 'Detect Death Slash ability',
    section = 'right',
    callback = function(value)
        System.__config.__detections.__deathslash = value
    end
})

DetectionTab:create_module({
    title = 'Time Hole Detection',
    flag = 'Time_Hole',
    description = 'Detect Time Hole ability',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__timehole = value
    end
})

local slashesModule = DetectionTab:create_module({
    title = 'Slashes Of Fury Detection',
    flag = 'Slashes_Of_Fury',
    description = 'Detect Slashes Of Fury ability',
    section = 'right',
    callback = function(value)
        System.__config.__detections.__slashesoffury = value
    end
})

slashesModule:create_slider({
    title = "Parry Delay",
    minimum_value = 0.05,
    maximum_value = 0.250,
    value = 0.05,
    round_number = true,
    flag = "parry_delay",
    callback = function(value)
        parryDelay = value
    end
})

slashesModule:create_slider({
    title = "Max Parry Count",
    minimum_value = 1,
    maximum_value = 36,
    value = 36,
    round_number = true,
    flag = "max_parry_count",
    callback = function(value)
        maxParryCount = value
    end
})

DetectionTab:create_module({
    title = 'Anti-Phantom [BETA]',
    flag = 'Anti_Phantom',
    description = 'Anti Phantom detection',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__phantom = value
    end
})


-- Player modules (Avatar, FOV, Character)
local __flags = {}
local __players = cloneref(game:GetService('Players'))
local __localplayer = __players.LocalPlayer

local function __apparence(__name)
    local s, e = pcall(function()
        local __id = __players:GetUserIdFromNameAsync(__name)
        return __players:GetHumanoidDescriptionFromUserId(__id)
    end)

    if not s then
        return nil
    end

    return e
end

local function __set(__name, __char)
    if not __name or __name == '' then
        return
    end
    
    local __hum = __char and __char:WaitForChild('Humanoid', 5)

    if not __hum then
        return
    end

    local __desc = __apparence(__name)
    
    if not __desc then
        warn("Failed to get appearance for: " .. tostring(__name))
        return
    end

    __localplayer:ClearCharacterAppearance()
    __hum:ApplyDescriptionClientServer(__desc)
end

-- Ability ESP (copied from EagleX, adapted)
local billboardLabels = {}
local function createBillboardGui(p)
    task.spawn(function()
        local character = p.Character
        while not character or not character.Parent do
            task.wait()
            character = p.Character
        end
        local head = character:WaitForChild("Head", 10)
        if not head then return end
        local bg = Instance.new("BillboardGui")
        bg.Name = "AbilityESP_Gui"
        bg.Adornee = head
        bg.Size = UDim2.new(0, 220, 0, 60)
        bg.StudsOffset = Vector3.new(0, 3.5, 0)
        bg.AlwaysOnTop = true
        bg.Parent = head
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.TextSize = 14
        tl.TextStrokeTransparency = 0
        tl.Font = Enum.Font.GothamBold
        tl.BackgroundTransparency = 1
        tl.Parent = bg
        tl.Visible = false
        billboardLabels[p] = tl
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not (character and character.Parent) then
                conn:Disconnect()
                pcall(function() bg:Destroy() end)
                billboardLabels[p] = nil
                return
            end
            tl.Visible = getgenv().AbilityESP
            if getgenv().AbilityESP then
                local ab = p:GetAttribute("EquippedAbility")
                tl.Text = ab and (p.DisplayName .. " [" .. ab .. "]") or p.DisplayName
            end
        end)
    end)
end

-- Initialize global flag if not present
getgenv().AbilityESP = getgenv().AbilityESP or false

-- Byte_Library: Headless & Korblox utilities (from EagleX)
local Byte_Library = {}
function Byte_Library.Korblox(char)
    if not char then return end
    local leg = char:FindFirstChild("Right Leg")
    if not leg then return end
    if not leg:FindFirstChild("KorbloxMesh") then
        for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
        local m = Instance.new("SpecialMesh")
        m.Name = "KorbloxMesh"
        m.MeshId = "rbxassetid://902942096"
        m.TextureId = "rbxassetid://902843398"
        m.Offset = Vector3.new(0, 0.7, 0)
        m.Parent = leg
    end
end
function Byte_Library.Restore_Leg(char)
    if not char then return end
    local leg = char:FindFirstChild("Right Leg")
    if not leg then return end
    for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
end
function Byte_Library.Headless(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 1
    for _, child in head:GetChildren() do
        if child:IsA("Decal") or child.Name == "face" then
            child.Transparency = 1
        elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
            if not child:GetAttribute("OriginalScale") then
                child:SetAttribute("OriginalScale", child.Scale)
                child.Scale = Vector3.new(0, 0, 0)
            end
        end
    end
end
function Byte_Library.Restore_Head(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 0
    for _, child in head:GetChildren() do
        if child:IsA("Decal") or child.Name == "face" then
            child.Transparency = 0
        elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
            local orig = child:GetAttribute("OriginalScale")
            if orig then
                child.Scale = orig
                child:SetAttribute("OriginalScale", nil)
            end
        end
    end
end

local headlessKorblox_conn = nil
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if getgenv().HeadlessKorbloxEnabled then
        Byte_Library.Headless(char)
        Byte_Library.Korblox(char)
    end
end)

-- Headless & Korblox module in Misc
local headless_module = MiscTab:create_module({
    title = "Cosmetics",
    description = "Apply Headless and Korblox",
    flag = "HeadlessKorbloxModule",
    section = "left",
    callback = function(state)
        getgenv().HeadlessKorbloxEnabled = state
        local char = LocalPlayer.Character
        if char then
            if state then
                pcall(function() Byte_Library.Headless(char); Byte_Library.Korblox(char) end)
            else
                pcall(function() Byte_Library.Restore_Head(char); Byte_Library.Restore_Leg(char) end)
            end
        end
        if state then
            if not headlessKorblox_conn then
                headlessKorblox_conn = LocalPlayer.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    if getgenv().HeadlessKorbloxEnabled then
                        pcall(function() Byte_Library.Headless(char); Byte_Library.Korblox(char) end)
                    end
                end)
            end
        else
            if headlessKorblox_conn then
                headlessKorblox_conn:Disconnect()
                headlessKorblox_conn = nil
            end
        end
    end
})

local function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)
    animation:Play()
    task.wait(info.Time)
    animation:Destroy()
end

local animation_system = {
    storage = {},
    current = nil,
    track = nil,
    is_playing = false
}

function animation_system.load_animations()
    local emotes_folder = game:GetService("ReplicatedStorage").Misc.Emotes
    for _, animation in pairs(emotes_folder:GetChildren()) do
        if animation:IsA("Animation") and animation:GetAttribute("EmoteName") then
            animation_system.storage[animation:GetAttribute("EmoteName")] = animation
        end
    end
end

function animation_system.get_emotes_list()
    local emotes_list = {}
    for emote_name in pairs(animation_system.storage) do
        table.insert(emotes_list, emote_name)
    end
    table.sort(emotes_list)
    return emotes_list
end

function animation_system.play(emote_name)
    local animation_data = animation_system.storage[emote_name]
    if not animation_data or not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
    end
    
    animation_system.track = animator:LoadAnimation(animation_data)
    animation_system.track:Play()
    animation_system.current = emote_name
    animation_system.is_playing = true
    
    animation_system.track.Stopped:Connect(function()
        animation_system.is_playing = false
    end)
    
    return true
end

function animation_system.stop()
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
        animation_system.track = nil
    end
    animation_system.current = nil
    animation_system.is_playing = false
end

function animation_system.start()
    if System.__properties.__connections.animations then
        System.__properties.__connections.animations:Disconnect()
    end
    
    System.__properties.__connections.animations = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        
        local speed = LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude
        
        if speed > 30 and getgenv().AutoStop then
            if animation_system.track and animation_system.is_playing then
                animation_system.track:Stop()
                animation_system.is_playing = false
            end
        else
            if animation_system.current and not animation_system.is_playing then
                animation_system.play(animation_system.current)
            end
        end
    end)
end

function animation_system.cleanup()
    animation_system.stop()
    if System.__properties.__connections.animations then
        System.__properties.__connections.animations:Disconnect()
        System.__properties.__connections.animations = nil
    end
end

animation_system.load_animations()
local emotes_data = animation_system.get_emotes_list()
local selected_animation = emotes_data[1]

-- Emotes module di MiscTab
local animations_module = MiscTab:create_module({
    title = 'Emotes',
    flag = 'Emotes',
    description = 'Custom Emotes Animation',
    section = 'right',
    callback = function(value)
        getgenv().Animations = value
        if value then
            animation_system.start()
            if selected_animation then
                animation_system.play(selected_animation)
            end
        else
            animation_system.cleanup()
        end
    end
})

animations_module:create_checkbox({
    title = "Auto Stop on Move",
    flag = "AutoStop",
    callback = function(value)
        getgenv().AutoStop = value
    end
})

local animation_dropdown = animations_module:create_dropdown({
    title = 'Emote Type',
    flag = 'Selected_Animation',
    options = emotes_data,
    multi_dropdown = false,
    maximum_options = 10,
    callback = function(value)
        selected_animation = value
        if getgenv().Animations then
            animation_system.play(value)
        end
    end
})

animation_dropdown:update(selected_animation)

local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)
local swordInstances = require(swordInstancesInstance)

local swordsController

while task.wait() and (not swordsController) do
    for i,v in getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent) do
        if v.Function and islclosure(v.Function) then
            local upvalues = getupvalues(v.Function)
            if #upvalues == 1 and type(upvalues[1]) == "table" then
                swordsController = upvalues[1]
                break
            end
        end
    end
end

function getSlashName(swordName)
    local slashName = swordInstances:GetSword(swordName)
    return (slashName and slashName.SlashName) or "SlashEffect"
end

function setSword()
    if not getgenv().skinChangerEnabled then return end
    setupvalue(rawget(swordInstances,"EquipSwordTo"),3,false)
    if getgenv().changeSwordModel then
        swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
    end
    if getgenv().changeSwordAnimation then
        swordsController:SetSword(getgenv().swordAnimations)
    end
end

local playParryFunc
local parrySuccessAllConnection

while task.wait() and not parrySuccessAllConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessAllConnection = v
            playParryFunc = v.Function
            v:Disable()
        end
    end
end

local parrySuccessClientConnection
while task.wait() and not parrySuccessClientConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessClientConnection = v
            v:Disable()
        end
    end
end

getgenv().slashName = getSlashName(getgenv().swordFX)

local lastOtherParryTimestamp = 0
local clashConnections = {}

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    setthreadidentity(2)
    local args = {...}
    if tostring(args[4]) ~= LocalPlayer.Name then
        lastOtherParryTimestamp = tick()
    elseif getgenv().skinChangerEnabled and getgenv().changeSwordFX then
        args[1] = getgenv().slashName
        args[3] = getgenv().swordFX
    end
    return playParryFunc(unpack(args))
end)

table.insert(clashConnections, getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)[1])

getgenv().updateSword = function()
    if getgenv().changeSwordFX then
        getgenv().slashName = getSlashName(getgenv().swordFX)
    end
    setSword()
end

task.spawn(function()
    while task.wait(1) do
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                setSword()
            end
            if char and (not char:FindFirstChild(getgenv().swordModel)) then
                setSword()
            end
            for _,v in (char and char:GetChildren()) or {} do
                if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                    v:Destroy()
                end
                task.wait()
            end
        end
    end
end)

-- Skin Changer module di MiscTab
local SkinChanger = MiscTab:create_module({
    title = 'Skin Changer',
    flag = 'SkinChanger',
    description = 'Change sword skin, animation, and FX',
    section = 'left',
    callback = function(value)
        getgenv().skinChangerEnabled = value
        if value then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})
SkinChanger:change_state(false)

local changeSwordModelCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword Model",
    flag = "ChangeSwordModel",
    callback = function(value)
        getgenv().changeSwordModel = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})
changeSwordModelCheckbox:change_state(true)

local swordModelTextbox = SkinChanger:create_textbox({
    title = "Sword Model Name",
    placeholder = "Enter Sword Model Name...",
    flag = "SwordModelTextbox",
    callback = function(text)
        getgenv().swordModel = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

local changeSwordAnimationCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword Animation",
    flag = "ChangeSwordAnimation",
    callback = function(value)
        getgenv().changeSwordAnimation = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})
changeSwordAnimationCheckbox:change_state(true)

local swordAnimationTextbox = SkinChanger:create_textbox({
    title = "Sword Animation Name",
    placeholder = "Enter Sword Animation Name...",
    flag = "SwordAnimationTextbox",
    callback = function(text)
        getgenv().swordAnimations = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordAnimation then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

local changeSwordFXCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword FX",
    flag = "ChangeSwordFX",
    callback = function(value)
        getgenv().changeSwordFX = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})
changeSwordFXCheckbox:change_state(true)

local swordFXTextbox = SkinChanger:create_textbox({
    title = "Sword FX Name",
    placeholder = "Enter Sword FX Name...",
    flag = "SwordFXTextbox",
    callback = function(text)
        getgenv().swordFX = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

-- Create module in Misc tab
local ability_esp_module = MiscTab:create_module({
    title = "Ability ESP",
    description = "Displays equipped abilities over players",
    flag = "AbilityESPModule",
    section = "left",
    callback = function(state)
        getgenv().AbilityESP = state
        for _, l in pairs(billboardLabels) do if l then l.Visible = state end end
    end
})

-- Hook existing players and new players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function() createBillboardGui(p) end)
        if p.Character then createBillboardGui(p) end
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() createBillboardGui(p) end)
end)

local no_render_module = MiscTab:create_module({
    title = "No Render",
    description = "Disables rendering of effects",
    flag = "NoRenderModule",
    section = "right",
    callback = function(state)
        local effectScripts = nil
        pcall(function()
            if Players and Players.LocalPlayer and Players.LocalPlayer.PlayerScripts then
                effectScripts = Players.LocalPlayer.PlayerScripts:FindFirstChild("EffectScripts")
            end
        end)
        if effectScripts then
            local clientFX = effectScripts:FindFirstChild("ClientFX")
            if clientFX then
                clientFX.Disabled = state
            end
        end

        if state then
            Connections_Manager['No Render'] = workspace.Runtime.ChildAdded:Connect(function(Value)
                Debris:AddItem(Value, 0)
            end)
        else
            if Connections_Manager['No Render'] then
                Connections_Manager['No Render']:Disconnect()
                Connections_Manager['No Render'] = nil
            end
        end
    end
})

local abilityModule = MiscTab:create_module({
    title = "Ability Exploit",
    flag = "AbilityExploit",
    description = "Ability Exploit",
    section = "right",
    callback = function(state)
        getgenv().AbilityExploit = state
    end
})

abilityModule:create_checkbox({
    title = "Thunder Dash No Cooldown",
    flag = "ThunderDashNoCooldown",
    callback = function(state)
        getgenv().ThunderDashNoCooldown = state
        if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then
            local thunderDashModule = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Abilities"):WaitForChild("Thunder Dash")
            local thunderDashData = require(thunderDashModule)
            thunderDashData.cooldown = 0
            thunderDashData.cooldownReductionPerUpgrade = 0
        end
    end
})

abilityModule:create_checkbox({
    title = "Continuity Zero Exploit",
    flag = "ContinuityZeroExploit",
    callback = function(state)
        getgenv().ContinuityZeroExploit = state
        if getgenv().AbilityExploit and getgenv().ContinuityZeroExploit then
            local continuityRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseContinuityPortal")
            local originalFunction
            originalFunction = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if self == continuityRemote and method == "FireServer" then
                    return originalFunction(self, CFrame.new(9e+017, 9e+016, 9e+015, 9e+014, 90000000000000.0, 9000000000000.0, 900000000000.0, 90000000000.0, 9000000000.0, 900000000.0, 90000000.0, 9000000.0), v.Name)
                end
                return originalFunction(self, ...)
            end)
        end
    end
})

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local save_folder = workspace:FindFirstChild("OwO") or Instance.new("Folder", workspace)
save_folder.Name = "OwO"

local function load_pos()
    local file = save_folder:FindFirstChild("ball_ui_pos")
    if not file then return nil end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(file.Value)
    end)

    if ok and data and data.x and data.y then
        return UDim2.new(0, data.x, 0, data.y)
    end

    return nil
end

local function save_pos(udim)
    local data = {
        x = udim.X.Offset,
        y = udim.Y.Offset
    }

    local json = HttpService:JSONEncode(data)

    local file = save_folder:FindFirstChild("ball_ui_pos") or Instance.new("StringValue", save_folder)
    file.Name = "ball_ui_pos"
    file.Value = json
end

local ball_velocity = {
    __config = {
        gui_name = "BallStatsGui",
        colors = {
            background = Color3.fromRGB(20, 20, 20),
            container = Color3.fromRGB(30, 30, 30),
            header = Color3.fromRGB(15, 15, 15),
            text_primary = Color3.fromRGB(255, 255, 255),
            text_secondary = Color3.fromRGB(180, 180, 180),
            accent_green = Color3.fromRGB(200, 200, 200),
            accent_orange = Color3.fromRGB(150, 150, 150),
            border = Color3.fromRGB(45, 45, 45)
        }
    },

    __state = {
        active = false,
        gui = nil,
        ball_data = {},
        is_dragging = false
    }
}

function ball_velocity.create_corner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

function ball_velocity.create_stroke(thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or ball_velocity.__config.colors.border
    return stroke
end

function ball_velocity.create_gui()
    local gui = Instance.new("ScreenGui")
    gui.Name = ball_velocity.__config.gui_name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main_frame = Instance.new("Frame")
    main_frame.Name = "MainFrame"
    main_frame.Size = UDim2.new(0, 180, 0, 95)
    main_frame.Position = load_pos() or UDim2.new(0, 20, 0, 150)
    main_frame.BackgroundColor3 = ball_velocity.__config.colors.background
    main_frame.BorderSizePixel = 0
    main_frame.Parent = gui

    ball_velocity.create_corner(10).Parent = main_frame
    ball_velocity.create_stroke(1, ball_velocity.__config.colors.border).Parent = main_frame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 26)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = ball_velocity.__config.colors.header
    header.BorderSizePixel = 0
    header.Parent = main_frame

    ball_velocity.create_corner(10).Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ball Stats"
    title.TextColor3 = ball_velocity.__config.colors.text_primary
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -18, 1, -34)
    content.Position = UDim2.new(0, 9, 0, 30)
    content.BackgroundTransparency = 1
    content.Parent = main_frame

    local current_label = Instance.new("TextLabel")
    current_label.Name = "CurrentLabel"
    current_label.Size = UDim2.new(1, 0, 0, 14)
    current_label.Position = UDim2.new(0, 0, 0, 2)
    current_label.BackgroundTransparency = 1
    current_label.Text = "Current"
    current_label.TextColor3 = ball_velocity.__config.colors.text_secondary
    current_label.TextSize = 10
    current_label.Font = Enum.Font.Gotham
    current_label.TextXAlignment = Enum.TextXAlignment.Left
    current_label.Parent = content

    local current_value = Instance.new("TextLabel")
    current_value.Name = "CurrentValue"
    current_value.Size = UDim2.new(1, 0, 0, 20)
    current_value.Position = UDim2.new(0, 0, 0, 14)
    current_value.BackgroundTransparency = 1
    current_value.Text = "0.0"
    current_value.TextColor3 = ball_velocity.__config.colors.accent_green
    current_value.TextSize = 16
    current_value.Font = Enum.Font.GothamBold
    current_value.TextXAlignment = Enum.TextXAlignment.Left
    current_value.Parent = content

    local peak_label = Instance.new("TextLabel")
    peak_label.Name = "PeakLabel"
    peak_label.Size = UDim2.new(1, 0, 0, 14)
    peak_label.Position = UDim2.new(0, 0, 0, 36)
    peak_label.BackgroundTransparency = 1
    peak_label.Text = "Peak"
    peak_label.TextColor3 = ball_velocity.__config.colors.text_secondary
    peak_label.TextSize = 10
    peak_label.Font = Enum.Font.Gotham
    peak_label.TextXAlignment = Enum.TextXAlignment.Left
    peak_label.Parent = content

    local peak_value = Instance.new("TextLabel")
    peak_value.Name = "PeakValue"
    peak_value.Size = UDim2.new(1, 0, 0, 20)
    peak_value.Position = UDim2.new(0, 0, 0, 50)
    peak_value.BackgroundTransparency = 1
    peak_value.Text = "0.0"
    peak_value.TextColor3 = ball_velocity.__config.colors.accent_orange
    peak_value.TextSize = 16
    peak_value.Font = Enum.Font.GothamBold
    peak_value.TextXAlignment = Enum.TextXAlignment.Left
    peak_value.Parent = content

    local drag_start, start_pos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            ball_velocity.__state.is_dragging = true
            drag_start = input.Position
            start_pos = main_frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if ball_velocity.__state.is_dragging and
            (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then

            local delta = input.Position - drag_start
            local newpos = UDim2.new(
                start_pos.X.Scale, start_pos.X.Offset + delta.X,
                start_pos.Y.Scale, start_pos.Y.Offset + delta.Y
            )

            main_frame.Position = newpos
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            ball_velocity.__state.is_dragging = false
            save_pos(main_frame.Position)
        end
    end)

    return gui, current_value, peak_value
end

function ball_velocity.start()
    if ball_velocity.__state.active then return end

    ball_velocity.__state.active = true
    ball_velocity.__state.ball_data = {}

    local gui, current_value, peak_value = ball_velocity.create_gui()
    ball_velocity.__state.gui = gui

    System.__properties.__connections.ball_velocity =
        RunService.Heartbeat:Connect(function()

            local ball = System.ball.get()

            if not ball then
                current_value.Text = "0.0"
                peak_value.Text = "0.0"
                return
            end

            local zoomies = ball:FindFirstChild("zoomies")
            if not zoomies then
                current_value.Text = "0.0"
                return
            end

            local velocity = zoomies.VectorVelocity.Magnitude

            ball_velocity.__state.ball_data[ball] =
                ball_velocity.__state.ball_data[ball] or 0

            if velocity > ball_velocity.__state.ball_data[ball] then
                ball_velocity.__state.ball_data[ball] = velocity
            end

            current_value.Text = string.format("%.1f", velocity)
            peak_value.Text = string.format("%.1f",
                ball_velocity.__state.ball_data[ball])
        end)
end

function ball_velocity.stop()
    if not ball_velocity.__state.active then return end

    ball_velocity.__state.active = false

    if System.__properties.__connections.ball_velocity then
        System.__properties.__connections.ball_velocity:Disconnect()
        System.__properties.__connections.ball_velocity = nil
    end

    if ball_velocity.__state.gui then
        ball_velocity.__state.gui:Destroy()
        ball_velocity.__state.gui = nil
    end

    ball_velocity.__state.ball_data = {}
end

MiscTab:create_module({
    title = "Show Ball Velocity",
    description = "Display current and peak ball velocity",
    flag = "ballvelocity",
    section = "right",
    callback = function(state)
        if state then
            ball_velocity.start()
        else
            ball_velocity.stop()
        end
    end
})

local fovChanger = {}

local state = {
    enabled = false,
    fovValue = 70,
    originalFov = nil,
    connection = nil
}

function fovChanger.toggle(enabled)
    state.enabled = enabled
    
    if enabled then
        local camera = workspace.CurrentCamera
        if camera then
            state.originalFov = camera.FieldOfView
            camera.FieldOfView = state.fovValue
        end
        
        if not state.connection then
            state.connection = game:GetService("RunService").RenderStepped:Connect(function()
                local camera = workspace.CurrentCamera
                if camera and state.enabled then
                    camera.FieldOfView = state.fovValue
                end
            end)
        end
    else
        if state.connection then
            state.connection:Disconnect()
            state.connection = nil
        end
        
        local camera = workspace.CurrentCamera
        if camera and state.originalFov then
            camera.FieldOfView = state.originalFov
        end
    end
end

function fovChanger.setFov(value)
    state.fovValue = value
    if state.enabled then
        local camera = workspace.CurrentCamera
        if camera then
            camera.FieldOfView = value
        end
    end
end

local fovModule = MiscTab:create_module({
    title = "FOV Changer",
    description = "Change camera field of view",
    flag = "FOVChanger",
    section = "left",
    callback = fovChanger.toggle
})

fovModule:create_slider({
    title = "FOV Value",
    flag = "FOVValue",
    maximum_value = 120,
    minimum_value = 1,
    value = 70,
    round_number = true,
    callback = fovChanger.setFov
})

-- Keep a reference to revertedRemotes on System if present
if System and System.__properties then
    System.__properties.__reverted_remotes = revertedRemotes
end
