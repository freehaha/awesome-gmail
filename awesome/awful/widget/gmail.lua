local awful = require('awful')
local wibox = require("wibox")
local vicious = require('vicious')
local naughty = require('naughty')
local M = {}
function M.new(args)
	local gmail = {}
	gmail.widget = wibox.widget.imagebox()
	gmail.image = {
		["disabled"] = awful.util.getdir("config") .. "/awful/widget/icons/mail-disabled.png",
		["active"] = awful.util.getdir("config") .. "/awful/widget/icons/mail.png",
		["new"] = awful.util.getdir("config") .. "/awful/widget/icons/mail-new.png",
	}
	gmail.widget.image = gmail.image['active']

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
				vicious.unregister(gmail.widget, true)
			else
				gmail.widget:set_image(gmail.image['active'])
				vicious.activate(gmail.widget)
			end
			gmail.enabled = not gmail.enabled
		end)
	))

	gmail.notify = nil
	gmail.widget:add_signal("mouse::enter",
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
	gmail.widget:add_signal("mouse::leave", 
	function ()
		if gmail.notify then
			naughty.destroy(gmail.notify)
			gmail.notify = nil
		end
	end)
	vicious.register(gmail.widget, vicious.widgets.gmail,
	function(widget, args)
		if args["{count}"] > 0 then
			widget:set_image(gmail.image['new'])
		else
			widget:set_image(gmail.image['active'])
		end
		if args["{count}"] > gmail.args["{count}"] then
			naughty.notify({
				text = "new mail: " .. args["{subject}"] .. "\nand " .. (args["{count}"]-1) .. " more...",
				title = "New Mail",
				timeout = 5
			})
		end
		gmail.args["{count}"] = args["{count}"]
		gmail.args["{subject}"] = args["{subject}"]
		return args
	end
	, 240)

	return gmail.widget
end

return M
