function irf_disp_surfplot(kc_x_max,kc_z_max,wfinal,extraparam,surfchoice,colorchoice)
%IRF_DISP_SURF_PL   Plot the cold plasma dispersion surfaces
%
%  IRF_DISP_SURF_PL(K_PERP_MAX,K_PAR_MAX,W,EXTRAPAR,SURFCHOICE,COLCHOICE)
%  plots the dispersion surfaces calculated by IRF_DISP_SURFCALC.
% 
%  This function is essential for IRF_DISP_SURF.
%  
%  K_PERP_MAX = max value of k_perpendicular*c/w_c
%  K_PAR_MAX = max value of k_perpendicular*c/w_c
%  W = the dispersion surfaces from IRF_DISP_SURFCALC.
%  EXTRAPAR = the extra parameters from IRF_DISP_SURFCALC
%  SURFCHOICE = vector explaining which of the surfaces to plot  
%  COLCHOICE = number telling how the surface will be painted
%  
% $Id$

% By Anders Tjulin, last update 4/2-2003.

  % First clear the plot

  cla
  
  % Make vectors of the wave numbers

  kc_z=linspace(0,kc_z_max,35);
  kc_x=linspace(0,kc_x_max,35);

  % Remember the view settings
  
  [az,el]=view;
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set some variables according to the colorchoice
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
	colorMap = 'parula'; % default colorbar
  if colorchoice==2
    colorstring='<---- Electrostatic                Electromagnetic ---->';
    colorlimits=[0,1];
  elseif colorchoice==3
    colorstring='<---- Transversal                 Longitudinal ---->';
    colorlimits=[0,1];
  elseif colorchoice==4
    colorstring='<---- Perpendicular                   Parallel ---->';
    colorlimits=[0,1];
  elseif colorchoice==5
    colorstring='v_g/c';
    colorlimits=[0,1];
  elseif colorchoice==6
    colorstring='<---- Left handed              Right handed ---->';
    colorlimits=[-1,1];
		colorMap = 'bluered';
  elseif colorchoice==7
    colorstring='<---- Most energy in B    log10(eps0 E^2/(B^2/mu0))  Most energy in E ---->';
    colorlimits=[-3,3];
		colorMap = 'bluered';
  elseif colorchoice==8
    colorstring='<---- Most energy in ions     log10(We/Wi)      Most energy in electrons ---->';
    colorlimits=[-3,3];
		colorMap = 'bluered';
  elseif colorchoice==9
    colorstring='<---- Most energy in particles     log10(Wp/Wf)      Most energy in fields ---->';
    colorlimits=[-3,3];
		colorMap = 'bluered';
  else
    colorchoice=1;
    colorlimits=[0,1];
    colorstring=('This colorscale is not implemented yet');
  end

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Create matrices that the normal surf command can handle  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  w1(:,:)=wfinal(10,:,:);color1(:,:)=extraparam(colorchoice,10,:,:);
  w2(:,:)=wfinal(9,:,:);color2(:,:)=extraparam(colorchoice,9,:,:);
  w3(:,:)=wfinal(8,:,:);color3(:,:)=extraparam(colorchoice,8,:,:);
  w4(:,:)=wfinal(7,:,:);color4(:,:)=extraparam(colorchoice,7,:,:);
  w5(:,:)=wfinal(6,:,:);color5(:,:)=extraparam(colorchoice,6,:,:);
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot the surfaces we want
  %%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if surfchoice(1)
    surf(kc_x,kc_z,w1,color1)
    hold on
  end
  if surfchoice(2)
    surf(kc_x,kc_z,w2,color2)
    hold on
  end
  if surfchoice(3)
    surf(kc_x,kc_z,w3,color3)
    hold on
  end
  if surfchoice(4)
    surf(kc_x,kc_z,w4,color4)
    hold on
  end
  if surfchoice(5)
    surf(kc_x,kc_z,w5,color5)
    hold on
  end
  
  xlabel('k_\perp c/\omega_{ce}')
  ylabel('k_{||} c/\omega_{ce}')
  zlabel('\omega/\omega_{ce}')
  
  set(gca,'xlim',[0 kc_x_max]);
  set(gca,'ylim',[0 kc_z_max]);
  
  hold off
  caxis(colorlimits);
  h_cbar=colorbar('hor');
	colormap(irf_colormap(colorMap));

  % Make sure that the frequency scale starts at zero  
  
  temp=axis;
  axis([temp(1:4),0,temp(6)]);

  % Print the color explanations
	xlabel(h_cbar,colorstring);
  
	% Set the view as it was
  
  view(az,el);
  
  % Make itposible to rotate the view
  
  rotate3d on
