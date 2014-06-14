teams = require("sourcemod/game/teams")
log = require("sourcemod/log")
interop = require("sourcemod/interop")
adminModule = require("sourcemod/admin")

natives.declare("GetClientCount")
natives.declare("GetClientName")
natives.declare("GetClientIP")
natives.declare("GetClientAuthString")
natives.declare("GetClientUserId")
natives.declare("IsClientConnected",types.bool)
natives.declare("IsClientInGame",types.bool)
natives.declare("IsClientInKickQueue",types.bool)
natives.declare("IsClientAuthorized",types.bool)
natives.declare("IsFakeClient",types.bool)
natives.declare("IsClientSourceTV",types.bool)
natives.declare("IsClientReplay",types.bool)
natives.declare("IsClientObserver",types.bool)
natives.declare("IsPlayerAlive",types.bool)
natives.declare("GetClientInfo")
natives.declare("GetClientTeam")
natives.declare("SetUserAdmin")
natives.declare("GetUserAdmin")
#natives.declare("AddUserFlags")
#natives.declare("RemoveUserFlags")
natives.declare("SetUserFlagBits")
natives.declare("GetUserFlagBits")
natives.declare("CanUserTarget",types.bool)
natives.declare("RunAdminCacheChecks")
natives.declare("NotifyPostAdminCheck")
natives.declare("CreateFakeClient")
natives.declare("SetFakeClientConVar")
natives.declare("GetClientHealth")
natives.declare("GetClientModel")
natives.declare("GetClientWeapon")
natives.declare("GetClientMaxs")
natives.declare("GetClientMins")
natives.declare("GetClientAbsAngles")
natives.declare("GetClientAbsOrigin")
natives.declare("GetClientArmor")
natives.declare("GetClientDeaths")
natives.declare("GetClientFrags")
natives.declare("GetClientDataRate")
natives.declare("IsClientTimingOut")
natives.declare("GetClientTime",types.float)
natives.declare("GetClientLatency",types.float)
natives.declare("GetClientAvgLatency",types.float)
natives.declare("GetClientAvgLoss",types.float),types.float
natives.declare("GetClientAvgChoke",types.float)
natives.declare("GetClientAvgData",types.float)
natives.declare("GetClientAvgPackets",types.float)
natives.declare("GetClientOfUserId")
natives.declare("KickClient")
natives.declare("KickClientEx")
natives.declare("ChangeClientTeam")
natives.declare("GetClientSerial")
natives.declare("GetClientFromSerial")

@enums =
	netflow:
		outgoing: 0
		incoming: 1
		both:     2

class Client
	constructor: (id) ->
		@id = id

	getInfo: (key) ->
		info = ref("",@settings.maxInfoLength)
		natives.GetClientInfo(@id,key,info,info.size)
		info.value

	getLatency: (flow) ->
		natives.GetClientLatency(@id, flow)

	getAvgLatency: (flow) ->
		natives.GetClientAvgLatency(@id, flow)

	getAvgLoss: (flow) ->
		natives.GetClientAvgLoss(@id, flow)

	getAvgChoke: (flow) ->
		natives.GetClientAvgChoke(@id, flow)

	getAvgData: (flow) ->
		natives.GetClientAvgData(@id, flow)

	getAvgPackets: (flow) ->
		natives.GetClientAvgPackets(@id, flow)

	kick: (format, rest...) ->
		reffedArgs = ref(v) for v in rest
		natives.KickClient(@id, format, reffedArgs...)

	kickEx: (format, rest...) ->
		reffedArgs = ref(v) for v in rest
		natives.KickClientEx(@id, format, reffedArgs...)

	canTarget: (other) ->
		natives.CanUserTarget(@id, other.id)

	setAdmin: (admin, temp=false) ->
		natives.SetUserAdmin(@id, admin.id, temp)

	settings:
		maxNameLength:       150
		maxAuthStringLength: 150
		maxIPLength:         30
		maxInfoLength:       200
		maxModelLength:      150


Object.defineProperty Client::, "name",
	get: ->
		name = ref("",@settings.maxNameLength)
		natives.GetClientName(@id,name,name.size)
		name.value

Object.defineProperty Client::, "authString",
	get: ->
		auth = ref("",@settings.maxAuthStringLength)
		natives.GetClientAuthString(@id,auth,auth.size)
		auth.value

Object.defineProperty Client::, "ip",
	get: ->
		ip = ref("",@settings.maxIPLength)
		natives.GetClientIP(@id,ip,ip.size,true)
		ip.value

