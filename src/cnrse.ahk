;================================================================================
;  CNR - Recipe-Script Editor
;  Author: Tobias Wirth (dunahan@schwerterkueste.de)
;================================================================================
; v0.8        shows simple reciepes, with some flaws
; v0.8.0.1  now more fexibility is provided, but not all possibilities are shown.
;================================================================================
VERSION := "0.8.0.1"
;================================================================================

#NoTrayIcon
#NoEnv                                                                        ; For performance and combatibility with newer AHK versions
#SingleInstance force

#Include cnrse_funcs.ahk                                                      ; external funcitons, don't blow up main script and readable

;==================================================================================
; As a reminder, the array-file holds of the following:
;  =>  M enues  (M|sMenuLevel5Scrolls)                                                                     => more than one possible
;  =>  N ame of the workbench (N|cnrScribeAverage)                                                  => sometimes there isn't one existent (as for cnrWaterTub.nss)
;  =>  R ecipes  (R|sMenuLevel5Scrolls|See Invisibility|NW_IT_SPARSCR205|1)           => as many recipes are provided in the recipe scripts
;  =>  another reminder, the function prints the product-tag from every recipe at the end of the following strings  <=
;  =>  Com P onents (P1|Blank Scroll|x2_it_cfm_bscrl|1)                                             => more than one possible, number of components are at P<#>
;  =>  B iproducts (B1|hw_glassphio|1|1)                                                                     => if a recipe produces a leftover, these are biproducts (numbering same as products)
;  =>  L evel  (L|6)                                                                                                     => the creation level required
;  =>  e X perience points (X|60|60)                                                                            => how many XP the PC gets (XP | CNR-XP)
;  =>  A ttributes  (A|0|0|0|50|50|0)                                                                              => which attributes are needed and at what percentage, MUST be in sum 100(%)!
;================================================================================

;================================================================================
;                                                Persistent Variables
;================================================================================
EXE := A_WorkingDir . "\cnrse.exe"
NAME := "CNR - Recipe-Script Editor"
IniRead, SCRIPT_DIR, config.ini, Default, SCRIPT_DIR, %A_WorkingDir%\mod\     ; at first, but configurable at latest run
IniRead, TEMP_DIR, config.ini, Default, TEMP_DIR, %A_WorkingDir%\tmp\         ; folder where temporary files are saved
IniRead, ITM_FILE, config.ini, Default, ITM_FILE, %A_WorkingDir%\items.csv    ; at first, a file with comma-separated values, here items of CNR 3.05
IniRead, MOVE_WIN, config.ini, Default, MOVE_WIN, 1                           ; should the recipe window moved with the main window
IniRead, DEBUG, config.ini, Default, DEBUG, 0                                 ; DebugMode 1 / 0

;================================================================================
;                                                Main Scripts
;================================================================================

Main:                                                                         ; <<<===  Main begins
{
  Menu, MyMenu, Add, Options, Options                                         ; build up menue
  Menu, MyMenu, Add, ShowAbout, ShowAbout
  Gui, 1: Menu, MyMenu
  
  IniRead, RecipeSpacerX, config.ini, Lists, RecipeSpacerX, 10                ; load the definitions for building up the list of the scripts
  IniRead, RecipeSpacerY, config.ini, Lists, RecipeSpacerY, 30                ; later more adjustable?
  IniRead, MaxRecipesPerRow, config.ini, Lists, MaxRecipesPerRow, 9
  CountedRecipes := 0
  
  IniRead, RecipeSpacerXAdd, config.ini, Lists, RecipeSpacerXAdd, 120
  IniRead, RecipeSpacerYAdd, config.ini, Lists, RecipeSpacerYAdd, 25
  
  Loop, Files, %SCRIPT_DIR%cnr*.nss                                           ; go through all cnr*.nss scripts in folder. this is for testing yet. later it should extract it from mod
  {
    IfNotInString, A_LoopFileName, _
    {
      StringTrimRight, VarName, A_LoopFileName, 4
      Gui, 1: Add, Text, x%RecipeSpacerX%  y%RecipeSpacerY% w120 h20 v%VarName% cBlue gRecipeShow, %A_LoopFileName%
      %VarName%_TT := "Double-click to start editing"                         ; want to do translate it later
      CountedRecipes := CountedRecipes + 1
      RecipeSpacerY := RecipeSpacerY + RecipeSpacerYAdd
      
      If (CountedRecipes > MaxRecipesPerRow)
      {
        RecipeSpacerX := RecipeSpacerX + RecipeSpacerXAdd
        IniRead, RecipeSpacerY, config.ini, Lists, RecipeSpacerY, 30
        CountedRecipes := 0
      }
      
      If (DEBUG = 1)
        MsgBox, %A_LoopFileName%
    }
  }
  
  Gui, 1: Submit, NoHide
  
  Gui, 1: Font, c000000 9, MS Sans SerIf
  Gui, 1: +E0x80000000
  
  Gui, 1: Show
  Gui, 1: Show, center autosize, %NAME%
  WinSet, exstyle, -0x80000, %NAME%
  
  OnMessage(0x200, "WM_MOUSEMOVE")
  
  WinGet, MainWin
  WinGetPos, WinGui1X, WinGui1Y, WinGui1W, WinGui1H, %NAME%                   ; save position of the main window, later interesting for more than one monitor
  
  RecipeSpacerX = 
  RecipeSpacerY = 
  MaxRecipesPerRow = 
  CountedRecipes = 
  
  RecipeSpacerXAdd = 
  RecipeSpacerYAdd = 
  
  If (MOVE_WIN = 1)
  {
    Loop                                                                      ; was main moved, so move edit window too
    {
      Sleep, 20
      WinGetPos, WinGui1NewX, WinGui1NewY, WinGui1NewW, WinGui1NewH, %NAME%
      
      If (WinGui1NewX <> WinGui1X OR WinGui1NewY <> WinGui1Y)
      {
        WinGui2NewPosX := WinGui1NewX + WinGui1W + 15
        WinGui2NewPosY := WinGui1NewY
        WinMove, Edit Recipes, , %WinGui2NewPosX%, %WinGui2NewPosY%
      }
    }
  }
}
Return                                                                        ; <<<===  Main ending

