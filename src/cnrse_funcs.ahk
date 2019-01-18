/*;==============================================================================
;   Error Messages:
;   ERROR100: from GetObjectName(RecipientTag)                =>  it was nothing recognized from temporary array
;   ERROR101: from GetObjectName(RecipientTag)                =>  it was nothing recognized from csv => really nothing!
;   ERROR102: from GetSpellName(SpellConstant)                =>  spell wasn't found, must be a custom spell. add it to csv?!
;   
;   ERROR200: from GetWorkbenchName(ProductTagToLookFor)      =>  nothing was found, error from the beginning
;   ERROR201: from GetWorkbenchName(ProductTagToLookFor)      =>  it was the same product tag found that we were looking for?!
;   
;   ERROR300: from GetCreatedProductNbr(ProductTagToLookFor)  =>  nothing was found, error from the beginning
;   
;   ERROR400: from ReturnLevelFromRecipe(ProductToLookFor)    =>  nothing was found, error from the beginning
;   ERROR401: from ReturnLevelFromRecipe(ProductToLookFor)    =>  no matching product, so nothing was found?!
;   ERROR402: from ReturnXPFromRecipe(ProductToLookFor)       =>  nothing was found, error from the beginning
;   ERROR403: from ReturnXPFromRecipe(ProductToLookFor)       =>  no matching product, so nothing was found?!
;   ERROR404: from ReturnAbilitysFromRecipe(ProductToLookFor) =>  nothing was found, error from the beginning
;   ERROR405: from ReturnAbilitysFromRecipe(ProductToLookFor) =>  no matching product, so nothing was found?!
;   ERROR406: from 
;   ERROR407: from 
;   ERROR408: from 
;   ERROR409: from 
;   
;   
;   As a reminder, the array-file holds of the following:
;   =>  M enues  (M|sMenuLevel5Scrolls)                       => more than one possible
;   =>  N ame of the workbench (N|cnrScribeAverage)           => sometimes there isn't one existent (as for cnrWaterTub.nss)
;   =>  R ecipes  (R|sMenuLevel5Scrolls|See Invisibility|NW_IT_SPARSCR205|1) => as many recipes are provided in the recipe scripts
;   =>  another reminder, the function prints the product-tag from every recipe at the end of the following strings
;   =>  Com P onents (P1|Blank Scroll|x2_it_cfm_bscrl|1)      => more than one possible, number of components are at P<#>
;   =>  B iproducts (B1|hw_glassphio|1|1)                     => if a recipe produces a leftover, these are biproducts (numbering same as products)
;   =>  L evel  (L|6)                                         => the creation level required
;   =>  e X perience points (X|60|60)                         => how many XP the PC gets (XP | CNR-XP)
;   =>  A ttributes  (A|0|0|0|50|50|0)                        => which attributes are needed and at what percentage, MUST be in sum 100(%)!
;
*/;==============================================================================

