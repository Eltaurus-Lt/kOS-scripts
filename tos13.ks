// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
set heightPID to PIDLOOP(0.001, 0.0001, 0.001, -0.2, 0.2).
set pitchPID to PIDLOOP(0.8, 0.05, 0.00, -1, 1).
set vvertPID to PIDLOOP(0.002, 0.004, 0, -0.2, 0.34).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(0.2, 0.002, 0.01, -1, 1).
set yawPID to PIDLOOP(0.2, 0.02, 0.1, -1, 1).

set speedPID to PIDLOOP(0.1, 0.05, 0.05, 0, 1).
set steerPID to PIDLOOP(-0.002, 0, 0, -0.05, 0.05).

// flight plan
set phase to 0.

set t0 to time:seconds.
set mode to "landed".
set pitchMODE to "none".
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
	set heightPID:setpoint to 10000.
	when ship:velocity:surface:mag > 0.8 then {
		brakes off.
	}

	set heightPID:maxoutput to 0.5.
	when ship:velocity:surface:mag > 75 then {
		set mode to "lift off".
		set pitchMODE to "alt sea".
		set pitchTRIM to 0.3.
		when alt:radar > 3 then {
			set pitchTRIM to 0.
		}
		when ship:altitude > 150 then {
			set heightPID:maxoutput to 0.2.
			set phase to phase+1.
		}
	}
}

when phase = 1 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 11000.

	set headingMODE to "geotarget".
	set geotarget to waypoint("Site WVTJ8V"):geoposition.

	when geotarget:distance < 20000 then {
		set phase to phase+1.
	}
}

when phase = 2 then {
	set pitchMODE to "direct".
	set headingMODE to "straight".
	set pitchPID:setpoint to 0.98.
	set speedPID:setpoint to 2000.
	stage.

	when ship:altitude > 18000 then {
		measure("sensorBarometer").
	}
	when ship:altitude > 50000 then {
		set pitchMODE to "none".
		when ship:altitude < 50000 then {
			set pitchMODE to "direct".
		}
	}
	when ship:altitude > 70000 then {
		set speedPID:setpoint to 0.
		set pitchPID:setpoint to -0.1.
		when ship:altitude < 10000 then {
			set phase to phase+1.
		}
	}

}

when phase = 3 then {
	// landing
	set pitchMODE to "alt sea".
	set headingMODE to "runway approach".
	set speedPID:setpoint to 300.
	set heightPID:setpoint to 2000.
	set runwayAZM to -90.
	set runwayY to 524.
	set geotarget to latlng(-0.0502, -74.507).
	setBrakes(35).

	when geotarget:distance < 30000 then {
		set heightPID:setpoint to 100.
		set speedPID:setpoint to 70.
	}

	when geotarget:distance < 10000 then {
		set heightPID:setpoint to 75.
		set heightPID:minoutput to -0.1.
		set speedPID:setpoint to 40.
	}
	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
	 	set heightPID:minoutput to -0.005.
	 	set heightPID:setpoint to 70.5.
	 	set speedPID:setpoint to 0.
	}		
	when ship:status = "LANDED" then {
		set phase to phase+1.
	}

}



// control loop
clearscreen.
until phase = 4 {
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
	} else if pitchMODE:startswith("alt ") {
		if pitchMODE = "alt surf" {
			set altitudeNOW to alt:radar + alt0.
		} else {
			set altitudeNOW to ship:altitude.
		}
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, altitudeNOW).
	}
	if pitchMODE = "none" {
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

display().
set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
wait 5.0.
brakes on.
wait until ship:velocity:surface:mag < 1.0.
wait 5.0.