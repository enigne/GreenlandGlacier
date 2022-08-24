% To compute the parameterization using ablation rate
% 
% Last Modified: 2022-08-04

function analyzeNormalizedArate(varargin)
	%Check inputs {{{
	%recover options
	options=pairoptions(varargin{:});
	% }}}
	%GET glacier: Can NOT be empty{{{
	glacier = getfieldvalue(options,'glacier', '');
	if isempty(glacier)
		error('glacier can not be empty')
	end
	% }}}
	%GET path (of the workspace) {{{
	workingPath = getfieldvalue(options,'path','/totten_1/chenggong/');
	projPath = [workingPath, glacier, '/'];
	% }}}
	%GET results folder : './PostProcessing/Results/'{{{
	resultsFolder = getfieldvalue(options,'results folder','./PostProcessing/Results/');
	% }}}
	%GET function handler {{{
	func = getfieldvalue(options,'function handler', @calvingTanh);
	%}}}
	%GET time windows: 0{{{
	timeWindow = getfieldvalue(options, 'time windows', 0);
	% }}}
	%GET data filename: Arates_Obs_Isoline{{{
	filename = getfieldvalue(options, 'data filename', 'Arates_Obs_Isoline');
	datafile = [projPath, resultsFolder, filename, '_aver', num2str(timeWindow), '.mat'];
	% }}}
	%GET bed range: [-700, -200] {{{
	bedRange = getfieldvalue(options, 'bed range', [-700, -200]);
	% }}}
	%GET number of x : 100{{{
	Nx = getfieldvalue(options, 'number of x', 100);
	% }}}
	%GET number of bins : 100{{{
	nbins = getfieldvalue(options, 'number of bins', 100);
	% }}}
	%GET paramX0 : [0.8, 0.01, 400, 0.5] {{{
	paramX0 = getfieldvalue(options, 'paramX0', [0.8, 0.01, 400, 0.5]);
	% }}}
	%GET figure position : [0.8, 0.01, 400, 0.5] {{{
	figPos = getfieldvalue(options, 'figure position', [0, 0, 500, 400]);
	% }}}
	%GET Index of x-axis{{{
	xdataInd = getfieldvalue(options,'xdata', 1); % 1-BedC, 2-HC, 3-sigmaVMC, 4-velC, 5-Hab, 6-TF, 7-isoline data
	% }}}

	% load model {{{
	disp(['    Loading ablation rate without smoothing from ', datafile])
	nsdata=load(datafile);
	nAc = nsdata.aRateC ./ nsdata.maxArateC;
	Ac = nAc(:);
	if xdataInd == 1
		disp('   Use bed elevation for x-axis');
		Bed =  nsdata.BedC(:);
		xname = 'Bed';
	elseif xdataInd == 2 % normalized vel
		disp('   Use normalized velocity for x-axis');
		Bed =  nsdata.VelC./max(nsdata.VelC);
		bedRange(1) = 0;
		bedRange(2) = 1;
		xname = 'normalized vel';
	elseif xdataInd == 3 % truncated vel
		disp('   Use truncated velocity for x-axis');
		threshold = 8000;
		Bed = min(1, nsdata.VelC./threshold);
		bedRange(1) = 0;
		bedRange(2) = 1;
		xname = 'truncated vel';
	elseif xdataInd == 4 % vel
		disp('   Use velocity for x-axis');
		upperbound = 8000;
		lowerbound = 100;
		Bed = (min(upperbound, max(lowerbound, nsdata.VelC))-lowerbound)/upperbound;
		bedRange(1) = 0;
		bedRange(2) = 1;
		xname = 'truncated vel';
	else
		error('missing xdata');
	end
	Bed = Bed(:);
	%}}}
	% Calculate the means{{{
	xbed = linspace(bedRange(1), bedRange(2), Nx+1);
	meanA = zeros(1, Nx);
	stdA = zeros(1, Nx);
	for i = 1:Nx
		flag = ((Bed>xbed(i)) & (Bed<xbed(i+1)));
		[N,edges]=histcounts(Ac(flag), nbins);
		[~, I] = max(N);
		meanA(i) = mean(Ac(flag), 'omitnan');
		stdA(i) = std(Ac(flag),'omitnan');
	end
	xdata = 0.5*(xbed(1:end-1)+xbed(2:end));
	ydata = meanA;
	figure('Position', figPos)
	errorbar(xdata, ydata, stdA)
	ylim([0,1.2])
	hold on
	%}}}
	% Curve fitting {{{
	nanFlag = (~isnan(xdata)) & (~isnan(ydata));
	xdata = xdata(nanFlag);
	ydata = ydata(nanFlag);
	obj = @(x) (func(xdata(:),ydata(:), x));
	options = optimoptions('lsqnonlin','Display','iter','StepTolerance',1e-10,'OptimalityTolerance',1e-10, 'TypicalX', paramX0,'FunctionTolerance', 1e-10, 'MaxFunctionEvaluations', 1000);
	[x,fval,exitflag,output] = lsqnonlin(obj, paramX0, [-2,-Inf, -Inf, -Inf], [2, Inf, Inf, Inf], options);
	xfit = linspace(bedRange(1), bedRange(2), Nx*5);
	yfit = func(xfit, 0, x);
	%}}}
	% plot{{{
	plot(xfit, yfit, 'k.','LineWidth', 1);
	ylim([0, 1])
	xlim([bedRange(1), bedRange(2)])
	xlabel(xname)
	ylabel('Normalized aRate')
	title(['mw=',num2str(timeWindow), ', optimal: ', num2str(x)])
	disp(['The optimal parameters are : ', num2str(x, '%.5f, ')])
	%}}}
