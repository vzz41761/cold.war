-- cobble hills logic (Guerra Fria - V2 Rage)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not Drawing then warn("[cobble] Sem Drawing API"); return end

-- ==========================================
-- CONFIGURAÇÃO
-- ==========================================
local defaults = {
    Movement = { SpeedEnabled=false, SpeedValue=22 },
    Aimbot = { 
        Enabled=true, Key=Enum.UserInputType.MouseButton2, FOV=150, Smooth=0.35, 
        ShowFOV=true, TeamCheck=true, Part="Head", AutoFire=false, FOVPulse=true
    },
    ESP = { 
        Enabled=true, Box=true, Health=true, Name=true, Distance=true, Tracer=true, 
        MaxDist=1000, VisibleCheck=false, HiddenColor=Color3.fromRGB(150, 50, 255) 
    },
    Visuals = { Fullbright=true, NoFog=true, FOV=70 },
    Rage = { HitboxExpander=false, HitboxSize=8 }
}
local Config = getgenv().CobbleConfig or {}
local function merge(dst, src) for k,v in pairs(src) do if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) elseif dst[k] == nil then dst[k] = v end end end
for s,tbl in pairs(defaults) do Config[s] = Config[s] or {}; merge(Config[s], tbl) end
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- ==========================================
-- CACHE E HITBOX
-- ==========================================
local CachedPlayers = {}
task.spawn(function()
    while alive do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                
                if hum and root and hum.Health > 0 then
                    temp[plr] = { Char=plr.Character, Hum=hum, Root=root, Head=head, Team=plr.Team }
                    
                    -- Hitbox Expander (Opcional)
                    if head then
                        if Config.Rage.HitboxExpander then
                            if head.Size ~= Vector3.new(Config.Rage.HitboxSize, Config.Rage.HitboxSize, Config.Rage.HitboxSize) then
                                head.Size = Vector3.new(Config.Rage.HitboxSize, Config.Rage.HitboxSize, Config.Rage.HitboxSize)
                                head.Transparency = 0.5
                            end
                        else
                            if head.Size ~= Vector3.new(2, 1, 1) then
                                head.Size = Vector3.new(2, 1, 1)
                                head.Transparency = 0
                            end
                        end
                    end
                end
            end
        end
        CachedPlayers = temp
        task.wait(0.2)
    end
end)

-- ==========================================
-- WALL CHECK MELHORADO
-- ==========================================
local function isVisible(targetChar)
    if not Config.ESP.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local targetPos = targetChar.Head.Position
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LP.Character, targetChar}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local hit = Workspace:Raycast(origin, (targetPos - origin), rayParams)
    return hit == nil
end

-- ==========================================
-- AIMBOT
-- ==========================================
local aimHeld, aimTarget = false, nil

local function isAimInput(input)
    local b = Config.Aimbot.Key
    if typeof(b) ~= "EnumItem" then return false end
    if b.EnumType == Enum.KeyCode then return input.KeyCode == b end
    return input.UserInputType == b
end

local function getBodyPart(data)
    if Config.Aimbot.Part == "Head" then return data.Head end
    if Config.Aimbot.Part == "Torso" then return data.Root end
    if Config.Aimbot.Part == "Nearest" then
        local spHead, _ = Camera:WorldToViewportPoint(data.Head.Position)
        local spRoot, _ = Camera:WorldToViewportPoint(data.Root.Position)
        local center = Camera.ViewportSize * 0.5
        local dHead = (Vector2.new(spHead.X, spHead.Y) - center).Magnitude
        local dRoot = (Vector2.new(spRoot.X, spRoot.Y) - center).Magnitude
        return dHead < dRoot and data.Head or data.Root
    end
    return data.Head
end

