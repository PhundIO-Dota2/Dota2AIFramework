--[[
	AI Manager.

	Highest level AI module, used for setting up AI in the game.

	Code: Perry
	Date: October, 2015
]]
if AIManager == nil then
	AIManager = class({})
end

function AIManager:Init()
	ListenToGameEvent( 'player_connect', AIManager.OnPlayerConnect, self )
	ListenToGameEvent( 'game_rules_state_change', AIManager.OnGameStateChange, self )

	AIManager.visionDummies = {}
	AIManager.numPlayers = 0

	AIManager.aiHandles = {}

	AIManager.playerRequests = {}
	AIManager.aiPlayers = {}
	AIManager.aiHeroes = {}

	AIManager.heroesToSpawn = 0
	AIManager.heroesSpawned = 0
end

function AIManager:OnPlayerConnect( event )
	--Handle player request
	local request = table.remove( AIManager.playerRequests, 1 )
	PlayerResource:SetCustomTeamAssignment( event.index, request.team )

	--Remember we have to spawn a hero for this player
	AIManager.heroesToSpawn = AIManager.heroesToSpawn + 1

	if AIManager.aiPlayers[ request.team ] == nil then 
		AIManager.aiPlayers[ request.team ] = {} 

		--Initialise array for heroes for this team too while we're at it
		AIManager.aiHeroes[ request.team ] = {} 
	end

	table.insert( AIManager.aiPlayers[ request.team ], { pID = event.index, hero = request.hero } )
end

function AIManager:OnGameStateChange( event )
	local gameState = GameRules:State_Get()

	if gameState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		--In hero selection, spawn the heroes for all AIs
		for team, players in pairs( AIManager.aiPlayers ) do
			for _,player in pairs( players ) do
				--Precache the hero
				print( player.hero )
				PrecacheUnitByNameAsync( player.hero, function()
					AIManager:PrecacheDone( player.pID, player.hero, team )
				end, player.pID )
			end
		end
	end
end

function AIManager:PrecacheDone( pID, heroName, team )
	--Spawn the hero
	local player = PlayerResource:GetPlayer( pID )
	local hero = CreateHeroForPlayer( heroName, player )

	table.insert( AIManager.aiHeroes[ team ], hero )

	--Check if we're done spawning yet
	AIManager.heroesSpawned = AIManager.heroesSpawned + 1
	if AIManager.heroesSpawned == AIManager.heroesToSpawn then
		AIManager:InitAllAI()
	end
end

function AIManager:InitAllAI()
	--Initialise all AI
	print('Initialising AI')
	for team, ai in pairs( AIManager.aiHandles ) do
		ai:Init( { team = team, heroes = AIManager.aiHeroes[ team ] } )
	end
end

--Initialise an AI player
function AIManager:AddAI( name, team, heroes )
	--Load an AI
	local ai = AIManager:LoadAI( name, team )
	AIManager.aiHandles[ team ] = ai

	--Make a dummy to use for visoin checks
	AIManager.visionDummies[ team ] = CreateUnitByName( 'npc_dota_thinker', Vector(0,0,0), false, nil, nil, team )
	AIManager.visionDummies[ team ]:AddNewModifier( nil, nil, 'modifier_dummy', {} ) --Apply the dummy modifier

	--Request heroes
	for i, hero in ipairs( heroes ) do
		table.insert( AIManager.playerRequests, { team = team, hero = hero } )
	end

	AIManager.numPlayers = AIManager.numPlayers + #heroes
	SendToServerConsole( 'dota_create_fake_clients '..AIManager.numPlayers )

	return ai
end

--Load a sandboxed AI player
function AIManager:LoadAI( name, team )
	--Define custom _G
	local global = {}
	global.AIWrapper = AIWrapper( team )
	global.AIEvents = AIEvents( team )

	--Populate global functions
	global = AIManager:PopulateAIGlobals( global, global.AIWrapper )

	--Load file in sandbox
	return setfenv(assert(loadfile('AI.UserAI.sample_ai')), global)()
end

--Make wrapper functions available globally to the AI
function AIManager:PopulateAIGlobals( global, wrapper )
	--Lua defaults
	global.math = math
	global.table = table
	global.bit = bit
	global.print = print
	global.pairs = pairs
	global.ipairs = ipairs
	global.type = type
	global.string = string

	--Auxiliary includes
	global.DeepPrintTable = DeepPrintTable
	global.Timers = Timers
	global.Vector = Vector

	--Default Dota global functions
	global.GetItemCost = GetItemCost
	global.LoadKeyValues = LoadKeyValues
	global.RandomFloat = RandomFloat
	global.RandomInt = RandomInt
	global.RandomVector = RandomVector
	global.RotateOrientation = RotateOrientation
	global.RotatePosition = RotatePosition
	global.RotateQuaternionByAxisAngle = RotateQuaternionByAxisAngle
	global.RotationDelta = RotationDelta

	--Overriden Dota global functions
	function global.AI_FindUnitsInRadius ( ... ) return wrapper:AI_FindUnitsInRadius( ... ) end
	function global.AI_EntIndexToHScript ( ... ) return wrapper:AI_EntIndexToHScript( ... ) end

	--Copy over constants
	for k, v in pairs( _G ) do
		if type( v ) == 'string' or type( v ) == 'number' then
			global[k] = v
		end
	end

	return global
end