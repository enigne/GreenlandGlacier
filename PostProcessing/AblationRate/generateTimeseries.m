% Use the arate data along the front to generate a time series
%	
% Last modified: 2022-11-15

function generateTimeseries(varargin)
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
	%GET save filename: Arates_Obs_Transient_aver{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs_Transient_aver');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}

	% load data {{{
	filename = [projPath, resultsFolder, datafilename];
	disp(['    Loading data from ', filename]);
	load(filename)
	disp('    Loading data done!'); %}}}
	% process each time window averaged data{{{
	% some threashold
	nanflag = isnan(VelC);
	nanflag = nanflag | (BedC > -0);
	nanflag = nanflag | (aRateC < 0);

	% set nan
	HC(nanflag) = nan;
	BedC(nanflag) = nan;
	VelC(nanflag) = nan;
	SigmaC(nanflag) = nan;

	% mean
	meanH = mean(HC, 'omitnan');
	meanBed = mean(BedC, 'omitnan');
	meanVel = mean(VelC, 'omitnan');
	meanSigma = mean(SigmaC, 'omitnan');

	maxH = max(HC);
	maxBed = max(BedC);
	maxVel = max(VelC);
	maxSigma = max(SigmaC);
	%}}}
	%% save {{{
	if saveFlag
		saveFilename = [projPath, resultsFolder, sfilename];
		disp(['    Saving time series to ', saveFilename]);
		save([saveFilename, '.mat'], 'time', 'meanH', 'maxH', 'meanBed', 'maxBed', 'meanVel', 'maxVel', 'meanSigma', 'maxSigma', 'meanArateC', 'maxArateC');
	end
	%}}}
