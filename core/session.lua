local _, pockets = ...

local PickPocketSession = {}
PickPocketSession.__index = PickPocketSession

function PickPocketSession.new()
	return setmetatable({
		active = false,
		lootSeen = false,
		preMoney = 0,
		gold = 0,
	}, PickPocketSession)
end

function PickPocketSession:start(preMoney)
	local leftover = self.gold
	self.active = true
	self.lootSeen = false
	self.preMoney = preMoney
	self.gold = 0
	return leftover
end

function PickPocketSession:recordMoney(currentMoney)
	local delta = currentMoney - self.preMoney
	self.preMoney = currentMoney
	if delta > 0 then
		self.gold = self.gold + delta
	end
	return self.gold, delta
end

function PickPocketSession:markLootOpened()
	self.lootSeen = true
end

function PickPocketSession:finish()
	local gold = self.gold
	self.active = false
	self.lootSeen = false
	self.preMoney = 0
	self.gold = 0
	return gold
end

function PickPocketSession:isActive()
	return self.active
end

function PickPocketSession:hasLoot()
	return self.lootSeen
end

pockets.session = PickPocketSession