CountTokens(string, dem) {
  StringReplace, string, string, dem, dem, UseErrorLevel
  string := ErrorLevel
  return string
}
;================================================================================
; GetObjectName(RecipientTag)
;================================================================================
GetObjectName(RecipientTag)
{
  Result = ERROR100
  StringLower, RecipientTag, RecipientTag
  
  Loop, Read, %A_WorkingDir%\tmp\array.tmp                                    ; search in array-file at first
  {
    itmarray := StrSplit(A_LoopReadLine, "|")
    resarray := itmarray[1]
;       wenn "R"
    If (resarray = "R")                                                       ; the recipe has the right names?!
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
  
  If (Result = "ERROR100")
  { 
    Result = ERROR101
    Loop, Read, %A_WorkingDir%\items.csv                                      ; search from csv-file then
    {
      itmarray := StrSplit(A_LoopReadLine, ",")
      resarray := % itmarray[2]
      tagarray := % itmarray[3]
      
      StringLower, resarray, resarray
      StringLower, tagarray, tagarray
      
      If (RecipientTag = resarray)
      {
        Result := % itmarray[1]
        ;StringReplace, Result, Result, (, (, UseErrorLevel
        ;Counted := ErrorLevel
        Test := CountTokens(Result, "(" )
        
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

;================================================================================
; GetSpellName(SpellConstant)
;================================================================================
GetSpellName(SpellConstant)
{
  Result = ERROR102
  
  Loop, Read, %A_WorkingDir%\spells.csv                                       ; search from csv-file only
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
  ArrayTmp := FileOpen(FileForArray, "w")
  
  If !IsObject(ArrayTmp)
  {
    MsgBox Can't open "%FileName%" for writing.
    Return
  }
  
  Loop, Read, %FileToParse%
  {
    ; add all SubMenues from "CnrRecipeAddSubMenu"  to   >M|<
    IfInString, A_LoopReadLine, CnrRecipeAddSubMenu
    {
      StringReplace, SubMenuResult, A_LoopReadLine, %A_SPACE%, , All          ; delete all spaces        >stringsMenuForgeMetal=CnrRecipeAddSubMenu("cnrForgePublic","Metall");
      
      StringGetPos, Count, SubMenuResult, =                                   ; should be 22
      Length := StrLen(SubMenuResult)                                         ; should be 69
      Count := Length-Count                                                   ; 69 - 22 = 47
      
      StringTrimRight, SubMenuResult, SubMenuResult, Count                    ; reduce from rigth        >stringsMenuForgeMetal
      StringTrimLeft, SubMenuResult, SubMenuResult, 6                         ; reduce from left         >sMenuForgeMetal
      
      SubMenuResult = M|%SubMenuResult%`n
      
      If (SubMenuResult != "")
        ArrayTmp.Write(SubMenuResult)
    }
    
    ; add Workbench from "CnrRecipeSetDeviceTradeskillType"  to >N|<
    IfInString, A_LoopReadLine, CnrRecipeSetDeviceTradeskillType
    {
      If (RecipeWorkbench = "")                                               ; verhindert das die zeile mehrmals addiert wird
      {
        ; Ausgelesene Zeile besser verarbeitbar machen
        RecipeWorkbench := StrReplace(A_LoopReadLine, Chr(34), "", ALL)       ; delete alle "           >  CnrRecipeSetDeviceTradeskillType   (cnrCarpsBench, CNR_TRADESKILL_WOOD_CRAFTING);<
        
        StringGetPos, Count, RecipeWorkbench, ( 
        StringTrimLeft, RecipeWorkbench, RecipeWorkbench, Count+1             ; delete                  >  CnrRecipeSetDeviceTradeskillType   (<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ", ", "|", ALL)        ; replace , & space mit |  >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING);<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ");" , "", ALL)        ; delete );               >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING<
        
        IfInString, RecipeWorkbench, */
          RecipeWorkbench := StrReplace(RecipeWorkbench, "*/", "", ALL)       ; delete pos. */ 
          
        WorkbenchArray := StrSplit(RecipeWorkbench, "|")
        RecipeWorkbench := WorkbenchArray[1]                                  ; name der Workbench in 1
        
        IfInString, RecipeWorkbench, //                                       ; entferne pos. kommentare
        {
          StringGetPos, Count, RecipeWorkbench, //
          StringLeft, RecipeWorkbench, RecipeWorkbench, Count
        }
        
        RecipeWorkbench = N|%RecipeWorkbench%`n
        If (RecipeWorkbench != "")
          ArrayTmp.Write(RecipeWorkbench)
      }
    }
    
    ; add Recipe from "CnrRecipeCreateRecipe"  to  >R|<
    IfInString, A_LoopReadLine, CnrRecipeCreateRecipe
    {
      RecipeRef =                                                             ; new recipe beginning, reset references
      ; Ausgelesene Zeile besser verarbeitbar machen
      RecipeResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)            ; delete alle "                >  sKeyToRecipe = CnrRecipeCreateRecipe(cnrWaterTub, Filled Water Bucket, cnrBucketWater, 1);<
      
      StringGetPos, Count, RecipeResult, ( 
      StringTrimLeft, RecipeResult, RecipeResult, Count+1                     ; delete                        >  sKeyToRecipe = CnrRecipeCreateRecipe(<
      
      StringReplace, Temp, RecipeResult, ), ), UseErrorLevel                  ; zaehle nach, wieviel ) sind im string fuer >  sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain (20)", "cnrArwHeadPlain", 1);  <
      If (ErrorLevel > 1)                                                     ; > sKeyToRecipe = CnrRecipeCreateRecipe(
      {
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)              ; delete );                     >sMenuTinkerArrowheads, Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, ", " , "|", , 1)             ; replace ein , & space    >sMenuTinkerArrowheads|Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, "), " , ")|", , 1)           ; replace ein ), & space   >sMenuTinkerArrowheads|Arrowheads, Plain (20|cnrArwHeadPlain, 1
        StringGetPos, Count, RecipeResult, `,                                 ; zaehle bis ,   => 32      >sMenuTinkerArrowheads|Arrowheads>,< Plain (20|cnrArwHeadPlain, 1
        RecipeResult := RegExReplace(RecipeResult, ", ", "|", , , Count)      ; nun replace , & space danach
      }
      
      Else                                                                    ; > sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain", "cnrArwHeadPlain", 1);
      {
        RecipeResult := StrReplace(RecipeResult, ", ", "|", ALL)              ; replace , & space mit |  >cnrWaterTub|Filled Water Bucket|cnrBucketWater|1);<
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)              ; delete );                     >cnrWaterTub,Filled Water Bucket,cnrBucketWater,1
      }
      
      IfInString, RecipeResult, */
        RecipeResult := StrReplace(RecipeResult, "*/", "", ALL)               ; delete pos. */
      
      IfInString, RecipeResult, //                                            ; entferne pos. kommentare
      {
        StringGetPos, Count, RecipeResult, //
        StringLeft, RecipeResult, RecipeResult, Count
      }
      
      IfInString, RecipeResult, GetObjectName                                 ; sMenuMythArmors|GetObjectName(NW_MAARCL037)|NW_MAARCL037|1
      {
        TempArray := StrSplit(RecipeResult, "|")                              ; array anlegen
        Replace := TempArray[2]                                               ; GetObjectName(NW_MAARCL037) ausgelesen
        StringTrimLeft, ReplaceText, Replace, 14
        StringTrimRight, ReplaceText, ReplaceText, 1
        RecipeRef := ReplaceText
        
        ReplaceText := GetObjectName(ReplaceText)                             ; lese korrekten Namen aus
        RecipeResult := StrReplace(RecipeResult, Replace, ReplaceText)        ; und replace diesen
      }
      
      RecipeResult = R|%RecipeResult%`n                                       ; solte das  >R|sMenuLevel5Scrolls|Dismissal|X1_IT_SPARSCR502|1<  produzieren
      
      If (RecipeRef = "")
      {
        TempArray := StrSplit(RecipeResult, "|")                              ; convert in an array
        RecipeRef := TempArray[4]                                             ; look for tag and set that as reference
      }
      
      If (RecipeResult != "")
        ArrayTmp.Write(RecipeResult)
      CountedPs := 0                                                          ; ein neues rezept beginnt, setze komponenten auf null
      CountedBs := 0
    }
    
    ; add comPonents from "CnrRecipeAddComponent"  to  >P#|<
    IfInString, A_LoopReadLine, CnrRecipeAddComponent
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      ComponentResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)         ; delete alle "                >  CnrRecipeAddComponent(sKeyToRecipe, cnrBucketEmpty, 1);
      
      StringGetPos, Count, ComponentResult, `,
      StringTrimLeft, ComponentResult, ComponentResult, Count                 ; delete                      >  CnrRecipeAddComponent(sKeyToRecipe
      ComponentResult := StrReplace(ComponentResult, ", ", "|", ALL)          ; replace , & space mit |    >|cnrBucketEmpty| 1);
      ComponentResult := StrReplace(ComponentResult, ");" , "", ALL)          ; delete );                   >|cnrBucketEmpty| 1
      
      IfInString, ComponentResult, */
        ComponentResult := StrReplace(ComponentResult, "*/", "", ALL)         ; delete pos. */
      
      IfInString, ComponentResult, //                                         ; delete pos. kommentare
      {
        StringGetPos, Count, ComponentResult, //
        StringLeft, ComponentResult, ComponentResult, Count
      }
      
      ComponentResult := StrReplace(ComponentResult, A_Space , "", ALL)       ; delete space               >|cnrBucketEmpty|1
      
      StringGetPos, Count, ComponentResult, |, , 1                            ; suche position des zweiten |
      Length := StrLen(ComponentResult)                                       ; laenge des strings
      Count := Length-Count
      
      StringTrimLeft, ProductResult, ComponentResult, 1                       ; delete erstes |             >NW_MAARCL078|1|1
      StringTrimRight, ProductResult, ProductResult, Count                    ; delete nach letztem |   >NW_MAARCL078
      
                                                                              ; P4|ERROR011|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST
      IfInString, ComponentResult, CNR_RECIPE_SPELL                           ; |CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST
      {
        TempArray := StrSplit(ComponentResult, "|")                           ; array anlegen
        Replace := TempArray[4]                                               ; SPELL_RAY_OF_FROST ausgelesen
        
        RecipeProduct := GetSpellName(Replace)                                ; lese korrekten Namen aus
      }
      Else
        RecipeProduct := GetObjectName(ProductResult)
      
      CountedPs := CountedPs+1
      ComponentResult = P%CountedPs%|%RecipeProduct%%ComponentResult%|%RecipeRef%`n
      If (ComponentResult != "") 
        ArrayTmp.Write(ComponentResult)
    }
    
    ; add biproducts from "CnrRecipeSetRecipeBiproduct"  to  >B#|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeBiproduct
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      Temp := A_LoopReadLine                                                  ; auf temp speichern                      >  CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);
      
      StringGetPos, Count, Temp, `,                                           ; suche position des ersten , = 42
      StringTrimLeft, Temp, Temp, Count+3                                     ; delete bis zum , +1                   >cnrGlassVial", 1, 1);
      StringGetPos, Count, Temp, `,                                           ; suche position des zweiten ,   = 13
      Length := StrLen(Temp)                                                  ; laenge des strings berechnen = 21
      Count := Length-Count                                                   ; 21-13 = 8
      
      StringTrimRight, BiProduct, Temp, Count+1                               ; reduziere auf                               >cnrGlassVial
      
      Length := StrLen(BiProduct)                                             ; laenge des strings berechnen = 12
      StringTrimLeft, Qty, Temp, Length+3                                     ; reduziere auf                               >1, 1);
      
      Qty := StrReplace(Qty, ", ", "|", ALL)                                  ; replace , & space mit |                 >1|1);
      StringTrimRight, Qty, Qty, 2                                            ; reduziere auf                               >1|1
      
      CountedBs := CountedBs+1
      BiProductResult = B%CountedBs%|%BiProduct%|%Qty%|%RecipeRef%`n
      If (BiProductResult != "")
        ArrayTmp.Write(BiProductResult)
    }
    
    ; add Level from "CnrRecipeSetRecipeLevel"  to  >L|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeLevel
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      LevelResult := A_LoopReadLine
      
      StringTrimRight, LevelResult, LevelResult, 2                            ; delete die letzten zwei        >  CnrRecipeSetRecipeLevel(sKeyToRecipe, 18
      StringGetPos, Count, LevelResult, `,                                    ; suche position des ersten , = 38
      
      StringTrimLeft, LevelResult, LevelResult, Count+2                       ; delete bis zum , +2             >18
      
      LevelResult = L|%LevelResult%|%RecipeRef%`n
      If (LevelResult != "")
        ArrayTmp.Write(LevelResult)
    }
    
    ; add XP from "CnrRecipeSetRecipeXP"  to  >X|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeXP
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      XpResult := A_LoopReadLine
      
      StringGetPos, Count, XpResult, `,
      StringTrimLeft, XpResult, XpResult, Count                               ; delete                         >  CnrRecipeSetRecipeXP(sKeyToRecipe
      XpResult := StrReplace(XpResult, ", ", "|", ALL)                        ; replace , & space mit |   >| 5| 5);
      XpResult := StrReplace(XpResult, ");" , "", ALL)                        ; delete );                      >| 5| 5
      
      IfInString, XpResult, */
        XpResult := StrReplace(XpResult, "*/", "", ALL)                       ; delete pos. */
      
      IfInString, XpResult, //
      {
        StringGetPos, Count, XpResult, //
        StringLeft, XpResult, XpResult, Count
      }
      
      XpResult := StrReplace(XpResult, A_Space , "", ALL)                     ; delete space               >|5|5
      XpResult = X%XpResult%|%RecipeRef%`n
      If (XpResult != "")
        ArrayTmp.Write(XpResult)
    }
    
    ; add Abilities from "CnrRecipeSetRecipeAbilityPercentages"  to  >A|<
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeAbilityPercentages
    {
      ; Ausgelesene Zeile besser verarbeitbar machen
      AbsResult := A_LoopReadLine
      
      StringGetPos, Count, AbsResult, `,
      StringTrimLeft, AbsResult, AbsResult, Count                             ; delete                    >  CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe
      AbsResult := StrReplace(AbsResult, ", ", "|", ALL)                      ; replace , & space mit |   >| 0| 0|40| 0|60| 0);
      AbsResult := StrReplace(AbsResult, ");" , "", ALL)                      ; delete );                      >| 0| 0|40| 0|60| 0
      
      IfInString, AbsResult, */
        AbsResult := StrReplace(AbsResult, "*/", "", ALL)                     ; delete pos. */
      
      IfInString, AbsResult, //
      {
        StringGetPos, Count, AbsResult, //
        StringLeft, AbsResult, AbsResult, Count
      }
      
      AbsResult := StrReplace(AbsResult, A_Space , "", ALL)                   ; delete space               >|0|0|40|0|60|0
      AbsResult = A%AbsResult%|%RecipeRef%`n
      If (AbsResult != "")
        ArrayTmp.Write(AbsResult)
    }
    
    ; empty all used vars? save memory?
    Temp = 
    TempArray = 
    Replace = 
    ReplaceText = 
    SubMenuResult = 
    RecipeResult = 
    Replace = 
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
  
  ArrayTmp.Close()                                                            ; Array were saved, so close file
}
;================================================================================

;================================================================================
; ReturnWorkbenchFromRecipe(ArrayTmpPath)
; from  >  N|cnrBakersOven <
;================================================================================
ReturnWorkbenchFromRecipe(ArrayTmpPath)
{
  AllThePlaceables := A_WorkingDir . "\plcs.csv"
  Loop, Read, %ArrayTmpPath%                                                  ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    LookFor := RecipeArray[1]
;       if "N"
    If (LookFor = "N")                                                        ; Name der Workbench
      ResultAdd := RecipeArray[2]                                             ; liegt unter "N" auf Platz zwei!
  }
  
  If (ResultAdd = "")                                                         ; keine Workbench gefunden, Rezept hats!
  {
    Loop, Read, %ArrayTmpPath%                                                ; lese nun die Array-Datei aus
    {
      RecipeArray := StrSplit(A_LoopReadLine, "|")
      LookFor := RecipeArray[1]
;           if "R"
      If (LookFor = "R")                                                      ; Name der Workbench
        ResultAdd := RecipeArray[2]                                           ; liegt unter "R" auf Platz zwei!
    }
  }
  
  Loop, Read, %AllThePlaceables%                                              ; read from csv
  {
    RecipeArray := StrSplit(A_LoopReadLine, ",")
    LookFor := RecipeArray[2]                                                 ; there is the Tag
    Temp := RecipeArray[1]                                                    ; this is the Name
    
    If (LookFor = ResultAdd)
      Result = %Temp% (%ResultAdd%)
  }
  
  RecipeArray = 
  LookFor = 
  Temp = 
  ResultAdd = 
  
  return Result
}
;================================================================================

;================================================================================
; ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
; from  >  M|sMenuBakeBreads  <
;================================================================================
ReturnWorkbenchMenuFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                              ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "M"
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
;           if "R"
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

;================================================================================
; ReturnRecipeListFromRecipe(ArrayTmpPath)
; from  >   R|sMenuBakeBreads|Roggenbrot|cnrRyeBread|1  <
;================================================================================
ReturnRecipeListFromRecipe(ArrayTmpPath)
{
  Loop, Read, %ArrayTmpPath%                                              ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "R"
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

;================================================================================
; ReturnComponentsFromRecipe(ProductToLookFor)                          ;time to do some loops!
; from  >  P1|Blank Scroll|cnrScrollBlank|1|ProductToLookFor  <
; sometimes  >  P4|Ray of Frost|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST|NW_IT_SPARSCR002  <
;================================================================================
ReturnComponentsFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result := ""
  
  Loop, Read, %AllTheArrays%                                       ; read from array, first loop
  {
    StringReplace, Temp, A_LoopReadLine, |, |, UseErrorLevel       ; count all tokens
    Tokens := ErrorLevel
    Temp := Tokens+1
    
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ProductTag := % RecipeArray[Temp]                             ; take a look at the last token
    
    If (Tokens <= 4)
      Temp := RecipeArray[5]
    Else
      Temp := RecipeArray[6]
    
;   if "P"
    IfInString, WhatKindOf, P                                      ; build up array for second loop
    {
      If (ProductTag = ProductToLookFor)
        SecLoop = %A_LoopReadLine%,%SecLoop%
      
      IfInString, SecLoop, ERROR
        StringTrimRight, SecLoop, SecLoop, 9                       ; delete Error-Msg, result not false!
    }
  }
  
  Loop, Parse, SecLoop, `,
  {
    If (A_LoopField != "")
    {
      StringReplace, Temp, A_LoopField, |, |, UseErrorLevel         ; count all tokens
      Tokens := ErrorLevel
      AddMe = 
      RecipeArray := StrSplit(A_LoopField, "|")                     ; P1|Blank Scroll|cnrScrollBlank|1|NW_IT_SPARSCR002
      
      If (Tokens <= 4)                                              ; component in smallest version
      {
        Tag := RecipeArray[3]
        NbrA := RecipeArray[4]
        AddMe = "%Tag%", %NbrA%
      }
      Else
      {
        IfInString, RecipeArray, CNR_RECIPE_SPELL
        {
          Tag := RecipeArray[4]
          NbrA := RecipeArray[5]
          AddMe = "CNR_RECIPE_SPELL", %Tag%, %NbrA%
        }
        ELse                                                        ; it something like this >P1|Empty Flask|cnrEmptyFlask|1|1|cnrAcidFlask< (if something goes wrong at creating product ingame
        {
          Tag := RecipeArray[3]
          NbrA := RecipeArray[4]
          NbrB := RecipeArray[5]
          AddMe = "%Tag%", %NbrA%, %NbrB%
        }
      }
      Result = %Result%CnrRecipeAddComponent(sKeyToRecipe, %AddMe%);`n
    }
  }
  
  AllTheArrays = 
  Temp = 
  Tokens = 
  RecipeArray = 
  WhatKindOf = 
  ProductTag = 
  SecLoop = 
  Tag = 
  NbrA = 
  NbrB = 
  AddMe = 
  
  return Result
}
;================================================================================

CompToArray(string) {
  string := ReturnComponentsFromRecipe(string)
  string := StrReplace(string, ";", "|")
  StringReplace, string, string, `n, , All
  
  return string
}

;================================================================================
; ReturnBiproductsFromRecipe(ProductToLookFor)                          ;time to do some loops!
; from  >  B1|cnrGlassVial|1|1|ProductToLookFor  <
;================================================================================
ReturnBiproductsFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result := ""
  
  Loop, Read, %AllTheArrays%                                       ; read from array, first loop
  {
    StringReplace, Temp, A_LoopReadLine, |, |, UseErrorLevel       ; count all tokens
    Tokens := ErrorLevel
    Temp := Tokens+1
    
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ProductTag := % RecipeArray[Temp]                             ; take a look at the last token
    
    If (Tokens <= 4)
      Temp := RecipeArray[5]
    Else
      Temp := RecipeArray[6]
    
;   if "B"
    IfInString, WhatKindOf, B                                      ; how many loops?
    {
      If (ProductTag = ProductToLookFor)
        SecLoop = %A_LoopReadLine%,%SecLoop%
      
      IfInString, SecLoop, ERROR
        StringTrimRight, SecLoop, SecLoop, 9                       ; delete Error-Msg, result not false!
    }
  }
  
  Loop, Parse, SecLoop, `,
  {
    If (A_LoopField != "")
    {
      StringReplace, Temp, A_LoopField, |, |, UseErrorLevel         ; count all tokens
      Tokens := ErrorLevel
      AddMe = 
      RecipeArray := StrSplit(A_LoopField, "|")                     ; B1|cnrGlassVial|1|1|ProductToLookFor
      
      If (Tokens <= 4)
      {
        Tag := RecipeArray[2]
        NbrA := RecipeArray[3]
        NbrB := RecipeArray[4]
        AddMe = "%Tag%", %NbrA%, %NbrB%
      }
      Else
      {
        Tag := RecipeArray[3]
        NbrA := RecipeArray[4]
        NbrB := RecipeArray[5]
        AddMe = "%Tag%", %NbrA%, %NbrB%
      }
      Result = %Result%CnrRecipeSetRecipeBiproduct(sKeyToRecipe, %AddMe%);`n
    }
  }
  
  AllTheArrays = 
  Temp = 
  Tokens = 
  RecipeArray = 
  WhatKindOf = 
  ProductTag = 
  SecLoop = 
  Tag = 
  NbrA = 
  NbrB = 
  AddMe = 
  
  return Result
}
;================================================================================

