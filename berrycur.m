function curvature=berrycur(n,parameters)
areadiamond=parameters.areadiamond;
% n=3;
nor=sqrt(areadiamond);
d=parameters.d;
Nk=parameters.Nk;
NN=parameters.NN;
xr=(4*pi/(3*sqrt(3)*d));
yc=(2*pi)/(3*d);
kxlist=linspace(-xr,xr,Nk);
kylist=linspace(-yc,yc,Nk);
xlist=linspace(0,sqrt(3)*d,NN);
ylist=linspace(0,3/2*d,NN);
[xgrid,ygrid]=meshgrid(xlist,ylist);
% wf=zeros(kx,ky,x,y)
wf=zeros(Nk,Nk,NN,NN);
parfor xindex=1:Nk
    for yindex=1:Nk
        kx=kxlist(xindex);
        ky=kylist(yindex);
        tmp=um(n,kx,ky,xgrid,ygrid,parameters)/nor;        
        wf(xindex,yindex,:,:)=((real(tmp)<0)*(-1)+(real(tmp)>=0)).*tmp;
    end
end
wfdx=zeros(Nk,Nk,NN,NN);
wfdy=zeros(Nk,Nk,NN,NN);
for xindex=1:NN
    for yindex=1:NN
        x=xlist(NN);
        y=ylist(NN);
        [wdx,wdy]=gradient(wf(:,:,xindex,yindex),(2*xr)/(Nk-1),(2*yc)/(Nk-1));
        wfdx(:,:,xindex,yindex)=wdx;
        wfdy(:,:,xindex,yindex)=wdy;        
    end
end
curvature=zeros(Nk,Nk);
for xindex=1:Nk
    for yindex=1:Nk
        cur=-1i*(conj(wfdx(xindex,yindex,:,:)).*wfdy(xindex,yindex,:,:)-conj(wfdy(xindex,yindex,:,:)).*wfdx(xindex,yindex,:,:));
        curvature(xindex,yindex)=trapz(ylist,trapz(xlist,squeeze(cur),2));
    end
end
end 
