program msgTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  Windows,
  msgpack;

type

  { TMyApp }

  TMyApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

  { TMyApp }




  function GetTick: longword;
  var
    tick, freq: TLargeInteger;
  begin
    QueryPerformanceFrequency(freq);
    QueryPerformanceCounter(tick);
    Result := Trunc((tick / freq) * 1000);
  end;

  procedure BenchMsgPack();
  var
    js: IMsgPackObject;
    xs: IMsgPackObject;
    i, l: integer;
    k: cardinal;
    s: string;
    ts: TMsgPackMap;
    Data: rawbytestring;
    a: TMsgPackArray;
  begin
    Randomize;
    k := GetTick;
    js := TMsgPackObject.Create(mptMap);
    ts := js.AsMap;
    for i := 1 to 100000 do
    begin
      l := i * 33;
      s := 'param' + IntToStr(l);
      ts.Put(s, TMsgPackObject.Create(s));
      s := 'int' + IntToStr(l);
      ts.Put(s, TMsgPackObject.Create(i));
    end;
    Writeln('insert map:', GetTick - k);

    k := GetTick();
    ts.Put('array', TMsgPackObject.Create(mptArray));
    a := ts['array'].AsArray();
    for i := 1 to 1000000 do
      a.Add(TMsgPackObject.Create(i * 33));
    Writeln('insert array:', GetTick - k);

    k := GetTick;
    Data := js.AsMsgPack();
    Writeln('dump: ', GetTick - k);
    Writeln('size: ', Length(Data));

    k := GetTick;
    xs := TMsgPackObject.Parse(Data);
    Writeln('parse: ', GetTick - k);

    k := GetTick;
    ts := xs.AsMap;
    for i := 1 to 100000 * 2 do
    begin
      l := i * 33;
      s := 'param' + IntToStr(l);
      ts.Get(s);

      l := i * 33;
      s := 'param' + IntToStr(l);
      ts.Get(s);
    end;
    Writeln('access map: ', GetTick - k);
  end;




  procedure TMyApp.DoRun;
  var
    ErrorMsg: string;
  begin
    // quick check parameters
    ErrorMsg := CheckOptions('h', 'help');
    if ErrorMsg <> '' then
    begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    // parse parameters
    if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    try

      Writeln('--- MsgPack ---');
      k := GetTick;
      BenchMsgPack();
      Writeln('total + cleanup: ', GetTick - k);

    except
      on E: Exception do
      begin
        Writeln(E.Message);
      end;
    end;
    readln;

    // stop program loop
    Terminate;
  end;

  constructor TMyApp.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMyApp.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMyApp.WriteHelp;
  begin
    { add your help code here }
    writeln('Usage: ', ExeName, ' -h');
  end;



var
  Application: TMyApp;
  k: cardinal;



begin
  Application := TMyApp.Create(nil);
  Application.Title := 'My App';
  Application.Run;
  Application.Free;
end.