local function pickTarget()
    if aimTarget and aimTarget.Char.Parent and aimTarget.Hum.Health > 0 then
        if Config.Aimbot.TeamCheck and aimTarget.Team == LP.Team then aimTarget = nil; return nil end
        if not isVisible(aimTarget.Char) then aimTarget = nil; return nil end
        return aimTarget
    end
    
    aimTarget = nil
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aimbot.FOV
    
    for _, d in pairs(CachedPlayers) do
        if d.Hum.Health > 0 then
            if not (Config.Aimbot.TeamCheck and d.Team == LP.Team) then
                local part = getBodyPart(d)
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if sp.Z > 0 and on then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < bestD then
                            if isVisible(d.Char) then
                                bestD = dist; best = d
                            end
                        end
                    end
                end
            end
        end
    end
    aimTarget = best
    return best
end

track(UserInputService.InputBegan:Connect(function(i, gpe) if not gpe and isAimInput(i) then aimHeld = true; aimTarget = nil end end))
track(UserInputService.InputEnded:Connect(function(i) if isAimInput(i) then aimHeld = false; aimTarget = nil end end))

-- Bind para Aimbot e FOV do jogo
RunService:BindToRenderStep("cobble_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    -- Força o FOV da câmera
    if Camera.FieldOfView ~= Config.Visuals.FOV then
        Camera.FieldOfView = Config.Visuals.FOV
    end

    -- Aimbot
    if not Config.Aimbot.Enabled or not aimHeld then return end
    local t = pickTarget()
    if not t then return end
    
    local part = getBodyPart(t)
    local want = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    local s = math.clamp(Config.Aimbot.Smooth, 0.01, 1)
    
    Camera.CFrame = Camera.CFrame:Lerp(want, 1 - (1 - s) ^ (dt * 60))
end)

-- Auto-Fire (Atira sozinho se estiver mirado)
local lastFire = 0
track(RunService.RenderStepped:Connect(function()
    if not Config.Aimbot.AutoFire or not aimHeld then return end
    local t = aimTarget
    if t then
        local sp, on = Camera:WorldToViewportPoint(getBodyPart(t).Position)
        if on and sp.Z > 0 then
            if tick() - lastFire > 0.1 then
                lastFire = tick()
                if mouse1click then mouse1click() 
                elseif keypress then keypress(0x01); task.wait(0.05); keyrelease(0x01) end
            end
        end
    end
end))

-- ==========================================
-- LUZES E EFEITOS
-- ==========================================
local FB_Defaults = { Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd }
local fbCC = nil
track(RunService.Heartbeat:Connect(function()
    if Config.Visuals.Fullbright then
        if not fbCC then fbCC = Instance.new("ColorCorrectionEffect"); fbCC.Brightness = 1; fbCC.Parent = Lighting end
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Brightness = 3; Lighting.ClockTime = 14
    else
        if fbCC then fbCC:Destroy(); fbCC = nil end
        for k, v in pairs(FB_Defaults) do pcall(function() Lighting[k] = v end) end
    end
    Lighting.FogEnd = Config.Visuals.NoFog and 1e5 or FB_Defaults.FogEnd

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Movement.SpeedEnabled and Config.Movement.SpeedValue or 16 end
    end
end))

-- ==========================================
-- ESP
-- ==========================================
local pDraw = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5; fovCircle.Filled = false; fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(255, 50, 50)

