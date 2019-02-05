;================================================================================
;  CNR - Recipe-Script Editor
;  Author: Tobias Wirth (dunahan@schwerterkueste.de)
;================================================================================
; v0.8.0.1  now more fexibility is provided, but not all possibilities are shown.
; v0.8.0.2  static GUI for components and misc, reloads components
; v0.8.0.3  moving some code to funcs-file for readability, more viewing/saving for recipes, translating-files
;================================================================================
VERSION := "0.8.0.3"
;================================================================================

#NoTrayIcon
#NoEnv                                                                           ; For performance and combatibility with newer AHK versions
#SingleInstance force

#Include cnrse_funcs.ahk                                                         ; external funcitons, won't blow up main script and maintains readability

;==================================================================================
; As a reminder, the array-file holds of the following:
;  =>  M enues  (M|sMenuLevel5Scrolls)                                           => more than one possible
;  =>  N ame of the workbench (N|cnrScribeAverage)                               => sometimes there isn't one existent (as for cnrWaterTub.nss)
;  =>  R ecipes  (R|sMenuLevel5Scrolls|See Invisibility|NW_IT_SPARSCR205|1)      => as many recipes are provided in the recipe scripts
;  =>  another reminder, the function prints the product-tag from every recipe at the end of the following strings  <=
;  =>  Com P onents (P1|Blank Scroll|x2_it_cfm_bscrl|1)                          => more than one possible, number of components are at P<#>
;  =>  B iproducts (B1|hw_glassphio|1|1)                                         => if a recipe produces a leftover, these are biproducts (numbering same as products)
;  =>  L evel  (L|6)                                                             => the creation level required
;  =>  e X perience points (X|60|60)                                             => how many XP the PC gets (XP | CNR-XP)
;  =>  A ttributes  (A|0|0|0|50|50|0)                                            => which attributes are needed and at what percentage, MUST be in sum 100(%)!
;================================================================================

;================================================================================
;                                                Persistent Variables
;================================================================================
EXE := A_WorkingDir . "\cnrse.exe"
NAME := "CNR - Recipe-Script Editor"

;================================================================================
;                                                Main Scripts
;================================================================================

