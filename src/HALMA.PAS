{ ******************************************************************* }
{                                                                     }
{                       (c) Nov 1998 by Tobias Kohn                   }
{                                                                     }
{ ******************************************************************* }
{  Diese Unit enthÑlt Prozeduren und Funktionen fÅr das Computerspiel }
{ Halma. Hier sind ebenso die Daten der 256 Felder erfasst. Einiges   }
{ muss jedoch trotzdem noch im Hauptprogramm vorgenommen werden. So   }
{ zum Beispiel das Laden der Figuren.                                 }
{ ******************************************************************* }
UNIT Halma;
{$G+}           { 286-Code benutzen. }
{ ******************************************************************* }
INTERFACE
{ ******************************************************************* }
 USES Graph2, GObjects;

  CONST
 { ********************************************************** }
 { Die Konstanten fÅr den Feldstatus:                         }
 {  ˘Black       Ein schwarzes, nicht benutzbares Feld.       }
 {  ˘Normal      Hier sind zwei Konstanten fÅr die beiden     }
 {                Feldfarben notwendig.                       }
 {  ˘Ziel        Die Zielfelder, auf die die Figuren gebracht }
 {                werden mÅssen.                              }
 {  ˘WegFall     Dieses Feld fÑllt nach einmaligem Benutzen   }
 {                weg und wird Schwarz.                       }
 {  ˘Mauer       Dieses Feld ist durch eine Mauer blockiert.  }
 {  ˘Trans       Kann die sich daraufbefindliche Figur an     }
 {                einen anderen Ort versetzen.                }
 {                                                            }
 {  ˘Colors      EnthÑlt die Farben fÅr die Felder.           }
 {  ˘HGColor     Die Hintergrundfarbe.                        }
 {  ˘WinCol      Wird in LoadFigure verwendet, um die Windows }
 {                Farben in DOS-Farben zu konvertieren.       }
 { ********************************************************** }
   fs_Black    = $00;
   fs_Normal1  = $01;
   fs_Normal2  = $02;
   fs_Ziel1    = $03;
   fs_Ziel2    = $04;
   fs_WegFall1 = $05;
   fs_WegFall2 = $06;
   fs_Mauer    = $07;
   fs_Trans    = $08;

   Colors: Array[0..8] of Byte = ($10,$20,$22,$80,$82,$7F,$6B,$78,$0E);

   HGColor: Byte = cl_Cyan;

   WinCol: Array[0..15] of Byte = ($0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$A,$B,$C,$D,$E,$F);

   MouseFlag: Byte = 0;  { Ob die Tastatur (1) oder die maus (0) selbst steuert }

  TYPE
 { ********************************************************** }
 {  ˘State       EnthÑlt den direktten Feldstatus. Wird in    }
 {                erster Linie fÅr die Farbbestimmung verwen- }
 {                det.                                        }
 {  ˘Figur       Ist gesetzt, wenn sich eine Figur auf dem    }
 {                Feld befindet.                              }
 {  ˘Select      Ist gesetzt, wenn die momentan aktive Figur  }
 {                auf dieses Feld springen kann.              }
 { ********************************************************** }
    FeldRec = Record
      State : Byte;
      Figur : Boolean;
      Select: Boolean;
    end;

 { ********************************************************** }
 {  ˘Number      Die erreichte Punktezahl.                    }
 {  ˘Text        Der Name oder die Bezeichnung des Spielers.  }
 {                                                            }
 {  ˘Names       EnthÑlt die Namen und Punktezahlen der 10    }
 {                besten.                                     }
 {  ˘FileName    EnthÑlt den Namen der Datei, in die ge-      }
 {                speichert werden soll.                      }
 {  Init         Erzeugt die Namenfelder und setzt sie auf 0. }
 {  Done         Gibt allen Speicher wieder frei.             }
 {  Insert       FÅgt einen neuen Namen mit Punktezahl ein.   }
 {                Dabei wird auf die Sortierung geachtet.     }
 {  Save         Speichert die Daten in die Datei.            }
 {  Load         LÑdt die Daten aus der Datei.                }
 {  Show         Stellt die Namen und Punkte auf dem Bild-    }
 {                schirm dar.                                 }
 { ********************************************************** }
  HScoreItem = ^LScoreItem;
  LScoreItem = Record
    Number: LongInt;
    Text  : String[15];
  end;

  HHighScore = ^LHighScore;
  LHighScore = object(LObject)
    Names: Array[0..9] of HScoreItem;
    FileName: String;
    constructor Init(AFileName: String);
    destructor Done; virtual;
    procedure Insert(APnts: LongInt; AName: String);
    procedure Save; virtual;
    procedure Load; virtual;
    procedure Show(x,y: Word); virtual;
  end;

  VAR
 { ********************************************************** }
 {  ˘Felder      EnthÑlt die Daten der Felder.                }
 {  ˘BFigure     Ein Zeiger auf das Bild, das die aktuelle    }
 {                Figur enthÑlt.                              }
 {  ˘BMauer      Ein Zeiger auf das Bild, das die Mauer ent-  }
 {                hÑlt.                                       }
 {  ˘BCanvas     Dieses Bild dient als Buffer, um nicht immer }
 {                das ganze Brett neu zeichnen zu mÅssen, die }
 {                Figuren jedoch korrekt dargestellt werden.  }
 {  ˘Level       Die Nummer des aktuellen Levels.             }
 { ********************************************************** }
    Felder : Array[1..16,1..16] of FeldRec;
    BFigure: HCanvas;
    BMauer : HCanvas;
    BCanvas: LCanvas;
    Level  : Byte;

 { ********************************************************** }
 {  DrawField    Zeichnet ein einzelnes Feld mit den Daten    }
 {                des Feldes ix,iy an die Koordinaten qX, qY  }
 {                in das Buffer-Bild.                         }
 {  DrawFull     Zeichnet ein kleines Brett in das Buffer-    }
 {                Bild mit dem Feld ix,iy als Mittelpunkt.    }
 {  Draw         Zeichnet das Feld ix,iy auf den Bildschirm.  }
 {  DrawBrett    Zeichnet das ganze Brett neu.                }
 {  Drehen       Dreht das Brett um 90¯ im Uhrzeigersinn.     }
 {  BrettInit    Versieht alle Felder mir Standart-Anfangs-   }
 {                werten.                                     }
 {  HalmaInit    Setzt die Figuren gemÑss der Halma-Anfangs-  }
 {                aufstellung.                                }
 {                                                            }
 {  AllOnDest    PrÅft, ob alle Figuren im Ziel sind.         }
 {                                                            }
 {  PossPush     Ermittelt alle Felder, auf die die Figur,    }
 {                welche auf dem Feld ix,iy steht, ziehen     }
 {                kann.                                       }
 {  PossJump     Ermittelt alle Felder, auf die die Figur,    }
 {                welche auf dem Feld ix,iy steht, springen   }
 {                kann.                                       }
 {               => Bei den erreichbaren Feldern wird Select  }
 {               auf True gesetzt.                            }
 {  NotPoss      Setzt bei allen Feldern Select wieder auf    }
 {                false.                                      }
 {                                                            }
 {  LoadFigure   LÑdt die Figur aus einem Windows-BMP-Bild    }
 {                und gibt, falls es geglÅckt ist, True zurÅck}
 {  LoadMauer    LÑdt das Bild der Mauer aus einem Windows-   }
 {                BMP-Bild.                                   }
 {  LoadFields   LÑdt die Daten fÅr das Brett aus einer Datei }
 {                                                            }
 {  Sound        Gibt einen Ton der Frequenz pFreq aus.       }
 {  NoSound      Schaltet die Soundausgabe wieder ab.         }
 {  Beep         Veranlasst den Computer, kurz zu pipsen.     }
 {                                                            }
 {  FileError    Gibt eine Fehlermeldung aus und beendet das  }
 {                Programm.                                   }
 {                                                            }
 {  KeyEvents    Bearbeitet die Tastaturereignisse, sodass    }
 {                der Mauscursor auch auf Pfeile reagiert.    }
 { ********************************************************** }
  procedure DrawField(qX, qY: Word; ix, iy: ShortInt);
  procedure DrawFull(ix, iy: Byte);

  procedure Draw(ix,iy: Byte);
  procedure DrawBrett;

  procedure Drehen;
  procedure BrettInit;
  procedure HalmaInit;

  function AllOnDest: Boolean;

  procedure PossPush(ix,iy: Byte);
  procedure PossJump(ix,iy: Byte);
  procedure NotPoss;

  function LoadFigure(AFile: String): Boolean;
  function LoadMauer(AFile: String): Boolean;
  function LoadFields(AFile: String): Boolean;

  procedure Sound(pFreq: Word);
  procedure NoSound;
  procedure Beep;

  procedure FileError(AFile: String);

