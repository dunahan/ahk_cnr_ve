;================================================================================
;  CNR - Recipe-Script Editor
;  Author: Tobias Wirth (dunahan@schwerterkueste.de)
;================================================================================
; v0.8
; aktuell ein kleiner viewer (comments in german)
;================================================================================
VERSION := "0.8"
;================================================================================

#NoTrayIcon
#NoEnv                                                                        ; Fuer Geschwindigkeit, Funktionalitaet mit neueren AHK Versionen
#SingleInstance force

#Include cnrse_funcs.ahk

;==================================================================================
; Erinnerung:
; Der Array besteht ueblicherweise aus:
;  =>  M enues  (M|sMenuLevel5Scrolls)
;  =>  N ame der Workbench  (N|cnrScribeAverage)
;  =>  R ezept  (R|sMenuLevel5Scrolls|oO-No Item found-Oo|X1_IT_SPARSCR502|1)
;  =>  Kom P onenten (1|Blank Scroll|x2_it_cfm_bscrl|1)  mehrfache moegliche
;  =>  a B fallprodukten (B1|hw_glassphio|1|1) mehrfache moeglich
;  =>  L evel  L|6)
;  =>  e X perience Punkte (X|60|60)
;  =>  A ttribute  (A|0|0|0|50|50|0)
;================================================================================

;================================================================================
;                                                Persistent Variablen
;================================================================================
EXE := A_WorkingDir . "\cnrse.exe"
NAME := "CNR - Recipe-Script Editor"
IniRead, SCRIPT_DIR, config.ini, Default, SCRIPT_DIR, %A_WorkingDir%\mod\     ; fuer den ersten Run, spaeter weitere Pfade machbar machen!
IniRead, TEMP_DIR, config.ini, Default, TEMP_DIR, %A_WorkingDir%\tmp\         ; temporaerer Ordner
IniRead, ITM_FILE, config.ini, Default, ITM_FILE, %A_WorkingDir%\items.csv    ; hier eine csv-Datei mit den ResRefs/Tags und Namen der Items
IniRead, MOVE_WIN, config.ini, Default, MOVE_WIN, 1                           ; hiermit wird das rezeptwindow mit bewegt oder nicht?
IniRead, DEBUG, config.ini, Default, DEBUG, 0                                 ; DebugMode 1 / 0

;================================================================================
;                                                Main Scripts
;================================================================================

