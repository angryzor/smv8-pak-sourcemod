#requireExt("SDKTools","sdktools.ext",true,true)

natives.declare("GetTeamName")
natives.declare("GetTeamCount")

class Team
	constructor: (id) ->
		@id = id

	equals: (other) ->
		@id == other.id

	settings:
		maxTeamNameLength: 40

Object.defineProperty(Team::,"name",
	get: ->
		name = ref("",@settings.maxTeamNameLength)
		natives.GetTeamName(@id, name, name.size)
		name.value)

module = @

@findById = (id) ->
	new Team(id)

Object.defineProperty(@,"count",
	get: ->
		natives.GetTeamCount())

Object.defineProperty(@,"all",
	get: ->
		new Team(id) for id in [0...4])
