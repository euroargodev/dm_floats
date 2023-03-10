% load_param_dmqc_interac.m

function s=load_param_dmqc_interac(flotteur,C_FILE,FLd,CONFIG)

options.Resize='on';
options.WindowStyle='normal';
options.Interpreter='none';


iswc=2;

s.LAUNCH_OFFSET =[];

% institution performing DM analysis
institution_code={'AO','BO','CI','CS','GE','GT','HZ','IF','IN','JA','JM','KM','KO','MB','ME','NA','NM','PM','RU','SI','SP','UW','VL','WH'};
institution_name={'AOML, USA','BODC, United Kingdom','IOS, Canada','CSIRO, Australia', 'BSH, Germany','GTS : used for data coming from WMO GTS network','CSIO, China','Ifremer, France','INCOIS, India','JMA, Japan','Jamstec, Japan','KMA, Korea','KORDI, Korea','MBARI, USA','MEDS, Canada','NAVO, USA','NMDIS, China','PMEL, USA','Russia','SIO, Scripps, USA','Spain','UW, USA','Far Eastern Regional Hydrometeorological Research Institute of Vladivostock, Russia','WHOI, USA'};

[isw,tf] = listdlg('PromptString','Institution performing DM?:',...
    'SelectionMode','single',...
    'ListString',institution_name,'InitialValue',8,'ListSize',[250,400]);
s.INSTITUTION=institution_code{isw};

% correction choice
while iswc==2
    
    fn = {'NO CORRECTION', 'OW' , 'LAUNCH_OFFSET' };
    [isw,tf] = listdlg('PromptString','Correction to apply?:',...
        'SelectionMode','single',...
        'ListString',fn);
    
    if isw==1
        s.CORRECTION = {'NO'};
        s.APPLY_upto_CY = [max(C_FILE.PROFILE_NO)];
        iswc=1;
    end
    
    if isw==3
        s.CORRECTION = {'LAUNCH_OFFSET'};
        s.APPLY_upto_CY = [max(C_FILE.PROFILE_NO)];
        prompt={['Enter the LAUNCH_OFFSET value (in PSU):']};
        dlg_title = 'LAUNCH OFFSET CORRECTION';
        def = {''};
        num_lines = 1;
        answer = inputdlg(prompt,dlg_title,num_lines,def,options);
        if isempty(answer)==0
            s.LAUNCH_OFFSET=str2num(answer{1});
            iswc=1;
        end
    end
    
    if isw==2
        s.CORRECTION = {'OW'};
        
        prompt={['The OW correction is applied from cycle :']; 'to cycle :'};
        
        dlg_title =  ['DM analysis is performed up to cycle ' num2str(max(C_FILE.PROFILE_NO))];
        
        num_lines = 1;
        def = {num2str(FLd.cycle_number.data(1)), num2str(max(C_FILE.PROFILE_NO))};
        
        stopasking=0;
        while stopasking==0
            
            answer = inputdlg(prompt,dlg_title,num_lines,def,options);
            
            if isempty(answer)==0
                
                if  isempty(str2num(answer{1}))|isempty(str2num(answer{2}))||str2num(answer{1})<FLd.cycle_number.data(1)||str2num(answer{2})>max(C_FILE.PROFILE_NO)||str2num(answer{1})>str2num(answer{2})
                    f = errordlg('Check cycle number values', 'OW correction');
                else
                    if  str2num(answer{1})==FLd.cycle_number.data(1)&& str2num(answer{2})==max(C_FILE.PROFILE_NO)
                        s.CORRECTION = {'OW'};
                        s.APPLY_upto_CY = [max(C_FILE.PROFILE_NO)];
                        iswc ='OK';
                        stopasking=1;
                    end
                    if  str2num(answer{1})>FLd.cycle_number.data(1)& str2num(answer{2})==max(C_FILE.PROFILE_NO)
                        prompt1= ['The OW correction will be applied from cycle ' answer{1} ', no correction before'];
                        iswc = questdlg(prompt1,'', 'OK', 'CANCEL','OK');
                        switch iswc
                            case{'OK'}
                                s.CORRECTION = {'NO';'OW'};
                                s.APPLY_upto_CY = [str2num(answer{1})-1,max(C_FILE.PROFILE_NO)];
                                stopasking=1;
                        end
                        
                    end
                    if  str2num(answer{1})==FLd.cycle_number.data(1)& str2num(answer{2})<max(C_FILE.PROFILE_NO)
                        prompt1= ['The OW correction will be applied up to cycle ' answer{2} ', no correction after'];
                        iswc = questdlg(prompt1,'', 'OK', 'CANCEL','OK');
                        switch iswc
                            case{'OK'}
                                s.CORRECTION = {'OW';'NO'};
                                s.APPLY_upto_CY = [str2num(answer{2}),max(C_FILE.PROFILE_NO)];
                                stopasking=1;
                        end
                    end
                    if  str2num(answer{1})>FLd.cycle_number.data(1)& str2num(answer{2})<max(C_FILE.PROFILE_NO)
                        prompt1= ['The OW correction will be applied from cycle '  answer{1}  ' and up to cycle :' answer{2} ', no correction before and after'];
                        iswc = questdlg(prompt1,'', 'OK', 'CANCEL','OK');
                        switch iswc
                            case{'OK'}
                                s.CORRECTION = {'NO';'OW';'NO'};
                                s.APPLY_upto_CY = [str2num(answer{1})-1 str2num(answer{2}),max(C_FILE.PROFILE_NO)];
                                stopasking=1;
                        end
                    end
                end
            end
        end
        
    end
