ods listing close;
ods output Attributes=Attributes EngineHost=EngineHost Variables=Variables;
  proc contents data=sashelp.class;
  run;
ods output clear;
ods listing;
data _null_;
    set EngineHost;
    if Label1 = "Release Created" then call symputx('releaseCreated', cValue1);
    if Label1 = "Host Created" then call symputx('hostCreated', cValue1);
  run;

data _null_;
    set Attributes;
    if Label1 = "Engine" then call symputx('engine', cValue1);
    if Label1 = "Created" then call symputx('created', cValue1);
    if Label1 = "Last Modified" then call symputx('lastModified', cValue1);
run;

%put &=releaseCreated &=hostCreated &=created &=lastModified &engine;
