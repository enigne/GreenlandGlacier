% hyperbolic tangential function which always intersects with (0,0)
function err = calvingTanh0(x, y, param)
	n = param(1);
	err = x.^n- y;
