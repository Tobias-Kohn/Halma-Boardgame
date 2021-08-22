{ *********************************************************************** }
{                                                                         }
{                       (c) 1998 by Tobias Kohn                           }
{                                                                         }
{                              Version 1.0                                }
{                                                                         }
{ *********************************************************************** }
UNIT GEditors;
{$G+}         { 286-Codes }
{ ************************************************************************** }
INTERFACE
 USES GObjects, Graph2;

 TYPE
   { Dient dazu, verwechslungen mit dem Bezeichner 'Text' vorzubeugen. }
   TextFile = Text;

   { ***************************************************************** }
   {  ˘Text             EnthÑllt den Text, der editiert wird.          }
   {  ˘TextStyle        Die Schriftart, mit der der Text angezeigt     }
   {                     wird. (Siehe unit Graph2)                     }
   {  ˘CursorPos        Die aktuelle Position des "Text"-Cursors       }
   {  ˘SelLength        Die LÑnge des selektierten Textes.             }
   {  ˘Overwrite        Legt fest, ob der neue Text eingefÅgt wird     }
   {                     oder ob er den alten Text Åberschreibt.       }
   {  ˘MaxLength        Legt die maximale LÑnge des Textes fest        }
   {  ˘MouseDelta       Speichert die Mausposition beim selektieren    }
   {                     des Textes mit Hilfe der Maus.                }
   {  ˘OkButton         Zeigt unter UmstÑnden auf einen Butten, der    }
   {                     Ausgelîst wird, wenn die Taste "Enter" ge-    }
   {                     drÅckt wurde.                                 }
   {  Init              Setzt die Anfangswerte fÅr die Variablen und   }
   {                     das Feld Options (siehe unit Gobjects)        }
   {  InitColors        Initialisiert die Farbpalette.                 }
   {  Draw              Zeichnet das Object in das Feld Canvas.        }
   {  HandleEvent       Behandelt die Ereignisse                       }
   {   => FÅr weitere Informationen sehen sie in der Unit GObjects     }
   {      unter dem Object "LView" nach.                               }
   { ***************************************************************** }
   HEdit = ^LEdit;
   LEdit = object(LView)
     Text      : String;
     TextStyle : Byte;
     CursorPos : Byte;
     SelLength : Byte;
     Overwrite : Boolean;
     MaxLength : Byte;
     MouseDelta: LPoint;
     OkButton  : HButton;
     constructor Init(AParent: HView; ABounds: LRect);
     procedure InitColors; virtual;
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
   end;

   { ***************************************************************** }
   {  ˘MyColor          EnthÑlt die momentan selektierte Farbe.        }
   {  Init              Setzt MyColor auf 0.                           }
   {  Draw              Zeichnet der Reihe nach alle 256 Farben auf    }
   {                     mit einer "Pixel"-Grîsse von 4x4 pro Farbe.   }
   {  HandleEvent       Reagiert auf einen Mausklick und lÑdt die an-  }
   {                     geklickte Farbe in das Feld "myColor"         }
   {  BigPixel          Zeichnet einen Pixel in Canvas, davon aus-     }
   {                     gehend, eine 4x4 Box sei ein Pixel.           }
   { ***************************************************************** }
   HColorBox = ^LColorBox;
   LColorBox = object(LView)
     MyColor: Byte;
     constructor Init(AParent : HView; ABounds : LRect);
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
   private
     procedure BigPixel(x,y: Word; AColor: Byte);
   end;

   { ***************************************************************** }
   { LSItem:            Beinhaltet einen einzelnen Eintrag.            }
   {  ˘Next             Ein Zeiger auf den nÑchsten Eintrag in der     }
   {                     Liste.                                        }
   {  ˘Size             Beinhaltet die Grîsse des gesamten Eintrages.  }
   {  ˘Text             Es kînnen maximal 255 Zeichen pro Eintrag ge-  }
   {                     speichert werden.                             }
   {                                                                   }
   { LStringList:       Diese Objekt verwaltet eine Liste aus Strings. }
   {  ˘First            Ein Zeiger auf das erste Element in der Liste. }
   {  ˘Count            Anzahl der Elemente.                           }
   {  Init              Setzt First und Count auf Null.                }
   {  Done              Gibt allen Speicher wieder frei.               }
   {  Add               FÅgt der Liste ein neues Element hinzu.        }
   {  Insert            FÅgt ein neues Element in die Liste ein.       }
   {  Delete            Lîscht ein Element aus der Liste.              }
   {  GetStr            Gibt den Text von Element Nr zurÅck (Bei Null  }
   {                     beginnend)                                    }
   {  SetStr            Weist dem Element Nr einen neuen Text hinzu.   }
   {  Sort              Sortiert alle Elemente dem Alphabet (ASCII-    }
   {                     Wert) nach, aufsteigend (A-Z).                }
   {  LoadFromFile      LÑdt eine Datei in die Liste.                  }
   {  SaveToFile        Speichert alle Strings in die angegebene Datei }
   {                     => Bereits bestehende Dateien werden Åber-    }
   {                     schrieben.                                    }
   { ***************************************************************** }
   HSItem = ^LSItem;
   LSItem = record
     Next: HSItem;
     Size: Byte;
     Text: Array[1..255] of Char;
   end;

   HStringList = ^LStringList;
   LStringList = object(LObject)
     First: HSItem;
     Count: Word;
     constructor Init;
     destructor Done; virtual;
     procedure Add(AText: String);
     procedure Insert(Nr: Word; AText: String);
     procedure Delete(Nr: Word);
     function GetStr(Nr: Word): String; virtual;
     procedure SetStr(Nr: Word; AText: String); virtual;
     procedure Sort; virtual;
     procedure LoadFromFile(AFileName: String);
     procedure SaveToFile(AFileName: String);
   end;

   { ***************************************************************** }
   {  ˘Select           Gibt das Selektierte Element an (beginnend bei }
   {                     Null)                                         }
   {  ˘StrList          Ein Zeiger auf die StringListe.                }
   {  ˘FirstVisible     Legt den sichtbaren Bereich fest (Scrollen)    }
   {  ˘KlickFlag        Wird benîtigt, damit bei einmaligem Klicken    }
   {                     auf die Scrollbuttons nicht die ganze Liste   }
   {                     durchgescrollt wird.                          }
   {  Init              Setzt alles auf Null, erzeugt jedoch noch      }
   {                     keine Stringliste.                            }
   {  AssignList        Weist der Liste eine Stringliste zu. Ist der   }
   {                     Parameter gleich Null, wird eine Neue, leere  }
   {                     Liste erzeugt.                                }
   {  HandleEvent       Reagiert standartmÑssig auf Maus und Tastatur. }
   { ***************************************************************** }
   HList = ^LList;
   LList = object(LView)
     Select : Word;
     StrList: HStringList;
     FirstVisible: Word;
     constructor Init(AParent: HView; ABounds: LRect);
     destructor Done; virtual;
     procedure InitColors; virtual;
     procedure AssignList(AList: HStringList);
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
   private
     KlickFlag: Boolean;
   end;

   { ***************************************************************** }
   {  HandleEvent       öberschreibt die von LView geerbte Methode     }
   {                     vollstÑndig, wobei die Quelltexte praktisch   }
   {                     identisch sind mit der Ausnahme, dass dieses  }
   {                     Objekt GContain anstatt Conatin aufruft, um   }
   {                     die Maus zu ÅberprÅfen.                       }
   { ***************************************************************** }
   HGView = ^LGView;
   LGView = object(LView)
     procedure HandleEvent(var AEvent); virtual;
   end;

   { ***************************************************************** }
   {  ˘ExecResult       Speichert das Kommando ab, mit dem das Fenster }
   {                     geschlossen wurde.                            }
   {  ˘ExecBool         Dient intern dazu, dass LDialog nur auf Ereig- }
   {                     nisse reagiert, wenn diese von Execute kommen }
   {  Execute           FÅhrt den Dialog aus: Liest die Ereignisse ein }
   {                     und gibt sie zur Verarbeitung weiter, bis ein }
   {                     Kommando ausgelîst wird.                      }
   {  HandleEvent       Bricht ab, wenn ExecBool False ist.            }
   { ***************************************************************** }
   HDialog = ^LDialog;
   LDialog = object(LWindow)
     ExecResult: Word;
     constructor Init(ABounds: LRect; ACaption: String);
     procedure Execute; virtual;
     procedure HandleEvent(var AEvent); virtual;
   private
     ExecBool: Boolean;
   end;

   { ***************************************************************** }
   {  Dieses Objekt ist eine Erweiterung des Objektes LMouse aus der   }
   { Unit GObjects. Hier wird jedoch die Maus mit Hilfe der Tastatur   }
   { simuliert.                                                        }
   {                                                                   }
   {  LWordArray        Dient zum Zugriff auf die Cursordaten.         }
   {                                                                   }
   {  ˘Saver            EnthÑlt das abgespeicherte Hintergrundbild.    }
   {  Run               Behandelt die Tastaturereignisse.              }
   {  Show              Stellt den Cursor dar.                         }
   {  Hide              Lîscht den Cursor vom Bildschirm.              }
   {  SetCursor         Setzt einen neuen Cursor.                      }
   {  Draw              Zeichnet den Cursor an der richtigen Position. }
   {  ReMove            Stellt den Hintergrund wieder her.             }
   { ***************************************************************** }
   HWordArray = ^LWordArray;
   LWordArray = Array[0..255] of Word;

   HKMouse = ^LKMouse;
   LKMouse = object(LMouse)
     Saver: HCanvas;
     procedure Run; virtual;
     procedure Show; virtual;
     procedure Hide; virtual;
     procedure SetCursor(var ACursor); virtual;
     procedure Draw; virtual;
     procedure ReMove; virtual;
   end;

   { ***************************************************************** }
   {  PrÅft, ob der mit (pX|pY) angegebene Punkt innerhalb des Para-   }
   { lellogrammes liegt, das mit ARect angegeben wird. Bei diesem      }
   { Paralellogramm gilt, dass jede der vier Ecken auf der Mitte der   }
   { Seiten des Rechteckes ARect liegt. Diese Funktion wird von LGView }
   { verwendet. Bei Spielen werden Oft Felder benîtigt, die diese Form }
   { haben und auf Mausereignisse reagieren sollen.                    }
   { ***************************************************************** }
   function GContain(ARect: LRect; pX, pY: Word) : Boolean;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }

   { ***************************************************************** }
   {  ˘Text             EnthÑllt den Text, der editiert wird.          }
   {  PrÅft, ob der mit (pX|pY) angegebene Punkt innerhalb des Para-   }
   { lellogrammes liegt, das mit ARect angegeben wird. Bei diesem      }
   { Paralellogramm gilt, dass jede der vier Ecken auf der Mitte der   }
   { Seiten des Rechteckes ARect liegt. Diese Funktion wird von LGView }
   { verwendet. Bei Spielen werden Oft Felder benîtigt, die diese Form }
   { haben und auf Mausereignisse reagieren sollen.                    }
   { ***************************************************************** }
 function GContain(ARect: LRect; pX, pY: Word) : Boolean;
 var
   Buffer : Boolean;
   f1,f2  : Integer;
   Mitte  : LPoint;
   Point  : LPoint;
 begin
   Buffer  := False;
   Mitte.X := (ARect.B.X - ARect.A.X) div 2;
   Mitte.Y := (ARect.B.Y - ARect.A.Y) div 2;
   Point.X := pX - (ARect.A.X + Mitte.X);
   Point.Y := pY - (ARect.A.Y + Mitte.Y);
   f1 := -(Point.X * Mitte.Y div Mitte.X) + Mitte.Y;
   f2 := -(Point.X * Mitte.Y div Mitte.X) - Mitte.Y;
   if (Point.Y > f2) and (Point.Y < f1) then begin
     f1 := (Point.X * Mitte.Y div Mitte.X) + Mitte.Y;
     f2 := (Point.X * Mitte.Y div Mitte.X) - Mitte.Y;
     if (Point.Y > f2) and (Point.Y < f1) then Buffer := True;
   end;
   GContain := Buffer;
 end;
   { ***************************************************************** }

   { ***************************************************************** }
   {  HandleEvent       öberschreibt die von LView geerbte Methode     }
   {                     vollstÑndig, wobei die Quelltexte praktisch   }
   {                     identisch sind mit der Ausnahme, dass dieses  }
   {                     Objekt GContain anstatt Conatin aufruft, um   }
   {                     die Maus zu ÅberprÅfen.                       }
   { ***************************************************************** }
 procedure LGView.HandleEvent(var AEvent);
 var
   Event: LEvent absolute AEvent;
 begin
   if Event.MVisible                                { Maus-"Status" Åbertragen }
    then EventMask := EventMask or ev_MVisible
    else EventMask := EventMask and not ev_MVisible;
   if (EventMask and ev_Command > 0) then begin
     if Event.Command = cm_Redraw then ReDraw;          { Neu darstellen. }
   end;
   { *** Maus - Ereignisse: *** }
   if (EventMask and ev_Mouse > 0) and (Event.MVisible) then begin
     { Maus ist auf Object: }
     if (GContain(Bounds,Event.Mouse.X,Event.Mouse.Y)) then begin
       if not TestOption(Options, opt_Mouse) then begin
         Options := Options or opt_Mouse;    { Option "Mouse" setzen }
         Mouse^.SetCursor(Cursor^);          { Den richtigen Mauscursor wÑhlen }
       end;
       { Mausklick: }
       if (TestOption(Options, opt_Select)) and (Event.MButton = 0)
        then Options := Options or opt_Focus;   { Fokus Åbernehmen. }
       { Wenn Commando noch leer, dann Maus-Kommando weitergeben. }
       if (Event.MButton = 0) and (Event.Command = cm_None)
        then Event.Command := cm_Mouse;
     end else begin
    { Maus nicht auf Object: }
       if (Event.MButton > 0) and (TestOption(Options, opt_Focus)) then begin
         Options := Options and not opt_Focus; ReDraw; { Mausklick ausserhalb: Fokus abgeben. }
       end;
       if TestOption(Options, opt_Mouse) then begin
         Options := Options and not opt_Mouse;
         Mouse^.SetCursor(Mouse^.StdCursor^);    { Cursor zurÅcksetzen. }
       end;
     end;
     { Maustaste auf Object gedrÅckt. }
     if (Event.MButton > 0) and (GContain(Bounds,Event.Mouse.X,Event.Mouse.Y))
      then begin if not TestOption(Options,opt_Select) then begin
        Options := Options or opt_Select;             { Wenn Maus auf Object und Taste gedrÅckt, }
        ReDraw;
      end; end else if TestOption(Options, opt_Select) then begin
        Options := Options and not opt_Select; { dann Option "Select" setzen. }
        ReDraw;
      end;
   end;
 end;

   { ***************************************************************** }
   {  ˘Text             EnthÑllt den Text, der editiert wird.          }
   {  ˘TextStyle        Die Schriftart, mit der der Text angezeigt     }
   {                     wird. (Siehe unit Graph2)                     }
   {  ˘CursorPos        Die aktuelle Position des "Text"-Cursors       }
   {  ˘SelLength        Die LÑnge des selektierten Textes.             }
   {  ˘Overwrite        Legt fest, ob der neue Text eingefÅgt wird     }
   {                     oder ob er den alten Text Åberschreibt.       }
   {  ˘MaxLength        Legt die maximale LÑnge des Textes fest        }
   {  ˘MouseDelta       Speichert die Mausposition beim selektieren    }
   {                     des Textes mit Hilfe der Maus.                }
   {  ˘OkButton         Zeigt unter UmstÑnden auf einen Butten, der    }
   {                     Ausgelîst wird, wenn die Taste "Enter" ge-    }
   {                     drÅckt wurde.                                 }
   {  Init              Setzt die Anfangswerte fÅr die Variablen und   }
   {                     das Feld Options (siehe unit Gobjects)        }
   {  InitColors        Initialisiert die Farbpalette.                 }
   {  Draw              Zeichnet das Object in das Feld Canvas.        }
   {  HandleEvent       Behandelt die Ereignisse                       }
   {   => FÅr weitere Informationen sehen sie in der Unit GObjects     }
   {      unter dem Object "LView" nach.                               }
   { ***************************************************************** }
 constructor LEdit.Init(AParent: HView; ABounds: LRect);
 begin
   inherited Init(AParent, ABounds);
   Options := Options or opt_3D;         { 3D-Darstellung }
   EventMask := $FF;                     { Alle Ereignisse werden behandelt }
   CursorPos := 0;                       { Cursor an Position 0 }
   SelLength := 0;                       { Kein selektierter Text }
   Text      := '';                      { Kein Text }
   Cursor    := Addr(c2);                { Den Mauscursor c2 wÑhlen }
   TextStyle := 0;                       { Normalen Text ausgeben }
   Overwrite := False;                   { Text einfÅgen }
   MaxLength := 255;                     { Maximale LÑnge sind 255 Zeichen. }
   OkButton  := nil;                     { Kein Button bei "Enter" }
 end;

 procedure LEdit.InitColors;
 begin
   GetMem(Colors,8);            { Speicher belegen }
   if Colors = nil then begin   { Wenn kein Speicher vorhande, dann Fehler }
     HandleError(er_NoColors);  { und abbrechen }
     exit;
   end;
   Colors^[0] := 8;             { Die Grîsse setzten  }
   Colors^[1] := $10;           { Schwarze Schrift.   }
   Colors^[2] := $1F;           { Weisser Hintergrund }
   Colors^[3] := $12;           { Rahmen: Dunkel }
   Colors^[4] := $1D;           { Rahmen: Hell   }
   Colors^[5] := cl_Blue;       { CursorFarbe: Blau  }
   Colors^[6] := cl_White;      { Selektierter Text: }
   Colors^[7] := cl_Blue;       { Weiss auf Blau.    }
 end;

 procedure LEdit.Draw;
 var
   Canv: HCanvas;
   x,o : Word;
 begin
   if not TestOption(Options, opt_Visible) then Exit;   { Nur weiter, wenn Prozedur freigegeben }
   if TestOption(Options, opt_Child) then begin         { Wenn ein öbergeordnetes Fenster vorhanden,... }
     Canv := Canvas;                                    { dann ein temporÑres Canvas erzeugen und dieses... }
     Canvas := New(HCanvas, Init(Bounds.B.X-Bounds.A.X,Bounds.B.Y-Bounds.A.Y,Colors^[2]));{ nachher einfÅgen. }
   end;
   if Canvas = nil then begin                   { Wenn kein Canvas vorhanden, dann abbrechen }
     HandleError(er_NoCanvas); Exit;
   end;
   Canvas^.Clear(Colors^[2]);                   { Canvas lîschen und mit Hintergrundfarbe fÅllen }
   if TestOption(Options, opt_3D) then Canvas^.Dim3(Colors^[3],Colors^[4]);     { 3D-Rahemn zeichnen }
   DrawTextXY(Canvas,3,3,Colors^[1],TextStyle,Text);   { Den Text hineinschreiben }
   o := Options;
   if not (Parent = nil) then                          { Nur Cursor darstellen, wenn }
    if not TestOption(Parent^.Options, opt_Focus)      { auch Åbergeordnetes Fenster (sofern vorhanden), }
     then Options := Options and not opt_Focus;        { den Focus besitzt. }
   if TestOption(Options, opt_Focus) then begin        { Wenn Object den Focus hat,... }
     x := (CursorPos * 8) + 3;                         { Cursorposition berechnen }
     if SelLength = 0 then begin
       DrawLine(Canvas,x,3,x,Mem[$0000:$0485],Colors^[5]);      { "normalen" Cursor zeichnen }
       DrawLine(Canvas,x-1,3,x-1,Mem[$0000:$0485],Colors^[5]);  { (doppelte Linie) }
     end else begin                                             { Selektierten Text schreiben (Weiss auf Blau) }
       ShowTextXY(Canvas,x,3,Colors^[6],Colors^[7],Copy(Text,CursorPos+1,SelLength));
     end;
   end;
   Options := o;
   if TestOption(Options, opt_Child) then begin         { Wenn temporÑress Canvas erzeugt, }
     Canv^.Insert(Canvas, Delta.X, Delta.Y);            { dann dieses wieder }
     Dispose(Canvas, Done);                             { entfernen. }
     Canvas := Canv;
   end;
 end;

 procedure LEdit.HandleEvent(var AEvent);
 var
   Event: LEvent absolute AEvent;
   ch   : Char;
   wrd  : Word;
 begin
   if TestOption(Options, opt_Disable) then Exit;
   if not (Parent = nil) then                   { Wenn Åbergeordnetes fenster nicht Fokus hat, abbrechen. }
    if not TestOption(Parent^.Options, opt_Focus) then Exit;
   inherited HandleEvent(AEvent);
   { *** Die Maus-Ereignisse: *** }
   if ((EventMask and ev_Mouse) > 0) and ((EventMask and ev_MVisible) > 0) then begin
   { Die Maus wird auf dem Object gedrÅckt, wÑrend das Object den Fokus hat: }
     if (Event.MButton = 1) and (Contain(Bounds,Event.Mouse.X,Event.Mouse.Y))
      and (TestOption(Options, opt_Focus)) then begin
       if MouseDelta.X = 0 then begin
       { AnfÑngliche Mauskoordinaten sichern: }
         MouseDelta.X := Event.Mouse.X;
         CursorPos := (Event.Mouse.X - Bounds.A.X) div 8;
       end else begin
       { Den selektierten Block der Mausbewegung anpassen: }
         SelLength := abs(MouseDelta.X - Event.Mouse.X) div 8;
         if MouseDelta.X > Event.Mouse.X
          then CursorPos := (Event.Mouse.X - Bounds.A.X) div 8
          else CursorPos := (MouseDelta.X - Bounds.A.X) div 8;
        { Neu zeichnen: }
         ReDraw;
       end;
       { Cursor oder selktierter Block nicht Åber die TextlÑnge hinaus. }
       if CursorPos > length(Text) then CursorPos := length(Text);
       if (CursorPos + SelLength) > length(Text)
        then SelLength := length(Text) - CursorPos;
     end else MouseDelta.X := 0;
   end;
   { *** Die Tastaturereignisse: *** }
   if ((EventMask and ev_Key) > 0) and (TestOption(Options, opt_Focus)) then begin
     { Eine "normale" ASCII-Taste: }
     if (Event.KeyCode mod $100) > 0 then begin
       ch := chr(Event.KeyCode mod $100);
       case ch of
         { BackSpace: }
         #8 : if SelLength > 0 then begin
           Delete(Text,CursorPos+1,SelLength);  { Selektierten Block lîschen }
           SelLength := 0;
           Event.KeyCode := 0;
         end else if CursorPos > 0 then begin   { letztes Zeichen lîschen }
           Event.KeyCode := 0;
           Delete(Text,CursorPos,1);
           dec(CursorPos);
         end;
         { Tab: }
         #9 : begin
           CursorPos := Length(Text);
           Options := Options and not opt_Focus;    { Fokus abgeben. }
         end;
         { Enter/Return: }
         #13 : begin
           Options := Options and not opt_Focus; ReDraw; { Fokus abgeben }
           if not (OkButton = nil) then begin            { OkButton auslîsen: }
             OkButton^.Options := OkButton^.Options or opt_Focus;
             Okbutton^.HandleEvent(Event);
           end;
         end;
       else
         { ASCII-Zeichen: }
         if SelLength > 0 then begin
           Delete(Text,CursorPos+1,SelLength);  { Selektierten Block lîschen }
           SelLength := 0;
         end;
         if (((CursorPos+1) * 8) < (Bounds.B.X-Bounds.A.X)) { PrÅfen, ob das Zeichen noch }
          and ((CursorPos) < MaxLength) then begin          { Platz hat. }
           Inc(CursorPos);                   { Cursor eins nach Rechts. }
           if Overwrite
            then begin
              if CursorPos > length(Text)
               then Text := Text + ch           { Text anhÑngen.      }
               else Text[CursorPos] := ch;      { Text Åberschreiben. }
            end else if length(Text) < MaxLength
             then Insert(ch,Text,CursorPos)     { Text einfÅgen. }
             else dec(CursorPos);
         end;
         Event.KeyCode := 0;       { Zeichen ist bearbeitet ! }
       end;
       ReDraw;                     { Neu zeichnen. }
     end else begin
       wrd := Event.KeyCode;
       Event.KeyCode := 0;
       Case wrd of
         { Delete: }
         $5300 : if SelLength > 0
          then begin
            Delete(Text,CursorPos+1,SelLength);
            SelLength := 0;
          end else if CursorPos < length(Text) then Delete(Text,CursorPos+1,1);
         { Linkspfeil: }
         $4B00 : begin
           if (Event.KeyState and st_Shift) = 0 then begin   { Wenn Shift gedrÅckt, dann }
             if CursorPos > 0 then
              if SelLength = 0
               then dec(CursorPos)
               else SelLength := 0;
           end else if CursorPos > 0 then begin              { ...Text selektieren }
             dec(CursorPos);
             inc(SelLength);
           end;
         end;
         { Rechtspfeil: }
         $4D00 : if (Event.KeyState and st_Shift) = 0 then begin   { Wenn Shift gedrÅckt,... }
             if (CursorPos+SelLength) < length(Text) then
              if SelLength = 0
               then inc(CursorPos)
               else CursorPos := CursorPos + SelLength;
             SelLength := 0;
           end else if (CursorPos+SelLength) < Length(Text)        { ...dann Text selektieren }
            then inc(SelLength);
         { Insert: }   { Umschalten zwischen EinfÅgen und öberschreiben. }
         $5200 : if Overwrite then overwrite := False else overwrite := True;
         { Home: }
         $4700 : begin
           CursorPos := 0;
           SelLength := 0;
         end;
         { End: }
         $4F00 : begin
           CursorPos := length(Text);
           SelLength := 0;
         end;
       else
         Event.KeyCode := wrd;
       end;
       if (Event.KeyCode = 0) and (wrd > 0) then ReDraw;  { Neu zeichnen. }
     end;
   end;
 end;

   { ***************************************************************** }
   {  ˘MyColor          EnthÑlt die momentan selektierte Farbe.        }
   {  Init              Setzt MyColor auf 0.                           }
   {  Draw              Zeichnet der Reihe nach alle 256 Farben auf    }
   {                     mit einer "Pixel"-Grîsse von 4x4 pro Farbe.   }
   {  HandleEvent       Reagiert auf einen Mausklick und lÑdt die an-  }
   {                     geklickte Farbe in das Feld "myColor"         }
   {  BigPixel          Zeichnet einen Pixel in Canvas, davon aus-     }
   {                     gehend, eine 4x4 Box sei ein Pixel.           }
   { ***************************************************************** }
 constructor LColorBox.Init(AParent : HView; ABounds : LRect);
 begin
   Inherited Init(AParent, ABounds);
   MyColor := 0;
   EventMask := EventMask or ev_Mouse;
 end;

 procedure LColorBox.Draw;
 var
   i,j: Byte;
 begin
   if not TestOption(Options, opt_Visible) then Exit;
   if (Canvas = nil) then begin
     HandleError(er_NoCanvas); Exit;
   end;
   Canvas^.Clear(0);
   For i := 1 to 8 do
    For j := 1 to 23 do begin
      BigPixel(i+1,j-1,((i-1)*24)+j+32);
   end;
   For i := 0 to 15 do begin
     BigPixel(0,i,i);
     BigPixel(1,i,i+16);
   end;
 end;

 procedure LColorBox.HandleEvent(var AEvent);
 var
   Event: LEvent absolute AEvent;
   x,y  : Integer;
 begin
   Inherited HandleEvent(AEvent);
   if (EventMask and ev_Mouse) > 0 then
    if TestOption(Options, opt_Mouse) and (Event.MButton = 1) then begin
      x := Event.Mouse.X - Bounds.A.X;
      y := Event.Mouse.Y - Bounds.A.Y;
      if not (Canvas = nil)
       then MyColor := Canvas^.GetPixel(x,y);
    end;
 end;

 procedure LColorBox.BigPixel(x,y: Word; AColor: Byte);
 var
   i,j: Byte;
 begin
   if not TestOption(Options, opt_Visible) then Exit;
   if Canvas = nil then begin
     HandleError(er_NoCanvas); Exit;
   end;
   x := x * 4; y := y * 4;
   For j := 1 to 4 do
    For i := 1 to 4 do
     Canvas^.SetPixel(x+i,y+j,AColor);
 end;

   { ***************************************************************** }
   {  ˘ExecResult       Speichert das Kommando ab, mit dem das Fenster }
   {                     geschlossen wurde.                            }
   {  ˘ExecBool         Dient intern dazu, dass LDialog nur auf Ereig- }
   {                     nisse reagiert, wenn diese von Execute kommen }
   {  Execute           FÅhrt den Dialog aus: Liest die Ereignisse ein }
   {                     und gibt sie zur Verarbeitung weiter, bis ein }
   {                     Kommando ausgelîst wird.                      }
   {  HandleEvent       Bricht ab, wenn ExecBool False ist.            }
   { ***************************************************************** }
 constructor LDialog.Init(ABounds: LRect; ACaption: String);
 begin
   Inherited Init(ABounds, ACaption);    { LWindow.Init aufrufen. }
   ExecResult := 0;                      { Kein RÅckgabekommando vorhanden. }
   ExecBool   := False;                  { Ereignissbehandlung sperren }
 end;

 procedure LDialog.Execute;
 var
   Event : LEvent;
   MVisib: Boolean;
 begin
   MVisib := (EventMask and ev_MVisible) > 0;    { Ist die Maus aktiv ? }
   ExecBool := True;                             { Eregnissbehandlung freigeben }
   Show;                                         { Dialog auf den Bildschirm darstellen. }
   Options := Options or opt_Focus; ReDraw;      { Fokus auf Dialog setzen. }
   repeat                                        { Wiederholen: }
     GetEvent(Event);                            { Event laden }
     Event.MVisible := MVisib;                   { Maus auf sicht- bzw. unsichtbar setzen }
     if not TestOption(Options, opt_Focus) then begin
       Options := Options or opt_Focus; ReDraw   { Fenster ist sicher angewÑhlt }
     end;
     HandleEvent(Event);                         { Ereignisse behandeln }
     if (Event.Command = cm_Close) then Break;   { Bei Close-Ereigniss auch schliessen }
   until (Event.Command > $0F);                  { Bis ein Kommando ausgelîst wurde.  }
   ExecBool := False;                            { Ereignissbehandlung wieder sperren }
   ExecResult := Event.Command;                  { Kommando fÅr Weitergabe speichern  }
   Hide;                                         { Dialog entfernen. }
 end;

 procedure LDialog.HandleEvent(var AEvent);
 begin
   if not ExecBool then Exit;                   { Wenn nicht mit Execute ausgefÅhrt wird, dann Abbrechen }
   Inherited HandleEvent(AEvent);               { LWindow.HandleEvent aufrufen }
 end;

   { ***************************************************************** }
   {  ˘First            Ein Zeiger auf das erste Element in der Liste. }
   {  ˘Count            Anzahl der Elemente.                           }
   {  Init              Setzt First und Count auf Null.                }
   {  Done              Gibt allen Speicher wieder frei.               }
   {  Add               FÅgt der Liste ein neues Element hinzu.        }
   {  Insert            FÅgt ein neues Element in die Liste ein.       }
   {  Delete            Lîscht ein Element aus der Liste.              }
   {  GetStr            Gibt den Text von Element Nr zurÅck (Bei Null  }
   {                     beginnend)                                    }
   {  SetStr            Weist dem Element Nr einen neuen Text hinzu.   }
   {  Sort              Sortiert alle Elemente dem Alphabet (ASCII-    }
   {                     Wert) nach, aufsteigend (A-Z).                }
   { ***************************************************************** }
  constructor LStringList.Init;
  begin
    inherited Init;
    Count := 0; First := nil;    { Anfangs noch keine Strings enthalten }
  end;

  destructor LStringList.Done;
  var
    i: Word;
  begin
    For i := (Count - 1) downto 0 do
     Delete(i);
    inherited Done;
  end;

  procedure LStringList.Add(AText: String);
  var
    p,q: HSItem;
    s: Byte;
  begin
    s := 5 + ord(AText[0]);     { Grîsse des Speichernedarfes berechnen }
    GetMem(p,s);                { Speicher reservieren }
    if p = nil then Exit;       { Wenn nicht erfolgreich, abbrechen }
    p^.Next := nil; p^.Size := s; { Grîsse und Zeiger auf nÑchstes setzen }
    For s := 1 to (s-5) do      { Text Åbertragen }
     p^.Text[s] := AText[s];
    if (Count = 0) then begin   { Ersten String einfÅgen: }
      First := p; Count := 1;   { Als erster String einfÅgen, Anzahl auf 1 }
    end else begin
      q := First;               { Zuerst bis ans Ende der Liste gehen }
      while not (q^.Next = nil) do q := q^.Next;
      q^.Next := p;             { Als letztes einfÅgen }
      inc(Count);               { Anzahl erhîhen. }
    end;
  end;

  function LStringList.GetStr(Nr: Word): String;
  var
    p: HSItem;
    s: String;
    i: Byte;
  label Fertig;
  begin
    s := ''; p := First; i := Nr;               { Buffer initialisieren }
    while (i > 0) do begin                      { GewÅnschte Anzahl Åberspringen }
      if (p^.Next = nil) or (p = nil) then Goto Fertig;
      p := p^.Next; dec(i);
    end;
    For i := 1 to (p^.Size - 5) do              { Text in den Buffer }
     s := s + p^.Text[i];
  Fertig: GetStr := s;                          { Text als RÅckgabeparameter }
  end;

  procedure LStringList.Insert(Nr: Word; AText: String);
  var
    p,n: HSItem;
    i,s: Word;
  begin
    s := ord(AText[0]) + 5;                     { Speicherbedarf berechnen }
    GetMem(n,s); if (n = nil) then Exit;        { Speicher reservieren }
    n^.Size := s;                               { Grîsse ins Objekt laden }
    For i := 1 to (s - 5) do n^.Text[i] := AText[i];  { Text Åbertragen }
    if Nr = 0 then begin                        { Als erstes einfÅgen. }
      n^.Next := First;
      First := n;
    end else begin                              { In der Kette einfÅgen }
      p := First; i := Nr - 1;
      While (i > 0) do begin                    { Bis zu (Nr-1) alle Åberspringen }
        if (p^.Next = nil) or (p = nil) then Exit;
        p := p^.Next; dec(i);
      end;
      n^.Next := p^.Next;                       { n einfÅgen }
      p^.Next := n;
    end;
    inc(Count);                                 { Anzahl erhîhen. }
  end;

  procedure LStringList.Delete(Nr: Word);
  var
    p,q: HSItem;
    i  : Byte;
  begin
    if (Nr + 1) > Count then Exit;              { Abbrechen, wenn ausserhalb des Bereiches. }
    if (Nr = 0) then begin                      { Ersten Eintrag lîschen }
      q := First^.Next;                         { Zweiten Eintrag sichern }
      FreeMem(First, First^.Size);              { Ersten lîschen }
      First := q;                               { Zweiten als ersten eintragen }
    end else begin                              { Eintrag in der Kette lîschen }
      p := First; i := Nr - 1;                  { Zuerst zu Element (n-1) springen }
      while (i > 0) do begin
        if (p = nil) or (p^.Next = nil) then Exit;
        p := p^.Next;
        dec(i);
      end;
      q := p^.Next;                             { q ist zu lîschen }
      p^.Next := q^.Next;                       { Kette Åber q hinweg wieder "zuflicken" }
      FreeMem(q,q^.Size);                       { q lîschen }
    end;
    dec(Count);                                 { Anzahl um eins kleiner }
  end;

  procedure LStringList.SetStr(Nr: Word; AText: String);
  begin
    if (Nr+1) > Count then Exit;
    Delete(Nr); Insert(Nr, AText);
  end;

  procedure LStringList.Sort;
  var
    i,j: Word;
    s,t: String;
  begin
    if Count = 0 then Exit;     { Nicht sortieren, wenn Objekt leer }
    For i := (Count - 2) to 1 do
     For j := 0 to (i - 1) do begin
       s := GetStr(j);
       t := GetStr(j+1);
       if (s > t) then begin
         SetStr(j,t); SetStr(j+1,s);
       end;
     end;
  end;

  procedure LStringList.LoadFromFile(AFileName: String);
  var
    f     : TextFile;
    Buffer: String;
    i     : Word;
  begin
    Assign(f, AFileName);               { Dateinamen zuweisen. }
    {$I-}                               { öberprÅfung deaktivieren }
     ReSet(f);                          { Datei îffnen }
     if not (IoResult = 0) then Exit;   { Verusch fehlgeschlagen ? }
    {$I+}                               { öberprÅfung aktivieren }
    For i := (Count - 1) downto 0 do    { Alle Listenelement lîschen }
     Delete(i);
    while not eof(f) do begin           { Die Datei einlesen. }
      ReadLn(f, Buffer);
      Add(Buffer);
    end;
    Close(f);                           { Die Datei schliessen. }
  end;

  procedure LStringList.SaveToFile(AFileName: String);
  var
    f     : TextFile;
    Buffer: String;
    i     : Word;
  begin
    Assign(f, AFileName);               { Datei zuweisen. }
    ReWrite(f);                         { Datei neu erstellen }
    For i := 0 to (Count - 1) do begin  { Strings in Datei speichern }
      Buffer := GetStr(i);
      WriteLn(f, Buffer);
    end;
    Close(f);                           { Datei schliessen. }
  end;

   { ***************************************************************** }
   {  ˘Select           Gibt das Selektierte Element an (beginnend bei }
   {                     Null)                                         }
   {  ˘StrList          Ein Zeiger auf die StringListe.                }
   {  ˘FirstVisible     Legt den sichtbaren Bereich fest (Scrollen)    }
   {  ˘KlickFlag        Wird benîtigt, damit bei einmaligem Klicken    }
   {                     auf die Scrollbuttons nicht die ganze Liste   }
   {                     durchgescrollt wird.                          }
   {  Init              Setzt alles auf Null, erzeugt jedoch noch      }
   {                     keine Stringliste.                            }
   {  AssignList        Weist der Liste eine Stringliste zu. Ist der   }
   {                     Parameter gleich Null, wird eine Neue, leere  }
   {                     Liste erzeugt.                                }
   {  HandleEvent       Reagiert standartmÑssig auf Maus und Tastatur. }
   { ***************************************************************** }
 constructor LList.Init(AParent: HView; ABounds: LRect);
 begin
   Inherited Init(AParent, ABounds);
   Select := 0;
   StrList:= nil;
   EventMask := EventMask or ev_Mouse or ev_Key;
   KlickFlag := False;
   FirstVisible := 0;
 end;

 destructor LList.Done;
 begin
   if not (StrList = nil)
    then Dispose(StrList, Done);
   Inherited Done;
 end;

 procedure LList.InitColors;
 begin
   GetMem(Colors, 8);
   if (Colors = nil) then begin
     HandleError(er_NoColors); Exit;
   end;
   Colors^[0] := 8;                { Grîsse in Bytes }
   Colors^[1] := $10;              { Schrift }
   Colors^[2] := $1F;              { Hintergrund }
   Colors^[3] := $12;              { Rahmen Hell }
   Colors^[4] := $1D;              { Rahmen Dunkel }
   Colors^[5] := $1F;              { Schrift selektiert }
   Colors^[6] := $20;              { Hintergrund selektiert }
   Colors^[7] := $19;              { Button-Hintergrund }
 end;

 procedure LList.AssignList(AList: HStringList);
 begin
   if not (StrList = nil)
    then Dispose(StrList, Done);                { Alte Liste lîschen }
   if not (AList = nil)                         { Neue Liste zuweisen oder }
    then StrList := AList                       { gegebenenfalls selbst }
    else StrList := New(HStringList, Init);     { erstellen. }
 end;

 procedure LList.Draw;
 var
   i,m,n: Word;
   s: String;
   c: Byte;
   CharSize: Byte absolute $0000:$0485;
   TextCanv: HCanvas;
 begin
   if not TestOption(Options, opt_Visible) then Exit;   { PrÅfen, ob das Objekt }
   if (Canvas = nil) then begin                         { wirklich gezeichnet werden soll und }
     HandleError(er_NoCanvas); Exit;                    { ein Canvas vorhanden ist. }
   end;
   if (StrList = nil) then Exit;                        { Wenn keine Liste vorhanden, abbrechen }
   m := (Bounds.B.Y - Bounds.A.Y - 10) div (CharSize + 2) - 1;  { Diese berechnungen werden hier durchgefÅhrt, }
   n := (Bounds.B.X - Bounds.A.X - 8);                          { um Zeit und Platz zu sparen. }
   TextCanv := New(HCanvas, Init(n,CharSize+2,0));      { TemporÑres Canvas erzeugen. }
   For i := 0 to m do begin                             { Jedes Listenelement einzeln darstellen. }
     if ((i + FirstVisible) = Select) then c := 5 else c := 1;     { Farbe wÑhlen }
     if (TextCanv = nil)                                           { Wenn kein temporÑres Canvas vorhanden, direkt schreiben }
      then ShowTextXY(Canvas, Delta.X+4, Delta.Y+4+(i*(CharSize+2)),Colors^[c],Colors^[c+1],StrList^.GetStr(i+FirstVisible))
      else begin
        TextCanv^.Clear(Colors^[c+1]);                  { sonst mit Hilfe des Canvas. }
        DrawTextXY(TextCanv,2,1,Colors^[c],0,StrList^.GetStr(i+FirstVisible));
        Canvas^.Insert(TextCanv,Delta.X+3,Delta.Y+4+(i*(CharSize+2)));
      end;
   end;
   if not (TextCanv = nil) then Dispose(TextCanv, Done);        { TemporÑres Canvas entfernen }
   if TestOption(Options, opt_ScrollV) then begin               { Unter UmstÑnden die Scroll-Buttons zeichnen }
     TextCanv := New(HCanvas, Init(20,10,0));                   { Wieder temporÑres Canvas erzeugen }
     if not (TextCanv = nil) then begin
       TextCanv^.Clear(Colors^[7]);                      { Buttons zeichnen }
       TextCanv^.Dim3(Colors^[3],Colors^[4]);
       Canvas^.Insert(TextCanv,Delta.X+n-12,Delta.Y);    { In Canvas einfÅgen. }
       Canvas^.Insert(TextCanv,Delta.X+n-12,Delta.Y+Bounds.B.Y-Bounds.A.Y-10);
       Dispose(TextCanv, Done);                          { TemporÑres Canvas entfernen }
     end;
   end;
 end;

 procedure LList.HandleEvent(var AEvent);
 var
   Event   : LEvent absolute AEvent;
   CharSize: Byte absolute $0000:$0485;
   sel,n,m : Word;
   R       : LRect;
 begin
   Inherited HandleEvent(AEvent);                       { Standart-Routinen ausfÅhren. }
   if (Options and opt_Focus) = 0 then Exit;            { Nur, wenn Objekt Focus besitzt. }
   if Event.MButton = 0 then KlickFlag := False;        { Dient zur Åberwachung der Scrollbuttons }
   if ((EventMask and ev_Mouse) > 0) and (Event.MButton = 1) then begin    { Maus-Ereignisse: }
     if TestOption(Options, opt_ScrollV) and not KlickFlag then begin   { Scrollbuttons ? }
       m := Delta.Y + Bounds.A.Y; n := Delta.X + Bounds.B.X;   { Rechnungen vorgezogen zur öbersichtlichkeit }
       SetRect(R,n-20,m,n,m+10);                               { ...um Zeit zu sparen. }
       if Contain(R,Event.Mouse.X,Event.Mouse.Y) and (FirstVisible > 0) then begin  { Oberer Button gedrÅckt. }
         dec(FirstVisible);                                          { Als Erstes Elemnt eines weiter nach Oben. }
         n := (Bounds.B.Y - Bounds.A.Y - 20) div (CharSize + 2);
         if ((FirstVisible+n) < Select) then dec(Select); { Selektiertes Feld immer innerhalb Bereich }
         KlickFlag := True;   { Verhindert, dass durch einmaliges Klicken gleich die ganze Liste bid zum Ende scrollt. }
         ReDraw; Exit;        { Neuzeichnen und keine weiteren Ereignisse behandlen... }
       end;
       m := Delta.Y + Bounds.B.Y;
       SetRect(R,n-20,m-10,n,m);                        { Unterer Button }
       if Contain(R,Event.Mouse.X,Event.Mouse.Y) and (FirstVisible < (StrList^.Count - 1)) then begin
         inc(FirstVisible);                             { Sichtbereich eins nach Unten. }
         if (FirstVisible > Select) then inc(Select);   { Selektiertes Feld innerhalb Bereich }
         KlickFlag := True;
         ReDraw; Exit;
       end;
     end;
     { Ein Eintrag wurde gewÑhlt: }
     Sel := FirstVisible + ((Event.Mouse.Y - Bounds.A.Y - 4) div (CharSize + 2));
     if (Sel < StrList^.Count) then Select := Sel;
     ReDraw;                        { Neu zeichnen }
   end;
   if (EventMask and ev_Key) > 0 then begin     { Tastaturereignisse: }
     Case Event.KeyCode of
       $4800: if (Select > 0) then begin        { AufwÑrtspfeil: }
         dec(Select);                           { letztes Selektieren }
         if (FirstVisible > Select) then dec(FirstVisible); { Innerhalb sichtbaren Bereiches bleiben }
         ReDraw;                                            { Neu zeichnen. }
       end;
       $5000: if (Select < (StrList^.Count - 1)) then begin     { AbwÑrtspfeil: }
         inc(Select);                           { nÑchstes Element }
         n := (Bounds.B.Y - Bounds.A.Y - 20) div (CharSize + 2); { Innerhalb des sichtbaren Bereiches bleiben }
         if ((FirstVisible + n) < Select) then inc(FirstVisible);
         ReDraw;                                { Neu zeichnen }
       end;
     end;
   end;
 end;

   { ***************************************************************** }
   {  Dieses Objekt ist eine Erweiterung des Objektes LMouse aus der   }
   { Unit GObjects. Hier wird jedoch die Maus mit Hilfe der Tastatur   }
   { simuliert.                                                        }
   {                                                                   }
   {  LWordArray        Dient zum Zugriff auf die Cursordaten.         }
   {                                                                   }
   {  ˘Saver            EnthÑlt das abgespeicherte Hintergrundbild.    }
   {  Run               Behandelt die Tastaturereignisse.              }
   {  Show              Stellt den Cursor dar.                         }
   {  Hide              Lîscht den Cursor vom Bildschirm.              }
   {  SetCursor         Setzt einen neuen Cursor.                      }
   {  Draw              Zeichnet den Cursor an der richtigen Position. }
   {  ReMove            Stellt den Hintergrund wieder her.             }
   { ***************************************************************** }
 procedure LKMouse.Run;
 var
   k: Byte;
 begin
   { Setzt die Tastaturereignisse in Mausereignisse um. }
   if (ShiftState and st_Shift) = 0        { Wenn gleichzeitig Shift gedrÅckt, }
    then k := 2                            { ...dann nicht um 2, sondern um 20 }
    else k := 20;                          { ...weitergehen }
   Button := 0;                            { StandartmÑssig: Kein Button gedrÅckt }
   case KeyCode of
     { Leertaste }
     kb_Space : if k = 2
      then Button := 1                 { Mit Shift zusammen wird die Leertaste }
      else Button := 2;                { zum rechten Mausbutton. }
     { Pfeil nach Oben }
     kb_Up : begin
       ReMove;
       if (Where.Y > k) then Where.Y := Where.Y - k;
       Draw;
     end;
     { Pfeil Links }
     kb_Left : begin
       ReMove;
       if (Where.X > k) then Where.X := Where.X - k;
       Draw;
     end;
     { Pfeil Rechts }
     kb_Right : begin
       ReMove;
       if (Where.X < Screen.X - k) then Where.X := Where.X + k;
       Draw;
     end;
     { Pfeil Down }
     kb_Down : begin
       ReMove;
       if (Where.Y < Screen.Y - k) then Where.Y := Where.Y + k;
       Draw;
     end;
   end;
 end;

 procedure LKMouse.Show;
 begin
   if Visible then Exit;
   Visible := True;
   Draw;
 end;

 procedure LKMouse.Hide;
 begin
   if not Visible then Exit;
   ReMove;
   Visible := False;
 end;

 procedure LKMouse.Draw;
 var
   x1,y1: Word;
   i,j  : Byte;
   Buff : Word;
   Bild : HCanvas;
 begin
   if not Visible then Exit;                         { Nur zeichnen, wenn der Cursor sichtbar ist }
   x1 := Where.X - HWordArray(AktCursor)^[0];        { Die Koordinaten berechnen }
   y1 := Where.Y - HWordArray(AktCursor)^[1];
   Saver := GetPicture(x1,y1,x1+16,y1+16);           { Den Hintergrund abspeichern }
   Bild := New(HCanvas, Init(16,16,0));              { Bild fÅr den Zeiger generieren }
   if not (Bild = nil) then begin                    { Cursor in Bild zeichnen }
     For i := 0 to 15 do begin
       Buff := HWordArray(AktCursor)^[i+2];
       For j := 0 to 15 do begin
         if (Buff and $8000) = 0 then Bild^.SetPixel(j,i,$10);
         Buff := Buff shl 1;
       end;
     end;
     Bild^.Show(x1,y1);                              { Cursor auf den Bildschirm }
     Dispose(Bild, Done);                            { Speicher wieder freigeben }
   end;
 end;

 procedure LKMouse.ReMove;
 var
   x1,y1: Word;
 begin
   if not Visible then Exit;
   x1 := Where.X - HWordArray(AktCursor)^[0];        { Die Koordinaten berechnen }
   y1 := Where.Y - HWordArray(AktCursor)^[1];
   if not (Saver = nil) then begin
     Saver^.Show(x1,y1);
     Dispose(Saver, Done);
   end;
 end;

 procedure LKMouse.SetCursor(var ACursor);
 var
   Buf: Boolean;
 begin
   Buf := Visible;
   if Buf then Hide;
   AktCursor := @ACursor;
   if Buf then Show;
 end;
END.