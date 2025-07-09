// import
run shipstate.
run shipsystems.
run science.

// control params
set heightPID to PIDLOOP(0.07, 0.001, 0.12, -0.2, 0.3).
set pitchPID to PIDLOOP(0.2, 0.01, 1.0, -1, 1).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(1.0, 0, 2.0, -1, 1).
set yawPID to PIDLOOP(0.3, 0.02, 2.0, -1, 1).

set speedPID to PIDLOOP(0.1, 0.01, 0.2, 0, 1).

// prep
sas off.
brakes on.
stage.
lock throttle to 1.0.
wait 5.0.
brakes off.
wait until ship:velocity:surface:mag > 40.

// take off
print "take off".
set ship:control:pitch to 0.4.
set pitchSIN to sin(7.0).
wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.
sas on.
wait until alt:radar > 25.
sas off.


// flight plan
set t0 to time:seconds.
set mode to "".
set phase to 0.

set heightPID:setpoint to 2000.
set speedPID:setpoint to 250.

when ship:altitude > 250 then {
	set phase to 1.

	set mode to "geotarget".
	set geotarget to waypoint("Area CMK4"):geoposition.

	when geotarget:distance < 5000 then {
		set phase to 2.
		measureALL().
	}
}

when phase = 2 then {
	// landing
	set mode to "landing".
	set heightPID:setpoint to 500.
	set speedPID:setpoint to 65.
	set runwayAZM to 90.
	set runwayY to 512.
	set geotarget to latlng(0.0489, -74.7).
	setBrakes(50).

	when geotarget:distance < 4000 then {
		set heightPID:minoutput to -0.1.
		set heightPID:setpoint to 73.
		set speedPID:setpoint to 55.
	}
	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
	 	print "landing".
	 	set heightPID:minoutput to -0.01.
	 	set heightPID:setpoint to 70.5.
	 	set speedPID:setpoint to 0.
	}		
	when ship:status = "LANDED" then {
		set mode to "touchdown".
	}

}


// control loop
until mode = "touchdown" {
	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, ship:velocity:surface:mag).
	// print "" + ship:velocity:surface:mag + " " + speedPID:setpoint + " " + throttle.

	// yaw
	set ship:control:yaw to yawPID:UPDATE(time:seconds, slipSIN()).

	// height -> pitch
	set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude) + 0.01.
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()) + 0.1.
	
	// heading 
	if mode = "geotarget" {

		set headingPID:setpoint to geotarget:heading.

		print geotarget:distance + " " + headingPID:ERROR.
	} else if mode = "landing" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / 3000 ).
		set headingPID:setpoint to runwayAZM - headingDelta.

		print "" + ofs + " " + headingDelta + " " + headingPID:ERROR + " [" + geotarget:distance + "]".
		// print ((geoposition:lng - geotarget:lng) * sin(runwayAZM)).
	} 

	// -> roll
	if mode = "" {
		set rollPID:setpoint to 0.
	} else {
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
	}

	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}

set ship:control:neutralize to true.
lock throttle to 0.
wait 1.0.
brakes on.
when ship:velocity:surface:mag < 30 then {
	print "full brakes".
	setBrakes(100).
}