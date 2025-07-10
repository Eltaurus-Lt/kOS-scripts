// import
run shipstate.
run shipsystems.
run science.

// control params
set heightPID to PIDLOOP(0.01, 0.001, 0.01, -0.2, 0.2).
set pitchPID to PIDLOOP(1.0, 0.05, 0.1, -1, 1).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(0.2, 0, 0.01, -1, 1).
set yawPID to PIDLOOP(0.2, 0.02, 0.1, -1, 1).

set speedPID to PIDLOOP(0.2, 0.02, 0.2, 0, 1).

// flight plan
set phase to 1.

set t0 to time:seconds.
set mode to "landed".
set altitudeMODE to "absolute".
set mult to 1.
set pitchTRIM to 0.
set geotarget to geoposition.

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
		set phase to 1.
	}

}

when phase = 1 and ship:altitude > 150 then {
	set phase to 2.
	set heightPID:setpoint to 12000.
	set pitchTRIM to 0.

	set mode to "geotarget".
	set geotarget to waypoint("Bill's Bane Alpha"):geoposition.

	when geotarget:distance < 60000 then {
		// slow-level phase
		set speedPID:setpoint to 50.
		set heightPID:setpoint to 350.
		setBrakes(50).
		when ship:velocity:surface:mag < 70 then {
			set altitudeMODE to "radar".
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

function disp {
	parameter number.
	parameter nchars to 5.

	local s to "" + number.

	if s:contains("e") {
		set exp to "e" + s:split("e")[1].
	} else {
		set exp to "    ".
	}

	return s:padleft(nchars):substring(0, nchars) + exp.
}

// control loop
clearscreen.
until phase = 3 {
	//state
	set speedNOW to ship:velocity:surface:mag.
	set pitchNOW to pitchSIN().

	// throttle
	lock throttle to speedPID:UPDATE(time:seconds, speedNOW).

	// yaw
	if mode = "landed" {
		set ship:control:yaw to 0.
	} else {
		set ship:control:yaw to mult * yawPID:UPDATE(time:seconds, slipSIN()) * 100 / speedNOW.
	}

	// height -> pitch
	if altitudeMODE = "radar" {
		set altitudeNOW to ship:altitude.
	} else {
		set altitudeNOW to alt:radar.
	}
	set pitchPID:setpoint to heightPID:UPDATE(time:seconds, altitudeNOW).
	if mode = "landed" {
		set ship:control:pitch to 0.
	} else {
		set ship:control:pitch to mult * pitchPID:UPDATE(time:seconds, pitchNOW) * 100 / speedNOW + pitchTRIM.
	}
	
	// heading 
	if mode = "geotarget" {

		set headingPID:setpoint to geotarget:heading.

		
	} else if mode = "landing" {

		set ofs to landingOFS(runwayAZM, runwayY).
		set headingDelta to arctan( ofs / 3000 ).
		set headingPID:setpoint to runwayAZM - headingDelta.

		// print "" + ofs + " " + headingDelta + " " + headingPID:ERROR + " [" + geotarget:distance + "]".
		// print ((geoposition:lng - geotarget:lng) * sin(runwayAZM)).
	}

	// -> roll
	if mode = "lift off" {
		set rollPID:setpoint to 0.
	} else {
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
	}
	if mode = "landed" {
		set ship:control:roll to 0.
	} else {
		set ship:control:roll to mult * rollPID:UPDATE(time:seconds, rollSIN()) * 100 / speedNOW.
	}


	// clearscreen.
	print mode + ": " at(1,1).
	if mode = "geotarget" {
		set distanceNOW to geotarget:distance.
		if distanceNOW < 10000 {
			set distanceSTR to disp(distanceNOW):trimend + "m".
		} else {
			set distanceSTR to disp(distanceNOW / 1000):trimend + "km".
		}
		set etaNOW to geotarget:distance / ship:velocity:surface:mag.
		if etaNOW < 150 {
			set etaSTR to disp(etaNOW):trimend + "s".
		} else if etaNOW < 150 * 60 {
			set etaSTR to disp(etaNOW / 60):trimend + "m".
		} else {
			set etaSTR to disp(etaNOW / 3600):trimend + "h".
		}
		print distanceSTR + " (eta: " + etaSTR + ")" at(7,2).
	}
	print "=============================================" at(1,3).
	print "height" at (5,5).
	print disp(alt:radar) at (7, 8).

	print "set: " + disp(heightPID:setpoint) at (15, 6).
	print "err: " + disp(-heightPID:error) at (15, 8).
	print "out: " + disp(heightPID:output) at (15, 10).

	print "P: " + disp(heightPID:Pterm) at (30, 6).
	print "I: " + disp(heightPID:Iterm) at (30, 8).
	print "D: " + disp(heightPID:Dterm) at (30, 10).


	print "pitch(sin)" at (5,15).
	print disp(pitchNOW) at (7, 18).

	print "set: " + disp(pitchPID:setpoint) at (15, 16).
	print "err: " + disp(-pitchPID:error) at (15, 18).
	print "out: " + disp(pitchPID:output) at (15, 20).
	print "ctrl: " + disp(ship:control:pitch) at (14, 22).

	print "P: " + disp(pitchPID:Pterm) at (30, 16).
	print "I: " + disp(pitchPID:Iterm) at (30, 18).
	print "D: " + disp(pitchPID:Dterm) at (30, 20).

	print "speed" at (5, 25).
	print disp(speedNOW) at (7, 28).

	print "set: " + disp(speedPID:setpoint) at (15, 26).
	print "err: " + disp(-speedPID:error) at (15, 28).
	print "out: " + disp(speedPID:output) at (15, 30).
	print "ctrl: " + disp(throttle) at (14, 32).

	print "P: " + disp(speedPID:Pterm) at (30, 26).
	print "I: " + disp(speedPID:Iterm) at (30, 28).
	print "D: " + disp(speedPID:Dterm) at (30, 30).
}

set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
wait 0.5.
brakes on.
wait until ship:velocity:surface:mag < 1.0.

wait 5.0.