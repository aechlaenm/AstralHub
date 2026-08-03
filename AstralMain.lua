local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Plots = workspace:WaitForChild("Plots")
local CharacterInfo = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Characters"):WaitForChild("CharactersInfo"))

local AstralLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aechlaenm/AstralHub/refs/heads/main/Libraries/AstralLib.lua"))()

local CharacterRarities = {}
local CharacterOptions = { "None" }
for _, character in ipairs(CharacterInfo.Characters) do
	local chance = tonumber(character.Chance) or 0
	if chance > 0 and chance ~= 69 then
		CharacterRarities[character.Name] = character.Rarity
		table.insert(CharacterOptions, character.Name)
	end
end
table.sort(CharacterOptions, function(a, b)
	if a == "None" then return b ~= "None" end
	if b == "None" then return false end
	return a < b
end)

local Window = AstralLib:Window({
	Title = "Astral",
	Subtitle = "Anime RNG TD",
	Size = UDim2.fromOffset(700, 500),
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
	ShowUserInfo = true,
})

local AutoTab = Window:TabGroup():Tab({ Name = "Auto" })
local AutoSection = AutoTab:Section({ Side = "Left" })

AutoSection:Header({ Text = "Roll" })
local StatusLabel = AutoSection:Label({ Text = "Plot: searching..." })

local PlayerPlot
local Characters
local RollPrompt
local resultConnection
local autoRoll = false
local autoRollRunning = false
local unloaded = false
local targetRarity
local targetCharacter
local AutoRollToggle

local function getPlayerPlot()
	for _, plot in ipairs(Plots:GetChildren()) do
		if tonumber(plot:GetAttribute("FightOwnerUserId")) == LocalPlayer.UserId then
			return plot
		end
	end
end

local function resolvePlayerPlot()
	if PlayerPlot and PlayerPlot.Parent and RollPrompt and RollPrompt.Parent then
		return true
	end

	local plot = getPlayerPlot()
	local characters = plot and plot:FindFirstChild("Characters")
	local prompt = plot and plot:FindFirstChild("RollPrompt", true)
	if not (characters and prompt and prompt:IsA("ProximityPrompt")) then
		return false
	end

	PlayerPlot, Characters, RollPrompt = plot, characters, prompt
	RollPrompt.MaxActivationDistance = math.huge
	StatusLabel:UpdateName("Plot: " .. plot.Name)

	if resultConnection then resultConnection:Disconnect() end
	resultConnection = Characters.ChildAdded:Connect(function(character)
		if character:IsA("Model") then
			local rarity = CharacterRarities[character.Name] or character:GetAttribute("Rarity")
			print("[Astral] Roll result:", character.Name, rarity or "Unknown")

			if autoRoll and ((targetRarity and targetRarity == rarity) or (targetCharacter and targetCharacter == character.Name)) then
				autoRoll = false
				task.defer(function() AutoRollToggle:UpdateState(false) end)
				Window:Notify({
					Title = "Astral",
					Description = "Target found: " .. character.Name .. " (" .. (rarity or "Unknown") .. ")",
					Lifetime = 5,
				})
			end
		end
	end)

	return true
end

local function setAutoRoll(enabled)
	if enabled and type(fireproximityprompt) ~= "function" then
		Window:Notify({
			Title = "Astral",
			Description = "Your executor does not support fireproximityprompt.",
			Lifetime = 5,
		})
		task.defer(function() AutoRollToggle:UpdateState(false) end)
		return
	end

	autoRoll = enabled
	if autoRollRunning or not enabled then return end

	autoRollRunning = true
	task.spawn(function()
		while autoRoll and not unloaded do
			if resolvePlayerPlot() and RollPrompt.Enabled then
				fireproximityprompt(RollPrompt)
			end
			task.wait(1)
		end
		autoRollRunning = false
	end)
end

AutoSection:Dropdown({
	Name = "Target Rarity",
	Search = false,
	Multi = false,
	Required = true,
	Options = { "None", "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "God", "Limited" },
	Default = 1,
	Callback = function(value)
		targetRarity = value ~= "None" and value or nil
	end,
}, "TargetRarity")

AutoSection:Dropdown({
	Name = "Target Character",
	Search = true,
	Multi = false,
	Required = true,
	Options = CharacterOptions,
	Default = 1,
	Callback = function(value)
		targetCharacter = value ~= "None" and value or nil
	end,
}, "TargetCharacter")

AutoRollToggle = AutoSection:Toggle({
	Name = "Auto Roll",
	Default = false,
	Callback = setAutoRoll,
}, "AutoRoll")
AutoSection:SubLabel({ Text = "Stops when either selected target is rolled. None keeps rolling." })

-- Retry only until the server assigns FightOwnerUserId.
task.spawn(function()
	while not unloaded and not resolvePlayerPlot() do
		task.wait(1)
	end
end)

Window.onUnloaded(function()
	unloaded = true
	autoRoll = false
	if resultConnection then resultConnection:Disconnect() end
end)

AutoTab:Select()
