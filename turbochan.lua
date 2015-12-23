_G.TURBO_SSL = true
local turbo = require "turbo"
local luchia = require "luchia"

local StacheHelper = turbo.web.Mustache.TemplateHelper("./templates/")

local HomeHandler = class("HomeHandler", turbo.web.RequestHandler)
function HomeHandler:get()
	self:write(StacheHelper:render("index.mustache", {["header"] = "Turbochan"}))
end

local BoardHandler = class("BoardHandler", turbo.webRequestHandler)
function BoardHandler:get(site, board)
	
end

turbo.web.Application({
	{"^/$", HomeHandler}, 
	{"^/static/(.*)$", turbo.web.StaticFileHandler, "./static/"},
	{"^/(.+)/?$", BoardHandler}
}):listen(8888)

turbo.ioloop.instance():start()