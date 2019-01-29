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
  temp := StrReplace(string, dem, dem, result)
  
  return result
}

;================================================================================
; GetObjectName(RecipientTag)
;================================================================================
GetObjectName(RecipientTag)
{
  Result = ERROR100
  StringLower, RecipientTag, RecipientTag
  
  Loop, Read, %A_WorkingDir%\tmp\array.tmp                                      ; search in array-file at first
  {
    itmarray := StrSplit(A_LoopReadLine, "|")
    resarray := itmarray[1]
    ; if "R"
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
  
  If (Result = "ERROR100")
  { 
    Result = ERROR101
    Loop, Read, %A_WorkingDir%\items.csv                                        ; search from csv-file then
    {
      itmarray := StrSplit(A_LoopReadLine, ",")
      resarray := % itmarray[2]
      tagarray := % itmarray[3]
      
      StringLower, resarray, resarray
      StringLower, tagarray, tagarray
      
      If (RecipientTag = resarray)
      {
        Result := % itmarray[1]
        Counted := CountTokens(Result, "(")
        
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
  ArrayTmp := FileOpen(FileForArray, "w")
  
  If !IsObject(ArrayTmp)
  {
    MsgBox Can't open "%FileName%" for writing.
    Return
  }
  
  Loop, Read, %FileToParse%                                                      ; add all SubMenues from "CnrRecipeAddSubMenu"  to   >M|<
  {
    IfInString, A_LoopReadLine, CnrRecipeAddSubMenu
    {
      StringReplace, SubMenuResult, A_LoopReadLine, %A_SPACE%, , All             ; delete all spaces        >stringsMenuForgeMetal=CnrRecipeAddSubMenu("cnrForgePublic","Metall");
      
      StringGetPos, Count, SubMenuResult, =                                      ; should be 22
      Length := StrLen(SubMenuResult)                                            ; should be 69
      Count := Length-Count                                                      ; 69 - 22 = 47
      
      StringTrimRight, SubMenuResult, SubMenuResult, Count                       ; reduce from rigth        >stringsMenuForgeMetal
      StringTrimLeft, SubMenuResult, SubMenuResult, 6                            ; reduce from left         >sMenuForgeMetal
      
      SubMenuResult = M|%SubMenuResult%`n
      
      If (SubMenuResult != "")
        ArrayTmp.Write(SubMenuResult)
    }
    
    IfInString, A_LoopReadLine, CnrRecipeSetDeviceTradeskillType                 ; add Workbench from "CnrRecipeSetDeviceTradeskillType"  to >N|<
    {
      If (RecipeWorkbench = "")                                                  ; stop, if line already exist
      {
        ; get the line workable
        RecipeWorkbench := StrReplace(A_LoopReadLine, Chr(34), "", ALL)          ; delete every "           >  CnrRecipeSetDeviceTradeskillType   (cnrCarpsBench, CNR_TRADESKILL_WOOD_CRAFTING);<
        
        StringGetPos, Count, RecipeWorkbench, ( 
        StringTrimLeft, RecipeWorkbench, RecipeWorkbench, Count+1                ; delete                   >  CnrRecipeSetDeviceTradeskillType   (<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ", ", "|", ALL)           ; replace , & space with | >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING);<
        RecipeWorkbench := StrReplace(RecipeWorkbench, ");" , "", ALL)           ; delete );                >cnrCarpsBench|CNR_TRADESKILL_WOOD_CRAFTING<
        
        IfInString, RecipeWorkbench, */
          RecipeWorkbench := StrReplace(RecipeWorkbench, "*/", "", ALL)          ; delete ggf. */ 
          
        WorkbenchArray := StrSplit(RecipeWorkbench, "|")
        RecipeWorkbench := WorkbenchArray[1]                                     ; workbench at array nbr 1
        
        IfInString, RecipeWorkbench, //                                          ; delete comments
        {
          StringGetPos, Count, RecipeWorkbench, //
          StringLeft, RecipeWorkbench, RecipeWorkbench, Count
        }
        
        RecipeWorkbench = N|%RecipeWorkbench%`n
        If (RecipeWorkbench != "")
          ArrayTmp.Write(RecipeWorkbench)
      }
    }
    
    IfInString, A_LoopReadLine, CnrRecipeCreateRecipe                            ; add Recipe from "CnrRecipeCreateRecipe"  to  >R|<
    {
      RecipeRef =                                                                ; new recipe beginning, reset references
      ; get the line workable
      RecipeResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)               ; delete every "           >  sKeyToRecipe = CnrRecipeCreateRecipe(cnrWaterTub, Filled Water Bucket, cnrBucketWater, 1);<
      
      StringGetPos, Count, RecipeResult, ( 
      StringTrimLeft, RecipeResult, RecipeResult, Count+1                        ; delete                   >  sKeyToRecipe = CnrRecipeCreateRecipe(<
      Counted := CountTokens(RecipeResult, ")")                                  ; count ")"                >  sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain (20)", "cnrArwHeadPlain", 1);  <
      
      If (Counted > 1)                                                           ;                          > sKeyToRecipe = CnrRecipeCreateRecipe(
      {
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)                 ; delete );                >sMenuTinkerArrowheads, Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, ", " , "|", , 1)                ; replace one , & space    >sMenuTinkerArrowheads|Arrowheads, Plain (20), cnrArwHeadPlain, 1
        RecipeResult := StrReplace(RecipeResult, "), " , ")|", , 1)              ; replace one ), & space   >sMenuTinkerArrowheads|Arrowheads, Plain (20)|cnrArwHeadPlain, 1
        StringGetPos, Count, RecipeResult, )|                                    ; count to ,   => 32       >sMenuTinkerArrowheads|Arrowheads, Plain (20>)|<cnrArwHeadPlain, 1
        RecipeResult := RegExReplace(RecipeResult, ", ", "|", , , Count+1)       ; replace this ", & space"
      }
      
      Else                                                                       ; > sKeyToRecipe = CnrRecipeCreateRecipe(sMenuTinkerArrowheads, "Arrowheads, Plain", "cnrArwHeadPlain", 1);
      {
        RecipeResult := StrReplace(RecipeResult, ", ", "|", ALL)                 ; replace , & space with | >cnrWaterTub|Filled Water Bucket|cnrBucketWater|1);<
        RecipeResult := StrReplace(RecipeResult, ");" , "", ALL)                 ; delete );                >cnrWaterTub,Filled Water Bucket,cnrBucketWater,1
      }
      
      IfInString, RecipeResult, */
        RecipeResult := StrReplace(RecipeResult, "*/", "", ALL)                  ; delete ggf. */
      
      IfInString, RecipeResult, //                                               ; delete comments
      {
        StringGetPos, Count, RecipeResult, //
        StringLeft, RecipeResult, RecipeResult, Count
      }
      
      IfInString, RecipeResult, GetObjectName                                    ; sMenuMythArmors|GetObjectName(NW_MAARCL037)|NW_MAARCL037|1
      {
        TempArray := StrSplit(RecipeResult, "|")                                 ; create array
        Replace := TempArray[2]                                                  ; look for "GetObjectName(NW_MAARCL037)"
        StringTrimLeft, ReplaceText, Replace, 14
        StringTrimRight, ReplaceText, ReplaceText, 1
        RecipeRef := ReplaceText
        
        ReplaceText := GetObjectName(ReplaceText)                                ; get the right name
        RecipeResult := StrReplace(RecipeResult, Replace, ReplaceText)           ; set it
      }
      
      RecipeResult = R|%RecipeResult%`n                                          ; result =>R|sMenuLevel5Scrolls|Dismissal|X1_IT_SPARSCR502|1
      
      If (RecipeRef = "")
      {
        TempArray := StrSplit(RecipeResult, "|")                                 ; create array
        RecipeRef := TempArray[4]                                                ; look for tag and set that as reference
      }
      
      If (RecipeResult != "")
        ArrayTmp.Write(RecipeResult)
      CountedPs := 0                                                             ; new recipe, so set to zero!
      CountedBs := 0
    }
    
    IfInString, A_LoopReadLine, CnrRecipeAddComponent                            ; add comPonents from "CnrRecipeAddComponent"  to  >P#|<
    {
      ; get the line workable
      ComponentResult := StrReplace(A_LoopReadLine, Chr(34), "", ALL)            ; delete every "           >  CnrRecipeAddComponent(sKeyToRecipe, cnrBucketEmpty, 1);
      
      StringGetPos, Count, ComponentResult, `,
      StringTrimLeft, ComponentResult, ComponentResult, Count                    ; delete                   >  CnrRecipeAddComponent(sKeyToRecipe
      ComponentResult := StrReplace(ComponentResult, ", ", "|", ALL)             ; replace , & space with | >|cnrBucketEmpty| 1);
      ComponentResult := StrReplace(ComponentResult, ");" , "", ALL)             ; delete );                >|cnrBucketEmpty| 1
      
      IfInString, ComponentResult, */
        ComponentResult := StrReplace(ComponentResult, "*/", "", ALL)            ; delete ggf. */
      
      IfInString, ComponentResult, //                                            ; delete ggf. kommentare
      {
        StringGetPos, Count, ComponentResult, //
        StringLeft, ComponentResult, ComponentResult, Count
      }
      
      ComponentResult := StrReplace(ComponentResult, A_Space , "", ALL)          ; delete space             >|cnrBucketEmpty|1
      
      StringGetPos, Count, ComponentResult, |, , 1                               ; search for |
      Length := StrLen(ComponentResult)                                          ; length of string
      Count := Length-Count
      
      StringTrimLeft, ProductResult, ComponentResult, 1                          ; delete first |           >NW_MAARCL078|1|1
      StringTrimRight, ProductResult, ProductResult, Count                       ; delete after last |      >NW_MAARCL078
      
      IfInString, ComponentResult, CNR_RECIPE_SPELL                              ; P4|ERROR011|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST
      {
        TempArray := StrSplit(ComponentResult, "|")                              ; create array
        Replace := TempArray[4]                                                  ; read const int SPELL_RAY_OF_FROST
        
        RecipeProduct := GetSpellName(Replace)                                   ; replace name
      }
      Else
        RecipeProduct := GetObjectName(ProductResult)
      
      CountedPs := CountedPs+1
      ComponentResult = P%CountedPs%|%RecipeProduct%%ComponentResult%|%RecipeRef%`n
      If (ComponentResult != "") 
        ArrayTmp.Write(ComponentResult)
    }
    
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeBiproduct                      ; add Biproducts from "CnrRecipeSetRecipeBiproduct"  to  >B#|<
    {
      ; get the line workable
      Temp := A_LoopReadLine                                                     ; save in temp             >  CnrRecipeSetRecipeBiproduct(sKeyToRecipe, "cnrGlassVial", 1, 1);
      
      StringGetPos, Count, Temp, `,                                              ; get first "," => 42
      StringTrimLeft, Temp, Temp, Count+3                                        ; reduce to ","+1          >cnrGlassVial", 1, 1);
      StringGetPos, Count, Temp, `,                                              ; get second "," => 13
      Length := StrLen(Temp)                                                     ; count string length => 21
      Count := Length-Count                                                      ; 21-13 = 8
      
      StringTrimRight, BiProduct, Temp, Count+1                                  ; reduce to                >cnrGlassVial
      
      Length := StrLen(BiProduct)                                                ; get string length
      StringTrimLeft, Qty, Temp, Length+3                                        ; reduce to                >1, 1);
      
      Qty := StrReplace(Qty, ", ", "|", ALL)                                     ; replace , & space with | >1|1);
      StringTrimRight, Qty, Qty, 2                                               ; reduce to                >1|1
      
      CountedBs := CountedBs+1
      BiProductResult = B%CountedBs%|%BiProduct%|%Qty%|%RecipeRef%`n
      If (BiProductResult != "")
        ArrayTmp.Write(BiProductResult)
    }
    
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeLevel                          ; add Level from "CnrRecipeSetRecipeLevel"  to  >L|<
    {
      ; get the line workable
      LevelResult := A_LoopReadLine
      
      StringTrimRight, LevelResult, LevelResult, 2                               ; reduce last two digits   >  CnrRecipeSetRecipeLevel(sKeyToRecipe, 18
      StringGetPos, Count, LevelResult, `,                                       ; get first "," => 38
      
      StringTrimLeft, LevelResult, LevelResult, Count+2                          ; delete to ","+2          >18
      
      LevelResult = L|%LevelResult%|%RecipeRef%`n
      If (LevelResult != "")
        ArrayTmp.Write(LevelResult)
    }
    
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeXP                             ; add XP from "CnrRecipeSetRecipeXP"  to  >X|<
    {
      ; get the line workable
      XpResult := A_LoopReadLine
      
      StringGetPos, Count, XpResult, `,
      StringTrimLeft, XpResult, XpResult, Count                                  ; delete                   >  CnrRecipeSetRecipeXP(sKeyToRecipe
      XpResult := StrReplace(XpResult, ", ", "|", ALL)                           ; replace , & space mit |  >| 5| 5);
      XpResult := StrReplace(XpResult, ");" , "", ALL)                           ; delete );                >| 5| 5
      
      IfInString, XpResult, */
        XpResult := StrReplace(XpResult, "*/", "", ALL)                          ; delete */
      
      IfInString, XpResult, //
      {
        StringGetPos, Count, XpResult, //
        StringLeft, XpResult, XpResult, Count
      }
      
      XpResult := StrReplace(XpResult, A_Space , "", ALL)                        ; delete space             >|5|5
      XpResult = X%XpResult%|%RecipeRef%`n
      If (XpResult != "")
        ArrayTmp.Write(XpResult)
    }
    
    IfInString, A_LoopReadLine, CnrRecipeSetRecipeAbilityPercentages             ; add Abilities from "CnrRecipeSetRecipeAbilityPercentages"  to  >A|<
    {
      ; get the line workable
      AbsResult := A_LoopReadLine
      
      StringGetPos, Count, AbsResult, `,
      StringTrimLeft, AbsResult, AbsResult, Count                                ; delete                   >  CnrRecipeSetRecipeAbilityPercentages(sKeyToRecipe
      AbsResult := StrReplace(AbsResult, ", ", "|", ALL)                         ; replace , & space mit |  >| 0| 0|40| 0|60| 0);
      AbsResult := StrReplace(AbsResult, ");" , "", ALL)                         ; delete );                >| 0| 0|40| 0|60| 0
      
      IfInString, AbsResult, */
        AbsResult := StrReplace(AbsResult, "*/", "", ALL)                        ; delete */
      
      IfInString, AbsResult, //
      {
        StringGetPos, Count, AbsResult, //
        StringLeft, AbsResult, AbsResult, Count
      }
      
      AbsResult := StrReplace(AbsResult, A_Space , "", ALL)                      ; delete space             >|0|0|40|0|60|0
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
  
  ArrayTmp.Close()                                                               ; array was saved, so close file
}
;================================================================================

;================================================================================
; ReturnWorkbenchFromRecipe(ArrayTmpPath)
; from  >  N|cnrBakersOven <
;================================================================================
ReturnWorkbenchFromRecipe(ArrayTmpPath)
{
  AllThePlaceables := A_WorkingDir . "\plcs.csv"
  Loop, Read, %ArrayTmpPath%                                                     ; read array-file
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    LookFor := RecipeArray[1]
    ; if "N"
    If (LookFor = "N")                                                           ; name of workbench
      ResultAdd := RecipeArray[2]                                                ; is at nbr 2 for "N"
  }
  
  If (ResultAdd = "")                                                            ; no workbench found, search at recipe 
  {
    Loop, Read, %ArrayTmpPath%                                                   ; read array-file
    {
      RecipeArray := StrSplit(A_LoopReadLine, "|")
      LookFor := RecipeArray[1]
      ; if "R"
      If (LookFor = "R")                                                         ; name of workbench
        ResultAdd := RecipeArray[2]                                              ; get from "R"ecipe at nbr 2
    }
  }
  
  Loop, Read, %AllThePlaceables%                                                 ; read from csv
  {
    RecipeArray := StrSplit(A_LoopReadLine, ",")
    LookFor := RecipeArray[2]                                                    ; get the Tag
    Temp := RecipeArray[1]                                                       ; get the Name
    
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
  Loop, Read, %ArrayTmpPath%                                                     ; read array-file
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "M"
    If (WhatKindOf = "M")                                                        ; name of workbench
    {
      Workbench := RecipeArray[2]                                                ; at nbr two from "M"
      
      IfNotInString, Result, Workbench                                           ; add it, if its not here
        Result = %Workbench%|%Result%
    }
  }
  
  If (Result = "")                                                               ; no workbench found, search at recipe 
  {
    Loop, Read, %ArrayTmpPath%                                                   ; read array-file
    {
      RecipeArray := StrSplit(A_LoopReadLine, "|")
      WhatKindOf := RecipeArray[1]
      ; if "R"
      If (WhatKindOf = "R")                                                      ; name of workbench
        Result := RecipeArray[2]                                                 ; is at nbr 2 for "N"
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
  Loop, Read, %ArrayTmpPath%                                                     ; read array-file
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "R"
    If (WhatKindOf = "R")                                                        ; recipe beginning
    {
      RecipeProduct    := RecipeArray[3]                                         ; Name of procuct
      RecipeProductTag := RecipeArray[4]                                         ; ResRef/Tag of product
      
      IfInString, RecipeProduct, GetObjectName                                   ; is GetObjectName in string? replace it
        RecipeProduct := GetObjectName(RecipeProductTag)
      
      RecipeProductNbr := RecipeArray[5]                                         ; nbr of products
      
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
; ReturnComponentsFromRecipe(ProductToLookFor)
; from  >  P1|Blank Scroll|cnrScrollBlank|1|ProductToLookFor  <
; sometimes  >  P4|Ray of Frost|CNR_RECIPE_SPELL|1|SPELL_RAY_OF_FROST|NW_IT_SPARSCR002  <
;================================================================================
ReturnComponentsFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result := ""
  
  Loop, Read, %AllTheArrays%                                                     ; read from array, first loop
  {
    Tokens := CountTokens(A_LoopReadLine, "|")                                   ; count all tokens
    Temp := Tokens+1
    
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ProductTag := % RecipeArray[Temp]                                            ; take a look at the last token
    
    If (Tokens <= 4)
      Temp := RecipeArray[5]
    Else
      Temp := RecipeArray[6]
    
    ; if "P"
    IfInString, WhatKindOf, P                                                    ; build up array for second loop
    {
      If (ProductTag = ProductToLookFor)
        SecLoop = %A_LoopReadLine%,%SecLoop%
      
      IfInString, SecLoop, ERROR
        StringTrimRight, SecLoop, SecLoop, 9                                     ; delete Error-Msg, result should not contain false!
    }
  }
  
  Loop, Parse, SecLoop, `,
  {
    If (A_LoopField != "")
    {
      Tokens := CountTokens(A_LoopField, "|")                                    ; count all tokens
      AddMe = 
      RecipeArray := StrSplit(A_LoopField, "|")                                  ; P1|Blank Scroll|cnrScrollBlank|1|NW_IT_SPARSCR002
      
      If (Tokens <= 4)                                                           ; component in array
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
        ELse                                                                     ; it's something like this >P1|Empty Flask|cnrEmptyFlask|1|1|cnrAcidFlask< (if something goes wrong at creating product ingame
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
; ReturnBiproductsFromRecipe(ProductToLookFor)
; from  >  B1|cnrGlassVial|1|1|ProductToLookFor  <
;================================================================================
ReturnBiproductsFromRecipe(ProductToLookFor)
{
  AllTheArrays := A_WorkingDir . "\tmp\array.tmp"
  Result := ""
  
  Loop, Read, %AllTheArrays%                                                     ; read from array, first loop
  {
    Tokens := CountTokens(A_LoopReadLine, "|")                                   ; count all tokens
    Temp := Tokens+1
    
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ProductTag := % RecipeArray[Temp]                                            ; take a look at the last token
    
    If (Tokens <= 4)
      Temp := RecipeArray[5]
    Else
      Temp := RecipeArray[6]
    
    ; if "B"
    IfInString, WhatKindOf, B                                                    ; how many loops?
    {
      If (ProductTag = ProductToLookFor)
        SecLoop = %A_LoopReadLine%,%SecLoop%
      
      IfInString, SecLoop, ERROR
        StringTrimRight, SecLoop, SecLoop, 9                                     ; delete Error-Msg, result not false!
    }
  }
  
  Loop, Parse, SecLoop, `,
  {
    If (A_LoopField != "")
    {
      Tokens := CountTokens(A_LoopField, "|")                                    ; count all tokens
      AddMe = 
      RecipeArray := StrSplit(A_LoopField, "|")                                  ; B1|cnrGlassVial|1|1|ProductToLookFor
      
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
  Loop, Read, %AllTheArrays%                                                     ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "L"
    If (WhatKindOf = "L")                                                        ; Level string?
    {
      WhatKindOf := RecipeArray[3]                                               ; look for tag
      Temp := RecipeArray[2]                                                     ; Level
      
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
  Loop, Read, %AllTheArrays%                                                     ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "X"
    If (WhatKindOf = "X")                                                        ; EP fuers Erstellen des Produkts
    {
      WhatKindOf := RecipeArray[4]                                               ; look for tag
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
  Loop, Read, %AllTheArrays%                                                     ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "A"
    If (WhatKindOf = "A")                                                        ; Attribute festlegen  >A|0|50|50|0|0|0|ProductToLookFor
    {
      WhatKindOf := RecipeArray[8]                                               ; look for tag
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
  Count := InStr(LookAndTrim, " (")-1                                            ; GetObjectName> (<bf_ioun_lightred ) (bf_ioun_lightred) [1]
  StringTrimLeft, LookAndTrim, LookAndTrim, Count                                ;  (hw_it_mpotion024) [1]
  
  Count := CountTokens(LookAndTrim, ")")                                         ; count how many ")" are in this string >  (20) (cnrArwHeadBlunt) [1]  <
  If (Count > 1)
  {
    Count := InStr(LookAndTrim, ") ")+2                                          ; get first ) & space +2
    StringTrimLeft, LookAndTrim, LookAndTrim, Count                              ; reduziere bis dahin
  }
  
  LookAndTrim := StrReplace(LookAndTrim, " (", "", ALL)                          ; hw_it_mpotion024) [1]
  LookAndTrim := StrReplace(LookAndTrim, ")", "", ALL)                           ; hw_it_mpotion024 [1]
  
  Count := InStr(LookAndTrim, " [")-1                                            ; bf_ioun_lightred [1]
  Count := StrLen(LookAndTrim) - Count                                           ; bf_ioun_lightred<[1]>
  StringTrimRight, LookAndTrim, LookAndTrim, Count                               ; bf_ioun_lightred
  
  Count = 
  
  return LookAndTrim
}
;================================================================================

;================================================================================
; TrimToGetProduct(LookAndTrim)
;================================================================================
TrimToGetProduct(LookAndTrim)
{
  IfInString, LookAndTrim, GetObjectName                                         ; is GetObjectName in string
  {
    LookAndTrim := TrimToGetTag(LookAndTrim)
    LookAndTrim := GetObjectName(LookAndTrim)
  }
  
  Else
  {
    Count := CountTokens(LookAndTrim, ")")                                       ; count all ")"   =>  Arrowheads, Blunt (20) (cnrArwHeadBlunt) [1]  <
    If (Count > 1)                                                               ; Arrowheads, Blunt (20) (cnrArwHeadBlunt) [1]
      Count := InStr(LookAndTrim, ") ", R)                                       ; get position of last ") & space"
    Else
      Count := InStr(LookAndTrim, " (", R)                                       ; Filled Water Bucket (cnrBucketWater)  > TrimToGetProduct: 20 |36 | Filled Water Bucket (cnrBucketWater)
    
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
  
  Loop, Read, %AllTheArrays%                                                     ; read from array
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    LookFor := RecipeArray[1]
    ; if "R"
    If (LookFor = "R")                                                           ; recipe found
    {
      Temp := RecipeArray[4]                                                     ; look for ResRef/Tag
      
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
  
  Loop, Read, %AllTheArrays%                                                     ; read array-file
  {
    RecipeArray := StrSplit(A_LoopReadLine, "|")
    WhatKindOf := RecipeArray[1]
    ; if "R"
    If (WhatKindOf = "R")                                                        ; recipe beginning
    {
      RecipeProductTag := RecipeArray[4]                                         ; get ResRef/Tag
      
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
  Result = 0                                                                     ; reset and now count all the tokens in array
  CountedTokens := CountTokens(WorkbenchMenuToLookAt, "|")                       ; => 8                     > sMenuAltarSceptre|sMenuAltarStaves|sMenuAltarRods|sMenuAltarGreIou|sMenuAltarLesIou|sMenuAltarLight|sMenuAltarEnchMat|sMenuAltarBags|
  StringGetPos, Temp, WorkbenchMenuToLookAt, %ProductTagToLookFor%               ; => 50
  StringTrimLeft, Temp, WorkbenchMenuToLookAt, Temp                              ; reduce from 50
  NewCountedTokens := CountTokens(Temp, "|")                                     ; count last tokens => 5
  Result := CountedTokens-NewCountedTokens                                       ; get position
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

ReturnWasSomethingChanged(string, token)
{
  result := 0
  
  
  
  return result
}

RemoveUnessesaries(string)
{
    string := StrReplace(string, Chr(34), "", ALL)
    StringReplace, string, string, %A_SPACE%, , All
    string := StrReplace(string, ",", "", ALL)
    string := StrReplace(string, ")", "", ALL)
    string := StrReplace(string, "(", "", ALL)
    string := StrReplace(string, "#", "", ALL)
    string := StrReplace(string, ":", "", ALL)
    string := StrReplace(string, "-", "", ALL)
    
  return string
}

