console helpfulness

need to make things work with rails console, and async mode.

Okay...

detect where we are... am I running the server, or the console... if console then I do a post to server

after-commit/change-or-destroy/model/id



execute `rubycon` to bring up console in a new window

uses <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/0.11.7/js/jquery.terminal.min.js"></script>

<link href="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/0.11.7/css/jquery.terminal.min.css" rel="stylesheet"/>

the rubycon function will bring up a new browser window running the terminal emulator.

the rubycon function will intercept all console.log/warn/error function calls and send them to the server, the server will push these out

As each line is typed it is passed to the opal compiler

once the compiler can parse the input it will be compiled to JS, and sent the server

the server will then push using a dedicated debug channel out to the browser window.

any result will be be sent back to the console.

get new-console/clientid  

post client-to-console/clientid log-message
post console-to-client/clientid js-code-string
post console-to-server/clientid js-code-string (only accepts in dev mode)

channel ClientToConsole-clientid log-message
channel ConsoleToClient-clientid js-code-string

1) `rubycon()` will generate a GUID
2) then open a popup window with url syncromesh-root/new-console/GUID
3) then open channel connection ConsoleToClient-GUID
4) then patch window.log/warn/error
5) the `new-console` page will bring up a terminal window
6) then open channel connection ClientToConsole-GUID

when either channel terminates, that will get resent to the other channel
7) the client window will disconnect the log/warn/error window, and disconnect the channel
8) the console window will close

1-4 + 7 are in a class RubyCon
5-6 + 8 use hyper-react-express in SAP




nothing works whilst in debugger

sooo... one place to hook in is render:  if in debug mode when hitting render we render out a message, then wait for an event, then message the debugger with the component... debugger can poke around in the component, see what the state is, change state, whatever.. in otherwords we want to execute some opal code as if self were that component... fine! debugger can set state and finally leave.  

so render method is wrapped like this:

if React::State(Debugger, :debugging_in_session)
  "DEBUGGING IN SESSSION"
else
  ...normal code...
