declare("ServerCommand")
declare("ServerCommandEx")
declare("InsertServerCommand")
declare("ServerExecute")
declare("PrintToServer")
declare("AddServerTag")
declare("RemoveServerTag")

@exec = (format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.ServerCommand(format,reffedArgs...)

@execResult = (format, rest...) ->
	res = ref("",500)
	reffedArgs = ref(v) for v in rest
	natives.ServerCommandEx(res,res.size,format,reffedArgs...)
	res.value

@insert = (format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.InsertServerCommand(format,reffedArgs...)

@flush = ->
	natives.ServerExecute()

@print = (format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.PrintToServer(format,reffedArgs...)

@addTag = (tag) ->
	natives.AddServerTag(tag)

@removeTag = (tag) ->
	natives.RemoveServerTag(tag)
