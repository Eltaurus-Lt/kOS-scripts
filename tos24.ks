// import
run shipstate.
run shipsystems.
run science.
run display.

// control params
function setPIDs {
	set altPID to PIDLOOP(0.01, 0.2, 0.1, 0.1, 1).
	set speedPID to PIDLOOP(0.5, 0.2, 0.0, 0.1, 1).

	set pitchPID to PIDLOOP(15.0, 0.2, 7.0, -1, 1).
	set yawPID to PIDLOOP(15.0, 0.2, 7.0, -1, 1).

	set rollPID to PIDLOOP(1.0, 0.01, 0.5, -1, 1).

	set tiltPID to PIDLOOP(0.002, 0.001, 0.05, 0, 0.005).

	set vhPID to PIDLOOP(0.05, 0.0002, 0.0, 0, 25).
	set hthrustPID to PIDLOOP(0.01, 0.005, 0.25, 0, 0.1).
}

set phase to 0.
set t0 to time:seconds.

setPIDs().
stage.

set geotarget to geoposition.
set altPID:setpoint to 34000.
set throttleMODE to "alt".
set tiltMODE to "geotarget".

set speedPID:setpoint to 500.
set speedPID:minoutput to 0.

// when ship:altitude > 30500 then {
// 	stage.
// 	when ship:altitude < 15000 then {
// 		set speedPID:minoutput to 0.1.
// 	}
// 	set throttleMODE to "alt".
// 	set altPID:setpoint to 75.
// }

// set altPID:setpoint to 3000.
// when ship:altitude > altPID:setpoint then {
// 	set speedPID:minoutput to 0.1.
// 	set altPID:setpoint to 75.
// }

set altPID:setpoint to 150.
set geotarget to latlng(-0.0973684 + 0.003, -74.557178 - 0.0675).
set geotarget to latlng(-0.0945671, -74.624932).

when geodistance(geotarget, geoposition) < 1 and ship:velocity:surface:mag < 1 then {
	set altPID:setpoint to 142.4.
}

when alt:radar > 100 then {
	when ship:status = "LANDED" then {
		set phase to -1.
	}
}

// when ship:altitude > 700 then {
// 	set yawPID:setpoint to 0.2.
// }

// when time:seconds - t0 > 37 then {
// 	set altPID:setpoint to 77.
// 	when geodistance(geotarget, geoposition) < 2 and ship:altitude < altPID:setpoint then {
// 		set altPID:setpoint to 75.
// 	}
// 	when ship:status = "LANDED" then {
// 		set phase to -1.
// 	}
// }

list engines in engine.

// control loop
clearscreen.
until phase = -1 {
	// "constants"
	set g1 to constant:G * Kerbin:Mass / (Kerbin:radius + ship:altitude)^2.
	set gt to engine[0]:possiblethrust / ship:mass.


	// throttle
	if throttleMODE = "speed" {
		lock throttle to speedPID:UPDATE(time:seconds, Vvert()).
	}　else if throttleMODE = "alt" {

		set deltaH to altPID:setpoint - ship:altitude.

		if deltaH > 0 {
			set speedPID:setpoint to 1.02 * sqrt( 2 * (g1 - speedPID:minoutput * gt) * deltaH ).
		} else {
			set speedPID:setpoint to - 0.97 * sqrt( 2 * (g1 - speedPID:maxoutput * gt) * deltaH ).
		}

		lock throttle to speedPID:UPDATE(time:seconds, Vvert()).

	} if throttleMODE = "alt1" {
		lock throttle to altPID:UPDATE(time:seconds, ship:altitude).
	}

	// tilt
	if tiltMODE = "geotarget" {
		set vhTGT to vhPID:UPDATE(time:seconds, - geodistance(geotarget, geoposition)).
		// set vhNOW to north:vector * (north:vector * ship:velocity:surface) + north:starvector * (north:starvector * ship:velocity:surface).
		// set vhERR to vhTGT * (north:vector * cos(geotarget:heading) - north:starvector * sin(geotarget:heading)) - vhNOW.

		set dvhN to vhTGT * cos(geotarget:heading) - north:vector * ship:velocity:surface.
		set dvhE to vhTGT * sin(geotarget:heading) + north:starvector * ship:velocity:surface.

		set hthrust to hthrustPID:UPDATE(time:seconds, - sqrt(dvhN ^ 2 + dvhE ^2)).// / max(throttle, 0.1).
		set hthrustAZM to arctan2(dvhE, dvhN).
		set hthrustVEC to hthrust * (north:vector * cos(hthrustAZM) - north:starvector * sin(hthrustAZM)).


		set pitchPID:setpoint to - hthrustVEC * facing:upvector.
		set yawPID:setpoint to - hthrustVEC * facing:starvector.

		print geodistance(geotarget, geoposition) at (4, 15).
		print vhTGT at (4, 16).
		print dvhN at (4, 17).
		print dvhE at (24, 17).

		print hthrust at (6, 19).
		print hthrustPID:setpoint at (6, 20).
		print hthrustPID:error at (26, 20).
		print hthrustPID:Kp at (6, 21).
		print hthrustPID:Ki at (26, 21).

	} else if tiltMODE = "geotarget1" {
		set tilt to tiltPID:UPDATE(time:seconds, -geodistance(geotarget, geoposition)).
		// set heading to geotarget:heading.

		set tiltVEC to tilt * (north:vector * cos(geotarget:heading) - north:starvector * sin(geotarget:heading)) / max(throttle, 0.1).

		set pitchPID:setpoint to -tiltVEC * facing:upvector.
		set yawPID:setpoint to -tiltVEC * facing:starvector.
	
		print geodistance(geotarget, geoposition) at (4, 15).
		print tiltPID:error at (4, 16).
		print "tilt: " + tilt + "                                              " at (4, 17).
		// print tiltPID:pterm at (4, 19).

		print pitchPID:setpoint at (4, 21).
		print polarSIN() at (29, 21).

		print geotarget:heading at (15, 24).
		print tiltVEC*north:vector + "  " at (5, 25).
		print tiltVEC*north:starvector + "  " at (29, 25).
	}

	set ship:control:pitch to - pitchPID:UPDATE(time:seconds, polarSIN()).
	set ship:control:yaw to - yawPID:UPDATE(time:seconds, yawSIN()).
	

	// roll
	set ship:control:roll to - rollPID:UPDATE(time:seconds, rollOMEGA()).

	print Vvert() + "    " at (25, 1).
	print gt + "    " at (25, 2).

	print speedPID:setpoint + "   " at (2, 1).
	print speedPID:error + "   " at (2, 2).

	print speedPID:pterm + "   " at (2, 4).
	print speedPID:iterm + "   " at (2, 5).
	print speedPID:dterm + "   " at (2, 6).

	// print ship:control:mainthrottle + "   " at (2, 9).
	print throttle + "   " at (2, 10).

}


set ship:control:neutralize to true.
set ship:control:mainthrottle to 0.
lock throttle to 0.
