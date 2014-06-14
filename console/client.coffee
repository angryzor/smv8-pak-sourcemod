declare("ClientCommand")
declare("FakeClientCommand")
declare("FakeClientCommandEx")
declare("PrintToConsole")
declare("ShowActivity")
declare("ShowActivityEx")
declare("ShowActivity2")
declare("FormatActivitySource")

@exec = (client, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.ClientCommand(client.id, format, reffedArgs...)

@execFake = (client, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.FakeClientCommand(client.id, format, reffedArgs...)

@execFakeDelayed = (client, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.FakeClientCommandEx(client.id, format, reffedArgs...)

@print = (format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.PrintToConsole(format, reffedArgs...)

@showActivity = (client, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.ShowActivity(client.id, format, reffedArgs...)

@showActivityEx = (client, tag, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.ShowActivityEx(client.id, tag, format, reffedArgs...)

@showActivity2 = (client, tag, format, rest...) ->
	reffedArgs = ref(v) for v in rest
	natives.ShowActivity2(client.id, tag, format, reffedArgs...)

@formatActivitySource = (client, target) ->
	res = ref("",150)
	natives.FormatActivitySource(client.id, target.id, res, res.size)
	res.value

