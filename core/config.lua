local _, pockets = ...

local config = {
	defaults = {
		totalGold = 0,
	}
}

function config:Init()
	local db = PocketsDB or {}
	for k, v in pairs(self.defaults) do
		if db[k] == nil then
			db[k] = v
		end
	end
	self.db = db
end

pockets.config = config
