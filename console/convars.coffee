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
		@queries = []
		@maxStringLength = 500
		@alreadyHooked = false

	dispose: ->
		@unhookAll()
		natives.CloseHandle(@handle)
		# TODO: deal with dangling queries

	startHooks: ->
		natives.HookConVarChange(@handle, @onConVarChanged) unless @alreadyHooked
		@alreadyHooked = true

	endHooks: ->
		natives.UnhookConVarChange(@handle, @onConVarChanged) unless not @alreadyHooked
		@alreadyHooked = false

	callHookedFunctions: (oldValue, newValue) ->
		func(oldValue, newValue) for func in @hooks

	reset: ->
		natives.ResetConVar(@handle, true, true)

	hook: (func) ->
		pos = @hooks.indexOf(func)
		throw new Error("This function is already in the hook chain!") unless pos == -1

		@startHooks() if @hooks.length == 0
		@hooks.push(func)

	unhook: (func) ->
		pos = @hooks.indexOf(func)
		throw new Error("This function is not in the hook chain!") if pos == -1

		@hooks = @hooks.splice(pos,1)
		@endHooks() if @hooks.length == 0

	unhookAll: ->
		@hooks = []
		@endHooks()

	clearMin: ->
		natives.SetConVarBounds(@handle, enums.conVarBounds.lower, false)

	clearMax: ->
		natives.SetConVarBounds(@handle, enums.conVarBounds.upper, false)

	onConVarChanged: (handle, oldValue, newValue) =>
		@callHookedFunctions(oldValue, newValue)

	# Todo: adjust with success and failure
	queryClientValue: (client, callback) ->
		clearQueryCallback = =>
			pos = @queries.indexOf(onConVarQueryFinished)
			@hooks = @hooks.splice(pos,1) unless pos == -1

		onConVarQueryFinished = (ignoredcookie,result,cvarName,cvarValue) =>
			callback(result, cvarValue.value, @, client)
			clearQueryCallback()

		@queries.push(onConVarQueryFinished)

		if natives.QueryClientConVar(client.id, @name, onConVarQueryFinished) == 0
			clearQueryCallback()
			return false
		else
			return true

	sendClientValue: (client, value) ->
		natives.SendConVarValue(client.id, @handle, value)


Object.defineProperty ConVar::, "intValue",
	set: (value) ->
		throw new Error("Integer required for intValue") if typeof(value) != "number"
		natives.SetConVarInt(@handle, Math.floor(value), true, true)
	get: ->
		natives.GetConVarInt(@handle)

Object.defineProperty ConVar::, "floatValue",
	set: (value) ->
		throw new Error("Number required for floatValue") if typeof(value) != "number"
		natives.SetConVarFloat(@handle, asFloat(value), true, true)
	get: ->
		natives.GetConVarFloat(@handle)

Object.defineProperty ConVar::, "stringValue",
	set: (value) ->
		throw new Error("String required for stringValue") if typeof(value) != "string"
		natives.SetConVarString(@handle, value, true, true)
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarString(@handle, ref, @maxStringLength)
		str.value

Object.defineProperty ConVar::, "booleanValue",
	set: (value) ->
		throw new Error("Boolean required for booleanValue") if typeof(value) != "boolean"
		natives.SetConVarBoolean(@handle, value, true, true)
	get: ->
		natives.GetConVarBoolean(@handle)

defineConversionProperty = (conversionName,realProp) ->
	Object.defineProperty ConVar::, conversionName,
		get: ->
			res = Object.create(@)
			Object.defineProperty(res, "value", Object.getOwnPropertyDescriptor(ConVar::, realProp))
			res

defineConversionProperty("asInt", "intValue")
defineConversionProperty("asFloat", "floatValue")
defineConversionProperty("asString", "stringValue")
defineConversionProperty("asBoolean", "booleanValue")

Object.defineProperty ConVar::, "default",
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarDefault(@handle, ref, @maxStringLength)
		str.value

Object.defineProperty ConVar::, "name",
	get: ->
		str = ref("",@maxStringLength)
		natives.GetConVarName(@handle, ref, @maxStringLength)
		str.value

Object.defineProperty ConVar::, "min",
	set: (value) ->
		throw new Error("Number required for min") if typeof(value) != "number"
		natives.SetConVarBounds(@handle, enums.conVarBounds.lower, true, asFloat(value))
	get: ->
		val = ref(0.125)
		isBound = natives.GetConVarBounds(@handle, enums.conVarBounds.lower, ref)
		if isBound then val else null

Object.defineProperty ConVar::, "max",
	set: (value) ->
		throw new Error("Number required for max") if typeof(value) != "number"
		natives.SetConVarBounds(@handle, enums.conVarBounds.upper, true, asFloat(value))
	get: ->
		val = ref(0.125)
		isBound = natives.GetConVarBounds(@handle, enums.conVarBounds.upper, ref)
		if isBound then val else null

interop.flags.defineFlagsProperty ConVar::, "flags", flags.create, ["sponly","plugin"],
	->
		natives.GetConVarFlags(@handle)
	,
	(value) ->
		natives.SetConVarFlags(@handle, value)



@create = (name, defaultValue, options={}) ->
	cvarFlags = interop.flags.options2Flags(options, flags.create, ["sponly","plugin"])

	{description} = options
	description = "" unless description?

	throw new Error("Invalid ConVar name") unless isValidConVarName(name)

	new ConVar(natives.CreateConVar(name,
	                                defaultValue.toString(),
	                                description, options.min?,
	                                toFloat(options.min ? 0),
	                                cvarFlags, options.max?,
	                                toFloat(options.max ? 0)))

@find = (name) ->
	new ConVar(natives.FindConVar(name))

@isValidName = isValidConVarName

Object.defineProperty @, "all",
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

		cmds
