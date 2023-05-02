% To compute time average ablation rate along the frontal isoline
%
% Last Modified: 2023-05-02

function averageIsolineArate(varargin)
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
	%GET data filename: Arates_thd0_FC_Obs_Isoline_aver{{{
	filename = getfieldvalue(options, 'data filename', 'Arates_thd0_FC_Obs_Isoline_aver');
	datafile = [projPath, resultsFolder, filename, '0.mat'];
	% }}}
	%GET save filename: Arates_thd0_FC_Obs_Isoline_aver{{{
	sfilename = getfieldvalue(options, 'save filename', filename);
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET time windows: [12, 30, 60, 90, 180]{{{
	timeWindows= getfieldvalue(options, 'time windows', [12, 30, 60, 90, 180]);
	% }}}
	%GET dataname: cmRates{{{
	dataname = getfieldvalue(options, 'data name', 'aRateC');
	% }}}

	%% load model {{{
	disp(['    Loading ablation rate without smoothing from ', datafile])
	nsdata=load(datafile);
	if isfield(nsdata, dataname)
		data = eval(['nsdata.', dataname]);
	else
		error(['Unknown data name ', dataname])
	end

	xDist = nsdata.xDist;
	% remove nan
	data(isnan(data))=0;
	%}}}
	% moving average{{{
	for i = 1: length(timeWindows)
		disp(['    Averaging ablation rate with time window=', num2str(timeWindows(i))]);

		smoothdata = movingAverage([data;nsdata.time], 'time window', timeWindows(i), 'resample', 0);
		eval([dataname, ' = smoothdata(1:end-1,:);']);
		
		time = smoothdata(end,:);

		% save 
		if saveFlag
			saveFilename = [projPath, resultsFolder, sfilename, num2str(timeWindows(i)), '.mat'];
			disp(['    Saving ablation rate to ', saveFilename]);
			eval(['save([saveFilename], ''', dataname, ''' , ''time'', ''xDist'');'] )
		end
	end
	%}}}
