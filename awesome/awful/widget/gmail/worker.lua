-- code for feed processing are borrowed from [vicious](https://github.com/Mic92/vicious)/widgets/gmail
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

function M.go(ctx, timeout)
	local ok, s, err, msg
	local s, err = ctx:socket(zmq.PUSH)
	local sc = ctx:socket(zmq.PULL)

	ok, err = s:connect("inproc://gmail")
	if ok == nil then
		print(err:msg())
	end
	sc:set_rcvtimeo(timeout * 1000)
	ok, err = sc:connect("inproc://gmail_close")

	while true do
		local mail = M.check()
		msg = zmq.msg_init_data(serialize(mail))
		ok, err = s:send_msg(msg)
		if ok == nil then
			print(err:msg())
		end
		msg:close()
		msg, err = sc:recv_new_msg()
		if msg ~= nil or err:no() ~= zmq.EAGAIN then
			return
		end
	end
end

return M
