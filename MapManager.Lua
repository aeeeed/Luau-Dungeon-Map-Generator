local replicatedStorage = game:GetService("ReplicatedStorage")
local assetFolder = replicatedStorage:WaitForChild("Blocks")
local dungeon = game.Workspace.Dungeon

local Block = require(script.Block)

local blocks = {}
local blockCount = 0
local maxBlocks = 100

local sectionCount = 0
local maxSections = 10
local minSectionBlocks = 10

local function contains(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

local function findModel(search)
	for index, value in blocks do
		if value.model == search then
			return value
		end
	end
end

local function checkBlock(position, offset)
	local checkBox = replicatedStorage:WaitForChild("CheckBlock"):Clone()
	local primaryPart = checkBox:FindFirstChild("CheckPart")
	checkBox.PrimaryPart = checkBox:FindFirstChild("Entrance")

	if offset == 0 or offset == nil then
		checkBox:PivotTo(position)
	else
		checkBox:PivotTo(position * offset)
	end

	checkBox.Parent = game.Workspace.Dungeon
	checkBox.PrimaryPart = primaryPart
	
	
	local parts = game.Workspace:GetPartsInPart(primaryPart)
	--wait(0.2)
	checkBox:Destroy()

	local collision
	if #parts >= 1  then
		collision = parts[1]
		while collision and collision.Parent do
			if collision:GetAttribute("isRoom") or collision:GetAttribute("isCheckbox") or collision:GetAttribute("isStartingRoom") then
				break
			end

			collision = collision.Parent
		end

		if collision and collision.Parent then
			if collision:GetAttribute("isRoom") == true then
				print("Returning: " .. collision.Name)
				
				local returnBlock = findModel(collision)
				
				print(returnBlock)
				
				return returnBlock

			elseif collision:GetAttribute("isCheckbox") == true	 then
				print("Detected another checkbox: " .. collision.Name)
				local rand = math.random(0.1, 0.5)
				wait(rand)
				checkBlock(position, offset)
			elseif collision:GetAttribute("isStartingRoom") == true then
				return "startingRoom"
			else
				print("Collision has no valid attributes.")
			end
		elseif not collision and collision.Parent then
			print("Error: Collision was deleted")
			local rand = math.random(0.1, 0.5)
			wait(rand)
			checkBlock(position, offset)
		end

	else
		print("No parts detected")
		return collision
	end
end

local function processNeighbors(block)
	local blockModel = block.model
	
	for _,v in pairs(blockModel:GetChildren()) do
		if v.Name == "Exit" then
			local position = v:GetPivot()
			local neighbor = coroutine.wrap(checkBlock)(position, 0)
			
			if neighbor then
				block:addNeighbor(neighbor)
				neighbor:addNeighbor(block)
			end
		end
	end
end

local function connectBlocks(blockOne, blockTwo)
	local function removeExits(blockOne, blockTwo)
		for _,v in pairs(blockOne.model:GetChildren()) do
			if v.Name == "Exit" then
				local position = v:GetPivot()
				local checkedBlock = checkBlock(position, 0)
				
				if checkedBlock ~= nil then
					if checkedBlock.model == blockTwo.model then
						v:Destroy()
					end
				end
			end
		end
	end
	
	removeExits(blockOne, blockTwo)
	removeExits(blockTwo, blockOne)
	
	blockOne:connectTo(blockTwo)
	blockTwo:connectTo(blockOne)
end

local function insertBlock(prevBlock, v)
	local collision  = checkBlock(v.CFrame, 0)

	if collision then
		if collision == "startingRoom" then
			return	
		end
		
		connectBlocks(prevBlock, collision)
		return
	else
		local newModel = replicatedStorage.Blocks:FindFirstChild("BlockOne"):Clone()
		local primaryPart = newModel:FindFirstChild("PrimaryPart")
		local entrance = newModel:FindFirstChild("Entrance")

		newModel.PrimaryPart = entrance

		local offset = CFrame.new(0,0,1)

		newModel:PivotTo(v.CFrame * offset)
		newModel.PrimaryPart = primaryPart

		entrance:Destroy()
		v:Destroy()

		newModel.Parent = game.Workspace.Dungeon

		local newBlock = Block.new(blockCount, 1, newModel)
		newModel.Name = blockCount
		blockCount += 1

		table.insert(blocks, newBlock)
		
		for _,v in pairs(newModel:GetChildren()) do
			local exitDir = v:GetAttribute("ExitDirection")
			if v.Name == "Exit" then
				collision  = checkBlock(v.CFrame, 0)
				
				if collision then
					if collision == "startingRoom" then
						return
					end
					
					connectBlocks(newBlock, collision)
					return
				end
			end
		end
		
		return newBlock
	end
end

local branches = {"L", "R", "2pt", "3pt"}

local function generate(prevBlock)
	
	local hallwayCount = math.random(3,4)
	
	local lastGenBlock = prevBlock
	local lastGenBlockModel = lastGenBlock.model

	for count = 0, hallwayCount do
		for _,v in pairs(lastGenBlockModel:GetChildren()) do
			local exitDir = v:GetAttribute("ExitDirection")
			
			if v.Name == "Exit" and exitDir == 2 then
				lastGenBlock = insertBlock(lastGenBlock, v)
				print(lastGenBlock)
				if lastGenBlock then
					lastGenBlockModel = lastGenBlock.model
					break
				else
					return	
				end
			end
		end
	end
	
	local branch = branches[math.random(1,4)]
	
	local findDir = {}
	if branch == "L" then
		findDir = {1}
	elseif branch == "R" then
		findDir = {3}
	elseif branch == "2pt" then
		findDir = {1,3}
	elseif branch == "3pt" then
		findDir = {1,2,3}
	end

	local dirIndex = 0
	local function branchout()
		for _,v in pairs(lastGenBlockModel:GetChildren()) do
			local exitDir = v:GetAttribute("ExitDirection")
			if v.Name == "Exit" and exitDir == findDir[dirIndex] then
				return insertBlock(lastGenBlock, v)
			end
		end
	end
	
	local branches = {}
	for count = 0, #findDir, 1 do
		dirIndex += 1
		if sectionCount < maxSections then
			branch = branchout()
			if lastGenBlock ~= nil then
				sectionCount += 1
				
				table.insert(branches, branch)
				lastGenBlockModel = lastGenBlock.model
			else
				return
			end
		else 
			break
		end
	end
	
	if branches then
		for i, branch in pairs(branches) do
			coroutine.wrap(generate)(branch)
		end
	end
end

local startingBlock = Block.new(blockCount, 1, replicatedStorage:WaitForChild("StartingBlock"):Clone())
local startingModel = startingBlock.model
startingModel.Parent = dungeon

local startingRoom = dungeon.StartingRoom
local startingRoomExit = startingRoom.Exit
local exitPos = startingRoomExit.Position

local primaryPart = startingModel:FindFirstChild("PrimaryPart")
startingModel.PrimaryPart = startingModel.Entrance
startingModel:SetPrimaryPartCFrame(CFrame.new(exitPos))
startingModel.PrimaryPart = primaryPart
startingModel.Entrance:Destroy()
blockCount += 1

table.insert(blocks, startingBlock)
generate(startingBlock)
print(blocks)

local function checkRoomCollision()
	
end

local currentRoomGenerated = 0
local Maxrooms = 5

local function placeRooms(exitPos)
	local room = replicatedStorage:FindFirstChild("Rooms"):FindFirstChild("RoomOne"):Clone()
	
	--Position Room
	room.PrimaryPart = room:FindFirstChild("Entrance")
	room:PivotTo(exitPos)
	room.PrimaryPart = room:FindFirstChild("PrimaryPart")
	local primaryPart = room.PrimaryPart
	
	--Get size of new room
	local exclude = room:FindFirstChild("Entrance")
	exclude:Destroy()
	
	local roomSize = room:GetExtentsSize()
	
	--Create checkbox to see if area is clear to place new room
	local offset = Vector3.new(0,0,0)
	local newPosition = room:GetPrimaryPartCFrame().Position

	local checkBox = Instance.new("Part", game.Workspace.Debris)
	checkBox.Anchored = true
	checkBox.Size = roomSize
	checkBox:SetAttribute("isRoom", true)
	checkBox:PivotTo(primaryPart.CFrame)

	local partsInCheckBox = game.Workspace:GetPartsInPart(checkBox)
	
	wait(1)
	
	checkBox:Destroy()
	local clearHallway = true

	if #partsInCheckBox > 0 then
		local partsLen = #partsInCheckBox

		for i=1, partsLen do

			local parent = partsInCheckBox[i]

			while parent.Parent do
				if parent.Parent:GetAttribute("isRoom") == true then
					parent = parent.Parent
					break
				end

				parent = parent.Parent
			end
		end
		clearHallway = false
	elseif #partsInCheckBox <= 0 then
		clearHallway = true
	end

	if clearHallway == false then
		print("DESTROY")
		room:Destroy()

	else
		room.Parent = game.Workspace.Dungeon
		currentRoomGenerated += 1
	end
end

if sectionCount == maxSections then
	for i,block in pairs(blocks) do
		if block.model then
			for i,v in pairs(block.model:GetChildren()) do
				if v.Name == "Exit" and currentRoomGenerated <= Maxrooms then
					placeRooms(v.CFrame)
					v:Destroy()
					break
				end
			end
		end
	end
end
