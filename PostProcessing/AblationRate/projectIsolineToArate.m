% Project the isoline aRate back to the whole mesh
%	
% Last modified: 2023-04-27

function projectIsolineToArate(varargin)
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
	%GET data filename: Arates_Obs_Isoline_aver0{{{
	datafilename = getfieldvalue(options, 'data filename', 'Arates_Obs_Isoline_aver0');
	% }}}
	%GET save filename: Arates_Obs_projected{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs_projected');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET flowline contour: flowlineContour{{{
	flowlineContourExp = getfieldvalue(options, 'flowline contour', 'flowlineContour');
	% }}}

	% load model {{{
	disp(['    Loading reference model']);
	md = loadRefMd();

	% load C-flowline contour
	expfile = [projPath, '/PostProcessing/Results/', flowlineContourExp, '.exp'];
	disp(['    Loading flowline contour from ', expfile])
	flowlineLevelset = ExpToLevelSet(md.mesh.x, md.mesh.y, expfile);

	% load arate data
	aratedatafile = [projPath, resultsFolder, datafilename, '.mat']; 
	disp(['    Loading ablation rate from ', aratedatafile])
	aratedata = load([aratedatafile]);
	time = aratedata.time;
	xDist = aratedata.xDist;
	aRate = aratedata.aRateC;
	Nt = numel(time);
	aRate(isnan(aRate)) = 0;
	disp('    Loading model done!'); %}}}
% project back to the mesh {{{
aRateOnMesh = zeros(md.mesh.numberofvertices, Nt);
for i =1:Nt
	aRateOnMesh(:,i) = interp1(xDist, aRate(:,i), flowlineLevelset, 'linear');
end
nanFlag = isnan(aRateOnMesh);
aRateOnMesh(nanFlag) = 0;
%}}}
%% save {{{
if saveFlag
	saveFilename = [projPath, resultsFolder, sfilename];
	disp(['    Saving aRateC to ', saveFilename]);
	save([saveFilename, '.mat'],	'time', 'aRateOnMesh');
end
%}}}
