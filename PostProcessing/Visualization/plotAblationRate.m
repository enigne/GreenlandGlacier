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
	%GET parameterization range{{{
	aParamRange = getfieldvalue(options, 'parameterization range', []);
	% }}}
	%GET velocity range{{{
	velRange = getfieldvalue(options, 'velocity range', [0, 1e4]);
	% }}}
	%GET ablation rate range{{{
	aRateRange = getfieldvalue(options, 'ablation rate range', [0, 8e4]);
	% }}}

	% process each time window averaged data{{{
	for i = 1:length(timeWindows)
		% Load data {{{
		datafile = [projPath, resultsFolder, datafilename, num2str(timeWindows(i)), '.mat'];
		disp(['    Loading isoline data from ', datafile])
		load(datafile);
		% process data
		NaRateC = aRateC ./ maxArateC;
		if isempty(yl)
			yl = [min(xDist), max(xDist)];
		end
		% }}}
		% plot {{{
		figure('position', [0,500,800,1000])
		jet0 = [1,1,1;jet()];
		colormap(jet0)
		subplot(5,1,1);
		imagesc(time, xDist, NaRateC)
		title('Normalized aRate')
		colorbar
		ylim(yl)

		subplot(5,1,2);
		imagesc(time, xDist, -BedC)
		title('Depth')
		colorbar
		ylim(yl)
		if ~isempty(bedRange)
			caxis(bedRange)
		end

		subplot(5,1,3);
		imagesc(time, xDist, NaRateC./(-BedC))
		title('aRate/(Depth)')
		colorbar
		ylim(yl)
		if ~isempty(aParamRange)
			caxis(aParamRange)
		end

		subplot(5,1,4);
		imagesc(time, xDist, VelC)
		title('Velocity')
		colorbar
		caxis(velRange)
		ylim(yl)

		subplot(5,1,5);
		imagesc(time, xDist, SigmaC)
		title('Sigma')
		colorbar
		caxis([0,1e6])
		ylim(yl)

		% max aRate
		figure('position', [750,500,800,200])
		plot(time, max(aRateC))
		hold on
		plot(time, mean(aRateC, 'omitnan'))
		title('Max aRate')
		xlim([min(time), max(time)])
		ylim(aRateRange)
		legend({'max','mean'})
	end % }}}
