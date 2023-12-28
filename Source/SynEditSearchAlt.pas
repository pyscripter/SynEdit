unit SynEditSearchAlt;

{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditSearch.pas, released 2000-04-07.

The Original Code is based on the mwEditSearch.pas file from the mwEdit
component suite by Martin Waldenburg and other developers.
Portions created by Martin Waldenburg are Copyright 1999 Martin Waldenburg.
Unicode translation by Maël Hörz.
All Rights Reserved.

Contributors to the SynEdit project are listed in the Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynEditSearch.pas,v 1.12.2.6 2009/09/29 00:16:46 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
  This uses the Delphi library routine SearchBuf which uses a "wholeword" definition
  different from SynEdit.
-------------------------------------------------------------------------------}


interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  SynEditTypes,
  SynEditMiscClasses;

type
  TSynEditSearchAlt = class(TSynEditSearchCustom)
  private
    Run: PWideChar;
    Origin: PWideChar;
    TheEnd: PWideChar;

    FTextToSearch: string;
    FTextLen: Integer;

    FPattern: String;
    FOriginalPattern: string;
    FPatLen: Integer;

    FCaseSensitive: Boolean;
    FWholeWord: Boolean;
    FBackwards: Boolean;
    FSearchOptions: TStringSearchOptions;

    FResults: TList;

    function FindFirst(const NewText: string; StartIndex: Integer = 1): Integer;
    function Next: Integer;
    function Prev: Integer;

  protected
    procedure SetPattern(const Value: string); override;
    function GetPattern: string; override;
    function GetLength(Index: Integer): Integer; override;
    function GetResult(Index: Integer): Integer; override;
    function GetResultCount: Integer; override;
    procedure SetOptions(const Value: TSynSearchOptions); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    function FindAll(const NewText: string; StartIndex: Integer = 1): Integer; override;
    function Replace(const aOccurrence, aReplacement: string): string; override;
  end;

implementation

constructor TSynEditSearchAlt.Create(aOwner: TComponent);
begin
  inherited;
  FResults := TList.Create;
end;

destructor TSynEditSearchAlt.Destroy;
begin
  FResults.Free;
  inherited Destroy;
end;

function TSynEditSearchAlt.GetLength(Index: Integer): Integer;
begin
  Result := FPatLen;
end;

function TSynEditSearchAlt.GetPattern: string;
begin
  Result := FOriginalPattern;
end;

procedure TSynEditSearchAlt.SetPattern(const Value: string);
begin
  FOriginalPattern := Value;
  if FCaseSensitive then
    FPattern := FOriginalPattern
  else
    FPattern := AnsiLowerCase(FOriginalPattern);
  FPatLen := Length(FOriginalPattern);
end;

procedure TSynEditSearchAlt.SetOptions(const Value: TSynSearchOptions);
begin
  FWholeWord := ssoWholeWord in Value;
  FBackwards := ssoBackwards in Value;
  FCaseSensitive := ssoMatchCase in Value;
  SetPattern(FOriginalPattern);
end;

function TSynEditSearchAlt.GetResult(Index: Integer): Integer;
begin
  Result := 0;
  if (Index >= 0) and (Index < FResults.Count) then
    Result := Integer(FResults[Index]);
end;

function TSynEditSearchAlt.GetResultCount: Integer;
begin
  Result := FResults.Count;
end;

function TSynEditSearchAlt.Replace(const aOccurrence, aReplacement: string): string;
begin
  Result := aReplacement;
end;

procedure ReverseTList(AList: TList);
var
  b, e: Integer;
begin
  b := 0;
  e := AList.Count - 1;
  while b < e do
  begin
    AList.Exchange(b, e);
    Inc(b);
    Dec(e);
  end;
end;

function TSynEditSearchAlt.FindAll(const NewText: string; StartIndex: Integer = 1): Integer;
var
  Found: Integer;
begin
  FResults.Count := 0;
  Found := FindFirst(NewText, StartIndex);
  while Found > 0 do
  begin
    FResults.Add(Pointer(Found));
    if FBackwards then
      Found := Prev
    else
      Found := Next;
  end;
  // The backwards search creates the results list in reverse order so reverse it per SynEditSearch specs.
  if FBackwards then
    ReverseTList(FResults);
  Result := FResults.Count;
end;

function TSynEditSearchAlt.FindFirst(const NewText: string; StartIndex: Integer = 1): Integer;
begin
  Result := 0;
  FTextLen := Length(NewText);
  if FTextLen >= FPatLen then
  begin
    if FBackwards then
      FSearchOptions := [soMatchCase]
    else
      FSearchOptions := [soDown, soMatchCase];
    if FWholeWord then
      FSearchOptions := FSearchOptions + [soWholeWord];
    if FCaseSensitive then
      FTextToSearch := NewText
    else
      FTextToSearch := AnsiLowerCase(NewText);
    Origin := PWideChar(FTextToSearch);
    TheEnd := Origin + FTextLen;
    Run := Origin + (StartIndex - 1);
    if FBackwards then
      Result := Prev
    else
      Result := Next;
  end;
end;

function TSynEditSearchAlt.Prev: Integer;
var
  Res: PChar;
begin
  Result := 0;
  {$IF RTLVersion112}
    // SelStart is oddly -1 based when searching backwards, but only for Delphi 11.2 and up.
    Res := SearchBuf(Origin, Length(FTextToSearch), (Run - Origin) - 1, 0, FPattern, FSearchOptions);
  {$ELSE}
    Res := SearchBuf(Origin, Length(FTextToSearch), (Run - Origin), 0, FPattern, FSearchOptions);
  {$ENDIF}
  if Res <> nil then
  begin
    Run := Res;
    Result := Res - Origin + 1;
  end;
end;

function TSynEditSearchAlt.Next: Integer;
var
  Res: PChar;
begin
  Result := 0;
  Res := SearchBuf(Origin, Length(FTextToSearch), (Run - Origin), 0, FPattern, FSearchOptions);
  if Res <> nil then
  begin
    Run := Res + FPatLen;
    Result := Res - Origin + 1;
  end;
end;

end.