Object.defineProperty Client::, "ipAndPort",
	get: ->
		ip = ref("",@settings.maxIPLength)
		natives.GetClientIP(@id,ip,ip.size,false)
		ip.value

Object.defineProperty Client::, "userId",
	get: ->
		natives.GetClientUserId(@id)

Object.defineProperty Client::, "isConnected",
	get: ->
		natives.IsClientConnected(@id)

Object.defineProperty Client::, "isInGame",
	get: ->
		natives.IsClientInGame(@id)

Object.defineProperty Client::, "isInKickQueue",
	get: ->
		natives.IsClientInKickQueue(@id)

Object.defineProperty Client::, "isAuthorized",
	get: ->
		natives.IsClientAuthorized(@id)

Object.defineProperty Client::, "isFake",
	get: ->
		natives.IsFakeClient(@id)

Object.defineProperty Client::, "isSourceTV",
	get: ->
		natives.IsClientSourceTV(@id)

Object.defineProperty Client::, "isReplay",
	get: ->
		natives.IsClientReplay(@id)

Object.defineProperty Client::, "isObserver",
	get: ->
		natives.IsClientObserver(@id)

Object.defineProperty Client::, "isAlive",
	get: ->
		natives.IsPlayerAlive(@id)

Object.defineProperty Client::, "isTimingOut",
	get: ->
		natives.IsClientTimingOut(@id)

Object.defineProperty Client::, "team",
	get: ->
		teams.findById(natives.GetClientTeam(@id))
	set: (team) ->
		natives.ChangeClientTeam(@id, team.id)

Object.defineProperty Client::, "health",
	get: ->
		natives.GetClientHealth(@id)

Object.defineProperty Client::, "model",
	get: ->
		model = ref("",@settings.maxModelLength)
		natives.GetClientModel(@id, model, model.size)
		model.value

Object.defineProperty Client::, "weapon",
	get: ->
		weapon = ref("",@settings.maxWeaponLength)
		natives.GetClientModel(@id, weapon, weapon.size)
		weapon.value

Object.defineProperty Client::, "maxSize",
	get: ->
		vec = toFloat(ref([],3))
		natives.GetClientModel(@id, vec)
		vec.value

Object.defineProperty Client::, "adminId",
	get: ->
		natives.GetUserAdmin(@id)

interop.flags.defineFlagsProperty Client::, "flags", admModule.flags.access, [],
	->
		natives.GetUserFlagBits(@id)
	,
	(value) ->
		natives.SetUserFlagBits(@id, value)



module = @

@Client = Client

@server = new Client(0)

@findById = (id) ->
	new Client(id)

@findByUserId = (uid) ->
	new CLient(natives.GetClientOfUserId(uid))

Object.defineProperty @, "max",
	get: ->
		natives.GetMaxClients()

Object.defineProperty @, "all",
	get: ->
		new Client(id) for id in [1..module.max]

Object.defineProperty @, "connected",
	get: ->
		client for client in module.all when client.isConnected

Object.defineProperty @, "inGame",
	get: ->
		client for client in module.all when client.isInGame

Object.defineProperty @, "authorized",
	get: ->
		client for client in module.all when client.isAuthorized

Object.defineProperty @, "inGameAndAuthorized",
	get: ->
		client for client in module.all when client.isInGame and client.isAuthorized

Object.defineProperty @, "fake",
	get: ->
		client for client in module.connected when client.isFake

Object.defineProperty @, "real",
	get: ->
		client for client in module.connected when not client.isFake

Object.defineProperty @, "inGameAndFake",
	get: ->
		client for client in module.all when client.isInGame and client.isFake

Object.defineProperty @, "inGameAndReal",
	get: ->
		client for client in module.all when client.isInGame and not client.isFake

Object.defineProperty @, "inGameAuthorizedAndFake",
	get: ->
		client for client in module.all when client.isInGame and client.isAuthorized and client.isFake

Object.defineProperty @, "inGameAuthorizedAndReal",
	get: ->
		client for client in module.all when client.isInGame and client.isAuthorized and not client.isFake

Object.defineProperty @, "alive",
	get: ->
		client for client in module.inGame when client.isAlive

Object.defineProperty @, "count",
	get: ->
		natives.GetClientCount(false)

Object.defineProperty @, "inGameCount",
	get: ->
		natives.GetClientCount(true)