RecipeShow:                                                                   ; <<<===  RecipeShow begins
{
  If A_GuiEvent = DoubleClick                                               ; if user double clicks a script, editing begins
  {
    If (EditWin != "")                                                      ; bäh, you are editing one recipe already. don't open another one!
    {
      MsgBox, A recipe is already being edited                              ; bad spelling?! should be corrected and later translated
      Return
    }
    
    ; should set another if-question is the temp_dir existing. if not create it!
    
    FileDelete, %TEMP_DIR%*.tmp                                             ; first, delete all temporary files that where left over
    
    MouseGetPos, , , , RecipeScriptControl, 1                               ; which script was clicked
    StringTrimLeft, StaticNbr, RecipeScriptControl, 6                       ; recieve that number
    ControlGetText, RecipeScript, %RecipeScriptControl%                     ; read the text of that control
    
    If (DEBUG = 1)
      MsgBox, Within RecipeShow`nMouseGetPos: %RecipeScriptControl%`nStringTrimLeft: %StaticNbr%`nControlGetText: %RecipeScript%
    
    If (RecipeScript = )                                                    ; the text of the control is missing, so is the script?
    {                                                                       ; tell the user that something went wrong...
      MsgBox, The clicked script is somehow missing.                        ; translate that later
      Return
    }
    
    RecipeScriptPath = %SCRIPT_DIR%%RecipeScript%                           ; build the path and file in a seperate script
    RecipeScriptTemp = %TEMP_DIR%recipebook.tmp                             ; this is the file where the script is copied to, so nothing could go wrong with the original
    FileCopy, %RecipeScriptPath%, %RecipeScriptTemp%, 1                     ; do the copy
    
    If (DEBUG = 1)
      MsgBox, Show path to file: %RecipeScriptPath%`nShow path to temp: %RecipeScriptTemp%
    
    ArrayTmpPath = %TEMP_DIR%array.tmp                                      ; this would be the array, where the translated script would be saved to
    CreateArrayTempFile(RecipeScriptTemp, ArrayTmpPath)                     ; create the file for saving the arrays to it, less memory using
    
    Gui, 2: +owner1
    Gui, 2: +ToolWindow
    Gui, 2: +LastFound
    hGui2 := WinExist()
    
    PrintWorkbenchName := ReturnWorkbenchFromRecipe(ArrayTmpPath)
    PrintWorkbenchMenu := ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
    PrintRecipesWithinWorkbench := ReturnRecipeListFromRecipe(ArrayTmpPath)
    
    Gui, 2: Add, Text, x6   y8 w250 h21, %PrintWorkbenchName%                   ; build up GUI 2
    Gui, 2: Add, DDL,  x235 y5 w310 Sort vActRecipeProduct Choose1 gRecipesWithinWorkbench, %PrintRecipesWithinWorkbench%
    
    Gui, 2: Submit, NoHide
    
    PrintActRecipeProduct := TrimToGetProduct(ActRecipeProduct)
    PrintActRecipeProductTag := TrimToGetTag(ActRecipeProduct)
    PrintActRecipeWorkbenchName := GetWorkbenchName(PrintActRecipeProductTag)
    PrintActRecipeProductNbr := GetCreatedProductNbr(PrintActRecipeProductTag)
    
    Me := 0
    If (PrintWorkbenchMenu = "None")
      Me := 1
    
    IfInString, PrintWorkbenchMenu, %PrintActRecipeWorkbenchName%
      Me := GetWorkbenchNumberInList(PrintWorkbenchMenu, PrintActRecipeWorkbenchName)
    
    Gui, 2: Add, Tab2, x6 y35 w550 h300, RecipeTag|Components|Miscellaneous     ; build up contents
      Gui, 2: Tab, RecipeTag, , Exact
        Gui, 2: Add, Text, x15  y65  w100 h21                                   , Workbench:
        Gui, 2: Add, Edit, x105 y61  w250      vEditWorkbenchName -Wrap ReadOnly, %PrintWorkbenchName%
        Gui, 2: Add, Text, x15  y90  w100 h21                                   , WorkbenchMenu:
        Gui, 2: Add, DDL,  x105 y86  w250      vEditWorkbenchMenu     Choose%Me%, %PrintWorkbenchMenu%
        Gui, 2: Add, Text, x15  y115 w100 h21                                   , ProductName:
        Gui, 2: Add, Edit, x105 y111 w250      vEditRecipeProduct       ReadOnly, %PrintActRecipeProduct%
        Gui, 2: Add, Text, x15  y140 w100 h21                                   , ProductTag:
        Gui, 2: Add, Edit, x105 y136 w250      vEditRecipeProductTag    ReadOnly, %PrintActRecipeProductTag%
        Gui, 2: Add, Text, x15  y165 w100 h21                                   , ProductNbr:
        Gui, 2: Add, Edit, x105 y161 w250      vEditRecipeProductNbr    ReadOnly, %PrintActRecipeProductNbr%
        
        ; skript beispiel einfuegen?!
        Gui, 2: Font, , Courier new
        SCRIPTVAR := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
        
        Gui, 2: Add, Edit, x15  y190 w535 h140 vEditRecipeScript -Wrap ReadOnly, %SCRIPTVAR%
        
        Gui, 2: Font, , MS Sans SerIf
        
      Gui, 2: Tab, Components, , Exact
        Gui, 2: Add, Text, x15 y65, Test
        Gui, 2: Add, Edit, x55 y61, Components
      
      Gui, 2: Tab, Miscellaneous, , Exact
        Gui, 2: Add, Text, x15 y65, Test
        Gui, 2: Add, Edit, x55 y61, Miscellaneous
    
    WinGui2X := WinGui1X + WinGui1W + 15                                    ; show GUI 2
    WinGui2Y := WinGui1Y
    
    Gui, 2: Show
    Gui, 2: Show, autosize x%WinGui2X% y%WinGui2Y%, Edit Recipes
    
    WinSet, exstyle, -0x80000, Edit Recipes
    WinGet, EditWin
    Winset, Redraw
    
    PrintWorkbenchName = 
    PrintWorkbenchMenu = 
    PrintRecipesWithinWorkbench = 
    PrintActRecipeProduct = 
    PrintActRecipeProductTag = 
    PrintActRecipeWorkbenchName = 
    PrintActRecipeProductNbr = 
    SCRIPTVAR = 
  }
}
Return                                                                        ; <<<===  RecipeShow ending

