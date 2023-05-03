% To compute the parameterization using ablation rate
% 
% Last Modified: 2023-05-03

function getArateParams(varargin)
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
	reffile = [projPath, resultsFolder, filename, '_aver0.mat'];
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
	%GET title : ''{{{
	titleText = getfieldvalue(options,'title', ''); 
	% }}}
	%GET showCurveFit : 1{{{
	showCurveFit = getfieldvalue(options,'show curve fit', 1); 
	% }}}
	%GET color : 1{{{
	color = getfieldvalue(options,'color', []); 
	% }}}

	% load model {{{
disp(['    Loading reference without smoothing from ', reffile])
refdata=load(reffile);
disp('   Use bed elevation for x-axis');
BedC = refdata.BedC;
xname = 'Bed elevation (m)';
Bed = BedC(:);
%}}}
% Set mask {{{
disp(['    Loading ablation rate from ', datafile])
nsdata=load(datafile);
maxArateC = max(nsdata.aRateC);
nAc = nsdata.aRateC ./ maxArateC;
nanFlag = isnan(nsdata.aRateC) | isnan(refdata.BedC);
nanFlag = nanFlag | (refdata.VelC<200);
nAc(nanFlag) = NaN;
param = nAc ./ BedC;
param(BedC>-10) = NaN;
param(param<-0.005) = NaN;
%}}}
% compute hist for each year {{{
time = nsdata.time;
Nst = 200;
Nyears = ceil(numel(time)/Nst);

figure('Position', [0, 800, 1000, 800])
for i = 1:Nyears
   subplot(4,4,i)
   tempP = param(:,[1+(i-1)*Nst:i*Nst]);
   histfit(tempP(:), 1000, 'normal')
   dist(i) = fitdist(tempP(:), 'normal');
   title(['median=', num2str(median(tempP(:), 'omitnan'))])
   xlim([-0.005,0])
end
totaldist = fitdist(param(:), 'normal');
figure('Position', [950, 800, 400, 800])
errorbar([2007:2019], [dist(:).mu], [dist(:).sigma])
ylim([-0.005, 0])
hold on
plot([2007,2019], [totaldist.mu,totaldist.mu])
title(['mu=', num2str(totaldist.mu)])
%}}}
