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
	%GET mode: meanA{{{
	datamode = getfieldvalue(options,'mode', 'meanA');
	%}}}
	%GET Xrange: [-700, -200] {{{
	XRange = getfieldvalue(options, 'Xrange', [-700, -200]);
	% }}}
	%GET number of x : 100{{{
	Nx = getfieldvalue(options, 'number of x', 100);
	% }}}
	%GET number of bins : 100{{{
	nbins = getfieldvalue(options, 'number of bins', 100);
	% }}}

	% Calculate the means{{{
	if strcmp(datamode, 'meanA')
		x = linspace(XRange(1), XRange(2), Nx+1);
		meanA = zeros(1, Nx);
		stdA = zeros(1, Nx);
		for i = 1:Nx
			flag = ((xdata>x(i)) & (xdata<x(i+1)));
			[N,edges]=histcounts(ydata(flag), nbins);
			[~, I] = max(N);
			meanA(i) = mean(ydata(flag), 'omitnan');
			stdA(i) = std(ydata(flag),'omitnan');
		end
		xdata = 0.5*(x(1:end-1)+x(2:end));
		ydata = meanA;
	end
	%}}}
	% curve fitting
	nanFlag = (~isnan(xdata)) & (~isnan(ydata));
	xdata = xdata(nanFlag);
	ydata = ydata(nanFlag);
	obj = @(x) (func(xdata(:),ydata(:), x));
	options = optimoptions('lsqnonlin','Display','iter','StepTolerance',1e-10,'OptimalityTolerance',1e-10, 'TypicalX', x0,'FunctionTolerance', 1e-10);
	[x,fval,exitflag,output] = lsqnonlin(obj, x0, [-2,-Inf, -Inf, -Inf], [2, Inf, Inf, Inf], options);

	% plot
	hold on
	xfit = linspace(xmin, xmax, 200);
	yfit = func(xfit, 0, x);
	plot(xfit, yfit, 'k.','LineWidth', 1);
	disp(['The optimal parameters are: ',num2str(x)]);
