% To compute ablation rate from the observed calving front position
%  - averaging sigmaMax is added by 20220812
%
% Last Modified: 2022-08-12

function averageAblationRate(varargin)
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
	%GET data filename: Arates_Obs{{{
	filename = getfieldvalue(options, 'data filename', 'Arates_Obs');
	datafile = [projPath, resultsFolder, filename, '.mat'];
	% }}}
	%GET save filename: Arates_Obs_aver{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs_aver');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET time windows: [12, 30, 60, 90]{{{
	timeWindows= getfieldvalue(options, 'time windows', [12,30,60,90]);
	% }}}
	%GET dataname: cmRates{{{
	dataname = getfieldvalue(options, 'dataname', 'cmRates');
	% }}}

%% load model {{{
disp(['    Loading ablation rate without smoothing from ', datafile])
nsdata=load(datafile);
%}}}
% moving average{{{
for i = 1: length(timeWindows)
	if strcmp(dataname, 'cmRates')
		disp(['    Averaging ablation rate with time window=', num2str(timeWindows(i))]);
		smoothdata = movingAverage([nsdata.cmRates;nsdata.time], 'time window', timeWindows(i), 'resample', 0);
		cmRates = smoothdata(1:end-1,:);
	elseif strcmp(dataname, 'sigmaMax')
		disp(['    Averaging sigma_max with time window=', num2str(timeWindows(i))]);
		smoothdata = movingAverage([nsdata.sigmaMax;nsdata.time], 'time window', timeWindows(i), 'resample', 0);
		sigmaMax = smoothdata(1:end-1,:);
	else
		error('unknown dataname')
	end
	time = smoothdata(end,:);

	% save 
	if saveFlag
		saveFilename = [projPath, resultsFolder, sfilename, num2str(timeWindows(i)), '.mat'];

		if strcmp(dataname, 'cmRates')
			disp(['    Saving ablation rate to ', saveFilename]);
			save([saveFilename], 'cmRates', 'time');
		elseif strcmp(dataname, 'sigmaMax')
			disp(['    Saving sigma_max to ', saveFilename]);
			save([saveFilename], 'sigmaMax', 'time');
		else
			error('unknown dataname')
		end
	end
end
%}}}
