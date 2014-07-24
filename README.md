#Installation

use the widget, you'll need [vicious](https://github.com/Mic92/vicious) installed.

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


#Threaded version
Some of you might have noticed the blocking behavior of this widget. It is because vicious's gmail widget blocks
the thread when executing curl and when you're having a bad connection this effect magnifies.

I tried different ways to solve this problem and ended up using a threaded environment, which might be an overkill but I figured
that I might also use this later on so I went for it anyway.  For those who are interested you can checkout the branch threaded.
You will be able to notice the much faster bootstrapping of awesome because it no longer blocks.

Using [bashets](http://awesome.naquadah.org/wiki/Bashets) is another option because it support asynchronous execution of scripts
but the fact that it cannot turn on/off the activity of a single widgets made me take a step back.

Anyway, if you have any thoughs on this you're welcome to send pull requests or suggestions to me.