Main:                                                                            ; <<<===  Main begins
{
  GetConfig()
  GetLanguage()
  
  Menu, MyMenu, Add, %MenuOptions%, Options
  Menu, MyMenu, Add, %MenuShowAbout%, ShowAbout
  Gui, 1: Menu, MyMenu
  
  CountedRecipes := 0
  
  Loop, Files, %SCRIPT_DIR%cnr*.nss                                              ; go through all cnr*.nss scripts in folder. this is for testing yet. later it should extract it from mod
  {
    IfNotInString, A_LoopFileName, _
    {
      StringTrimRight, VarName, A_LoopFileName, 4
      Gui, 1: Add, Text, x%RecipeSpacerX%  y%RecipeSpacerY% w120 h20 v%VarName% cBlue gRecipeShow, %A_LoopFileName%
      
      IfNotInString, VarName, Chr(34)                                            ; add tooltip only when its possible?! why it's not working?
        %VarName%_TT = %OnToolTipMain%
      
      CountedRecipes := CountedRecipes + 1
      RecipeSpacerY := RecipeSpacerY + RecipeSpacerYAdd
      
      If (CountedRecipes > MaxRecipesPerRow)
      {
        RecipeSpacerX := RecipeSpacerX + RecipeSpacerXAdd
        IniRead, RecipeSpacerY, config.ini, Lists, RecipeSpacerY, 30             ; reload this value again...
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
  
  WinGet, MainWin, ID, %NAME%
  WinGetPos, WinGui1X, WinGui1Y, WinGui1W, WinGui1H, %NAME%                      ; save position of the main window, later interesting for more than one monitor
  
  RecipeSpacerX = 
  RecipeSpacerY = 
  MaxRecipesPerRow = 
  CountedRecipes = 
  
  RecipeSpacerXAdd = 
  RecipeSpacerYAdd = 
  
  OnMessage(0x200, "WM_MOUSEMOVE", 1)
  
  If (MOVE_WIN = 1)
  {
    Loop                                                                         ; was main moved, so move edit window too
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
Return                                                                           ; <<<===  Main ending

RecipeShow:                                                                      ; <<<===  RecipeShow begins
{
  GetLanguage()
  
  If A_GuiEvent = DoubleClick                                                    ; if user double clicks a script, editing begins
  {
    If (EditWin != "")                                                           ; bäh, you are editing one recipe already. don't open another one!
    {
      MsgBox, %OnRecipeIsEdited%
      Return
    }
    
    IfNotExist, %TEMP_DIR%
      FileCreateDir, %TEMP_DIR%
    Else
      FileDelete, %TEMP_DIR%*.tmp                                                ; first, delete all temporary files that where left over
    
    MouseGetPos, , , , RecipeScriptControl, 1                                    ; which script was clicked
    StringTrimLeft, StaticNbr, RecipeScriptControl, 6                            ; recieve that number
    ControlGetText, RecipeScript, %RecipeScriptControl%                          ; read the text of that control
    
    If (DEBUG = 1)
      MsgBox, Within RecipeShow`nMouseGetPos: %RecipeScriptControl%`nStringTrimLeft: %StaticNbr%`nControlGetText: %RecipeScript%
    
    If (RecipeScript = )                                                         ; the text of the control is missing, so is the script?
    {                                                                            ; tell the user that something went wrong...
      MsgBox, %OnRecipeIsMissing%
      Return
    }
    
    RecipeScriptPath = %SCRIPT_DIR%%RecipeScript%                                ; build the path and file in a seperate script
    RecipeScriptTemp = %TEMP_DIR%recipebook.tmp                                  ; this is the file where the script is copied to, so nothing could go wrong with the original
    FileCopy, %RecipeScriptPath%, %RecipeScriptTemp%, 1                          ; do the copy
    
    If (DEBUG = 1)
      MsgBox, Show path to file: %RecipeScriptPath%`nShow path to temp: %RecipeScriptTemp%
    
    ArrayTmpPath = %TEMP_DIR%array.tmp                                           ; this would be the array, where the translated script would be saved to
    CreateArrayTempFile(RecipeScriptTemp, ArrayTmpPath)                          ; create the file for saving the arrays to it, less memory using
    
    PrintWorkbenchName := ReturnWorkbenchFromRecipe(ArrayTmpPath)
    PrintWorkbenchMenu := ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
    PrintRecipesWithinWorkbench := ReturnRecipeListFromRecipe(ArrayTmpPath)
    
    If (DEBUG = 1)
      Gui, 2: Add, ListView, x6 y350 r20 c50 w550 h220 vListViewElement, ClassNN|HWND|Tab Control|Tab #|Text
    
    Gui, 2: Add, Text, x6   y8 w250 h21, %PrintWorkbenchName%                    ; build up GUI 2
    Gui, 2: Add, DDL,  x235 y5 w310 Sort vActRecipeProduct Choose1 gRecipesWithinWorkbench, %PrintRecipesWithinWorkbench%
    
    GoSub, BuildUpCompAndMisc
    
    Gui, 2: +owner1
    Gui, 2: +ToolWindow
    Gui, 2: +LastFound
    hGui2 := WinExist()
    
    WinGui2X := WinGui1X + WinGui1W + 15                                         ; show GUI 2
    WinGui2Y := WinGui1Y
    
    Gui, 2: Show
    Gui, 2: Show, x%WinGui2X% y%WinGui2Y% autosize, Edit Recipes
    
    WinSet, exstyle, -0x80000, Edit Recipes
    WinGet, EditWin
    Winset, Redraw
    
    PrintWorkbenchName = 
    PrintWorkbenchMenu = 
    PrintRecipesWithinWorkbench = 
  }
}
Return                                                                           ; <<<===  RecipeShow ending

BuildUpCompAndMisc:
{
  GetLanguage()
  
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
  
  Gui, 2: Add, Tab2, x6 y35 w550 h300                           gEditRecipeTab, %Tab2RecipePure%|%Tab2ComBiPEdit%|%Tab2MiscEditor%
  {
    Gui, 2: Tab, %Tab2RecipePure%, , Exact
    {
      Gui, 2: Add, Text, x15  y65  w100 h21                                   , %Tab2RecipWorkb%:
      Gui, 2: Add, Edit, x105 y61  w250      vEditWorkbenchName -Wrap ReadOnly, %PrintWorkbenchName%
      Gui, 2: Add, Text, x15  y90  w100 h21                                   , %Tab2RecipWbMen%:
      Gui, 2: Add, DDL,  x105 y86  w250      vEditWorkbenchMenu     Choose%Me%, %PrintWorkbenchMenu%
      Gui, 2: Add, Text, x15  y115 w100 h21                                   , %Tab2RecipProdN%:
      Gui, 2: Add, Edit, x105 y111 w250      vEditRecipeProduct       ReadOnly, %PrintActRecipeProduct%
      Gui, 2: Add, Text, x15  y140 w100 h21                                   , %Tab2RecipProdT%:
      Gui, 2: Add, Edit, x105 y136 w250      vEditRecipeProductTag    ReadOnly, %PrintActRecipeProductTag%
      Gui, 2: Add, Text, x15  y165 w100 h21                                   , %Tab2RecipPrNbr%:
      Gui, 2: Add, Edit, x105 y161 w250      vEditRecipeProductNbr    ReadOnly, %PrintActRecipeProductNbr%
      
      Gui, 2: Font, , Courier new
      SCRIPTVAR := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
      
      Gui, 2: Add, Edit, x15  y190 w535 h140 vEditRecipeScript -Wrap ReadOnly, %SCRIPTVAR%
      
      Gui, 2: Font, , MS Sans SerIf
    }
    
    Gui, 2: Tab, %Tab2ComBiPEdit%, , Exact
    {
      ComponentsToShow := CompToArray(PrintActRecipeProductTag)
      BiProductsToShow := BiProdToArray(PrintActRecipeProductTag)
      
      xa := 15
      ya := 65
      xb := 100
      yb := 61
      xc := 360
      yc := 61
      xd := 420
      yd := 61
      xe := 490
      ye := 65
      cl := 5
      
      Loop, Parse, ComponentsToShow, |
      {
        If (A_LoopField != "")
        {
          isSpell := 0
          
          ComponentArray := ReturnPlaceComponent(A_LoopField)
          ComponentArray := StrSplit(ComponentArray, "|")
          
          IfInString, A_LoopField, CNR_RECIPE_SPELL
          {
            PlaceComponent := ComponentArray[3]
            NbrCA := ComponentArray[2]
            isSpell := 1
          }
          Else
          {
            PlaceComponent := ComponentArray[1]
            NbrCa := ComponentArray[2]
            NbrCb := ComponentArray[3]
            
            If (NbrCb = 0)
              NbrCb = 
          }
          
          Gui, 2: Add, Text,     x%xa% y%ya% w90                                , %Tab2ComBiPEdCo% #%A_Index%:
          Gui, 2: Add, Edit,     x%xb% y%yb% w250 vCA#%A_Index%                 , %PlaceComponent%
          Gui, 2: Add, Edit,     x%xc% y%yc% w50  vCB#%A_Index%                 , %NbrCa%
          Gui, 2: Add, Edit,     x%xd% y%yd% w50  vCC#%A_Index%                 , %NbrCb%
          Gui, 2: Add, Checkbox, x%xe% y%ye%      vCD#%A_Index% Checked%isSpell%, %Tab2ComBiPEdiS%
          
          ya := ya + 25
          yb := yb + 25
          yc := yc + 25
          yd := yd + 25
          ye := ye + 25
          
          cl := cl - 1
        }
      }
      
      fx := 5 - cl
      Loop, %cl%
      {
        nbr := fx + A_Index
        
        Gui, 2: Add, Text,     x%xa% y%ya% w90           , %Tab2ComBiPEdCo% #%nbr%:
        Gui, 2: Add, Edit,     x%xb% y%yb% w250 vCA#%nbr%, 
        Gui, 2: Add, Edit,     x%xc% y%yc% w50  vCB#%nbr%, 
        Gui, 2: Add, Edit,     x%xd% y%yd% w50  vCC#%nbr%, 
        Gui, 2: Add, Checkbox, x%xe% y%ye%      vCD#%nbr%, %Tab2ComBiPEdiS%
        
        ya := ya + 25
        yb := yb + 25
        yc := yc + 25
        yd := yd + 25
        ye := ye + 25
      }
      
      yf := ya + 15
      yg := yb + 15
      yh := yc + 15
      yi := yd + 15
      cl := 5
      bp := 0
      
      If (BiProductsToShow != "")
      {
        Loop, Parse, BiProductsToShow, |
        {
          If (A_LoopField != "")
          {
            BiProductArray := ReturnPlaceBiProduct(A_LoopField)
            BiProductArray := StrSplit(BiProductArray, "|")
            
            PlaceBiProduct := BiProductArray[1]
            NbrBa := BiProductArray[2]
            NbrBb := BiProductArray[3]
            
            Gui, 2: Add, Text, x%xa% y%yf% w90               , %Tab2ComBiPEdBi% #%A_Index%:
            Gui, 2: Add, Edit, x%xb% y%yg% w250 vBA#%A_Index%, %PlaceBiProduct%
            Gui, 2: Add, Edit, x%xc% y%yh% w50  vBB#%A_Index%, %NbrBa%
            Gui, 2: Add, Edit, x%xd% y%yi% w50  vBC#%A_Index%, %NbrBb%
            
            yf := yf + 25
            yg := yg + 25
            yh := yh + 25
            yi := yi + 25
            
            cl := cl - 1
          }
        }
      }
      
      fx := 5 - cl
      Loop, %cl%
      {
        nbr := fx + A_Index
        
        Gui, 2: Add, Text, x%xa% y%yf% w90           , %Tab2ComBiPEdBi% #%nbr%:
        Gui, 2: Add, Edit, x%xb% y%yg% w250 vBA#%nbr%, 
        Gui, 2: Add, Edit, x%xc% y%yh% w50  vBB#%nbr%, 
        Gui, 2: Add, Edit, x%xd% y%yi% w50  vBC#%nbr%, 
        
        yf := yf + 25
        yg := yg + 25
        yh := yh + 25
        yi := yi + 25
      }
      
      xd := xd + 60
      yi := yi - 26
      Gui, 2: Add, Button, x%xd% y%yi% gSave Default, %Tab2ComBiPSave%
    }  
    
    Gui, 2: Tab, %Tab2MiscEditor%, , Exact
    {
      Gui, 2: Add, Text, x15 y65, Test
      Gui, 2: Add, Edit, x55 y61, Miscellaneous
    }
  }
  
  ActRecipeProduct = 
  PrintActRecipeProduct = 
  PrintActRecipeProductTag = 
  PrintActRecipeWorkbenchName = 
  PrintActRecipeProductNbr = 
  SCRIPTVAR = 
  
  ComponentsToShow = 
  ComponentArray = 
  CompNbr = 
  Count = 
  PlaceComponent = 
  isSpell = 
  BiProductsToShow = 
  BiProductArray = 
  BiPrNbr = 
  PlaceBiProduct = 
  NbrCA = 
  NbrCB = 
  NbrBa = 
  NbrBb = 
  
  xa = 
  ya = 
  xb = 
  yb = 
  xc = 
  yc = 
  xd = 
  yd = 
  xe = 
  ye = 
  yf = 
  yg = 
  yh = 
  yi = 
}
Return

RecipesWithinWorkbench:                                                          ; <<<===  RecipesWithinWorkbench begins
{
  GetLanguage()
  
  Gui, 2: Submit, NoHide                                                         ; send variables to memory
  
  PrintActRecipeProduct := TrimToGetProduct(ActRecipeProduct)
  PrintActRecipeProductTag := TrimToGetTag(ActRecipeProduct)
  PrintActRecipeProductNbr := GetCreatedProductNbr(PrintActRecipeProductTag)
  NewRecipeWorkbench := GetWorkbenchName(PrintActRecipeProductTag)
  SCRIPTVAR := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
  
  ComponentsToShow := CompToArray(PrintActRecipeProductTag)
  BiProductsToShow := BiProdToArray(PrintActRecipeProductTag)
  StringReplace, ComponentsToShow, ComponentsToShow, |, |, UseErrorLevel
  cl := 5-ErrorLevel
  StringReplace, BiProductsToShow, BiProductsToShow, |, |, UseErrorLevel
  bl := 5-ErrorLevel
  
  If (DEBUG = 1)
    MsgBox, RecipesWithinWorkbench: %NewRecipeWorkbench%
  
  GuiControl,, EditRecipeProduct, %PrintActRecipeProduct%                        ; update necessary fields
  GuiControl,, EditRecipeProductTag, %PrintActRecipeProductTag%
  GuiControl,, EditRecipeProductNbr, %PrintActRecipeProductNbr%
  GuiControl,, EditRecipeScript, %SCRIPTVAR%
  
  GuiControl, ChooseString, EditWorkbenchMenu, %NewRecipeWorkbench%
  
  Loop, 5                                                                        ; empty me first!
  {
    GuiControl,, CA#%A_Index%, 
    GuiControl,, CB#%A_Index%, 
    GuiControl,, CC#%A_Index%, 
    GuiControl,, CD#%A_Index%, %Tab2ComBiPEdiS%
    
    GuiControl,, BA#%A_Index%, 
    GuiControl,, BB#%A_Index%, 
    GuiControl,, BC#%A_Index%, 
  }
  
  Loop, Parse, ComponentsToShow, |
  {
    If (A_LoopField != "")
    {
      isSpell := 0
      
      ComponentArray := ReturnPlaceComponent(A_LoopField)
      ComponentArray := StrSplit(ComponentArray, "|")
      
      IfInString, A_LoopField, CNR_RECIPE_SPELL
      {
        PlaceComponent := ComponentArray[3]
        NbrCA := ComponentArray[2]
        isSpell := 1
      }
      Else
      {
        PlaceComponent := ComponentArray[1]
        NbrCa := ComponentArray[2]
        NbrCb := ComponentArray[3]
        
        If (NbrCb = 0)
          NbrCb = 
      }
      
      GuiControl,, CA#%A_Index%, %PlaceComponent%
      GuiControl,, CB#%A_Index%, %NbrCa%
      GuiControl,, CC#%A_Index%, %NbrCb%
      GuiControl,, CD#%A_Index%, %isSpell%
    }
  }
  
  If (BiProductsToShow != "")
  {
    Loop, Parse, BiProductsToShow, |
    {
      If (A_LoopField != "")
      {
        BiProductArray := ReturnPlaceBiProduct(A_LoopField)
        BiProductArray := StrSplit(BiProductArray, "|")
        
        PlaceBiProduct := BiProductArray[1]
        NbrBa := BiProductArray[2]
        NbrBb := BiProductArray[3]
        
        
        GuiControl,, BA#%A_Index%, %PlaceBiProduct%
        GuiControl,, BB#%A_Index%, %NbrBa%
        GuiControl,, BC#%A_Index%, %NbrBb%
      }
    }
  }
  PrintActRecipeProduct = 
  PrintActRecipeProductTag = 
  PrintActRecipeProductNbr = 
  NewRecipeWorkbench = 
  SCRIPTVAR = 
  
  ComponentsToShow = 
  ComponentArray = 
  CompNbr = 
  Count = 
  PlaceComponent = 
  isSpell = 
  BiProductsToShow = 
  BiProductArray = 
  BiPrNbr = 
  PlaceBiProduct = 
  NbrCA = 
  NbrCB = 
  NbrBa = 
  NbrBb = 
}
Return                                                                           ; <<<===  RecipesWithinWorkbench ends

Save:
  SomethingChanged := 0                                                          ; assume at first, nothing was changed
  Gui, 2: Submit, NoHide                                                         ; send variables to memory
  
  original := EditRecipeProductTag
  changed  := CreateChangedRecipeVersion()
  result   := ReturnWasSomethingChanged(original, changed)
  
  If (DEBUG = 1)
  {
    cti := TurnToArray( CompToArray(original) ) TurnToArray( BiProdToArray(original) )
    MsgBox, Original recipe: %cti%`nChanged recipe: %changed%`n`nThere have been %result% changes.
  }
Return

EditRecipeTab:
  ;MsgBox, %OnNothingToShow%
Return

Options:
  MsgBox, %OnNothingToShow%
Return

ShowAbout:
  ListVars
  ;MsgBox, %OnNothingToShow%
Return


;==================================================================================
;                                                Necessary funcs
; found on: https://autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/
;==================================================================================
WM_MOUSEMOVE()
{
    MouseGetPos, , , ActWindow
    WinGet, MainWin, ID, "CNR - Recipe-Script Editor"
    
;    If (%ActWindow% != %MainWin%)
;      return
    
    static CurrControl, PrevControl, _TT                                         ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    
    CurrControl := RemoveUnessesaries(CurrControl)
    
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
      ToolTip                                                                    ; Turn off any previous tooltip.
      SetTimer, DisplayToolTip, 1000
      PrevControl := CurrControl
    }
    return

    DisplayToolTip:
      SetTimer, DisplayToolTip, Off
      ToolTip % %CurrControl%_TT                                                 ; The leading percent sign tell it to use an expression.
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
  RecipeTagTabBuilded = 0
Return

; Ends app and destroys program
GuiClose:
  FileDelete, %TEMP_DIR%*.tmp
  ExitApp