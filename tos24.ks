// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	set throttlePID to PIDLOOP(0.01, 0.1, 0.2, 0, 1).
}

set phase to 0.
set t0 to time:seconds.

setPIDs().
stage.
sas on.

set throttlePID:setpoint to 1000.
set throttleMODE to "height".

when time:seconds - t0 > 90 then {
	set throttlePID:setpoint to 71.
}

// control loop
clearscreen.
until phase = -1 {

	lock throttle to throttlePID:UPDATE(time:seconds, ship:altitude).

	print throttlePID:setpoint + "   " at (2, 1).
	print throttlePID:error + "   " at (2, 2).

	print throttlePID:pterm + "   " at (2, 4).
	print throttlePID:iterm + "   " at (2, 5).
	print throttlePID:dterm + "   " at (2, 6).

	print ship:control:mainthrottle + "   " at (2, 9).
	print throttle + "   " at (2, 10).
}


set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
