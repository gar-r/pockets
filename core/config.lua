local _, pockets = ...

local config = {
	defaults = {
		totalGold = 0,
		trackEnabled = true,
		showGoldFrame = true,
		resetOnLogin = false,
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
	self.totalGoldListeners = self.totalGoldListeners or {}
end

function config:GetTotalGold()
	return self.db.totalGold
end

function config:AddTotalGold(amount)
	if self:IsTrackingEnabled() and amount > 0 then
		self.db.totalGold = self.db.totalGold + amount
		self:notifyTotalGoldChanged()
	end
end

function config:ResetTotalGold()
	self.db.totalGold = 0
	self:notifyTotalGoldChanged()
end

function config:RegisterTotalGoldListener(fn)
	table.insert(self.totalGoldListeners, fn)
end

function config:notifyTotalGoldChanged()
	for _, fn in ipairs(self.totalGoldListeners) do
		fn(self:GetTotalGold())
	end
end

function config:IsTrackingEnabled()
	return self.db.trackEnabled
end

function config:SetTrackingEnabled(value)
	self.db.trackEnabled = value and true or false
end

function config:IsShowGoldFrameEnabled()
	return self.db.showGoldFrame
end

function config:SetShowGoldFrame(value)
	self.db.showGoldFrame = value and true or false
end

function config:IsResetOnLoginEnabled()
	return self.db.resetOnLogin
end

function config:SetResetOnLoginEnabled(value)
	self.db.resetOnLogin = value and true or false
end

pockets.config = config
