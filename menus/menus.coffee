class Menu
	constructor: ->
		@handle = natives.CreateMenu(generateMenuHandler(@), 0xFFFFFFFF)

	

@create = ->
	natives.CreateMenu(generateMenuHandler(handle))