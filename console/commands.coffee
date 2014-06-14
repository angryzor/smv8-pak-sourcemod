interop = require("sourcemod/interop")
ccmdflags = require("flags")
adminflags = require("sourcemod/admin/flags")
log = require("sourcemod/log")
clients = require("sourcemod/clients")

natives.declare("ReplyToCommand")
natives.declare("GetCmdReplySource")
natives.declare("SetCmdReplySource")
natives.declare("RegServerCmd")
natives.declare("RegConsoleCmd")
natives.declare("RegAdminCmd")
natives.declare("GetCmdArgs")
natives.declare("GetCmdArg")
# natives.declare("GetCmdArgString") -- Not used atm.
natives.declare("GetCommandIterator")
natives.declare("ReadCommandIterator",types.bool)
natives.declare("CheckCommandAccess")
natives.declare("CheckAccess")
natives.declare("GetCommandFlags")
natives.declare("SetCommandFlags")
natives.declare("FindFirstConCommand")
natives.declare("FindNextConCommand",types.bool)
natives.declare("AddServerTag")
natives.declare("RemoveServerTag")
natives.declare("AddCommandListener")
natives.declare("RemoveCommandListener")

@enums =
	console: 0
	chat:    1

class ConCommand
	conCmdCallbacks = []

	constructor: (name, description="") ->
		@name = name
		@description = description
		@cmdListeners = []

	register: (callback, options={}) ->
		flags = interop.flags.options2Flags(options,ccmdflags.create,[])

		{@description,access,group} = options
		@description = "" unless @description?

		wrappedcb = (client, args) =>
			callback(new ConCommandCall(@, clients.findById(client), args))
		conCmdCallbacks.push(wrappedcb)

		if access?
			admFlags = interop.flags.options2Flags(access,adminflags.access,[])
			natives.RegAdminCmd(@name, wrappedcb, admFlags, @description, group ? "", flags)
		else
			natives.RegConsoleCmd(@name, wrappedcb, @description, flags)

	registerServer: (callback, options={}) ->
		flags = interop.flags.options2Flags(options,ccmdflags.create,[])

		{@description} = options
		@description = "" unless @description?

		wrappedcb = (args) =>
			callback(new ConCommandCall(@, null, args))
		conCmdCallbacks.push(wrappedcb)

		natives.RegServerCmd(@name, wrappedcb, @description, flags)

	checkCommandAccess: (client,options) ->
		flags = interop.flags.options2Flags(options,adminflags.access,[])
		{override_only} = options
		override_only ?= false

		natives.CheckCommandAccess(client.id, @name, flags, override_only)

	checkAccess: (adminid,options) ->
		flags = interop.flags.options2Flags(options,adminflags.access,[])
		{override_only} = options
		override_only ?= false

		natives.CheckAccess(adminid, @name, flags, override_only)

	addListener: (callback) ->
		wrappedcb = (client,command,args) =>
			callback(new ConCommandCall(@, clients.findById(client), args))
		@cmdListeners.push({cb:callback, wcb:wrappedcb})

		natives.AddCommandListener(wrappedcb)

	removeListener: (callback) ->
		i = 0
		for i in [0...cmdListeners.length]
			if cmdListeners[i].cb == callback
				natives.RemoveCommandListener(cmdListeners[i].wcb)
				cmdListeners.splice(i,1)
				return true
		return false


interop.flags.defineFlagsProperty(ConCommand::, "flags", ccmdflags.create, ["sponly","plugin"],
	->
		natives.GetCommandFlags(@name)
	,
	(value) ->
		natives.SetCommandFlags(@name, value)
	)


class ConCommandCall
	constructor: (command,sender,argCount) ->
		@command = command
		@sender = sender
		@args = []

		for i in [0..argCount]
			arg = ref("",200)
			natives.GetCmdArg(i,arg,arg.size)
			@args[i] = arg.value

	reply: (format, rest...) ->
		natives.ReplyToCommand(@sender.id, format, rest...)


@link = (name) ->
	new ConCommand(name)

Object.defineProperty @, "replySource",
	set: (src) ->
		natives.SetCmdReplySource(src)

	get: ->
		natives.GetCmdReplySource()

Object.defineProperty @, "sourcemod",
	get: ->
		i = natives.GetCommandIterator()

		name = ref("",100)
		eflags = ref(0)
		desc = ref("",300)

		cmds = (while ReadCommandIterator(i, name, name.size, eflags, desc, desc.size)
			new ConCommand(name.value, description.value))

		natives.CloseHandle(i)

		cmds

Object.defineProperty @, "all",
	get: ->
		name = ref("",100)
		eflags = ref(0)
		desc = ref("",300)
		isCommand = ref(false)

		cmds = []

		i = natives.FindFirstConCommand(name, name.size, isCommand, eflags, description, description.size)
		return [] if i == interop.handles.invalid

		cmds.push(new ConCommand(name.value, description.value)) if isCommand.value

		while FindNextConCommand(i, name, name.size, isCommand, eflags, desc, desc.size)
			cmds.push(new ConCommand(name.value, description.value)) if isCommand.value

		natives.CloseHandle(i)

		cmds
