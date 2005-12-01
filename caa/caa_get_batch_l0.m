function caa_get_batch_l0(iso_t,dt,cl_id,sdir,srcvars)
%CAA_GET_BATCH_L1 CAA get L0 data by CaaRunner
%
% caa_get_batch_l0(iso_t,dt,cl_id,sdir,srcvars)
%
% Input: iso_t - ISO epoch
%           dt - length of time interval in sec
%        cl_id - Cluster ID
%         sdir - directory to save the data   
%      srcvars - see help ClusterProc/getData, ex. 'dies|die'
%
% $Id$

% Copyright 2005 Yuri Khotyaintsev

error(nargchk(5,5,nargin))

sc_list = cl_id;

REQ_INT = 60; % Intervals (sec) for which we request FDM
SPLIT_INT = 90*60; % Typical interval length (sec)
MAX_SKIP = 2; % Number of NM frames we skip after BM interval

DB_S = c_ctl(0,'isdat_db');
DP_S = c_ctl(0,'data_path');

% Create the storage directory if it does not exist
if ~exist(sdir, 'dir')
	[SUCCESS,MESSAGE,MESSAGEID] = mkdir(sdir);
	if SUCCESS, irf_log('save',['Created storage directory ' sdir])
	else, error(MESSAGE)
	end
end

st = iso2epoch(iso_t);

% First we check if we have any EFW HX data
% and check for NM/BM1
count_skip = 0;
for cl_id=sc_list
	st_tmp = st;
	tm = []; tm_prev = [];
	
	while st_tmp<st+dt
		
		[t,data] = caa_is_get(DB_S,st_tmp,REQ_INT,cl_id,'efw','FDM');
		if ~isempty(data), tm_cur = data(5,1);
		else
			irf_log('dsrc',['No FDM for C' num2str(cl_id) ...
				' at ' epoch2iso(st_tmp,1)])
			tm_cur = -1;
		end
		
		% First frame is directly good, probably we started in the middle of
		% good interval
		if isempty(tm_prev) & tm_cur>=0
			tm(end+1,:) = [st_tmp tm_cur];
		end
		
		if tm_prev~=tm_cur & tm_cur>=0
			% We skip MAX_SKIP frames of NM because it is folliwing 
			% BM1 or data gap and usually contains junk
			if tm_cur==0 & count_skip<MAX_SKIP
				tm_cur = -2;
				count_skip = count_skip + 1;
				irf_log('proc',['Skipping one NM frame for C' num2str(cl_id)...
					' at ' epoch2iso(st_tmp,1)])
			else
				tm(end+1,:) = [st_tmp tm_cur];
				count_skip = 0;
			end
		else, count_skip = 0;
		end
		
		st_tmp = st_tmp + REQ_INT;
		tm_prev = tm_cur;
	end
	
	% Throw away all modes>1
	if ~isempty(tm)
		ii_out = find(tm(:,2)>1);
		if ~isempty(ii_out)
			irf_log('proc',sprintf('Removing %d intervals TM>1 for C%d',...
				length(ii_out),cl_id))
			tm(ii_out,:) = [];
		end
	end
	c_eval('tm? = tm;',cl_id)
end
clear tm tm_cur

% Make SC_LIST from SC for which TM is not empty 
sc_list = [];
c_eval('if exist(''tm?'',''var''),if ~isempty(tm?), sc_list = [sc_list ?]; end, end')

if isempty(sc_list), irf_log('dsrc','No data'), return, end

for cl_id=sc_list
	cdir = [sdir '/C' num2str(cl_id)];
	if ~exist(cdir, 'dir')
		[SUCCESS,MESSAGE,MESSAGEID] = mkdir(cdir);
		if SUCCESS, irf_log('save',['Created storage directory ' cdir])
		else, error(MESSAGE)
		end
	end
	c_eval('tm=tm?;',cl_id);
	
	% Split long intervals into SPLIT_INT chunks
	j = 1;
	while 1
		st_tmp = tm(j,1);
		tm_cur = tm(j,2);
		if j==size(tm,1), dt_tmp = st + dt - st_tmp;
		else, dt_tmp = tm(j+1,1) - st_tmp;
		end
		% For BM1 we take SPLIT_INT/3 intervals
		if dt_tmp > SPLIT_INT*4/3*(1-tm_cur*2/3)
			if j==size(tm,1)
				tm(j+1,:) = [tm(j,1)+SPLIT_INT*(1-tm_cur*2/3) tm(j,2)];
			else
				tm(j+1:end+1,:) = [tm(j,1)+SPLIT_INT*(1-tm_cur*2/3) tm(j,2); tm(j+1:end,:)];
			end
		end
		if j>=size(tm,1), break
		else, j = j + 1;
		end
	end
	
	for inter=1:size(tm,1)
		t1 = tm(inter,1);
		if inter==size(tm,1), dt1 = st +dt -t1;
		else, dt1 = tm(inter+1,1) -t1;
		end
		if inter~=1 & inter~=size(tm,1) & dt1<500
			irf_log('proc',['C' num2str(cl_id) ' skipping ' ...
				epoch2iso(t1,1) ' - ' epoch2iso(t1+dt1,1)])
		else
			irf_log('proc',['C' num2str(cl_id) ' interval ' ...
				epoch2iso(t1,1) ' - ' epoch2iso(t1+dt1,1)])
		end
		
		% Get data
		c_get_batch(t1,dt1,'db',DB_S,'sc_list',cl_id,'sdir',cdir,'vars',srcvars,'noproc') 	
	end
end

