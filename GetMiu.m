function varargout = GetMiu(varargin)
% GETMIU MATLAB code for GetMiu.fig
%      GETMIU, by itself, creates a new GETMIU or raises the existing
%      singleton*.
%
%      H = GETMIU returns the handle to a new GETMIU or the handle to
%      the existing singleton*.
%
%      GETMIU('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GETMIU.M with the given input arguments.
%
%      GETMIU('Property','Value',...) creates a new GETMIU or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GetMiu_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GetMiu_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GetMiu

% Last Modified by GUIDE v2.5 03-Sep-2020 20:04:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GetMiu_OpeningFcn, ...
                   'gui_OutputFcn',  @GetMiu_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GetMiu is made visible.
function GetMiu_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GetMiu (see VARARGIN)
global hh
hh=handles;
% Choose default command line output for GetMiu
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GetMiu wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = GetMiu_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global wavelengths cube height width bands
[name,path]=uigetfile('*.h5');
if name
    set(handles.text2,'string',[path name]);
    set(handles.msg,'string','Waiting for loading...');
    pause(0.01)
    %% Open H5 Data
    cube = h5read([path name], '/Cube/Images');
    cube =single(cube);
    wavelengths = h5read([path name], '/Cube/Wavelength');
    
    height = size(cube, 1);
    width = size(cube, 2);
    bands = size(cube, 3);
    
    %% GUI processing
    
    set(handles.energy1,'string',mat2cell(wavelengths',1,bands));
    set(handles.x1,'string',mat2cell(1:width,1,width));
    set(handles.y1,'string',mat2cell(1:height,1,height));
    set(handles.energy2,'string',mat2cell(wavelengths',1,bands));
    set(handles.x2,'string',mat2cell(1:width,1,width));
    set(handles.y2,'string',mat2cell(1:height,1,height));
    set(handles.energy2,'value',bands);
    set(handles.x2,'value',width);
    set(handles.y2,'value',height);
    set(handles.energystep,'string',1);
    set(handles.xstep,'string',1);
    set(handles.ystep,'string',1);
    %% Plot
    set(handles.msg,'string','Load completed');
    energy1_Callback(hObject, eventdata, handles)
end

% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global abs
[name,path]=uigetfile({'*.dat;*.txt;*.mat','All Files'},'Get absorption spectrum');
if name
    set(handles.text17,'string',[path name]);
    k=0;
    for i=0:5
        dd= importdata([path name],'\t',i);
        if isstruct(dd)
            dd=dd.data;
        end
        a=size(dd);
        if a(2)>k || a(2)==0
           k=a(2);
           load_data=dd;
        else
            break
        end
    end
    load_data(isnan(load_data))=0;
    abs=load_data;
    set(handles.viewab,'string',mat2cell(1:size(abs,2)-1,1,size(abs,2)-1));
    energy1_Callback(hObject, eventdata, handles)
    viewab_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in fit1d.
function fit1d_Callback(hObject, eventdata, handles)
% hObject    handle to fit1d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global PLf eef d method iflog viewfab R aafit ee aa fixT T miuerr
if ~isempty(aa)
    if ~isempty(PLf) && length(eef)==length(PLf)
        method=get(handles.method,'value');
        d=str2double(get(handles.d,'string'))*1e-7; %cm
        R=str2double(get(handles.r,'string')); %m
        iflog=get(handles.log,'value');
        fixT=get(handles.fixT,'value');
        T=str2double(get(handles.T,'string'));
        viewfab=0;
        if method<3
            k0=[1.2 290];
            lb=[0.8 280];
            ub=[2 500];
            axes(handles.axes2)
            set(handles.msg,'string','Start to fit...')
            options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
            [kp,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval,k0,eef,log10(PLf),lb,ub,options);
            set(handles.msg,'string','Fitting completed')
            set(handles.miu,'string',kp(1))
            if fixT
                J(:,end)=[];
                err=nlparci(kp(1),resid,'jacobian',J);
                err=round(err(2)-err(1),4);     
                set(handles.miuerr,'string',err)
                set(handles.Terr,'string',0)
            else
                err=nlparci(kp,resid,'jacobian',J);
                err=round(err(:,2)-err(:,1),4);
                set(handles.T,'string',kp(2))
                set(handles.miuerr,'string',err(1))
                set(handles.Terr,'string',err(2))
            end
            miuerr=err(1);
            viewfab=1;
            aafit=numval([kp(1) kp(2)],ee);
        else
            k0=[1.2 290 1.6 30/1000];
            lb=[0.8 280 1.55 10/1000];
            ub=[2 500 1.8 200/1000];
            axes(handles.axes2)
            set(handles.msg,'string','Start to fit...')
            options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
            [kp,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval,k0,eef,log10(PLf),lb,ub,options);
            set(handles.msg,'string','Fitting completed')
            set(handles.miu,'string',kp(1))
            if fixT
                J(:,2)=[];
                kpp=kp;
                kpp(2)=[];
                err=nlparci(kpp,resid,'jacobian',J);
                err=round(err(:,2)-err(:,1),4);
                set(handles.miuerr,'string',err(1))
                set(handles.Terr,'string',0)
                set(handles.text40,'string',err(2))
                set(handles.text42,'string',err(3))
            else
                err=nlparci(kp,resid,'jacobian',J);
                err=round(err(:,2)-err(:,1),4);
                set(handles.T,'string',kp(2))
                set(handles.miuerr,'string',err(1))
                set(handles.Terr,'string',err(2))
                set(handles.text40,'string',err(3))
                set(handles.text42,'string',err(4))
            end
            miuerr=err(1);
            set(handles.edit12,'string',kp(3))
            set(handles.edit13,'string',kp(4)*1000)
            viewfab=1;
            aafit=numval([kp(1) kp(2) kp(3) kp(4)],ee);
        end
        axes(handles.axes3)
        hold off
        if method==1 || method==3
            plot(ee,(1-R)*(1-exp(-aa*d))./(1-R*exp(-aa*d)))
        else
            plot(ee,(1-exp(-aa*d)));
        end
        hold on
        plot(ee,aafit,'r')
    else
        set(handles.msg,'string','Error: PL spectrum is not correct')
    end
else
    set(handles.msg,'string','Error: Absorption spectrum is not exist')
end

function y=numval(k,x)
global d R T PL PLf a aa method iflog viewfab aafit integ fixT Eg EU copyfit1d
e=1240./x; %eV
c=2.998e8;%m/s
kb=8.617e-5;%eV/K
h=4.136e-15; %eV*s
if fixT
elseif viewfab~=2
    T=k(2);
end
if viewfab==1
    switch method
        case 1
            y=PL./(2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1));
        case 2
            y=PL./(2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-2./(exp((e-k(1))/2/kb/T)+1)));
        case 3
            y=PL./(2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1));
            Eg=k(3);
            g=k(4);
            alpha0=interp1(e,aa,Eg);
            y(e<=Eg)=alpha0*exp((e(e<=Eg)-Eg)/g);
            y(e<=Eg)=(1-R).*(1-exp(-y(e<=Eg)*d))./(1-R*exp(-y(e<=Eg)*d));
        otherwise
            y=PL./(2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-2./(exp((e-k(1))/2/kb/T)+1)));
            Eg=k(3);
            g=k(4);
            alpha0=interp1(e,aa,Eg);
            y(e<=Eg)=alpha0*exp((e(e<=Eg)-Eg)/g);
            y(e<=Eg)=(1-exp(-y(e<=Eg)*d));
    end
elseif viewfab==2
    switch method
        case 1
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k)/kb/T)-1).*(1-R).*(1-exp(-aa*d))./(1-R*exp(-aa*d));
        case 2
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k)/kb/T)-1).*(1-exp(-aa*d)).*(1-2./(exp((e-k)/2/kb/T)+1));
        case 3
            alpha0=interp1(e,aa,Eg);
            alpha=aa;
            alpha(e<=Eg)=alpha0*exp((e(e<=Eg)-Eg)/EU);
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-alpha*d))./(1-R*exp(-alpha*d));
        otherwise
            alpha0=interp1(e,aafit,Eg);
            alpha=aafit;
            alpha(e<=Eg)=alpha0*exp((e(e<=Eg)-Eg)/EU);
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*alpha;
    end
    if integ
        y=sum(y)*abs(x(2)-x(1))/1240;
    end
elseif viewfab==3
    switch method
        case 1
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-aa*d))./(1-R*exp(-aa*d));
        case 2
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-aa*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
        case 3
            alpha0=interp1(e,aa,k(3));
            alpha=aa;
            alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-alpha*d))./(1-R*exp(-alpha*d));
        otherwise
            alpha0=interp1(e,aa,k(3));
            alpha=aa;
            alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-alpha*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
    end
else
    switch method
        case 1
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-a*d))./(1-R*exp(-a*d));
        case 2
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-a*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
        case 3
            alpha0=interp1(e,a,k(3));
            alpha=a;
            alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-alpha*d))./(1-R*exp(-alpha*d));
        otherwise
            alpha0=interp1(e,a,k(3));
            alpha=a;
            alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
            y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-alpha*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
    end
    hold off
    if iflog
        plot(x,log10(PLf))
        hold on
        plot(x,log10(y),'r')
        ylabel('log(ph/eV/m^2/s)')
        copyfit1d=[x,log10(PLf),log10(y)];
    else
        plot(x,PLf)
        hold on
        plot(x,y,'r')
        ylabel('ph/eV/m^2/s')
        copyfit1d=[x,PLf,y];
    end
    y=log10(y);
    pause(0.01)
end



% --- Executes on button press in pl2d.
function pl2d_Callback(hObject, eventdata, handles)
% hObject    handle to pl2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pl2d
energy1_Callback(hObject, eventdata, handles)


function energystep_Callback(hObject, eventdata, handles)
% hObject    handle to energystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of energystep as text
%        str2double(get(hObject,'String')) returns contents of energystep as a double
global bands
a=fix(str2double(get(hObject,'string')));
if a<=0
    a=1;
elseif a>bands
    a=width;
end
set(hObject,'string',a)
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function energystep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to energystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in getmo.
function getmo_Callback(hObject, eventdata, handles)
% hObject    handle to getmo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of getmo
global I_1D xx yy ee eef I PL PLf ab a aa method PL2D PL2Df
if get(handles.getmo,'value')
    set(handles.getmo2,'value',0)
    set(handles.if1d,'value',0)
end
if ~isempty(I)
    geometry=get(handles.sf,'value');
    method=get(handles.method,'value');
    if method>2
        set(handles.fitsub,'enable','on')
        set(handles.text40,'enable','on')
        set(handles.text41,'enable','on')
        set(handles.text42,'enable','on')
        set(handles.text43,'enable','on')
        set(handles.edit12,'enable','on')
        set(handles.edit13,'enable','on')
    else
        set(handles.fitsub,'enable','off')
        set(handles.text40,'enable','off')
        set(handles.text41,'enable','off')
        set(handles.text42,'enable','off')
        set(handles.text43,'enable','off')
        set(handles.edit12,'enable','off')
        set(handles.edit13,'enable','off')
    end
    axesHandlesToChildObjects = findobj(handles.axes1, 'Type', 'line');
    if ~isempty(axesHandlesToChildObjects)
        delete(axesHandlesToChildObjects);
    end
    x=xx(get(handles.xx,'value'));
    y=yy(get(handles.yy,'value'));
    axes(handles.axes2)
    hold off
    if get(handles.if1d,'value')
        PL=I_1D(:);
    else
        PL=I(y,x,:);
        PL=PL(:);
    end
    PL(PL<1)=min(PL(PL>1));
    if geometry==1
        cosine=(1-cos(asin(str2double(get(handles.na,'string'))))^2);
    else
        cosine=1;
    end
    PL=PL/cosine;
    PL=double(PL);
    w1=get(handles.ffrom,'value');
    w2=get(handles.fto,'value');
    eef=ee(min(w1,w2):max(w1,w2));
    PLf=PL(min(w1,w2):max(w1,w2));
    if ~isempty(ab)
        aa=ab(:,get(handles.viewab,'value'));
        a=aa(min(w1,w2):max(w1,w2));
    end
    if get(handles.log,'value')
        plot(eef,log10(PLf))
        ylabel('log(ph/eV/m^2/s)')
    else
        plot(eef,PLf)
        ylabel('ph/eV/m^2/s')
    end
    if get(handles.getmo,'value')
        axes(handles.axes1)
        xlim=get(gca, 'XLim');
        ylim=get(gca, 'YLim');
        hold on
        if get(handles.pl2d,'value')
            p1=[x ylim(1)];
            p2=[x ylim(end)];
            plot([p1(1),p2(1)],[p1(2),p2(2)],'Color','r','LineWidth',1);
            p1=[xlim(1) y];
            p2=[xlim(end) y];
            plot([p1(1),p2(1)],[p1(2),p2(2)],'Color','r','LineWidth',1);
            set(handles.msg,'string','1D PL spectrum is plotted')
        end
    end
    if ~isempty(PL2D)
        PL2Df=PL2D(:,:,min(w1,w2):max(w1,w2));
        set(handles.pts,'string',[num2str(size(PL2D,1)*size(PL2D,2)) ' points'])
    end
else
    set(handles.msg,'string','Error: PL data is not exist')
end

function T_Callback(hObject, eventdata, handles)
% hObject    handle to T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T as text
%        str2double(get(hObject,'String')) returns contents of T as a double


% --- Executes during object creation, after setting all properties.
function T_CreateFcn(hObject, eventdata, handles)
% hObject    handle to T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function d_Callback(hObject, eventdata, handles)
% hObject    handle to d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of d as text
%        str2double(get(hObject,'String')) returns contents of d as a double


% --- Executes during object creation, after setting all properties.
function d_CreateFcn(hObject, eventdata, handles)
% hObject    handle to d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xstep_Callback(hObject, eventdata, handles)
% hObject    handle to xstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xstep as text
%        str2double(get(hObject,'String')) returns contents of xstep as a double
global width
a=fix(str2double(get(hObject,'string')));
if a<=0
    a=1;
elseif a>width
    a=width;
end
set(hObject,'string',a)
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function xstep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ystep_Callback(hObject, eventdata, handles)
% hObject    handle to ystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ystep as text
%        str2double(get(hObject,'String')) returns contents of ystep as a double
global height
a=fix(str2double(get(hObject,'string')));
if a<=0
    a=1;
elseif a>height
    a=height;
end
set(hObject,'string',a)
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function ystep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ave.
function ave_Callback(hObject, eventdata, handles)
% hObject    handle to ave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ave
energy1_Callback(hObject, eventdata, handles)

