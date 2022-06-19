function x = curvefitting(varargin)
	%recover options {{{
	options=pairoptions(varargin{:});
	% }}}
	%GET xdata {{{
	xdata = getfieldvalue(options,'xdata', 0);
	%}}}
	%GET ydata {{{
	ydata = getfieldvalue(options,'ydata', 0);
	%}}}
	%GET x0 {{{
	x0 = getfieldvalue(options,'x0', [0,0,0]);
	%}}}
	%GET function handler {{{
	func = getfieldvalue(options,'func', @calvingTanh);
	%}}}
	%GET xmin {{{
	xmin = getfieldvalue(options,'xmin', -1e3);
	%}}}
	%GET xmax {{{
	xmax = getfieldvalue(options,'xmax', 1e3);
	%}}}

	% curve fitting
	nanFlag = ~isnan(xdata);
	xdata = xdata(nanFlag);
	ydata = ydata(nanFlag);
	obj = @(x) (func(xdata(:),ydata(:), x));
	options = optimoptions('lsqnonlin','Display','iter','StepTolerance',1e-10,'OptimalityTolerance',1e-10, 'TypicalX', x0,'FunctionTolerance', 1e-10);
	[x,fval,exitflag,output] = lsqnonlin(obj, x0, [-1,-Inf, -Inf], [0, Inf, Inf], options);

	% plot
	hold on
	xfit = linspace(xmin, xmax, 200);
	yfit = func(xfit, 0, x);
	plot(xfit, yfit, 'k.','LineWidth', 1);
	disp(['The optimal parameters are: ',num2str(x)]);
