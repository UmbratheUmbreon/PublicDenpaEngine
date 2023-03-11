This is where all your custom .hscript (and at one point maybe .lua) 
sub-states/menus go.

Files are to be named after what you want the sub-state to be called.
To open your sub-state, run the "openSubState('subStateName', [args])" 
command on any file.
Unlike states, sub-states will call "new(args)", where args is an array of
state loading arguments which can be used inside the function, call from
the "openSubState" command.

Example:

(in a different file):
openSubState('ExampleSubState', [15, 25]);

ExampleSubState.hscript:
var x = 0;
var y = 0;
function new(args:Array<Dynamic>) {
  x = args[0]; //15
  y = args[1]; //25
}