﻿namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Text,
  System.Xml.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  XcodePlugin = public class(IPluginRegistration)
  private
    class method XcodeRun(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions; aActions: String);
  public
    method &Register(aServices: IApiRegistrationServices);

    class method CheckSettings(aServices: IApiRegistrationServices);

    [WrapAs('xcode.clean', SkipDryRun := false)]
    class method XcodeClean(aServices: IApiRegistrationServices;ec: ExecutionContext;  aProject: String; aOptions: XcodeOptions);
    [WrapAs('xcode.build', SkipDryRun := false)]
    class method XcodeBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions);
    [WrapAs('xcode.rebuild', SkipDryRun := false)]
    class method XcodeRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions);
  end;

  XcodeOptions = public class
  private
  public
    property configuration: String;
    property target: String;
    property destinationFolder: String;
    property sdk: String;
    property extraArgs: String;
  end; 

implementation

method XcodePlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('xcode')
    .AddValue('clean', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(XcodePlugin), 'XcodeClean'))
    .AddValue('build', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(XcodePlugin), 'XcodeBuild'))
    .AddValue('rebuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(XcodePlugin), 'XcodeRebuild'));
end;

class method XcodePlugin.CheckSettings(aServices: IApiRegistrationServices);
begin
end;

class method XcodePlugin.XcodeRun(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions; aActions: String);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  //aServices.Logger.LogMessage('Building: '+aProject);

  CheckSettings(aServices);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append(' -project "'+aProject+'"');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' -configuration "'+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.target) then
      sb.Append(' -target "'+aOptions.target+'"');
    if not String.IsNullOrEmpty(aOptions.sdk) then
      sb.Append(' -sdk "'+aOptions.sdk+'"');
    sb.Append(' '+aActions);
    if not String.IsNullOrEmpty(aOptions.destinationFolder) then
      sb.Append(' SYMROOT="'+aServices.ResolveWithBase(ec,aOptions.destinationFolder)+'"');
    sb.Append(' '+aOptions.extraArgs);
  end;
  //aServices.Logger.LogMessage(sb.ToString);


  var lOutput := new StringBuilder;
  var lErrors := new System.Collections.Generic.List<String>;
  var n := Shell.ExecuteProcess('/usr/bin/xcodebuild', sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      locking lErrors do lErrors.Add(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin

      var atrim := a.TrimStart;
      if atrim.StartsWith('ld: ') or atrim.StartsWith('clang: ') then
        locking lErrors do lErrors.Add(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then begin
    aServices.Logger.LogMessage(lOutput.ToString);
    for each el in lErrors do
      aServices.Logger.LogError(el);
  end else
    aServices.Logger.LogDebug(lOutput.ToString);


  if n <> 0 then raise new Exception('Xcode failed');

end;

class method XcodePlugin.XcodeClean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions);
begin
  XcodeRun(aServices, ec, aProject, aOptions, 'clean');
end;

class method XcodePlugin.XcodeBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions);
begin
  XcodeRun(aServices, ec, aProject, aOptions, 'build');
end;

class method XcodePlugin.XcodeRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: XcodeOptions);
begin
  XcodeRun(aServices, ec, aProject, aOptions, 'clean build');
end;

end.
