--[[
	AIEvents.

	This file contains the event manager available to AI. It filters events so that
	AIs will only get information that a human player would get.

	Code: Perry
	Date: October, 2015
]]

--Class definition
if AIEvents == nil then
	AIEvents = class({})
end

--Constructor
function AIEvents:constructor( team )
	self.team = team
end

local function ForAllTeams( params, team )
	return true
end

local function IsAlly( unit, team )
	return unit:GetTeamNumber() == team
end

local function IsPlayerAlly( playerID, team )
	return PlayerResource:GetTeam( playerID ) == team
end

--Define event filters
local FilterFunctions = {
	['team_score'] = ForAllTeams,
	['npc_spawned'] = function( params, team )
		--Fetch the spawned unit
		local unit = EntIndexToHScript( params.entindex )

		--Allow the event if it's in team vision
		if InVision( unit, team ) then
			return true
		end

		return false
	end,
	['entity_killed'] = function( params, team )
		local killedUnit = EntIndexToHScript( params.entindex_killed )

		if InVision( killedUnit, team ) then
			return true
		end

		return true
	end,
	['entity_hurt'] = function( params, team )
		--Get hurt unit
		local hurtUnit = EntIndexToHScript( params.entindex_killed )

		--Check if the hurt unit is in vision
		if InVision( hurtUnit, team ) then
			return true
		end

		return false
	end,
	['game_rules_state_change'] = ForAllTeams,
	['modifier_event'] = function( params, team )
		return false
	end,
	['dota_player_kill'] = ForAllTeams,
	['dota_player_deny'] = ForAllTeams,
	['dota_barracks_kill'] = ForAllTeams,
	['dota_tower_kill'] = ForAllTeams,
	['dota_roshan_kill'] = ForAllTeams,
	['dota_courier_lost'] = ForAllTeams,
	['dota_courier_respawned'] = ForAllTeams,
	['dota_glyph_used'] = ForAllTeams,
	['dota_super_creeps'] = ForAllTeams,
	['dota_rune_pickup'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.userid )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['dota_rune_spotted'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.userid )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['dota_item_spotted'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.userid )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['dota_item_picked_up'] = function( params, team )
		local hero = EntIndexToHScript( params.HeroEntityIndex )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['last_hit'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.PlayerID )

		if InVision( hero, team )
			return true
		end

		return false
	end,
	['player_reconnected'] = ForAllTeams,
	['nommed_tree'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.PlayerID )

		if InVision( hero, team )
			return true
		end

		return false
	end,
	['dota_rune_activated_server'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.PlayerID )

		if InVision( hero, team )
			return true
		end

		return false
	end,
	['dota_player_gained_level'] = ForAllTeams,
	['dota_player_pick_hero'] = ForAllTeams,
	['dota_player_learned_ability'] = function( params, team )
		if IsPlayerAlly( params.player ) then
			return true
		end

		return false
	end,
	['dota_player_used_ability'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.PlayerID )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['dota_player_killed'] = ForAllTeams,
	['dota_item_purchased'] = function( params, team )
		if IsPlayerAlly( params.PlayerID, team ) then
			return true
		end

		return false
	end,
	['dota_item_used'] = function( params, team )
		local hero = PlayerResource:GetSelectedHeroEntity( params.PlayerID )

		if InVision( hero, team ) then
			return true
		end

		return false
	end,
	['player_fullyjoined'] = ForAllTeams,
	['dota_match_done'] = ForAllTeams,
	['dota_hero_swap'] = ForAllTeams,
	['show_center_message'] = ForAllTeams,
	['player_chat'] = function( params, team )
		if params.teamonly then
			if IsPlayerAlly( params.userid ) then
				return true
			else
				return false
			end
		else
			return true
		end
	end
}

--Register an event listener
function AIEvents:RegisterEventListener( eventName, callback )
	ListenToGameEvent( eventName, function( s, params )
		--Wait one frame to prevent weirdness
		Timers:CreateTimer( function()
			--Get filter function
			local filter = FilterFunctions[ eventName ]

			--If the filter allows, fire the callback
			if filter and filter( params, self.team ) then
				callback( params )
			end
		end)
	end, self )
end