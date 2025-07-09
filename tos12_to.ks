// import
run shipstate.
run shipsystems.
run science.

// control params
set heightPID to PIDLOOP(0.01, 0.001, 0.04, -0.3, 0.3).
set pitchPID to PIDLOOP(0.2, 0.02, 1.0, -1, 1).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(1.0, 0, 2.0, -1, 1).
set yawPID to PIDLOOP(0.3, 0.02, 2.0, -1, 1).

set speedPID to PIDLOOP(0.1, 0.02, 0.2, 0, 1).

set phase to 1.

set pitchTRIM to 0.

if phase = 0 {
	// prep
	sas off.
	setBrakes(200).
	brakes on.
	stage.
	lock throttle to 1.0.
	wait 5.0.
	brakes off.
	wait until ship:velocity:surface:mag > 40.

	// take off
	print "take off".
	set ship:control:pitch to 0.5.
	set pitchSIN to sin(7.0).
	wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.
	sas on.
	wait until alt:radar > 25.
	sas off.
}

// flight plan
set t0 to time:seconds.
set mode to "".

set heightPID:setpoint to 8000.
set heightPID:maxoutput to 0.2.
set speedPID:setpoint to 350.

when ship:altitude > 250 then {
	set phase to 1.

	set mode to "geotarget".
	set geotarget to waypoint("Bill's Bane Alpha"):geoposition.

	when geotarget:distance < 38000 then {
		set phase to 2.
		set mode to "landing rough".
		// slow-level phase
		set speedPID:setpoint to 50.
		set heightPID:setpoint to 150.
		set heightPID:maxoutput to 0.35.
		setBrakes(40).
		when ship:velocity:surface:mag < 70 then {
			// close-envelope phase
			set pitchPID:Kp to 1.0.
			set speedPID:setpoint to 45.
			set heightPID:setpoint to 50.
			set heightPID:minoutput to -0.05.
			when throttle > 0 and ship:velocity:surface:mag > speedPID:setpoint and heightPID:changerate > 0 then {
				// descent phase
				set speedPID:setpoint to 37.
				set heightPid:setpoint to 40.
				when alt:radar < 3.5 then {
					set pitchTRIM to 0.5.
				}
			}
		}

		when ship:status = "LANDED" then {
			set phase to 3.
		}
	}
}

// when phase = 5 then {
// 	// landing
// 	set mode to "landing".
// 	set heightPID:setpoint to 500.
// 	set speedPID:setpoint to 65.
// 	set runwayAZM to -90.
// 	set runwayY to 524.
// 	set geotarget to latlng(-0.0502, -74.507).
// 	setBrakes(50).

// 	when geotarget:distance < 4000 then {
// 		set heightPID:minoutput to -0.1.
// 		set heightPID:setpoint to 73.
// 		set speedPID:setpoint to 55.
// 	}
// 	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
// 	 	print "landing".
// 	 	set heightPID:minoutput to -0.01.
// 	 	set heightPID:setpoint to 70.5.
// 	 	set speedPID:setpoint to 0.
// 	}		
// 	when ship:status = "LANDED" then {
// 		set mode to "touchdown".
// 	}

// }


// control loop
until phase = 3 {
	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, ship:velocity:surface:mag).

	// yaw
	set ship:control:yaw to yawPID:UPDATE(time:seconds, slipSIN()).

	// height -> pitch
	if mode <> "landing rough" {
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude) + 0.01.
	} else {
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, alt:radar).

		print alt:radar + " [" + heightPID:setpoint + "] " + pitchPID:setpoint + " | " + ship:velocity:surface:mag. //pitchPID:Pterm + " ; " + pitchPID:Iterm + " ; " + pitchPID:Dterm.
	}
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()) + pitchTRIM.
	
	// heading 
	if mode = "geotarget" {

		set headingPID:setpoint to geotarget:heading.

		print geotarget:distance + " (eta: " + (geotarget:distance / ship:velocity:surface:mag) + ")".
	} else if mode = "landing" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / 3000 ).
		set headingPID:setpoint to runwayAZM - headingDelta.

		print "" + ofs + " " + headingDelta + " " + headingPID:ERROR + " [" + geotarget:distance + "]".
		// print ((geoposition:lng - geotarget:lng) * sin(runwayAZM)).
	}

	// -> roll
	if mode = "" or mode = "landing rough" {
		set rollPID:setpoint to 0.
	} else {
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
	}

	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}

set ship:control:neutralize to true.
lock throttle to 0.
wait 0.5.
brakes on.
wait until ship:velocity:surface:mag < 1.0.

wait 5.0.