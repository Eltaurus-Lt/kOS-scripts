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
// set phase to 3.
// set phase to 4.
// set phase to 5.

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
	set heightPID:setpoint to 10000.
	set pitchTRIM to 0.
	when ship:altitude > 8000 then {
		set heightPID:maxoutput to 0.1.
		when ship:altitude < 8000 then {
			set heightPID:maxoutput to 0.2.
		}
	}

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to latlng(85, -65).

	// when geotarget:distance < 80000 then {
	// 	KUniverse:PAUSE().
	// }

	when geotarget:distance < 115000 then {
		measureALL().
		lights off.
		when geotarget:distance < 110000 then {
			transmitALL().
		}
	}


	when geotarget:distance < 75000 then {
		// slow down and level

		set speedPID:setpoint to 60.
		set heightPID:setpoint to 300.

		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
		lights on.
		setBrakes(50).
		set rollPID:Ki to 0.
		
		// when geotarget:distance < 12500 then {
		// 	KUniverse:PAUSE.
		// }

		when geotarget:distance < 10000 then {
			set speedPID:setpoint to 40.
			set heightPID:setpoint to 0.
			when alt:radar < 150 then {
				set heightPID:setpoint to ship:altitude.
			}
			set heightPID:minoutput to -0.05.
		}

		when geotarget:distance < 4000 then {
			openBays().
			set alt0 to (ship:altitude - alt:radar).
			set pitchMODE to "vvert".
			set vvertPID:setpoint to -2.
			set headingMODE to "straight".
			set speedPID:setpoint to 30.
		}

		when alt:radar < 50 then {
			set vvertPID:setpoint to -0.5.
			gear on.
		}

		when ship:status = "LANDED" then {
			set phase to phase+1.
			set mode to "landed".
		}
	}
}

when phase = 2 then {
	set speedPID:setpoint to 0.
	set turnMODE to "wheels".
	setBrakes(35).
	closeBays().

	when ship:velocity:surface:mag < 1.0 then {
		wait 5.0.

		// KUniverse:PAUSE.
		gear off.
		lights off.
		openBays().

		print "".
		print "----------------------------------".
		print "1. take and transmit cabin report".
		print "2. clean 3 goo + 1 module".
		print "3. take EVA report".
		print "4. transmit EVA report".
		print "----------------------------------".
		print "".
		powerDown().

		set phase to phase+1.

	}
}

// science experiments
when phase = 3 then {
	measureALL().
	wait 5.0.
	transmitALL().
	wait 10.

	print "".
	print "----------------------------------".
	print "1. clean 3 goo + 1 module".
	print "2. take EVA report".
	print "2. take cabin report".
	print "----------------------------------".
	print "".
	powerDown().

	set phase to phase+1.
}

// science experiments 2
when phase = 4 then {
	measureALL().
	wait 5.0.

	print "".
	print "----------------------------------".
	print "1. take and restore 1 goo + 1 module".
	print "2. take 1 thermometer + 1 barometer".
	print "----------------------------------".
	print "".
	powerDown().

	set phase to phase+1.
}

// return take off
when phase = 5 then {
	gear on.
	wait 5.0.
	lights on.
	closeBays().

	setPIDs().

	clearscreen.
	set pitchMODE to "absolute".
	set headingMODE to "straight".
	set turnMODE to "avionics".
	set speedPID:setpoint to 350.
	set pitchTRIM to 0.

	when ship:velocity:surface:mag > 0.8 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 55 then {
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when alt:radar > 100 then {
			set pitchPID:Kd to defPitchD.
			set phase to phase+1.
			clearscreen.
			gear off.
			measureALL().
			when alt:radar > 500 then {
				closeBays().
			}
		}
	}
}

when phase = 6 then {
	set speedPID:setpoint to 350.
	set heightPID:setpoint to 11000.
	set pitchTRIM to 0.

	when ship:altitude > 8000 then {
		clearscreen.
		set heightPID:maxoutput to 0.1.
		when ship:altitude < 8000 then {
			set heightPID:maxoutput to 0.2.
		}
	}

	set mode to "geotarget".
	set headingMODE to "geotarget".
	set geotarget to latlng(0, -65).
	when geotarget:distance < 100000 then {
		set phase to phase+1.
	}
}

when phase = 7 then {
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
until phase = 8 {
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
setBrakes(50).
wait until ship:velocity:surface:mag < 1.0.
closeBays().
wait 5.0.