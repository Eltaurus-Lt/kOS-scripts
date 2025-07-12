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

function display {
	// clearscreen.
	print phase at (50,1).
	print headingMODE + ": " at (1,1).
	if true or headingMODE = "geotarget" {
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
		print distanceSTR + " (eta: " + etaSTR + ")" at (7,2).
	}
	if headingMODE = "runway approach" {
		print "b: " + disp(ofs):trimend + "m (at: " + disp(headingDelta):trimend + "deg)    " at (7,3).
	}
	print "=============================================" at (1,5).

	print "heading" at (3,7).
	print disp(realHEADING(steerPID:setpoint)) at (7, 9).

	print "set: " + disp(headingPID:setpoint) at (16, 8).
	print "err: " + disp(-headingPID:error) at (16, 9).
	print "out: " + disp(headingPID:output) at (16, 10).

	print "P: " + disp(headingPID:Pterm) at (31, 8).
	print "I: " + disp(headingPID:Iterm) at (31, 9).
	print "D: " + disp(headingPID:Dterm) at (31, 10).


	print "roll (sin)" at (3,12).
	print disp(rollSIN()) at (6, 14).

	print "set: " + disp(rollPID:setpoint) at (16, 13).
	print "err: " + disp(-rollPID:error) at (16, 14).
	print "out: " + disp(rollPID:output) at (16, 15).
	print "ctrl: " + disp(ship:control:roll,8) at (15, 16).

	print "P: " + disp(rollPID:Pterm) at (31, 13).
	print "I: " + disp(rollPID:Iterm) at (31, 14).
	print "D: " + disp(rollPID:Dterm) at (31, 15).


	print "height" at (3,18).
	print disp(ship:altitude) at (7, 20).
	print disp(alt:radar) at (7, 21).
	if (pitchMODE = "radar") {
		print " " at (5, 20).
		print ">" at (5, 21).
	} else if (pitchMODE = "absolute") {
		print ">" at (5, 20).
		print " " at (5, 21).
	} else {
		print " " at (5, 20).
		print " " at (5, 21).
	}

	if (pitchMODE = "radar") {
		print "set: " + disp(heightPID:setpoint - alt0) at (16, 19).
	} else {
		print "set: " + disp(heightPID:setpoint) at (16, 19).
	}
	print "err: " + disp(-heightPID:error) at (16, 20).
	print "out: " + disp(heightPID:output) at (16, 21).

	print "P: " + disp(heightPID:Pterm) at (31, 19).
	print "I: " + disp(heightPID:Iterm) at (31, 20).
	print "D: " + disp(heightPID:Dterm) at (31, 21).


	print "pitch (sin)" at (3,23).
	print disp(pitchNOW) at (6, 25).

	print "set: " + disp(pitchPID:setpoint) at (16, 24).
	print "err: " + disp(-pitchPID:error) at (16, 25).
	print "out: " + disp(pitchPID:output) at (16, 26).
	print "ctrl: " + disp(ship:control:pitch) at (15, 27).

	print "P: " + disp(pitchPID:Pterm) at (31, 24).
	print "I: " + disp(pitchPID:Iterm) at (31, 25).
	print "D: " + disp(pitchPID:Dterm) at (31, 26).


	print "speed" at (3, 29).
	print disp(speedNOW) at (7, 31).
	print "V: " + disp(Vvert()) at (4, 32).
	if (pitchMODE = "vvert") {
		print " -> " + disp(vvertPID:setpoint):trimstart at (4, 33).
	} else {
		print "         " at (4, 33).
	}

	print "set: " + disp(speedPID:setpoint) at (16, 30).
	print "err: " + disp(-speedPID:error) at (16, 31).
	print "out: " + disp(speedPID:output) at (16, 32).
	print "ctrl: " + disp(throttle) at (15, 33).

	print "P: " + disp(speedPID:Pterm) at (31, 30).
	print "I: " + disp(speedPID:Iterm) at (31, 31).
	print "D: " + disp(speedPID:Dterm) at (31, 32).
}

// print realHEADING(steerPID:setpoint) + "->" + geotarget:heading + " | " + geotarget:distance.

// print ((geoposition:lng - geotarget:lng) * sin(runwayAZM)).