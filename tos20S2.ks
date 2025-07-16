// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	set heightPID to PIDLOOP(0.003, 0.0001, 0.001, -0.2, 0.2).
	set pitchPID to PIDLOOP(0.5, 0.05, 0.00, -1, 1).
	set vvertPID to PIDLOOP(0.002, 0.004, 0, -0.2, 0.34).

	set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
	set rollPID to PIDLOOP(0.2, 0.002, 0.01, -1, 1).
	set yawPID to PIDLOOP(0.2, 0.02, 0.1, -1, 1).

	set speedPID to PIDLOOP(0.2, 0.02, 0.02, 0, 1).
	set steerPID to PIDLOOP(-0.002, 0, 0, -0.05, 0.05).
}

// flight plan
set phase to 0.

setPIDs().
set t0 to time:seconds.
set mode to "landed".
set pitchMODE to "absolute".
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
	when ship:velocity:surface:mag > 0.8 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 55 then {
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when ship:altitude > 150 then {
			set phase to phase+1.
			gear off.
		}
	}
}

when phase = 1 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 7000.
	set pitchTRIM to 0.

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to latlng(0.079629, -79.37082). // mountain peak (grasslands + highlands on the way)

	when geotarget:distance < 9000 then {
		set phase to phase+1.
	}

}

when phase = 2 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 7000.
	set pitchTRIM to 0.

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to latlng(0.88977, -73.5948). // water (+ shores + grasslands + highlands on the way)

	when geotarget:distance > 58000 then {
		measure("sensorThermometer").
	}

	when geotarget:distance < 25000 then {
		set heightPID:setpoint to 2000.
	}	

	when geotarget:distance < 4000 then {
		measure("science.module").
		set phase to phase+1.
	}
}

when phase = 3 then {
	// landing
	set headingMODE to "runway approach".
	set runwayAZM to -90.
	set runwayY to 524.
	set geotarget to latlng(-0.0502, -74.507).
	setBrakes(35).

	// when geotarget:distance < 80000 then {
	// 	KUniverse:PAUSE.
	// }

	when geotarget:distance < 70000 then {
		set heightPID:setpoint to 75.
		set speedPID:setpoint to 60.
		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
	}

	when geotarget:distance < 7000 then {
		set heightPID:minoutput to -0.1.
		set speedPID:setpoint to 40.

		gear on.
	}
	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
	 	set heightPID:minoutput to -0.005.
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

	set cm to  mult * 100 / max(speedNOW, 30).

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
	} else if headingMODE = "runway approach" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / max(geotarget:distance / 10, 1000) ).
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
setBrakes(50).
wait until ship:velocity:surface:mag < 1.0.
closeBays().
wait 5.0.