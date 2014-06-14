interop = require("sourcemod/interop")
flags = require("flags")
enums = require("enums")
groups = require("groups")

natives.declare("CreateAdmin")
natives.declare("GetAdminUsername")
natives.declare("BindAdminIdentity",types.bool)
natives.declare("SetAdminFlag")
natives.declare("GetAdminFlag")
natives.declare("GetAdminFlags")
natives.declare("AdminInheritGroup")
natives.declare("GetAdminGroupCount")
natives.declare("GetAdminGroup")
natives.declare("SetAdminPassword")
natives.declare("GetAdminPassword")
natives.declare("FindAdminByIdentity")
natives.declare("RemoveAdmin")

class Admin
	constructor: (id) ->
		@id = id

	bindIdentity: (authmethod, ident) ->
		natives.BindAdminIdentity(@id, authmethod.id, ident)

	addGroup: (group) ->
		natives.AdminInheritGroup(@id, group.id)

	canTarget: (target) ->
		natives.CanAdminTarget(@id, target)

	settings:
		maxUsernameLength: 64
		maxPasswordLength: 100
		maxAdminGroupNameLength: 200

Object.defineProperty Admin::, "username",
	get: ->
		res = ref("",@settings.maxUsernameLength)
		natives.GetAdminUsername(@id, res, res.size)
		res.value

Object.defineProperty Admin::, "groups",
	get: ->
		res = {}
		for i in [0...natives.GetAdminGroupCount(@id)]
			name = ref("",@settings.maxAdminGroupNameLength)
			g = natives.GetAdminGroup(@id, i, name, name.size)
			res[name.value] = groups.findById(g)
		res

Object.defineProperty Admin::, "password",
	get: ->
		res = ref("",@settings.maxPasswordLength)
		natives.GetAdminPassword(@id, res, res.size)
		res.value
	set: (value) ->
		natives.SetAdminPassword(@id, value)

Object.defineProperty Admin::, "immunity",
	get: ->
		natives.GetAdminImmunityLevel(@id)
	set: (value) ->
		natives.SetAdminImmunityLevel(@id, value)

interop.flags.defineFlagsProperty Admin::, "flags", flags.access, [],
	->
		natives.GetAdminFlags(@id)
	,
	(value) ->
		options = interop.flags.flags2Options(value, flags.access)
		for own k, v of options
			natives.SetAdminFlag(@id, enums.access[k], !!v)



@create = (name) ->
	new Admin(natives.CreateAdmin(name))

@findById = (id) ->
	if id != -1 then new Admin(id) else null

@findByIdentity = (authmethod, ident) ->
	id = natives.FindAdminByIdentity(authmethod.id, ident)

@remove = (admin) ->
	natives.RemoveAdmin(admin.id)