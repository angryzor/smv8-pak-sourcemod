natives.declare("LogMessage")

@log = (format,rest...) ->
	throw "String required" unless typeof(format) == "string"
	fixedrest = (ref(i) for i in rest)
	natives.LogMessage(format,fixedrest...)
