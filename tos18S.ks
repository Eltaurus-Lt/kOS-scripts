// import
run shipstate.
run shipsystems.
run science.

// control params
set steerPID to PIDLOOP(-0.002, 0, 0, -0.05, 0.05).
set speedPID to PIDLOOP(0.1, 0.02, 0.2, 0, 1).

stage.

set geotarget to latlng( 0, -74.8).
set geotarget to latlng( 0, -75.1).
set speedPID:setpoint to 10.

set phase to 0.

when geotarget:distance < 400 then {
	measureALL().
	set geotarget to latlng( -0.0485, -74.7131).

	when geotarget:distance < 15 then {
		set phase to 4.
	}
}

setBrakes(20).

until phase = 4 {
	// throttle
	set ship:control:mainthrottle to speedPID:UPDATE(time:seconds, ship:velocity:surface:mag).
	if (ship:velocity:surface:mag - speedPID:setpoint > 2 ) {
		brakes on.
	} else {
		brakes off.
	}

	set steerPID:setpoint to geotarget:heading.
	set ship:control:wheelsteer to steerPID:UPDATE(time:seconds, realHEADING(steerPID:setpoint)).

	print realHEADING(steerPID:setpoint) + "->" + geotarget:heading + " | " + geotarget:distance.
}

print "done".
set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
wait 0.5.
brakes on.
wait until ship:velocity:surface:mag < 1.0.
wait 5.0.
setBrakes(50).