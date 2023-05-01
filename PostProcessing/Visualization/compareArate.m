% compare the frontal ablation rate
%	
% Last modified: 2023-05-01

function compareArate(varargin)
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
	%GET fileList Arates_thd0_FC_Model_Isoline_aver0{{{
	fileList = getfieldvalue(options, 'fileList', {'Arates_thd0_FC_Model_Isoline_aver0'});
	% }}}
	%GET titleList 'Model'{{{
	titleList = getfieldvalue(options, 'titleList', {'Model'});
	% }}}
	%GET parameter range{{{
	ca = getfieldvalue(options, 'caxis', [0, 1.5e4]);
	% }}}

	% load each arate file{{{
	Nfile = length(fileList);
	for i = 1:Nfile
		datafile = [projPath, resultsFolder, fileList{i}, '.mat'];
		disp(['    Loading isoline data from ', datafile])
		data{i} = load(datafile);
	end
	%}}}
	% Plot {{{
	figure('position', [0,800,800,1000])
	for i = 1:Nfile
		subplot(Nfile, 1, i)
		imagesc(data{i}.time, data{i}.xDist, data{i}.aRateC);
		colormap(jet)
		colorbar
		title(titleList{i})
		caxis(ca)
	end
	figure('position', [0,800,800,1000])
	for i = 1:Nfile
		subplot(Nfile, 1, i)
		if i > 1
			imagesc(data{i}.time, data{i}.xDist, data{i}.aRateC-data{1}.aRateC);
			title([titleList{i}, ' - ', titleList{1}])
			caxis([-2e3,2e3])
		else
			imagesc(data{i}.time, data{i}.xDist, data{i}.aRateC);
			title(titleList{i})
			caxis(ca)
		end
		colormap(jet)
		colorbar
	end
	%}}}
