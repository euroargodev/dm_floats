function check_dmqc(CHECK,param,CORRECTION,APPLY_upto_CY,float_number)


% Figures de CHECK
%keyboard
if isfield(CHECK,param)
    
    %CHECK.(param).n_correction = libargo.sd_round(CHECK.(param).n_correction,3);
    if isfield(CHECK.(param),'resolution')
        %CHECK.(param).resolution=CHECK.(param).resolution/10;
        CHECK.(param).n_correction = round(CHECK.(param).n_correction./CHECK.(param).resolution).*CHECK.(param).resolution;
    else
        CHECK.(param).n_correction = libargo.libargo.sd_round(CHECK.(param).n_correction,2);
    end
    figure
    %hf= figure;
    %initpos = get(hf,'Position') ;
    %set(hf,'Position', [initpos(1)   initpos(2)-(initpos(4)*0.9)   initpos(3)*1.1   initpos(4)*1.8]) ;
    %---------------------------------------------------
    subplot(4,1,1)
    %set(gca,'Fontsize',12)
    %set(gca,'FontWeight','bold')
    hold on
    grid on
	box on
    plot( CHECK.n_cycle_for_plot, CHECK.(param).n_correction,'-+');
    
    
    title([float_number ': Mean ' upper(param) ' CORRECTION (' param '_adjusted - ' param ') in the netcdf file'],'interpreter', 'none')
    %xlabel('n_cycle','interpreter','none')
    ylabel([ param ' units'])
    
    xlim=get(gca,'XLim');
    xlim1=[xlim(1) max(CHECK.n_cycle_for_plot)];
    xlim=xlim1;
    
    ylim1(1)=libargo.sd_round(min(CHECK.(param).n_correction),5);
    ylim1(2)=libargo.sd_round(max(CHECK.(param).n_correction),5);
    ylim1(1)=ylim1(1)-abs((ylim1(2)-ylim1(1))/100);
    ylim1(2)=ylim1(2)+abs((ylim1(2)-ylim1(1))/100);
    if (ylim1(1)==ylim1(2))
        if ylim1(1)==0
            ylim1(1)=-1;
            ylim1(2)=1;
        else
            ylim1(1)=ylim1(1)-abs(ylim1(1)/10);
            ylim1(2)=ylim1(2)+abs(ylim1(2)/10);
        end
    end
    if isnan(ylim1(1))|isnan(ylim1(2))
            ylim1(1)=-1;
            ylim1(2)=1;
    end
    axis([xlim1(1) xlim1(2) ylim1(1) ylim1(2)])
    
    %---------------------------------------------------
    subplot(4,1,2)
     %set(gca,'Fontsize',12)
    %set(gca,'FontWeight','bold')
    hold on
    box on
    grid on
    w(:,:)=[1,1,1;0,0,1;0.3,1,0.3;1,1,0.3;1,0.7,0.3;1,0.3,0.3];
   % w(:,:)=[0,0,0;0.3,1,0.3;1,1,0.3;1,0.7,0.3;1,0.3,0.3];
    CHECK.(param).adjqc(CHECK.(param).adjqc==99)=-1;
    
    %keyboard
    a=[CHECK.n_cycle_for_plot,CHECK.n_cycle_for_plot(end)+1];
    b=double([CHECK.(param).adjqc;CHECK.(param).adjqc(end,:)]);
	A=repmat(a',[1,size(b,2)]);
    c=[1:size(CHECK.(param).qc,2)];
    C=repmat(c, [size(b,1),1]);
    %pcolor([1:size(CHECK.(param).adjqc,1)],[1:size(CHECK.(param).adjqc,2)],double(CHECK.(param).adjqc'))
    %pcolor(a,[1:size(CHECK.(param).adjqc,2)],b')
    ii=find(b==0);
    scatter(A(ii),C(ii),10,'*b')
    ii=find(b==1);
    scatter(A(ii),C(ii),10,'*g')
    ii=find(b==2);
    scatter(A(ii),C(ii),10,'*y')
    ii=find(b==3);
    scatter(A(ii),C(ii),10,'*m')
    ii=find(b==4);
    scatter(A(ii),C(ii),10,'*r')
    set(gca,'YDir','reverse')
    set(gca,'YDir','reverse')
    %shading('flat')
    ylabel('level')
    %xlabel('n_cycle','interpreter','none')
    title([upper(param) '_ADJUSTED_QC  in the netcdf file'],'interpreter', 'none')
    
    
    colormap(w)
    caxis([-1.5 4.5])
    yymax=max(find(sum(isnan(CHECK.(param).adjqc))==size(CHECK.(param).adjqc,1)==0));
    axis([xlim(1) xlim(2)+0.5 0 yymax+5])
    %keyboard
    %---------------------------------------------------
    subplot(4,1,3)
    %set(gca,'Fontsize',12)
    %set(gca,'FontWeight','bold')
    hold on
    box on
    grid on
    %w(:,:)=[0,0,0;0.3,1,0.3;1,1,0.3;1,0.7,0.3;1,0.3,0.3];
    w(:,:)=[1,1,1;0,0,1;0.3,1,0.3;1,1,0.3;1,0.7,0.3;1,0.3,0.3];
    CHECK.(param).qc(CHECK.(param).qc==99)=-1;
    a=[CHECK.n_cycle_for_plot,CHECK.n_cycle_for_plot(end)+1];
    b=double([CHECK.(param).qc;CHECK.(param).qc(end,:)]);
	A=repmat(a',[1,size(b,2)]);
    c=[1:size(CHECK.(param).qc,2)];
    C=repmat(c, [size(b,1),1]);
    %pcolor([1:size(CHECK.(param).adjqc,1)],[1:size(CHECK.(param).adjqc,2)],double(CHECK.(param).adjqc'))
    %pcolor(a,[1:size(CHECK.(param).qc,2)],b')
     ii=find(b==0);
    scatter(A(ii),C(ii),10,'*b')
    ii=find(b==1);
    scatter(A(ii),C(ii),10,'*g')
    ii=find(b==2);
    scatter(A(ii),C(ii),10,'*y')
    ii=find(b==3);
    scatter(A(ii),C(ii),10,'*m')
    ii=find(b==4);
    scatter(A(ii),C(ii),10,'*r')
    set(gca,'YDir','reverse')
    %shading('flat')
    ylabel('level')
   % xlabel('n_cycle','interpreter','none')
    title([upper(param) '_QC  in the netcdf file'],'interpreter', 'none')
    
    colormap(w)
    caxis([-1.5 4.5])
    yymax=max(find(sum(isnan(CHECK.(param).qc))==size(CHECK.(param).qc,1)==0));
    axis([xlim(1) xlim(2)+0.5 0 yymax+5])
    
    
    %---------------------------------------------------
    subplot(4,1,4)
    %set(gca,'Fontsize',12)
    %set(gca,'FontWeight','bold')
    %keyboard
    hold on
    plot( CHECK.n_cycle_for_plot, CHECK.(param).adj_err,'-+r');
    xlim3=get(gca,'XLim');
    ylim3(1)=libargo.sd_round(min(CHECK.(param).adj_err),5);
    ylim3(2)=libargo.sd_round(max(CHECK.(param).adj_err),5);
    
    if (ylim3(1)==ylim3(2))
        if ylim3(1)==0
            ylim3(1)=-1;
            ylim3(2)=1;
        else
            ylim3(1)=ylim3(1)-abs(ylim3(1)/10);
            ylim3(2)=ylim3(2)+abs(ylim3(2)/10);
        end
        
    end
    if isnan(ylim3(1))|isnan(ylim3(2))
            ylim3(1)=-1;
            ylim3(2)=1;
    end
    axis([xlim(1) xlim(2)+0.5 ylim3(1) ylim3(2)])
    %  h1=gca;
    %  set(h1,'YAxisLocation','left','TickLength',[0 0])
    %  h2=axes('position',get(h1,'position'),'color','none');
    %  set(h2,'YAxisLocation','right','Color','none','XTickLabel',[])
    %  line(n_cycle+0.5, adj_sal_err,'Color','k','Parent',h2,'Marker','+','MarkerEdgeColor','k');
    %  %plot( n_cycle, adj_sal_err,'-+y');
    %  linkaxes([h1 h2], 'x');
    %
    %  xlim=get(h2,'XLim');
   % title([upper(param) '_ADJUSTED_ERROR  in the netcdf file'],'interpreter', 'none')
    title(['Mean ' upper(param) '_ADJUSTED_ERROR  in the netcdf file'],'interpreter', 'none')

    grid on
    box on
    ylabel([ param ' units'])
    xlabel('n_cycle','interpreter','none')
    
    
    % % PATCH
    % for ik=[1,4]
        % subplot(4,1,ik)
        
        % xlim=get(gca,'XLim');
        % ylim=libargo.sd_round(get(gca,'YLim'),5);
        % if (ylim(1)==ylim(2))
            % ylim(1)=ylim(1)-abs(ylim(1)/10);
            % ylim(2)=ylim(2)+abs(ylim(1)/10);
        % end
        
        % vec=[xlim(1) APPLY_upto_CY+0.5 ];
        
        % for k=1:length(vec)-1
            % xdata=[vec(k) vec(k+1)  vec(k+1) vec(k)];
            % ydata=[ylim(1) ylim(1) ylim(2) ylim(2)];
            % p=patch(xdata,ydata,'w');
            % xpos= [vec(k)+(vec(k+1)-vec(k))/2];
            % ypos= [ylim(1)+(ylim(2)-ylim(1))/1.5];
            % thecorrection=CORRECTION{k};
            
            
            % switch thecorrection
                % case{'NO'}
                    % set(p,'FaceColor',[0.8 0.8 0.8],'FaceAlpha',0.5,'EdgeColor',[0.9 0.9 0.9]);
                % case{'LAUNCH_OFFSET'}
                    % set(p,'FaceColor',[0.8 0.8 1],'FaceAlpha',0.5,'EdgeColor',[0.9 0.9 0.9]);
                % case{'OW'}
                    % set(p,'FaceColor',[1 0.8 0.8],'FaceAlpha',0.5,'EdgeColor',[0.9 0.9 0.9]);
            % end
            % text(double(xpos),double(ypos),thecorrection,'interpreter','none')
        % end
        % clear xlim ylim
        
    % end
    
    subplot(4,1,1)
    plot( CHECK.n_cycle_for_plot, CHECK.(param).n_correction,'-+');
    axis([xlim1(1) xlim1(2)+0.5 ylim1(1) ylim1(2)])
    %ylim1
    
    subplot(4,1,4)
    plot( CHECK.n_cycle_for_plot, CHECK.(param).adj_err,'-+r');
    %keyboard
    axis([xlim(1) xlim(2)+0.5 ylim3(1) ylim3(2)])
    drawnow
    %  plot (C_FILE.PROFILE_NO,cal_sal,'g')
    %  plot (n_cycle,adj_sal,'+r')
    
    
    if isfield(CHECK.(param), 'comment')
        % COMMENTAIRE
        disp(['****************  ' upper(param) '  *********************'])
        disp(' ')
        
        vec=[CHECK.n_cycle(1)-1 APPLY_upto_CY ];
        
        
        for k=1:length(vec)-1
            
            thecorrection=CORRECTION{k};
            
            ii1=find(CHECK.n_cycle==vec(k)+1);
            ii2=find(CHECK.n_cycle==vec(k+1));
            if strcmp(param,'psal')
            disp(['Calibration Comment for ' param ' from cycle ' num2str(vec(k)+1) ' to ' num2str(vec(k+1)) ' CORRECTION:' thecorrection ])
            else
            disp(['Calibration Comment for ' param ' from cycle ' num2str(vec(k)+1) ' to ' num2str(vec(k+1))  ])
            end
            disp('-------------------------------------------------------------- ')
            uniqcom=unique(CHECK.(param).comment(ii1:ii2));
            for l=1:length(uniqcom)
                disp(uniqcom{l})
                disp(' ')
            end
            disp('-------------------------------------------------------------- ')
            disp(' ')
        end
        
    end
    %keyboard
    outps=['./paramlog/' float_number '/check_' param '_' num2str(float_number) '.pdf'];
    %eval(['print  -dpdf ' outps]) ;
end




