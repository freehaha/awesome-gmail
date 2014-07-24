#Installation

the threaded version uses lzmq and llthreads2 modules.  You can install them by using luarocks: (might need to sudo depending on your environment)

```sh
luarocks install lua-llthreads2
luarocks install lzmq
```

to install this widget:

```sh
cp -r awesome ~/.config/awesome
```

to include this library put these lines into your rc.lua:

```lua
awful.widget.gmail = require('awful.widget.gmail')
gmailwidget = awful.widget.gmail.new()
```

and then insert 'gmailwidget' into your widget list.

login id and password should be enter in ~/.netrc in the following form:

	machine mail.google.com login <username@gmail.com> password <password>

where ```<username@gmail.com>``` and ```<password>``` should be replace by your own id/pwd

Then, after reloading awesome you should see your gmail widget up and running

right click on it (button 3) to toggle the activity of the widget and left click to opens the browser
which the browser command can be set to global variable ```browser``` or ```firefox``` is used as default browser

