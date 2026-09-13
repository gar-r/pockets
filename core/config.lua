local _, pockets = ...

local config = {
	defaults = {
		totalGold = 0,
		trackEnabled = true,
	}
}

function config:Init()
	PocketsDB = PocketsDB or {}
	local db = PocketsDB
	for k, v in pairs(self.defaults) do
		if db[k] == nil then
			db[k] = v
		end
	end
	self.db = db
end

function config:GetTotalGold()
	return self.db.totalGold
end

function config:AddTotalGold(amount)
	if self:IsTrackingEnabled() and amount > 0 then
		self.db.totalGold = self.db.totalGold + amount
	end
end

function config:IsTrackingEnabled()
	return self.db.trackEnabled
end

function config:SetTrackingEnabled(value)
	self.db.trackEnabled = value and true or false
end

pockets.config = config
