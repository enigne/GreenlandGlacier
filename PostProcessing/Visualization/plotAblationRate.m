% plot the frontal ablation rate
%	
% Last modified: 2022-06-19

function plotArate(varargin)
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
	%GET data filename: Arates_Obs_Isoline_aver{{{
	datafilename = getfieldvalue(options, 'data filename', 'Arates_Obs_Isoline_aver');
	% }}}
	%GET time windows: [0, 12, 30, 60, 90]{{{
	timeWindows= getfieldvalue(options, 'time windows', [0, 12, 30, 60, 90]);
	% }}}
	%GET ylim{{{
	yl= getfieldvalue(options, 'ylim', []);
	% }}}
	%GET bed range{{{
	bedRange= getfieldvalue(options, 'bed range', []);
	% }}}
	%GET parameter name: Arate{{{
	paramName = getfieldvalue(options, 'parameter name', 'Arate');
	% }}}
	%GET parameter range{{{
	rateRange = getfieldvalue(options, 'parameter range', [0, 8e4]);
	% }}}
	%GET parameterization range(for rate/bed){{{
	paramRange = getfieldvalue(options, 'parameterization range', []);
	% }}}
	%GET velocity range{{{
	velRange = getfieldvalue(options, 'velocity range', [0, 1e4]);
	% }}}

	% process each time window averaged data{{{
	for i = 1:length(timeWindows)
		% Load data {{{
		datafile = [projPath, resultsFolder, datafilename, num2str(timeWindows(i)), '.mat'];
		disp(['    Loading isoline data from ', datafile])
		load(datafile);

		% process data
		if strcmp(paramName, 'SigmaMax')
			paramRate = 1./sigmaMaxC;
			maxParamRate = max(paramRate);
			xData{1} =  paramRate ./ maxParamRate;
			xRange{1} = [0,1];
			xTitle{1} = 'Normalized sigmaMax';
		else
			paramRate = aRateC;
			maxParamRate = maxArateC;
			xData{1} =  paramRate ./ maxParamRate;
			xRange{1} = [0,1];
			xTitle{1} = 'Normalized ablation rate';
		end

		% general settings {{{
		% 2 - water depth 
		xData{2} = -BedC;
		xRange{2} = bedRange;
		xTitle{2} = 'Depth';
		% 3 - x{1} / x{2} 
		xData{3} =  xData{1}./xData{2};
		xRange{3} = paramRange;
		xTitle{3} = [xTitle{1}, '/', xTitle{2}];
		% 4 - Velocity 
		xData{4} = VelC;
		xRange{4} = velRange;
		xTitle{4} = 'Velocity';
		% 5 - Sigma 
		xData{5} = SigmaC;
		xRange{5} = [0, 1e6];
		xTitle{5} = 'Sigma';

		if strcmp(paramName, 'Strainrate')
			% 5 - Strainrate 
			xData{5} = -log(abs(StrainRateparallelC))/log(10);
			xRange{5} = [7, 8.5];
			xTitle{5} = 'StrainrateParallel';
			
			% 6 - Strainrate 
			xData{6} = -log(abs(StrainRateperpendicularC))/log(10);
			xRange{6} = [6, 10];
			xTitle{6} = 'StrainratePerpend';
		end
		Ndata = length(xData);
		if isempty(yl)
			yl = [min(xDist), max(xDist)];
		end
		%}}}
		%}}}
		% plot {{{
		figure('position', [0,800,800,1000])
		% set nan and 0 to white
		jet0 = [1,1,1;jet()];
		colormap(jet0)

		for i = 1: Ndata
			subplot(Ndata,1,i);
			imagesc(time, xDist, xData{i})
			title(xTitle{i})
			colorbar
			ylim(yl)
			if ~isempty(xRange{i})
				caxis(xRange{i});
			end
		end

		% max aRate
		figure('position', [0,500,800,200])
		semilogy(time, maxParamRate)
		hold on
		semilogy(time, mean(paramRate, 'omitnan'))
		semilogy(time, min(paramRate))
		title('Max Rate')
		xlim([min(time), max(time)])
		ylim(rateRange)
		legend({'max','mean','min'})
	end % }}}
	%}}}
