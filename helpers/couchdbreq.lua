local couch = {}
local requests = require "requests"

function couch.conf(cnf)
	Config = cnf
end

function couch.get(reqpath, reqparams)
	if Config.couch.auth == true then
		local auth = requests.HTTPBasicAuth(Config.couch.user, Config.couch.pass)
		return requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {auth = auth, params = reqparams})
	else
		return requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {params = reqparams})
	end
end

function couch.put(reqpath, reqdata)
	if Config.couch.auth == true then
		local auth = requests.HTTPBasicAuth(Config.couch.user, Config.couch.pass)
		return requests.put("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {auth = auth, data = reqdata})
	else
		return requests.put("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {data = reqdata})
	end
end

function couch.uuid()
	local resp = requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/_uuids")
	local uuids = resp.json()
	return uuids.uuids[1]
end

return couch