% --- Executes on selection change in xx1.
function energy1_Callback(hObject, eventdata, handles)
% hObject    handle to xx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx1
global I I_1D I_2D wavelengths cube ee im xx yy abs ab sun am cimage PL2D PL2Df
if ~isempty(cube)
    energy1=get(handles.energy1,'value');
    energy2=get(handles.energy2,'value');
    x1=get(handles.x1,'value');
    x2=get(handles.x2,'value');
    y1=get(handles.y1,'value');
    y2=get(handles.y2,'value');
    energystep=str2double(get(handles.energystep,'string'));
    xstep=str2double(get(handles.xstep,'string'));
    ystep=str2double(get(handles.ystep,'string'));
    I1=cube(:,:,energy1:energystep:fix((energy2-energy1+1)/energystep)*energystep+energy1-1)*1e4; %photons/m^2/eV/s
    ee=wavelengths(energy1:energystep:fix((energy2-energy1+1)/energystep)*energystep+energy1-1);
    set(handles.ffrom,'string',mat2cell(ee',1,length(ee)));
    if get(handles.ffrom,'value')>length(ee)
        set(handles.ffrom,'value',1);
    end
    set(handles.fto,'string',mat2cell(ee',1,length(ee)));
    if get(handles.fto,'value')>length(ee) || get(handles.fto,'value')<=get(handles.ffrom,'value')
        set(handles.fto,'value',length(ee));
    end
    if ~isempty(abs)
        ab=interp1(abs(:,1),abs(:,2:end),ee);
        ab(isnan(ab))=0;
        sun=am15(get(handles.am,'value'));
        am=interp1(sun(:,1),sun(:,2:end),abs(:,1));
        am(isnan(am))=0;
    end
    if get(handles.ave,'value')
        for i=2:energystep
            I1=I1+cube(:,:,energy1+i-1:energystep:fix((energy2-energy1+1)/energystep)*energystep+energy1-1);
        end
        I1=I1/energystep;
    end
    I2=I1(:,x1:xstep:fix((x2-x1+1)/xstep)*xstep+x1-1,:);
    xx=x1:xstep:fix((x2-x1+1)/xstep)*xstep+x1-1;
    xx=1:length(xx);
    set(handles.xx,'string',mat2cell(xx,1,length(xx)));
    set(handles.xx,'value',fix(length(xx)/2));
    set(handles.xx1,'string',mat2cell(xx,1,length(xx)));
    set(handles.xx1,'value',1);
    set(handles.xx2,'string',mat2cell(xx,1,length(xx)));
    set(handles.xx2,'value',length(xx));
    if get(handles.ave,'value')
        for i=2:xstep
            I2=I2+I1(:,x1+i-1:xstep:fix((x2-x1+1)/xstep)*xstep+x1-1,:);
        end
        I2=I2/xstep;
    end
    I3=I2(y1:ystep:fix((y2-y1+1)/ystep)*ystep+y1-1,:,:);
    yy=y1:ystep:fix((y2-y1+1)/ystep)*ystep+y1-1;
    yy=1:length(yy);
    set(handles.yy,'value',fix(length(yy)/2));
    set(handles.yy,'string',mat2cell(yy,1,length(yy)));
    set(handles.yy1,'value',1);
    set(handles.yy1,'string',mat2cell(yy,1,length(yy)));
    set(handles.yy2,'value',length(yy));
    set(handles.yy2,'string',mat2cell(yy,1,length(yy)));
    if get(handles.ave,'value')
        for i=2:ystep
            I3=I3+I2(y1+i-1:ystep:fix((y2-y1+1)/ystep)*ystep+y1-1,:,:);
        end
        I3=I3/ystep;
    end
    I=I3;
    clear I1 I2 I3
    I_1D= mean(mean(I, 1), 2);
    I_2D=mean(I,3);
    PL2D=double(I);
    w1=get(handles.ffrom,'value');
    w2=get(handles.fto,'value');
    PL2D(PL2D<1)=min(PL2D(PL2D>1));
    PL2Df=PL2D(:,:,min(w1,w2):max(w1,w2));
    set(handles.pts,'string',[num2str(size(PL2D,1)*size(PL2D,2)) ' points'])
    set(handles.getmo2,'value',0)
    % Normalize cube by mean spectrum
    axes(handles.axes1)
    hold off
    if get(handles.pl2d,'value')
        cimage=I_2D;
        switch get(handles.colormap,'value')
            case 1
                im=imshow(I_2D,[],'Colormap',jet(256));
            case 2
                im=imshow(I_2D,[],'Colormap',parula(256));
            case 3
                im=imshow(I_2D,[],'Colormap',hsv(256));
            case 4
                im=imshow(I_2D,[],'Colormap',hot(256));
            case 5
                im=imshow(I_2D,[],'Colormap',cool(256));
            case 6
                im=imshow(I_2D,[],'Colormap',spring(256));
            case 7
                im=imshow(I_2D,[],'Colormap',summer(256));
            case 8
                im=imshow(I_2D,[],'Colormap',autumn(256));
            case 9
                im=imshow(I_2D,[],'Colormap',winter(256));
            case 10
                im=imshow(I_2D,[],'Colormap',gray(256));
            case 11
                im=imshow(I_2D,[],'Colormap',bone(256));
            case 12
                im=imshow(I_2D,[],'Colormap',copper(256));
            otherwise
                im=imshow(I_2D,[],'Colormap',pink(256));
        end
        colorbar;
        set(im,'ButtonDownFcn', @axes1_ButtonDownFcn)
        title('2D maping of Mean Spectrum');
        axis on
        xlabel('X (pix)');
        ylabel('Y (pix)');
        getmo_Callback(hObject, eventdata, handles)
    else
        im=plot(ee, I_1D(:));
        title('Mean Spectrum');
        xlabel('Wavelengths (nm)');
        ylabel('Signal');
    end
else
    set(handles.msg,'string','Error: PL cube is not exist')
end


% --- Executes during object creation, after setting all properties.
function energy1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in xx1.
function x1_Callback(hObject, eventdata, handles)
% hObject    handle to xx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx1
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function x1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in yy1.
function y1_Callback(hObject, eventdata, handles)
% hObject    handle to yy1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yy1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yy1
global height
a=get(handles.y1,'value');
b=get(handles.y2,'value');
step=str2double(get(handles.ystep,'string'));
if a==height
    a=height-1;
    set(handles.y1,'value',a)
end
if a+step>=b && a+step<=height 
    set(handles.y2,'value',a+step);
elseif a+step>=b && a+step>height
    set(handles.y2,'value',height)
    set(handles.ystep,'value',height-a)
end
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function y1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yy1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in energy2.
function energy2_Callback(hObject, eventdata, handles)
% hObject    handle to energy2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns energy2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from energy2
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function energy2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to energy2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in xx2.
function x2_Callback(hObject, eventdata, handles)
% hObject    handle to xx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx2
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function x2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in yy2.
function y2_Callback(hObject, eventdata, handles)
% hObject    handle to yy2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yy2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yy2
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function y2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yy2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in colormap.
function colormap_Callback(hObject, eventdata, handles)
% hObject    handle to colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colormap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormap
energy1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function colormap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in xx.
function xx_Callback(hObject, eventdata, handles)
% hObject    handle to xx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function xx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in yy.
function yy_Callback(hObject, eventdata, handles)
% hObject    handle to yy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yy contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yy
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function yy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global xx yy hh count
pt = get(gca, 'CurrentPoint');
x = fix(pt(1,1));
y = fix(pt(1,2));
if get(hh.getmo,'value')
    [~,ix]=find(xx==x);
    [~,iy]=find(yy==y);
    if isempty(ix)
        ix=1;
    end
    if isempty(iy)
        iy=1;
    end
    set(hh.xx,'value',ix)
    set(hh.yy,'value',iy)
    getmo_Callback(hh.getmo, eventdata, hh)
elseif get(hh.getmo2,'value')
    [~,ix]=find(xx==x);
    [~,iy]=find(yy==y);
    if isempty(ix)
        ix=1;
    end
    if isempty(iy)
        iy=1;
    end
    if isempty(count) || fix(count/2)==0
        count=2;
        set(hh.xx1,'value',ix)
        set(hh.yy1,'value',iy)
    else
        count=0;
        set(hh.xx2,'value',ix)
        set(hh.yy2,'value',iy)
    end
    getmo2_Callback(hh.getmo, eventdata, hh)
end


% --- Executes on button press in fit.
function fit_Callback(hObject, eventdata, handles)
% hObject    handle to fit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global PL2Df eef d method iflog viewfab R miu2d T2d Eg2d Ub2d fixT T PL2D
if ~isempty(PL2Df)
    geometry=get(handles.sf,'value');
    if geometry==1
        cosine=(1-cos(asin(str2double(get(handles.na,'string'))))^2);
    else
        cosine=1;
    end
    PL2Dtemp=PL2Df/cosine;
    method=get(handles.method,'value');
    d=str2double(get(handles.d,'string'))*1e-7; %cm
    R=str2double(get(handles.r,'string')); %m
    iflog=get(handles.log,'value');
    fixT=get(handles.fixT,'value');
    loopi=1:size(PL2Df,1);
    loopj=1:size(PL2Df,2);
    miu=str2double(get(handles.miu,'string')); 
    miu2d=ones(size(PL2Df,1),size(PL2Df,2),1)*miu;
    T=str2double(get(handles.T,'string'));
    T2d=miu2d;
    if method>2
        Eg2d=miu2d;
        Ub2d=miu2d;
    end
    axes(handles.axes3)
    count=0;
    set(handles.abort2,'userdata',0)
    set(handles.msg,'string','Start to fit...')
    for i=loopi
        for j=loopj
            count=count+1;
            if method<3
                k0=[1.2 290];
                lb=[0.8 280];
                ub=[2 500];
                options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
                y=log10(PL2Dtemp(i,j,:));
                [kp,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval2,k0,eef,y(:),lb,ub,options);
                miu2d(i,j,1)=kp(1);
                T2d(i,j,1)=kp(2);
            else
                k0=[1.2 290 1.6 0.03];
                lb=[0.8 280 1.55 0.001];
                ub=[2 500 1.8 0.3];
                options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
                y=log10(PL2Dtemp(i,j,:));
                [kp,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval2,k0,eef,y(:),lb,ub,options);
                miu2d(i,j,1)=kp(1);
                T2d(i,j,1)=kp(2);
                Eg2d(i,j,1)=kp(3);
                Ub2d(i,j,1)=kp(4)*1000;
            end
            if fix(count/fix(max(loopi)*max(loopj)/200))*fix(max(loopi)*max(loopj)/200)==count
                hold off
                imshow(miu2d,[],'Colormap',jet(256));
                set(handles.msg,'string',['Fitting: ' num2str(fix(count/max(loopi)/max(loopj)*1000)/10) '%...'])
                pause(0.01)
            end
        end
    end
    imshow(miu2d,[],'Colormap',jet(256));
    set(handles.msg,'string','Fitting completed')
else
    set(handles.msg,'string','Error: PL spectrum is not exist')
end

function y=numval2(k,x)
global d R a method hh fixT T
e=1240./x; %eV
c=2.998e8;%m/s
kb=8.617e-5;%eV/K
h=4.136e-15; %eV*s
if fixT
else
    T=k(2);
end
switch method
    case 1
        y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-a*d))./(1-R*exp(-a*d));
    case 2
        y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-a*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
    case 3
        alpha0=interp1(e,a,k(3));
        alpha=a;
        alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
        y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-R).*(1-exp(-alpha*d))./(1-R*exp(-alpha*d));
    otherwise
%         alpha0=interp1(e,a,k(3));
%         alpha=a;
%         alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
%         y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-alpha*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
        
        alpha0=interp1(e,a,k(3));
        alpha=a;
        alpha(e<=k(3))=alpha0*exp((e(e<=k(3))-k(3))/k(4));
        y=2*pi.*e.*e/h/h/h/c/c./(exp((e-k(1))/kb/T)-1).*(1-exp(-alpha*d)).*(1-2./(exp((e-k(1))/2/kb/T)+1));
end
y=log10(y);
if get(hh.abort2,'userdata')==1
    set(hh.msg,'string','Fitting is aborted by user')
    error('Fitting is aborted by user');
end


% --- Executes during object creation, after setting all properties.
function viewab_CreateFcn(hObject, eventdata, handles)
% hObject    handle to viewab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in viewab.
function viewab_Callback(hObject, eventdata, handles)
% hObject    handle to viewab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ee ab abs cube a aa
axes(handles.axes3)
hold off
if isempty(abs)
    set(handles.msg,'string','Error: Absorption spectrum is not exist')
elseif isempty(cube)
    set(handles.msg,'string','Error: PL cube is not exist')
else
    if length(ee)==size(ab,1)
        aa=ab(:,get(handles.viewab,'value'));
        a=aa(get(handles.ffrom,'value'):get(handles.fto,'value'));
        plot(ee,aa)
        set(handles.msg,'string','Absorption spectrum is plotted')
    else
        set(handles.msg,'string','Error: Absorption spectrum does not match the PL spectrum')
    end
end


function y=am15(x)
%unit W/m^2/nm
%x=1 Etr
%x=2 Global
%x=3 Direct
y=[280	8.20E-02	4.73E-23	2.54E-26
280.5	9.90E-02	1.23E-21	1.09E-24
281	1.50E-01	5.69E-21	6.13E-24
281.5	2.12E-01	1.57E-19	2.75E-22
282	2.67E-01	1.19E-18	2.83E-21
282.5	3.03E-01	4.54E-18	1.33E-20
283	3.25E-01	1.85E-17	6.76E-20
283.5	3.23E-01	3.54E-17	1.46E-19
284	2.99E-01	7.27E-16	4.98E-18
284.5	2.50E-01	2.49E-15	2.16E-17
285	1.76E-01	8.01E-15	9.00E-17
285.5	1.55E-01	4.26E-14	6.44E-16
286	2.42E-01	1.37E-13	2.35E-15
286.5	3.33E-01	8.38E-13	1.85E-14
287	3.62E-01	2.74E-12	7.25E-14
287.5	3.39E-01	1.09E-11	3.66E-13
288	3.11E-01	6.23E-11	2.81E-12
288.5	3.25E-01	1.72E-10	9.07E-12
289	3.92E-01	5.63E-10	3.50E-11
289.5	4.79E-01	2.07E-09	1.54E-10
290	5.63E-01	6.02E-09	5.15E-10
290.5	6.06E-01	1.38E-08	1.33E-09
291	6.18E-01	3.51E-08	3.90E-09
291.5	5.98E-01	1.09E-07	1.44E-08
292	5.67E-01	2.68E-07	4.08E-08
292.5	5.29E-01	4.27E-07	7.04E-08
293	5.38E-01	8.65E-07	1.58E-07
293.5	5.49E-01	2.27E-06	4.71E-07
294	5.33E-01	4.17E-06	9.46E-07
294.5	5.20E-01	6.59E-06	1.60E-06
295	5.27E-01	1.23E-05	3.22E-06
295.5	5.59E-01	2.78E-05	8.02E-06
296	5.73E-01	4.79E-05	1.47E-05
296.5	5.21E-01	7.13E-05	2.33E-05
297	4.78E-01	9.68E-05	3.32E-05
297.5	5.29E-01	1.86E-04	6.79E-05
298	5.28E-01	2.90E-04	1.11E-04
298.5	4.68E-01	3.58E-04	1.43E-04
299	4.72E-01	4.92E-04	2.03E-04
299.5	5.01E-01	8.61E-04	3.74E-04
300	4.58E-01	1.02E-03	4.56E-04
300.5	4.33E-01	1.25E-03	5.72E-04
301	4.63E-01	1.93E-03	9.19E-04
301.5	4.78E-01	2.69E-03	1.32E-03
302	4.49E-01	2.92E-03	1.46E-03
302.5	5.08E-01	4.28E-03	2.19E-03
303	6.12E-01	7.09E-03	3.73E-03
303.5	6.46E-01	8.98E-03	4.80E-03
304	6.21E-01	9.47E-03	5.10E-03
304.5	6.26E-01	1.20E-02	6.47E-03
305	6.42E-01	1.65E-02	8.93E-03
305.5	6.11E-01	1.87E-02	1.02E-02
306	5.65E-01	1.86E-02	1.02E-02
306.5	5.75E-01	2.11E-02	1.16E-02
307	6.05E-01	2.78E-02	1.52E-02
307.5	6.31E-01	3.56E-02	1.95E-02
308	6.45E-01	3.78E-02	2.08E-02
308.5	6.41E-01	4.14E-02	2.28E-02
309	5.80E-01	4.05E-02	2.23E-02
309.5	5.00E-01	4.33E-02	2.37E-02
310	5.33E-01	5.09E-02	2.78E-02
310.5	6.52E-01	6.55E-02	3.59E-02
311	7.62E-01	8.29E-02	4.54E-02
311.5	7.44E-01	8.41E-02	4.62E-02
312	7.06E-01	9.34E-02	5.09E-02
312.5	6.76E-01	9.90E-02	5.38E-02
313	6.94E-01	1.07E-01	5.83E-02
313.5	7.24E-01	1.08E-01	5.90E-02
314	7.17E-01	1.20E-01	6.53E-02
314.5	6.76E-01	1.31E-01	7.05E-02
315	6.85E-01	1.36E-01	7.37E-02
315.5	6.32E-01	1.18E-01	6.48E-02
316	5.87E-01	1.23E-01	6.71E-02
316.5	6.49E-01	1.50E-01	8.11E-02
317	7.39E-01	1.72E-01	9.30E-02
317.5	8.02E-01	1.82E-01	9.97E-02
318	7.24E-01	1.76E-01	9.58E-02
318.5	6.80E-01	1.86E-01	1.00E-01
319	7.06E-01	2.05E-01	1.10E-01
319.5	7.33E-01	1.96E-01	1.07E-01
320	7.75E-01	2.05E-01	1.13E-01
320.5	8.26E-01	2.45E-01	1.33E-01
321	7.65E-01	2.50E-01	1.34E-01
321.5	7.19E-01	2.38E-01	1.28E-01
322	7.35E-01	2.22E-01	1.22E-01
322.5	7.12E-01	2.17E-01	1.20E-01
323	6.49E-01	2.12E-01	1.16E-01
323.5	6.81E-01	2.49E-01	1.34E-01
324	7.41E-01	2.75E-01	1.49E-01
324.5	7.88E-01	2.83E-01	1.55E-01
325	8.29E-01	2.79E-01	1.55E-01
325.5	9.14E-01	3.24E-01	1.79E-01
326	9.98E-01	3.81E-01	2.09E-01
326.5	1.02E+00	4.07E-01	2.22E-01
327	1.00E+00	3.98E-01	2.18E-01
327.5	9.87E-01	3.85E-01	2.13E-01
328	9.57E-01	3.51E-01	1.98E-01
328.5	9.34E-01	3.72E-01	2.07E-01
329	1.00E+00	4.22E-01	2.33E-01
329.5	1.10E+00	4.69E-01	2.59E-01
330	1.11E+00	4.71E-01	2.62E-01
330.5	1.04E+00	4.28E-01	2.41E-01
331	9.91E-01	4.03E-01	2.28E-01
331.5	9.94E-01	4.18E-01	2.36E-01
332	9.93E-01	4.36E-01	2.45E-01
332.5	9.80E-01	4.39E-01	2.47E-01
333	9.64E-01	4.29E-01	2.43E-01
333.5	9.37E-01	4.07E-01	2.33E-01
334	9.56E-01	4.15E-01	2.38E-01
334.5	9.89E-01	4.45E-01	2.54E-01
335	1.01E+00	4.64E-01	2.65E-01
335.5	9.75E-01	4.53E-01	2.59E-01
336	8.90E-01	4.15E-01	2.38E-01
336.5	8.29E-01	3.82E-01	2.21E-01
337	8.18E-01	3.74E-01	2.18E-01
337.5	8.77E-01	4.01E-01	2.34E-01
338	9.25E-01	4.34E-01	2.53E-01
338.5	9.58E-01	4.55E-01	2.65E-01
339	9.69E-01	4.64E-01	2.71E-01
339.5	9.89E-01	4.74E-01	2.78E-01
340	1.05E+00	5.02E-01	2.97E-01
340.5	1.05E+00	5.01E-01	2.97E-01
341	9.71E-01	4.71E-01	2.79E-01
341.5	9.59E-01	4.69E-01	2.79E-01
342	9.96E-01	4.89E-01	2.91E-01
342.5	1.03E+00	5.08E-01	3.03E-01
343	1.04E+00	5.15E-01	3.09E-01
343.5	9.83E-01	4.86E-01	2.92E-01
344	8.54E-01	4.18E-01	2.54E-01
344.5	8.13E-01	4.03E-01	2.44E-01
345	9.16E-01	4.59E-01	2.79E-01
345.5	9.70E-01	4.89E-01	2.98E-01
346	9.43E-01	4.78E-01	2.91E-01
346.5	9.56E-01	4.87E-01	2.97E-01
347	9.70E-01	4.94E-01	3.03E-01
347.5	9.33E-01	4.77E-01	2.94E-01
348	9.25E-01	4.75E-01	2.93E-01
348.5	9.37E-01	4.83E-01	2.99E-01
349	8.99E-01	4.66E-01	2.89E-01
349.5	9.20E-01	4.78E-01	2.97E-01
350	1.01E+00	5.28E-01	3.29E-01
350.5	1.08E+00	5.67E-01	3.55E-01
351	1.05E+00	5.52E-01	3.46E-01
351.5	1.01E+00	5.30E-01	3.34E-01
352	9.84E-01	5.18E-01	3.27E-01
352.5	9.26E-01	4.90E-01	3.10E-01
353	9.80E-01	5.20E-01	3.30E-01
353.5	1.08E+00	5.72E-01	3.64E-01
354	1.13E+00	6.05E-01	3.85E-01
354.5	1.14E+00	6.12E-01	3.90E-01
355	1.14E+00	6.11E-01	3.91E-01
355.5	1.10E+00	5.90E-01	3.79E-01
356	1.03E+00	5.54E-01	3.56E-01
356.5	9.59E-01	5.19E-01	3.35E-01
357	8.42E-01	4.57E-01	2.95E-01
357.5	8.50E-01	4.62E-01	3.00E-01
358	7.89E-01	4.30E-01	2.79E-01
358.5	7.31E-01	3.99E-01	2.60E-01
359	8.58E-01	4.70E-01	3.07E-01
359.5	1.03E+00	5.65E-01	3.70E-01
360	1.09E+00	5.98E-01	3.92E-01
360.5	1.03E+00	5.65E-01	3.72E-01
361	9.42E-01	5.20E-01	3.43E-01
361.5	9.18E-01	5.10E-01	3.36E-01
362	9.58E-01	5.34E-01	3.54E-01
362.5	1.05E+00	5.85E-01	3.88E-01
363	1.07E+00	6.02E-01	4.00E-01
363.5	1.04E+00	5.85E-01	3.90E-01
364	1.07E+00	6.06E-01	4.05E-01
364.5	1.06E+00	6.01E-01	4.02E-01
365	1.10E+00	6.24E-01	4.18E-01
365.5	1.20E+00	6.86E-01	4.61E-01
366	1.29E+00	7.35E-01	4.95E-01
366.5	1.28E+00	7.37E-01	4.97E-01
367	1.26E+00	7.23E-01	4.89E-01
367.5	1.23E+00	7.09E-01	4.80E-01
368	1.16E+00	6.68E-01	4.53E-01
368.5	1.15E+00	6.63E-01	4.51E-01
369	1.19E+00	6.93E-01	4.72E-01
369.5	1.28E+00	7.45E-01	5.09E-01
370	1.29E+00	7.55E-01	5.17E-01
370.5	1.17E+00	6.83E-01	4.68E-01
371	1.18E+00	6.93E-01	4.76E-01
371.5	1.22E+00	7.21E-01	4.96E-01
372	1.14E+00	6.74E-01	4.65E-01
372.5	1.09E+00	6.43E-01	4.44E-01
373	1.04E+00	6.19E-01	4.28E-01
373.5	9.39E-01	5.58E-01	3.87E-01
374	9.34E-01	5.56E-01	3.87E-01
374.5	9.25E-01	5.52E-01	3.84E-01
375	9.85E-01	5.89E-01	4.11E-01
375.5	1.09E+00	6.52E-01	4.55E-01
376	1.12E+00	6.75E-01	4.72E-01
376.5	1.10E+00	6.64E-01	4.65E-01
377	1.18E+00	7.12E-01	5.00E-01
377.5	1.31E+00	7.95E-01	5.59E-01
378	1.41E+00	8.56E-01	6.03E-01
378.5	1.38E+00	8.34E-01	5.89E-01
379	1.23E+00	7.44E-01	5.26E-01
379.5	1.10E+00	6.67E-01	4.73E-01
380	1.15E+00	7.01E-01	4.98E-01
380.5	1.23E+00	7.51E-01	5.34E-01
381	1.25E+00	7.64E-01	5.44E-01
381.5	1.12E+00	6.88E-01	4.91E-01
382	9.54E-01	5.87E-01	4.20E-01
382.5	8.23E-01	5.08E-01	3.64E-01
383	7.36E-01	4.55E-01	3.26E-01
383.5	7.11E-01	4.40E-01	3.17E-01
384	8.21E-01	5.10E-01	3.67E-01
384.5	9.86E-01	6.14E-01	4.42E-01
385	1.08E+00	6.74E-01	4.86E-01
385.5	1.03E+00	6.44E-01	4.65E-01
386	9.91E-01	6.21E-01	4.50E-01
386.5	1.03E+00	6.46E-01	4.68E-01
387	1.04E+00	6.51E-01	4.73E-01
387.5	1.02E+00	6.42E-01	4.67E-01
388	1.01E+00	6.36E-01	4.64E-01
388.5	9.97E-01	6.31E-01	4.61E-01
389	1.08E+00	6.85E-01	5.01E-01
389.5	1.20E+00	7.60E-01	5.56E-01
390	1.25E+00	7.97E-01	5.85E-01
390.5	1.26E+00	8.04E-01	5.90E-01
391	1.33E+00	8.51E-01	6.26E-01
391.5	1.35E+00	8.63E-01	6.36E-01
392	1.24E+00	7.95E-01	5.87E-01
392.5	1.03E+00	6.63E-01	4.90E-01
393	7.45E-01	4.80E-01	3.55E-01
393.5	5.91E-01	3.82E-01	2.83E-01
394	7.67E-01	4.96E-01	3.68E-01
394.5	1.06E+00	6.84E-01	5.08E-01
395	1.25E+00	8.08E-01	6.01E-01
395.5	1.32E+00	8.60E-01	6.41E-01
396	1.16E+00	7.57E-01	5.64E-01
396.5	8.43E-01	5.50E-01	4.11E-01
397	6.52E-01	4.26E-01	3.19E-01
397.5	9.61E-01	6.29E-01	4.72E-01
398	1.30E+00	8.52E-01	6.39E-01
398.5	1.53E+00	1.01E+00	7.56E-01
399	1.62E+00	1.07E+00	8.04E-01
399.5	1.67E+00	1.10E+00	8.30E-01
400	1.69E+00	1.11E+00	8.40E-01
401	1.75E+00	1.16E+00	8.77E-01
402	1.81E+00	1.21E+00	9.14E-01
403	1.74E+00	1.16E+00	8.82E-01
404	1.76E+00	1.18E+00	8.98E-01
405	1.72E+00	1.15E+00	8.78E-01
406	1.67E+00	1.12E+00	8.59E-01
407	1.63E+00	1.10E+00	8.45E-01
408	1.70E+00	1.15E+00	8.85E-01
409	1.81E+00	1.23E+00	9.47E-01
410	1.54E+00	1.05E+00	8.09E-01
411	1.72E+00	1.17E+00	9.08E-01
412	1.82E+00	1.25E+00	9.67E-01
413	1.74E+00	1.20E+00	9.30E-01
414	1.71E+00	1.18E+00	9.21E-01
415	1.77E+00	1.23E+00	9.56E-01
416	1.82E+00	1.26E+00	9.86E-01
417	1.77E+00	1.23E+00	9.64E-01
418	1.69E+00	1.18E+00	9.24E-01
419	1.75E+00	1.23E+00	9.64E-01
420	1.60E+00	1.12E+00	8.85E-01
421	1.81E+00	1.28E+00	1.01E+00
422	1.78E+00	1.26E+00	9.95E-01
423	1.72E+00	1.22E+00	9.65E-01
424	1.71E+00	1.21E+00	9.62E-01
425	1.76E+00	1.25E+00	9.93E-01
426	1.70E+00	1.21E+00	9.67E-01
427	1.64E+00	1.17E+00	9.36E-01
428	1.65E+00	1.18E+00	9.46E-01
429	1.52E+00	1.10E+00	8.78E-01
430	1.21E+00	8.75E-01	7.01E-01
431	1.10E+00	7.94E-01	6.38E-01
432	1.82E+00	1.32E+00	1.06E+00
433	1.69E+00	1.23E+00	9.91E-01
434	1.56E+00	1.14E+00	9.17E-01
435	1.71E+00	1.25E+00	1.01E+00
436	1.87E+00	1.37E+00	1.11E+00
437	1.90E+00	1.39E+00	1.13E+00
438	1.66E+00	1.22E+00	9.94E-01
439	1.60E+00	1.18E+00	9.58E-01
440	1.83E+00	1.35E+00	1.10E+00
441	1.80E+00	1.33E+00	1.09E+00
442	1.92E+00	1.43E+00	1.16E+00
443	1.95E+00	1.45E+00	1.18E+00
444	1.89E+00	1.41E+00	1.15E+00
445	1.97E+00	1.46E+00	1.20E+00
446	1.76E+00	1.31E+00	1.08E+00
447	1.99E+00	1.49E+00	1.23E+00
448	2.01E+00	1.51E+00	1.24E+00
449	2.00E+00	1.50E+00	1.24E+00
450	2.07E+00	1.56E+00	1.29E+00
451	2.14E+00	1.62E+00	1.34E+00
452	2.05E+00	1.55E+00	1.28E+00
453	1.89E+00	1.43E+00	1.19E+00
454	2.02E+00	1.53E+00	1.27E+00
455	2.00E+00	1.52E+00	1.27E+00
456	2.06E+00	1.57E+00	1.31E+00
457	2.08E+00	1.59E+00	1.32E+00
458	2.03E+00	1.55E+00	1.29E+00
459	2.01E+00	1.54E+00	1.29E+00
460	2.00E+00	1.53E+00	1.28E+00
461	2.06E+00	1.58E+00	1.33E+00
462	2.08E+00	1.60E+00	1.34E+00
463	2.08E+00	1.60E+00	1.35E+00
464	2.02E+00	1.55E+00	1.31E+00
465	1.98E+00	1.54E+00	1.29E+00
466	2.02E+00	1.57E+00	1.32E+00
467	1.93E+00	1.50E+00	1.26E+00
468	2.01E+00	1.56E+00	1.32E+00
469	2.02E+00	1.57E+00	1.32E+00
470	1.94E+00	1.51E+00	1.27E+00
471	1.97E+00	1.53E+00	1.30E+00
472	2.07E+00	1.61E+00	1.37E+00
473	1.99E+00	1.55E+00	1.31E+00
474	2.01E+00	1.57E+00	1.33E+00
475	2.08E+00	1.62E+00	1.38E+00
476	2.01E+00	1.56E+00	1.33E+00
477	2.03E+00	1.57E+00	1.34E+00
478	2.09E+00	1.62E+00	1.38E+00
479	2.04E+00	1.59E+00	1.36E+00
480	2.07E+00	1.62E+00	1.38E+00
481	2.06E+00	1.62E+00	1.38E+00
482	2.06E+00	1.62E+00	1.39E+00
483	2.03E+00	1.60E+00	1.37E+00
484	1.99E+00	1.57E+00	1.35E+00
485	1.98E+00	1.57E+00	1.35E+00
486	1.60E+00	1.27E+00	1.09E+00
487	1.79E+00	1.42E+00	1.22E+00
488	1.94E+00	1.54E+00	1.33E+00
489	1.82E+00	1.45E+00	1.25E+00
490	2.03E+00	1.62E+00	1.40E+00
491	1.95E+00	1.56E+00	1.34E+00
492	1.86E+00	1.49E+00	1.28E+00
493	1.98E+00	1.59E+00	1.37E+00
494	1.93E+00	1.55E+00	1.34E+00
495	2.05E+00	1.65E+00	1.42E+00
496	1.95E+00	1.57E+00	1.35E+00
497	1.98E+00	1.59E+00	1.38E+00
498	1.92E+00	1.55E+00	1.34E+00
499	1.92E+00	1.55E+00	1.34E+00
500	1.92E+00	1.55E+00	1.34E+00
501	1.86E+00	1.50E+00	1.30E+00
502	1.86E+00	1.50E+00	1.30E+00
503	1.95E+00	1.57E+00	1.36E+00
504	1.83E+00	1.46E+00	1.27E+00
505	1.95E+00	1.56E+00	1.36E+00
506	2.03E+00	1.63E+00	1.42E+00
507	1.94E+00	1.56E+00	1.35E+00
508	1.88E+00	1.52E+00	1.32E+00
509	1.97E+00	1.59E+00	1.39E+00
510	1.91E+00	1.55E+00	1.35E+00
511	1.94E+00	1.58E+00	1.38E+00
512	1.99E+00	1.62E+00	1.41E+00
513	1.87E+00	1.52E+00	1.33E+00
514	1.82E+00	1.49E+00	1.30E+00
515	1.88E+00	1.53E+00	1.34E+00
516	1.89E+00	1.55E+00	1.35E+00
517	1.54E+00	1.26E+00	1.10E+00
518	1.76E+00	1.44E+00	1.26E+00
519	1.70E+00	1.40E+00	1.22E+00
520	1.86E+00	1.52E+00	1.33E+00
521	1.87E+00	1.53E+00	1.35E+00
522	1.92E+00	1.57E+00	1.38E+00
523	1.80E+00	1.48E+00	1.30E+00
524	1.94E+00	1.59E+00	1.40E+00
525	1.93E+00	1.58E+00	1.39E+00
526	1.87E+00	1.53E+00	1.35E+00
527	1.64E+00	1.34E+00	1.18E+00
528	1.88E+00	1.54E+00	1.35E+00
529	1.97E+00	1.61E+00	1.41E+00
530	1.89E+00	1.54E+00	1.36E+00
531	2.00E+00	1.63E+00	1.43E+00
532	1.96E+00	1.60E+00	1.41E+00
533	1.75E+00	1.43E+00	1.26E+00
534	1.87E+00	1.53E+00	1.35E+00
535	1.90E+00	1.55E+00	1.37E+00
536	1.97E+00	1.62E+00	1.43E+00
537	1.82E+00	1.50E+00	1.32E+00
538	1.91E+00	1.57E+00	1.39E+00
539	1.86E+00	1.54E+00	1.36E+00
540	1.80E+00	1.48E+00	1.31E+00
541	1.73E+00	1.43E+00	1.26E+00
542	1.89E+00	1.55E+00	1.37E+00
543	1.85E+00	1.53E+00	1.35E+00
544	1.92E+00	1.58E+00	1.40E+00
545	1.87E+00	1.54E+00	1.37E+00
546	1.86E+00	1.53E+00	1.35E+00
547	1.88E+00	1.55E+00	1.37E+00
548	1.83E+00	1.50E+00	1.33E+00
549	1.88E+00	1.55E+00	1.38E+00
550	1.86E+00	1.54E+00	1.36E+00
551	1.86E+00	1.54E+00	1.36E+00
552	1.90E+00	1.57E+00	1.39E+00
553	1.84E+00	1.53E+00	1.35E+00
554	1.88E+00	1.55E+00	1.38E+00
555	1.89E+00	1.56E+00	1.39E+00
556	1.86E+00	1.54E+00	1.37E+00
557	1.81E+00	1.50E+00	1.33E+00
558	1.85E+00	1.53E+00	1.36E+00
559	1.76E+00	1.45E+00	1.29E+00
560	1.79E+00	1.47E+00	1.31E+00
561	1.89E+00	1.56E+00	1.39E+00
562	1.80E+00	1.48E+00	1.32E+00
563	1.87E+00	1.54E+00	1.37E+00
564	1.84E+00	1.51E+00	1.35E+00
565	1.85E+00	1.52E+00	1.36E+00
566	1.75E+00	1.44E+00	1.28E+00
567	1.87E+00	1.53E+00	1.37E+00
568	1.86E+00	1.52E+00	1.36E+00
569	1.83E+00	1.48E+00	1.32E+00
570	1.83E+00	1.48E+00	1.32E+00
571	1.76E+00	1.43E+00	1.28E+00
572	1.87E+00	1.51E+00	1.35E+00
573	1.88E+00	1.52E+00	1.36E+00
574	1.87E+00	1.51E+00	1.35E+00
575	1.83E+00	1.48E+00	1.32E+00
576	1.82E+00	1.47E+00	1.31E+00
577	1.86E+00	1.50E+00	1.35E+00
578	1.80E+00	1.46E+00	1.30E+00
579	1.82E+00	1.48E+00	1.32E+00
580	1.83E+00	1.50E+00	1.35E+00
581	1.83E+00	1.51E+00	1.35E+00
582	1.85E+00	1.53E+00	1.37E+00
583	1.86E+00	1.55E+00	1.39E+00
584	1.85E+00	1.54E+00	1.38E+00
585	1.84E+00	1.53E+00	1.37E+00
586	1.79E+00	1.50E+00	1.34E+00
587	1.84E+00	1.53E+00	1.37E+00
588	1.82E+00	1.49E+00	1.34E+00
589	1.62E+00	1.29E+00	1.16E+00
590	1.72E+00	1.37E+00	1.23E+00
591	1.81E+00	1.47E+00	1.32E+00
592	1.79E+00	1.44E+00	1.29E+00
593	1.79E+00	1.46E+00	1.31E+00
594	1.79E+00	1.45E+00	1.30E+00
595	1.78E+00	1.43E+00	1.29E+00
596	1.80E+00	1.47E+00	1.33E+00
597	1.81E+00	1.48E+00	1.33E+00
598	1.77E+00	1.46E+00	1.31E+00
599	1.76E+00	1.46E+00	1.31E+00
600	1.77E+00	1.48E+00	1.33E+00
601	1.74E+00	1.46E+00	1.31E+00
602	1.72E+00	1.44E+00	1.29E+00
603	1.75E+00	1.47E+00	1.32E+00
604	1.78E+00	1.49E+00	1.34E+00
605	1.77E+00	1.49E+00	1.34E+00
606	1.76E+00	1.48E+00	1.34E+00
607	1.76E+00	1.49E+00	1.34E+00
608	1.75E+00	1.49E+00	1.34E+00
609	1.73E+00	1.47E+00	1.33E+00
610	1.72E+00	1.47E+00	1.32E+00
611	1.71E+00	1.46E+00	1.32E+00
612	1.74E+00	1.48E+00	1.34E+00
613	1.71E+00	1.46E+00	1.32E+00
614	1.66E+00	1.42E+00	1.28E+00
615	1.71E+00	1.47E+00	1.33E+00
616	1.66E+00	1.43E+00	1.29E+00
617	1.64E+00	1.41E+00	1.27E+00
618	1.70E+00	1.47E+00	1.32E+00
619	1.71E+00	1.47E+00	1.33E+00
620	1.71E+00	1.47E+00	1.33E+00
621	1.72E+00	1.48E+00	1.34E+00
622	1.68E+00	1.43E+00	1.29E+00
623	1.68E+00	1.42E+00	1.28E+00
624	1.67E+00	1.41E+00	1.28E+00
625	1.64E+00	1.40E+00	1.27E+00
626	1.64E+00	1.40E+00	1.27E+00
627	1.69E+00	1.44E+00	1.30E+00
628	1.69E+00	1.36E+00	1.23E+00
629	1.69E+00	1.41E+00	1.28E+00
630	1.67E+00	1.39E+00	1.26E+00
631	1.66E+00	1.42E+00	1.28E+00
632	1.59E+00	1.36E+00	1.23E+00
633	1.67E+00	1.45E+00	1.31E+00
634	1.64E+00	1.43E+00	1.29E+00
635	1.65E+00	1.45E+00	1.31E+00
636	1.61E+00	1.41E+00	1.28E+00
637	1.66E+00	1.46E+00	1.32E+00
638	1.67E+00	1.47E+00	1.33E+00
639	1.65E+00	1.46E+00	1.32E+00
640	1.61E+00	1.43E+00	1.30E+00
641	1.61E+00	1.43E+00	1.30E+00
642	1.61E+00	1.44E+00	1.30E+00
643	1.63E+00	1.45E+00	1.31E+00
644	1.61E+00	1.45E+00	1.31E+00
645	1.63E+00	1.46E+00	1.32E+00
646	1.59E+00	1.42E+00	1.28E+00
647	1.61E+00	1.41E+00	1.27E+00
648	1.60E+00	1.40E+00	1.26E+00
649	1.55E+00	1.35E+00	1.22E+00
650	1.53E+00	1.36E+00	1.23E+00
651	1.61E+00	1.44E+00	1.31E+00
652	1.59E+00	1.39E+00	1.26E+00
653	1.60E+00	1.43E+00	1.30E+00
654	1.58E+00	1.42E+00	1.28E+00
655	1.52E+00	1.35E+00	1.22E+00
656	1.32E+00	1.19E+00	1.07E+00
657	1.38E+00	1.24E+00	1.12E+00
658	1.54E+00	1.39E+00	1.25E+00
659	1.54E+00	1.39E+00	1.26E+00
660	1.56E+00	1.40E+00	1.27E+00
661	1.57E+00	1.39E+00	1.26E+00
662	1.57E+00	1.38E+00	1.25E+00
663	1.56E+00	1.38E+00	1.25E+00
664	1.55E+00	1.40E+00	1.26E+00
665	1.57E+00	1.42E+00	1.29E+00
666	1.56E+00	1.42E+00	1.29E+00
667	1.54E+00	1.41E+00	1.28E+00
668	1.53E+00	1.42E+00	1.28E+00
669	1.56E+00	1.44E+00	1.30E+00
670	1.53E+00	1.42E+00	1.29E+00
671	1.53E+00	1.42E+00	1.28E+00
672	1.51E+00	1.40E+00	1.27E+00
673	1.52E+00	1.41E+00	1.28E+00
674	1.51E+00	1.41E+00	1.27E+00
675	1.50E+00	1.40E+00	1.26E+00
676	1.52E+00	1.41E+00	1.28E+00
677	1.50E+00	1.40E+00	1.27E+00
678	1.51E+00	1.41E+00	1.27E+00
679	1.49E+00	1.39E+00	1.26E+00
680	1.49E+00	1.40E+00	1.27E+00
681	1.49E+00	1.39E+00	1.26E+00
682	1.49E+00	1.40E+00	1.27E+00
683	1.48E+00	1.38E+00	1.25E+00
684	1.47E+00	1.37E+00	1.24E+00
685	1.47E+00	1.37E+00	1.25E+00
686	1.43E+00	1.34E+00	1.22E+00
687	1.47E+00	9.68E-01	8.83E-01
688	1.48E+00	1.12E+00	1.02E+00
689	1.48E+00	1.13E+00	1.03E+00
690	1.48E+00	1.18E+00	1.07E+00
691	1.47E+00	1.23E+00	1.12E+00
692	1.45E+00	1.27E+00	1.15E+00
693	1.46E+00	1.26E+00	1.14E+00
694	1.46E+00	1.25E+00	1.13E+00
695	1.44E+00	1.27E+00	1.15E+00
696	1.44E+00	1.27E+00	1.15E+00
697	1.44E+00	1.34E+00	1.22E+00
698	1.42E+00	1.32E+00	1.20E+00
699	1.43E+00	1.29E+00	1.17E+00
700	1.42E+00	1.28E+00	1.16E+00
701	1.41E+00	1.27E+00	1.15E+00
702	1.40E+00	1.27E+00	1.15E+00
703	1.41E+00	1.27E+00	1.16E+00
704	1.42E+00	1.31E+00	1.19E+00
705	1.43E+00	1.32E+00	1.20E+00
706	1.41E+00	1.31E+00	1.19E+00
707	1.40E+00	1.31E+00	1.19E+00
708	1.40E+00	1.30E+00	1.18E+00
709	1.39E+00	1.31E+00	1.19E+00
710	1.40E+00	1.32E+00	1.20E+00
711	1.40E+00	1.32E+00	1.19E+00
712	1.38E+00	1.31E+00	1.19E+00
713	1.37E+00	1.29E+00	1.17E+00
714	1.38E+00	1.30E+00	1.18E+00
715	1.35E+00	1.26E+00	1.14E+00
716	1.37E+00	1.27E+00	1.15E+00
717	1.37E+00	1.11E+00	1.01E+00
718	1.36E+00	1.03E+00	9.39E-01
719	1.30E+00	9.23E-01	8.43E-01
720	1.35E+00	9.86E-01	8.99E-01
721	1.35E+00	1.09E+00	9.90E-01
722	1.36E+00	1.24E+00	1.13E+00
723	1.35E+00	1.14E+00	1.04E+00
724	1.36E+00	1.06E+00	9.63E-01
725	1.35E+00	1.04E+00	9.47E-01
726	1.34E+00	1.08E+00	9.86E-01
727	1.34E+00	1.09E+00	9.90E-01
728	1.34E+00	1.04E+00	9.50E-01
729	1.28E+00	1.05E+00	9.55E-01
730	1.34E+00	1.13E+00	1.03E+00
731	1.31E+00	1.07E+00	9.77E-01
732	1.33E+00	1.15E+00	1.05E+00
733	1.31E+00	1.20E+00	1.09E+00
734	1.34E+00	1.24E+00	1.13E+00
735	1.33E+00	1.22E+00	1.11E+00
736	1.31E+00	1.21E+00	1.10E+00
737	1.31E+00	1.20E+00	1.10E+00
738	1.30E+00	1.23E+00	1.12E+00
739	1.26E+00	1.19E+00	1.09E+00
740	1.28E+00	1.22E+00	1.11E+00
741	1.27E+00	1.21E+00	1.11E+00
742	1.26E+00	1.22E+00	1.11E+00
743	1.29E+00	1.24E+00	1.13E+00
744	1.30E+00	1.25E+00	1.14E+00
745	1.29E+00	1.25E+00	1.14E+00
746	1.29E+00	1.25E+00	1.14E+00
747	1.29E+00	1.25E+00	1.14E+00
748	1.28E+00	1.24E+00	1.13E+00
749	1.28E+00	1.24E+00	1.13E+00
750	1.27E+00	1.23E+00	1.13E+00
751	1.27E+00	1.23E+00	1.12E+00
752	1.27E+00	1.23E+00	1.13E+00
753	1.27E+00	1.23E+00	1.12E+00
754	1.28E+00	1.24E+00	1.14E+00
755	1.28E+00	1.24E+00	1.13E+00
756	1.26E+00	1.22E+00	1.12E+00
757	1.26E+00	1.22E+00	1.12E+00
758	1.27E+00	1.23E+00	1.12E+00
759	1.25E+00	1.19E+00	1.09E+00
760	1.26E+00	2.66E-01	2.47E-01
761	1.25E+00	1.54E-01	1.43E-01
762	1.25E+00	6.88E-01	6.35E-01
763	1.25E+00	3.80E-01	3.52E-01
764	1.26E+00	5.39E-01	4.99E-01
765	1.25E+00	6.86E-01	6.34E-01
766	1.20E+00	8.15E-01	7.51E-01
767	1.21E+00	9.74E-01	8.96E-01
768	1.23E+00	1.11E+00	1.02E+00
769	1.21E+00	1.13E+00	1.03E+00
770	1.21E+00	1.16E+00	1.06E+00
771	1.21E+00	1.17E+00	1.07E+00
772	1.21E+00	1.18E+00	1.08E+00
773	1.21E+00	1.18E+00	1.08E+00
774	1.21E+00	1.18E+00	1.08E+00
775	1.21E+00	1.18E+00	1.08E+00
776	1.21E+00	1.18E+00	1.08E+00
777	1.20E+00	1.17E+00	1.08E+00
778	1.20E+00	1.17E+00	1.08E+00
779	1.21E+00	1.18E+00	1.08E+00
780	1.19E+00	1.16E+00	1.07E+00
781	1.19E+00	1.16E+00	1.07E+00
782	1.20E+00	1.17E+00	1.07E+00
783	1.19E+00	1.16E+00	1.07E+00
784	1.18E+00	1.15E+00	1.06E+00
785	1.19E+00	1.16E+00	1.06E+00
786	1.19E+00	1.16E+00	1.07E+00
787	1.19E+00	1.15E+00	1.05E+00
788	1.18E+00	1.13E+00	1.04E+00
789	1.18E+00	1.13E+00	1.04E+00
790	1.17E+00	1.09E+00	1.00E+00
791	1.16E+00	1.11E+00	1.02E+00
792	1.15E+00	1.10E+00	1.01E+00
793	1.14E+00	1.09E+00	1.00E+00
794	1.13E+00	1.10E+00	1.01E+00
795	1.13E+00	1.09E+00	1.01E+00
796	1.14E+00	1.07E+00	9.90E-01
797	1.16E+00	1.09E+00	1.01E+00
798	1.15E+00	1.11E+00	1.02E+00
799	1.14E+00	1.09E+00	1.00E+00
800	1.12E+00	1.07E+00	9.89E-01
801	1.14E+00	1.08E+00	1.00E+00
802	1.14E+00	1.09E+00	1.00E+00
803	1.12E+00	1.07E+00	9.83E-01
804	1.13E+00	1.08E+00	9.95E-01
805	1.10E+00	1.05E+00	9.73E-01
806	1.13E+00	1.10E+00	1.01E+00
807	1.12E+00	1.09E+00	1.00E+00
808	1.12E+00	1.08E+00	9.98E-01
809	1.10E+00	1.05E+00	9.74E-01
810	1.11E+00	1.06E+00	9.75E-01
811	1.11E+00	1.05E+00	9.73E-01
812	1.12E+00	1.03E+00	9.49E-01
813	1.12E+00	1.01E+00	9.32E-01
814	1.12E+00	9.04E-01	8.37E-01
815	1.11E+00	8.95E-01	8.29E-01
816	1.11E+00	8.32E-01	7.72E-01
817	1.11E+00	8.52E-01	7.90E-01
818	1.09E+00	8.23E-01	7.63E-01
819	1.07E+00	9.05E-01	8.38E-01
820	1.07E+00	8.62E-01	7.99E-01
821	1.08E+00	9.98E-01	9.23E-01
822	1.06E+00	9.52E-01	8.81E-01
823	1.08E+00	6.73E-01	6.26E-01
824	1.07E+00	9.35E-01	8.66E-01
825	1.07E+00	9.69E-01	8.98E-01
826	1.08E+00	9.34E-01	8.65E-01
827	1.08E+00	9.85E-01	9.12E-01
828	1.07E+00	8.50E-01	7.89E-01
829	1.06E+00	9.29E-01	8.61E-01
830	1.06E+00	9.16E-01	8.49E-01
831	1.06E+00	9.24E-01	8.57E-01
832	1.06E+00	8.94E-01	8.30E-01
833	1.03E+00	9.57E-01	8.86E-01
834	1.05E+00	9.34E-01	8.66E-01
835	1.05E+00	1.00E+00	9.29E-01
836	1.06E+00	9.72E-01	9.01E-01
837	1.05E+00	1.01E+00	9.35E-01
838	1.05E+00	9.99E-01	9.26E-01
839	1.04E+00	1.00E+00	9.28E-01
840	1.05E+00	1.02E+00	9.41E-01
841	1.05E+00	1.01E+00	9.36E-01
842	1.03E+00	9.97E-01	9.24E-01
843	1.03E+00	1.01E+00	9.32E-01
844	1.01E+00	9.86E-01	9.14E-01
845	1.04E+00	1.02E+00	9.42E-01
846	1.04E+00	1.02E+00	9.44E-01
847	1.01E+00	9.92E-01	9.19E-01
848	1.01E+00	9.92E-01	9.20E-01
849	1.01E+00	9.86E-01	9.14E-01
850	9.10E-01	8.94E-01	8.29E-01
851	9.98E-01	9.75E-01	9.05E-01
852	9.90E-01	9.69E-01	8.99E-01
853	9.81E-01	9.65E-01	8.95E-01
854	8.69E-01	8.51E-01	7.90E-01
855	9.27E-01	9.13E-01	8.47E-01
856	9.90E-01	9.73E-01	9.03E-01
857	1.01E+00	9.92E-01	9.21E-01
858	1.01E+00	9.92E-01	9.21E-01
859	1.01E+00	9.92E-01	9.21E-01
860	1.00E+00	9.88E-01	9.18E-01
861	9.99E-01	9.87E-01	9.16E-01
862	1.01E+00	9.94E-01	9.24E-01
863	1.01E+00	1.00E+00	9.29E-01
864	9.90E-01	9.79E-01	9.10E-01
865	9.74E-01	9.63E-01	8.95E-01
866	8.58E-01	8.49E-01	7.89E-01
867	9.25E-01	9.15E-01	8.51E-01
868	9.69E-01	9.59E-01	8.91E-01
869	9.59E-01	9.50E-01	8.83E-01
870	9.77E-01	9.68E-01	8.99E-01
871	9.63E-01	9.54E-01	8.87E-01
872	9.76E-01	9.67E-01	8.99E-01
873	9.66E-01	9.57E-01	8.90E-01
874	9.49E-01	9.40E-01	8.75E-01
875	9.36E-01	9.27E-01	8.62E-01
876	9.62E-01	9.53E-01	8.86E-01
877	9.65E-01	9.56E-01	8.89E-01
878	9.62E-01	9.52E-01	8.86E-01
879	9.46E-01	9.37E-01	8.71E-01
880	9.49E-01	9.40E-01	8.74E-01
881	9.20E-01	9.09E-01	8.46E-01
882	9.44E-01	9.32E-01	8.68E-01
883	9.39E-01	9.29E-01	8.65E-01
884	9.44E-01	9.33E-01	8.69E-01
885	9.55E-01	9.44E-01	8.79E-01
886	9.26E-01	9.08E-01	8.45E-01
887	9.23E-01	9.11E-01	8.48E-01
888	9.41E-01	9.22E-01	8.59E-01
889	9.44E-01	9.35E-01	8.70E-01
890	9.42E-01	9.24E-01	8.61E-01
891	9.39E-01	9.26E-01	8.63E-01
892	9.33E-01	9.09E-01	8.47E-01
893	9.18E-01	8.73E-01	8.14E-01
894	9.24E-01	8.51E-01	7.94E-01
895	9.26E-01	8.14E-01	7.60E-01
896	9.34E-01	7.63E-01	7.13E-01
897	9.27E-01	6.66E-01	6.23E-01
898	9.24E-01	7.18E-01	6.71E-01
899	9.14E-01	5.49E-01	5.15E-01
900	9.14E-01	7.43E-01	6.94E-01
901	8.98E-01	5.99E-01	5.62E-01
902	8.77E-01	6.68E-01	6.25E-01
903	9.22E-01	6.89E-01	6.45E-01
904	9.21E-01	8.45E-01	7.89E-01
905	9.18E-01	8.17E-01	7.63E-01
906	9.08E-01	7.76E-01	7.25E-01
907	9.15E-01	6.39E-01	5.98E-01
908	9.01E-01	6.52E-01	6.11E-01
909	8.86E-01	7.04E-01	6.59E-01
910	8.95E-01	6.25E-01	5.86E-01
911	8.97E-01	6.68E-01	6.26E-01
912	8.90E-01	6.89E-01	6.45E-01
913	9.00E-01	6.28E-01	5.89E-01
914	8.98E-01	6.26E-01	5.87E-01
915	8.88E-01	6.78E-01	6.36E-01
916	8.95E-01	5.76E-01	5.41E-01
917	8.89E-01	7.30E-01	6.84E-01
918	8.88E-01	5.93E-01	5.56E-01
919	8.92E-01	7.39E-01	6.92E-01
920	8.85E-01	7.44E-01	6.97E-01
921	8.70E-01	7.80E-01	7.30E-01
922	8.63E-01	7.00E-01	6.56E-01
923	8.33E-01	7.45E-01	6.97E-01
924	8.70E-01	7.22E-01	6.76E-01
925	8.76E-01	7.11E-01	6.66E-01
926	8.46E-01	7.03E-01	6.59E-01
927	8.78E-01	7.87E-01	7.37E-01
928	8.71E-01	5.90E-01	5.54E-01
929	8.70E-01	5.51E-01	5.18E-01
930	8.69E-01	4.32E-01	4.07E-01
931	8.71E-01	4.09E-01	3.85E-01
932	8.65E-01	3.01E-01	2.84E-01
933	8.70E-01	2.48E-01	2.35E-01
934	8.67E-01	1.44E-01	1.36E-01
935	8.56E-01	2.51E-01	2.37E-01
936	8.52E-01	1.61E-01	1.53E-01
937	8.54E-01	1.63E-01	1.55E-01
938	8.59E-01	2.01E-01	1.90E-01
939	8.57E-01	3.99E-01	3.76E-01
940	8.40E-01	4.72E-01	4.44E-01
941	8.32E-01	3.72E-01	3.51E-01
942	8.06E-01	4.05E-01	3.82E-01
943	8.38E-01	2.78E-01	2.63E-01
944	8.19E-01	2.86E-01	2.70E-01
945	8.24E-01	3.68E-01	3.47E-01
946	8.31E-01	1.95E-01	1.84E-01
947	8.28E-01	3.71E-01	3.50E-01
948	8.31E-01	2.74E-01	2.59E-01
949	8.33E-01	4.94E-01	4.65E-01
950	8.29E-01	1.47E-01	1.39E-01
951	8.20E-01	4.84E-01	4.56E-01
952	8.24E-01	2.69E-01	2.54E-01
953	8.21E-01	3.44E-01	3.24E-01
954	8.12E-01	4.24E-01	4.00E-01
955	7.69E-01	3.41E-01	3.22E-01
956	8.02E-01	3.28E-01	3.10E-01
957	8.06E-01	2.71E-01	2.56E-01
958	8.11E-01	4.61E-01	4.35E-01
959	8.15E-01	3.74E-01	3.53E-01
960	8.06E-01	4.21E-01	3.97E-01
961	8.00E-01	4.61E-01	4.35E-01
962	8.02E-01	4.42E-01	4.17E-01
963	7.98E-01	5.05E-01	4.76E-01
964	7.88E-01	4.59E-01	4.32E-01
965	7.96E-01	5.04E-01	4.75E-01
966	7.86E-01	5.03E-01	4.74E-01
967	7.95E-01	5.02E-01	4.74E-01
968	7.85E-01	6.52E-01	6.13E-01
969	7.88E-01	6.86E-01	6.45E-01
970	7.91E-01	6.35E-01	5.97E-01
971	7.82E-01	7.14E-01	6.71E-01
972	7.88E-01	6.88E-01	6.46E-01
973	7.81E-01	6.06E-01	5.71E-01
974	7.69E-01	5.75E-01	5.42E-01
975	7.73E-01	5.90E-01	5.55E-01
976	7.81E-01	5.72E-01	5.39E-01
977	7.72E-01	6.39E-01	6.01E-01
978	7.78E-01	6.15E-01	5.79E-01
979	7.67E-01	6.38E-01	6.00E-01
980	7.75E-01	6.05E-01	5.69E-01
981	7.73E-01	7.13E-01	6.71E-01
982	7.79E-01	6.92E-01	6.51E-01
983	7.75E-01	6.69E-01	6.29E-01
984	7.69E-01	7.37E-01	6.93E-01
985	7.71E-01	6.88E-01	6.47E-01
986	7.66E-01	7.51E-01	7.06E-01
987	7.66E-01	7.39E-01	6.95E-01
988	7.64E-01	7.35E-01	6.91E-01
989	7.55E-01	7.49E-01	7.04E-01
990	7.57E-01	7.32E-01	6.88E-01
991	7.62E-01	7.54E-01	7.08E-01
992	7.57E-01	7.51E-01	7.06E-01
993	7.56E-01	7.37E-01	6.93E-01
994	7.59E-01	7.54E-01	7.09E-01
995	7.54E-01	7.52E-01	7.07E-01
996	7.53E-01	7.49E-01	7.04E-01
997	7.43E-01	7.40E-01	6.96E-01
998	7.43E-01	7.39E-01	6.95E-01
999	7.42E-01	7.39E-01	6.95E-01
1000	7.43E-01	7.35E-01	6.92E-01
1001	7.47E-01	7.44E-01	7.00E-01
1002	7.47E-01	7.28E-01	6.85E-01
1003	7.38E-01	7.34E-01	6.91E-01
1004	7.31E-01	7.23E-01	6.81E-01
1005	6.84E-01	6.82E-01	6.41E-01
1006	7.18E-01	7.13E-01	6.70E-01
1007	7.31E-01	7.28E-01	6.85E-01
1008	7.33E-01	7.27E-01	6.84E-01
1009	7.29E-01	7.20E-01	6.77E-01
1010	7.31E-01	7.19E-01	6.77E-01
1011	7.26E-01	7.23E-01	6.80E-01
1012	7.25E-01	7.19E-01	6.77E-01
1013	7.20E-01	7.18E-01	6.76E-01
1014	7.23E-01	7.21E-01	6.78E-01
1015	7.11E-01	7.08E-01	6.67E-01
1016	7.14E-01	7.11E-01	6.70E-01
1017	7.07E-01	7.03E-01	6.62E-01
1018	7.16E-01	7.14E-01	6.73E-01
1019	6.96E-01	6.89E-01	6.49E-01
1020	7.01E-01	6.99E-01	6.58E-01
1021	7.03E-01	7.02E-01	6.61E-01
1022	6.93E-01	6.90E-01	6.50E-01
1023	6.99E-01	6.95E-01	6.55E-01
1024	7.01E-01	6.91E-01	6.51E-01
1025	6.99E-01	6.98E-01	6.57E-01
1026	6.99E-01	6.96E-01	6.56E-01
1027	6.96E-01	6.93E-01	6.53E-01
1028	6.97E-01	6.94E-01	6.54E-01
1029	6.90E-01	6.86E-01	6.47E-01
1030	6.92E-01	6.91E-01	6.51E-01
1031	6.90E-01	6.87E-01	6.48E-01
1032	6.90E-01	6.88E-01	6.49E-01
1033	6.78E-01	6.76E-01	6.38E-01
1034	6.82E-01	6.80E-01	6.41E-01
1035	6.84E-01	6.82E-01	6.43E-01
1036	6.84E-01	6.82E-01	6.43E-01
1037	6.77E-01	6.75E-01	6.37E-01
1038	6.74E-01	6.72E-01	6.34E-01
1039	6.79E-01	6.76E-01	6.38E-01
1040	6.74E-01	6.72E-01	6.34E-01
1041	6.75E-01	6.72E-01	6.34E-01
1042	6.75E-01	6.72E-01	6.34E-01
1043	6.69E-01	6.65E-01	6.28E-01
1044	6.72E-01	6.68E-01	6.31E-01
1045	6.68E-01	6.65E-01	6.27E-01
1046	6.51E-01	6.47E-01	6.11E-01
1047	6.62E-01	6.57E-01	6.20E-01
1048	6.68E-01	6.63E-01	6.26E-01
1049	6.65E-01	6.59E-01	6.22E-01
1050	6.61E-01	6.55E-01	6.18E-01
1051	6.62E-01	6.55E-01	6.19E-01
1052	6.58E-01	6.51E-01	6.15E-01
1053	6.57E-01	6.49E-01	6.13E-01
1054	6.55E-01	6.46E-01	6.10E-01
1055	6.58E-01	6.48E-01	6.12E-01
1056	6.56E-01	6.46E-01	6.11E-01
1057	6.55E-01	6.45E-01	6.09E-01
1058	6.49E-01	6.38E-01	6.03E-01
1059	6.30E-01	6.19E-01	5.85E-01
1060	6.48E-01	6.36E-01	6.01E-01
1061	6.34E-01	6.21E-01	5.87E-01
1062	6.47E-01	6.33E-01	5.98E-01
1063	6.37E-01	6.22E-01	5.88E-01
1064	6.46E-01	6.32E-01	5.97E-01
1065	6.45E-01	6.29E-01	5.95E-01
1066	6.31E-01	6.17E-01	5.83E-01
1067	6.35E-01	6.20E-01	5.86E-01
1068	6.36E-01	6.19E-01	5.86E-01
1069	6.01E-01	5.86E-01	5.54E-01
1070	6.22E-01	6.05E-01	5.72E-01
1071	6.28E-01	6.17E-01	5.83E-01
1072	6.31E-01	6.15E-01	5.82E-01
1073	6.18E-01	6.04E-01	5.71E-01
1074	6.31E-01	6.22E-01	5.88E-01
1075	6.18E-01	5.93E-01	5.61E-01
1076	6.25E-01	6.15E-01	5.81E-01
1077	6.24E-01	6.04E-01	5.72E-01
1078	6.25E-01	6.03E-01	5.71E-01
1079	6.12E-01	6.05E-01	5.72E-01
1080	6.23E-01	5.97E-01	5.65E-01
1081	6.07E-01	5.81E-01	5.50E-01
1082	6.02E-01	5.89E-01	5.58E-01
1083	6.09E-01	5.98E-01	5.66E-01
1084	6.14E-01	5.79E-01	5.48E-01
1085	6.12E-01	5.93E-01	5.62E-01
1086	6.16E-01	5.54E-01	5.25E-01
1087	5.91E-01	5.67E-01	5.37E-01
1088	6.07E-01	5.93E-01	5.62E-01
1089	6.09E-01	5.79E-01	5.49E-01
1090	6.04E-01	5.56E-01	5.27E-01
1091	6.08E-01	5.88E-01	5.57E-01
1092	5.97E-01	5.81E-01	5.50E-01
1093	5.92E-01	5.11E-01	4.84E-01
1094	5.61E-01	5.40E-01	5.11E-01
1095	5.83E-01	5.21E-01	4.94E-01
1096	5.86E-01	5.03E-01	4.77E-01
1097	5.91E-01	5.79E-01	5.48E-01
1098	5.87E-01	5.03E-01	4.77E-01
1099	5.82E-01	5.08E-01	4.82E-01
1100	6.00E-01	4.86E-01	4.61E-01
1101	5.99E-01	4.97E-01	4.72E-01
1102	5.82E-01	4.69E-01	4.45E-01
1103	5.95E-01	4.66E-01	4.43E-01
1104	5.93E-01	4.68E-01	4.44E-01
1105	5.91E-01	5.06E-01	4.81E-01
1106	5.90E-01	3.98E-01	3.78E-01
1107	5.86E-01	4.83E-01	4.59E-01
1108	5.87E-01	4.16E-01	3.95E-01
1109	5.86E-01	4.13E-01	3.92E-01
1110	5.87E-01	4.79E-01	4.55E-01
1111	5.83E-01	3.32E-01	3.16E-01
1112	5.83E-01	4.14E-01	3.93E-01
1113	5.78E-01	2.69E-01	2.56E-01
1114	5.84E-01	3.00E-01	2.86E-01
1115	5.82E-01	2.50E-01	2.38E-01
1116	5.75E-01	2.01E-01	1.92E-01
1117	5.83E-01	7.96E-02	7.62E-02
1118	5.72E-01	2.18E-01	2.08E-01
1119	5.72E-01	1.13E-01	1.08E-01
1120	5.69E-01	1.42E-01	1.36E-01
1121	5.72E-01	1.86E-01	1.78E-01
1122	5.75E-01	8.17E-02	7.82E-02
1123	5.74E-01	1.28E-01	1.23E-01
1124	5.73E-01	1.09E-01	1.04E-01
1125	5.70E-01	1.44E-01	1.38E-01
1126	5.53E-01	5.16E-02	4.94E-02
1127	5.62E-01	1.57E-01	1.50E-01
1128	5.68E-01	9.92E-02	9.49E-02
1129	5.68E-01	1.06E-01	1.01E-01
1130	5.64E-01	7.06E-02	6.76E-02
1131	5.68E-01	2.96E-01	2.82E-01
1132	5.70E-01	2.34E-01	2.24E-01
1133	5.62E-01	1.53E-01	1.47E-01
1134	5.63E-01	4.17E-02	4.00E-02
1135	5.63E-01	1.55E-02	1.48E-02
1136	5.65E-01	1.29E-01	1.23E-01
1137	5.52E-01	2.88E-01	2.75E-01
1138	5.44E-01	2.03E-01	1.94E-01
1139	5.53E-01	2.99E-01	2.85E-01
1140	5.56E-01	2.56E-01	2.44E-01
1141	5.43E-01	1.93E-01	1.85E-01
1142	5.55E-01	2.25E-01	2.15E-01
1143	5.50E-01	3.12E-01	2.98E-01
1144	5.45E-01	1.13E-01	1.08E-01
1145	5.50E-01	1.46E-01	1.40E-01
1146	5.54E-01	1.58E-01	1.51E-01
1147	5.54E-01	5.92E-02	5.67E-02
1148	5.50E-01	2.71E-01	2.59E-01
1149	5.48E-01	2.19E-01	2.09E-01
1150	5.46E-01	1.22E-01	1.16E-01
1151	5.45E-01	2.03E-01	1.95E-01
1152	5.42E-01	2.48E-01	2.37E-01
1153	5.43E-01	2.38E-01	2.28E-01
1154	5.47E-01	1.42E-01	1.36E-01
1155	5.47E-01	3.13E-01	2.99E-01
1156	5.40E-01	2.81E-01	2.68E-01
1157	5.44E-01	3.15E-01	3.00E-01
1158	5.43E-01	3.12E-01	2.98E-01
1159	5.35E-01	3.37E-01	3.22E-01
1160	5.29E-01	2.86E-01	2.74E-01
1161	5.19E-01	3.48E-01	3.32E-01
1162	5.33E-01	3.50E-01	3.34E-01
1163	5.37E-01	4.69E-01	4.46E-01
1164	5.27E-01	4.02E-01	3.83E-01
1165	5.35E-01	3.89E-01	3.71E-01
1166	5.22E-01	3.75E-01	3.58E-01
1167	5.30E-01	4.10E-01	3.91E-01
1168	5.34E-01	4.20E-01	4.00E-01
1169	5.16E-01	4.23E-01	4.03E-01
1170	5.29E-01	4.59E-01	4.37E-01
1171	5.31E-01	4.48E-01	4.28E-01
1172	5.31E-01	4.55E-01	4.34E-01
1173	5.27E-01	4.56E-01	4.35E-01
1174	5.28E-01	3.37E-01	3.22E-01
1175	5.19E-01	4.52E-01	4.31E-01
1176	5.10E-01	4.77E-01	4.54E-01
1177	5.23E-01	4.72E-01	4.50E-01
1178	5.17E-01	3.60E-01	3.44E-01
1179	5.15E-01	4.84E-01	4.61E-01
1180	5.22E-01	4.41E-01	4.21E-01
1181	5.18E-01	4.55E-01	4.34E-01
1182	5.17E-01	3.23E-01	3.09E-01
1183	4.88E-01	4.39E-01	4.19E-01
1184	5.11E-01	4.20E-01	4.01E-01
1185	5.16E-01	4.07E-01	3.89E-01
1186	5.15E-01	4.77E-01	4.55E-01
1187	5.15E-01	4.56E-01	4.35E-01
1188	5.10E-01	3.35E-01	3.20E-01
1189	4.84E-01	4.16E-01	3.97E-01
1190	5.06E-01	4.62E-01	4.41E-01
1191	5.14E-01	4.47E-01	4.26E-01
1192	5.12E-01	4.73E-01	4.52E-01
1193	5.11E-01	4.54E-01	4.34E-01
1194	5.11E-01	4.69E-01	4.48E-01
1195	5.06E-01	4.47E-01	4.27E-01
1196	5.06E-01	4.31E-01	4.12E-01
1197	5.03E-01	4.77E-01	4.55E-01
1198	4.92E-01	4.34E-01	4.14E-01
1199	4.74E-01	3.65E-01	3.49E-01
1200	5.00E-01	4.48E-01	4.28E-01
1201	5.06E-01	4.37E-01	4.17E-01
1202	5.07E-01	4.37E-01	4.17E-01
1203	4.88E-01	4.34E-01	4.14E-01
1204	4.87E-01	3.62E-01	3.46E-01
1205	5.02E-01	4.37E-01	4.17E-01
1206	4.99E-01	4.81E-01	4.59E-01
1207	5.01E-01	4.30E-01	4.10E-01
1208	4.90E-01	4.33E-01	4.14E-01
1209	4.66E-01	4.14E-01	3.95E-01
1210	4.92E-01	4.53E-01	4.33E-01
1211	4.79E-01	4.22E-01	4.03E-01
1212	4.91E-01	4.25E-01	4.06E-01
1213	4.92E-01	4.70E-01	4.48E-01
1214	4.89E-01	4.34E-01	4.14E-01
1215	4.90E-01	4.28E-01	4.09E-01
1216	4.89E-01	4.66E-01	4.45E-01
1217	4.88E-01	4.55E-01	4.35E-01
1218	4.86E-01	4.59E-01	4.38E-01
1219	4.82E-01	4.47E-01	4.26E-01
1220	4.84E-01	4.58E-01	4.37E-01
1221	4.83E-01	4.65E-01	4.44E-01
1222	4.81E-01	4.51E-01	4.31E-01
1223	4.76E-01	4.44E-01	4.24E-01
1224	4.82E-01	4.48E-01	4.28E-01
1225	4.79E-01	4.62E-01	4.41E-01
1226	4.80E-01	4.68E-01	4.47E-01
1227	4.68E-01	4.33E-01	4.14E-01
1228	4.74E-01	4.67E-01	4.45E-01
1229	4.77E-01	4.67E-01	4.46E-01
1230	4.75E-01	4.60E-01	4.39E-01
1231	4.74E-01	4.72E-01	4.51E-01
1232	4.69E-01	4.66E-01	4.45E-01
1233	4.71E-01	4.54E-01	4.34E-01
1234	4.69E-01	4.70E-01	4.49E-01
1235	4.66E-01	4.65E-01	4.44E-01
1236	4.69E-01	4.69E-01	4.48E-01
1237	4.68E-01	4.63E-01	4.43E-01
1238	4.67E-01	4.68E-01	4.47E-01
1239	4.62E-01	4.63E-01	4.42E-01
1240	4.60E-01	4.61E-01	4.40E-01
1241	4.64E-01	4.62E-01	4.41E-01
1242	4.62E-01	4.62E-01	4.42E-01
1243	4.57E-01	4.58E-01	4.37E-01
1244	4.55E-01	4.55E-01	4.35E-01
1245	4.56E-01	4.57E-01	4.36E-01
1246	4.59E-01	4.59E-01	4.39E-01
1247	4.58E-01	4.57E-01	4.37E-01
1248	4.61E-01	4.59E-01	4.38E-01
1249	4.60E-01	4.60E-01	4.39E-01
1250	4.59E-01	4.57E-01	4.37E-01
1251	4.56E-01	4.53E-01	4.33E-01
1252	4.52E-01	4.51E-01	4.31E-01
1253	4.54E-01	4.48E-01	4.28E-01
1254	4.54E-01	4.44E-01	4.24E-01
1255	4.53E-01	4.51E-01	4.31E-01
1256	4.52E-01	4.40E-01	4.21E-01
1257	4.49E-01	4.35E-01	4.16E-01
1258	4.51E-01	4.45E-01	4.25E-01
1259	4.48E-01	4.27E-01	4.09E-01
1260	4.50E-01	4.31E-01	4.12E-01
1261	4.49E-01	4.11E-01	3.94E-01
1262	4.43E-01	3.96E-01	3.79E-01
1263	4.48E-01	4.00E-01	3.83E-01
1264	4.42E-01	3.71E-01	3.56E-01
1265	4.43E-01	3.96E-01	3.79E-01
1266	4.46E-01	3.85E-01	3.69E-01
1267	4.39E-01	3.88E-01	3.72E-01
1268	4.36E-01	3.71E-01	3.55E-01
1269	4.40E-01	2.47E-01	2.37E-01
1270	4.42E-01	3.87E-01	3.71E-01
1271	4.43E-01	4.08E-01	3.91E-01
1272	4.41E-01	4.09E-01	3.91E-01
1273	4.41E-01	4.06E-01	3.89E-01
1274	4.38E-01	4.06E-01	3.89E-01
1275	4.41E-01	4.12E-01	3.95E-01
1276	4.42E-01	4.17E-01	3.99E-01
1277	4.42E-01	4.20E-01	4.02E-01
1278	4.41E-01	4.28E-01	4.09E-01
1279	4.38E-01	4.25E-01	4.06E-01
1280	4.35E-01	4.22E-01	4.04E-01
1281	4.23E-01	4.13E-01	3.96E-01
1282	3.76E-01	3.73E-01	3.57E-01
1283	4.12E-01	4.07E-01	3.90E-01
1284	4.27E-01	4.21E-01	4.03E-01
1285	4.29E-01	4.24E-01	4.06E-01
1286	4.29E-01	4.27E-01	4.09E-01
1287	4.30E-01	4.22E-01	4.04E-01
1288	4.27E-01	4.20E-01	4.02E-01
1289	4.28E-01	4.09E-01	3.92E-01
1290	4.19E-01	4.13E-01	3.95E-01
1291	4.22E-01	4.18E-01	4.00E-01
1292	4.23E-01	3.96E-01	3.79E-01
1293	4.23E-01	4.13E-01	3.95E-01
1294	4.16E-01	4.04E-01	3.87E-01
1295	4.19E-01	4.05E-01	3.88E-01
1296	4.20E-01	3.90E-01	3.73E-01
1297	4.17E-01	3.71E-01	3.56E-01
1298	4.13E-01	3.92E-01	3.75E-01
1299	4.17E-01	4.09E-01	3.91E-01
1300	4.15E-01	3.53E-01	3.39E-01
1301	4.14E-01	3.62E-01	3.47E-01
1302	4.10E-01	3.92E-01	3.75E-01
1303	4.08E-01	3.46E-01	3.32E-01
1304	4.06E-01	3.01E-01	2.88E-01
1305	4.10E-01	3.84E-01	3.68E-01
1306	4.10E-01	3.85E-01	3.69E-01
1307	4.10E-01	3.06E-01	2.94E-01
1308	4.09E-01	3.47E-01	3.33E-01
1309	4.09E-01	3.84E-01	3.68E-01
1310	4.07E-01	3.01E-01	2.89E-01
1311	4.06E-01	3.34E-01	3.20E-01
1312	4.03E-01	3.33E-01	3.20E-01
1313	3.91E-01	3.14E-01	3.01E-01
1314	4.03E-01	2.88E-01	2.77E-01
1315	3.92E-01	2.86E-01	2.74E-01
1316	3.94E-01	3.24E-01	3.11E-01
1317	4.01E-01	3.12E-01	3.00E-01
1318	3.95E-01	3.33E-01	3.20E-01
1319	4.01E-01	2.69E-01	2.58E-01
1320	3.99E-01	2.59E-01	2.49E-01
1321	3.95E-01	2.99E-01	2.87E-01
1322	3.95E-01	3.02E-01	2.90E-01
1323	3.95E-01	2.33E-01	2.24E-01
1324	3.95E-01	2.62E-01	2.52E-01
1325	3.94E-01	3.22E-01	3.09E-01
1326	3.92E-01	2.81E-01	2.70E-01
1327	3.89E-01	2.66E-01	2.56E-01
1328	3.91E-01	2.35E-01	2.26E-01
1329	3.80E-01	1.78E-01	1.71E-01
1330	3.85E-01	2.29E-01	2.21E-01
1331	3.88E-01	1.45E-01	1.40E-01
1332	3.79E-01	1.46E-01	1.40E-01
1333	3.87E-01	2.03E-01	1.95E-01
1334	3.87E-01	1.69E-01	1.63E-01
1335	3.86E-01	2.31E-01	2.22E-01
1336	3.82E-01	1.83E-01	1.77E-01
1337	3.83E-01	1.65E-01	1.59E-01
1338	3.81E-01	1.78E-01	1.72E-01
1339	3.76E-01	1.77E-01	1.70E-01
1340	3.74E-01	1.68E-01	1.62E-01
1341	3.82E-01	1.70E-01	1.64E-01
1342	3.80E-01	1.78E-01	1.71E-01
1343	3.80E-01	1.27E-01	1.23E-01
1344	3.80E-01	7.56E-02	7.30E-02
1345	3.80E-01	1.09E-01	1.05E-01
1346	3.76E-01	5.82E-02	5.62E-02
1347	3.78E-01	6.01E-02	5.81E-02
1348	3.77E-01	4.75E-03	4.59E-03
1349	3.76E-01	1.62E-02	1.56E-02
1350	3.71E-01	1.60E-02	1.55E-02
1351	3.72E-01	4.63E-03	4.48E-03
1352	3.75E-01	1.52E-03	1.47E-03
1353	3.74E-01	9.61E-05	9.29E-05
1354	3.73E-01	2.90E-04	2.81E-04
1355	3.68E-01	3.60E-06	3.48E-06
1356	3.69E-01	4.81E-05	4.65E-05
1357	3.64E-01	7.18E-05	6.94E-05
1358	3.70E-01	4.19E-06	4.06E-06
1359	3.69E-01	7.34E-07	7.10E-07
1360	3.65E-01	2.14E-06	2.07E-06
1361	3.70E-01	4.81E-09	4.66E-09
1362	3.69E-01	1.81E-11	1.75E-11
1363	3.62E-01	3.16E-06	3.05E-06
1364	3.67E-01	1.36E-06	1.32E-06
1365	3.66E-01	9.08E-12	8.78E-12
1366	3.66E-01	1.28E-05	1.24E-05
1367	3.62E-01	4.98E-06	4.82E-06
1368	3.66E-01	1.48E-13	1.43E-13
1369	3.59E-01	5.17E-07	5.00E-07
1370	3.59E-01	2.92E-07	2.83E-07
1371	3.59E-01	1.97E-08	1.91E-08
1372	3.63E-01	2.75E-06	2.66E-06
1373	3.63E-01	4.44E-05	4.30E-05
1374	3.63E-01	1.79E-04	1.74E-04
1375	3.57E-01	3.23E-04	3.13E-04
1376	3.54E-01	2.57E-04	2.49E-04
1377	3.58E-01	1.23E-04	1.19E-04
1378	3.57E-01	1.11E-03	1.07E-03
1379	3.60E-01	5.22E-05	5.05E-05
1380	3.57E-01	8.16E-05	7.90E-05
1381	3.58E-01	2.37E-06	2.30E-06
1382	3.53E-01	2.57E-06	2.49E-06
1383	3.54E-01	4.40E-08	4.27E-08
1384	3.56E-01	6.17E-07	5.98E-07
1385	3.52E-01	2.09E-06	2.03E-06
1386	3.55E-01	2.52E-06	2.44E-06
1387	3.51E-01	1.99E-04	1.93E-04
1388	3.53E-01	4.03E-06	3.90E-06
1389	3.54E-01	5.81E-04	5.63E-04
1390	3.47E-01	4.93E-04	4.78E-04
1391	3.52E-01	3.44E-04	3.33E-04
1392	3.52E-01	2.38E-05	2.31E-05
1393	3.50E-01	1.16E-04	1.12E-04
1394	3.48E-01	7.55E-05	7.33E-05
1395	3.48E-01	6.71E-07	6.51E-07
1396	3.49E-01	6.32E-09	6.13E-09
1397	3.49E-01	4.91E-05	4.76E-05
1398	3.50E-01	1.27E-03	1.23E-03
1399	3.49E-01	8.12E-04	7.88E-04
1400	3.39E-01	3.25E-09	3.15E-09
1401	3.39E-01	1.05E-08	1.02E-08
1402	3.44E-01	1.84E-03	1.78E-03
1403	3.40E-01	2.38E-03	2.31E-03
1404	3.41E-01	7.39E-04	7.18E-04
1405	3.40E-01	3.64E-07	3.54E-07
1406	3.42E-01	2.04E-03	1.99E-03
1407	3.41E-01	1.75E-04	1.70E-04
1408	3.40E-01	1.65E-03	1.60E-03
1409	3.41E-01	6.19E-04	6.02E-04
1410	3.40E-01	4.67E-04	4.53E-04
1411	3.38E-01	2.11E-03	2.05E-03
1412	3.29E-01	2.64E-03	2.57E-03
1413	3.33E-01	2.34E-02	2.27E-02
1414	3.37E-01	3.64E-04	3.54E-04
1415	3.37E-01	1.84E-04	1.79E-04
1416	3.35E-01	3.56E-02	3.46E-02
1417	3.37E-01	1.18E-02	1.14E-02
1418	3.38E-01	1.36E-02	1.32E-02
1419	3.34E-01	2.14E-03	2.09E-03
1420	3.33E-01	8.27E-03	8.04E-03
1421	3.36E-01	9.16E-03	8.91E-03
1422	3.29E-01	4.63E-02	4.50E-02
1423	3.29E-01	9.22E-03	8.97E-03
1424	3.28E-01	1.70E-02	1.65E-02
1425	3.33E-01	2.59E-02	2.51E-02
1426	3.23E-01	2.78E-02	2.70E-02
1427	3.27E-01	4.95E-02	4.82E-02
1428	3.30E-01	4.56E-03	4.44E-03
1429	3.23E-01	3.80E-02	3.70E-02
1430	3.23E-01	6.16E-02	5.99E-02
1431	3.24E-01	5.02E-02	4.88E-02
1432	3.31E-01	2.52E-03	2.45E-03
1433	3.31E-01	3.58E-02	3.49E-02
1434	3.25E-01	2.10E-02	2.04E-02
1435	3.27E-01	2.14E-02	2.08E-02
1436	3.27E-01	3.84E-02	3.73E-02
1437	3.28E-01	2.99E-02	2.91E-02
1438	3.26E-01	1.33E-02	1.29E-02
1439	3.29E-01	5.10E-02	4.97E-02
1440	3.13E-01	3.96E-02	3.85E-02
1441	3.17E-01	3.18E-02	3.10E-02
1442	3.16E-01	3.63E-02	3.54E-02
1443	3.18E-01	4.51E-02	4.39E-02
1444	3.19E-01	6.18E-02	6.01E-02
1445	3.19E-01	4.98E-02	4.84E-02
1446	3.21E-01	2.31E-02	2.25E-02
1447	3.18E-01	3.62E-02	3.53E-02
1448	3.21E-01	1.16E-01	1.13E-01
1449	3.20E-01	1.02E-01	9.94E-02
1450	3.18E-01	2.74E-02	2.67E-02
1451	3.14E-01	1.13E-02	1.10E-02
1452	3.14E-01	6.24E-02	6.07E-02
1453	3.15E-01	8.20E-02	7.98E-02
1454	3.13E-01	1.38E-01	1.34E-01
1455	3.12E-01	6.62E-02	6.44E-02
1456	3.10E-01	8.85E-02	8.62E-02
1457	3.12E-01	1.17E-01	1.14E-01
1458	3.16E-01	1.36E-01	1.33E-01
1459	3.17E-01	1.63E-01	1.59E-01
1460	3.14E-01	8.54E-02	8.32E-02
1461	3.13E-01	9.03E-02	8.79E-02
1462	3.10E-01	1.31E-01	1.27E-01
1463	3.08E-01	4.32E-02	4.21E-02
1464	3.08E-01	1.52E-01	1.48E-01
1465	3.12E-01	9.34E-02	9.09E-02
1466	3.07E-01	6.52E-02	6.35E-02
1467	3.13E-01	3.61E-02	3.51E-02
1468	3.08E-01	7.69E-02	7.49E-02
1469	3.12E-01	9.48E-02	9.23E-02
1470	3.10E-01	4.97E-02	4.84E-02
1471	3.04E-01	1.78E-02	1.74E-02
1472	3.06E-01	4.68E-02	4.56E-02
1473	3.06E-01	7.02E-02	6.84E-02
1474	2.97E-01	9.73E-02	9.48E-02
1475	3.03E-01	1.85E-01	1.80E-01
1476	3.04E-01	6.88E-02	6.70E-02
1477	3.03E-01	6.97E-02	6.79E-02
1478	3.02E-01	6.35E-02	6.18E-02
1479	3.05E-01	1.20E-01	1.17E-01
1480	3.06E-01	6.06E-02	5.91E-02
1481	3.02E-01	1.15E-01	1.12E-01
1482	3.05E-01	5.85E-02	5.70E-02
1483	2.98E-01	1.49E-01	1.45E-01
1484	3.02E-01	1.37E-01	1.34E-01
1485	3.06E-01	1.25E-01	1.22E-01
1486	3.02E-01	1.23E-01	1.20E-01
1487	3.00E-01	6.06E-02	5.90E-02
1488	2.65E-01	9.42E-02	9.17E-02
1489	2.99E-01	1.90E-01	1.84E-01
1490	3.01E-01	1.75E-01	1.70E-01
1491	3.02E-01	1.98E-01	1.92E-01
1492	2.98E-01	1.64E-01	1.60E-01
1493	3.02E-01	1.82E-01	1.77E-01
1494	3.02E-01	2.04E-01	1.98E-01
1495	3.01E-01	1.83E-01	1.77E-01
1496	2.91E-01	1.69E-01	1.64E-01
1497	2.97E-01	2.29E-01	2.22E-01
1498	2.99E-01	1.90E-01	1.84E-01
1499	2.95E-01	2.18E-01	2.11E-01
1500	3.01E-01	2.51E-01	2.43E-01
1501	3.00E-01	2.66E-01	2.58E-01
1502	2.97E-01	2.34E-01	2.27E-01
1503	2.69E-01	1.85E-01	1.80E-01
1504	2.83E-01	1.60E-01	1.56E-01
1505	2.71E-01	1.84E-01	1.79E-01
1506	2.84E-01	2.58E-01	2.50E-01
1507	2.94E-01	2.55E-01	2.48E-01
1508	2.90E-01	2.43E-01	2.36E-01
1509	2.88E-01	1.87E-01	1.82E-01
1510	2.94E-01	2.71E-01	2.63E-01
1511	2.94E-01	2.65E-01	2.57E-01
1512	2.88E-01	2.61E-01	2.53E-01
1513	2.87E-01	2.42E-01	2.35E-01
1514	2.85E-01	2.26E-01	2.19E-01
1515	2.88E-01	2.66E-01	2.58E-01
1516	2.87E-01	2.57E-01	2.49E-01
1517	2.85E-01	2.49E-01	2.42E-01
1518	2.90E-01	2.52E-01	2.45E-01
1519	2.85E-01	2.44E-01	2.37E-01
1520	2.88E-01	2.65E-01	2.57E-01
1521	2.81E-01	2.75E-01	2.67E-01
1522	2.80E-01	2.64E-01	2.56E-01
1523	2.84E-01	2.80E-01	2.72E-01
1524	2.85E-01	2.75E-01	2.67E-01
1525	2.78E-01	2.59E-01	2.51E-01
1526	2.86E-01	2.67E-01	2.60E-01
1527	2.83E-01	2.62E-01	2.55E-01
1528	2.85E-01	2.79E-01	2.71E-01
1529	2.83E-01	2.72E-01	2.65E-01
1530	2.67E-01	2.55E-01	2.48E-01
1531	2.83E-01	2.70E-01	2.62E-01
1532	2.83E-01	2.78E-01	2.70E-01
1533	2.80E-01	2.77E-01	2.69E-01
1534	2.75E-01	2.69E-01	2.61E-01
1535	2.78E-01	2.67E-01	2.59E-01
1536	2.81E-01	2.75E-01	2.67E-01
1537	2.81E-01	2.73E-01	2.66E-01
1538	2.73E-01	2.72E-01	2.64E-01
1539	2.78E-01	2.73E-01	2.65E-01
1540	2.69E-01	2.65E-01	2.57E-01
1541	2.73E-01	2.69E-01	2.61E-01
1542	2.75E-01	2.69E-01	2.62E-01
1543	2.75E-01	2.72E-01	2.64E-01
1544	2.77E-01	2.72E-01	2.64E-01
1545	2.78E-01	2.77E-01	2.69E-01
1546	2.77E-01	2.75E-01	2.67E-01
1547	2.74E-01	2.73E-01	2.65E-01
1548	2.67E-01	2.67E-01	2.59E-01
1549	2.73E-01	2.73E-01	2.66E-01
1550	2.70E-01	2.70E-01	2.62E-01
1551	2.71E-01	2.71E-01	2.63E-01
1552	2.74E-01	2.72E-01	2.64E-01
1553	2.71E-01	2.71E-01	2.64E-01
1554	2.65E-01	2.65E-01	2.57E-01
1555	2.67E-01	2.68E-01	2.60E-01
1556	2.63E-01	2.63E-01	2.56E-01
1557	2.70E-01	2.71E-01	2.63E-01
1558	2.68E-01	2.68E-01	2.61E-01
1559	2.68E-01	2.68E-01	2.61E-01
1560	2.65E-01	2.66E-01	2.58E-01
1561	2.70E-01	2.70E-01	2.62E-01
1562	2.68E-01	2.68E-01	2.60E-01
1563	2.67E-01	2.67E-01	2.59E-01
1564	2.63E-01	2.63E-01	2.55E-01
1565	2.67E-01	2.67E-01	2.60E-01
1566	2.63E-01	2.62E-01	2.55E-01
1567	2.64E-01	2.63E-01	2.56E-01
1568	2.60E-01	2.57E-01	2.50E-01
1569	2.63E-01	2.55E-01	2.47E-01
1570	2.61E-01	2.42E-01	2.35E-01
1571	2.67E-01	2.35E-01	2.29E-01
1572	2.67E-01	2.38E-01	2.31E-01
1573	2.63E-01	2.34E-01	2.28E-01
1574	2.62E-01	2.41E-01	2.35E-01
1575	2.47E-01	2.40E-01	2.33E-01
1576	2.60E-01	2.47E-01	2.40E-01
1577	2.37E-01	2.16E-01	2.10E-01
1578	2.57E-01	2.35E-01	2.29E-01
1579	2.62E-01	2.37E-01	2.30E-01
1580	2.64E-01	2.45E-01	2.38E-01
1581	2.65E-01	2.49E-01	2.42E-01
1582	2.54E-01	2.42E-01	2.35E-01
1583	2.58E-01	2.48E-01	2.41E-01
1584	2.54E-01	2.49E-01	2.42E-01
1585	2.62E-01	2.59E-01	2.51E-01
1586	2.58E-01	2.56E-01	2.48E-01
1587	2.55E-01	2.53E-01	2.46E-01
1588	2.50E-01	2.51E-01	2.44E-01
1589	2.32E-01	2.32E-01	2.26E-01
1590	2.42E-01	2.42E-01	2.35E-01
1591	2.41E-01	2.42E-01	2.35E-01
1592	2.53E-01	2.52E-01	2.45E-01
1593	2.58E-01	2.58E-01	2.51E-01
1594	2.56E-01	2.56E-01	2.49E-01
1595	2.58E-01	2.58E-01	2.51E-01
1596	2.45E-01	2.45E-01	2.38E-01
1597	2.49E-01	2.47E-01	2.40E-01
1598	2.56E-01	2.54E-01	2.47E-01
1599	2.50E-01	2.42E-01	2.35E-01
1600	2.53E-01	2.38E-01	2.31E-01
1601	2.45E-01	2.23E-01	2.17E-01
1602	2.49E-01	2.24E-01	2.18E-01
1603	2.49E-01	2.24E-01	2.18E-01
1604	2.50E-01	2.28E-01	2.22E-01
1605	2.47E-01	2.37E-01	2.30E-01
1606	2.47E-01	2.41E-01	2.35E-01
1607	2.45E-01	2.33E-01	2.26E-01
1608	2.50E-01	2.30E-01	2.23E-01
1609	2.49E-01	2.27E-01	2.21E-01
1610	2.33E-01	2.18E-01	2.11E-01
1611	2.41E-01	2.27E-01	2.20E-01
1612	2.41E-01	2.31E-01	2.24E-01
1613	2.46E-01	2.37E-01	2.30E-01
1614	2.44E-01	2.38E-01	2.32E-01
1615	2.44E-01	2.41E-01	2.34E-01
1616	2.32E-01	2.31E-01	2.24E-01
1617	2.36E-01	2.35E-01	2.28E-01
1618	2.44E-01	2.44E-01	2.37E-01
1619	2.42E-01	2.41E-01	2.34E-01
1620	2.34E-01	2.34E-01	2.28E-01
1621	2.34E-01	2.34E-01	2.28E-01
1622	2.37E-01	2.38E-01	2.31E-01
1623	2.42E-01	2.42E-01	2.36E-01
1624	2.42E-01	2.43E-01	2.36E-01
1625	2.37E-01	2.38E-01	2.31E-01
1626	2.40E-01	2.40E-01	2.33E-01
1627	2.40E-01	2.41E-01	2.34E-01
1628	2.41E-01	2.41E-01	2.34E-01
1629	2.41E-01	2.41E-01	2.35E-01
1630	2.37E-01	2.37E-01	2.30E-01
1631	2.39E-01	2.38E-01	2.31E-01
1632	2.39E-01	2.38E-01	2.32E-01
1633	2.36E-01	2.33E-01	2.26E-01
1634	2.33E-01	2.33E-01	2.26E-01
1635	2.37E-01	2.34E-01	2.27E-01
1636	2.37E-01	2.35E-01	2.29E-01
1637	2.27E-01	2.27E-01	2.21E-01
1638	2.27E-01	2.20E-01	2.14E-01
1639	2.22E-01	2.20E-01	2.14E-01
1640	2.26E-01	2.15E-01	2.09E-01
1641	2.24E-01	2.20E-01	2.13E-01
1642	2.24E-01	2.21E-01	2.15E-01
1643	2.29E-01	2.15E-01	2.09E-01
1644	2.26E-01	2.24E-01	2.17E-01
1645	2.25E-01	2.18E-01	2.12E-01
1646	2.29E-01	2.17E-01	2.11E-01
1647	2.29E-01	2.28E-01	2.21E-01
1648	2.29E-01	2.17E-01	2.11E-01
1649	2.24E-01	2.19E-01	2.13E-01
1650	2.28E-01	2.25E-01	2.19E-01
1651	2.24E-01	2.09E-01	2.03E-01
1652	2.28E-01	2.24E-01	2.18E-01
1653	2.25E-01	2.23E-01	2.17E-01
1654	2.27E-01	2.16E-01	2.10E-01
1655	2.24E-01	2.22E-01	2.16E-01
1656	2.26E-01	2.21E-01	2.15E-01
1657	2.26E-01	2.22E-01	2.16E-01
1658	2.25E-01	2.25E-01	2.19E-01
1659	2.22E-01	2.21E-01	2.15E-01
1660	2.24E-01	2.23E-01	2.17E-01
1661	2.25E-01	2.24E-01	2.18E-01
1662	2.24E-01	2.19E-01	2.13E-01
1663	2.23E-01	2.22E-01	2.16E-01
1664	2.23E-01	2.21E-01	2.15E-01
1665	2.21E-01	2.12E-01	2.06E-01
1666	2.19E-01	1.79E-01	1.74E-01
1667	2.20E-01	2.11E-01	2.05E-01
1668	2.16E-01	2.15E-01	2.09E-01
1669	2.18E-01	2.15E-01	2.09E-01
1670	2.22E-01	2.22E-01	2.16E-01
1671	2.21E-01	2.19E-01	2.13E-01
1672	2.12E-01	2.11E-01	2.06E-01
1673	2.16E-01	2.16E-01	2.11E-01
1674	2.19E-01	2.16E-01	2.10E-01
1675	2.16E-01	2.14E-01	2.08E-01
1676	2.13E-01	2.11E-01	2.06E-01
1677	2.15E-01	2.12E-01	2.07E-01
1678	2.16E-01	2.09E-01	2.04E-01
1679	2.13E-01	2.13E-01	2.07E-01
1680	2.06E-01	2.06E-01	2.00E-01
1681	1.98E-01	1.94E-01	1.89E-01
1682	2.03E-01	2.04E-01	1.98E-01
1683	2.09E-01	2.09E-01	2.04E-01
1684	2.12E-01	1.98E-01	1.93E-01
1685	2.13E-01	2.13E-01	2.08E-01
1686	2.10E-01	2.10E-01	2.05E-01
1687	2.11E-01	2.05E-01	2.00E-01
1688	2.11E-01	2.10E-01	2.05E-01
1689	2.08E-01	2.07E-01	2.02E-01
1690	2.08E-01	2.05E-01	2.00E-01
1691	2.12E-01	1.93E-01	1.88E-01
1692	2.12E-01	2.07E-01	2.02E-01
1693	2.11E-01	2.11E-01	2.06E-01
1694	2.11E-01	2.05E-01	2.00E-01
1695	2.11E-01	2.10E-01	2.04E-01
1696	2.10E-01	2.09E-01	2.04E-01
1697	2.09E-01	1.81E-01	1.76E-01
1698	2.09E-01	2.07E-01	2.02E-01
1699	2.08E-01	2.06E-01	2.00E-01
1700	2.05E-01	2.00E-01	1.95E-01
1702	2.05E-01	2.04E-01	1.99E-01
1705	2.04E-01	1.98E-01	1.93E-01
1710	1.99E-01	1.88E-01	1.83E-01
1715	2.02E-01	1.90E-01	1.85E-01
1720	1.98E-01	1.87E-01	1.82E-01
1725	1.97E-01	1.78E-01	1.74E-01
1730	1.93E-01	1.74E-01	1.70E-01
1735	1.82E-01	1.62E-01	1.58E-01
1740	1.90E-01	1.68E-01	1.64E-01
1745	1.86E-01	1.55E-01	1.51E-01
1750	1.85E-01	1.66E-01	1.62E-01
1755	1.85E-01	1.53E-01	1.49E-01
1760	1.82E-01	1.60E-01	1.56E-01
1765	1.81E-01	1.33E-01	1.30E-01
1770	1.80E-01	1.42E-01	1.38E-01
1775	1.76E-01	1.15E-01	1.12E-01
1780	1.76E-01	1.01E-01	9.81E-02
1785	1.74E-01	7.70E-02	7.52E-02
1790	1.74E-01	8.89E-02	8.68E-02
1795	1.71E-01	4.69E-02	4.59E-02
1800	1.68E-01	3.18E-02	3.11E-02
1805	1.69E-01	1.48E-02	1.45E-02
1810	1.69E-01	9.69E-03	9.48E-03
1815	1.55E-01	3.28E-03	3.21E-03
1820	1.60E-01	9.88E-04	9.66E-04
1825	1.63E-01	1.27E-03	1.25E-03
1830	1.59E-01	5.20E-06	5.09E-06
1835	1.58E-01	6.42E-06	6.28E-06
1840	1.56E-01	6.27E-08	6.13E-08
1845	1.53E-01	6.27E-06	6.13E-06
1850	1.53E-01	3.00E-06	2.93E-06
1855	1.51E-01	2.84E-07	2.78E-07
1860	1.49E-01	1.12E-05	1.09E-05
1865	1.47E-01	1.70E-05	1.66E-05
1870	1.46E-01	2.67E-10	2.61E-10
1875	1.32E-01	4.51E-10	4.43E-10
1880	1.47E-01	7.75E-05	7.61E-05
1885	1.46E-01	4.39E-05	4.31E-05
1890	1.40E-01	2.23E-04	2.20E-04
1895	1.38E-01	1.29E-04	1.27E-04
1900	1.40E-01	8.62E-07	8.49E-07
1905	1.39E-01	5.67E-07	5.58E-07
1910	1.37E-01	2.30E-05	2.27E-05
1915	1.36E-01	1.99E-05	1.97E-05
1920	1.35E-01	4.51E-04	4.45E-04
1925	1.34E-01	9.36E-04	9.23E-04
1930	1.31E-01	5.52E-04	5.45E-04
1935	1.32E-01	3.59E-03	3.54E-03
1940	1.30E-01	3.28E-03	3.24E-03
1945	1.20E-01	1.09E-02	1.07E-02
1950	1.26E-01	1.67E-02	1.65E-02
1955	1.28E-01	1.00E-02	9.89E-03
1960	1.26E-01	2.19E-02	2.16E-02
1965	1.23E-01	2.86E-02	2.81E-02
1970	1.24E-01	4.88E-02	4.81E-02
1975	1.22E-01	6.79E-02	6.67E-02
1980	1.20E-01	7.55E-02	7.42E-02
1985	1.19E-01	8.31E-02	8.16E-02
1990	1.20E-01	8.56E-02	8.41E-02
1995	1.17E-01	8.12E-02	7.98E-02
2000	1.17E-01	3.82E-02	3.75E-02
2005	1.15E-01	1.50E-02	1.47E-02
2010	1.15E-01	3.97E-02	3.91E-02
2015	1.14E-01	2.66E-02	2.62E-02
2020	1.12E-01	4.50E-02	4.42E-02
2025	1.12E-01	7.40E-02	7.28E-02
2030	1.10E-01	8.49E-02	8.35E-02
2035	1.09E-01	9.64E-02	9.48E-02
2040	1.07E-01	8.98E-02	8.83E-02
2045	1.08E-01	9.11E-02	8.96E-02
2050	1.06E-01	6.79E-02	6.69E-02
2055	1.05E-01	5.49E-02	5.41E-02
2060	1.03E-01	6.92E-02	6.82E-02
2065	1.02E-01	6.19E-02	6.10E-02
2070	1.01E-01	6.57E-02	6.47E-02
2075	1.01E-01	7.74E-02	7.63E-02
2080	9.93E-02	8.68E-02	8.55E-02
2085	9.83E-02	8.51E-02	8.38E-02
2090	9.75E-02	8.91E-02	8.78E-02
2095	9.60E-02	8.97E-02	8.84E-02
2100	9.62E-02	8.61E-02	8.49E-02
2105	9.58E-02	9.32E-02	9.18E-02
2110	9.46E-02	8.97E-02	8.83E-02
2115	9.39E-02	9.17E-02	9.03E-02
2120	9.31E-02	8.76E-02	8.63E-02
2125	9.22E-02	8.86E-02	8.73E-02
2130	9.24E-02	8.98E-02	8.84E-02
2135	9.11E-02	9.00E-02	8.87E-02
2140	9.11E-02	9.08E-02	8.94E-02
2145	8.99E-02	8.95E-02	8.81E-02
2150	8.97E-02	8.46E-02	8.34E-02
2155	8.89E-02	8.48E-02	8.36E-02
2160	8.79E-02	8.42E-02	8.29E-02
2165	8.20E-02	7.63E-02	7.52E-02
2170	8.54E-02	8.20E-02	8.08E-02
2175	8.58E-02	8.04E-02	7.93E-02
2180	8.46E-02	8.18E-02	8.06E-02
2185	8.47E-02	7.46E-02	7.35E-02
2190	8.31E-02	7.91E-02	7.79E-02
2195	8.35E-02	7.90E-02	7.78E-02
2200	8.28E-02	7.12E-02	7.02E-02
2205	8.09E-02	7.40E-02	7.29E-02
2210	8.08E-02	7.93E-02	7.82E-02
2215	8.04E-02	7.63E-02	7.52E-02
2220	8.00E-02	7.77E-02	7.66E-02
2225	7.88E-02	7.55E-02	7.44E-02
2230	7.84E-02	7.58E-02	7.47E-02
2235	7.79E-02	7.43E-02	7.33E-02
2240	7.65E-02	7.31E-02	7.21E-02
2245	7.63E-02	7.08E-02	6.99E-02
2250	7.54E-02	7.19E-02	7.10E-02
2255	7.43E-02	6.77E-02	6.69E-02
2260	7.41E-02	6.69E-02	6.61E-02
2265	7.33E-02	6.81E-02	6.74E-02
2270	7.31E-02	6.49E-02	6.41E-02
2275	7.26E-02	6.40E-02	6.33E-02
2280	7.14E-02	6.63E-02	6.56E-02
2285	7.14E-02	6.31E-02	6.24E-02
2290	7.12E-02	6.32E-02	6.25E-02
2295	6.93E-02	6.13E-02	6.06E-02
2300	6.96E-02	5.88E-02	5.82E-02
2305	6.94E-02	5.92E-02	5.85E-02
2310	6.89E-02	6.39E-02	6.32E-02
2315	6.82E-02	5.81E-02	5.75E-02
2320	6.76E-02	5.20E-02	5.15E-02
2325	6.56E-02	5.62E-02	5.56E-02
2330	6.62E-02	5.68E-02	5.62E-02
2335	6.57E-02	5.80E-02	5.74E-02
2340	6.52E-02	4.58E-02	4.54E-02
2345	6.51E-02	5.14E-02	5.09E-02
2350	6.43E-02	4.15E-02	4.11E-02
2355	6.26E-02	4.75E-02	4.70E-02
2360	6.31E-02	5.02E-02	4.97E-02
2365	6.30E-02	4.94E-02	4.89E-02
2370	6.24E-02	3.08E-02	3.05E-02
2375	6.14E-02	4.41E-02	4.37E-02
2380	6.18E-02	4.26E-02	4.21E-02
2385	5.91E-02	3.08E-02	3.05E-02
2390	6.04E-02	3.71E-02	3.67E-02
2395	6.01E-02	4.06E-02	4.02E-02
2400	5.97E-02	4.42E-02	4.37E-02
2405	5.94E-02	3.36E-02	3.33E-02
2410	5.92E-02	3.38E-02	3.35E-02
2415	5.70E-02	2.73E-02	2.71E-02
2420	5.78E-02	2.66E-02	2.64E-02
2425	5.73E-02	3.31E-02	3.28E-02
2430	5.72E-02	4.51E-02	4.47E-02
2435	5.65E-02	1.49E-02	1.48E-02
2440	5.63E-02	4.32E-02	4.29E-02
2445	5.56E-02	2.08E-02	2.07E-02
2450	5.46E-02	1.36E-02	1.35E-02
2455	5.42E-02	2.49E-02	2.47E-02
2460	5.45E-02	3.34E-02	3.32E-02
2465	5.43E-02	2.41E-02	2.40E-02
2470	5.34E-02	1.67E-02	1.66E-02
2475	5.34E-02	1.65E-02	1.64E-02
2480	5.21E-02	8.04E-03	8.00E-03
2485	5.18E-02	5.61E-03	5.58E-03
2490	5.22E-02	3.51E-03	3.50E-03
2495	4.89E-02	2.88E-03	2.86E-03
2500	5.14E-02	7.06E-03	7.03E-03
2505	5.08E-02	1.52E-03	1.51E-03
2510	4.96E-02	2.22E-03	2.21E-03
2515	4.88E-02	5.19E-04	5.16E-04
2520	4.81E-02	3.71E-04	3.69E-04
2525	4.77E-02	4.14E-05	4.12E-05
2530	4.77E-02	6.36E-07	6.33E-07
2535	4.71E-02	1.75E-07	1.74E-07
2540	4.68E-02	3.77E-07	3.75E-07
2545	4.66E-02	5.38E-11	5.35E-11
2550	4.63E-02	2.82E-13	2.81E-13
2555	4.59E-02	1.04E-09	1.04E-09
2560	4.54E-02	3.10E-11	3.08E-11
2565	4.52E-02	1.60E-14	1.58E-14
2570	4.49E-02	1.53E-18	1.52E-18
2575	4.45E-02	1.08E-27	1.07E-27
2580	4.41E-02	3.82E-22	3.79E-22
2585	4.33E-02	1.72E-34	1.71E-34
2590	4.34E-02	5.48E-31	5.44E-31
2595	4.30E-02	2.28E-33	2.27E-33
2600	4.29E-02	4.49E-28	4.46E-28
2605	4.28E-02	5.81E-35	5.76E-35
2610	4.25E-02	5.94E-34	5.90E-34
2615	4.23E-02	1.12E-37	1.11E-37
2620	4.19E-02	5.65E-29	5.61E-29
2625	4.06E-02	3.87E-28	3.84E-28
2630	4.12E-02	2.80E-45	2.80E-45
2635	4.10E-02	3.90E-16	3.87E-16
2640	4.02E-02	1.18E-16	1.17E-16
2645	4.02E-02	9.00E-19	8.93E-19
2650	4.00E-02	1.43E-19	1.42E-19
2655	3.96E-02	1.31E-27	1.30E-27
2660	3.95E-02	2.61E-25	2.59E-25
2665	3.90E-02	1.11E-37	1.10E-37
2670	3.91E-02	0.00E+00	0.00E+00
2675	3.86E-02	0.00E+00	0.00E+00
2680	3.84E-02	0.00E+00	0.00E+00
2685	3.82E-02	0.00E+00	0.00E+00
2690	3.78E-02	1.02E-29	1.02E-29
2695	3.75E-02	7.13E-33	7.10E-33
2700	3.71E-02	0.00E+00	0.00E+00
2705	3.69E-02	2.93E-42	2.93E-42
2710	3.67E-02	1.13E-35	1.12E-35
2715	3.66E-02	3.86E-26	3.85E-26
2720	3.64E-02	5.61E-45	5.61E-45
2725	3.61E-02	7.29E-22	7.31E-22
2730	3.60E-02	6.07E-19	6.09E-19
2735	3.57E-02	5.49E-21	5.51E-21
2740	3.55E-02	2.33E-27	2.34E-27
2745	3.54E-02	1.31E-23	1.32E-23
2750	3.52E-02	1.66E-28	1.68E-28
2755	3.49E-02	6.73E-44	6.73E-44
2760	3.46E-02	0.00E+00	0.00E+00
2765	3.44E-02	2.68E-27	2.70E-27
2770	3.43E-02	8.38E-24	8.45E-24
2775	3.39E-02	4.00E-38	4.04E-38
2780	3.36E-02	4.81E-34	4.85E-34
2785	3.34E-02	3.89E-27	3.93E-27
2790	3.32E-02	1.22E-16	1.23E-16
2795	3.29E-02	3.62E-16	3.66E-16
2800	3.28E-02	1.65E-12	1.67E-12
2805	3.25E-02	6.75E-14	6.82E-14
2810	3.24E-02	4.02E-10	4.07E-10
2815	3.23E-02	2.87E-10	2.90E-10
2820	3.21E-02	2.05E-11	2.08E-11
2825	3.18E-02	1.76E-07	1.78E-07
2830	3.17E-02	3.90E-06	3.95E-06
2835	3.15E-02	2.13E-10	2.15E-10
2840	3.12E-02	1.96E-07	1.98E-07
2845	3.10E-02	4.06E-05	4.11E-05
2850	3.07E-02	1.16E-06	1.17E-06
2855	3.04E-02	4.49E-07	4.54E-07
2860	3.02E-02	2.54E-05	2.57E-05
2865	3.00E-02	1.68E-04	1.70E-04
2870	2.96E-02	6.31E-06	6.39E-06
2875	2.94E-02	3.92E-04	3.97E-04
2880	2.94E-02	2.47E-04	2.50E-04
2885	2.92E-02	4.53E-04	4.59E-04
2890	2.91E-02	1.86E-04	1.89E-04
2895	2.90E-02	2.66E-03	2.70E-03
2900	2.88E-02	8.12E-04	8.22E-04
2905	2.87E-02	1.11E-04	1.12E-04
2910	2.85E-02	2.72E-03	2.76E-03
2915	2.82E-02	1.26E-03	1.27E-03
2920	2.80E-02	2.89E-03	2.93E-03
2925	2.78E-02	1.08E-03	1.10E-03
2930	2.76E-02	5.89E-03	5.96E-03
2935	2.73E-02	6.49E-03	6.57E-03
2940	2.71E-02	1.63E-03	1.65E-03
2945	2.68E-02	1.45E-03	1.47E-03
2950	2.67E-02	5.23E-03	5.29E-03
2955	2.66E-02	2.34E-03	2.37E-03
2960	2.64E-02	4.60E-03	4.65E-03
2965	2.63E-02	7.44E-03	7.53E-03
2970	2.61E-02	3.52E-04	3.57E-04
2975	2.60E-02	8.54E-04	8.65E-04
2980	2.58E-02	1.34E-03	1.35E-03
2985	2.57E-02	6.96E-03	7.05E-03
2990	2.55E-02	1.03E-02	1.04E-02
2995	2.54E-02	4.28E-03	4.33E-03
3000	2.53E-02	7.85E-03	7.94E-03
3005	2.51E-02	2.89E-03	2.93E-03
3010	2.50E-02	6.85E-03	6.93E-03
3015	2.49E-02	5.56E-03	5.62E-03
3020	2.47E-02	6.34E-04	6.41E-04
3025	2.45E-02	7.50E-03	7.59E-03
3030	2.44E-02	6.08E-03	6.15E-03
3035	2.42E-02	2.50E-03	2.53E-03
3040	2.39E-02	2.02E-03	2.05E-03
3045	2.40E-02	4.21E-03	4.26E-03
3050	2.40E-02	1.03E-03	1.04E-03
3055	2.39E-02	2.89E-04	2.93E-04
3060	2.38E-02	6.30E-03	6.38E-03
3065	2.35E-02	2.91E-03	2.95E-03
3070	2.34E-02	1.75E-03	1.77E-03
3075	2.34E-02	6.02E-03	6.09E-03
3080	2.32E-02	3.62E-03	3.66E-03
3085	2.30E-02	1.77E-03	1.79E-03
3090	2.28E-02	2.38E-03	2.41E-03
3095	2.26E-02	6.55E-04	6.63E-04
3100	2.24E-02	4.40E-03	4.45E-03
3105	2.23E-02	9.22E-04	9.32E-04
3110	2.21E-02	8.46E-04	8.55E-04
3115	2.18E-02	2.27E-03	2.29E-03
3120	2.17E-02	9.82E-03	9.93E-03
3125	2.16E-02	3.03E-03	3.06E-03
3130	2.15E-02	5.76E-03	5.82E-03
3135	2.14E-02	1.14E-02	1.16E-02
3140	2.12E-02	3.32E-03	3.36E-03
3145	2.11E-02	3.25E-03	3.29E-03
3150	2.09E-02	6.67E-03	6.75E-03
3155	2.08E-02	5.64E-03	5.70E-03
3160	2.07E-02	9.23E-03	9.33E-03
3165	2.07E-02	1.40E-02	1.42E-02
3170	2.05E-02	1.25E-02	1.26E-02
3175	2.05E-02	9.23E-03	9.33E-03
3180	2.03E-02	1.06E-02	1.07E-02
3185	2.02E-02	8.08E-03	8.16E-03
3190	2.02E-02	4.24E-03	4.28E-03
3195	2.01E-02	2.69E-03	2.72E-03
3200	1.99E-02	4.38E-04	4.43E-04
3205	1.99E-02	3.10E-04	3.13E-04
3210	1.98E-02	1.36E-04	1.38E-04
3215	1.96E-02	4.98E-04	5.02E-04
3220	1.95E-02	1.61E-03	1.62E-03
3225	1.94E-02	1.99E-04	2.01E-04
3230	1.94E-02	3.41E-04	3.44E-04
3235	1.93E-02	7.29E-03	7.36E-03
3240	1.92E-02	3.75E-03	3.78E-03
3245	1.91E-02	7.34E-04	7.41E-04
3250	1.91E-02	2.61E-03	2.63E-03
3255	1.89E-02	9.94E-03	1.00E-02
3260	1.88E-02	1.22E-03	1.24E-03
3265	1.87E-02	2.45E-03	2.47E-03
3270	1.86E-02	1.22E-03	1.23E-03
3275	1.85E-02	5.93E-03	5.98E-03
3280	1.84E-02	2.86E-03	2.89E-03
3285	1.83E-02	1.11E-02	1.12E-02
3290	1.83E-02	8.76E-03	8.83E-03
3295	1.80E-02	1.22E-03	1.23E-03
3300	1.79E-02	1.78E-03	1.79E-03
3305	1.79E-02	3.94E-03	3.97E-03
3310	1.77E-02	3.92E-03	3.96E-03
3315	1.76E-02	1.61E-05	1.63E-05
3320	1.73E-02	6.00E-05	6.05E-05
3325	1.73E-02	3.52E-03	3.55E-03
3330	1.71E-02	4.66E-03	4.70E-03
3335	1.70E-02	9.07E-03	9.15E-03
3340	1.69E-02	3.46E-03	3.49E-03
3345	1.68E-02	3.54E-03	3.57E-03
3350	1.66E-02	8.03E-03	8.10E-03
3355	1.65E-02	3.63E-03	3.66E-03
3360	1.64E-02	5.24E-03	5.29E-03
3365	1.63E-02	7.19E-03	7.26E-03
3370	1.62E-02	3.94E-03	3.98E-03
3375	1.61E-02	8.46E-03	8.54E-03
3380	1.60E-02	5.11E-03	5.16E-03
3385	1.60E-02	7.49E-03	7.57E-03
3390	1.59E-02	9.86E-03	9.96E-03
3395	1.58E-02	9.55E-03	9.64E-03
3400	1.56E-02	1.25E-02	1.26E-02
3405	1.57E-02	4.46E-03	4.51E-03
3410	1.55E-02	7.08E-03	7.15E-03
3415	1.55E-02	7.28E-03	7.35E-03
3420	1.54E-02	1.32E-02	1.33E-02
3425	1.53E-02	1.00E-02	1.01E-02
3430	1.52E-02	8.69E-03	8.78E-03
3435	1.52E-02	1.16E-02	1.17E-02
3440	1.51E-02	8.03E-03	8.12E-03
3445	1.50E-02	1.13E-02	1.14E-02
3450	1.49E-02	1.12E-02	1.13E-02
3455	1.49E-02	8.31E-03	8.39E-03
3460	1.48E-02	1.25E-02	1.27E-02
3465	1.48E-02	9.82E-03	9.92E-03
3470	1.47E-02	1.23E-02	1.24E-02
3475	1.46E-02	1.09E-02	1.11E-02
3480	1.45E-02	1.12E-02	1.13E-02
3485	1.45E-02	1.21E-02	1.22E-02
3490	1.44E-02	1.04E-02	1.05E-02
3495	1.43E-02	1.23E-02	1.24E-02
3500	1.42E-02	1.19E-02	1.20E-02
3505	1.42E-02	1.18E-02	1.19E-02
3510	1.41E-02	1.20E-02	1.21E-02
3515	1.40E-02	1.15E-02	1.16E-02
3520	1.39E-02	1.21E-02	1.22E-02
3525	1.39E-02	1.14E-02	1.15E-02
3530	1.38E-02	1.11E-02	1.12E-02
3535	1.38E-02	9.46E-03	9.53E-03
3540	1.37E-02	9.03E-03	9.10E-03
3545	1.37E-02	9.54E-03	9.62E-03
3550	1.36E-02	1.05E-02	1.06E-02
3555	1.35E-02	9.06E-03	9.12E-03
3560	1.34E-02	1.08E-02	1.09E-02
3565	1.34E-02	1.09E-02	1.09E-02
3570	1.33E-02	8.34E-03	8.40E-03
3575	1.32E-02	8.64E-03	8.70E-03
3580	1.31E-02	1.02E-02	1.03E-02
3585	1.31E-02	9.17E-03	9.23E-03
3590	1.30E-02	9.45E-03	9.51E-03
3595	1.29E-02	9.67E-03	9.73E-03
3600	1.29E-02	1.03E-02	1.03E-02
3605	1.28E-02	1.04E-02	1.04E-02
3610	1.27E-02	9.48E-03	9.54E-03
3615	1.27E-02	9.47E-03	9.53E-03
3620	1.26E-02	1.16E-02	1.17E-02
3625	1.26E-02	1.02E-02	1.03E-02
3630	1.25E-02	9.96E-03	1.00E-02
3635	1.25E-02	1.03E-02	1.04E-02
3640	1.24E-02	1.15E-02	1.15E-02
3645	1.24E-02	1.06E-02	1.07E-02
3650	1.23E-02	1.01E-02	1.02E-02
3655	1.22E-02	1.10E-02	1.10E-02
3660	1.22E-02	1.09E-02	1.10E-02
3665	1.22E-02	1.03E-02	1.03E-02
3670	1.20E-02	7.90E-03	7.95E-03
3675	1.20E-02	4.83E-03	4.86E-03
3680	1.19E-02	8.33E-03	8.38E-03
3685	1.18E-02	9.44E-03	9.49E-03
3690	1.18E-02	9.69E-03	9.75E-03
3695	1.17E-02	1.01E-02	1.02E-02
3700	1.16E-02	1.09E-02	1.09E-02
3705	1.16E-02	1.08E-02	1.08E-02
3710	1.15E-02	9.36E-03	9.41E-03
3715	1.15E-02	9.23E-03	9.27E-03
3720	1.14E-02	1.04E-02	1.04E-02
3725	1.14E-02	1.07E-02	1.08E-02
3730	1.13E-02	9.27E-03	9.32E-03
3735	1.13E-02	8.58E-03	8.63E-03
3740	1.11E-02	8.85E-03	8.89E-03
3745	1.11E-02	1.03E-02	1.04E-02
3750	1.10E-02	9.29E-03	9.33E-03
3755	1.10E-02	8.99E-03	9.03E-03
3760	1.09E-02	8.86E-03	8.90E-03
3765	1.09E-02	8.55E-03	8.59E-03
3770	1.09E-02	9.12E-03	9.16E-03
3775	1.08E-02	9.05E-03	9.09E-03
3780	1.07E-02	9.57E-03	9.62E-03
3785	1.07E-02	8.81E-03	8.85E-03
3790	1.06E-02	7.76E-03	7.79E-03
3795	1.06E-02	8.87E-03	8.91E-03
3800	1.05E-02	9.86E-03	9.90E-03
3805	1.05E-02	9.30E-03	9.34E-03
3810	1.04E-02	8.25E-03	8.28E-03
3815	1.04E-02	7.76E-03	7.79E-03
3820	1.03E-02	9.66E-03	9.69E-03
3825	1.03E-02	9.51E-03	9.54E-03
3830	1.03E-02	9.59E-03	9.63E-03
3835	1.02E-02	7.69E-03	7.72E-03
3840	1.02E-02	8.98E-03	9.01E-03
3845	1.01E-02	8.78E-03	8.81E-03
3850	1.01E-02	8.83E-03	8.86E-03
3855	1.00E-02	8.51E-03	8.54E-03
3860	9.94E-03	7.99E-03	8.02E-03
3865	9.91E-03	8.10E-03	8.12E-03
3870	9.83E-03	7.36E-03	7.38E-03
3875	9.83E-03	6.76E-03	6.78E-03
3880	9.75E-03	6.53E-03	6.55E-03
3885	9.70E-03	6.77E-03	6.79E-03
3890	9.71E-03	6.88E-03	6.90E-03
3895	9.62E-03	7.48E-03	7.50E-03
3900	9.60E-03	7.93E-03	7.95E-03
3905	9.59E-03	7.93E-03	7.95E-03
3910	9.52E-03	7.14E-03	7.16E-03
3915	9.50E-03	6.99E-03	7.01E-03
3920	9.41E-03	6.95E-03	6.97E-03
3925	9.40E-03	6.85E-03	6.87E-03
3930	9.32E-03	7.05E-03	7.07E-03
3935	9.30E-03	7.35E-03	7.37E-03
3940	9.23E-03	7.40E-03	7.42E-03
3945	9.20E-03	7.54E-03	7.56E-03
3950	9.11E-03	7.63E-03	7.65E-03
3955	9.08E-03	7.72E-03	7.74E-03
3960	9.02E-03	7.75E-03	7.77E-03
3965	9.01E-03	7.81E-03	7.83E-03
3970	8.93E-03	7.68E-03	7.70E-03
3975	8.91E-03	7.51E-03	7.53E-03
3980	8.84E-03	7.39E-03	7.40E-03
3985	8.80E-03	7.43E-03	7.45E-03
3990	8.78E-03	7.37E-03	7.39E-03
3995	8.70E-03	7.21E-03	7.23E-03
4000	8.68E-03	7.10E-03	7.12E-03];
y=[y(:,1) y(:,x+1)];


% --- Executes on selection change in am.
function am_Callback(hObject, eventdata, handles)
% hObject    handle to am (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns am contents as cell array
%        contents{get(hObject,'Value')} returns selected item from am
global sun am abs d R sumflux
if length(abs)>1
    sun=am15(get(handles.am,'value')); %W/m^2/nm
    wavelength=abs(:,1);
    temp=abs(:,get(handles.viewab,'value')+1);
    ab=[temp;(300:wavelength(end)-1)'];
    ab(length(wavelength)-5:end)=max(temp);
    wavelength=[wavelength;(wavelength(end)-1:-1:300)'];
    w=(wavelength(1):-1:300)';
    ab_am=interp1(wavelength,ab,w);
    ab_am(isnan(ab_am))=0;
    am=interp1(sun(:,1),sun(:,2),w)/1.6e-19./(1240./w);%photons/m^2/s/nm;
    am(isnan(am))=0;
    axes(handles.axes2)
    hold off
    area(w,am)
    hold on
    d=str2double(get(handles.d,'string'))*1e-7; %/cm
    R=str2double(get(handles.r,'string'));
    flux=(1-R)*(1-exp(-d*ab_am))./(1-R*exp(-d*ab_am)).*am;
    sumflux=sum(flux);
    set(handles.flux,'string',['Absorbed flux: ' num2str(sumflux,3) '/m^2/s'])
    plot(w,flux,'r')
else
    set(handles.msg,'string','Error: Absorption spectrum is not exist')
end


% --- Executes during object creation, after setting all properties.
function am_CreateFcn(hObject, eventdata, handles)
% hObject    handle to am (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in sf.
function sf_Callback(hObject, eventdata, handles)
% hObject    handle to sf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sf contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sf
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function sf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in method.
function method_Callback(hObject, eventdata, handles)
% hObject    handle to method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns method contents as cell array
%        contents{get(hObject,'Value')} returns selected item from method
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function method_CreateFcn(hObject, eventdata, handles)
% hObject    handle to method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ffrom.
function ffrom_Callback(hObject, eventdata, handles)
% hObject    handle to ffrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ffrom contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ffrom
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function ffrom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ffrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in fto.
function fto_Callback(hObject, eventdata, handles)
% hObject    handle to fto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fto contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fto
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function fto_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function na_Callback(hObject, eventdata, handles)
% hObject    handle to na (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of na as text
%        str2double(get(hObject,'String')) returns contents of na as a double
getmo_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function na_CreateFcn(hObject, eventdata, handles)
% hObject    handle to na (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function miu_Callback(hObject, eventdata, handles)
% hObject    handle to miu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of miu as text
%        str2double(get(hObject,'String')) returns contents of miu as a double


% --- Executes during object creation, after setting all properties.
function miu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to miu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in if1d.
function if1d_Callback(hObject, eventdata, handles)
% hObject    handle to if1d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of if1d
if get(handles.if1d,'value')
    set(handles.getmo,'value',0)
    set(handles.getmo2,'value',0)
end
getmo_Callback(hObject, eventdata, handles)

% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function miurad_Callback(hObject, eventdata, handles)
% hObject    handle to miurad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of miurad as text
%        str2double(get(hObject,'String')) returns contents of miurad as a double


% --- Executes during object creation, after setting all properties.
function miurad_CreateFcn(hObject, eventdata, handles)
% hObject    handle to miurad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function miuext_Callback(hObject, eventdata, handles)
% hObject    handle to miuext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of miuext as text
%        str2double(get(hObject,'String')) returns contents of miuext as a double


% --- Executes during object creation, after setting all properties.
function miuext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to miuext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plqyext_Callback(hObject, eventdata, handles)
% hObject    handle to plqyext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plqyext as text
%        str2double(get(hObject,'String')) returns contents of plqyext as a double


% --- Executes during object creation, after setting all properties.
function plqyext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plqyext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in getmo2.
function getmo2_Callback(hObject, eventdata, handles)
% hObject    handle to getmo2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of getmo2
global I PL2D PL2Df xx yy ee eef
if get(handles.getmo2,'value')
    set(handles.getmo,'value',0)
end
if ~isempty(I)
    axesHandlesToChildObjects = findobj(handles.axes1, 'Type', 'line');
    if ~isempty(axesHandlesToChildObjects)
        delete(axesHandlesToChildObjects);
    end
    x1=get(handles.xx1,'value');
    x2=get(handles.xx2,'value');
    y1=get(handles.yy1,'value');
    y2=get(handles.yy2,'value');
    w1=get(handles.ffrom,'value');
    w2=get(handles.fto,'value');
    xx1=xx(x1);
    yy1=yy(y1);
    xx2=xx(x2);
    yy2=yy(y2);
    PL2D=double(I(min(y1,y2):max(y1,y2),min(x1,x2):max(x1,x2),:));
    PL2D(PL2D<1)=min(PL2D(PL2D>1));
    PL2Df=PL2D(:,:,min(w1,w2):max(w1,w2));
    set(handles.pts,'string',[num2str(size(PL2D,1)*size(PL2D,2)) ' points'])
    eef=ee(min(w1,w2):max(w1,w2));
    if get(handles.getmo2,'value')
        axes(handles.axes1)
        hold on
        if get(handles.pl2d,'value')
            plot([xx1,xx1],[yy1,yy2],'r-.','LineWidth',1);
            plot([xx2,xx2],[yy1,yy2],'r-.','LineWidth',1);
            plot([xx1,xx2],[yy1,yy1],'r-.','LineWidth',1);
            plot([xx1,xx2],[yy2,yy2],'r-.','LineWidth',1);
            set(handles.msg,'string','2D fitting region is displayed')
        end
    end
else
    set(handles.msg,'string','Error: PL data is not exist')
end

% --- Executes on button press in log.
function log_Callback(hObject, eventdata, handles)
% hObject    handle to log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of log
global iflog
iflog=get(handles.log,'value');
getmo_Callback(hObject, eventdata, handles)

% --- Executes on button press in getmiuext.
function getmiuext_Callback(hObject, eventdata, handles)
% hObject    handle to getmiuext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sun am abs d R sumflux ee viewfab T PL integ method Eg EU miuerr
if ~isempty(abs)
    sun=am15(get(handles.am,'value')); %W/m^2/nm
    wavelength=abs(:,1);
    temp=abs(:,get(handles.viewab,'value')+1);
    ab=[temp;(300:wavelength(end)-1)'];
    ab(length(wavelength)-5:end)=max(temp);
    wavelength=[wavelength;(wavelength(end)-1:-1:300)'];
    %w=(wavelength(1):-1:300)';
    w=ee;
    ab_am=interp1(wavelength,ab,w);
    ab_am(isnan(ab_am))=0;
    am=interp1(sun(:,1),sun(:,2),w)/1.6e-19./(1240./w);%photons/m^2/s/nm;
    am(isnan(am))=0;
    d=str2double(get(handles.d,'string'))*1e-7; %/cm
    R=str2double(get(handles.r,'string'));
    flux=(1-R)*(1-exp(-d*ab_am))./(1-R*exp(-d*ab_am)).*am;
    sumflux=sum(flux);
    sumam=sum(am);
    set(handles.flux,'string',['Absorbed flux: ' num2str(sumflux,3) '/m^2/s'])
    miu=str2double(get(handles.miu,'string'));
    T=str2double(get(handles.T,'string'));
    Eg=str2double(get(handles.edit12,'string'));
    EU=str2double(get(handles.edit13,'string'))/1000;
    PLQE_ext=str2double(get(handles.plqyext,'string'));
    axes(handles.axes3);
    viewfab=2;
    integ=1;
    method=get(handles.method,'value');
    lb=0.8;
    ub=1.5;
    lambda=ee;
    options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
    [miusq,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval,miu,lambda,sumam,lb,ub,options);
    set(handles.miusq,'string',miusq)
    set(handles.miusqerr,'string',miuerr)
    [miurad,resnorm,resid,~,~,~,J]=lsqcurvefit(@numval,miu,lambda,sumflux,lb,ub,options);
    set(handles.miurad,'string',miurad)
    set(handles.miuraderr,'string',miuerr)
    miuext=miurad+8.617e-5*T*log(PLQE_ext);
    set(handles.miuext,'string',miuext)
    set(handles.miuexterr,'string',miuerr)
    integ=0;
    T=str2double(get(handles.T2,'string'));
    hold off
    y=numval(miusq,lambda);
    plot(lambda,log10(y),'b')
    hold on
    y=numval(miurad,lambda);
    plot(lambda,log10(y),'r')
    plot(lambda,log10(PL),'k')
    legend('miu\_SQ','miu\_rad','miu','Location','SouthEast')
else
    set(handles.msg,'string','Error: Absorption spectrum is not exist')
end


% --- Executes during object creation, after setting all properties.
function xx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function xx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function yy1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function yy2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in xx1.
function xx1_Callback(hObject, eventdata, handles)
% hObject    handle to xx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx1
getmo2_Callback(hObject, eventdata, handles)

% --- Executes on selection change in yy1.
function yy1_Callback(hObject, eventdata, handles)
% hObject    handle to yy1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yy1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yy1
getmo2_Callback(hObject, eventdata, handles)

% --- Executes on selection change in xx2.
function xx2_Callback(hObject, eventdata, handles)
% hObject    handle to xx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xx2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xx2
getmo2_Callback(hObject, eventdata, handles)

% --- Executes on selection change in yy2.
function yy2_Callback(hObject, eventdata, handles)
% hObject    handle to yy2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yy2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yy2
getmo2_Callback(hObject, eventdata, handles)



function r_Callback(hObject, eventdata, handles)
% hObject    handle to r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of r as text
%        str2double(get(hObject,'String')) returns contents of r as a double
global R
R=str2double(get(handles.r,'string'));

% --- Executes during object creation, after setting all properties.
function r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function T2_Callback(hObject, eventdata, handles)
% hObject    handle to T2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T2 as text
%        str2double(get(hObject,'String')) returns contents of T2 as a double


% --- Executes during object creation, after setting all properties.
function T2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to T2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function miusq_Callback(hObject, eventdata, handles)
% hObject    handle to miusq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of miusq as text
%        str2double(get(hObject,'String')) returns contents of miusq as a double


% --- Executes during object creation, after setting all properties.
function miusq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to miusq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in viewfab.
function viewfab_Callback(hObject, eventdata, handles)
% hObject    handle to viewfab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global aa ee viewfab iflog method R d geometry aafit
if ~isempty(aa)
    k1=str2double(get(handles.miu,'string'));
    k2=str2double(get(handles.T,'string'));
    k3=str2double(get(handles.edit12,'string'));
    k4=str2double(get(handles.edit13,'string'))/1000;
    geometry=get(handles.sf,'value');
    method=get(handles.method,'value');
    d=str2double(get(handles.d,'string'))*1e-7; %cm
    R=str2double(get(handles.r,'string')); %m
    iflog=get(handles.log,'value');
    viewfab=1;
    axes(handles.axes3)
    if method<3
        aafit=numval([k1 k2],ee);
    else
        aafit=numval([k1 k2 k3 k4],ee);
    end
    hold off
    if method==1 || method==3
        plot(ee,(1-R)*(1-exp(-aa*d))./(1-R*exp(-aa*d)))
    else
        plot(ee,(1-exp(-aa*d)));
    end
    hold on
    plot(ee,aafit,'r')
    am_Callback(hObject, eventdata, handles)
else
    set(handles.msg,'string','Error: Absorption spectrum is not exist')
end

function y=absfit(k,x)
global absub Eg
e=1240./x;
y=absub;
alpha0=interp1(e,absub,Eg);
y(e<=Eg)=alpha0*exp(-abs((e(e<=Eg)-Eg))/k(1));
hold off
plot(x,absub)
hold on
plot(x,y,'r')
y=log10(y);
pause(0.01)


% --- Executes on button press in fitsub.
function fitsub_Callback(hObject, eventdata, handles)
% hObject    handle to fitsub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global abs absub absubx eef Eg
absubx=abs(:,1);
absub=abs(:,get(handles.viewab,'value')+1);
absub(absub<1)=1;
absub=absub(absubx>=min(eef)&absubx<=max(eef));
absubx=absubx(absubx>=min(eef)&absubx<=max(eef));
Eg=str2double(get(handles.edit12,'string'));
k0=0.03;
lb=0.001;
ub=0.3;
axes(handles.axes2)
set(handles.msg,'string','Start to fit...')
options = optimset('Display','off','TolX',eps,'TolFun',eps,'LargeScale','on','Algorithm','trust-region-reflective');
[kp,resnorm,resid,~,~,~,J]=lsqcurvefit(@absfit,k0,absubx,log10(absub),lb,ub,options);
set(handles.msg,'string','Fit completed')
set(handles.edit13,'string',kp(1)*1000)


% --- Executes on button press in abort2.
function abort2_Callback(hObject, eventdata, handles)
% hObject    handle to abort2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.abort2,'userdata',1)

% --- Executes on button press in viewf.
function viewf_Callback(hObject, eventdata, handles)
% hObject    handle to viewf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of viewf
global viewfab PL ee iflog method
k1=str2double(get(handles.miu,'string'));
k2=str2double(get(handles.T,'string'));
k3=str2double(get(handles.edit12,'string'));
k4=str2double(get(handles.edit13,'string'))/1000;
iflog=get(handles.log,'value');
method=get(handles.method,'value');
axes(handles.axes2);
viewfab=3;
if method<3
    y=numval([k1 k2],ee);
else
    y=numval([k1 k2 k3 k4],ee);
end
hold off
if iflog
    plot(ee,log10(PL))
    hold on
    plot(ee,log10(y),'r')
    ylabel('log(ph/eV/m^2/s)')
else
    plot(ee,PL)
    hold on
    plot(ee,y,'r')
    ylabel('ph/eV/m^2/s')
end


% --- Executes on button press in dpl2d.
function dpl2d_Callback(hObject, eventdata, handles)
% hObject    handle to dpl2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dpl2d
global I_2D cimage
if get(hObject,'value')
    cimage=I_2D;
    set(handles.dpl2df,'value',0)
    set(handles.dmiu2d,'value',0)
    set(handles.dt2d,'value',0)
    set(handles.deg2d,'value',0)
    set(handles.dub2d,'value',0)
else
    set(handles.dpl2d,'value',1)
end

% --- Executes on button press in dpl2df.
function dpl2df_Callback(hObject, eventdata, handles)
% hObject    handle to dpl2df (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dpl2df
global PL2Df cimage
if get(hObject,'value')
    cimage=mean(PL2Df,3);
    set(handles.dpl2d,'value',0)
    set(handles.dmiu2d,'value',0)
    set(handles.dt2d,'value',0)
    set(handles.deg2d,'value',0)
    set(handles.dub2d,'value',0)
else
    set(handles.dpl2df,'value',1)
end

% --- Executes on button press in dmiu2d.
function dmiu2d_Callback(hObject, eventdata, handles)
% hObject    handle to dmiu2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dmiu2d
global miu2d cimage
if get(hObject,'value')
    cimage=miu2d;
    set(handles.dpl2d,'value',0)
    set(handles.dpl2df,'value',0)
    set(handles.dt2d,'value',0)
    set(handles.deg2d,'value',0)
    set(handles.dub2d,'value',0)
else
    set(handles.dmiu2d,'value',0)
end

% --- Executes on button press in dt2d.
function dt2d_Callback(hObject, eventdata, handles)
% hObject    handle to dt2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dt2d
global T2d cimage
if get(hObject,'value')
    cimage=T2d;
    set(handles.dpl2d,'value',0)
    set(handles.dpl2df,'value',0)
    set(handles.dmiu2d,'value',0)
    set(handles.deg2d,'value',0)
    set(handles.dub2d,'value',0)
else
    set(handles.dt2d,'value',0)
end


% --- Executes on button press in view.
function view_Callback(hObject, eventdata, handles)
% hObject    handle to view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cimage PL2Df miu2d T2d Eg2d Ub2d
axes(handles.axes1)
if ~isempty(cimage)
    if get(handles.dpl2d,'value')
        set(handles.getmo,'enable','on')
        set(handles.getmo2,'enable','on')
        energy1_Callback(hObject, eventdata, handles);
    else
        hold off
        set(handles.getmo,'enable','off')
        set(handles.getmo2,'enable','off')
        if get(handles.dpl2df,'value')
            cimage=mean(PL2Df,3);
        elseif get(handles.dmiu2d,'value')
            cimage=miu2d;
            set(handles.getmo,'value',0)
            set(handles.getmo2,'value',0)
        elseif get(handles.dt2d,'value')
            cimage=T2d;
            set(handles.getmo,'value',0)
            set(handles.getmo2,'value',0)
        elseif get(handles.deg2d,'value')
            cimage=Eg2d;
            set(handles.getmo,'value',0)
            set(handles.getmo2,'value',0)
        elseif get(handles.dub2d,'value')
            cimage=Ub2d;
            set(handles.getmo,'value',0)
            set(handles.getmo2,'value',0)
        end
        switch get(handles.colormap,'value')
            case 1
                imshow(cimage,[],'Colormap',jet(256));
            case 2
                imshow(cimage,[],'Colormap',parula(256));
            case 3
                imshow(cimage,[],'Colormap',hsv(256));
            case 4
                imshow(cimage,[],'Colormap',hot(256));
            case 5
                imshow(cimage,[],'Colormap',cool(256));
            case 6
                imshow(cimage,[],'Colormap',spring(256));
            case 7
                imshow(cimage,[],'Colormap',summer(256));
            case 8
                imshow(cimage,[],'Colormap',autumn(256));
            case 9
                imshow(cimage,[],'Colormap',winter(256));
            case 10
                imshow(cimage,[],'Colormap',gray(256));
            case 11
                imshow(cimage,[],'Colormap',bone(256));
            case 12
                imshow(cimage,[],'Colormap',copper(256));
            otherwise
                imshow(cimage,[],'Colormap',pink(256));
        end
        colorbar;
        title('2D image');
        axis on
        xlabel('X (pix)');
        ylabel('Y (pix)');
    end
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end

% --- Executes on button press in analysis.
function analysis_Callback(hObject, eventdata, handles)
% hObject    handle to analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cimage miu2d T2d I_2D PL2Df Eg2d Ub2d
set(handles.getmo,'value',0)
set(handles.getmo2,'value',0)
set(handles.getmo,'enable','off')
set(handles.getmo2,'enable','off')
if get(handles.dpl2df,'value')
    cimage=mean(PL2Df,3);
elseif get(handles.dmiu2d,'value')
    cimage=miu2d;
elseif get(handles.dt2d,'value')
    cimage=T2d;
elseif get(handles.deg2d,'value')
    cimage=Eg2d;
elseif get(handles.dub2d,'value')
    cimage=Ub2d;
else
    cimage=I_2D;
end
if ~isempty(cimage)
    a=reshape(cimage,size(cimage,1)*size(cimage,2),1);
    axes(handles.axes1)
    hold off
    hist(a,50)
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end


% --- Executes on button press in copy.
function copy_Callback(hObject, eventdata, handles)
% hObject    handle to copy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cimage PL2Df I_2D miu2d T2d  Eg2d Ub2d
set(handles.msg,'string','Begin to copy...');
pause(0.01);
if get(handles.dpl2df,'value')
    cimage=mean(PL2Df,3);
elseif get(handles.dmiu2d,'value')
    cimage=miu2d;
elseif get(handles.dt2d,'value')
    cimage=T2d;
elseif get(handles.deg2d,'value')
    cimage=Eg2d;
elseif get(handles.dub2d,'value')
    cimage=Ub2d;
else
    cimage=I_2D;
end
D=cimage;
if iscell(D)
    set(handles.text3,'string','Error:the data for copy is not exist');
else
    a=size(D);
    t=floor(prod(a)/50000);
    set(handles.msg,'string',['Estimated time: ' num2str(t) ' s...']);
    pause(0.01);
    aa{a(1),a(2)}={};
    for i=1:a(1)
        for j=1:a(2)
            aa{i,j}=num2str(D(i,j));
        end
    end
    d=[];
    for i=1:a(1)
        b=sprintf('%s\t',aa{i,:});
        c=sprintf('%s\n',b);
        d=[d c];
    end
    clipboard('copy',d);
    set(handles.msg,'string','Copy completed');
end


% --- Executes on button press in vmiu2d.
function vmiu2d_Callback(hObject, eventdata, handles)
% hObject    handle to vmiu2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global miu2d
axes(handles.axes3)
hold off
if ~isempty(miu2d)
    switch get(handles.colormap,'value')
        case 1
            imshow(miu2d,[],'Colormap',jet(256));
        case 2
            imshow(miu2d,[],'Colormap',parula(256));
        case 3
            imshow(miu2d,[],'Colormap',hsv(256));   
        case 4
            imshow(miu2d,[],'Colormap',hot(256));
        case 5
            imshow(miu2d,[],'Colormap',cool(256));
        case 6
            imshow(miu2d,[],'Colormap',spring(256));
        case 7
            imshow(miu2d,[],'Colormap',summer(256));
        case 8
            imshow(miu2d,[],'Colormap',autumn(256));
        case 9
            imshow(miu2d,[],'Colormap',winter(256));
        case 10
            imshow(miu2d,[],'Colormap',gray(256));
        case 11
            imshow(miu2d,[],'Colormap',bone(256));
        case 12
            imshow(miu2d,[],'Colormap',copper(256));
        otherwise
            imshow(miu2d,[],'Colormap',pink(256));
    end
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end

% --- Executes on button press in vt2d.
function vt2d_Callback(hObject, eventdata, handles)
% hObject    handle to vt2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global T2d
axes(handles.axes3)
hold off
if ~isempty(T2d)
    switch get(handles.colormap,'value')
        case 1
            imshow(T2d,[],'Colormap',jet(256));
        case 2
            imshow(T2d,[],'Colormap',parula(256));
        case 3
            imshow(T2d,[],'Colormap',hsv(256));
        case 4
            imshow(T2d,[],'Colormap',hot(256));
        case 5
            imshow(T2d,[],'Colormap',cool(256));
        case 6
            imshow(T2d,[],'Colormap',spring(256));
        case 7
            imshow(T2d,[],'Colormap',summer(256));
        case 8
            imshow(T2d,[],'Colormap',autumn(256));
        case 9
            imshow(T2d,[],'Colormap',winter(256));
        case 10
            imshow(T2d,[],'Colormap',gray(256));
        case 11
            imshow(T2d,[],'Colormap',bone(256));
        case 12
            imshow(T2d,[],'Colormap',copper(256));
        otherwise
            imshow(T2d,[],'Colormap',pink(256));
    end
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end


% --- Executes on button press in veg2d.
function veg2d_Callback(hObject, eventdata, handles)
% hObject    handle to veg2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Eg2d
axes(handles.axes3)
hold off
if ~isempty(Eg2d)
    switch get(handles.colormap,'value')
        case 1
            imshow(Eg2d,[],'Colormap',jet(256));
        case 2
            imshow(Eg2d,[],'Colormap',parula(256));
        case 3
            imshow(Eg2d,[],'Colormap',hsv(256));   
        case 4
            imshow(Eg2d,[],'Colormap',hot(256));
        case 5
            imshow(Eg2d,[],'Colormap',cool(256));
        case 6
            imshow(Eg2d,[],'Colormap',spring(256));
        case 7
            imshow(Eg2d,[],'Colormap',summer(256));
        case 8
            imshow(Eg2d,[],'Colormap',autumn(256));
        case 9
            imshow(Eg2d,[],'Colormap',winter(256));
        case 10
            imshow(Eg2d,[],'Colormap',gray(256));
        case 11
            imshow(Eg2d,[],'Colormap',bone(256));
        case 12
            imshow(Eg2d,[],'Colormap',copper(256));
        otherwise
            imshow(Eg2d,[],'Colormap',pink(256));
    end
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end

% --- Executes on button press in vurb2d.
function vurb2d_Callback(hObject, eventdata, handles)
% hObject    handle to vurb2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Ub2d
axes(handles.axes3)
hold off
if ~isempty(Ub2d)
    switch get(handles.colormap,'value')
        case 1
            imshow(Ub2d,[],'Colormap',jet(256));
        case 2
            imshow(Ub2d,[],'Colormap',parula(256));
        case 3
            imshow(Ub2d,[],'Colormap',hsv(256));   
        case 4
            imshow(Ub2d,[],'Colormap',hot(256));
        case 5
            imshow(Ub2d,[],'Colormap',cool(256));
        case 6
            imshow(Ub2d,[],'Colormap',spring(256));
        case 7
            imshow(Ub2d,[],'Colormap',summer(256));
        case 8
            imshow(Ub2d,[],'Colormap',autumn(256));
        case 9
            imshow(Ub2d,[],'Colormap',winter(256));
        case 10
            imshow(Ub2d,[],'Colormap',gray(256));
        case 11
            imshow(Ub2d,[],'Colormap',bone(256));
        case 12
            imshow(Ub2d,[],'Colormap',copper(256));
        otherwise
            imshow(Ub2d,[],'Colormap',pink(256));
    end
else
    set(handles.msg,'string','Error: The data for displaying is not exist')
end

% --- Executes on button press in deg2d.
function deg2d_Callback(hObject, eventdata, handles)
% hObject    handle to deg2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of deg2d
global Eg2d cimage
if get(hObject,'value')
    cimage=Eg2d;
    set(handles.dpl2d,'value',0)
    set(handles.dmiu2d,'value',0)
    set(handles.dt2d,'value',0)
    set(handles.dpl2df,'value',0)
    set(handles.dub2d,'value',0)
else
    set(handles.deg2d,'value',1)
end

% --- Executes on button press in dub2d.
function dub2d_Callback(hObject, eventdata, handles)
% hObject    handle to dub2d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dub2d
global Ub2d cimage
if get(hObject,'value')
    cimage=Ub2d;
    set(handles.dpl2d,'value',0)
    set(handles.dmiu2d,'value',0)
    set(handles.dt2d,'value',0)
    set(handles.dpl2df,'value',0)
    set(handles.deg2d,'value',0)
else
    set(handles.dub2d,'value',1)
end


% --- Executes on button press in fixT.
function fixT_Callback(hObject, eventdata, handles)
% hObject    handle to fixT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fixT



function naf_Callback(hObject, eventdata, handles)
% hObject    handle to naf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of naf as text
%        str2double(get(hObject,'String')) returns contents of naf as a double


% --- Executes during object creation, after setting all properties.
function naf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to naf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in copy1d.
function copy1d_Callback(hObject, eventdata, handles)
% hObject    handle to copy1d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global copyfit1d
set(handles.msg,'string','Begin to copy...');
pause(0.01);
D=copyfit1d;
if isempty(D)
    set(handles.text3,'string','Error:the data for copy is not exist');
else
    a=size(D);
    t=floor(prod(a)/50000);
    set(handles.msg,'string',['Estimated time: ' num2str(t) ' s...']);
    pause(0.01);
    aa{a(1),a(2)}={};
    for i=1:a(1)
        for j=1:a(2)
            aa{i,j}=num2str(D(i,j));
        end
    end
    d=[];
    for i=1:a(1)
        b=sprintf('%s\t',aa{i,:});
        c=sprintf('%s\n',b);
        d=[d c];
    end
    clipboard('copy',d);
    set(handles.msg,'string','Copy completed');
end
