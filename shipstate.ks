function pitchSIN {
	return ship:up:vector * ship:facing:vector.
}

function rollSIN {
	return lookdirup( facing:vector, up:vector ):starvector * facing:upvector.
}

function slipSIN {
	return - ship:velocity:surface:normalized * facing:starvector.
}

function Vvert {
	return ship:velocity:surface * up:vector.
}

function realHEADING {
	declare parameter about is 0.

	local plane to lookdirup( up:vector, facing:vector ).
	local headed to arctan2( plane:starvector * north:vector, plane:upvector * north:vector).
	return mod(headed - about + 900, 360) + about - 180.
}

function landingOFS {
	declare parameter azm is 90.
	declare parameter startY is 512.

	return sin(azm) * (ship:body:position:y - startY).
}