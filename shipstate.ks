function pitchSIN {
	return ship:up:vector * ship:facing:vector.
}

function rollSIN {
	return lookdirup( facing:vector, up:vector ):starvector * facing:upvector.
}

function slipSIN {
	return - ship:velocity:surface:normalized * facing:starvector.
}

function polarSIN { //pitch relative to vertical
	return up:vector * facing:upvector.
}

function yawSIN {
	return up:vector * facing:starvector.
}

function Vvert {
	return ship:velocity:surface * up:vector.
}

function rollOMEGA {
	return ship:angularvel * facing:vector.
}

function realHEADING {
	parameter about is 0.

	local plane to lookdirup( up:vector, facing:vector ).
	local headed to arctan2( plane:starvector * north:vector, plane:upvector * north:vector).

	return mod(headed - about + 900, 360) + about - 180.
}

function landingOFS {
	parameter azm is 90.
	parameter startY is 512.

	return sin(azm) * (ship:body:position:y - startY).
}

function geodistance {
	parameter geo1.
	parameter geo2.

	set phi1 to geo1:lat.
	set phi2 to geo2:lat.
	set delta to geo2:lng - geo1:lng.

	return kerbin:radius * arccos(min(cos(phi1) * cos(phi2) * cos(delta) + sin(phi1) * sin(phi2),1)) / 180 * constant:pi.
}
