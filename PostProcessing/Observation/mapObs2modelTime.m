% map velocity obs to the nearest time point, NO interpolation in space, or time, leave NaN as it is
%
% Last modified: 2022-08-23
function mapObs2modelTime(varargin)
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
	%GET start time{{{
	tStart = getfieldvalue(options, 'start time', 2007);
	% }}}
	%GET end time{{{
	tEnd = getfieldvalue(options, 'end time', 2020);
	% }}}
	%GET dt{{{
	dt = getfieldvalue(options, 'dt', 0.005);
	% }}}
	%GET data filename: velObs_onmesh{{{
	datafilename = getfieldvalue(options, 'data filename', 'velObs_onmesh');
	% }}}
	%GET save filename: timeSeries_Model_onmesh{{{
	sfilename = getfieldvalue(options, 'save filename', 'timeSeries_Obs_mapped');
	% }}}
	%GET isSave: 1{{{
	saveflag = getfieldvalue(options, 'isSave', 1);
	% }}}


	% settings {{{
	time = linspace(tStart+dt, tEnd, (tEnd-tStart)/dt);
	%}}}
	% load obs mat{{{
	datafile = [projPath, resultsFolder, datafilename, '.mat'];
	disp(['Loading velocity obs from ', datafile]);
	load(datafile);
	%}}}
	%% map the obs to the time series in transient simulation {{{
	% Take unique
	[time_uni,ind_uni] = unique((TStart+TEnd)./2);
	vx_uni = vx_onmesh(:,ind_uni);
	vy_uni = vy_onmesh(:,ind_uni);
	vel_uni = vel_onmesh(:,ind_uni);

	% sort
	[time_sort, ind] = sort(time_uni);
	vx_sort = vx_uni(:,ind);
	vy_sort = vy_uni(:,ind);
	vel_sort = vel_uni(:,ind);

	% project obs to the time series of model
	[Nx, Ntdata] = size(vx_onmesh);
	Nt = length(time);

	vx_obs = NaN(Nx, Nt);
	vy_obs = NaN(Nx, Nt);
	vel_obs = NaN(Nx, Nt);
	timeTracker = ones(1, Nt);

	% interpolate
	disp(['Map the obs velocity to the closest time point']);


	for i = 1:Ntdata
		% find the closest time point in the time series
		[~, tempId] = min(abs(time-time_sort(i)));
		if timeTracker(tempId)
			disp(['--> Mapping from ', num2str(time_sort(i)), ' to ', num2str(time(tempId))]);
			vx_obs(:, tempId) = vx_sort(:, i);
			vy_obs(:, tempId) = vy_sort(:, i);
			vel_obs(:, tempId) = vel_sort(:, i);
			timeTracker(tempId) = 0;
		end
	end
	disp(['Mapping done!']);

	%}}}
	%% save the data {{{
	if saveflag
		saveFilename = [projPath, resultsFolder, sfilename, '.mat'];
		disp(['Saving the results to ', saveFilename]);
		save(saveFilename, 'time', 'vx_obs', 'vy_obs', 'vel_obs');
	end %}}}
