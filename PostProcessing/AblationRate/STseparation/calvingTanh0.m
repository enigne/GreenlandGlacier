% hyperbolic tangential function which always intersects with (0,0)
function err = calvingTanh0(x, y, param)
	theta = param(1);
	alpha = param(2);
	xoffset = param(3);
	yoffset = 0.5*theta*tanh(alpha*(xoffset));
	err = yoffset-0.5*theta*tanh(alpha*(x+xoffset)) - y;
