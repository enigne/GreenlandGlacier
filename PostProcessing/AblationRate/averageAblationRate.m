% To compute ablation rate from the observed calving front position
% 
% Last Modified: 2022-06-19

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
	%GET vdata filename: timeSeries_Obs_onmesh{{{
	filename = getfieldvalue(options, 'data filename', 'Arates_Obs');
	datafile = [projPath, resultsFolder, filename, '.mat'];
	% }}}
	%GET save filename: timeSeries_Obs_onmesh_extrap{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs_aver');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET time windows: [12, 30, 60, 90]{{{
	timeWindows= getfieldvalue(options, 'time windows', [12,30,60,90]);
	% }}}

%% load model {{{
disp(['    Loading ablation rate without smoothing from ', datafile])
nsdata=load(datafile);
%}}}
% moving average{{{
for i = 1: length(timeWindows)
	disp(['    Averaging ablation rate with time window=', num2str(timeWindows(i))]);
	smoothdata = movingAverage([nsdata.cmRates;nsdata.time], 'time window', timeWindows(i), 'resample', 0);
	cmRates = smoothdata(1:end-1,:);
	time = smoothdata(end,:);

	% save 
	if saveFlag
		saveFilename = [projPath, resultsFolder, sfilename, num2str(timeWindows(i)), '.mat'];
		disp(['    Saving to ', saveFilename]);
		save([saveFilename], 'cmRates', 'time');
	end
end
%}}}
