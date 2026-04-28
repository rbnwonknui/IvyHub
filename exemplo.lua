local antoralib = loadstring(game:HttpGet("https://raw.githubusercontent.com/rbnwonknui/IvyHub/refs/heads/main/main.lua"))()

-- Criar janela
local Window = antoralib:MakeWindow({
    Name = "IvyHub",
    SubTitle = "by: rbnwonknui",
    SaveFolder = "IvyHub.json"
})

-- Botão de minimizar
Window:AddMinimizeButton({
    Button = {
        BackgroundTransparency = 0,
        Image = "rbxassetid://71014873973869"
    },
    Corner = { CornerRadius = UDim.new(0, 35) }
})

-- aba principal
local Tab1 = Window:MakeTab({ "Main", "home" })

Tab1:AddSection("General")

Tab1:AddParagraph({
    "Welcome",
    "This is an example script using IvyHub library."
})

Tab1:AddButton({
    "Print Hello",
    function()
        print("Hello World!")
    end
})

Tab1:AddToggle({
    "God Mode",
    false,
    function(Value)
        print("God Mode:", Value)
    end,
    "godmode_flag"
})

Tab1:AddSlider({
    "Walk Speed",
    16,   -- Min
    500,  -- Max
    1,    -- Increase
    16,   -- Default
    function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
    "walkspeed_flag"
})

Tab1:AddDropdown({
    "Select Team",
    { "Red", "Blue", "Green" },
    "Red",
    function(Value)
        print("Selected:", Value)
    end,
    "team_flag"
})

Tab1:AddTextBox({
    "Custom Message",
    "",
    false,
    function(Value)
        print("Message:", Value)
    end,
    "Type here..."
})

-- Aba de informações do servidor
local Tab2 = Window:MakeTab({ "Info", "info" })

Tab2:AddServerInfo({
    ScriptVersion = "v1.0"
})

-- Aba de suporte ao jogo
local Tab3 = Window:MakeTab({ "Game", "gamepad" })

Tab3:AddGameSupport({
    PlaceId = game.PlaceId,
    LastUpdate = "28/04/2026"
})

-- Notificação de boas-vindas
Window:Notify({
    Title = "IvyHub Loaded",
    Content = "Script loaded successfully!",
    Duration = 5
})
