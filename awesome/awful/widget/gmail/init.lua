local awful = require('awful')
local wibox = require("wibox")
local naughty = require('naughty')
local capi = { timer = timer }

local zmq = require "lzmq"
local zthread = require "lzmq.threads"
local timer;

local M = {}


local function stopThread(gmail)
	local msg = zmq.msg_init_data("")
	gmail.sc:send_msg(msg, zmq.DONTWAIT)
	gmail.tm:stop()
	msg:close()
end

local function startThread(options, gmail)
	gmail.tm:start()
	zthread.run(gmail.ctx, function(paths, timeout)
		local ctx = require "lzmq.threads".context()
		package.path = paths
		require("awful.widget.gmail.worker").go(ctx, timeout)
	end, package.path, options.timeout):start(true, true)
end

-- http://lua-users.org/wiki/SplitJoin
local function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

local function deserialize(string)
	local mail = {}
	args = split(string, "|", 2)
	mail["{count}"] = tonumber(args[1])
	mail["{subject}"] = args[2]
	return mail
end

function M.new(options)
	options = options or {}
	options.timeout = options.timeout or 30
	options.half = options.timeout / 2
	if options.half < 1 then
		options.half = 1
	end

	local gmail = {}
	gmail.ctx = zmq.context({io_threads = 1, max_sockets = 10})
	gmail.s, err = gmail.ctx:socket(zmq.PULL)
	gmail.sc, err = gmail.ctx:socket(zmq.PUSH)
	local ok, err = gmail.s:bind("inproc://gmail")
	gmail.sc:bind("inproc://gmail_close")
	if ok == nil then
		naughty.notify({
			text = "PANIC",
			title = "GMail",
			timeout = 5
		})
	end

	gmail.widget = wibox.widget.imagebox()
	gmail.image = {
		["disabled"] = awful.util.getdir("config") .. "/awful/widget/icons/mail-disabled.png",
		["active"] = awful.util.getdir("config") .. "/awful/widget/icons/mail.png",
		["new"] = awful.util.getdir("config") .. "/awful/widget/icons/mail-new.png",
	}
	gmail.widget:set_image(gmail.image['active'])

	gmail.enabled = true
	gmail.args = { ["{count}"] = 0 }
	gmail.widget:buttons(awful.util.table.join(
		awful.button({ }, 1, function ()
			local browser = browser or "firefox"
			awful.util.spawn(browser .. " https://mail.google.com")
			gmail.widget:set_image(gmail.image['active'])
			gmail.args["{count}"] = 0
		end),
		awful.button({}, 3, function ()
			if gmail.enabled then
				gmail.widget:set_image(gmail.image['disabled'])
				stopThread(gmail)
			else
				gmail.widget:set_image(gmail.image['active'])
				startThread(options, gmail)
			end
			gmail.enabled = not gmail.enabled
		end)
	))

	gmail.notify = nil
	gmail.widget:connect_signal("mouse::enter",
	function()
		local popuptext = ""
		if gmail.args["{count}"] > 0 then
			popuptext = gmail.args["{count}"] .. " unread mails."
		else
			popuptext = "no unread mail"
		end
		if gmail.notify then
			naughty.destroy(gmail.notify)
		end
		gmail.notify = naughty.notify({
			text = popuptext,
			title = "Mail",
			timeout = 0
		})
	end)
	gmail.widget:connect_signal("mouse::leave", 
	function ()
		if gmail.notify then
			naughty.destroy(gmail.notify)
			gmail.notify = nil
		end
	end)

	function update()
		local msg, err = gmail.s:recv_new_msg(zmq.DONTWAIT)
		local last_msg = nil
		local mail
		while msg ~= nil do
			if last_msg ~= nil then
				last_msg:close()
			end
			last_msg = msg
			msg, err = gmail.s:recv_new_msg(zmq.DONTWAIT)
		end
		if err:no() ~= zmq.EAGAIN then
			-- TODO: panic
			naughty.notify({
				text = "PANIC",
				title = "Gmail",
				timeout = 5
			})
			return
		end
		if last_msg ~= nil then
			mail = deserialize(last_msg:data())
			last_msg:close()
		else
			return
		end
		if mail["{count}"] > 0 then
			gmail.widget:set_image(gmail.image['new'])
		else
			gmail.widget:set_image(gmail.image['active'])
		end
		if mail["{count}"] > gmail.args["{count}"] then
			naughty.notify({
				text = "new mail: " .. mail["{subject}"] .. "\nand " .. (mail["{count}"]-1) .. " more...",
				title = "New Mail",
				timeout = 5
			})
		end
		gmail.args["{count}"] = mail["{count}"]
		gmail.args["{subject}"] = mail["{subject}"]
	end

	-- register a timer
	gmail.tm = capi.timer({ timeout = options.half })
	if gmail.tm.connect_signal then
		gmail.tm:connect_signal("timeout", update)
	else
		gmail.tm:add_signal("timeout", update)
	end

	-- notify the worker thread to terminate when exiting awesome
	awesome.connect_signal("exit", function(restart)
		stopThread(gmail)
		gmail.sc:close()
		gmail.s:close()
	end)

	startThread(options, gmail)
	return gmail.widget
end

return M
