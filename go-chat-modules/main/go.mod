module tim2.com/main

go 1.17

replace tim.com/chat v0.0.0 => ../chat

require tim.com/chat v0.0.0

replace tim.com/message v0.0.0 => ../message

require tim.com/message v0.0.0 // indirect

replace tim.com/server v0.0.0 => ../server

require tim.com/server v0.0.0
