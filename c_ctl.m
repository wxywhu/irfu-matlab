function c_ctl(varargin)
%C_CTL Cluster control
%
% $Id$

default_mcctl_path = '';

if nargin<1, c_ctl_usage, return, end
args = varargin;

if isstr(args{1})
	if strcmp(args{1},'init')
		if nargin>=2
			d = args{2};
			if exist(d,'dir')
				if exist([d '/mcctl.mat'])
					clear global c_ct; global c_ct
					eval(['load ' d '/mcctl.mat'])
				else
					error(['No mcctl.mat in ' d])
				end
			elseif exist(d,'file')
				clear global c_ct; global c_ct
				eval(['load ' d])
			else
				error(['Directory or file ' d ' does not exist'])
			end
		else
			clear global c_ct; global c_ct
			if exist([d '/mcctl.mat'])
				eval(['load ' default_mcctl_path '/mcctl.mat'])
			else
				% init with defaults
				def_ct.ns_ops = [];
				def_ct.ang_lim = 15;
				c_ct{1} = def_ct;
				c_ct{2} = def_ct;
				c_ct{3} = def_ct;
				c_ct{4} = def_ct;
				clear def_ct
			end
		end
	elseif strcmp(args{1},'load_ns_ops')
		global c_ct
		if isempty(c_ct), c_ctl('init'), end
		
		if nargin>1, d = args{2};
		else, d = '.';
		end
		
		for j=1:4
			try 
				f_name = [d '/ns_ops_c' num2str(j) '.dat'];
				if exist(f_name,'file')
					eval(['c_ct{j}.ns_ops=load(''' f_name ''',''-ascii'');'])
					
					% remove lines with undefined dt
					c_ct{j}.ns_ops(find(c_ct{j}.ns_ops(:,2)==-157),:) = [];
				end
			catch
				disp(lasterr)
			end
		end
		
	elseif strcmp(args{1},'save')
		global c_ct
		if isempty(c_ct), disp('CTL is not initialized.'), return, end
		
		if nargin>1
			d = args{2};
			if exist(d,'dir')
				disp(['Saving ' d '/mcctl.mat'])
				eval(['save -MAT ' d '/mcctl.mat c_ct'])
			else
				disp(['Saving ' d])
				eval(['save -MAT ' d ' c_ct'])
			end
		else
			disp('Saving mcctl.mat')
			save -MAT mcctl.mat c_ct
		end
	else
		error('Invalid argument')
	end
elseif isnumeric(args{1})
	sc_list = args{1};
	if nargin>1, have_options = 1; args = args(2:end);
	else, have_options = 0; args = '';
	end
	
	global c_ct
	if isempty(c_ct), c_ctl('init'), end
	
	while have_options
		if length(args)>1
			if isstr(args{1})
				try
					for j=sc_list
						%disp(j)
						%disp(['c_ct{j}.' args{1} '=args{2};'])
						eval(['c_ct{j}.' args{1} '=args{2};'])
					end
				catch
					disp(lasterr)
					error('bad option')
				end
			else
				error('option must be a string')
			end
			if length(args) >= 2
				args = args(3:end);
				if length(args) == 0, break, end
			else break
			end
		else
			disp('Usage: c_ctl(sc_list,''ctl'',value)')
			break
		end
	end
else
	error('Invalid argument')
end

function c_ctl_usage
	disp('Usage:')
	disp('  c_ctl(''init'')')
	disp('  c_ctl(''init'',''/path/to/mcctl.mat/'')')
	disp('  c_ctl(''init'',''/path/to/alternative_mcctl.mat'')')
	disp('  c_ctl(''load_ns_ops'')')
	disp('  c_ctl(''load_ns_ops'',''/path/to/ns_ops_cN.dat/'')')
	disp('  c_ctl(''save'')')
	disp('  c_ctl(''save'',''/path/to/mcctl.mat/'')')
	disp('  c_ctl(''save'',''/path/to/alternative_mcctl.mat'')')
	disp('  c_ctl(''sc_list'',''ctl'',value)')
