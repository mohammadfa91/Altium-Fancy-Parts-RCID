//Developed by AmirMohammad Farahi
procedure ConvertResistorValuesToCode;
var
    schDoc      : ISch_Document;
    comp        : ISch_Component;
    compIter    : ISch_Iterator;
    paramIter   : ISch_Iterator;
    param       : ISch_Parameter;
    codeParam   : ISch_Parameter;
    resistorVal : String;
    codeVal     : String;
    resistance  : Double;
    digits      : String;
    exponent    : Integer;
    compLibRef  : String;
    int_part    : Integer;
    frac_part   : Double;
    frac_str    : String;
    digitsStr   : String;
    Kpos        : Integer;
    Mpos        : Integer;
    Rpos        : Integer;
    adjustedExponent, decimalPlaces: Integer;
    tolerance   : String;
    OnePercentAccuracy :Boolean;
    EIA_96      :Boolean;
  function GetEIA96SMDCode(Resistance: Double): string;
  var
    EIA96_VALUES: array[1..96] of Integer;
    EIA96_MULTIPLIERS: array[0..8] of Char;
    EIA96_MULTIPLIER_POWERS: array[0..8] of Integer;
    i, j: Integer;
    MinError: Double;
    CurrentError: Double;
    CalculatedValue: Double;
    ValueIndex: Integer;
    MultiplierIndex: Integer;
  begin
    Result := '';
    if Resistance <= 0 then Exit;

    // Initialize EIA-96 values
    EIA96_VALUES[1] := 100; EIA96_VALUES[2] := 102; EIA96_VALUES[3] := 105; EIA96_VALUES[4] := 107;
    EIA96_VALUES[5] := 110; EIA96_VALUES[6] := 113; EIA96_VALUES[7] := 115; EIA96_VALUES[8] := 118;
    EIA96_VALUES[9] := 121; EIA96_VALUES[10] := 124; EIA96_VALUES[11] := 127; EIA96_VALUES[12] := 130;
    EIA96_VALUES[13] := 133; EIA96_VALUES[14] := 137; EIA96_VALUES[15] := 140; EIA96_VALUES[16] := 143;
    EIA96_VALUES[17] := 147; EIA96_VALUES[18] := 150; EIA96_VALUES[19] := 154; EIA96_VALUES[20] := 158;
    EIA96_VALUES[21] := 162; EIA96_VALUES[22] := 165; EIA96_VALUES[23] := 169; EIA96_VALUES[24] := 174;
    EIA96_VALUES[25] := 178; EIA96_VALUES[26] := 182; EIA96_VALUES[27] := 187; EIA96_VALUES[28] := 191;
    EIA96_VALUES[29] := 196; EIA96_VALUES[30] := 200; EIA96_VALUES[31] := 205; EIA96_VALUES[32] := 210;
    EIA96_VALUES[33] := 215; EIA96_VALUES[34] := 221; EIA96_VALUES[35] := 226; EIA96_VALUES[36] := 232;
    EIA96_VALUES[37] := 237; EIA96_VALUES[38] := 243; EIA96_VALUES[39] := 249; EIA96_VALUES[40] := 255;
    EIA96_VALUES[41] := 261; EIA96_VALUES[42] := 267; EIA96_VALUES[43] := 274; EIA96_VALUES[44] := 280;
    EIA96_VALUES[45] := 287; EIA96_VALUES[46] := 294; EIA96_VALUES[47] := 301; EIA96_VALUES[48] := 309;
    EIA96_VALUES[49] := 316; EIA96_VALUES[50] := 324; EIA96_VALUES[51] := 332; EIA96_VALUES[52] := 340;
    EIA96_VALUES[53] := 348; EIA96_VALUES[54] := 357; EIA96_VALUES[55] := 365; EIA96_VALUES[56] := 374;
    EIA96_VALUES[57] := 383; EIA96_VALUES[58] := 392; EIA96_VALUES[59] := 402; EIA96_VALUES[60] := 412;
    EIA96_VALUES[61] := 422; EIA96_VALUES[62] := 432; EIA96_VALUES[63] := 442; EIA96_VALUES[64] := 453;
    EIA96_VALUES[65] := 464; EIA96_VALUES[66] := 475; EIA96_VALUES[67] := 487; EIA96_VALUES[68] := 499;
    EIA96_VALUES[69] := 511; EIA96_VALUES[70] := 523; EIA96_VALUES[71] := 536; EIA96_VALUES[72] := 549;
    EIA96_VALUES[73] := 562; EIA96_VALUES[74] := 576; EIA96_VALUES[75] := 590; EIA96_VALUES[76] := 604;
    EIA96_VALUES[77] := 619; EIA96_VALUES[78] := 634; EIA96_VALUES[79] := 649; EIA96_VALUES[80] := 665;
    EIA96_VALUES[81] := 681; EIA96_VALUES[82] := 698; EIA96_VALUES[83] := 715; EIA96_VALUES[84] := 732;
    EIA96_VALUES[85] := 750; EIA96_VALUES[86] := 768; EIA96_VALUES[87] := 787; EIA96_VALUES[88] := 806;
    EIA96_VALUES[89] := 825; EIA96_VALUES[90] := 845; EIA96_VALUES[91] := 866; EIA96_VALUES[92] := 887;
    EIA96_VALUES[93] := 909; EIA96_VALUES[94] := 931; EIA96_VALUES[95] := 953; EIA96_VALUES[96] := 976;

    // Initialize multiplier data
    EIA96_MULTIPLIERS[0] := 'Z'; EIA96_MULTIPLIERS[1] := 'R'; EIA96_MULTIPLIERS[2] := 'S';
    EIA96_MULTIPLIERS[3] := 'A'; EIA96_MULTIPLIERS[4] := 'B'; EIA96_MULTIPLIERS[5] := 'C';
    EIA96_MULTIPLIERS[6] := 'D'; EIA96_MULTIPLIERS[7] := 'E'; EIA96_MULTIPLIERS[8] := 'F';

    EIA96_MULTIPLIER_POWERS[0] := -3; EIA96_MULTIPLIER_POWERS[1] := -2; EIA96_MULTIPLIER_POWERS[2] := -1;
    EIA96_MULTIPLIER_POWERS[3] := 0; EIA96_MULTIPLIER_POWERS[4] := 1; EIA96_MULTIPLIER_POWERS[5] := 2;
    EIA96_MULTIPLIER_POWERS[6] := 3; EIA96_MULTIPLIER_POWERS[7] := 4; EIA96_MULTIPLIER_POWERS[8] := 5;

    MinError := MaxDouble;
    ValueIndex := 1;
    MultiplierIndex := 0;

    // Find the closest EIA-96 value and multiplier combination
    for i := 1 to 96 do
    begin
      for j := 0 to 8 do
      begin
        CalculatedValue := EIA96_VALUES[i] * Power(10, EIA96_MULTIPLIER_POWERS[j]);
        CurrentError := Abs(Resistance - CalculatedValue) / Resistance;

        if CurrentError < MinError then
        begin
          MinError := CurrentError;
          ValueIndex := i;
          MultiplierIndex := j;
        end;
      end;
    end;

    // Format the code: two digits for value index (01-96) + multiplier letter
    Result := Format('%.2d%s', [ValueIndex, EIA96_MULTIPLIERS[MultiplierIndex]]);
  end;
