interop = require("sourcemod/interop")
flags = require("flags")

natives.declare("CreateConVar")
natives.declare("FindConVar")
natives.declare("HookConVarChange")
natives.declare("UnhookConVarChange")
natives.declare("GetConVarBool",types.bool)
natives.declare("SetConVarBool")
natives.declare("GetConVarInt")
natives.declare("SetConVarInt")
natives.declare("GetConVarFloat",types.float)
natives.declare("SetConVarFloat")
natives.declare("GetConVarString")
natives.declare("SetConVarString")
natives.declare("ResetConVar")
natives.declare("GetConVarDefault")
natives.declare("GetConVarFlags")
natives.declare("SetConVarFlags")
natives.declare("GetConVarBounds",types.bool)
natives.declare("SetConVarBounds")
natives.declare("GetConVarName")
natives.declare("QueryClientConVar")
natives.declare("SendConVarValue")
natives.declare("FindFirstConCommand")
natives.declare("FindNextConCommand",types.bool)

enums =
	conVarBounds:
		upper : 0
		lower : 1

isValidConVarName = (name) ->
	/^[a-zA-Z0-9_]+$/.test(name)

# Convar prototype
class ConVar
	constructor: (handle) ->
		@handle = handle
		@hooks = []
		@maxStringLength = 500
		@alreadyHooked = false

		# I make this local to this closure so we can access the convar object without 
		# having to track handles (well, we're still tracking it, but now the GC does it for us)
		self = @
		onConVarChanged = (handle, oldValue, newValue) ->
			self.callHookedFunctions(oldValue,newValue)
		@startHooks = ->
			natives.HookConVarChange(@handle, onConVarChanged) unless @alreadyHooked
			@alreadyHooked = true

	callHookedFunctions: (oldValue, newValue) ->
		func(oldValue, newValue) for func in @hooks

	reset: ->
		natives.ResetConVar(@handle, true, true)

	hook: (func) ->
		pos = @hooks.indexOf(func)
		throw "This function is already in the hook chain!" unless pos == -1

		@hooks.push(func)
		@startHooks()

	unhook: (func) ->
		pos = @hooks.indexOf(func)
		throw "This function is not in the hook chain!" if pos == -1

		@hooks = @hooks.splice(pos,1)

	clearMin: ->
		natives.SetConVarBounds(@handle, enums.conVarBounds.lower, false)

	clearMax: ->
		natives.SetConVarBounds(@handle, enums.conVarBounds.upper, false)

	# Todo: adjust with success and failure
	queryClientValue: (client, callback) ->
		self = @
		onConVarQueryFinished = (cookie,result,cvarName,cvarValue) ->
			callback(result, cvarValue.value, self, client)
		
		natives.QueryClientConVar(client.id, @name, onConVarQueryFinished)

	sendClientValue: (client, value) ->
		natives.SendConVarValue(client.id, @handle, value)


Object.defineProperty(ConVar::, "asInt", 
	set: (value) ->
		throw "Integer required for asInt" if typeof(value) != "number"
		natives.SetConVarInt(@handle, Math.floor(value), true, true)
	get: ->
		natives.GetConVarInt(@handle))

Object.defineProperty(ConVar::, "asFloat", 
	set: (value) ->
		throw "Number required for asFloat" if typeof(value) != "number"
		natives.SetConVarFloat(@handle, asFloat(value), true, true)
	get: ->
		natives.GetConVarFloat(@handle))

Object.defineProperty(ConVar::, "asString", 
	set: (value) ->
		throw "String required for asString" if typeof(value) != "string"
		natives.SetConVarString(@handle, value, true, true)
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarString(@handle, ref, @maxStringLength)
		str.value)

Object.defineProperty(ConVar::, "asBoolean", 
	set: (value) ->
		throw "Boolean required for asBoolean" if typeof(value) != "boolean"
		natives.SetConVarBoolean(@handle, value, true, true)
	get: ->
		natives.GetConVarBoolean(@handle))	

Object.defineProperty(ConVar::, "default",
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarDefault(@handle, ref, @maxStringLength)
		str.value)

Object.defineProperty(ConVar::, "name",
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarName(@handle, ref, @maxStringLength)
		str.value)

Object.defineProperty(ConVar::, "min",
	set: (value) ->
		throw "Number required for min" if typeof(value) != "number"
		natives.SetConVarBounds(@handle, enums.conVarBounds.lower, true, asFloat(value))
	get: ->
		val = ref(0.125)
		isBound = natives.GetConVarBounds(@handle, enums.conVarBounds.lower, ref)
		if isBound then val else null)

Object.defineProperty(ConVar::, "max",
	set: (value) ->
		throw "Number required for max" if typeof(value) != "number"
		natives.SetConVarBounds(@handle, enums.conVarBounds.upper, true, asFloat(value))
	get: ->
		val = ref(0.125)
		isBound = natives.GetConVarBounds(@handle, enums.conVarBounds.upper, ref)
		if isBound then val else null)

interop.flags.defineFlagsProperty(ConVar::, "flags", flags.create, ["sponly","plugin"],
	->
		natives.GetConVarFlags(@handle)
	,
	(value) ->
		natives.SetConVarFlags(@handle, value)
	)


@create = (name, defaultValue, options={}) ->
	cvarFlags = interop.flags.options2Flags(options, flags.create, ["sponly","plugin"])

	{description} = options
	description = "" unless description?

	throw "Invalid ConVar name" unless isValidConVarName(name)

	new ConVar(natives.CreateConVar(name, defaultValue.toString(), description, options.min?, toFloat(options.min ? 0), cvarFlags, options.max?, toFloat(options.max ? 0)))

@find = (name) ->
	new ConVar(natives.FindConVar(name))

@isValidName = isValidConVarName

Object.defineProperty(@, "all",
	get: ->
		name = ref("",100)
		eflags = ref(0)
		desc = ref("",300)
		isCommand = ref(false)

		cmds = []

		i = natives.FindFirstConCommand(name, name.size, isCommand, eflags, description, description.size)
		return [] if i == interop.handles.invalid

		cmds.push(new ConCommand(name.value, description.value)) unless isCommand.value

		while FindNextConCommand(i, name, name.size, isCommand, eflags, desc, desc.size)
			cmds.push(new ConCommand(name.value, description.value)) unless isCommand.value

		natives.CloseHandle(i)

		cmds)
