function err = calvingTanh(x, y, param)
	theta = param(1);
	alpha = param(2);
	midp = param(3);
	err = 0.5*theta*(1-tanh((x+midp)/(alpha)))+(1-theta) - y;
