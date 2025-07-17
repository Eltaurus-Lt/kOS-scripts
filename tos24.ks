// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	set altPID to PIDLOOP(0.01, 0.1, 0.2, 0, 1).
	set speedPID to PIDLOOP(0.5, 0.05, 0.0, 0, 1).
}

set phase to 0.
set t0 to time:seconds.

setPIDs().
stage.
sas on.

set altPID:setpoint to 1000.
set throttleMODE to "alt".

set speedPID:setpoint to 200.

when time:seconds - t0 > 37 then {
	set altPID:setpoint to 75.
	when ship:status = "LANDED" then {
		set phase to -1.
	}
}

list engines in engine.

// control loop
clearscreen.
until phase = -1 {
	// "constants"
	set g1 to constant:G * Kerbin:Mass / (Kerbin:radius + ship:altitude)^2.
	set gt to engine[0]:possiblethrust / ship:mass.


	if throttleMODE = "speed" {
		lock throttle to speedPID:UPDATE(time:seconds, Vvert()).
	}　else if throttleMODE = "alt" {

		set deltaH to altPID:setpoint - ship:altitude.

		if deltaH > 0 {
			set speedPID:setpoint to 1.02 * sqrt( 2 * g1 * deltaH ).
		} else {
			set speedPID:setpoint to - 0.97 * sqrt( 2 * (g1 - gt) * deltaH ).
		}

		lock throttle to speedPID:UPDATE(time:seconds, Vvert()).

	} if throttleMODE = "altAGN" {
		lock throttle to altPID:UPDATE(time:seconds, ship:altitude).
	}

	print Vvert() + "    " at (25, 1).
	print gt + "    " at (25, 2).

	print speedPID:setpoint + "   " at (2, 1).
	print speedPID:error + "   " at (2, 2).

	print speedPID:pterm + "   " at (2, 4).
	print speedPID:iterm + "   " at (2, 5).
	print speedPID:dterm + "   " at (2, 6).

	// print ship:control:mainthrottle + "   " at (2, 9).
	print throttle + "   " at (2, 10).
}


set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