Main:                                                                         ; <<<===  Main beginnt
{
  Menu, MyMenu, Add, Options, Options                                         ; Menu aufbauen
  Menu, MyMenu, Add, ShowAbout, ShowAbout
  Gui, 1: Menu, MyMenu
  
  IniRead, RecipeSpacerX, config.ini, Lists, RecipeSpacerX, 10                ; Definitionen fuer die Rezepte-Uebersicht laden
  IniRead, RecipeSpacerY, config.ini, Lists, RecipeSpacerY, 30                ; evtl. spaeter noch definierbarer
  IniRead, MaxRecipesPerRow, config.ini, Lists, MaxRecipesPerRow, 9
  CountedRecipes := 0
  
  IniRead, RecipeSpacerXAdd, config.ini, Lists, RecipeSpacerXAdd, 120
  IniRead, RecipeSpacerYAdd, config.ini, Lists, RecipeSpacerYAdd, 25
  
  Loop, Files, %SCRIPT_DIR%cnr*.nss                                           ; lese die Namen der CNR-Skripte ein und baue die Liste auf
  {
    IfNotInString, A_LoopFileName, _
    {
      StringTrimRight, VarName, A_LoopFileName, 4
      Gui, 1: Add, Text, x%RecipeSpacerX%  y%RecipeSpacerY% w120 h20 v%VarName% cBlue gRecipeShow, %A_LoopFileName%
      %VarName%_TT := "Doppelklick um Bearbeitung zu starten"
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
  
  hGui1 := WinExist()
  Gui, 1: Font, c000000 9, MS Sans SerIf
  Gui, 1: +E0x80000000
  
  Gui, 1: Show
  Gui, 1: Show, center autosize, %NAME%
  WinSet, exstyle, -0x80000, %NAME%
  
  OnMessage(0x200, "WM_MOUSEMOVE")
  
  WinGet, MainWin
  WinGetPos, WinGui1X, WinGui1Y, WinGui1W, WinGui1H, %NAME%                 ; Position Mainwindow speichern, nuetzlich fuer mehrere Bildschirme

  If (MOVE_WIN = 1)
  {
    Loop                                                                      ; Wurde das Fenster bewegt, bewege das zweite Fenster auch
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
Return                                                                        ; <<<===  Main endet

RecipeShow:                                                                   ; <<<===  RecipeShow beginnt
{
  If A_GuiEvent = DoubleClick
  {
    If (EditWin != "")
    {
      MsgBox, %EditWin%`nEs wird bereits ein Rezept bearbeitet
      Return
    }
    
    FileDelete, %TEMP_DIR%*.tmp                                             ; loesche temporaere Dateien, die vorher angelegt waren
    
    MouseGetPos, , , , RecipeScriptControl, 1                               ; welches Rezept wurde angeklickt?
    StringTrimLeft, StaticNbr, RecipeScriptControl, 6                       ; was fuer eine Nummer hat dies?
    ControlGetText, RecipeScript, %RecipeScriptControl%                     ; lese den Text dieses Objekts aus!
    
    If (DEBUG = 1)
      MsgBox, Within RecipeShow`nMouseGetPos: %RecipeScriptControl%`nStringTrimLeft: %StaticNbr%`nControlGetText: %RecipeScript%
    
    If (RecipeScript = )                                                    ; okay hier lief was schief beim oeffnen des Skripts
    {
      MsgBox, Something went wrong
      Return                                                                ; gibt bescheid und brich hier ab.
    }
    
    RecipeScriptPath = %SCRIPT_DIR%%RecipeScript%
    RecipeScriptTemp = %TEMP_DIR%recipebook.tmp
    FileCopy, %RecipeScriptPath%, %RecipeScriptTemp%, 1                     ; kopiere  es und veraendere das Ende zu*.txt 
    
    If (DEBUG = 1)
      MsgBox, Show path to file: %RecipeScriptPath%`nShow path to temp: %RecipeScriptTemp%
    
    ArrayTmpPath = %TEMP_DIR%array.tmp
    CreateArrayTempFile(RecipeScriptTemp, ArrayTmpPath)                     ; erstelle eine temoraere Datei um die Arrays weniger speicherintensiv erreichbar zu halten
    
    Gui, 2: +owner1
    Gui, 2: +ToolWindow
    Gui, 2: +LastFound
    hGui2 := WinExist()
    
    PrintWorkbenchName := ReturnWorkbenchFromRecipe(ArrayTmpPath)
    PrintWorkbenchMenu := ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
    PrintRecipesWithinWorkbench := ReturnRecipeListFromRecipe(ArrayTmpPath)
    
    Gui, 2: Add, Text, x6 y8 w90 h21, %PrintWorkbenchName%                                                  ; Baue die GUI 2 auf
    Gui, 2: Add, DDL, x100 y4 w350 Sort vActRecipeProduct Choose1 gRecipesWithinWorkbench, %PrintRecipesWithinWorkbench%
    
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
    
    Gui, 2: Add, Tab2, x6 y35 w550 h300, RecipeTag|Components|Miscellaneous                                 ; baue den Inhalt auf
      Gui, 2: Tab, RecipeTag, , Exact
        Gui, 2: Add, Text, x15  y65  w100 h21                                  , Workbench:
        Gui, 2: Add, Edit, x105 y61  w200      vEditWorkbenchName      ReadOnly, %PrintWorkbenchName%
        Gui, 2: Add, Text, x15  y90  w100 h21                                  , WorkbenchMenu:
        Gui, 2: Add, DDL,  x105 y86  w200      vEditWorkbenchMenu    Choose%Me%, %PrintWorkbenchMenu%
        Gui, 2: Add, Text, x15  y115 w100 h21                                  , ProductName:
        Gui, 2: Add, Edit, x105 y111 w200      vEditRecipeProduct      ReadOnly, %PrintActRecipeProduct%
        Gui, 2: Add, Text, x15  y140 w100 h21                                  , ProductTag:
        Gui, 2: Add, Edit, x105 y136 w200      vEditRecipeProductTag   ReadOnly, %PrintActRecipeProductTag%
        Gui, 2: Add, Text, x15  y165 w100 h21                                  , ProductNbr:
        Gui, 2: Add, Edit, x105 y161 w200      vEditRecipeProductNbr   ReadOnly, %PrintActRecipeProductNbr%
        
        ; skript beispiel einfuegen?!
        Gui, 2: Font, , Courier new
        SCRIPTVAR = sKeyToRecipe = CnrRecipeCreateRecipe("%PrintActRecipeProduct%", "%PrintActRecipeProductTag%", %PrintActRecipeProductNbr%);`n
        
        SCRIPTVAR = %SCRIPTVAR%               CnrRecipeAddComponent(sKeyToRecipe, "hw_resiron", 2, 1);`n                                                      ;loop notwendig
        
        SCRIPTVAR = %SCRIPTVAR%               CnrRecipeSetRecipeLevel(sKeyToRecipe, 2);`n                                                                                    ;muss ich noch einbauen
        
          ;Bi-Product Loop einfuegen?!
        
        SCRIPTVAR = %SCRIPTVAR%               CnrRecipeSetRecipeXP(sKeyToRecipe, 30, 30);`n                                                                                ;einfach reicht
        SCRIPTVAR = %SCRIPTVAR%               CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, 70, 30, 0, 0, 0, 0);`n                        ;
          ;sKeyToRecipe = CnrRecipeCreateRecipe(sMenuHelme, GetObjectName("hw_arhe001"), "hw_arhe001", 1);
          ;               CnrRecipeAddComponent(sKeyToRecipe, "hw_resiron", 2, 1);
          ;               CnrRecipeAddComponent(sKeyToRecipe, "NW_ARHE001", 1, 1);
          ;               CnrRecipeSetRecipeLevel(sKeyToRecipe, 2);
          ;               CnrRecipeSetRecipeXP(sKeyToRecipe, 30, 30);
          ;               CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, 70, 30, 0, 0, 0, 0);
          
          ; R|sMenuHelme|GetObjectName(hw_arhe001)|hw_arhe001|1  
          ; P1|hw_arhe001|hw_resiron|2|1
          ; P2|hw_arhe001|NW_ARHE001|1|1
          ; X|hw_arhe001|30|30
          ; A|hw_arhe001|70|30|0|0|0|0
        
        Gui, 2: Add, Edit, x15  y190 w535 h140 vEditRecipeScript -Wrap ReadOnly, %SCRIPTVAR%
        
        Gui, 2: Font, , MS Sans SerIf
        
      Gui, 2: Tab, Components, , Exact
        Gui, 2: Add, Text, x15 y65, Test
        Gui, 2: Add, Edit, x55 y61, Components
      
      Gui, 2: Tab, Miscellaneous, , Exact
        Gui, 2: Add, Text, x15 y65, Test
        Gui, 2: Add, Edit, x55 y61, Miscellaneous
    
    WinGui2X := WinGui1X + WinGui1W + 15                                    ; zeige gui 2
    WinGui2Y := WinGui1Y
    
    Gui, 2: Show
    Gui, 2: Show, autosize x%WinGui2X% y%WinGui2Y%, Edit Recipes
    
    WinSet, exstyle, -0x80000, Edit Recipes
    WinGet, EditWin
    Winset, Redraw
  }
}
Return                                                                        ; <<<===  RecipeShow endet

RecipesWithinWorkbench:                                                       ; <<<===  RecipesWithinWorkbench beginnt
  Gui, 2: Submit, NoHide                                                      ; uebermittle Variablen
  PrintActRecipeProduct := TrimToGetProduct(ActRecipeProduct)
  PrintActRecipeProductTag := TrimToGetTag(ActRecipeProduct)
  PrintActRecipeProductNbr := GetCreatedProductNbr(PrintActRecipeProductTag)
  NewRecipeWorkbench := GetWorkbenchName(PrintActRecipeProductTag)
  
  If (DEBUG = 1)
    MsgBox, RecipesWithinWorkbench: %NewRecipeWorkbench%
  
  GuiControl,, EditRecipeProduct, %PrintActRecipeProduct%                     ; Aktualisiere die notwendigen Anzeigen
  GuiControl,, EditRecipeProductTag, %PrintActRecipeProductTag%
  GuiControl,, EditRecipeProductNbr, %PrintActRecipeProductNbr%
  
  GuiControl, ChooseString, EditWorkbenchMenu, %NewRecipeWorkbench%
Return                                                                        ; <<<===  RecipesWithinWorkbench beginnt

Options:
  MsgBox, Nothing here; Options
Return

ShowAbout:
  MsgBox, Nothing here; ShowAbout
Return

;==================================================================================
;                                                Benoetigte Funktionen
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
;                                                Ende
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
