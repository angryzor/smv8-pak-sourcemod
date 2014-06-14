flags = require("flags")

natives.declare("CreateAdmGroup")
natives.declare("FindAdmGroup")
natives.declare("SetAdmGroupAddFlag")
natives.declare("GetAdmGroupAddFlag")
natives.declare("GetAdmGroupAddFlags")
natives.declare("SetAdmGroupImmuneFrom")
natives.declare("GetAdmGroupImmuneCount")
natives.declare("GetAdmGroupImmuneFrom")
natives.declare("AddAdmGroupCmdOverride")
natives.declare("GetAdmGroupCmdOverride",types.bool)
natives.declare("SetAdmGroupImmunityLevel")
natives.declare("GetAdmGroupImmunityLevel")

class Group
	constructor: (id) ->
		@id = id

	setImmuneFrom: (other) ->
		natives.SetAdmGroupImmuneFrom(@id, other.id)

###
	addCmdOverride: (name, type, rule) ->
		natives.AddAdmGroupCmdOverride(@id, name, type, rule)

	getCmdOverride: (name, type) ->
		rule = ref(0)
		hasOverride = natives.GetAdmGroupCmdOverride(@id, name, type, rule)
		if hasOverride then rule.value else null
###

Object.defineProperty Group::, "immunity",
	get: ->
		natives.GetAdmGroupImmunityLevel(@id)
	set: (value) ->
		natives.SetAdmGroupImmunityLevel(@id, value)

Object.defineProperty Group::, "immuneFromGroups",
	get: ->
		gicount = natives.GetAdmGroupImmuneCount(@id)
		new Group(natives.GetAdmGroupImmuneFrom(@id,i)) for i in [0...gicount]


interop.flags.defineFlagsProperty Group::, "flags", flags.access, [],
	->
		natives.GetAdmGroupAddFlags(@id)
	,
	(value) ->
		options = interop.flags.flags2Options(value, flags.access)
		for own k, v of options
			natives.SetAdmGroupAddFlag(@id, enums.access[k], !!v)


@create = (name) ->
	new Group(natives.CreateAdmGroup(name))

@findById = (id) ->
	if gid != -1 then	new Group(id) else null

@findByName = (name) ->
	gid = natives.FindAdmGroup(name)
	if gid != -1 then new Group(gid) else null