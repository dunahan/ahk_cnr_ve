;================================================================================
;  CNR - Recipe-Script Editor
;  Author: Tobias Wirth (dunahan@schwerterkueste.de)
;================================================================================
; v0.8.0.5  save func now builds up full script snippet, added the ability per right mouse to edit the nss directly
; v0.8.0.6  some code corrections and more things to do... trying to add erf-reader without third party tools
; v0.8.0.7  adding third party tools for erf extraction/creation by niv at github.com (neverwinter.nim)
;================================================================================
VERSION := "0.8.0.7"
;================================================================================

#NoTrayIcon
#NoEnv                                                                           ; For performance and combatibility with newer AHK versions
#SingleInstance force

#Include cnrse_funcs.ahk                                                         ; external funcitons, won't blow up main script and maintains readability

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
  
  Gui, 1: Add, Button, x6   y4   w75           gOpenErf             , %OnButtonOpenErf%
  Gui, 1: Add, Button, x81  y4   w75           gNewRecipe           , %NewRecipeButton%
  Gui, 1: Add, DDL,    x156 y5   w75 AltSubmit gSaveVariant vSaveVar, %SaveVariantText%
  
  CountedRecipes := 0
  
  If !FileExist(SCRIPT_DIR)
    MsgBox, %OnNoRecipeHere% %SCRIPT_DIR%.
  
  Loop, Files, %SCRIPT_DIR%cnr*.nss                                              ; go through all cnr*.nss scripts in folder. this is for testing yet. later it should extract it from mod
  {
    IfNotInString, A_LoopFileName, _
    {
      StringTrimRight, VarName, A_LoopFileName, 4
      Gui, 1: Add, Text, x%RecipeSpacerX%  y%RecipeSpacerY% w120 h20 v%VarName% cBlue gRecipeShow, %A_LoopFileName%
      
      IfNotInString, VarName, Chr(34)                                            ; add tooltip only if its possible
        %VarName%_TT = %OnToolTipMain1%`n%OnToolTipMain2%
      
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

SaveVariant:
{
  GetLanguage()
  Gui, 1: Submit, NoHide
  
  IniRead, SVT, language.ini, %LANG%, SaveVariantText, Save|Copy|User
  StringReplace, SVT, SVT, ||, |, ALL
  
  SVTA := StrSplit(SVT, "|")
  SVTS := SVTA[ SaveVar ]
  
  SaveC := SVTS           ; Button6
  SaveM := SVTS           ; Button7
  
  ControlGetText, HWNDSaveC, Button6
  ControlGetText, HWNDSaveM, Button7
  
  ;If (DEBUG = 1)
    MsgBox, Choosen Item: %SaveVar%`nArray to Parse: %SVT%`nString found: %SVTS%`nCompBut: %SaveC%/%HWNDSaveC%`nMiscBut: %SaveM%/%HWNDSaveM%
  
  SVT = 
  SVTA = 
  SVTS = 
}
Return

~RButton::                                                                       ; <<<===  use of right Mouse button
{
  IniRead, FAV, config.ini, Other, FAV, Notepad.exe
  
  MouseGetPos, , , MainWinID
  If (MainWinID == MainWin)
  {
    MouseGetPos, , , , Ctrl
    
    If InStr(Ctrl, "Static")                                                     ; open only if it's a script
    {
      ControlGetText, RecipeToEdit, %Ctrl%, %NAME%
      
      If (DEBUG = 1)
        MsgBox, % "Control " Ctrl "`nRecipe " RecipeToEdit "`n" SCRIPT_DIR "`n" FAV
      
      Run %FAV% %SCRIPT_DIR%%RecipeToEdit%
    }
  }
}
Return                                                                           ; <<<===  use of right Mouse button