RecipesWithinWorkbench:                                                       ; <<<===  RecipesWithinWorkbench begins
{
  Gui, 2: Submit, NoHide                                                      ; send variables to memory
  PrintActRecipeProduct := TrimToGetProduct(ActRecipeProduct)
  PrintActRecipeProductTag := TrimToGetTag(ActRecipeProduct)
  PrintActRecipeProductNbr := GetCreatedProductNbr(PrintActRecipeProductTag)
  NewRecipeWorkbench := GetWorkbenchName(PrintActRecipeProductTag)
  SCRIPTVAR := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
  
  If (DEBUG = 1)
    MsgBox, RecipesWithinWorkbench: %NewRecipeWorkbench%
  
  GuiControl,, EditRecipeProduct, %PrintActRecipeProduct%                     ; update necessary fields
  GuiControl,, EditRecipeProductTag, %PrintActRecipeProductTag%
  GuiControl,, EditRecipeProductNbr, %PrintActRecipeProductNbr%
  GuiControl,, EditRecipeScript, %SCRIPTVAR%
  
  GuiControl, ChooseString, EditWorkbenchMenu, %NewRecipeWorkbench%
  
  PrintActRecipeProduct = 
  PrintActRecipeProductTag = 
  PrintActRecipeProductNbr = 
  NewRecipeWorkbench = 
  SCRIPTVAR = 
}
Return                                                                        ; <<<===  RecipesWithinWorkbench ends

Options:
  MsgBox, Nothing to show at "Options"
Return

ShowAbout:
  ListVars
  ;MsgBox, Nothing to show at "About"
Return

;==================================================================================
;                                                Necessary funcs
; found on: https://autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/
;==================================================================================
WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 3000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

;================================================================================
;                                                Ending and closing the GUI's
;================================================================================



2GuiClose:
2GuiEscape:
  Gui, 2: Destroy
  EditWin = 
Return

; Ends app and destroys program
GuiClose:
  FileDelete, %TEMP_DIR%*.tmp
  ExitApp
