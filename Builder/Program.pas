﻿namespace Builder;

interface

uses
  RemObjects.Builder,
  System.Collections.Generic,
  System.IO,
  System.Linq, 
  NDesk.Options;


type
  ConsoleApp = class
  public
    class method Main(args: array of String): Integer;
  end;

  Logger = public class(ILogger)
  private
  public
    method LogDebug(s: System.String);
    method LogWarning(s: System.String);
    method LogMessage(s: System.String);
    method LogHint(s: System.String);
    method LogError(s: System.String);
    method Enter(aScript: String; params args: array of Object);
    method &Exit(aScript: String; params args: array of Object);

    property ShowDebug: Boolean := false;
    property ShowWarning: Boolean := true;
    property ShowMessage: Boolean := true;
    property ShowHint: Boolean := true;
  end;

implementation

method Logger.LogDebug(s: System.String);
begin
  if not ShowDebug then exit;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.DarkBlue;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogError(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Red;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogHint(s: System.String);
begin
  if not ShowHint then exit;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Magenta;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogMessage(s: System.String);
begin
  if not ShowMessage then exit;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Gray;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogWarning(s: System.String);
begin
  if not ShowWarning then exit;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Yellow;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.Enter(aScript: String; params args:  array of Object);
begin
  if (length(args) = 1) and (args[0] is array of Object) then begin
    args := Array of Object(args[0]);
  end;

  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.White;
  var lArgs := String.Join(', ', args);
  if length(lArgs) > 0 then lArgs := ' '+lArgs;
  Console.WriteLine('Enter: '+aScript+ lArgs);
  Console.ForegroundColor := lCol;
end;

method Logger.&Exit(aScript: String; params  args:array of  Object);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.White;
  var lArgs := String.Join(', ', args);
  if length(lArgs) > 0 then lArgs := ' '+lArgs;
  Console.WriteLine('Exit: '+aScript+ lArgs);
  Console.ForegroundColor := lCol;
end;

class method ConsoleApp.Main(args: array of String): Integer;
begin
  Console.WriteLine('TrainRunner copyright (c) 2012 RemObjects Software');
  var lLogger := new Logger;
  var lGlobalVars := new Dictionary<string, string>;
  var lOptions := new OptionSet();
  var lShowHelp: Boolean := false;
  var lDryRun: Boolean := false;
  var lWait := false;
  var lGlobalSettings: String := Path.Combine(Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location), 'builder.ini');
  var lIncludes: List<string> := new List<string>;
  lOptions.Add('o|options=', 'Override the ini file with the global options', v-> begin lGlobalSettings := coalesce(lGlobalSettings, v); end);
  lOptions.Add('d|debug', 'Show debugging messages', v-> begin lLogger.ShowDebug := assigned(v); end);
  lOptions.Add('w|warning', 'Show warning messages', v-> begin lLogger.ShowWarning := assigned(v); end);
  lOptions.Add('i|hint', 'Show hint messages', v-> begin lLogger.ShowDebug := assigned(v); end);
  lOptions.Add('m|message', 'Show info messages', v-> begin lLogger.ShowMessage := assigned(v); end);
  lOptions.Add("h|?|help", "show help", v -> begin lShowHelp := assigned(v); end );
  lOptions.Add('v|var=', 'Defines global vars; sets {0:name}={1:value}; multiple allowed', (k, v) -> begin if assigned(k) and assigned(v) then lGlobalVars.Add(k, v); end);
  lOptions.Add('include=', 'Include a script', (v) -> begin if assigned(v) then lIncludes.Add(v); end);
  lOptions.Add('wait', 'Wait for a key before finishing', v-> begin lWait := assigned(v) end);
  lOptions.Add('dryrun', 'Do a script dry run (skips file/exec actions)', v->begin lDryRun := assigned(v); end);
  var lArgs: List<String>;
  try
    lArgs := lOptions.Parse(args);
  except
    on  Exception  do
      lShowHelp := true;
  end;
  if  lShowHelp then begin
    Console.WriteLine('TrainRunner.exe <script.js> [options]');
    lOptions.WriteOptionDescriptions(Console.Out);
    exit 1;
  end else if lArgs.Count = 0 then begin
    lLogger.LogError('No files specified');
    exit 1;
  end;
  try
    var lRoot := new RemObjects.Builder.API.Environment();
    lRoot.LoadSystem;
    if File.Exists(lGlobalSettings) then 
      lRoot.LoadIni(lGlobalSettings);
    for each el in lGlobalVars do lRoot[el.Key] := el.Value;
    for each el in lArgs do begin
      var lEngine := new Engine(lRoot, el);
      lEngine.Logger := lLogger;
      lEngine.DryRun := lDryRun;
      for each incl in lIncludes do
        lEngine.LoadInclude(incl);
      lEngine.Run();
      lEngine.Logger := nil;
    end;
  except
    on e: Exception do begin
      lLogger.LogError('Exception: {0}', e.Message);

      exit 1;
    end;
  finally
    if lWait then begin
      console.WriteLine('Waiting for enter to continue');
      Console.ReadLine;
    end;
  end;
end;

end.