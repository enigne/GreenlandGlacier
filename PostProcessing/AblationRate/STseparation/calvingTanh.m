function err = calvingTanh(x, y, param)
	theta = param(1);
	alpha = param(2);
	xoffset = param(3);
	yoffset = param(4);
	err = yoffset-0.5*theta*tanh(alpha*(x+xoffset)) - y;