track(RunService.RenderStepped:Connect(function()
    local camPos = Camera.CFrame.Position
    local activeP = {}
    
    if Config.ESP.Enabled then
        for plr, data in pairs(CachedPlayers) do
            if data.Hum.Health > 0 and data.Head then
                local vis = isVisible(data.Char)
                
                if vis or not Config.ESP.VisibleCheck then
                    activeP[plr] = true
                    local o = pDraw[plr]
                    if not o then
                        o = {
                            box=Drawing.new("Square"), healthBg=Drawing.new("Square"), healthFill=Drawing.new("Square"),
                            name=Drawing.new("Text"), dist=Drawing.new("Text"), tracer=Drawing.new("Line")
                        }
                        o.box.Thickness = 1; o.box.Filled = false
                        o.healthBg.Filled = true; o.healthBg.Color = Color3.new(0,0,0); o.healthBg.Transparency = 0.5
                        o.healthFill.Filled = true
                        o.name.Center=true; o.name.Outline=true; o.name.Size=13; o.name.Color=Color3.new(1,1,1)
                        o.dist.Center=true; o.dist.Outline=true; o.dist.Size=12; o.dist.Color=Color3.fromRGB(200,205,220)
                        o.tracer.Thickness = 1
                        pDraw[plr] = o
                    end
                    
                    -- Cor: Time (Verde), Inimigo Visível (Vermelho), Inimigo Atrás da Parede (Roxo)
                    local color = Color3.fromRGB(255, 60, 60)
                    if Config.Aimbot.TeamCheck and data.Team == LP.Team then
                        color = Color3.fromRGB(50, 255, 50)
                    elseif not vis then
                        color = Config.ESP.HiddenColor
                    end
                    
                    o.box.Color = color; o.tracer.Color = color
                    
                    local sp, on = Camera:WorldToViewportPoint(data.Root.Position + Vector3.new(0,3,0))
                    local spBot, onBot = Camera:WorldToViewportPoint(data.Root.Position - Vector3.new(0,3,0))
                    local dist = (camPos - data.Root.Position).Magnitude
                    
                    if sp.Z > 0 and on and onBot and dist <= Config.ESP.MaxDist then
                        local h = spBot.Y - sp.Y; local w = h * 0.6
                        local bx, by = sp.X - w/2, sp.Y
                        
                        o.box.Position = Vector2.new(bx, by); o.box.Size = Vector2.new(w, h); o.box.Visible = Config.ESP.Box
                        
                        if Config.ESP.Health then
                            local frac = math.clamp(data.Hum.Health / math.max(data.Hum.MaxHealth, 1), 0, 1)
                            o.healthBg.Position = Vector2.new(bx - 5, by); o.healthBg.Size = Vector2.new(3, h); o.healthBg.Visible = true
                            o.healthFill.Position = Vector2.new(bx - 5, by + h*(1-frac)); o.healthFill.Size = Vector2.new(3, h*frac)
                            o.healthFill.Color = Color3.fromRGB(255*(1-frac), 255*frac, 60); o.healthFill.Visible = true
                        else o.healthBg.Visible = false; o.healthFill.Visible = false end

                        o.name.Text = plr.Name; o.name.Position = Vector2.new(sp.X, by - 16); o.name.Visible = Config.ESP.Name
                        o.dist.Text = math.floor(dist) .. "m"; o.dist.Position = Vector2.new(sp.X, spBot.Y + 4); o.dist.Visible = Config.ESP.Distance
                        
                        if Config.ESP.Tracer then
                            o.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            o.tracer.To = Vector2.new(sp.X, spBot.Y); o.tracer.Visible = true
                        else o.tracer.Visible = false end
                    else
                        o.box.Visible=false; o.healthBg.Visible=false; o.healthFill.Visible=false
                        o.name.Visible=false; o.dist.Visible=false; o.tracer.Visible=false
                    end
                end
            end
        end
    end
    
    for p, o in pairs(pDraw) do 
        if not activeP[p] then 
            o.box:Remove(); o.healthBg:Remove(); o.healthFill:Remove(); o.name:Remove(); o.dist:Remove(); o.tracer:Remove()
            pDraw[p] = nil 
        end 
    end

    -- Desenho do FOV (Pulse Effect)
    if Config.Aimbot.Enabled and Config.Aimbot.ShowFOV and aimHeld then
        fovCircle.Position = Camera.ViewportSize * 0.5
        if Config.Aimbot.FOVPulse then
            fovCircle.Radius = Config.Aimbot.FOV + math.sin(tick() * 10) * 3
            fovCircle.Color = Color3.fromRGB(255, 100, 100)
        else
            fovCircle.Radius = Config.Aimbot.FOV
            fovCircle.Color = Color3.fromRGB(255, 50, 50)
        end
        fovCircle.Visible = true
    else 
        fovCircle.Visible = false 
    end
end))

getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, o in pairs(pDraw) do o.box:Remove(); o.healthBg:Remove(); o.healthFill:Remove(); o.name:Remove(); o.dist:Remove(); o.tracer:Remove() end
    pcall(function() fovCircle:Remove() end)
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
    if fbCC then fbCC:Destroy() end
    print("[cobble] Combat Script Unloaded.")
end