RecipeShow:                                                                      ; <<<===  RecipeShow begins
{
  GetLanguage()
  
  If A_GuiControlEvent = DoubleClick                                             ; if user double clicks a script, editing begins
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
    
    PrintWorkbenchName          := ReturnWorkbenchFromRecipe(ArrayTmpPath)
    PrintWorkbenchMenu          := ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
    PrintRecipesWithinWorkbench := ReturnRecipeListFromRecipe(ArrayTmpPath)
    
    If (PrintWorkbenchName == "")
      PrintWorkbenchName := RecipeScript
    
    If (DEBUG = 1)
      Gui, 2: Add, ListView, x6 y350 r20 c50 w550 h220 vListViewElement, ClassNN|HWND|Tab Control|Tab #|Text
    
    Gui, 2: Add, Text, x6   y8 w250 h21, %PrintWorkbenchName%                    ; build up GUI 2
    Gui, 2: Add, DDL,  x235 y5 w310 Sort vActRecipeProduct Choose1 gRecipesWithinWorkbench, %PrintRecipesWithinWorkbench%
      ActRecipeProduct_TT = Changed data will be erased if you change the recipe without using the <Save button>
    
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

BuildUpCompAndMisc:                                                              ; <<<===  Build up contents begins
{
  GetLanguage()
  
  Gui, 2: Submit, NoHide
  
  PrintActRecipeProduct       := TrimToGetProduct(ActRecipeProduct)
  PrintActRecipeProductTag    := TrimToGetTag(ActRecipeProduct)
  PrintActRecipeWorkbenchName := GetWorkbenchName(PrintActRecipeProductTag)
  PrintActRecipeProductNbr    := GetCreatedProductNbr(PrintActRecipeProductTag)
  
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
      Gui, 2: Add, Edit, x105 y61  w250      vShowWorkbenchName -Wrap ReadOnly, %PrintWorkbenchName%
      Gui, 2: Add, Text, x15  y90  w100 h21                                   , %Tab2RecipWbMen%:
      Gui, 2: Add, DDL,  x105 y86  w250      vShowWorkbenchMenu     Choose%Me%, %PrintWorkbenchMenu%
      Gui, 2: Add, Text, x15  y115 w100 h21                                   , %Tab2RecipProdN%:
      Gui, 2: Add, Edit, x105 y111 w250      vShowRecipeProduct       ReadOnly, %PrintActRecipeProduct%
      Gui, 2: Add, Text, x15  y140 w100 h21                                   , %Tab2RecipProdT%:
      Gui, 2: Add, Edit, x105 y136 w250      vShowRecipeProductTag    ReadOnly, %PrintActRecipeProductTag%
      Gui, 2: Add, Text, x15  y165 w100 h21                                   , %Tab2RecipPrNbr%:
      Gui, 2: Add, Edit, x105 y161 w250      vShowRecipeProductNbr    ReadOnly, %PrintActRecipeProductNbr%
      
      Gui, 2: Font, , Courier new
      SCRIPTVAR := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
      
      Gui, 2: Add, Edit, x15  y190 w535 h140 vShowRecipeScript -Wrap ReadOnly, %SCRIPTVAR%
      
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
      Gui, 2: Add, Button, x%xd% y%yi% Default gSave vSaveC , Save
    }
    
    Gui, 2: Tab, %Tab2MiscEditor%, , Exact
    {
      Gui, 2: Add, Text, x15  y65  w100 h21                                   , %Tab2RecipWorkb%:
      Gui, 2: Add, Edit, x105 y61  w250      vEditWorkbenchName -Wrap ReadOnly, %PrintWorkbenchName%
      Gui, 2: Add, Text, x15  y90  w100 h21                                   , %Tab2RecipWbMen%:
      Gui, 2: Add, DDL,  x105 y86  w250      vEditWorkbenchMenu     Choose%Me%, %PrintWorkbenchMenu%
      Gui, 2: Add, Text, x15  y115 w100 h21                                   , %Tab2RecipProdN%:
      Gui, 2: Add, Edit, x105 y111 w250      vEditRecipeProduct               , %PrintActRecipeProduct%
      Gui, 2: Add, Text, x15  y140 w100 h21                                   , %Tab2RecipProdT%:
      Gui, 2: Add, Edit, x105 y136 w124      vEditRecipeProductTag            , %PrintActRecipeProductTag%
      Gui, 2: Add, Text, x233 y140 w100 h21                                   , %Tab2RecipPrNbr%:
      Gui, 2: Add, Edit, x316 y136 w40       vEditRecipeProductNbr            , %PrintActRecipeProductNbr%
      
      Gui, 2: Add, Text, x15  y165 w100 h21                                   , %Tab2MiscLevel%:
      Gui, 2: Add, Edit, x105 y161 w40       vEditRecipeLevel                 , % ReturnLevelFromRecipe(PrintActRecipeProductTag)
      
      XPArray := StrSplit(ReturnXPFromRecipe(PrintActRecipeProductTag), "|")
      Gui, 2: Add, Text, x155 y165 w100 h21                                   , %Tab2MiscXPaCXP%:
      Gui, 2: Add, Edit, x273 y161 w40       vEditRecipeXP                    , % XPArray[ 1 ]
      Gui, 2: Add, Edit, x316 y161 w40       vEditRecipeCnrXP                 , % XPArray[ 2 ]
      
      AbsArray := StrSplit(ReturnAbilitysFromRecipe(PrintActRecipeProductTag), "|")  ; create the Ability Array
      Gui, 2: Add, Text, x15  y190 w100 h21                                   , %Tab2MiscAbilit%:
      Gui, 2: Add, Edit, x105 y186 w40       vEditRecipeAbilityStr   gCheckAbs, % AbsArray[ 1 ]
      Gui, 2: Add, Edit, x147 y186 w40       vEditRecipeAbilityDex   gCheckAbs, % AbsArray[ 2 ]
      Gui, 2: Add, Edit, x189 y186 w40       vEditRecipeAbilityCon   gCheckAbs, % AbsArray[ 3 ]
      Gui, 2: Add, Edit, x231 y186 w40       vEditRecipeAbilityInt   gCheckAbs, % AbsArray[ 4 ]
      Gui, 2: Add, Edit, x273 y186 w40       vEditRecipeAbilityWis   gCheckAbs, % AbsArray[ 5 ]
      Gui, 2: Add, Edit, x316 y186 w40       vEditRecipeAbilityCha   gCheckAbs, % AbsArray[ 6 ]
      Gui, 2: Add, Edit, x359 y186 w40       vShowRecipeAbilitySum    ReadOnly, 
      
      EditRecipeAbilityStr_TT = %Tab2MiscAbStr%
      EditRecipeAbilityDex_TT = %Tab2MiscAbDex%
      EditRecipeAbilityCon_TT = %Tab2MiscAbCon%
      EditRecipeAbilityInt_TT = %Tab2MiscAbInt%
      EditRecipeAbilityWis_TT = %Tab2MiscAbWis%
      EditRecipeAbilityCha_TT = %Tab2MiscAbCha%
      ShowRecipeAbilitySum_TT = %Tab2MiscAbSum%
      
      Gui, 2: Add, Edit, x15  y215 w450 h110 vEditRecipeComments -Wrap        , %Tab2MiscCommen%
      
      Gui, 2: Add, Button, x%xd% y%yi%       vSaveM gSave, Save
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
  XPArray = 
  AbsArray = 
  
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
Return                                                                           ; <<<===  Build up contents ends

CheckAbs:                                                                        ; <<<===  Check Abilities begins
{
  Gui, 2: Submit, NoHide
  Sum := EditRecipeAbilityStr + EditRecipeAbilityDex + EditRecipeAbilityCon + EditRecipeAbilityInt + EditRecipeAbilityWis + EditRecipeAbilityCha
  
  GuiControl, , ShowRecipeAbilitySum, %Sum%
  
  Sum = 
}
Return                                                                           ; <<<===  Check Abilities ends

RecipesWithinWorkbench:                                                          ; <<<===  RecipesWithinWorkbench begins
{
  GetLanguage()
  
  Gui, 2: Submit, NoHide                                                         ; send variables to memory
  
  PrintActRecipeProduct     := TrimToGetProduct(ActRecipeProduct)
  PrintActRecipeProductTag  := TrimToGetTag(ActRecipeProduct)
  PrintActRecipeProductNbr  := GetCreatedProductNbr(PrintActRecipeProductTag)
  NewRecipeWorkbench        := GetWorkbenchName(PrintActRecipeProductTag)
  SCRIPTVAR                 := ReturnScriptSnippetForRecipe(PrintActRecipeProductTag)
  
  ComponentsToShow := CompToArray(PrintActRecipeProductTag)
  BiProductsToShow := BiProdToArray(PrintActRecipeProductTag)
  StringReplace, ComponentsToShow, ComponentsToShow, |, |, UseErrorLevel
  cl := 5-ErrorLevel
  StringReplace, BiProductsToShow, BiProductsToShow, |, |, UseErrorLevel
  bl := 5-ErrorLevel
  
  If (DEBUG = 1)
    MsgBox, RecipesWithinWorkbench: %NewRecipeWorkbench%
  
  GuiControl,, ShowRecipeProduct,     %PrintActRecipeProduct%                    ; update necessary fields
  GuiControl,, ShowRecipeProductTag,  %PrintActRecipeProductTag%
  GuiControl,, ShowRecipeProductNbr,  %PrintActRecipeProductNbr%
  GuiControl,, ShowRecipeScript,      %SCRIPTVAR%
  
  GuiControl, ChooseString, ShowWorkbenchMenu, %NewRecipeWorkbench%
  
  GuiControl,, EditRecipeProduct,     %PrintActRecipeProduct%                    ; update necessary fields
  GuiControl,, EditRecipeProductTag,  %PrintActRecipeProductTag%
  GuiControl,, EditRecipeProductNbr,  %PrintActRecipeProductNbr%
  GuiControl,, EditRecipeScript,      %SCRIPTVAR%
  
  GuiControl,, EditRecipeLevel,       % ReturnLevelFromRecipe(PrintActRecipeProductTag)
  
  XPArray := StrSplit(ReturnXPFromRecipe(PrintActRecipeProductTag), "|")
  GuiControl,, EditRecipeXP,          % XPArray[ 1 ]
  GuiControl,, EditRecipeCnrXP,       % XPArray[ 2 ]
  
  AbsArray := StrSplit(ReturnAbilitysFromRecipe(PrintActRecipeProductTag), "|")  ; create the Ability Array
  GuiControl,, EditRecipeAbilityStr,  % AbsArray[ 1 ]
  GuiControl,, EditRecipeAbilityDex,  % AbsArray[ 2 ]
  GuiControl,, EditRecipeAbilityCon,  % AbsArray[ 3 ]
  GuiControl,, EditRecipeAbilityInt,  % AbsArray[ 4 ]
  GuiControl,, EditRecipeAbilityWis,  % AbsArray[ 5 ]
  GuiControl,, EditRecipeAbilityCha,  % AbsArray[ 6 ]
  
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
  
  XPArray = 
  AbsArray = 
  
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

Save:                                                                            ; <<<===  Save check begins
{
  SaveVar := 1                                                                   
  Gui, 2: Submit, NoHide                                                         ; send variables to memory
  
  If (DEBUG = 1)
  {
    MouseGetPos, , , , AusgabeSteuerelement
    MsgBox, % AusgabeSteuerelement
  }
  
  OriginalRecipe  := BuildOriginalRecipeVersion(ShowRecipeProductTag)
  OriginalMiscs   := BuildOriginalMiscVersion(ShowRecipeProductTag)
  ChangedRecipe   := CreateChangedRecipeVersion()
  ChangedMiscs    := CreateChangedMiscVersion()
  
  Original := OriginalRecipe "`n" OriginalMiscs
  Changed  := ChangedRecipe "`n" ChangedMiscs
  
  If (Original == Changed)
    Msgbox, %Tab2NoChanges%
  
  Else
  {
    If (DEBUG = 1)
      MsgBox, % "Changes:`n" Original "`n" Changed
    
    SomethingChanged := 1
  }
  
  If (SomethingChanged == 1)
  {
    SCRIPTVAR := ChangedRecipeToScriptSnippet(Changed)
    SCRIPTVAR := % "sKeyToRecipe = CnrRecipeCreateRecipe(" GetWorkbenchFromProduct(ShowRecipeProductTag) ", " SCRIPTVAR
    
    If (DEBUG = 1)
      MsgBox, 1) Save function:`n%SCRIPTVAR%
    
    If (SaveVar == 1)                                                            ; later, that should save it to the original
    {
      GuiControl, , ShowRecipeProduct,    % ChangedRecipeProductName(ChangedMiscs) ; for now, it only updates the necessary fields
      GuiControl, , ShowRecipeProductTag, % ChangedRecipeTagResRef(ChangedMiscs)
      GuiControl, , ShowRecipeProductNbr, % ChangedRecipeCreate(ChangedMiscs)
      GuiControl, , ShowRecipeScript,     %SCRIPTVAR%
      
      ;GuiControl, ChooseString, ShowWorkbenchMenu, %NewRecipeWorkbench%
    }
    
    Else
      MsgBox, %OnNothingToShow%
  }
  
  SaveVar = 
  OriginalRecipe = 
  OriginalMiscs = 
  ChangedRecipe = 
  ChangedMiscs = 
  Original = 
  Changed = 
  SCRIPTVAR = 
}
Return                                                                           ; <<<===  Save check ends

EditRecipeTab:
  ;MsgBox, %OnNothingToShow%
Return

OpenErf:
{
  MsgBox, 4, ,
  (
Note: This relays on third party tools (in this case on niv's neverwinter.nim) to extract the nss' from an ERF-file.
So it is nessesary to check if it's a new version online.
On this early stage you must check for yourself.

Is it on the least stable version?
  )
  
  IfMsgBox No
    Return
  
  FileSelectFile, OpenErfVar, , , , ERF-File (*.erf)
  If !FileExist("\erf")
    FileCreateDir, erf
  
  If OpenErfVar
  {
    FileCopy, %OpenErfVar%, %A_WorkingDir%, TRUE
    SplitPath, OpenErfVar, File
    
    If DEBUG
    {
      Run, %ComSpec% /k %A_WorkingDir%\tools\nwn_erf.exe -f %File% -t > log.txt
      Run, %ComSpec% /k %A_WorkingDir%\tools\nwn_erf.exe -f %File% -x
    }
    Else
    {
      Run, %ComSpec% /c %A_WorkingDir%\tools\nwn_erf.exe -f %File% -t > log.txt
      Run, %ComSpec% /c %A_WorkingDir%\tools\nwn_erf.exe -f %File% -x
    }
  }
  Else
    Return
  
  Sleep, 1000                                                                   ; wait 1 sec before continue
  If FileExist("log.txt")
  {
    Loop, Read, log.txt
    {
      FileMove, %A_LoopReadLine%, %A_WorkingDir%\erf\, TRUE
      FileMove, %File%, %A_WorkingDir%\erf\, TRUE
    }
  }
  
  Else
    MsgBox, %OpenErfError%
  
  FileDelete, log.txt
  
  MsgBox, %OpenErfClose%
  GoSub, GuiClose
}
Return

NewRecipe:
  MsgBox, %OnNothingToShow%
Return

Options:
  Gui, 3: Add, Text,   x6   y6                    , %OptWinFavEditTxt%:
  Gui, 3: Add, Button, x6   y27 w87  gChooseEditor, %OptWinFavEditBtn%
  Gui, 3: Add, Button, x97  y27     gEditorDefault, %OptWinFavEditDef%
  
  IniRead, LANGS, language.ini
  LANGS := StrReplace(LANGS, "`n", "|") "|"
  LANGS := StrReplace(LANGS, LANG, LANG "|")
  Gui, 3: Add, Text,   x6   y54                   , %OptWinLangTxt%:
  Gui, 3: Add, DDL,    x6   y74        gLang vLANG, %LANGS%
  
  Gui, 3: Add, Button, x55  y105        gCloseOpts, %OptWinFavEditCls%
  Gui, 1: +Disabled
  Gui, 2: +Disabled
  Gui, 3: Show
  Gui, 3: Show, center w150 h150, %OptWinName%
Return

Lang:
  MsgBox, %OptWinLangMsg%
Return

CloseOpts:
  Gui, 3: Submit, NoHide
  IniWrite, %FAV%,  config.ini, Other,   FAV
  IniWrite, %LANG%, config.ini, Default, LANG
  
  Gui, 1: -Disabled
  Gui, 2: -Disabled
  Gui, 3: Destroy
Return

ChooseEditor:
{
  FileSelectFile, FAV, , , , Exe-File (*.exe)
  
  If FAV
  {
    IniWrite, %FAV%, config.ini, Other, FAV
  }
  Else
  {
    MsgBox, %OptWinFavEdDefMs%
    FAV = Notepad.exe
    IniWrite, %FAV%, config.ini, Other, FAV
  }
}
Return

EditorDefault:
  FAV = Notepad.exe
  IniWrite, %FAV%, config.ini, Other, FAV
Return

ShowAbout:
  If DEBUG
    ListVars
  Else
    MsgBox, %OnNothingToShow%
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

3GuiClose:
3GuiEscape:
  ;save options!
  Gui, 3: Submit, NoHide
  IniWrite, %FAV%, config.ini, Other, FAV
  Gui, 1: -Disabled
  Gui, 2: -Disabled
  Gui, 3: Destroy
Return


; Ends app and destroys program
GuiClose:
  FileDelete, %TEMP_DIR%*.tmp
  ExitApp