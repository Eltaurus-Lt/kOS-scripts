// import
run shipstate.

setBrakes(75).

// control params
set heightPID to PIDLOOP(0.15, 0.04, 0.1, -0.15, 0.3).
set headingPID to PIDLOOP(0.04, 0, 0.02, -0.6, 0.6).
// set downPID to PIDLOOP(0, 0.001, 0, -0.01, 0.01).
set pitchPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).
set rollPID to PIDLOOP(1.0, 0.1, 1.0, -1, 1).
set yawPID to PIDLOOP(1.0, 0.1, 0.5, -1, 1).


// flight plan
set heightPID:setpoint to 500.
lock throttle to 0.
set geotarget to latlng(0.0489, -74.7).
set mode to "".
when geotarget:distance < 5000 then {
	set heightPID:setpoint to 70.6.
}
when geoposition:lng > geotarget:lng then {
	set mode to "landing".
	print "landing !!!!".
	// set downPID:setpoint to -0.001.
}
when ship:status = "LANDED" then {
	set mode to "touchdown".
}


// control loop
until mode = "touchdown" {
	// yaw
	set ship:control:roll to yawPID:UPDATE(time:seconds, slipSIN()).

	// height -> pitch
	if mode = "landing" {
		set pitchPID:setpoint to 0.//downPID:UPDATE(time:seconds, Vvert()).
	} else {
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude).	
	}
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()) + 0.1.	
	
	
	// heading 
	set headingDelta to arctan( 0.05 * landingOFS() / ship:velocity:surface:mag ).
	set headingPID:setpoint to 90 - headingDelta.
	// print ""+ landingOFS() + " " + headingDelta + " " + (realHEADING() - 90) + " " + headingPID:ERROR.
	print Vvert().

	// -> roll
	set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).

	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}

wait 2.0.
brakes on.

until false {

}