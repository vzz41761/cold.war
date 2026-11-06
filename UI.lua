-- cobble hills UI (Guerra Fria - Combat)
local Players = game:GetService("Players")
local Config = getgenv().CobbleConfig
if not Config then return end

local SU = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua"
local ok, S = pcall(function() return loadstring(game:HttpGet(SU), "@Slate")() end)
if not ok or not S then return end

S.Theme.Preset("Violet")
S.Theme.Set({
    Background = Color3.fromRGB(12, 11, 20), Surface = Color3.fromRGB(22, 19, 34),
    SurfaceAlt = Color3.fromRGB(31, 26, 46), Elevated = Color3.fromRGB(39, 31, 57),
    Accent = Color3.fromRGB(255, 50, 50), ToggleOn = Color3.fromRGB(255, 50, 50),
    Text = Color3.fromRGB(245, 242, 255), Muted = Color3.fromRGB(163, 154, 185),
    Radius = 12, RowHeight = 42, HeaderHeight = 56,
})
pcall(function() S:SetFontFamily("Montserrat") end)

local Window = S:CreateWindow({
    Name = "COBBLE <font color='#FF3232'>COMBAT</font>",
    Subtitle = "GUERRA FRIA EDITION",
    Icon = "crosshair", Logo = true,
    Size = UDim2.fromOffset(460, 340),
    ToggleKey = Enum.KeyCode.Insert,
    Backdrop = "aurora",
})

-- ABA 1: COMBATE
local tabCombat = Window:CreateTab({ Name = "AIMBOT", Icon = "crosshair" })
tabCombat:SetColumns(2)

local secAim = tabCombat:CreateSection({ Name = "Aimbot Settings" })
secAim:Toggle({ Name = "Ativar Aimbot", Default = true, Callback = function(v) Config.Aimbot.Enabled = v end })
secAim:Toggle({ Name = "Mostrar FOV", Default = true, Callback = function(v) Config.Aimbot.ShowFOV = v end })
secAim:Toggle({ Name = "Team Check (Aliados)", Default = true, Callback = function(v) Config.Aimbot.TeamCheck = v end })
secAim:Slider({ Name = "FOV", Min = 20, Max = 400, Default = 150, Callback = function(v) Config.Aimbot.FOV = v end })
secAim:Slider({ Name = "Suavidade", Min = 0.1, Max = 1.0, Default = 0.35, Callback = function(v) Config.Aimbot.Smooth = v end })
secAim:Paragraph({ Name = "Tecla Padrão", Text = "Segure o Botão DIREITO do mouse para mirar." })

-- ABA 2: VISUAIS
local tabVisuals = Window:CreateTab({ Name = "ESP & VISUAL", Icon = "eye" })
tabVisuals:SetColumns(2)

local secEsp = tabVisuals:CreateSection({ Name = "ESP Jogadores" })
secEsp:Toggle({ Name = "Ativar ESP", Default = true, Callback = function(v) Config.ESP.Enabled = v end })
secEsp:Toggle({ Name = "Caixa (Box)", Default = true, Callback = function(v) Config.ESP.Box = v end })
secEsp:Toggle({ Name = "Barra de Vida", Default = true, Callback = function(v) Config.ESP.Health = v end })
secEsp:Toggle({ Name = "Nome", Default = true, Callback = function(v) Config.ESP.Name = v end })
secEsp:Toggle({ Name = "Distância", Default = true, Callback = function(v) Config.ESP.Distance = v end })
secEsp:Toggle({ Name = "Tracer", Default = true, Callback = function(v) Config.ESP.Tracer = v end })
secEsp:Toggle({ Name = "Visible Check (Só quem tá na tela)", Default = false, Callback = function(v) Config.ESP.VisibleCheck = v end })
secEsp:Slider({ Name = "Distância Max", Min = 100, Max = 3000, Default = 1000, Callback = function(v) Config.ESP.MaxDist = v end })

local secLuz = tabVisuals:CreateSection({ Name = "Luz e FOV" })
secLuz:Toggle({ Name = "Fullbright", Default = true, Callback = function(v) Config.Visuals.Fullbright = v end })
secLuz:Toggle({ Name = "Remover Neblina", Default = true, Callback = function(v) Config.Visuals.NoFog = v end })
secLuz:Slider({ Name = "Camera FOV (Jogo)", Min = 50, Max = 120, Default = 70, Callback = function(v) Config.Visuals.FOV = v end })

-- ABA 3: MISC
local tabMisc = Window:CreateTab({ Name = "MISC", Icon = "settings" })
tabMisc:SetColumns(1)
local secMove = tabMisc:CreateSection({ Name = "Movimento" })
secMove:Toggle({ Name = "Speed Hack (Leve)", Default = false, Callback = function(v) Config.Movement.SpeedEnabled = v end })
secMove:Slider({ Name = "Velocidade", Min = 16, Max = 50, Default = 22, Callback = function(v) Config.Movement.SpeedValue = v end })

tabMisc:CreateSection({ Name = "Sessão" }):Button({ Name = "UNLOAD SCRIPT", Icon = "trash-2", Callback = function()
    if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
    Window:Destroy(); S:Destroy(); S.Cleanup()
end })

getgenv().Cobble_UI_Loaded = Window
