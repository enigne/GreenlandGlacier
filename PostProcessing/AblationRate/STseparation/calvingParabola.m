function err = calvingParabola(x, y, param)
	a = param(1);
	err = a*x.^2 - y;
