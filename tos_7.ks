// import
run shipstate.
run science.

// control params
set heightPID to PIDLOOP(0.07, 0.001, 0.12, -0.18, 0.3).
set pitchPID to PIDLOOP(0.2, 0.01, 1.0, -1, 1).

set headingPID to PIDLOOP(0.07, 0, 0.04, -0.6, 0.6).
set rollPID to PIDLOOP(1.0, 0, 2.0, -1, 1).
set yawPID to PIDLOOP(0.3, 0.02, 2.0, -1, 1).

// prep
sas off.
brakes on.
stage.
lock throttle to 1.0.
wait 5.0.
brakes off.
wait until ship:velocity:surface:mag > 40.

// take off
print "take off".
set ship:control:pitch to 0.5.
set pitchSIN to sin(7.0).
wait until pitchSIN - ship:up:vector * ship:facing:vector < 0.01.
sas on.
wait until alt:radar > 25.
sas off.



// flight plan
set t0 to time:seconds.
set mode to "".
set heightPID:setpoint to 3000.
when ship:velocity:surface:mag > 250 then {
	lock throttle to 0.5.
}
when ship:velocity:surface:mag > 200 and ship:altitude > 2900 then {
	// openBays().
	stage.
	cutChutes().
	// closeBays().
}
when ship:altitude > 250 then {
	
		// when geotarget:distance < 25000 then {
		// 	set mode to "landing approach".
		// 	set geotarget to latlng(0.0489, -74.7 - 0.1).
		// 	when geotarget:distance > 41000 then {
		// 		when geotarget:distance < 36100 then {
		// 			set heightPID:setpoint to 500.
		// 			lock throttle to 0.
		// 		}
		// 	}
		// 	when geotarget:distance < 3000 then {
		// 		set heightPID:setpoint to 83.
		// 	}
		// 	when geoposition:lng > geotarget:lng + 0.01 then {
		// 		set mode to "landing".
		// 		setBrakes(75).
		// 		print "landing".
		// 	}		
		// 	when ship:status = "LANDED" then {
		// 		set mode to "touchdown".
		// 	}
		// }

}


// control loop
until mode = "touchdown" {
	// yaw
	set ship:control:yaw to yawPID:UPDATE(time:seconds, slipSIN()).

	// height -> pitch
	if mode = "landing" {
		set pitchPID:setpoint to 0.06.
	} else {
		set pitchPID:setpoint to heightPID:UPDATE(time:seconds, ship:altitude) + 0.01.
	}
	set ship:control:pitch to pitchPID:UPDATE(time:seconds, pitchSIN()) + 0.1.// - 0.2 * ship:control:yaw.	
	
	// heading 
	if mode = "geotarget" {
		set headingPID:setpoint to geotarget:heading.
		print geotarget:distance + " " + headingPID:ERROR.
	} else if (mode = "landing approach" or mode = "landing") {
		set ofs0 to landingOFS().
		if (ofs0 > 5) { 
			set ofs to ofs0 - 5. 
		} else if (ofs0 < - 5) {
			set ofs to ofs0 + 5. 
		} else {
			set ofs to ofs0.
		}
		set headingDelta to arctan( ofs / 3500 ).

		set headingPID:setpoint to 90 - headingDelta.
		print "" + ofs0 + " " + headingDelta + " " + headingPID:ERROR + " [" + geotarget:distance + "]".
	} 

	// -> roll
	if mode = "" {
		set rollPID:setpoint to 0.
	} else {
		set rollPID:setpoint to headingPID:UPDATE(time:seconds, realHEADING(headingPID:setpoint)).
	}

	set ship:control:roll to rollPID:UPDATE(time:seconds, rollSIN()).

}

wait 2.0.
brakes on.