{ ******************************************************************* }
IMPLEMENTATION
{ ******************************************************************* }

 { ********************************************************** }
 {  ˘Number      Die erreichte Punktezahl.                    }
 {  ˘Text        Der Name oder die Bezeichnung des Spielers.  }
 {                                                            }
 {  ˘Names       EnthÑlt die Namen und Punktezahlen der 10    }
 {                besten.                                     }
 {  ˘FileName    EnthÑlt den Namen der Datei, in die ge-      }
 {                speichert werden soll.                      }
 {  Init         Erzeugt die Namenfelder und setzt sie auf 0. }
 {  Done         Gibt allen Speicher wieder frei.             }
 {  Insert       FÅgt einen neuen Namen mit Punktezahl ein.   }
 {                Dabei wird auf die Sortierung geachtet.     }
 {  Save         Speichert die Daten in die Datei.            }
 {  Load         LÑdt die Daten aus der Datei.                }
 {  Show         Stellt die Namen und Punkte auf dem Bild-    }
 {                schirm dar.                                 }
 { ********************************************************** }
 constructor LHighScore.Init(AFileName: String);
 var
   i: Byte;
 begin
   Inherited Init;
   FileName := AFileName;               { Dateinamen Åbernehmen         }
   For i := 0 to 9 do begin             { Alle Elemente erzeugen und... }
     Names[i] := New(HScoreItem);       { ..auf Null setzen.            }
     if (Names[i] = nil) then Exit;
     Names[i]^.Number := 0;
     Names[i]^.Text := '';
   end;
 end;

 destructor LHighScore.Done;
 var
   i: Byte;
 begin
   For i := 0 to 9 do Dispose(Names[i]);  { Speicher freigeben }
   inherited Done;
 end;

 procedure LHighScore.Insert(APnts: LongInt; AName: String);

  { Setzt alle Elemente ab j um eines herunter: }
  procedure MakePlace(j: Byte);
  begin
    if j > 8 then Exit;                         { FÅr 9tes Element nicht durchfÅhren. }
    For j := 8 downto j do begin
      Names[j+1]^.Text   := Names[j]^.Text;     { 9=8; 8=7; 7=6... }
      Names[j+1]^.Number := Names[j]^.Number;
    end;
  end;

 var
   i: Byte;
 begin
   For i := 0 to 9 do begin                     { Alle Elemente durchgehen }
     if (Names[i]^.Number < APnts) then begin   { Wenn die Punktezahl kleiner wird, als APnts, }
       MakePlace(i);                            { Platz schaffen und }
       Names[i]^.Number := APnts;               { das neue Element einfÅgen. }
       Names[i]^.Text   := AName;
       Exit;                                    { Wenn Platz gefunden, prozedur abbrechen. }
     end;
   end;
 end;

 procedure LHighScore.Save;
 var
   f: File of LScoreItem;
   i,j: Byte;
   Buffer: LScoreItem;
 begin
   Assign(f, FileName);                         { Dateinamen zuweisen }
   ReWrite(f);                                  { Datei neu erstellen }
   For i := 0 to 9 do begin                     { Alle Elemente speichern }
     Buffer.Number := Names[i]^.Number;         { Daten in Buffer Åbertragen }
     Buffer.Text   := Names[i]^.Text;
     Write(f, Buffer);                          { Buffer in Datei schreiben }
     For j := 1 to 15 do Buffer.Text[i] := ' '; { Buffer lîschen: sonst sind in der datei noch }
   end;                                         { ...Åberall Name-ReststÅcke vorhanden. }
   Close(f);                                    { Datei schliessen }
 end;

 procedure LHighScore.Load;
 var
   f: File of LScoreItem;
   i: Byte;
   buffer: LScoreItem;
 begin
   Assign(f, FileName);                 { Dateinamen zuweisen }
   {$I-}                                { automatische öberprÅfung aus }
    ReSet(f);                           { Datei îffnen }
    if not (IOResult = 0) then Exit;    { Wenn nicht erfolgreich, dann abbrechen }
    For i := 0 to 9 do begin            { Alle Elemente: }
      read(f, Buffer);                  { In Buffer einlesen }
      if not (IoResult = 0) then begin  { Wenn Fehler, abbrechen }
        Close(f); Exit;
      end;
      Names[i]^.Number := Buffer.Number;{ Bufferdaten Åbertragen }
      Names[i]^.Text   := Buffer.Text;
    end;
   {$I+}
   Close(f);                            { Datei schliessen. }
 end;

 procedure LHighScore.Show(x,y: Word);
 var
   Canvas: HCanvas;
   i     : Byte;
   bufstr: String[10];
 begin
   Canvas := New(HCanvas, Init(200,15,0));           { TemporÑres Canvas erzeugen. }
   if not (Canvas = nil) then begin                  { Wenn nicht nil ist, dann zeichnen }
     For i := 0 to 9 do begin                        { Alle Elemente darstellen }
       Canvas^.Clear(0);                             { Canvas lîschen }
       Str(Names[i]^.Number, bufstr);                { Punktezahl als Nummer }
       DrawTextXY(Canvas,130+(8*(7-ord(bufstr[0]))),1,$10,0,bufstr); { Nummer schreiben }
       DrawTextXY(Canvas,1,1,$10,0,Names[i]^.Text);                  { Namen schreiben }
       Canvas^.Show(x,y+(i*14));                     { Auf den Bildschirm. }
     end;
     Dispose(Canvas, Done);                          { Speicher wieder freigeben. }
   end;
 end;

 { ********************************************************** }
 { ********************************************************** }
 procedure DrawField(qX,qY: Word; ix, iy: ShortInt);
 var
   w    : Byte;
   i    : Word;
   j,k,v: Real;
 begin
   if (ix < 1) or (ix > 16) then Exit;     { Wenn die Koordinaten ausserhalb des... }
   if (iy < 1) or (iy > 16) then Exit;     { ...Berecihes liegen, nicht zeichnen! }
   j := qX;                                { Von Oben nach Unten gehen und jede... }
   k := qX;                                { ...Zeile im Paralellogramm zeichnen.  }
   v := 10 / 7;                            { j enthÑlt die Anfangs-, k die Endkoordinate }
   w := Colors[Felder[ix,iy].State];       { Die Feldfarbe in w speichern. }
   For i := (qY) to (qY + 14) do begin     { Obere HÑlfte. }
     DrawLine(@BCanvas,Round(j),i,Round(k),i,w);
     j := j - v; k := k + v;               { Linien auseinanderlaufend. }
   end;
   For i := (qY + 14) to (qY + 28) do begin{ Untere HÑlfte }
     j := j + v; k := k - v;               { Linien zusammenlaufend. }
     DrawLine(@BCanvas,Round(j),i,Round(k),i,w);
   end;
 end;

 procedure DrawFull(ix,iy: Byte);
 var
   i,j: ShortInt;
   x,y: Integer;
 begin
   dec(ix); dec(iy);
   BCanvas.Clear(HGColor);                   { Altes Bild lîschen. }
   For j := -2 to 4 do                       { Alle Felder zeichnen. }
    For i := -2 to 4 do begin
      x := (i+j) * 20 - 1;                      { Koordinaten berechnen }
      y := ((j-i) * 14) + 7;
      DrawField(x,y+63,ix+i,iy+j);              { Zeichnen }
    end;
   For j := -2 to 4 do                       { Figuren und Mauer zeichnen: }
    For i := -2 to 4 do
     if ((ix+i) > 0) and ((ix+i) < 17) then          { Nur gÅltige Felder }
      if ((iy+j) > 0) and ((iy+j) < 17) then begin
        x := (i+j) * 20 - 1;                         { Koordinaten berechnen. }
        y := ((j-i) * 14) + 7;                       { PrÅfen, on Koordinaten Åberhaupt... }
        if (x > 10) and (x < 90) and (y > -48) and (y < 120) then begin       { ... auf Bild sind. }
          if Felder[ix+i,iy+j].State = fs_Mauer      { Mauer zeichnen }
           then BCanvas.Insert(BMauer,x-10,y+48)
           else if Felder[ix+i,iy+j].Figur              { Figur zeichnen }
            then BCanvas.Insert(BFigure,x-10,y+48);
        end;
      end;
 end;

 procedure Draw(ix,iy: Byte);
 var
   Einfug: HCanvas;
 begin
   BCanvas.Clear(0);                    { Buffer-Bild lîschen }
   DrawFull(ix,iy);                     { Buffer-Bild neu zeichnen }
   Einfug := BCanvas.Copy(20,42,60,98); { Ausschnitt kopieren }
   if not (Einfug = nil) then begin
     Einfug^.Show((ix+iy)*20-40,230-((ix-iy)*14)-21); { Ausschnitt auf den Bildschirm }
     Dispose(Einfug, Done);             { Kopie wieder entfernen. }
   end;
 end;

 procedure DrawBrett;
 var
   i,j: Byte;
 begin
    For j := 16 downto 1 do             { Von hinten nach Vorne zeichnen. }
     For i := 1 to 16 do begin
       BCanvas.Clear(0);                { Bild als Buffer fÅr jeweils ein Feld. }
       DrawField(19,27,j,i);            { Feld zeichnen }
       if Felder[j,i].Figur             { Figur auf Feld zeichnen }
        then BCanvas.Insert(BFigure,9,12);
       if (Felder[j,i].State = fs_Mauer)         { Mauer zeichnen }
        then BCanvas.Insert(BMauer,9,12);
       BCanvas.Show((i+j)*20-40,210-((j-i)*14)); { Feld auf Bildschirm. }
     end;
 end;

 procedure Drehen;
 var
   Buffer: FeldRec;
   i,j   : Byte;
 begin
   For i := 1 to 8 do                           { Nur ein Viertel des Brettes... }
    For j := 1 to 8 do begin                    { ...durchgehen }
      Buffer := Felder[i,j];                    { Erstes Feld in Buffer Åber- }
      Felder[i,j] := Felder[j,17-i];            { tragen, zweites in erstes, }
      Felder[j,17-i] := Felder[17-i,17-j];      { drittes in zweites, ... }
      Felder[17-i,17-j] := Felder[17-j,i];
      Felder[17-j,i] := Buffer;
    end;
 end;

 procedure BrettInit;
 var
   i,j,k: Byte;
 begin
   k := 0;                         { Dient als "Kippschalter": Kariertes Feld }
   For j := 1 to 16 do begin
    For i := 1 to 16 do
     with Felder[i,j] do begin
       k := 1 - k;                 { Kippschaler umlegen }
       State := k + 1;             { Feldfarbe setzen    }
       Figur := False;             { Keine Figur         }
       Select:= False;             { Wird noch nicht benîtigt }
     end;
     k := 1 - k;
   end;
   For i := 16 downto 12 do begin
     Felder[i,1].State := Felder[i,1].State + 2;
     Felder[i,2].State := Felder[i,2].State + 2;
     if i > 12 then begin
       Felder[i,3].State := Felder[i,3].State + 2;
       if i > 13 then begin
         Felder[i,4].State := Felder[i,4].State + 2;
         if i > 14 then Felder[i,5].State := Felder[i,5].State + 2;
       end;
     end;
   end;
 end;

 procedure HalmaInit;
 var
   i : Byte;
 begin
   For i := 1 to 5 do begin
     Felder[i,16].Figur := True;
     Felder[i,15].Figur := True;
     if i < 5 then begin
       Felder[i,14].Figur := True;
       if i < 4 then begin
         Felder[i,13].Figur := True;
         if i < 3 then Felder[i,12].Figur := True;
       end;
     end;
   end;
 end;

 function AllOnDest: Boolean;
 var
   i,j: Byte;
 begin
   For i := 1 to 16 do
    For j := 1 to 16 do
     if (Felder[i,j].State = fs_Ziel1) or (Felder[i,j].State = fs_Ziel2)
      then if not Felder[i,j].Figur then begin
        AllOnDest := False; Exit;
      end;
   AllOnDest := True;
 end;

 procedure PossPush(ix,iy: Byte);
 var
   i,j: ShortInt;
 begin
   For j := -1 to 1 do
    For i := -1 to 1 do
     if (ix+i > 0) and (ix+i < 17) then         { Feld innerhalb gÅltigem Bereich }
      if (iy+j > 0) and (iy+j < 17) then
       if not Felder[ix+i,iy+j].Figur and (Felder[ix+i,iy+j].State < 7) and
        (Felder[ix+i,iy+j].State > 0)
         then Felder[ix+i,iy+j].Select := True;  { Wenn Feld von einer Figur oder Mauer }
                                                 { besetzt ist, nicht anwÑhlbar         }
 end;

 procedure PossJump(ix,iy: Byte);
 var
   i,j: ShortInt;
 begin
   For j := -1 to 1 do
    For i := -1 to 1 do
     if (ix+i+i > 0) and (ix+i+i < 17) and      { Innerhalb gÅltigem Bereich }
      (iy+j+j > 0) and (iy+j+j < 17) then        { Eine Figur steht dazwischen und das Ziel ist keine Mauer }
       if Felder[ix+i,iy+j].Figur and (Felder[ix+i+i,iy+j+j].State < 7) and
        (Felder[ix+i+i,iy+j+j].State > 0)
         then if not Felder[ix+i+i,iy+j+j].Figur and not  { Nicht von einer Figur besetzt. }
          Felder[ix+i+i,iy+j+j].Select then begin { Feld wurde bereits markiert ? }
           Felder[ix+i+i,iy+j+j].Select := True;  { Feld als Ziel mîglich }
           PossJump(ix+i+i,iy+j+j);               { Man kann Åber mehrere male springen. }
         end;
 end;

 procedure NotPoss;
 var
   i,j: Byte;
 begin
   For j := 1 to 16 do
    For i := 1 to 16 do
     Felder[i,j].Select := False;
 end;

 function LoadFigure(AFile: String): Boolean;
 var
   f: File;
   i: Byte;
 begin
   {$I-}
   Assign(f,AFile);             { Zuerst prÅfen, ob die Datei existiert. }
   ReSet(f);
   if IoResult <> 0 then begin
     LoadFigure := False;       { Wenn nicht, False zurÅckliefern und beenden }
     Exit;
   end else Close(f);           { Falls Datei vorhanden, wieder schliessen. }
   {$I+}
   BFigure := LoadBMP(AFile);   { Bild aus Datei laden. }
   if BFigure = nil then begin  { Bild konnte nicht erzeugt werden. }
     LoadFigure := False; Exit;
   end;
   For i := 0 to 15 do          { Windows-Farben in DOS-Farben umwandeln. }
    ReplaceCanvas(BFigure,i,WinCol[i]);
 end;

 function LoadMauer(AFile: String): Boolean;
 var
   f: File;
   i: Byte;
 begin
   {$I-}
   Assign(f,AFile);             { Zuerst prÅfen, ob die Datei existiert. }
   ReSet(f);
   if IoResult <> 0 then begin
     LoadMauer := False;        { Wenn nicht, False zurÅckliefern und beenden }
     Exit;
   end else Close(f);           { Falls Datei vorhanden, wieder schliessen. }
   {$I+}
   BMauer := LoadBMP(AFile);    { Bild aus Datei laden. }
   if BMauer = nil then begin   { Bild konnte nicht erzeugt werden. }
     LoadMauer := False; Exit;
   end;
   For i := 0 to 15 do          { Windows-Farben in DOS-Farben umwandeln. }
    ReplaceCanvas(BMauer,i,WinCol[i]);
 end;

 function LoadFields(AFile: String): Boolean;
 var
   f: File of FeldRec;
   i,j: Byte;
 begin
   Assign(f, AFile);                    { Die Datei zuordnen }
   {$I-}                                { In-Output-öberprÅfung aus }
    ReSet(f);                           { Datei îffnen }
    if IoResult <> 0 then begin         { ...versuch gescheitert ? }
      LoadFields := False; Exit;
    end;
   {$I+}                                { In-Output-öberprÅfung ein }
   For i := 1 to 16 do                  { Daten einlesen }
    For j := 1 to 16 do
     Read(f, Felder[i,j]);
   Close(f);                            { Datei schliessen }
   LoadFields := True;                  { Daten sind eingelesen }
 end;

