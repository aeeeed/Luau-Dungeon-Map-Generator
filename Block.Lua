local Block = {}
Block.__index = Block

Block.instances = {}

function Block.new(id, possibleConnections, model)
	local self = setmetatable({}, Block)
	self.ID = id
	self.model = model
	
	self.isRoom = true
	
	self.availableNeighbors = 4
	self.neighbors = {}
	
	self.availableConnections = 4
	self.connectedTo = {}
	
	return self
end

function Block:addNeighbor(neighborBlock)
	if self.availableNeighbors > 0 then
		table.insert(self.neighbors, neighborBlock)
		self.availableNeighbors -= 1
	end
end

function Block:connectTo(otherBlock)
	if self.availableConnections > 0 then
		table.insert(self.connectedTo, otherBlock)
		self.availableConnections -= 1
		
		self:addNeighbor(otherBlock)
	end	
end

function Block:printConnections()
	print("Block " .. self.ID .. " connections:")
	for _, block in ipairs(self.connectedTo) do
		print("- Connected to Block " .. block.ID)
	end
end

function Block:printNeighbors()
	print("Block " .. self.ID .. " neighbors:")
	for _, block in ipairs(self.neighbors) do
		print("- Neighbor Block " .. block.ID)
	end
end

return Block
