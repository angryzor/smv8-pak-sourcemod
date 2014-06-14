class AuthMethod
	constructor: (id) ->
		@id = id

@create = (name) ->
	natives.CreateAuthMethod(name) and new AuthMethod(name) or null

@findById = (name) ->
	new AuthMethod(name)

@steam = new AuthMethod("steam")
@ip = new AuthMethod("ip")
@name = new AuthMethod("name")