{ ******************************************************************* }
 procedure Sound(pFreq: Word); assembler;
 asm
      PUSH     DS                        { Diese Prozedur wurde von }
      MOV      BX,pFreq                  { Borland Turbo Pascal 7.0 }
      MOV      AX,34DDh                  { aus der Unit Crt abge-   }
      MOV      DX,0012h                  { schrieben.               }
      CMP      DX,BX
      JNB      @@2
      DIV      BX
      MOV      BX,AX
      IN       AL,61h
      TEST     AL,03h
      JNZ      @@1
      OR       AL,03h
      OUT      61h,AL
      MOV      AL,0B6h
      OUT      43h,AL
 @@1: MOV      AL,BL
      OUT      42h,AL
      MOV      AL,BH
      OUT      42h,AL
 @@2: POP      DS
 end;

 procedure NoSound; assembler;
 asm
      PUSH     DS               { Stammt aus Unit Crt }
      IN       AL,61h
      AND      AL,0FCh
      OUT      61h,AL
      POP      DS
 end;

 procedure Beep; assembler;
 asm
      PUSH     DS
      PUSH     120h
      CALL     Sound            { Sound mit 288 Hz anschalten }
      XOR      DX,DX
      MOV      ES,DX            { $0000:$046C enthÑlt die Takte }
      MOV      BX,046Ch
      MOV      CX,ES:[BX]       { in CX speichern }
      ADD      CX,5             { 5/18.2 - Sekunden dazuaddieren }
 @@1: MOV      AX,ES:[BX]
      CMP      AX,CX            { Zeit neu auslesen. }
      JL       @@1              { Wenn zeit noch nicht erreicht, zurÅck }
      CALL     NoSound          { Sound abschalten }
      POP      DS
 end;

 procedure FileError(AFile: String);
 begin
   WriteLn('Fehler beim Laden der Datei: ',AFile);
   Screen.Done;
   Halt;
 end;

BEGIN
  Level := 0;           { Zuerst Level 0 }
END.