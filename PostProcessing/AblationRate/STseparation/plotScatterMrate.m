% plotScatterMrate - plot inferred ablation rate at the calving front vs. other quantities
%
% Author: Cheng Gong
% Last modified: 2022-06-19
function x = plotScatterMrate(varargin)
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
	%GET figures folder : './PostProcessing/Figures/'{{{
	figuresFolder = getfieldvalue(options,'figures folder','./PostProcessing/Figures/');
	% }}}
	%GET data filename: Arates_Obs_Isoline_aver{{{
	datafilename = getfieldvalue(options, 'data filename', 'Arates_Obs_Isoline_aver');
	% }}}
	%GET save filename: obs_aver{{{
	sfigurename = getfieldvalue(options, 'save filename', 'obs_aver');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET time windows: [0, 12, 30, 60, 90]{{{
	timeWindows= getfieldvalue(options, 'time windows', [0, 12, 30, 60, 90]);
	% }}}
	%GET time step per year  {{{
	timestepInyear = getfieldvalue(options,'time steps per year', 200);
	% }}}
	%GET Index of x-axis{{{
	xdataInd = getfieldvalue(options,'xdata', 1); % 1-BedC, 2-HC, 3-sigmaVMC, 4-velC, 5-Hab, 6-TF, 7-isoline data
	% }}}
	%GET xRange {{{
	xRange = getfieldvalue(options,'xRange', []); 
	if isempty(xRange)
		error('need to set the range of x')
	end
	% }}}
	%GET x0 {{{
	x0 = getfieldvalue(options,'x0', []); 
	if isempty(x0)
		error('need to set an initial guess')
	end
	% }}}
	%GET y data id {{{
	ydataInd = getfieldvalue(options,'ydata', 1); % 1-max, 2-mean, 3-max then log, 4-isoline data
	% }}}
	%GET number of columns {{{
	Ncols = getfieldvalue(options,'number of columns', 3);
	% }}}
	%GET number of years for averaging {{{
	Navg = getfieldvalue(options, 'years averaging', 1);
	% }}}
	%GET flowlines to include {{{
	flowlines = getfieldvalue(options,'flowlines', [1:50]);
	% }}}
	%GET calving function handler {{{
	calvingfunc = getfieldvalue(options,'calving function', @calvingTanh);
	% }}}
	%GET scatter density plot{{{
	scatterDensity = getfieldvalue(options,'scatter density', 1); % 1-density plot, 0-use time/flowline index/etc for color
	if scatterDensity == 0
		cInd = getfieldvalue(options,'cdata', 1); % 1-time, 2-flowline index
	end
	% }}}


	% go through all the time windows data {{{
	for tw = 1:length(timeWindows)
		%% load data {{{
		datafile = [projPath, resultsFolder, datafilename, num2str(timeWindows(tw))];
		disp(['    Loading mRate data from ', datafile]);
		mdata = load(datafile);
		disp('    Loading complete');

		if saveFlag
			nameprefix = [projPath, figuresFolder, sfigurename, num2str(timeWindows(tw))];
		end
		if xdataInd < 7
			time = mdata.time;
			Ntime = length(mdata.time);
			Nyear = floor(Ntime/timestepInyear);
			disp(['       Data is from ', num2str(mdata.time(1)), ' to ', num2str(mdata.time(end)), ', in total ', num2str(Nyear), ' years.']);
		else
			Ntime = max(mdata.timeC);
			Nyear = floor(Ntime/timestepInyear);
		end
		%}}}
		% set xdata {{{
		if xdataInd == 1
			disp('   Use bed elevation for x-axis');
			xdata = mdata.BedC;
			%xmin = -1000; xmax = 100;
			xmin = xRange(1);
			xmax = xRange(2);
			xlb = 'bed (m)';
			name = 'bed';
			%x0 = [0.8, 200, 450];
			%x0 = [-0.1, 400, 450];
		elseif xdataInd == 2
			disp('   Use ice thickness for x-axis');
			xdata = mdata.HC;
			xmin = min(xdata(:));	xmax = max(xdata(:));
			xlb = 'H (m)';
			name = 'H';
			x0 = [0.8, -200, -400];
		elseif xdataInd == 3
			disp('   Use von-Mises tensor stress for x-axis');
			xdata = mdata.sigmaVMC;
			%		xmin = min(xdata(:));	xmax = max(xdata(:));
			xmin = 1e5; xmax = 12e5;
			xlb = 'sigamVM';
			name = 'sigmaVM';
			x0 = [55, 2e6, -5e6];
		elseif xdataInd == 4
			disp('   Use surface velocity for x-axis');
			xdata = mdata.velC;
			xmin = min(xdata(:));	xmax = max(xdata(:));
			xlb = 'vel (m/a)';
			name = 'vel';
			x0 = [0.8, -4000, -3000];
		elseif xdataInd == 5
			disp('   Use height above floatation for x-axis');
			rho_ice = 917;
			rho_water = 1023;
			xdata = mdata.HC - rho_water/rho_ice*(0-mdata.BedC); 
			xmin = 0; xmax = 100;
			xlb = 'Hab (m)';
			name = 'Hab';
			x0 = [0.8, 40, -10];
		elseif xdataInd == 6
			disp('   Use thermal forcing for x-axis');
			xdata = mdata.TFC;
			xmin = min(xdata(:));	xmax = max(xdata(:));
			xlb = 'Thermal forcing';
			name = 'TF';
			x0 = [0.8, 7, 20];
		elseif xdataInd == 7
			disp('   Use isoline bed elevation for x-axis');
			xdata = mdata.BedC(:);
			timedata = mdata.timeC(:);
			xmin = -1000; xmax = 0;
			xlb = 'bed (m)';
			name = 'bed';
			x0 = [-0.1, 200, 450];
		else
			error('missing xdata');
		end
		%}}}
		% set ydata {{{
		if ydataInd == 1
			disp(['   Normalize mRate with max value at each time step']);
			ydata = mdata.aRateC ./ max(mdata.aRateC);
			ymin = 0;
			ymax = 1;
			ylb = 'normalized Arate';
			assert(sum((ydata(:)>1))==0, 'The normalization did not work!');
		elseif ydataInd == 2
			disp(['   Normalize mRate with mean value at each time step']);
			ydata = mdata.aRateC ./ mean(mdata.aRateC);
			ylb = 'normalized Arate by mean';
			ymin = 0;
			ymax = 2;
		elseif ydataInd == 3
			disp(['   Normalize mRate with max value at each time step, then take logrithm']);
			ydata = mdata.aRateC ./ max(mdata.aRateC);
			ylb = 'log normalized Arate';
			assert(sum((ydata(:)>1))==0, 'The normalization did not work!');
			ydata = log(abs(ydata)+1e-16)/log(10);
			ymin = -5;
			ymax = 0;
		elseif ydataInd == 4
			disp(['   Use isoline aRate']);
			ydata = mdata.aRateC./max(mdata.aRateC);
			ydata = ydata(:);
			ylb = 'normalized Arate';
			ymin = 0;
			ymax = 1;
		else
			disp(['   No normalization is done for mRate']);
			ydata = mdata.aRateC(:);
			ylb = 'Arate';
			ymin = 0;
			ymax = 1e4;
		end
		%}}}
		% set cdata {{{
		if scatterDensity
			cdata = xdata;
		else
			if cInd == 1
				disp('   Use time for color');
				cdata = time;
			elseif cInd == 2
				disp('   Use ice thickness for x-axis');
				cdata = repmat([1:Nflowlines]',1,Ntime); 
			else
				error('missing color data');
			end
		end
		%}}}
		%% visualize {{{
		Nfigs = Nyear - Navg+1;
		Nrows = ceil(Nfigs/Ncols);
		% separate each year
		figure('Position', [0,500,1000,800])
		set(gcf,'color','w');
		colormap(hsv);
		x = zeros(Nfigs+1, 3);
		for i = 1:Nfigs
			subplot(Nrows, Ncols, i);
			% time sequence
			if xdataInd == 7
				timeseq = (timedata>(i-1)*timestepInyear) & (timedata<= (i+Navg-1)*timestepInyear);
				xtemp = xdata(timeseq);
				ytemp = ydata(timeseq);
				ctemp = cdata(timeseq);
			else
				timeseq = [1+(i-1)*timestepInyear:(i+Navg-1)*timestepInyear];
				xtemp = xdata(:, timeseq);
				ytemp = ydata(:, timeseq);
				ctemp = cdata(:, timeseq);
			end
			% remove Nan from temp data
			nanFlag = ~(isnan(xtemp)|isnan(ytemp)); 
			xtemp = xtemp(nanFlag);
			ytemp = ytemp(nanFlag);
			% plot
			if scatterDensity
				dscatter(xtemp(:), ytemp(:));
			else
				scatter(xtemp(:), ytemp(:), 1, ctemp(:));
			end
			if Navg == 1
				title([num2str(floor(mdata.time(1)+i-1))]);
			else
				title([num2str(floor(mdata.time(1)+i-1)), '--', num2str(floor(mdata.time(1)+i+Navg-2))]);
			end
			xlim([xmin, xmax])
			ylim([ymin, ymax])
			xlabel(xlb)
			ylabel(ylb)
			caxis([0, 0.5])

			x(i,:) = curvefitting('xdata', xtemp, 'ydata', ytemp, 'x0', x0, 'func', calvingfunc, 'xmin', xmin, 'xmax', xmax);
		end
		%save
		if saveFlag
			saveName = [nameprefix, '_individual_', name, '.pdf'];
			disp(['   Saving each year to ', saveName]);
			export_fig(saveName);
		end

		% plot everything in the same figure
		% remove Nan from data
		nanFlag = ~(isnan(xdata)|isnan(ydata)); 
		xdata = xdata(nanFlag);
		ydata = ydata(nanFlag);
		figure('Position', [1000,500,500,400])
		set(gcf,'color','w');
		colormap(hsv);
		if scatterDensity
			dscatter(xdata(:), ydata(:));
		else
			scatter(xdata(:), ydata(:), 1, cdata(:));
			% add legend
			colorbar;
		end
		xlim([xmin, xmax])
		ylim([ymin, ymax])
		xlabel(xlb)
		ylabel(ylb)
		title([num2str(floor(mdata.time(1))), '--', num2str(ceil(mdata.time(end)))]);
		caxis([0,0.5])
		% curve fitting {{{
		x(Nfigs+1,:) = curvefitting('xdata', xdata, 'ydata', ydata, 'x0', x0, 'func', calvingfunc, 'xmin', xmin, 'xmax', xmax);
		%}}}	
		%save
		if saveFlag
			saveName = [nameprefix, '_all_', name, '.pdf'];
			disp(['   Saving all the years to ', saveName]);
			export_fig(saveName);
		end
		%}}}
	end %}}}
