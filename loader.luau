local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local function load(name: string): any
	local module = Modules:FindFirstChild(name)
	assert(module, `Module '{name}' not found`)
	return require(module)
end

local function init()
	local player = Players.LocalPlayer

	load("SlimeManager").init(player)
	load("RNGHandler").init(player)
end

init()
