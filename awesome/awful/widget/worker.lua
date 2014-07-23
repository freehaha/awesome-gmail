local timer = require "lzmq.timer"
local zmq = require "lzmq"
local M = {}

local rss = {
  inbox   = {
    "https://mail.google.com/mail/feed/atom",
    "Gmail %- Inbox"
  },
}
local feed = rss.inbox
local mail = {
    ["{count}"]   = 0,
    ["{subject}"] = "N/A"
}

function M.check()
    local f = io.popen("curl --connect-timeout 1 -m 3 -fsn " .. feed[1])

	mail["{subject}"] = "N/A"
    -- Could be huge don't read it all at once, info we are after is at the top
    for line in f:lines() do
        mail["{count}"] = -- Count comes before messages and matches at least 0
          tonumber(string.match(line, "<fullcount>([%d]+)</fullcount>")) or mail["{count}"]

        -- Find subject tags
		for title in string.gmatch(line, "<title>([^<]*)</title>") do
			-- If the subject changed then break out of the loop
			if title ~= nil and not string.find(title, feed[2]) then
				-- Spam sanitize the subject and store
				mail["{subject}"] = title
				break
			end
		end
		if mail["{subject}"] ~= "N/A" then
			break
		end
    end
    f:close()
	return mail
end

function serialize(mail)
	return mail["{count}"] .. "|" .. mail["{subject}"]
end

function M.go(ctx)
	s, err = ctx:socket(zmq.PUSH)
	s:connect("inproc://#gmail")
	local msg
	while true do
		local mail = M.check()
		msg = zmq.msg_init_data(serialize(mail))
		s:send_msg(msg)
		msg:close()
		timer.sleep(30000)
	end
end

return M