begin
    schDoc := SchServer.GetCurrentSchDocument;
    if schDoc = nil then Exit;

    compIter := schDoc.SchIterator_Create;
    if compIter = nil then Exit;

    try
        compIter.SetState_IterationDepth(eIterateFirstLevel);
        compIter.AddFilter_ObjectSet(MkSet(eSchComponent));
        comp := compIter.FirstSchObject;
        while comp <> nil do
        begin
            compLibRef := comp.LibReference;

            if (compLibRef = 'R_SMD') then
            begin
                codeVal := 'XXX';
                codeParam := nil;
                OnePercentAccuracy := false;
                EIA_96 := false;

                paramIter := comp.SchIterator_Create;
                if paramIter <> nil then
                begin
                    try
                        paramIter.AddFilter_ObjectSet(MkSet(eParameter));
                        param := paramIter.FirstSchObject;
                        while param <> nil do
                        begin
                            if SameText(param.Name, 'Value') then
                            begin
                                resistorVal := StringReplace(param.Text, ' ', '', MkSet(rfReplaceAll));
                                resistorVal := StringReplace(resistorVal, 'O', '', MkSet(rfReplaceAll));
                                resistorVal := StringReplace(resistorVal, 'k', 'K', MkSet(rfIgnoreCase));

                                Kpos := pos('K', resistorVal);
                                if Kpos > 0 then
                                begin
                                    if (Kpos = Length(resistorVal)) then
                                        resistorVal := StringReplace(resistorVal, 'K', 'e3', MkSet(rfReplaceAll))
                                    else
                                    begin
                                        resistorVal := StringReplace(resistorVal, 'K', '.', MkSet(rfReplaceAll));
                                        resistorVal := resistorVal + 'e3';
                                    end;
                                end;

                                Mpos := pos('M', resistorVal);
                                if Mpos > 0 then
                                begin
                                    if (Mpos = Length(resistorVal)) then
                                        resistorVal := StringReplace(resistorVal, 'M', 'e6', MkSet(rfReplaceAll))
                                    else
                                    begin
                                        resistorVal := StringReplace(resistorVal, 'M', '.', MkSet(rfReplaceAll));
                                        resistorVal := resistorVal + 'e6';
                                    end;
                                end;

                                Rpos := pos('R', resistorVal);
                                if Rpos > 0 then
                                begin
                                    if (Rpos = Length(resistorVal)) then
                                        resistorVal := StringReplace(resistorVal, 'R', '', MkSet(rfReplaceAll))
                                    else
                                        resistorVal := StringReplace(resistorVal, 'R', '.', MkSet(rfReplaceAll));
                                end;

                                resistorVal := StringReplace(resistorVal, 'm', 'e-3', MkSet(rfReplaceAll));
                            end;

                            if SameText(param.Name, 'Tolerance') then
                            begin
                                tolerance := param.Text;
                                if pos('1%', tolerance)>0 then
                                begin
                                      OnePercentAccuracy := true;
                                end;
                            end;

                            if SameText(param.Name, 'EIA-96') then
                            begin
                                tolerance := param.Text;
                                if pos('1', tolerance)>0 then
                                begin
                                      EIA_96 := true;
                                end;
                            end;
                            if SameText(param.Name, 'Code') then
                            begin
                                codeParam := param;
                            end;
                            param := paramIter.NextSchObject;
                        end;

                        if (resistorVal <> 'XXX') then
                        begin
                            try
                                resistance := StrToFloatDef(resistorVal, 0.0);
                            except
                                ShowMessage('Invalid resistor value: ' + resistorVal);
                                resistance := -1;
                            end;

                            if resistance = 0 then
                            begin
                                codeVal := ' 000';
                            end;

                            if resistance > 0 then
                            begin
                            if EIA_96 then
                            begin
                                  codeVal :=  GetEIA96SMDCode(resistance);
                            end
                            else
                            begin
                                if resistance >= 10 then
                                begin
                                    exponent := 0;

                                    if OnePercentAccuracy then
                                    begin
                                        while resistance >= 1000 do
                                        begin
                                            resistance := resistance / 10;
                                            Inc(exponent);
                                        end;
                                    end
                                    else
                                    begin
                                        while resistance >= 100 do
                                        begin
                                            resistance := resistance / 10;
                                            Inc(exponent);
                                        end;
                                    end;

                                    digitsStr := FormatFloat('0.##', resistance);

                                    decimalPlaces := 0;
                                    if Pos('.', digitsStr) > 0 then
                                    begin
                                        decimalPlaces := Length(Copy(digitsStr, Pos('.', digitsStr) + 1, 3));
                                    end;

                                    digits := StringReplace(digitsStr, '.', '', MkSet(rfReplaceAll));
                                    adjustedExponent := exponent - decimalPlaces;

                                    if OnePercentAccuracy then
                                    begin
                                        if Length(digits) > 3 then
                                            digits := Copy(digits, 1, 3)
                                        else if Length(digits) < 3 then
                                            digits := digits + StringOfChar('0', 3 - Length(digits));
                                    end;

                                    codeVal := digits + IntToStr(adjustedExponent);
                                end
                                else
                                begin
                                    int_part := Floor(resistance);
                                    frac_part := resistance - int_part;
                                    if frac_part > 0 then
                                    begin
                                        frac_str := FormatFloat('0.##########', frac_part);
                                        frac_str := Copy(frac_str, 3, Length(frac_str)-2);
                                        while (Length(frac_str) > 1) and (frac_str[Length(frac_str)] = '0') do
                                            Delete(frac_str, Length(frac_str), 1);
                                        codeVal := IntToStr(int_part) + 'R' + frac_str;
                                    end
                                    else
                                        codeVal := IntToStr(int_part) + 'R0';
                                end;
                            end;
                            end;
                        end;

                        if (codeParam <> nil) and (codeVal <> 'XXX') then
                        begin
                            if Length(codeVal) = 3 then
                            begin
                                codeParam.Text := ' ' + codeVal;
                            end;
                            if Length(codeVal) = 5 then
                            begin
                                Delete(codeVal, 1, 1);
                                codeParam.Text := codeVal;
                            end;
                            if Length(codeVal) = 4 then
                            begin
                                codeParam.Text := codeVal;
                            end;
                        end;
                    finally
                        comp.SchIterator_Destroy(paramIter);
                    end;
                end;
            end;
            comp := compIter.NextSchObject;
        end;
    finally
        schDoc.SchIterator_Destroy(compIter);
    end;

    schDoc.GraphicallyInvalidate;
    SchServer.ProcessControl.PostProcess(schDoc, '');
end;
