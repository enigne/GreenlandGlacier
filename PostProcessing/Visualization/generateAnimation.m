% Generate animations 
% Last modified: 2022-06-21

function generateAnimation(varargin)

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
	%GET figures folder : './PostProcessing/Figures/'{{{
	figuresFolder = getfieldvalue(options,'figures folder','./PostProcessing/Figures/');
	% }}}
	%GET Id : 0{{{
	Id = getfieldvalue(options,'Id', 0);
	% }}}
	%GET movie name : ''{{{
	movieSuffix = getfieldvalue(options,'movie name', '');
	movieName = [projPath, 'PostProcessing/Figures/Animations/', glacier, '_', movieSuffix];
	% }}}
	%GET nRows : 1{{{
	nRows = getfieldvalue(options,'nRows', 1);
	% }}}
	%GET nCols : 1{{{
	nCols = getfieldvalue(options,'nCols', 1);
	% }}}
	%GET index : [1]{{{
	subind = getfieldvalue(options,'index', [1]);
	% }}}
	%GET frame step : 2 {{{
	nstep = getfieldvalue(options,'frame step', 10);
	% }}}
	%GET load obs : true {{{
	flagObs = getfieldvalue(options,'load obs', 1);
	% }}}
	%GET xlim and ylim : []{{{
	xl = getfieldvalue(options,'xlim', []);
	yl = getfieldvalue(options,'ylim', []);
	% }}}
	%GET ca for caxis [0, 1e4]{{{
	ca = getfieldvalue(options,'caxis', [0, 1e4]);
	% }}}

	%% Load data {{{
	[folderList, titleList] = getFolderList(Id, flagObs);

	% change the name, since we are going to use the ref model for the calving front position only
	if flagObs 
		titleList(1) = {'Observation'};
	end

	% Load simulations from compareToObs.mat
	outSol = loadData(folderList, 'velocity', [projPath, 'Models/']);
	% load model
	md = loadRefMd([projPath, 'Models/'], 'Param');
	% Load observation data
	obsdata = load([projPath, 'PostProcessing/Results/timeSeries_Obs_onmesh.mat']);
	% Load flowlines
	load([projPath, 'PostProcessing/Results/flowlines_', glacier, '_50.mat']);
	%}}}
	%% Get all the velocity {{{
	vx = cellfun(@(x)x.vx, {outSol{:}}, 'UniformOutput', 0);
	vy = cellfun(@(x)x.vy, {outSol{:}}, 'UniformOutput', 0);
	icemask = cellfun(@(x)x.ice_levelset, {outSol{:}}, 'UniformOutput', 0);

	% put obs at the beginning
	if flagObs
		vx(1) = {obsdata.vx_obs};
		vy(1) = {obsdata.vy_obs};
		time = outSol{2}.time;
	else
		time = outSol{1}.time;
	end
	time_obs = obsdata.time;
	if length(time) < length(time_obs)
		time = time_obs;
	end
	vel = cellfun(@(x,y)sqrt(x.^2+y.^2), vx, vy, 'UniformOutput', 0);
	%}}}
	%% Create Movie for friction and ice rheology {{{
	set(0,'defaultfigurecolor',[1, 1, 1])
	Nt = length(time);
	Nobs = length(time_obs);
	Ndata = length(vel);
	nframes = floor(Nt/nstep);

	clear mov;
	close all;
	figure('position',[0,500,1000,1200])
	mov(1:nframes) = struct('cdata', [],'colormap', []);
	count = 1;
	for i = 1:nstep:Nt
		for j = 1:Ndata	
			if (i <= size(vel{j}, 2))
				plotmodel(md,'data', vel{j}(:,i),...
					'ylim', yl, 'xlim', xl,...
					'levelset', icemask{j}(:,i), 'gridded', 1,...
					'caxis', ca, 'colorbar', 'off',...
					'xtick', [], 'ytick', [], ...
					'tightsubplot#all', 1,...
					'hmargin#all', [0.01,0.0], 'vmargin#all',[0,0.06], 'gap#all',[.0 .0],...
					'subplot', [nRows,nCols,subind(j)]);
				title(titleList{j}, 'interpreter','latex')
				set(gca,'fontsize',12);
				set(colorbar,'visible','off')
			end
		end
		h = colorbar('Position', [0.1 0.9  0.75  0.01], 'Location', 'northoutside');
		title(h, datestr( decyear2date(time(i)), 'yyyy-mm-dd'))
		colormap('jet')
		img = getframe(1);
		img = img.cdata;
		mov(count) = im2frame(img);
		set(h, 'visible','off');
		clear h;
		fprintf(['step ', num2str(count),' done\n']);
		count = count+1;
		clf;
	end
	% create video writer object
	writerObj = VideoWriter([movieName, '.avi']);
	% set the frame rate to one frame per second
	set(writerObj,'FrameRate', 20);
	% open the writer
	open(writerObj);

	for i=1:nframes
		img = frame2im(mov(i));
		[imind,cm] = rgb2ind(img,256,'dither');
		% convert the image to a frame using im2frame
		frame = im2frame(img);
		% write the frame to the video
		writeVideo(writerObj,frame);
	end
	close(writerObj);
	command = sprintf('ffmpeg -y -i %s.avi -c:v libx264 -crf 19 -preset slow -c:a libfaac -b:a 192k -ac 2 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" %s.mp4', movieName, movieName);
	system(command);
	%}}}
