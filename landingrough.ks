// import
run shipstate.
run shipsystems.
run science.

// control params
set heightPID to PIDLOOP(0.01, 0.001, 0.04, -0.3, 0.3).
set pitchPID to PIDLOOP(1.0, 0.04, 2.0, -1, 1).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(1.0, 0, 2.0, -1, 1).
set yawPID to PIDLOOP(0.3, 0.02, 2.0, -1, 1).

set speedPID to PIDLOOP(0.1, 0.02, 0.2, 0, 1).

set mode to "landing rough".
set speedPID:setpoint to 50.
set heightPID:setpoint to 200.
setBrakes(50).

when ship:velocity:surface:mag < 60 then {
	set speedPID:setpoint to 37.
	set heightPID:setpoint to 100.
	set heightPID:minoutput to -0.05.
	when throttle > 0 and ship:velocity:surface:mag > speedPID:setpoint and heightPID:changerate > 0 then {
		print "descent".
		set speedPID:setpoint to 35.
		set heightPid:setpoint to 50.
	}
}
// when ship:velocity:surface:mag < 50 then {
// 	set heightPID:setpoint to 40.
// 	set heightPID:minoutput to -0.03.
// }

when ship:status = "LANDED" then {
	set mode to "touchdown".
}

// control loop
until mode = "touchdown" {
	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, ship:velocity:surface:mag).
	// print "" + ship:velocity:surface:mag + " " + speedPID:setpoint + " " + throttle.

	// yaw
	set ship:control:yaw to yawPID:UPDATE(time:seconds, slipSIN()).

	// height -> pitch
	set pitchPID:setpoint to heightPID:UPDATE(time:seconds, alt:radar).
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()).
	print alt:radar + " ["+ heightPID:setpoint + "] " + heightPID:pterm + " " + heightPID:iterm + " " + heightPID:dterm + " | " + pitchPID:setpoint.
	
	// -> roll
	set rollPID:setpoint to 0.

	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}

set ship:control:neutralize to true.
lock throttle to 0.
wait 0.5.
brakes on.
// wait until ship:velocity:surface:mag < 30.
// setBrakes(200).