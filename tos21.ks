// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	set heightPID to PIDLOOP(0.00007, 0.00006, 0.01, -0.15, 0.2).
	set pitchPID to PIDLOOP(1.0, 0.07, 0.00, -1, 1).
	set vvertPID to PIDLOOP(0.002, 0.004, 0, -0.2, 0.34).

	set headingPID to PIDLOOP(0.07, 0, 0.04, -0.8, 0.8).
	set rollPID to PIDLOOP(0.1, 0.002, 0.01, -1, 1).
	set yawPID to PIDLOOP(0.2, 0.02, 0.1, -1, 1).

	set speedPID to PIDLOOP(0.1, 0.05, 0.1, 0, 1).
	set steerPID to PIDLOOP(-0.002, 0, 0, -0.05, 0.05).
}

// flight plan
set phase to 0.

setPIDs().
set t0 to time:seconds.
set mode to "landed".
set pitchMODE to "level".
set headingMODE to "straight".
set turnMODE to "avionics".
set mult to 1.
set pitchTRIM to 0.
set alt0 to 0.
set ofs to 0.
set headingDelta to 0.
set geotarget to geoposition.
set defPitchD to pitchPID:Kd.

if phase = 0 {
	// prep
	sas off.
	setBrakes(200).
	brakes on.
	stage.
	set speedPID:setpoint to 350.
	when ship:velocity:surface:mag > 1.0 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 90 then {
		set pitchMODE to "absolute".
		set heightPID:setpoint to 10000.
		when ship:altitude > 150 then {
			set phase to phase+1.
			gear off.
		}
	}
}

when phase = 1 then {
	set speedPID:setpoint to 600.
	set heightPID:setpoint to 5000.
	set pitchTRIM to 0.
	// when ship:altitude > 7000 then {
	// 	set heightPID:maxoutput to 0.1.
	// 	when ship:altitude < 7000 then {
	// 		set heightPID:maxoutput to 0.2.
	// 	}
	// }

	when ship:altitude > 3000 then {
		set speedPID:setpoint to 170.
	}

	when ship:velocity:surface:mag > 145 and ship:velocity:surface:mag < 190 and ship:altitude > 4000 and ship:altitude < 7000 then {
		openBays().
		stage.
		cutChutes().
		when ship:altitude > 7000 then {
			closeBays().
		}
		set phase to phase+1.
	}
}

when phase = 2 then {
	set speedPID:setpoint to 170.
	set heightPID:setpoint to 11000.
	set pitchTRIM to 0.
	// when ship:altitude > 7000 then {
	// 	set heightPID:maxoutput to 0.1.
	// 	when ship:altitude < 7000 then {
	// 		set heightPID:maxoutput to 0.2.
	// 	}
	// }

	when ship:velocity:surface:mag > 125 and ship:velocity:surface:mag < 175 and ship:altitude > 10500 and ship:altitude < 11500 then {
		runTests().
		set phase to phase+1.
	}
}


when phase = 3 then {
	// landing
	set headingMODE to "runway approach".
	set runwayAZM to -90.
	set runwayY to 524.
	set geotarget to latlng(-0.0502, -74.507).
	// setBrakes(35).

	when geotarget:distance < 70000 then {
		set speedPID:setpoint to 100.
		set heightPID:setpoint to 1000.
		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
	}

	when geotarget:distance < 15000 then {
		set speedPID:setpoint to 60.
		set heightPID:setpoint to 175.
		set heightPID:minoutput to -0.05.
		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
	}
	when geotarget:distance < 4000 then {
		set heightPID:setpoint to 85.
		set heightPID:minoutput to -0.01.
		gear on.
		lights on.
	}

	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
	 	set heightPID:minoutput to -0.003.
	 	set heightPID:setpoint to 70.5.
	 	set speedPID:setpoint to 0.
	}		
	when ship:status = "LANDED" then {
		openBays().
		set phase to phase+1.
	}

}



// control loop
clearscreen.
until phase = 4 {
	//state
	set speedNOW to ship:velocity:surface:mag.
	set pitchNOW to pitchSIN().

	set cm to  mult * 100 / max(speedNOW, 40).

	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, speedNOW).
	if turnMODE = "wheels" {
		if (speedNOW - speedPID:setpoint > 0 ) {
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
	if pitchMODE = "level" {
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
	} else if headingMODE = "runway approach" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / max(geotarget:distance / 3, 3000) ).
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
wait 3.0.
// setBrakes(200).
wait until ship:velocity:surface:mag < 1.0.
closeBays().
wait 5.0.