BiProdToArray(string) {
  string := ReturnBiproductsFromRecipe(string)
  string := StrReplace(string, ";", "|")
  StringReplace, string, string, `n, , All
  
  return string
}
;================================================================================
; ReturnLevelFromRecipe(ProductToLookFor)
; from  >  L|1|ProductToLookFor  <
;================================================================================
ReturnLevelFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR400
  Loop, Read, %AllTheArrays%                                       ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "L"
    If (WhatKindOf = "L")                                          ; Level string?
    {
      WhatKindOf := RecipeArray[3]                                 ; look for tag
      Temp := RecipeArray[2]                                       ; Level
      
      If (WhatKindOf = ProductToLookFor)
      {
        Result := Temp
        break
      }
      Else
        Result = ERROR401
    }
    Else
      Result := ""
  }
  
  AllTheArrays = 
  RecipeArray = 
  WhatKindOf = 
  Temp = 
  
  return Result
}
;================================================================================

;================================================================================
; ReturnXPFromRecipe(ProductToLookFor)
; from  >  X|10|10|ProductToLookFor  <
;================================================================================
ReturnXPFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR402
  Loop, Read, %AllTheArrays%                                       ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "X"
    If (WhatKindOf = "X")                                          ; EP fuers Erstellen des Produkts
    {
      WhatKindOf := RecipeArray[4]                                 ; look for tag
      RecipeCP := RecipeArray[2]
      RecipeXP := RecipeArray[3]
      
      If (WhatKindOf = ProductToLookFor)
      {
        Result = %RecipeCP%|%RecipeXP%
        break
      }
      Else
        Result = ERROR403
    }
    Else
      Result := ""
  }
  
  AllTheArrays = 
  RecipeArray = 
  WhatKindOf = 
  RecipeCP = 
  RecipeXP = 
  
  return Result
}
;================================================================================

;================================================================================
; ReturnAbilitysFromRecipe(ProductToLookFor)
; A|0|50|50|0|0|0|ProductToLookFor
;================================================================================
ReturnAbilitysFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR404
  Loop, Read, %AllTheArrays%                                       ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "A"
    If (WhatKindOf = "A")                                          ; Attribute festlegen  >A|0|50|50|0|0|0|ProductToLookFor
    {
      WhatKindOf := RecipeArray[8]                                 ; look for tag
      AbilityStr := RecipeArray[2]
      AbilityDex := RecipeArray[3]
      AbilityCon := RecipeArray[4]
      AbilityInt := RecipeArray[5]
      AbilityWis := RecipeArray[6]
      AbilityCha := RecipeArray[7]
      
      If (WhatKindOf = ProductToLookFor)
      {
        Result = %AbilityStr%|%AbilityDex%|%AbilityCon%|%AbilityInt%|%AbilityWis%|%AbilityCha%
        break
      }
      Else
       Result = ERROR405
    }
    Else
      Result := ""
  }
  
  AllTheArrays = 
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

;================================================================================
; GetWorkbenchName(ProductTagToLookFor)
;================================================================================
GetWorkbenchName(ProductTagToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR200
  
  Loop, Read, %AllTheArrays%                                ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    LookFor := RecipeArray[1]
;       if "R"
    If (LookFor = "R")                                      ; recipe found
    {
      Temp := RecipeArray[4]                                ; look for ResRef/Tag
      
      If (ProductTagToLookFor = Temp)
      {
        Result := RecipeArray[2]
        
        If (Result = ProductTagToLookFor)
          Result = ERROR201
      }
    }
  }
  
  AllTheArrays = 
  AllThePlaceables = 
  RecipeArray = 
  LookFor = 
  Temp = 
  
  return Result
}
;================================================================================

;================================================================================
; GetCreatedProductNbr(ProductTagToLookFor)
;================================================================================
GetCreatedProductNbr(ProductTagToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result = ERROR300
  
  Loop, Read, %AllTheArrays%                                ; lese nun die Array-Datei aus
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
;       if "R"
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
  
sKeyToRecipe = CnrRecipeCreateRecipe(sMenuLevel1Scrolls, "Ray of Frost", "NW_IT_SPARSCR002", 1);
CnrRecipeAddComponent(sKeyToRecipe, CNR_RECIPE_SPELL,1,SPELL_RAY_OF_FROST);
               CnrRecipeAddComponent(sKeyToRecipe, cnrGemDust001, 1);
               CnrRecipeAddComponent(sKeyToRecipe, cnrInkLConj, 1);
               CnrRecipeAddComponent(sKeyToRecipe, cnrScrollBlank, 1);
               CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);
               CnrRecipeSetRecipeLevel(sKeyToRecipe, 1);
               CnrRecipeSetRecipeXP(sKeyToRecipe, 10, 10);
               CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, 0, 0, 0, 50, 50, 0);
*/
;================================================================================
ReturnScriptSnippetForRecipe(ProductToShow)
{
  WB := GetWorkbenchName(ProductToShow)
  PD := GetObjectName(ProductToShow)
  TG := (ProductToShow)
  NB := GetCreatedProductNbr(ProductToShow)

  Result = sKeyToRecipe = CnrRecipeCreateRecipe(%WB%, "%PD%", "%TG%", %NB%);`n
  
  PX := ReturnComponentsFromRecipe(ProductToShow)
  If (PX != "")
    Result = %Result%%PX%

  BX := ReturnBiproductsFromRecipe(ProductToShow)
  If (BX != "")
    Result = %Result%%BX%
  
  LV := ReturnLevelFromRecipe(ProductToShow)
  If (LV != "")
    Result = %Result%CnrRecipeSetRecipeLevel(sKeyToRecipe, %LV%);`n
  
  XP := ReturnXPFromRecipe(ProductToShow)
  If (XP != "")
  {
    XP := StrReplace(XP, "|", ", ", ALL)
    Result = %Result%CnrRecipeSetRecipeXP(sKeyToRecipe, %XP%);`n
  }
  
  AB := ReturnAbilitysFromRecipe(ProductToShow)
  If (AB != "")
  {
    AB := StrReplace(AB, "|", ", ", ALL)
    Result = %Result%CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe, %AB%);`n
  }
  
  return Result
}
;================================================================================

;================================================================================
;  ReturnPlaceComponent(string)
;================================================================================
ReturnPlaceComponent(string)
{
  StringTrimLeft, string, string, 37
  string := StrReplace(string, Chr(34), "", ALL)
  string := StrReplace(string, ", ", "|", ALL)
  string := StrReplace(string, ");" , "", ALL)
  StringTrimRight, string, string, 1
  
  return string
}
;================================================================================

;================================================================================
;  ReturnPlaceBiProduct(string)
;================================================================================
ReturnPlaceBiProduct(string)
{
  StringTrimLeft, string, string, 43
  string := StrReplace(string, Chr(34), "", ALL)
  string := StrReplace(string, ", ", "|", ALL)
  string := StrReplace(string, ");" , "", ALL)
  StringTrimRight, string, string, 1
  
  return string
}


; ** function to retrieve HWNDs
GuiGetHWND(xxClassNN="", xxGUI=0) 
{ 
  If (xxGUI) 
    Gui, %xxGUI%:+LastFound 
  xxGui_hwnd := WinExist() 
  If xxClassNN= 
    Return, xxGui_hwnd 
  ControlGet, xxOutputVar, Hwnd,, %xxClassNN%, ahk_id %xxGui_hwnd% 
Return, xxOutputVar 
}