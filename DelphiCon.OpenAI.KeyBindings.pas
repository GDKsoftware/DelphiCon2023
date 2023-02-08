unit DelphiCon.OpenAI.KeyBindings;

interface

uses
  ToolsAPI,
  VCL.Menus,
  System.Classes;

type
  TOpenAIKeybindings = class(TNotifierObject, IOTAKeyboardBinding)
  private
    procedure Bind(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
    function SendRequestToOpenAI(const Prompt: string): string;
  public
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

implementation

uses
  Vcl.Dialogs,
  OpenAI,
  OpenAI.Completions,
  System.SysUtils;

var
  iKeyBindingIndex: Integer;

{ TOpenAIKeybindings }

procedure TOpenAIKeybindings.Bind(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  if KeyCode = TextToShortCut('Ctrl+Shift+F7') then
  begin
    var SelectedText := Context.EditBuffer.EditBlock.Text;
    var OpenAIResult := SendRequestToOpenAI(SelectedText);

    var TextToInsert: TArray<string> := OpenAIResult.Split([#10, #13]);

    for var Line in TextToInsert do
    begin
      Context.EditBuffer.EditPosition.InsertText(Line + sLineBreak);
      Context.EditBuffer.EditPosition.MoveBOL;
    end;

    BindingResult := TKeyBindingResult.krHandled;
  end;
end;

procedure TOpenAIKeybindings.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([TextToShortCut('Ctrl+Shift+F7')], Bind, nil);
end;

function TOpenAIKeybindings.GetBindingType: TBindingType;
begin
  Result := TBindingType.btPartial;
end;

function TOpenAIKeybindings.GetDisplayName: string;
begin
  Result := 'DelphiCon OpenAI';
end;

function TOpenAIKeybindings.GetName: string;
begin
  Result := 'DelphiConOpenAI';
end;

function TOpenAIKeybindings.SendRequestToOpenAI(const Prompt: string): string;
begin
  var OpenAI := TOpenAI.Create(nil, '<your key here>');

  var Completions := OpenAI.Completion.Create(
                     procedure(Params: TCompletionParams)
                     begin
                       Params.Prompt(Prompt);
                       Params.Model('text-davinci-003');
                       Params.MaxTokens(1000);
                     end);
  try
    for var Choice in Completions.Choices do
    begin
      Result := Choice.Text;
      Break;
    end;
  finally
    Completions.Free;
    OpenAI.Free;
  end;
end;

initialization
  iKeyBindingIndex := (BorlandIDEServices As IOTAKeyboardServices).AddKeyboardBinding(TOpenAIKeybindings.Create)

finalization
  if iKeyBindingIndex > 0 Then
    (BorlandIDEServices As IOTAKeyboardServices).RemoveKeyboardBinding(iKeyBindingIndex);


end.
