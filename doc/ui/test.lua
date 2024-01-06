local ui = require "ui"

-- create a simple Window
local win1 = ui.Window("Window1", 400, 300)

local win2 = ui.Window("Window2", 400, 300)

local button = ui.Button(win2, "Click me to bring Window2 to back")
button:center()

win1:show()
win2:show()

-- Button:onClick() event
function button:onClick()
	win2:toback(win1)
end

-- update the user interface until the user closes the Window
repeat
	ui.update()
until not win1.visible