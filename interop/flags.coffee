decideFlagValue = (options,defaults,flag) ->
	if options[flag]? then options[flag] else defaults.indexOf(flag) != -1

@options2Flags = (options,flagdefs,defaults) ->
	flags = 0
	flags |= value if decideFlagValue(options,defaults,flag) for flag, value of flagdefs
	flags

@flags2Options = (flags,flagdefs) ->
	options = {}
	options[flag] = !!(flags & value) for flag, value of flagdefs


flags2SettingOptions = (flagdefs,self,getter,setter) ->
	options = {}
	Object.defineProperty(options,flag,
		set: (v) ->
			throw new Error("Only booleans allowed for flags, type of value passed is #{typeof(value)}") if typeof(v) != "boolean"
			flags = getter.call(self)
			setter.call(self, if v then flags | value else flags & ~value)
		get: ->
			!!(getter.call(self) & value)
	) for flag, value of flagdefs


@defineFlagsProperty = (obj,name,flagdefs,defaults,getter,setter) ->
	Object.defineProperty obj, name,
		set: (v) ->
			throw new Error("Needs flag options object") if typeof(v) != "object"
			setter.call(this,options2Flags(v,flagdefs,defaults))
		get: ->
			flags2SettingOptions(flagdefs,this,getter,setter)
