--[[
Afk Kick mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
--]]

afkkick = {}

afkkick.maxInactiveTime = tonumber(minetest.settings:get("afkkick.max_inactive_time") or "1800")
afkkick.checkInterval = 120
afkkick.radius = 13
afkkick.kickMessage = "Kicked for loitering at spawn"

-- one time calculation of kickarea
local spawnPos = minetest.string_to_pos(minetest.settings:get("static_spawnpoint") or "(0, 0, 0)")
local radiusVector = { x = afkkick.radius, y = afkkick.radius, z = afkkick.radius }
afkkick.posA = vector.add(spawnPos, radiusVector)
afkkick.posB = vector.subtract(spawnPos, radiusVector)

-- table tracking players times
afkkick.players = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	afkkick.players[playerName] = {
		kickAt = 0
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	afkkick.players[playerName] = nil
end)

-- track time of last call
local iTimeNext = 0

minetest.register_globalstep(function()

	local currentTime = minetest.get_gametime()

	-- Check for inactivity once every CHECK_INTERVAL seconds
	if iTimeNext > currentTime then
		-- not yet
		return
	end

	iTimeNext = currentTime + afkkick.checkInterval

	local playerPos, playerName
	local isInX, isInY, isInZ, isAtSpawn
	local kickTime

	-- Loop through each player that is online
	for _, player in ipairs(minetest.get_connected_players()) do
		playerName = player:get_player_name()
		-- only bother if is a real player
		if 0 < #playerName then
			--Check if this player is near spawn
			playerPos = player:get_pos()
			isInX = (playerPos.x > afkkick.posB.x) and (playerPos.x < afkkick.posA.x)
			isInY = (playerPos.y > afkkick.posB.y) and (playerPos.y < afkkick.posA.y)
			isInZ = (playerPos.z > afkkick.posB.z) and (playerPos.z < afkkick.posA.z)
			isAtSpawn = isInX and isInY and isInZ
			if isAtSpawn then
				kickTime = afkkick.players[playerName].kickAt
				if 0 == kickTime then
					-- first time we check and player is at spawn
					afkkick.players[playerName].kickAt = currentTime + afkkick.maxInactiveTime
				elseif kickTime < currentTime then
					-- player has been here long enough, kick
					minetest.kick_player(playerName, afkkick.kickMessage)
				end
			else
				-- player is out of kick location
				afkkick.players[playerName].kickAt = 0
			end -- if at spawn or not
		end -- if real player
	end -- for loop
end -- function
)
