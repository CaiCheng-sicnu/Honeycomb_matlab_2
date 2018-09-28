%initial M_all and Uk
cellnumber=parameters.cellnumber;
d=parameters.d;
NN=parameters.NN;

b1=parameters.b1;
b2=parameters.b2;
q=4;
Nband=10;
bnor=b2(2)/q;
kset=cell(q^2,1);
pp=[3/4*sqrt(3*cellnumber)*d 3*sqrt(cellnumber)*d/4];
np=[-sqrt(3*cellnumber)*d/4 3*sqrt(cellnumber)*d/4];
nn=[-3/4*sqrt(3*cellnumber)*d -3/4*sqrt(cellnumber)*d];
pn=[sqrt(3*cellnumber)*d/4 -3*d/4*sqrt(cellnumber)];
x=linspace(nn(1),pp(1),NN);
y=linspace(nn(2),pp(2),NN);
[XX,YY]=meshgrid(x,y);
wb=1/(3*bnor^2);

for i1=1:q
    for i2=1:q
        index1=(2*i1-q-1)/(2*q);
        index2=(2*i2-q-1)/(2*q);
        kset{(i1-1)*q+i2}=index1*b1+index2*b2;
    end
end
bnset={bnor*[0,1],bnor*[sqrt(3)/2,1/2],bnor*[sqrt(3)/2,-1/2],bnor*[0,-1],bnor*[-sqrt(3)/2,-1/2],bnor*[-sqrt(3)/2,1/2]};
M_all=cell(q^2,6);
for kindex=1:q^2   
    for bindex=1:6
        kx=kset{kindex}(1);
        ky=kset{kindex}(2);
        bnx=bnset{bindex}(1);
        bny=bnset{bindex}(2);        
%         ubra=cell(Nband,1);
%         for i=1:Nband
%             ubra{i}=um(i,kx,ky,XX,YY,parameters);
%         end
        ubra=uaup(Nband,kx,ky,XX,YY,parameters);
%         uket=cell(Nband,1);
%         for i=1:Nband
%             uket{i}=um(i,kx+bnx,ky+bny,XX,YY,parameters);
%         end
        uket=uaup(Nband,kx+bnx,ky+bny,XX,YY,parameters);
        inner_u=zeros(Nband);
        for i=1:Nband
            for j=1:Nband
%                 intu=conj(ubra{i}).*uket{j};
                intu=conj(ubra(:,:,i)).*uket(:,:,j);                
                inner_u(i,j)=trapz(y,trapz(x,intu,2));
            end
        end
        M_all{kindex,bindex}=inner_u;
    end
end

Uk=cell(q^2,1);
for kindex=1:q^2
    Uk{kindex}=eye(Nband);
end


for iter=1:1000
%update rbar
    
    rbar=zeros(Nband,2);
    for kindex=1:q^2
        for bindex=1:6
            rbar=rbar+wb*imag(log(diag(M_all{kindex,bindex})))*bnset{bindex};
        end
    end
    rbar=rbar*(-1/q^2);

    %update qkb
    
    qkb=cell(q^2,6);
    for kindex=1:q^2
        for bindex=1:6
            qkb{kindex,bindex}=imag(log(diag(M_all{kindex,bindex})))+sum(repmat(bnset{bindex},[Nband,1]).*rbar,2);
        end
    end 

    %update Rkb
    
    Rkb=cell(q^2,6);
    for kindex=1:q^2
        for bindex=1:6
            Rkb{kindex,bindex}=M_all{kindex,bindex}.*repmat(diag(M_all{kindex,bindex})',[Nband,1]);
        end
    end

    %update Rtkb
    
    Rtkb=cell(q^2,6);
    for kindex=1:q^2
        for bindex=1:6
            Rtkb{kindex,bindex}=M_all{kindex,bindex}./repmat(diag(M_all{kindex,bindex}).',[Nband,1]);
        end
    end

    %update Tkb
    
    Tkb=cell(q^2,6);
    for kindex=1:q^2
        for bindex=1:6
            Tkb{kindex,bindex}=Rtkb{kindex,bindex}.*repmat(qkb{kindex,bindex}.',[Nband,1]);
        end
    end

    %update G
   
    G=cell(q^2,1);
    for kindex=1:q^2
        G{kindex}=0;
        for bindex=1:6
            G{kindex}=G{kindex}+wb*((Rkb{kindex,bindex}-Rkb{kindex,bindex}')/2-(Tkb{kindex,bindex}+Tkb{kindex,bindex}')/(2*1i));        
        end
        G{kindex}=4*G{kindex};
    end

    %update dW
    
    dW=cell(q^2,1);
    epsilon=0.001;
    for kindex=1:q^2
        dW{kindex}=epsilon*G{kindex};
    end

    %update Uk
    
    for kindex=1:q^2
        Uk{kindex}=Uk{kindex}*expm(dW{kindex});
%         if(Uk{kindex}'*Uk{kindex}~=eye(Nband))
%             error("non unitary");
%         end
    end
    
    %update M_all
    
    for kindex=1:q^2
        for bindex=1:6
            kxindex=ceil(kindex/q);
            kyindex=mod((kindex-1),q)+1;
            switch bindex
                case 1
                    kxbindex=kxindex;
                    kybindex=mod(kyindex,q)+1;
                case 2
                    kxbindex=mod(kxindex,q)+1;
                    kybindex=mod(kyindex,q)+1;
                case 3
                    kxbindex=mod(kxindex,q)+1;
                    kybindex=kyindex;
                case 4
                    kxbindex=kxindex;
                    kybindex=mod(kyindex-2,q)+1;
                case 5
                    kxbindex=mod(kxindex-2,q)+1;
                    kybindex=mod(kyindex-2,q)+1;
                case 6
                    kxbindex=mod(kxindex-2,q)+1;
                    kybindex=kyindex;
            end
            linindex=(kxbindex-1)*q+kybindex;
            M_all{kindex,bindex}=Uk{kindex}'*M_all{kindex,bindex}*Uk{linindex};
        end
    end
    wf=bloch2wannier(Uk,kset,0,0,parameters);
    surf(XX(1,:),YY(:,1),abs(wf(:,:,1)),'edgecolor','none');view(2);colorbar
    disp(omega(wf(:,:,1),0,0,parameters));    
end
% imagesc(real(Uk{1}));
%     caxis([-1,1])
%     colorbar;


    
                
                
       
        

        
 