	function display {
		// clearscreen.
		print mode + ": " at (1,1).
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
			print distanceSTR + " (eta: " + etaSTR + ")" at (7,2).
		}
		print "=============================================" at (1,3).
		print "height" at (5,5).
		print disp(ship:altitude) at (7, 8).
		print disp(alt:radar) at (7, 9).
		if (pitchMODE = "radar") {
			print " " at (5, 8).
			print ">" at (5, 9).
		} else if (pitchMODE = "absolute") {
			print ">" at (5, 8).
			print " " at (5, 9).
		} else {
			print " " at (5, 8).
			print " " at (5, 9).
		}

		if (pitchMODE = "radar") {
			print "set: " + disp(heightPID:setpoint - alt0) at (16, 6).
		} else {
			print "set: " + disp(heightPID:setpoint) at (16, 6).
		}
		print "err: " + disp(-heightPID:error) at (16, 8).
		print "out: " + disp(heightPID:output) at (16, 10).

		print "P: " + disp(heightPID:Pterm) at (31, 6).
		print "I: " + disp(heightPID:Iterm) at (31, 8).
		print "D: " + disp(heightPID:Dterm) at (31, 10).


		print "pitch(sin)" at (5,15).
		print disp(pitchNOW) at (7, 18).

		print "set: " + disp(pitchPID:setpoint) at (16, 16).
		print "err: " + disp(-pitchPID:error) at (16, 18).
		print "out: " + disp(pitchPID:output) at (16, 20).
		print "ctrl: " + disp(ship:control:pitch) at (15, 22).

		print "P: " + disp(pitchPID:Pterm) at (31, 16).
		print "I: " + disp(pitchPID:Iterm) at (31, 18).
		print "D: " + disp(pitchPID:Dterm) at (31, 20).

		print "speed" at (5, 25).
		print disp(speedNOW) at (7, 28).
		print "V: " + disp(Vvert()) at (4, 30).
		if (pitchMODE = "vvert") {
			print " -> " + disp(vvertPID:setpoint):trimstart at (4, 31).
		} else {
			print "         " at (4, 31).
		}

		print "set: " + disp(speedPID:setpoint) at (16, 26).
		print "err: " + disp(-speedPID:error) at (16, 28).
		print "out: " + disp(speedPID:output) at (16, 30).
		print "ctrl: " + disp(throttle) at (15, 32).

		print "P: " + disp(speedPID:Pterm) at (31, 26).
		print "I: " + disp(speedPID:Iterm) at (31, 28).
		print "D: " + disp(speedPID:Dterm) at (31, 30).
	}

// print "" + ofs + " " + headingDelta + " " + headingPID:ERROR + " [" + geotarget:distance + "]".
// print ((geoposition:lng - geotarget:lng) * sin(runwayAZM)).