function flag=c_ri_get_event_data(time_interval,path_Events,path_Out, data_list, dt_interval)
%function flag=c_ri_get_event_data(time_interval,path_Events,path_Out, data_list, dt_interval)
%
%Input:
%   time_interval - [start_time end_time] in isdat_epoch 
%   path_Events - where to look for Events files (files start with "E_")
%   path_Out    - where to write the data, ends with '/'
%   data_list   - structure with values of which data to load, e.g. {'EFW_E','EFW_P'}
%   dt_interval - download +- dt_interval seconds around event (default 5s)
%Output:
%   flag = matrix with one row per event and one column for every data kind (1/0 for sucessfull download)
%
%Descrition of the function:
%   Loads the specified data for each event in the given time interval
%
%Using:
%   
%Work method:
%
%Error:
% 
%Discription of variables:
% eventsw   - 1 event per row, 3 columns [start_time end_time s/c_mode(1-burst, 0-normal)]
%
%Written by Andris Vaivads Sep 2003

%--------------------- the beginning --------------------------
sc_list=1:4; % get data for all 4 s/c
isdat_database='disco:10'; % 
db = Mat_DbOpen(isdat_database);

if nargin==0, help c_ri_get_event_data; return; end
if nargin==1, path_Events=[pwd filesep];path_Out=[pwd  filesep];data_list={'EFW_P'};dt_interval=5;end
if nargin==2, path_Out=[pwd  filesep];data_list={'EFW_P'};dt_interval=5;end
if nargin==3, data_list={'EFW_P'};dt_interval=5;end
if nargin==4, dt_interval=5;end
default_cases={'EPH'};
data_list=[default_cases data_list ]; % ephemeris should be first

dir_list=dir([p_E 'E_' '*.mat'])

start_time=time_interval(1);
end_time=time_interval(2);

event_time_intervals=[]; % three columns [start_time end_time mode]; mode=0(normal), 1(burst)
next_event_row=1;

% construct time intervals to download, time intervals are in whole seconds
for i_Event_file=1:size(dir_list,1),
  event_file = dir_list(i_Event_file).name;
  load([path_Events event_file]); % load time_of_events variable
  flag_time_within_interval=sign((end_time-time_of_events(:,1)).*(time_of_events(:,1)-start_time));
  ind_events=find(flag_time_within_interval == 1);
  if ind_events,
    found_events=[floor(time_of_events(ind_events,1)-dt_interval) ceil(time_of_events(ind_events,1)+dt_interval) time_of_events(ind_events,5)];
    event_time_intervals(next_event_row+[0 size(found_events,1)-1],:)=found_events;
  end
end
disp(['Found ' size(event_time_intervals,1) 'events.']);

% clean up overlapping time intervals
events=event_time_intervals(1,:);i_final_events=1;
for i_event=2:size(event_time_intervals,1),
  if event_time_intervals(i_event,1)<=events(i_final_events,2),
    events(i_final_events,2)=event_time_intervals(i_event,2);
  else
    i_final_events=i_final_events+1;
    events(i_final_events,:)=event_time_intervals(i_event,:);
  end
end
disp(['From ' size(event_time_intervals,1) ' events ' size(event_time_intervals,1)-size(events,1) ' events were overlapping']);

if exist('mWork.mat'), save -append mWork events, else save mWork events; end

for i_event=1:size(event,1),
  start_time=event(i_event,1);
  end_time  =event(i_event,2);
  time_interval=[start_time end_time];
  Dt        =end_time-start_time;
  sc_mode   =event(i_event,3);
  for i_data=1:length(data_list),
    switch data_list{i_data}
    case 'EPH' % get ephemeris R,V,A,ILAT,MLT,satellite axis orientation
      file_prefix='EPH_';
      file_name=[path_out file_prefix deblank(R_datestring(start_time)) '_to_' deblank(R_datestring(end_time))];
      for ic=sc_list, 
        [tlt,lt] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'lt', ' ', ' ', ' ');
        [tmlt,mlt] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'mlt', ' ', ' ', ' ');
        [tL,Lshell] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'l_shell', ' ', ' ', ' ');
        [tilat,ilat] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'inv_lat', ' ', ' ', ' ');
        [tr,r] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'position', ' ', ' ', ' ');
        [tv,v] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'velocity', ' ', ' ', ' ');
        [tA,A] = isGetDataLite( db, start_time, Dt,'Cluster', num2str(ic), 'ephemeris', 'phase', ' ', ' ', ' ');
        eval(av_ssub('A?=[double(tA) double(A)];',ic));
        eval(av_ssub('LT?=[double(tlt) double(lt)];MLT?=[double(tmlt) double(mlt)];L?=[double(tL) double(Lshell)];ILAT?=[double(tilat) double(ilat)];R?=[double(tr) double(r)''];V?=[double(tv) double(v)''];',ic));clear tlt tmlt tL tilat lt mlt Lshell ilat tr r tv v;
        if exist(file_name,'file'), flag_append='-append';
        else flag_append='';
        end
        save(file_name,'A1','A2','A3','A4',flag_append);
        save(file_name,'L1','L2','L3','L4',flag_append);
        save(file_name,'LT1','LT2','LT3','LT4',flag_append);
        save(file_name,'MLT1','MLT2','MLT3','MLT4',flag_append);
        save(file_name,'ILAT1','ILAT2','ILAT3','ILAT4',flag_append);
        save(file_name,'R1','R2','R3','R4',flag_append);
        save(file_name,'V1','V2','V3','V4',flag_append);
      end
      
    case 'EFW_P',
      file_prefix='EFW_P_';
      file_name=[path_out file_prefix deblank(R_datestring(start_time)) '_to_' deblank(R_datestring(end_time))];
      EFW_P=c_isdat_get_EFW(time_interval,[],[],sc_mode,1:4,db,'P');
      P1=EFW_P{1};P2=EFW_P{2};P3=EFW_P{3};P4=EFW_P{4};
      if exist(file_name,'file'), 
        save(file_name,'P1','P2','P3','P4','-append');
      else,
        save(file_name,'P1','P2','P3','P4');
      end
      
    case 'EFW_E',
      file_prefix='EFW_E_';
      file_name=[path_out file_prefix deblank(R_datestring(start_time)) '_to_' deblank(R_datestring(end_time))];
      EFW_E=c_isdat_get_EFW(time_interval,[],[],sc_mode,1:4,db,'wE');
      wE1=EFW_E{1};wE2=EFW_E{2};wE3=EFW_E{3};wE4=EFW_E{4};
      if exist(file_name,'file'), 
        save(file_name,'wE1','wE2','wE3','wE4','-append');
      else,
        save(file_name,'wE1','wE2','wE3','wE4');
      end
    end
  end
end

Mat_DbClose(db);
