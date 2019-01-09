/*;================================================================================
;   Error Messages:
;   ERROR001: from GetObjectName(RecipientTag)  =>  it was nothing recognized from temporary array
;   ERROR011: from GetObjectName(RecipientTag)  =>  it was nothing recognized from csv => really nothing!
;   ERROR002: from GetWorkbenchName(ProductTagToLookFor)
;   ERROR021: from GetWorkbenchName(ProductTagToLookFor), later Message
;   ERROR003: from GetCreatedProductNbr(ProductTagToLookFor)
;   ERROR012: from GetSpellName(SpellConstant)  =>  spell wasn't found, must be a custom spell. add it to csv?!
*/;================================================================================

;================================================================================
; GetObjectName(RecipientTag)
;================================================================================
GetObjectName(RecipientTag)
{
  Result = ERROR001
  StringLower, RecipientTag, RecipientTag
  
  Loop, Read, %A_WorkingDir%\tmp\array.tmp                                      ; search in array-file at first
  {
    itmarray := StrSplit(A_LoopReadLine, "|")
    resarray := itmarray[1]
;       wenn "R"
    If (resarray = "R")                                                         ; the recipe has the right names?!
    {
      tagme := % itmarray[4]
      tagyou := % itmarray[3]
      StringLower, tagme, tagme
      
      If (RecipientTag = tagme)
      {
        Result := % tagyou
        break
      }
    }
  }
  
  If (Result = "ERROR001")
  { 
    Result = ERROR011
    Loop, Read, %A_WorkingDir%\items.csv                                          ; search from csv-file then
    {
      itmarray := StrSplit(A_LoopReadLine, ",")
      resarray := % itmarray[2]
      tagarray := % itmarray[3]
      
      StringLower, resarray, resarray
      StringLower, tagarray, tagarray
      
      If (RecipientTag = resarray)
      {
        Result := % itmarray[1]
        StringReplace, Result, Result, (, (, UseErrorLevel
        Counted := ErrorLevel
        
        If (Counted > 0)
        {
          StringReplace, Result, Result, %A_Space%(, `,%A_Space%
          StringReplace, Result, Result, ), 
        }
        
        break
      }
      
      Else If (RecipientTag = tagarray)
      {
        Result := % itmarray[1]
        break
      }
    } 
  }
  
  itmarray = 
  resarray = 
  tagarray = 
  tagme = 
  tagyou = 
  Counted = 
  
  return Result
}
;================================================================================
;
;================================================================================
; GetSpellName(SpellConstant)
;================================================================================
GetSpellName(SpellConstant)
{
  Result = ERROR012
  
  Loop, Read, %A_WorkingDir%\spells.csv                                          ; search from csv-file only
  {
    spellarray := StrSplit(A_LoopReadLine, ",")
    spellsearch := % spellarray[1]
    spellname := % spellarray[2]
    
    If (SpellConstant = spellsearch)
      Result = %spellname%
  }
  
  return Result
}
;================================================================================
; CreateArrayTempFile(FileToParse, FileForArray)
;================================================================================
CreateArrayTempFile(FileToParse, FileForArray)
{
  ArrayTmpPath = %FUNC_TEMP_DIR%array.tmp
  ArrayTmp := FileOpen(FileForArray, "w")
  
  If !IsObject(ArrayTmp)
  {
    MsgBox Can't open "%FileName%" for writing.
    Return
  }
  
  Loop, Read, %FileToParse%
  {
    ; addiere alle SubMenues ueber "CnrRecipeAddSubMenu"  mit   >M|<
    IfInString, A_LoopReadLine, CnrRecipeAddSubMenu
    {
      StringReplace, SubMenuResult, A_LoopReadLine, %A_SPACE%, , All     ; loesche alle Spaces     >stringsMenuForgeMetal=CnrRecipeAddSubMenu("cnrForgePublic","Metall");
      
      StringGetPos, Count, SubMenuResult, =                              ; sollte 22
      Length := StrLen(SubMenuResult)                                    ; sollte 69 sein
      Count := Length-Count                                              ; 69 - 22 = 47
      
      StringTrimRight, SubMenuResult, SubMenuResult, Count               ; reduziere von rechts      >stringsMenuForgeMetal
      StringTrimLeft, SubMenuResult, SubMenuResult, 6                    ; reduziere von links        >sMenuForgeMetal
      
      SubMenuResult = M|%SubMenuResult%`n
      
      If (SubMenuResult != "")
        ArrayTmp.Write(SubMenuResult)
    }
    
    ; addiere den Namen der Workbench ueber "CnrRecipeSetDeviceTradeskillType"  mit >N|<
    IfInString, A_LoopReadLine, CnrRecipeSetDeviceTradeskillType
    {
      If (RecipeWorkbench = "")                                          ; verhindert das die zeile mehrmals addiert wird
      {
        ; Ausgelesene Zeile besser verarbeitbar machen
        RecipeWorkbench := StrReplace(A_LoopReadLine, Chr(34), "", ALL)  ; loesche alle "                >  CnrRecipeSetDeviceTradeskillType   (cnrCarpsBench, CNR_TRADESKILL_WOOD_CRAFTING);<
        
        StringGetPos, Count, RecipeWorkbench, ( 
        StringTrimLeft, RecipeWorkbench, RecipeWorkbench, Count+1        ; loesche                        >  CnrRecipeSetDeviceTradeskillType   (<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ", ", "|", ALL)   ; ersetze , & space mit |  >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING);<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ");" , "", ALL)   ; loesche );                     >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING<
        
        IfInString, RecipeWorkbench, */
          RecipeWorkbench := StrReplace(RecipeWorkbench, "*/", "", ALL)  ; loesche ggf. */ 
          
        WorkbenchArray := StrSplit(RecipeWorkbench, "|")
        RecipeWorkbench := WorkbenchArray[1]                             ; name der Workbench in 1
        
        IfInString, RecipeWorkbench, //                                  ; entferne ggf. kommentare
        {
          StringGetPos, Count, RecipeWorkbench, //
          StringLeft, RecipeWorkbench, RecipeWorkbench, Count
        }
        
        RecipeWorkbench = N|%RecipeWorkbench%`n
        If (RecipeWorkbench != "")
          ArrayTmp.Write(RecipeWorkbench)
      }
    }
    
    ; addiere das rezept ueber "CnrRecipeCreateRecipe"  mit  >R|<
    IfInString, A_LoopReadLine, CnrRecipeCreateRecipe
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      RecipeResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)          ; loesche alle "                >  sKeyToRecipe = CnrRecipeCreateRecipe(cnrWaterTub, Filled Water Bucket, cnrBucketWater, 1);<
      
      StringGetPos, Count, RecipeResult, ( 
      StringTrimLeft, RecipeResult, RecipeResult, Count+1                   ; loesche                        >  sKeyToRecipe = CnrRecipeCreateRecipe(<
      
      StringReplace, Temp, RecipeResult, ), ), UseErrorLevel                ; zaehle nach, wieviel ) sind im string fuer >  sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain (20)", "cnrArwHeadPlain", 1);  <
      If (ErrorLevel > 1)                                                   ; > sKeyToRecipe = CnrRecipeCreateRecipe(
      {
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)            ; loesche );                     >sMenuTinkerArrowheads, Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, ", " , "|", , 1)           ; ersetze ein , & space    >sMenuTinkerArrowheads|Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, "), " , ")|", , 1)         ; ersetze ein ), & space   >sMenuTinkerArrowheads|Arrowheads, Plain (20|cnrArwHeadPlain, 1
        StringGetPos, Count, RecipeResult, `,                               ; zaehle bis ,   => 32      >sMenuTinkerArrowheads|Arrowheads>,< Plain (20|cnrArwHeadPlain, 1
        RecipeResult := RegExReplace(RecipeResult, ", ", "|", , , Count+2)  ; nun ersetze , & space danach?
        
        IfInString, RecipeResult, */
          RecipeResult := StrReplace(RecipeResult, "*/", "", ALL)           ; loesche ggf. */
        
        IfInString, RecipeResult, //                                        ; entferne ggf. kommentare
        {
          StringGetPos, Count, RecipeResult, //
          StringLeft, RecipeResult, RecipeResult, Count
        }
        
        IfInString, RecipeResult, GetObjectName                             ; sMenuMythArmors|GetObjectName(NW_MAARCL037)|NW_MAARCL037|1
        {
          TempArray := StrSplit(RecipeResult, "|")                          ; array anlegen
          Replace := TempArray[2]                                           ; GetObjectName(NW_MAARCL037) ausgelesen
          StringTrimLeft, ReplaceText, Replace, 14
          StringTrimRight, ReplaceText, ReplaceText, 1
          
          ReplaceText := GetObjectName(ReplaceText)                         ; lese korrekten Namen aus
          RecipeResult := StrReplace(RecipeResult, Replace, ReplaceText)    ; und ersetze diesen
        }
      }
      
      Else                                                                  ; > sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain", "cnrArwHeadPlain", 1);
      {
        RecipeResult := StrReplace(RecipeResult, ", ", "|", ALL)            ; ersetze , & space mit |  >cnrWaterTub|Filled Water Bucket|cnrBucketWater|1);<
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)            ; loesche );                     >cnrWaterTub,Filled Water Bucket,cnrBucketWater,1
        
        IfInString, RecipeResult, */
          RecipeResult := StrReplace(RecipeResult, "*/", "", ALL)           ; loesche ggf. */
        
        IfInString, RecipeResult, //                                        ; entferne ggf. kommentare
        {
          StringGetPos, Count, RecipeResult, //
          StringLeft, RecipeResult, RecipeResult, Count
        }
        
        IfInString, RecipeResult, GetObjectName                             ; sMenuMythArmors|GetObjectName(NW_MAARCL037)|NW_MAARCL037|1
        {
          TempArray := StrSplit(RecipeResult, "|")                          ; array anlegen
          Replace := TempArray[2]                                           ; GetObjectName(NW_MAARCL037) ausgelesen
          StringTrimLeft, ReplaceText, Replace, 14
          StringTrimRight, ReplaceText, ReplaceText, 1
          
          ReplaceText := GetObjectName(ReplaceText)                         ; lese korrekten Namen aus
          RecipeResult := StrReplace(RecipeResult, Replace, ReplaceText)    ; und ersetze diesen
        }
      }
      
      RecipeResult = R|%RecipeResult%`n                                     ; solte das  >R|sMenuLevel5Scrolls|Dismissal|X1_IT_SPARSCR502|1<  produzieren
      If (RecipeResult != "")
        ArrayTmp.Write(RecipeResult)
      CountedPs := 0                                                        ; ein neues rezept beginnt, setze komponenten auf null
      CountedBs := 0
    }
    
    ; addiere komponenten ueber "CnrRecipeAddComponent"  mit  >P#|<
    IfInString, A_LoopReadLine, CnrRecipeAddComponent
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      ComponentResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)   ; loesche alle "                >  CnrRecipeAddComponent(sKeyToRecipe, cnrBucketEmpty, 1);
      
      StringGetPos, Count, ComponentResult, `,
      StringTrimLeft, ComponentResult, ComponentResult, Count           ; loesche                      >  CnrRecipeAddComponent(sKeyToRecipe
      ComponentResult := StrReplace(ComponentResult, ", ", "|", ALL)    ; ersetze , & space mit |    >|cnrBucketEmpty| 1);
      ComponentResult := StrReplace(ComponentResult, ");" , "", ALL)    ; loesche );                   >|cnrBucketEmpty| 1
      
      IfInString, ComponentResult, */
        ComponentResult := StrReplace(ComponentResult, "*/", "", ALL)   ; loesche ggf. */
      
      IfInString, ComponentResult, //                                   ; loesche ggf. kommentare
      {
        StringGetPos, Count, ComponentResult, //
        StringLeft, ComponentResult, ComponentResult, Count
      }
      
      ComponentResult := StrReplace(ComponentResult, A_Space , "", ALL) ; loesche space               >|cnrBucketEmpty|1
      
      StringGetPos, Count, ComponentResult, |, , 1                      ; suche position des zweiten |
      Length := StrLen(ComponentResult)                                 ; laenge des strings
      Count := Length-Count
      
      StringTrimLeft, ProductResult, ComponentResult, 1                 ; loesche erstes |             >NW_MAARCL078|1|1
      StringTrimRight, ProductResult, ProductResult, Count              ; loesche nach letztem |   >NW_MAARCL078
      
                                                                        ; P4|ERROR011|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST
      IfInString, ComponentResult, CNR_RECIPE_SPELL                     ; |CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST
      {
        TempArray := StrSplit(ComponentResult, "|")                     ; array anlegen
        Replace := TempArray[4]                                         ; SPELL_RAY_OF_FROST ausgelesen
        
        RecipeProduct := GetSpellName(Replace)                          ; lese korrekten Namen aus
      }
      Else
        RecipeProduct := GetObjectName(ProductResult)
      
      CountedPs := CountedPs+1
      ComponentResult = P%CountedPs%|%RecipeProduct%%ComponentResult%`n
      If (ComponentResult != "") 
        ArrayTmp.Write(ComponentResult)
    }
    
    ; addiere biprodukte ueber "CnrRecipeSetRecipeBiproduct"  mit  >B|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeBiproduct
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      Temp := A_LoopReadLine                                ; auf temp speichern                      >  CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);
      
      StringGetPos, Count, Temp, `,                         ; suche position des ersten , = 42
      StringTrimLeft, Temp, Temp, Count+3                   ; loesche bis zum , +1                   >cnrGlassVial", 1, 1);
      StringGetPos, Count, Temp, `,                         ; suche position des zweiten ,   = 13
      Length := StrLen(Temp)                                ; laenge des strings berechnen = 21
      Count := Length-Count                                 ; 21-13 = 8
      
      StringTrimRight, BiProduct, Temp, Count+1             ; reduziere auf                               >cnrGlassVial
      
      Length := StrLen(BiProduct)                           ; laenge des strings berechnen = 12
      StringTrimLeft, Qty, Temp, Length+3                   ; reduziere auf                               >1, 1);
      
      Qty := StrReplace(Qty, ", ", "|", ALL)                ; ersetze , & space mit |                 >1|1);
      StringTrimRight, Qty, Qty, 2                          ; reduziere auf                               >1|1
      
      CountedBs := CountedBs+1
      BiProductResult = B%CountedBs%|%BiProduct%|%Qty%`n
      If (BiProductResult != "")
        ArrayTmp.Write(BiProductResult)
    }
    
    ; addiere stufe ueber "CnrRecipeSetRecipeLevel"  mit  >L|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeLevel
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      LevelResult := A_LoopReadLine
      
      StringTrimRight, LevelResult, LevelResult, 2      ; loesche die letzten zwei        >  CnrRecipeSetRecipeLevel(sKeyToRecipe, 18
      StringGetPos, Count, LevelResult, `,              ; suche position des ersten , = 38
      
      StringTrimLeft, LevelResult, LevelResult, Count+2 ; loesche bis zum , +2             >18
      
      LevelResult = L|%LevelResult%`n
      If (LevelResult != "")
        ArrayTmp.Write(LevelResult)
    }
    
    ; addiere erfahrungspunkte ueber "CnrRecipeSetRecipeXP"  mit  >X|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeXP
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      XpResult := A_LoopReadLine
      
      StringGetPos, Count, XpResult, `,
      StringTrimLeft, XpResult, XpResult, Count           ; loesche                         >  CnrRecipeSetRecipeXP(sKeyToRecipe
      XpResult := StrReplace(XpResult, ", ", "|", ALL)    ; ersetze , & space mit |   >| 5| 5);
      XpResult := StrReplace(XpResult, ");" , "", ALL)    ; loesche );                      >| 5| 5
      
      IfInString, XpResult, */
        XpResult := StrReplace(XpResult, "*/", "", ALL)   ; loesche ggf. */
      
      IfInString, XpResult, //
      {
        StringGetPos, Count, XpResult, //
        StringLeft, XpResult, XpResult, Count
      }
      
      XpResult := StrReplace(XpResult, A_Space , "", ALL) ; loesche space               >|5|5
      XpResult = X%XpResult%`n
      If (XpResult != "")
        ArrayTmp.Write(XpResult)
    }
    
    ; addiere attribute ueber "CnrRecipeSetRecipeAbilityPercentages"  mit  >A|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeAbilityPercentages
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      AbsResult := A_LoopReadLine
      
      StringGetPos, Count, AbsResult, `,
      StringTrimLeft, AbsResult, AbsResult, Count           ; loesche                         >  CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe
      AbsResult := StrReplace(AbsResult, ", ", "|", ALL)    ; ersetze , & space mit |   >| 0| 0|40| 0|60| 0);
      AbsResult := StrReplace(AbsResult, ");" , "", ALL)    ; loesche );                      >| 0| 0|40| 0|60| 0
      
      IfInString, AbsResult, */
        AbsResult := StrReplace(AbsResult, "*/", "", ALL)   ; loesche ggf. */
      
      IfInString, AbsResult, //
      {
        StringGetPos, Count, AbsResult, //
        StringLeft, AbsResult, AbsResult, Count
      }
      
      AbsResult := StrReplace(AbsResult, A_Space , "", ALL) ; loesche space               >|0|0|40|0|60|0
      AbsResult = A%AbsResult%`n
      If (AbsResult != "")
        ArrayTmp.Write(AbsResult)
    }
    
    ; speicher leeren!
    Temp = 
    TempArray = 
    Replace = 
    ReplaceText = 
    SubMenuResult = 
    RecipeResult = 
    Replace = 
    ReplaceText = 
    RecipeProduct = 
    RecipeWorkbench = 
    ComponentResult = 
    ProductResult = 
    BiProductResult = 
    BiProduct = 
    Qty = 
    LevelResult = 
    XpResult = 
    AbsResult = 
    Count = 
    Length = 
    
  }
  ArrayTmp.Close()                                          ; arrays fertig abgelegt, schließe die datei
}
;================================================================================
;
;================================================================================
; ReturnWorkbenchFromRecipe(ArrayTmpPath)
; vermerkt in  >  N|cnrBakersOven <
;================================================================================
ReturnWorkbenchFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                              ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       wenn "N"
    If (WhatKindOf = "N")                                                 ; Name der Workbench
      Result := RecipeArray[2]                                            ; liegt unter "N" auf Platz zwei!
  }
  
  If (Result = "")                                                        ; keine Workbench gefunden, Rezept hats!
  {
    Loop, Read, %ArrayTmpPath%                                            ; lese nun die Array-Datei aus
    {
      RecipeArray := StrSplit(A_LoopReadLine, "|")
      WhatKindOf := RecipeArray[1]
;           wenn "R"
      If (WhatKindOf = "R")                                               ; Name der Workbench
        Result := RecipeArray[2]                                          ; liegt unter "R" auf Platz zwei!
    }
  }
  
  RecipeArray = 
  WhatKindOf = 
  
  return Result
}
;================================================================================
;
;================================================================================
; ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
; wird aus  >  M|sMenuBakeBreads  <  aufgebaut  (mehrfache moeglich)
;================================================================================
ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                              ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       wenn "M"
    If (WhatKindOf = "M")                                                 ; Name der Workbench
    {
      Workbench := RecipeArray[2]                                         ; liegt unter "M" auf Platz zwei!
      
      IfNotInString, Result, Workbench                                    ; sollte sie noch nicht drin sein, addiere sie
        Result = %Workbench%|%Result%
    }
  }
  
  If (Result = "")                                                        ; keine Workbench gefunden, Rezept hats!
  {
    Loop, Read, %ArrayTmpPath%                                            ; lese nun die Array-Datei aus
    {
      RecipeArray := StrSplit(A_LoopReadLine, "|")
      WhatKindOf := RecipeArray[1]
;           wenn "R"
      If (WhatKindOf = "R")                                               ; Name der Workbench
        Result := RecipeArray[2]                                          ; liegt unter "N" auf Platz zwei!
    }
  }
  
  RecipeArray = 
  WhatKindOf = 
  Workbench = 
  
  return Result
}
;================================================================================
;
;================================================================================
; ReturnRecipeListFromRecipe(ArrayTmpPath)
; wird aus  >   R|sMenuBakeBreads|Roggenbrot|cnrRyeBread|1  <  aufgebaut  (mehrfache moeglich)
;================================================================================
ReturnRecipeListFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                              ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       wenn "R"
    If (WhatKindOf = "R")                                                 ; Rezept beginnt hier!
    {
      RecipeProduct    := RecipeArray[3]                                  ; Name des Produkts
      RecipeProductTag := RecipeArray[4]                                  ; ResRef/Tag des Produkts
      
      IfInString, RecipeProduct, GetObjectName                            ; wenn im Produktnamen GetObjectName ist, verwandle um!
        RecipeProduct := GetObjectName(RecipeProductTag)
      
      RecipeProductNbr := RecipeArray[5]                                  ; Anzahl der Produkte
      
      Result = %RecipeProduct% (%RecipeProductTag%) [%RecipeProductNbr%]|%Result%
    }
  }
  
  RecipeArray = 
  WhatKindOf = 
  RecipeProduct = 
  RecipeProductTag = 
  RecipeProductNbr = 
  
  return Result
}
;================================================================================
;
;================================================================================
; ReturnXPFromRecipe(ArrayTmpPath)
; X|10|10
;================================================================================
ReturnXPFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                       ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; wenn "X"
    If (WhatKindOf = "X")                                          ; EP fuers Erstellen des Produkts
    {
      RecipeCP := RecipeArray[3]
      RecipeXP := RecipeArray[4]
      
      Result := RecipeCP|RecipeXP|
    }
  }
  
  RecipeArray = 
  WhatKindOf = 
  RecipeCP = 
  RecipeXP = 
  
  return Result
}
;================================================================================
;
;================================================================================
; ReturnAbilitysFromRecipe(ArrayTmpPath)
;================================================================================
ReturnAbilitysFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                       ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       wenn "A"
    If (WhatKindOf = "A")                                          ; Attribute festlegen  >cnrBarleyGeroestetes|0|0|40|0|60|0
    {
       AbilityStr := RecipeArray[3]
       AbilityDex := RecipeArray[4]
       AbilityCon := RecipeArray[5]
       AbilityInt := RecipeArray[6]
       AbilityWis := RecipeArray[7]
       AbilityCha := RecipeArray[8]
       
       Result := AbilityStr|AbilityDex|AbilityCon|AbilityInt|AbilityWis|AbilityCha|
    }
  }
  
  RecipeArray = 
  WhatKindOf = 
  AbilityStr = 
  AbilityDex = 
  AbilityCon = 
  AbilityInt = 
  AbilityWis = 
  AbilityCha = 
  
  return Result
}
;================================================================================
;
;================================================================================
; TrimToGetTag(LookAndTrim)
;================================================================================
TrimToGetTag(LookAndTrim)
{
  Count := InStr(LookAndTrim, " (")-1                       ; GetObjectName> (<bf_ioun_lightred ) (bf_ioun_lightred) [1]
  StringTrimLeft, LookAndTrim, LookAndTrim, Count           ;  (hw_it_mpotion024) [1]
  
  StringReplace, Count, LookAndTrim, ), ), UseErrorLevel    ; zaehle nach, wieviel ) sind im string fuer >  (20) (cnrArwHeadBlunt) [1]  <
  If (ErrorLevel > 1)
  {
    Count := InStr(LookAndTrim, ") ")+2                     ; suche die position des ersten ) & space +2
    StringTrimLeft, LookAndTrim, LookAndTrim, Count         ; reduziere bis dahin
  }
  
  LookAndTrim := StrReplace(LookAndTrim, " (", "", ALL)     ; hw_it_mpotion024) [1]
  LookAndTrim := StrReplace(LookAndTrim, ")", "", ALL)      ; hw_it_mpotion024 [1]
  
  Count := InStr(LookAndTrim, " [")-1                       ; bf_ioun_lightred [1]
  Count := StrLen(LookAndTrim) - Count                      ; bf_ioun_lightred<[1]>
  StringTrimRight, LookAndTrim, LookAndTrim, Count          ; bf_ioun_lightred
  
  Count = 
  
  return LookAndTrim
}
;================================================================================
;
;================================================================================
; TrimToGetProduct(LookAndTrim)
;================================================================================
TrimToGetProduct(LookAndTrim)
{
  IfInString, LookAndTrim, GetObjectName                      ; Findet sich die Funktion GetObjectName im Produktnamen?
  {
    LookAndTrim := TrimToGetTag(LookAndTrim)
    LookAndTrim := GetObjectName(LookAndTrim)
  }
  
  Else
  {
    StringReplace, Count, LookAndTrim, ), ), UseErrorLevel    ; zaehle nach, wieviel ) sind im string fuer >  Arrowheads, Blunt (20) (cnrArwHeadBlunt) [1]  <
    If (ErrorLevel > 1)                                       ; Arrowheads, Blunt (20) (cnrArwHeadBlunt) [1]
      Count := InStr(LookAndTrim, ") ", R)                    ; nimm das letzte ) & space als ausgangspunkt
    Else
      Count := InStr(LookAndTrim, " (", R)                    ; Filled Water Bucket (cnrBucketWater)  > TrimToGetProduct: 20 |36 | Filled Water Bucket (cnrBucketWater)
    
    Length := StrLen(LookAndTrim)
    Count := Length - Count
    StringTrimRight, LookAndTrim, LookAndTrim, Count
  }
  
  Count = 
  Length = 
  
  return LookAndTrim
}
;================================================================================
;
;================================================================================
; GetWorkbenchName(ProductTagToLookFor)
;================================================================================
GetWorkbenchName(ProductTagToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR002
  
  Loop, Read, %AllTheArrays%                                ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    
    If (WhatKindOf = "R")                                   ; Rezept beginnt hier!
    {
      RecipeProductTag := RecipeArray[4]                    ; ResRef/Tag des Produkts
      
      If (ProductTagToLookFor = RecipeProductTag)
      {
        Result := RecipeArray[2]
        
        If (Result = ProductTagToLookFor)
          Result = ERROR021
      }
    }
  }
  
  AllTheArrays = 
  RecipeArray = 
  WhatKindOf = 
  RecipeProductTag = 
  
  return Result
}
;================================================================================
;
;================================================================================
; GetCreatedProductNbr(ProductTagToLookFor)
;================================================================================
GetCreatedProductNbr(ProductTagToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR003
  
  Loop, Read, %AllTheArrays%                                ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    
    If (WhatKindOf = "R")                                   ; Rezept beginnt hier!
    {
      RecipeProductTag := RecipeArray[4]                    ; ResRef/Tag des Produkts
      
      If (ProductTagToLookFor = RecipeProductTag)
        Result := RecipeArray[5]
    }
  }
  
  AllTheArrays = 
  RecipeArray = 
  WhatKindOf = 
  RecipeProductTag = 
  
  return Result
}
;================================================================================
;
;================================================================================
; GetWorkbenchNumberInList(WorkbenchMenuToLookAt, ProductTagToLookFor)
;================================================================================
GetWorkbenchNumberInList(WorkbenchMenuToLookAt, ProductTagToLookFor)
{
  Result = 0
  ; zaehle alle tokens im array
  StringReplace, Temp, WorkbenchMenuToLookAt, |, |, UseErrorLevel     ; sMenuAltarSceptre|sMenuAltarStaves|sMenuAltarRods|sMenuAltarGreIou|sMenuAltarLesIou|sMenuAltarLight|sMenuAltarEnchMat|sMenuAltarBags|
  CountedTokens := ErrorLevel                                         ; => 8
  StringGetPos, Temp, WorkbenchMenuToLookAt, %ProductTagToLookFor%    ; => 50
  StringTrimLeft, Temp, WorkbenchMenuToLookAt, Temp                   ; reduziere ab 50
  StringReplace, Temp, Temp, |, |, UseErrorLevel                      ; ueber gebliebene token zaehlen
  NewCountedTokens := ErrorLevel                                      ; => 5
  Result := CountedTokens-NewCountedTokens                            ; berechne position
  Result := Result + 1
  
  Temp = 
  CountedTokens = 
  NewCountedTokens = 
  
  return Result
}
;================================================================================
;
;================================================================================
; ReturnScriptSnippetForRecipe(ProductToShow)
/*
  referents to PrintActRecipeProduct
  sKeyToRecipe = CnrRecipeCreateRecipe(sMenuLevel6Scrolls, "Vampiric Touch", "NW_IT_SPARSCR311", 1);
  CnrRecipeAddComponent(sKeyToRecipe, "cnrScrollBlank", 1);
  CnrRecipeAddComponent(sKeyToRecipe, "cnrInkNecro", 1);
  CnrRecipeAddComponent(sKeyToRecipe, "cnrGemDust003", 1);
  CnrRecipeAddComponent(sKeyToRecipe, "CNR_RECIPE_SPELL", 1, SPELL_VAMPIRIC_TOUCH);
  CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);
  CnrRecipeSetRecipeLevel(sKeyToRecipe, 6);
  CnrRecipeSetRecipeXP(sKeyToRecipe, 60, 60);
  CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, 0, 0, 0, 50, 50, 0);
*/
;================================================================================
ReturnScriptSnippetForRecipe(ProductToShow)
{
  WB := GetWorkbenchName(ProductToShow)
  PD := GetObjectName(ProductToShow)
  TG := (ProductToShow)
  NB := GetCreatedProductNbr(ProductToShow)
  
  Result = KeyToRecipe = CnrRecipeCreateRecipe(%WB%, "%PD%", "%TG%", %NB%);`n
  
  Result = %Result%              CnrRecipeAddComponent(sKeyToRecipe, "hw_resiron", 2, 1);`n                                                      ;loop notwendig
  
  
  
  Result = %Result%              CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);`n                                      ;loop notwendig
  Result = %Result%              CnrRecipeSetRecipeLevel(sKeyToRecipe, 2);`n                                                                                    ;muss ich insg. noch einbauen
  Result = %Result%              CnrRecipeSetRecipeXP(sKeyToRecipe, 30, 30);`n                                                                                ;einfach reicht ab hier wieder
  Result = %Result%              CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, 70, 30, 0, 0, 0, 0);`n                        ;
  
  return Result
}
;================================================================================
