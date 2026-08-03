local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Plots = workspace:WaitForChild("Plots")

local AstralLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aechlaenm/AstralHub/refs/heads/main/Libraries/AstralLib.lua"))()

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
local StatusLabel = AutoSection:Label({ Text = "Plot: searching... (UserId: " .. LocalPlayer.UserId .. ")" })

local PlayerPlot
local Characters
local RollPrompt
local resultConnection
local autoRoll = false
local autoRollRunning = false
local unloaded = false

local function getPlayerPlot()
	for _, plot in ipairs(Plots:GetChildren()) do
		local configuration = plot:FindFirstChild("Configuration")
		local owner = configuration and configuration:FindFirstChild("Owner")
		local value = owner and owner:IsA("ValueBase") and owner.Value

		if value == LocalPlayer or value == LocalPlayer.Name or tostring(value) == tostring(LocalPlayer.UserId) then
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
	StatusLabel:UpdateName("Plot: " .. plot.Name .. " (UserId: " .. LocalPlayer.UserId .. ")")

	if resultConnection then resultConnection:Disconnect() end
	resultConnection = Characters.ChildAdded:Connect(function(character)
		if character:IsA("Model") then
			print("[Astral] Roll result:", character.Name)
		end
	end)

	return true
end

local AutoRollToggle
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

AutoRollToggle = AutoSection:Toggle({
	Name = "Auto Roll",
	Default = false,
	Callback = setAutoRoll,
}, "AutoRoll")
AutoSection:SubLabel({ Text = "New roll results print to the console." })

-- ponytail: six-plot startup scan; use owner-change events only if the plot count grows.
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
