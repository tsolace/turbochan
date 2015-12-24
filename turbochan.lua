_G.TURBO_SSL = true
local turbo = require "turbo"
local yaml = require "yaml"
local socket = require "socket"
local requests = require "requests"

local f = assert(io.open(arg[1], "r"))
Config = yaml.load(f:read("*all"))

local function couchreq(reqpath, reqparams)
	if Config.couch.auth == true then
		local auth = requests.HTTPBasicAuth(Config.couch.user, Config.couch.pass)
		return requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {auth = auth, params = reqparams})
	else
		return requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {params = reqparams})
	end
end

local function couchput(reqpath, reqdata)
	if Config.couch.auth == true then
		local auth = requests.HTTPBasicAuth(Config.couch.user, Config.couch.pass)
		return requests.put("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {auth = auth, data = reqdata})
	else
		return requests.put("http://"..Config.couch.host..":"..Config.couch.port.."/"..Config.couch.base.."/"..reqpath, {data = reqdata})
	end
end

local function couchuuid()
	local resp = requests.get("http://"..Config.couch.host..":"..Config.couch.port.."/_uuids")
	local uuids = resp.json()
	return uuids.uuids[1]
end

local StacheHelper = turbo.web.Mustache.TemplateHelper("./templates/")

local HomeHandler = class("HomeHandler", turbo.web.RequestHandler)
function HomeHandler:get()
	local resp = couchreq("_design/get/_view/by_post", {include_docs = true, descending = true, limit = 4})
	local presp = resp.json()
	local posts = {}
	for rowcount = 1, #presp.rows do table.insert(posts, presp.rows[rowcount].doc) end
	self:write(StacheHelper:render("index.mustache", {["header"] = "Turbochan", ["time"] = socket.gettime(), posts = posts}))
end

local BoardpageHandler = class("BoardpageHandler", turbo.web.RequestHandler)
function BoardpageHandler:get(board)
	self:write(StacheHelper:render("board.mustache", {["board"] = board}))
end

local PostHandler = class("PostHandler", turbo.web.RequestHandler)
function PostHandler:post(pboard)
	local psubject = self:get_argument("subject", "No subject")
	local pbody    = self:get_argument("body", "No body")
	local pauthor  = self:get_argument("author", "Anonymous")
	local resp = couchreq("_design/get/_view/by_post", {limit = 1, descending = true})
	if resp.status_code ~= 200 then
		self:write("<p>Error! Couldn't access CouchDB with code "..resp.status_code.."</p>")
		return
	end
	psid = resp.json()
	local ptable = {subject = psubject, author = pauthor, body = pbody, board = pboard, pid = psid.rows[1].key + 1, ts = socket.gettime() }
	local resp = couchput(couchuuid(), turbo.escape.json_encode(ptable))
	if resp.status_code ~= 201 then
		self:write("<p>Error! Couldn't write to CouchDB with code "..resp.status_code.."</p>")
		return
	end
	self:write("<p>Post to board /"..pboard.."/ successful!</p>")
end

local DebugHandler = class("DebugHandler", turbo.web.RequestHandler)
function DebugHandler:get()
	self:write("Base: " .. Config.couch.base .. "<br>")
end

turbo.web.Application({
	{"^/$", HomeHandler}, 
	{"^/static/(.*)$", turbo.web.StaticFileHandler, "./static/"},
	{"^/debug$", DebugHandler}, 
	{"^/post/([^/]-)$", PostHandler},
	{"^/([^/]-)/?$", BoardpageHandler}
}):listen(8888)

turbo.ioloop.instance():start()