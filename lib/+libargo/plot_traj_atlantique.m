function [thetitle]=plot_traj_atlantique(FL,Vec)
% -========================================================
%   USAGE : plot_traj(FL)
%   PURPOSE : plot the trajectory of the float, on a map with bathy
% -----------------------------------
%   INPUT :
%     FL   (structure)  Float data
%   optional input :
%     Vec 1*n_cycle parameter to plot along the trajectory
%   OUTPUT :
%    thetitle (char) title of the plot
% -----------------------------------
%   HISTORY  : created (2009) ccabanes
%            : modified (yyyy) byxxx
%   CALLED SUBROUTINES: none
% ========================================================

%keyboard

% load topo
Topo_ficin='/home/lpoargo1/DMARGO/OW/TOPO/topo.onetenthdeg.atlfull.nc';
Topo=libargo.read_netcdf_allthefile(Topo_ficin);

Topo = libargo.shiftEW(Topo,'lon','pacif_atl');

% load colormap
load ('/home/lpoargo1/DMARGO/OW/TOPO/bathy_17_colormap.mat');


if isfield(FL,'longitude')
    if isfield(FL,'latitude')
        
        
        FL = libargo.shiftEW(FL,'longitude','pacif_atl');
        
        region.lonmin = floor((min(FL.longitude.data)-5));
        region.lonmax = ceil(max(FL.longitude.data)+5);
        region.latmin = floor(min(FL.latitude.data)-5);
        region.latmax = ceil(max(FL.latitude.data)+5);
        
        
        
        
        
        %keyboard
        iy = (Topo.lat.data(:,1)>= region.latmin & Topo.lat.data(:,1)<= region.latmax);
        ix = (Topo.lon.data(1,:)>= region.lonmin & Topo.lon.data(1,:)<= region.lonmax);
        
        
        r=reshape(Topo.lat.data(iy,ix),sum(ix)*sum(iy),1);
        t=reshape(Topo.lon.data(iy,ix),sum(ix)*sum(iy),1);
        y=reshape(Topo.topo.data(iy,ix),sum(ix)*sum(iy),1);
        y(y>0)=NaN;
        
        
        figure;
        hold on
        box on
        grid on
        
        cvec=[-7000:500:1000,100000];
        [c,h]=contourf(Topo.lon.data(iy,ix),Topo.lat.data(iy,ix),Topo.topo.data(iy,ix),cvec);
        p = get(h,'Children');
        thechild=get(p,'CData');
        cdat=cell2mat(thechild);
        for i=1:length(cvec)-1
            set(p(cdat>=cvec(i)& cdat< cvec(i+1)),'Facecolor',newmap(i,:),'LineStyle','none')
        end
        contour(Topo.lon.data(iy,ix),Topo.lat.data(iy,ix),Topo.topo.data(iy,ix),[0 0],'LineColor',[0.6 0.5 0.4]);
        
        
        plot(FL.longitude.data,FL.latitude.data,'b')
        
        if  nargin==1
            Vec = FL.cycle_number.data;
        end
        
        
        scatter(FL.longitude.data,FL.latitude.data,30,Vec,'filled')
        
        Vec=Vec(~isnan(Vec));
        minvec=min(Vec);
        maxvec=max(Vec);
        
        if minvec<maxvec
        caxis([minvec maxvec])
        else
        caxis([minvec maxvec+1])
        end
        
        xlabel('longitude')
        ylabel('latitude')
        
        colorbar
        
        %keyboard
        thetitle = [' '];
        info1  = {'platform_number','pi_name','data_centre','juld'};
        info2  = {'Platform: ', ', PI: ', ', ',', date of the first cycle: '};
        
        
        
        for k=1:length(info1)
            if isfield(FL,info1{k})
                if isfield(FL.(info1{k}), 'data')
                    if isequal(info1{k},'juld')
                        % transforme la date juld > jour dd/mm/yyyy
                        thedate = datestr( (FL.juld.data(1,:) + datenum('19500101','yyyymmdd')),'dd/mm/yyyy');
                        
                        thetitle = [thetitle info2{k}  thedate  ];
                    else
                        thetitle = [thetitle info2{k}  strtrim(num2str(FL.(info1{k}).data(1,:)))  ];
                    end
                    
                end
            end
        end
        
        title(thetitle,'interpreter','none')
        
    else
        error(' No latitude data in the float data structure')
    end
    
else
    error('No longitude data in the float data structure ')
end


