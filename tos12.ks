// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
set heightPID to PIDLOOP(0.003, 0.0001, 0.001, -0.2, 0.2).
set pitchPID to PIDLOOP(1.0, 0.05, 0.01, -1, 1).
set vvertPID to PIDLOOP(0.002, 0.004, 0, -0.2, 0.2).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(0.2, 0, 0.01, -1, 1).
set yawPID to PIDLOOP(0.2, 0.02, 0.1, -1, 1).

set speedPID to PIDLOOP(0.2, 0.02, 0.02, 0, 1).
set steerPID to PIDLOOP(-0.002, 0, 0, -0.05, 0.05).

// flight plan
set phase to 1.

set t0 to time:seconds.
set mode to "landed".
set pitchMODE to "absolute".
set headingMODE to "straight".
set turnMODE to "avionics".
set mult to 1.
set pitchTRIM to 0.
set alt0 to 0.
set geotarget to geoposition.
set defPitchD to pitchPID:Kd.

if phase = 0 {
	// prep
	sas off.
	setBrakes(200).
	brakes on.
	stage.
	set speedPID:setpoint to 350.
	when ship:velocity:surface:mag > 0.8 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 30 then {
		// local temp to pitchPID:Kp.
		// set pitchPID:Kp to 5.0.
		// when alt:radar > 5 then {
		// 	set pitchPID:Kp to temp.
		// }
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when ship:altitude > 150 then {
			set phase to 1.
		}
	}
}

when phase = 1 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 12000.
	set pitchTRIM to 0.

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to waypoint("Bill's Bane Alpha"):geoposition.

	when geotarget:distance < 80000 then {
		// KUniverse:PAUSE().
	}

	when geotarget:distance < 75000 then {
		// slow down and level

		set speedPID:setpoint to 60.
		set heightPID:setpoint to 600.
		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
		setBrakes(50).
		
		// when geotarget:distance < 15000 then {
		// 	set pitchMODE to "vvert".
		// 	set vvertPID:setpoint to -1.
		// }

		// when geotarget:distance < 10000 then {
		// 	KUniverse:PAUSE.
		// }

		when geotarget:distance < 9000 then {
			openBays().
			set alt0 to (ship:altitude - alt:radar).
			set pitchMODE to "radar".
			set vvertPID:setpoint to -1.
			set headingMODE to "straight".
			set speedPID:setpoint to 25.
			set heightPID:setpoint to 150 + alt0.
			set heightPID:minoutput to -0.05.
		}

		when (geoposition:lng - geotarget:lng) > 0  then {
			set speedPID:setpoint to 22.
			set pitchMODE to "vvert".
			set pitchTRIM to heightPID:output.
			set vvertPID:setpoint to -0.5.
		}

		when ship:status = "LANDED" then {
			set phase to 2.
			set mode to "landed".
		}
	}
}

when phase = 2 then {
	set speedPID:setpoint to 10.
	set turnMODE to "wheels".
	setBrakes(20).
	closeBays().

	set headingMODE to "geotarget".
	set geotarget to waypoint("Bill's Bane Alpha"):geoposition.

	when geotarget:distance < 300 then {
		measureALL().
		set geotarget to waypoint("Bill's Bane Beta"):geoposition.
		when geotarget:distance < 300 then {
			resetALL().
			set geotarget to waypoint("Bill's Bane Gamma"):geoposition.
			measureALL().
			when geotarget:distance < 300 then {
				resetALL().
				measureALL().
				set phase to 3.
			}
		}
	}
}

when phase = 3 then {
	set heightPID to PIDLOOP(0.003, 0.0001, 0.001, -0.2, 0.2).
	set pitchPID to PIDLOOP(1.0, 0.05, .4, -1, 1).

	clearscreen.
	set pitchMODE to "absolute".
	set headingMODE to "straight".
	set turnMODE to "avionics".
	set speedPID:setpoint to 350.
	set pitchTRIM to 0.

	when ship:velocity:surface:mag > 0.8 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 30 then {
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when alt:radar > 100 then {
			set pitchPID:Kd to defPitchD.
			set phase to 4.
		}
	}
}

when phase = 4 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 12000.
	set pitchTRIM to 0.

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to latlng(0, -60).
	when geotarget:distance < 30000 then {
		set phase to 5.
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
clearscreen.
until phase = 6 {
	//state
	set speedNOW to ship:velocity:surface:mag.
	set pitchNOW to pitchSIN().

	set cm to  mult * 100 / max(speedNOW, 30).

	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, speedNOW).
	if turnMODE = "wheels" {
		if (speedNOW - speedPID:setpoint > 5 ) {
			brakes on.
		} else {
			brakes off.
		}
	}

	// yaw
	if mode = "landed" {
		set ship:control:yaw to 0.
	} else {
		set ship:control:yaw to cm * yawPID:UPDATE(time:seconds, slipSIN()).
	}

	// height -> pitch
	if pitchMODE = "vvert" {
		set pitchPID:setpoint to vvertPID:UPDATE(time:seconds, Vvert()).
	} else {
		if pitchMODE = "radar" {
			set altitudeNOW to alt:radar + alt0.
		} else {
			set altitudeNOW to ship:altitude.
		}
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, altitudeNOW).
	}
	if mode = "landed" {
		set ship:control:pitch to 0.
	} else {
		set ship:control:pitch to cm * (pitchPID:UPDATE(time:seconds, pitchNOW) + pitchTRIM).
	}
	
	// heading 
	if headingMODE = "geotarget" {
		if turnMODE = "wheels" {
			set steerPID:setpoint to geotarget:heading.
			set ship:control:wheelsteer to steerPID:UPDATE(time:seconds, realHEADING(steerPID:setpoint)).
		} else {
			set headingPID:setpoint to geotarget:heading.
		}
	} else if mode = "landing" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / 3000 ).
		set headingPID:setpoint to runwayAZM - headingDelta.
	}

	// -> roll
	if headingMODE = "straight" {
		set rollPID:setpoint to 0.
	} else {
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
	}
	if turnMODE = "wheels" {
		set ship:control:roll to 0.
	} else {
		set ship:control:roll to cm * rollPID:UPDATE(time:seconds, rollSIN()).
	}


	display().
}

set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
brakes on.
wait until ship:velocity:surface:mag < 1.0.

KUniverse:PAUSE().