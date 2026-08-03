local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Plots = workspace:WaitForChild("Plots")

local AstralLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aechlaenm/AstralHub/refs/heads/main/Libraries/AstralLib.lua"))()

local function getPlayerPlot()
	for _, plot in ipairs(Plots:GetChildren()) do
		local configuration = plot:FindFirstChild("Configuration")
		local owner = configuration and configuration:FindFirstChild("Owner")
		local value = owner and owner.Value

		if value == LocalPlayer or value == LocalPlayer.Name or tostring(value) == tostring(LocalPlayer.UserId) then
			return plot
		end
	end
end

local PlayerPlot
repeat
	PlayerPlot = getPlayerPlot()
	if not PlayerPlot then task.wait(1) end
until PlayerPlot

local Characters = PlayerPlot:WaitForChild("Characters")
local RollPrompt = PlayerPlot:FindFirstChild("RollPrompt", true)

assert(RollPrompt and RollPrompt:IsA("ProximityPrompt"), "Astral: RollPrompt not found")
assert(type(fireproximityprompt) == "function", "Astral: executor does not support fireproximityprompt")

local autoRoll = false
local autoRollRunning = false

local resultConnection = Characters.ChildAdded:Connect(function(character)
	if character:IsA("Model") then
		print("[Astral] Roll result:", character.Name)
	end
end)

local function setAutoRoll(enabled)
	autoRoll = enabled
	if autoRollRunning or not enabled then return end

	autoRollRunning = true
	task.spawn(function()
		while autoRoll do
			if RollPrompt.Enabled then
				fireproximityprompt(RollPrompt)
			end
			task.wait(1)
		end
		autoRollRunning = false
	end)
end

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
AutoSection:Label({ Text = "Plot: " .. PlayerPlot.Name .. " (UserId: " .. LocalPlayer.UserId .. ")" })
AutoSection:Toggle({
	Name = "Auto Roll",
	Default = false,
	Callback = setAutoRoll,
}, "AutoRoll")
AutoSection:SubLabel({ Text = "New roll results print to the console." })

Window.onUnloaded(function()
	setAutoRoll(false)
	resultConnection:Disconnect()
end)

AutoTab:Select()
