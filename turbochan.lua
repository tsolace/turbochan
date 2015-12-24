_G.TURBO_SSL = true
local turbo = require "turbo"
local yaml = require "yaml"
local socket = require "socket"
local couch = require "helpers/couchdbreq"

local f = assert(io.open(arg[1], "r"))
Config = yaml.load(f:read("*all"))
couch.conf(Config)

local StacheHelper = turbo.web.Mustache.TemplateHelper("./templates/")

local HomeHandler = class("HomeHandler", turbo.web.RequestHandler)
function HomeHandler:get()
	local resp = couch.get("_design/get/_view/by_ts", {include_docs = true, descending = true, limit = 10})
	if resp.status_code ~= 200 then
		self:write("<p>Error! Couldn't access CouchDB with code "..resp.status_code.."</p>")
		return
	end
	local presp = resp.json()
	local posts = {}
	for rowcount = 1, #presp.rows do table.insert(posts, presp.rows[rowcount].doc) end
	self:write(StacheHelper:render("index.mustache", {["header"] = "Turbochan", ["time"] = socket.gettime(), posts = posts}))
end

local BoardpageHandler = class("BoardpageHandler", turbo.web.RequestHandler)
function BoardpageHandler:get(board)
	local resp = couch.get("_design/get/_view/by_board", {include_docs = true, descending = true, key = "\""..board.."\""})
	if resp.status_code ~= 200 then
		self:write("<p>Error! Couldn't access CouchDB with code "..resp.status_code.."</p>")
		return
	end
	local presp = resp.json()
	local posts = {}
	for rowcount = 1, #presp.rows do table.insert(posts, presp.rows[rowcount].doc) end
	self:write(StacheHelper:render("board.mustache", {board = board, posts = posts}))
end

local PostHandler = class("PostHandler", turbo.web.RequestHandler)
function PostHandler:post(pboard)
	local psubject = self:get_argument("subject", "No subject")
	local pbody    = self:get_argument("body")
	local pauthor  = self:get_argument("author", "Anonymous")
	local resp = couch.get("_design/get/_view/by_board", {limit = 1, descending = true, key = "\""..pboard.."\""})
	if resp.status_code ~= 200 then
		self:write("<p>Error! Couldn't access CouchDB with code "..resp.status_code.."</p>")
		return
	end
	psid = resp.json()
	if #psid.rows == 0 then fpid = 1 else fpid = psid.rows[1].value + 1 end
	local ptable = {subject = psubject, author = pauthor, body = pbody, board = pboard, pid = fpid, ts = socket.gettime() }
	local resp = couch.put(couch.uuid(), turbo.escape.json_encode(ptable))
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
}):listen(Config.httpport)

turbo.ioloop.instance():start()