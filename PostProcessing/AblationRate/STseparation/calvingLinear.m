function err = calvingLinear(x,y,param)
	a = param(1);
	b = param(2);
	dump = param(3);
	err = a*x-y;
