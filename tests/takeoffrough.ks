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

// prep
sas off.
setBrakes(200).
brakes on.
stage.
lock throttle to 1.0.
wait 5.0.
brakes off.
wait until ship:velocity:surface:mag > 32.

// take off
set mode to "".
set pitchTRIM to 0.
print "take off".
set ship:control:pitch to 0.5.
set pitchSIN to sin(20.0).
wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.
sas on.
wait until alt:radar > 25.
sas off.

set heightPID:setpoint to 8000.
set speedPID:setpoint to 350.

until false {
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