end

display('SET ADJUSTED QCs')
choiceishelp=1;
while choiceishelp==1
    choice = questdlg('DEFAULT PSAL_ADJUSTED_QC IS 1','SET ADJUSTED QCs', 'OK', 'CHANGE','HELP','OK');
    s.DEF_PSAL_ADJ_QC = '1';
    s.MOD_PSAL_ADJ_QC{1} = '1';
    s.MOD_PSAL_ADJ_QC_CYCLE{1}=[FLd.cycle_number.data(1):(max(C_FILE.PROFILE_NO))];
    s.MOD_PSAL_ADJ_QC_DIRECTION{1}='A';
    display(['Default psal-adjusted_qc cycles:' num2str(FLd.cycle_number.data(1)) '-' num2str( max(C_FILE.PROFILE_NO))])
    defqc=ones(length(s.MOD_PSAL_ADJ_QC_CYCLE{1}),1);
    defcy=s.MOD_PSAL_ADJ_QC_CYCLE{1};
    
    display(defqc')
    switch choice
        case{'OK'}
            choiceishelp=0;
        case{'CHANGE'}
            ic=1;
            iswc=2;
            while iswc==2
                
                dlg_title =  ['PSAL_ADJUSTED_QC ?'];
                clear prompt1 def
                %prompt1{1} = ['DEFAULT PSAL_ADJUSTED_QC IS:' ] ;
                prompt1{1} = ['CHANGE PSAL_ADJUSTED_QC TO:' ] ;
                prompt1{2} = ['FOR CYCLE NUMBERS:'] ;
                prompt1{3} =['Apply on Ascending (A) or descending (D) profiles ?:'];
                %keyboard
                %def{1} = '1';
                def{1} = '1';
                def{2} = ['[' num2str(FLd.cycle_number.data(1)) ':' num2str(max(C_FILE.PROFILE_NO)) ']' ];
                def{3} = 'A';
                num_lines = 1;
                answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
                
                
                if isempty(answer)==0
                    %s.DEF_PSAL_ADJ_QC = strtrim(answer{1});
                    s.MOD_PSAL_ADJ_QC{ic} = strtrim(answer{1});
                    s.MOD_PSAL_ADJ_QC_DIRECTION{ic}=strtrim(answer{3})
                    eval(['s.MOD_PSAL_ADJ_QC_CYCLE{ic} = ' answer{2} ';']);
                    
                    defqc(ismember(defcy,s.MOD_PSAL_ADJ_QC_CYCLE{ic}))=str2num(s.MOD_PSAL_ADJ_QC{ic});
                    display('Changed to:')
                    display(defqc')
                    if str2num(s.MOD_PSAL_ADJ_QC{ic})>=2 && str2num(s.MOD_PSAL_ADJ_QC{ic})<4 % quand c'est 4 c'est à fillvalue.
                        h = helpdlg('PSAL_ADJUSTED_ERROR is automatically increased to 0.016 PSU when PSAL_ADJUSTED_QC>=2');
                    end
                    if sum(str2num(s.DEF_PSAL_ADJ_QC)==[1:4])==0 |sum(str2num(s.MOD_PSAL_ADJ_QC{ic})==[1:4])==0
                        iswc=2;
                        f = errordlg('QC values should be between 1-4');
                    else
                        
                        choice_suiv = questdlg('CHANGE DEFAULT PSAL_ADJUSTED_QC FOR OTHER CYCLES?','SET ADJUSTED QCs', 'YES', 'NO','NO');
                        switch choice_suiv
                            case{'YES'}
                                icwc=2
                                ic=ic+1;
                            case{'NO'}
                                iswc=1;
                        end
                    end
                    
                end
            end
            choiceishelp=0;
        case{'HELP'}
            h=helpdlg({'By DEFAULT PSAL_ADJUSTED_QC=1, that means that:',...
                'PSAL_ADJUSTED_QC = 1 if PSAL_QC =1', ...
                'PSAL_ADJUSTED_QC = 1 if PSAL_QC =2', ...
                'PSAL_ADJUSTED_QC = 1 if PSAL_QC =3', ...
                'PSAL_ADJUSTED_QC = 4 if PSAL_QC =4  (the others QCs are unchanged)',...
                'click CHANGE to modify the DEFAULT value for all or only some cycles'});
            uiwait(h)
    end
    
end

display('SET PSAL UNCERTAINTIES')
iswc=2;
s.SAL_INST_UNCERTAINTY = 0.01;
s.SAL_PI_UNCERTAINTY =[];

while iswc==2
    
    isw = questdlg('ERROR on PSAL_ADJUSTED ?','SET PSAL_ADJUSTED UNCERTAINTIES', 'MAX[1*OW,INSTRUMENT UNCERTAINTY]', 'PI_UNCERTAINTY','HELP','MAX[1*OW,INSTRUMENT UNCERTAINTY]' );
    
    switch isw
        case {'MAX[1*OW,INSTRUMENT UNCERTAINTY]'}
            prompt={['INSTRUMENT UNCERTAINTY ?'] };
            
            dlg_title =  ['MAX[1*OW,INSTRUMENT UNCERTAINTY]'];
            
            num_lines = 1;
            def = {num2str(0.01)};
            
            answer = inputdlg(prompt,dlg_title,num_lines,def,options);
            if isempty(answer)==0
                s.SAL_INST_UNCERTAINTY = str2num(answer{1});
                s.PSAL_ERROR='MAX_OW_INST';
                iswc=1;
            end
        case {'PI_UNCERTAINTY'}
            prompt={['PI UNCERTAINTY ?'] };
            
            dlg_title =  ['ERROR on PSAL is PI_UNCERTAINTY'];
            
            num_lines = 1;
            def = {num2str(0.01)};
            
            answer = inputdlg(prompt,dlg_title,num_lines,def,options);
            if isempty(answer)==0
                s.SAL_PI_UNCERTAINTY = str2num(answer{1});
                s.PSAL_ERROR = 'FROM_PI';
                iswc=1;
            end
        case {'HELP'}
            h=helpdlg({'It is possible to choose',...
                '1) PSAL_ADJUSTED_ERROR = max(OW err, INST_UNCERTAINTY)',...
                'or 2) PSAL_ADJUSTED_ERROR = PI_UNCERTAINTY',...
                'if 1),  INST_UNCERTAINTY = 0.01 PSU by default.',...
                'Note: if, for a given cycle, PSAL_ADJUSTED QC is >=2 or',...
                'if |PSAL_ADJUSTED -PSAL|>0.05 PSU then ',...
                'PSAL_ADJUSTED_ERROR = max(PSAL_ADJUSTED_ERROR,0.016)'});
            uiwait(h)
    end
    
end





%%%%  CALIBRATION COMMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choiceishelp=1;
while choiceishelp==1
    choice = questdlg('How do you want to store calibration information','SCIENTIFIC CALIBRATION SECTION', 'N_CALIB=1', 'N_CALIB=N_CALIB+1','HELP','N_CALIB=1');
    
    switch choice
        case{'N_CALIB=1'}
            choiceishelp=0;
            s.ADD_NCALIB=0;
        case{'N_CALIB=N_CALIB+1'}
            choiceishelp=0;
            s.ADD_NCALIB=1;
            
        case{'HELP'}
            h=helpdlg({'N_CALIB is a dimension used in the SCIENTIFIC CALIBRATION variables',...
                'This corresponds to the maximum number of calibration performed on a profile:', ...
                '* if N_CALIB=1, all previous calibration comments will be erased, the details', ...
                ' of all steps in PSAL adjustement (press adjutement effect', ...
                'thermal lag, OW adjustement) have to be described in a single calibration comment', ...
                '* if N_CALIB=N_CALIB+1 the OW step will result in an additional calibration comment'});
            uiwait(h)
    end
    
end

s.ADD_NCALIB

choiceishelp=1;
while choiceishelp==1
    choice = questdlg('Has salinity previously adjusted for thermal mass effect?','THERMAL MASS ADJUSTEMENT', 'NO', 'YES','HELP','NO');
    
    switch choice
        case{'YES'}
            s.THERM=1;
            s.force='adjusted';
            f=warndlg('Input for salinity calibration are: TEMP_ADJUSTED, PSAL_ADJUSTED and PRES_ADJUSTED');
            uiwait(f)
            
            if s.ADD_NCALIB==0 % CTM equation and coefficient will be added in the SCIENTIFIC CALIB EQUATION and COEFFICIENT FOR PSAL
                dlg_title =  ['Coefficients for CTM correction:'];
                clear prompt1 def
                prompt1{1} = ['alpha'] ;
                prompt1{2} = 'tau';
                prompt1{3} = 'rise rate';
                prompt1{4} = 'method';
                
                def{1} = '0.141';
                def{2} = '6.89';
                def{3} = '10 cm/s';
                def{4} = 'Johnson et al, 2007, JAOT';
                num_lines = 1;
                answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
                s.CTM_coefficient=['CTM alpha= ' answer{1} ' & tau= ' answer{2} ', rise rate=' answer{3} ' with error equal to the correction. '];
                s.CTM_equation=[', corrected for CTM, ' answer{4}];
            end
            choiceishelp=0;
        case{'NO'}
            s.THERM=0;
            choiceishelp=0;
        case{'HELP'}
            h=helpdlg({'if YES: the program will apply OW calibration on PSAL_ADJUSTED:',...
                '       input_temp is TEMP_ADJUSTED,',...
                '       input_pres is PRES_ADJUSTED,',...
                '       input_psal is PSAL_ADJUSTED',...
                'if NO: input_temp is TEMP, ',...
                '       input_pres is PRES or PRES_ADJUSTED if PRES was ADJUSTED before,',...
                '       input_psal is PSAL or PSAL recalculated to take into account',...
                '       effects of pressure adjustement'});
            uiwait(h)
            
    end
end

iswc=2;

while iswc==2
    
    prompt = {'METHOD ?'; 'VERSION ?'; 'CONFIG ?'; 'REFERENCE DATABASE ?        ';'OTHER COMMENTS to be included in SCIENTIFIC_CALIB_COMMENT (e.g. mapping scales..) ?'};
    
    
    dlg_title =  ['INFORMATIONS on OW METHOD USED TO CALIBRATE PSAL'];
    
    num_lines = 1;
    NCONFIG='';
    %      if strcmp(NCONFIG,'39')|strcmp(NCONFIG,'392')
    %          BASEREF='CTD2016V1';
    %      end
    NCONFIG_str=['config  ' strtrim(NCONFIG)];
    
    def = {'OWC Method'; CONFIG.VERSION; ''; CONFIG.BASEREF; ''};
    
    answer = inputdlg(prompt,dlg_title,num_lines,def,options);
    
    if isempty(answer)==0
        s.METHOD = [strtrim(answer{1}) ', ' strtrim(answer{2}) ', ' strtrim(answer{3}) ' -' strtrim(answer{4}) ' -'];
        s.OW_RELEASE = strtrim(answer{2});
        s.OW_REF = strtrim(answer{4});
        s.REPPORT = strtrim(answer{5});
        iswc=1;
    end
end


% to be included in PSAL calibration comment
% SCIENTIFIC_CALIB_COMMENT = [s.CORR_PSAL_comment_XX s.ERROR_PSAL_comment_XX s.METHOD s.REPPORT];



s.CORR_PSAL_comment.NO = ['No adjustement was necessary. '];


s.CORR_PSAL_comment.LAUNCH_OFFSET =['An offset was detected by comparing float data with the reference CTD cast made at float launch. This offset of ' num2str(s.LAUNCH_OFFSET) ' PSU was added . '];
%s.CORR_PSAL_comment.LAUNCH_OFFSET =['An offset was detected before launch and was confirmed by comparing data from other closest floats. This offset of ' num2str(s.LAUNCH_OFFSET) ' PSU was added . '];
s.CORR_PSAL_comment.OW = ['Salinity drift or offset detected - OWC fit is adopted. '];


s.ERROR_PSAL_comment.MAX_OW_INST = ['Error = maximum [statistical uncertainty, ' num2str(s.SAL_INST_UNCERTAINTY) ']. '];

s.ERROR_PSAL_comment.FROM_PI = ['Error = ' num2str(s.SAL_PI_UNCERTAINTY) ' provided by the PI. '];




VEC=[FLd.cycle_number.data(1)-1,s.APPLY_upto_CY];

for lk=1:length(VEC)-1
    thecorrection=s.CORRECTION{lk};
    
    dlg_title =  ['Cycles ' num2str(VEC(lk)+1) ' - ' num2str(VEC(lk+1)) ': SCIENTIFIC_CALIB_COMMENT FOR PSAL_ADJUSTED'];
    clear prompt1 def
    prompt1{1} = ['CORR_PSAL_ADJUSTED_comment (' thecorrection ' CORRECTION is applied)'] ;
    prompt1{2} = 'ERROR_PSAL_ADJUSTEDcomment';
    prompt1{3} = 'METHOD_comment';
    prompt1{4} = 'OTHER_comment';
    
    def{1} = s.CORR_PSAL_comment.(thecorrection);
    def{2} = s.ERROR_PSAL_comment.(s.PSAL_ERROR);
    def{3} = s.METHOD;
    def{4} = s.REPPORT;
    num_lines = 1;
    answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
    if isempty(answer)==0
        s.CORR_PSAL_comment.(thecorrection) = answer{1};
        s.ERROR_PSAL_comment.(s.PSAL_ERROR) = answer{2};
        s.METHOD = answer{3};
        s.REPPORT = strtrim(answer{4});
    else
        error('You should run the program again')
    end
    
end

% for the conductivity CNDC: same comment as PSAL but the word "salinity" is replaced by the word "conductivity".
% CORR_CNDC_comment_XX = regexprep(s.CORR_PSAL_comment_XX,'salinity','conductivity','preservecase');


% to be included in TEMP calibration comment
% SCIENTIFIC_CALIB_COMMENT = [s.CORR_TEMP_comment]
if s.ADD_NCALIB==0;
    %  iswc=2;
    %  while iswc==2
    
    dlg_title =  ['SCIENTIFIC_CALIB_COMMENT FOR TEMP_ADJUSTED         '];
    clear prompt1 def
    prompt1{1} = ['CORR_TEMP_ADJUSTED_comment                         :'] ;
    prompt1{2} = ['ERROR_TEMP_ADJUSTED_comment'] ;
    
    def{1} = 'No adjustement was necessary -';
    def{2} = 'Calibration error is manufacturer specified accuracy';
    
    num_lines = 1;
    %      answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
    %      if isempty(answer)==0
    %          s.CORR_TEMP_comment=[answer{1} answer{2}];
    s.CORR_TEMP_comment=[def{1} def{2}];
    %          iswc=1;
    %      end
    %  end
end
% to be included in PRES calibration comment (unless a calibration of the PRESSURE has already been done!!)
% SCIENTIFIC_CALIB_COMMENT = [s.CORR_PRES_comment]
if s.ADD_NCALIB==0;
    %  iswc=2;
    %  while iswc==2
    
    dlg_title =  ['SCIENTIFIC_CALIB_COMMENT FOR PRES ADJUSTED         '];
    clear prompt1 def
    prompt1{1} = ['CORR_PRES_ADJUSTED_comment (Warning : if a calibration of the PRESSURE has already been done the original comment/eq/coeff will be kept!!)' ] ;
    prompt1{2} = ['ERROR_PRES_ADJUSTED_comment'] ;
    
    def{1} = 'No adjustement was necessary -';
    def{2} = 'Calibration error is manufacturer specified accuracy';
    
    num_lines = 1;
    %answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
    %if isempty(answer)==0
    %s.CORR_PRES_comment=[answer{1} answer{2}];
    s.CORR_PRES_comment=[def{1} def{2}];
    %iswc=1;
    %end
    %  end
end
%  s.CORR_DOXY_comment=[];
%
%  if sum(ismember(cellstr(theparamd),'DOXY'))>0|sum(ismember(cellstr(theparame),'DOXY'))>0
%      iswc=2;
%      while iswc==2
%
%          dlg_title =  ['SCIENTIFIC_CALIB_COMMENT FOR DOXY          '];
%          clear prompt1 def
%          prompt1{1} = ['CORR_DOXY_comment (if a calibration of the DOXY has already been done the original comment is kept!!)' ] ;
%
%          def{1} = 'Delayed mode qc on DOXY is not yet available -';
%
%
%          num_lines = 1;
%          answer = inputdlg(prompt1,dlg_title,num_lines,def,options);
%          if isempty(answer)==0
%              s.CORR_DOXY_comment=[answer{1} ];
%              iswc=1;
%          end
%      end
%
%  else
%      s.CORR_DOXY_comment='Delayed mode qc on DOXY is not yet available -';
%  end



if length(s.CORRECTION)~=length(s.APPLY_upto_CY)
    error('CORRECTION and APPLY_upto_CY should have the same length')
end

% save logs

%save (['./paramlog/load_param_dmqc_' flotteur '.mat'],'s.DEF_PSAL_ADJ_QC','s.MOD_PSAL_ADJ_QC','s.MOD_PSAL_ADJ_QC_CYCLE','s.CORRECTION','s.APPLY_upto_CY','s.CORR_DOXY_comment','s.CORR_PRES_comment','s.CORR_TEMP_comment','s.CORR_PSAL_comment','s.ERROR_PSAL_comment','s.METHOD','s.REPPORT','s.OW_RELEASE','s.OW_REF','s.SAL_PI_UNCERTAINTY','s.SAL_INST_UNCERTAINTY','s.PSAL_ERROR','s.LAUNCH_OFFSET')
save (['./paramlog/load_param_dmqc_' flotteur '.mat'],'s')
