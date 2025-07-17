// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	// set heightPID to PIDLOOP(0.00007, 0.00001, 0.004, -0.1, 0.2).
	set heightPID to PIDLOOP(0.00007, 0.00003, 0.01, -0.15, 0.2).
	// set pitchPID to PIDLOOP(1.2, 0.006, 0.00, -1, 1).
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
	when ship:velocity:surface:mag > 1.0 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 90 then {
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when ship:altitude > 150 then {
			set phase to phase+1.
			gear off.
		}
	}
}

when phase = 1 then {
	set speedPID:setpoint to 550.
	set heightPID:setpoint to 10000.
	set pitchTRIM to 0.
	// when ship:altitude > 7000 then {
	// 	set heightPID:maxoutput to 0.1.
	// 	when ship:altitude < 7000 then {
	// 		set heightPID:maxoutput to 0.2.
	// 	}
	// }

	set mode to "geotarget".
	set headingMODE to "geotarget".
	// set geotarget to latlng(8.39, -118.469). // desert
	set geotarget to latlng(9.0, -118.710). // desert

	// when geotarget:distance < 80000 then {
	// 	KUniverse:PAUSE().
	// }


	when geotarget:distance < 75000 then {
		// slow down and level

		set speedPID:setpoint to 150.
		set heightPID:setpoint to 6000.
		when geotarget:distance < 50000 then {
			set heightPID:Kp to 0.001.
			set heightPID:setpoint to 4000.
		}
		when geotarget:distance < 35000 then {
			set speedPID:setpoint to 75.
			set heightPID:setpoint to 2000.
		}
		when geotarget:distance < 15000 then {
			set speedPID:setpoint to 100.
			set heightPID:setpoint to 650.	
		}

		openBays().
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}

		setBrakes(100).
		// set rollPID:Ki to 0.
		
		// when geotarget:distance < 12500 then {
		// 	KUniverse:PAUSE.
		// }

		when geotarget:distance < 10000 then {
			set heightPID:setpoint to 0.
			when alt:radar < 150 then {
				set heightPID:setpoint to ship:altitude.
			}
			set heightPID:minoutput to -0.05.
			set speedPID:setpoint to 70.
		}

		when geotarget:distance < 4000 then {
			openBays().
			measureAll().
			set alt0 to (ship:altitude - alt:radar).
			set pitchMODE to "vvert".
			set vvertPID:setpoint to -2.
			set headingMODE to "straight".
			set speedPID:setpoint to 60.
		}

		when alt:radar < 50 then {
			storeAll(0).
			set vvertPID:setpoint to -0.5.
			lights on.
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
	closeBays().

	when ship:velocity:surface:mag < 1.0 then {
		wait 5.0.

		// KUniverse:PAUSE.
		gear off.
		lights off.
		openBays().

		// print "".
		// print "----------------------------------".
		// print "1. take cabin report".
		// print "2. transmit cabin report".
		// print "2. clean goo + module".
		// print "3. take EVA report".
		// print "4. transmit EVA report".
		// print "----------------------------------".
		// print "".
		// powerDown().
		
		wait 10.0.
		set phase to 5.

	}
}

// science experiments
when phase = 3 then {
	measureALL().
	wait 5.0.
	storeAll(0).
	wait 10.

	print "".
	print "----------------------------------".
	print "1. clean goo + module".
	print "----------------------------------".
	print "".
	powerDown().

	set phase to phase+1.
}

// science experiments 2
when phase = 4 then {
	measureALL().
	wait 5.0.
	storeAll(1).

	print "".
	print "----------------------------------".
	print "1. clean goo + module".
	print "----------------------------------".
	print "".
	powerDown().

	set phase to phase+1.
}

// return take off
when phase = 5 then {
	gear on.
	wait 5.0.
	brakes on.
	lights on.
	closeBays().
	setPIDs().
	clearscreen.

	set pitchMODE to "absolute".
	set headingMODE to "straight".
	set turnMODE to "avionics".
	set speedPID:setpoint to 550.
	set pitchTRIM to 0.

	when ship:velocity:surface:mag > 1.0 then {
		brakes off.
	}

	when ship:velocity:surface:mag > 80 then {
		set mode to "lift off".
		set heightPID:setpoint to 10000.
		when alt:radar > 100 then {
			set pitchPID:Kd to defPitchD.
			set phase to phase+1.
			clearscreen.
			gear off.
			lights off.
			measureALL().
			when alt:radar > 500 then {
				closeBays().
			}
		}
	}
}


when phase = 6 then {
	// landing
	set headingMODE to "runway approach".
	set runwayAZM to 90.
	set runwayY to 512.
	set geotarget to latlng(0.0489, -74.7).
	// setBrakes(35).

	set pitchMODE to "absolute".
	set turnMODE to "avionics".
	set mode to "lift off".
	set speedPID:setpoint to 550.
	set heightPID:setpoint to 10000.
	set pitchTRIM to 0.


	when geotarget:distance < 90000 then {
		set speedPID:setpoint to 100.
		set heightPID:setpoint to 6000.
		set heightPID:Kp to 0.001.
	}

	when geotarget:distance < 55000 then {
		set heightPID:setpoint to 1000.
		openBays().
	}

	when geotarget:distance < 20000 then {
		set speedPID:setpoint to 60.
		set heightPID:setpoint to 600.
		// set heightPID:Kp to 0.001.
	}

	when geotarget:distance < 7000 then {
		set heightPID:setpoint to 250.
		set heightPID:minoutput to -0.05.
		when ship:velocity:surface:mag < speedPID:setpoint then {
			closeBays().
		}
		gear on.
	}
	when geotarget:distance < 4000 then {
		set heightPID:setpoint to 110.
		set heightPID:minoutput to -0.01.
	}

	when (geoposition:lng - geotarget:lng) * sin(runwayAZM) > 0 then {
	 	set heightPID:minoutput to -0.0015.
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
until phase = 7 {
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
// setBrakes(200).
wait until ship:velocity:surface:mag < 1.0.
closeBays().
wait 5.0.