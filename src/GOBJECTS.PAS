{                                       }
{       (c) 1998 Tobias Kohn            }
{                                       }
UNIT GObjects;
{ ************************************************************************** }
{  Diese Unit enthÑlt einige Grund-Objekte fÅr das Arbeiten im Graphimodus   }
{ mit 256 Farben. Zum benutzen dieser Unit werden die Units "Graph2" und     }
{ "XMS" benîtigt.                                                            }
{  Die Unit "Graph2" stellt die notwendigen Objekte und Funktionen fÅr das   }
{ Ausgeben von Graphiken zur VerfÅgung. Damit diese Unit arbeiten kann,      }
{ benîtigt ihr Computer jedoch eine VESA-Kompatible Karte und einen Bild-    }
{ schirm mit 256 Farben (mind 256 Farben).                                   }
{  Die Unit "XMS" verwaltet den oberen Speicherbereich. Die Fensterobjekte   }
{ zum Beispiel legen den Hintergrund im oberen Speicherbereich ab. Falls sie }
{ dies nicht wollen, so stellen sie bei den Optionen in ihrem Fenster die    }
{ Option "opt_SaveBackG" aus (Options := Options and not opt_SaveBackG;).    }
{  Die Canvas-Objekte, die in der Unit "Graph2" deklariert sind, zeichnen    }
{ ein Bild zuerst in den Speicher und dann (durch die Methode "Show") auf    }
{ Bildschirm. Damit genug Speicher vorhanden ist, mÅssen sie mit dem Com-    }
{ piler-Befehl $M (siehe Handbuch oder Hilfe) den maximalen Heap auf ein     }
{ Minimum setzen. Gleichzeitig sollten die den Stack mîglichst gross machen. }
{ ************************************************************************** }
INTERFACE
{ ************************************************************************** }
 USES Graph2;

 CONST
   { *** Die Scancodes der Tasten von A bis Z *** }
   ScanCodes : Array['A'..'Z'] of Byte = (30,48,46,32,18,33,34,35,23,36,
                                          37,38,50,49,24,25,16,19,31,20,
                                          22,47,17,45,44,21);

   { *** BITFELDER FöR DIE MAUSZEIGER: *** }
  { Standart-Pfeil: }
   c1: Array[0..33] of Word =
        ($0001,$0001,
         $3FFF,$1FFF,$0FFF,$07FF,$03FF,$01FF,$00FF,$007F,
         $003F,$001F,$003F,$00FF,$B0FF,$F87F,$F87F,$FCFF,
         $0000,$4000,$6000,$7000,$7800,$7C00,$7E00,$7F00,
         $7F80,$7FC0,$7E00,$4600,$0600,$0300,$0300,$0000);
  { "Editier-Balken" }
   c2: Array[0..33] of Word =
        ($0007,$0007,
         $F39F,$FD7F,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,
         $FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FD7F,$F39F,
         $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
         $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000);
  { Spiele-Kreuz }
   c3: Array[0..33] of Word =
        ($0007,$0007,
         $FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FD7F,$0381,
         $FD7F,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FEFF,$FFFF,
         $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
         $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000);

   { *** OPTION - KONSTANTEN *** }
    opt_None    = $0000;        { Keine Optionen   }
    opt_Init    = $0001;        { Object verfÅgbar }
    opt_Visible = $0002;        { Object auf dem Bildschirm }
    opt_Child   = $0004;        { Object ist untergeordnet  }
    opt_3D      = $0008;        { Object mit 3D-Rahmen darstellen }
    opt_Focus   = $0010;        { Object hat momentan gerade den Focus. }
    opt_Select  = $0020;        { Maus mit gedrÅckter Taste auf Object. }
    opt_Mouse   = $0040;        { Maus auf Object.                 }
    opt_Disable = $0080;        { Objekt momentan nicht verfÅgbar. }
    opt_Window  = $0100;        { Objekt ist ein Fenster.          }
    opt_SaveBackG=$0200;        { Ein Fenster speichert den Hintergrund, bevor es sich zeichnet. }
    opt_ScrollH = $0400;        { Horizontale Scroll-Bar }
    opt_ScrollV = $0800;        { Vertikale Scroll-Bar }

   { *** FEHLER - KONSTANTEN *** }
    er_NoError  = $0000;         { Kein Fehler }
    er_NoCanvas = $0001;         { Canvas fehlt (nicht initialisiert) }
    er_NoColors = $0002;         { Farbepalette fehlt (nicht initialisiert) }
    er_SmRect   = $0003;         { Zu kleines Rechteck (Koordinaten zu dicht) }

    er_Opt_Halt = $1000;         { Programm sofort anhalten }
    er_Opt_Msg  = $2000;         { Mitteilung ausgeben      }
    er_Opt_Done = $4000;         { Object entfernen         }
    er_opt_Run  = $8000;         { Runtime-Error auslîsen   }

   { *** KOMMANDO - KONSTANTEN *** }
    cm_None     = $0000;    cm_OK       = $0010;
    cm_Quit     = $0001;    cm_Cancel   = $0011;
    cm_Close    = $0002;    cm_Yes      = $0012;
    cm_Help     = $0003;    cm_No       = $0013; {8}
    cm_ReDraw   = $0004;    cm_Continue = $0014;
    cm_Mouse    = $000A;

   { *** EREIGNISSMASKEN - KONSTANTEN *** }
    ev_None     = $0000;         { Keine Ereignisse }
    ev_MButton  = $0001;         { Auf Mausdruck }
    ev_MouseXY  = $0002;         { Auf Mauskoordinaten }
    ev_Mouse    = $0003;         { Auf gesamte Maus }
    ev_KeyCode  = $0004;         { Auf Tasten }
    ev_KeyState = $0008;         { Auf StatusTasten (Shift, Alt...) }
    ev_Key      = $000C;         { Auf gesamte Tastatur }
    ev_Command  = $0010;         { Auf Kommandos }

    ev_MVisible = $0080;         { Maus ist sichtbar }

   { *** KEYSTATE - KONSTANTEN *** }
    st_None   = $00;    st_Alt    = $08;
    st_ShiftR = $01;    st_Scroll = $10;
    st_ShiftL = $02;    st_Num    = $20;
    st_Shift  = $03;    st_Caps   = $40;
    st_Ctrl   = $04;    st_Ins    = $80;
    st_Strg   = $04;

   { *** Einige Tastatur-Codes: *** }
    kb_Up     = $4800;  kb_Space  = $3920;  kb_F1   = $3B00;
    kb_Down   = $5000;  kb_BackSp = $0E08;  kb_F2   = $3C00;
    kb_Left   = $4B00;  kb_Esc    = $011B;  kb_F3   = $3D00;
    kb_Right  = $4D00;  kb_Tab    = $0F09;  kb_F4   = $3E00;
    kb_Enter  = $1C0D;  kb_AltX   = $2D00;  kb_F5   = $3F00;
    kb_Return = $1C0D;  kb_AltF3  = $6A00;  kb_F6   = $4000;
    kb_PageUp = $4900;  kb_Home   = $4700;  kb_F7   = $4100;
    kb_PageDn = $5100;  kb_End    = $4F00;  kb_F8   = $4200;

 TYPE
   { ***************************************************************** }
   {  Stellt einen String fÅr 127 Zeichen sowie einen dazugehîrigen    }
   { Zeiger zur VerfÅgung.                                             }
   { ***************************************************************** }
   HString = ^LString;
   LString = String[127];

   { ***************************************************************** }
   {  Speichert die Koodinaten eines Punktes auf dem Bildschirm.       }
   { ***************************************************************** }
   HPoint = ^LPoint;
   LPoint = record
     X,Y : Integer;
   end;

   { ***************************************************************** }
   {  Speichert die Koodinaten eines Rechtecks auf dem Bildschirm.     }
   { ***************************************************************** }
   HRect = ^LRect;
   LRect = Record
     A,B : LPoint;
   end;

   { ***************************************************************** }
   {  Speichert die Ereignisse und gibt sie and andere Objecte weiter. }
   { ***************************************************************** }
   HEvent = ^LEvent;
   LEvent = record
     Command  : Word;            { Kommando }
     KeyCode  : Word;            { Taste    }
     KeyState : Byte;            { Statustasen }
     MButton  : Byte;            { Maustasten  }
     Mouse    : LPoint;          { Mauskoordinaten }
     MVisible : Boolean;         { Maus sichtbar   }
     Parameter: Pointer;         { Parameter       }
   end;

   { ***************************************************************** }
   {  Die Farbpalette.                                                 }
   { ***************************************************************** }
   HColors = ^LColors;
   LColors = Array[0..31] of Byte;

   { ***************************************************************** }
   {  Stellt die Grundlage fÅr alle auf dem Bildschirm sichtbaren      }
   { Objecte dar.                                                      }
   {  ˘Bounds           Die Koordinaten des Objects auf dem Bildschirm }
   {  ˘Options          Speichert Einstellungen fÅe das Object.        }
   {  ˘Colors           Die Farbpalette                                }
   {  ˘Canvas           Die "Zeichnungsunterlage"                      }
   {  ˘Parent           Das Åbergeordnete Fenster                      }
   {  ˘Next             Ein Zeiger auf das nÑchste Fenster in einer    }
   {                     Liste.                                        }
   {  ˘EventMask        Speichert, auf welche Ereignisse das Object    }
   {                     reagiert.                                     }
   {  ˘Delta            Bei untergeordneten Objekten, ist der eigene   }
   {                     Punkt (0|0) nicht an der Stelle (0|0) des     }
   {                     Canvas. Delta zeigt nun auf den eigenen Punkt }
   {                     (0|0). Bei "normalen" objekten ist Delta      }
   {                     immer Null. Aus kompatibilitÑtsgrÅnden sollte }
   {                     Delta jedoch immer (!) verwendet werden.      }
   {  ˘Client           EnthÑlt die Ausdehnung in X bzw. Y-Achse. Das  }
   {                     heisst, hier ist die Grîsse des Objektes ab-  }
   {                     gelegt.                                       }
   {  ˘Cursor           Zeigt auf den Cursor, der aktiviert werden     }
   {                     soll, wenn die Maus sich auf dem Objekt be-   }
   {                     findet.                                       }
   {  Init              Initialisiert das Object und setzt gewisse     }
   {                    Standarteinstellungen.                         }
   {  Done              Gibt belegten Speicher wieder frei.            }
   {  Show              Legt eine  "Zeichnungsunterlage" im Speicher   }
   {                     an und sorgt dafÅr, dass das Bild zum ersten  }
   {                     Mal gezeichnet wird.                          }
   {  Hide              Gibt die "Zeichnungsunterlage" wieder frei und }
   {                     sperrt alle Darstellungsroutinen.             }
   {  Draw              Zu Åberschreiben ! Zeichnet das Bild in den    }
   {                     Speicher.                                     }
   {  ReDraw            Ruft Draw auf und ÅbertrÑgt danach das Bild    }
   {                     auf den Bildschirm.                           }
   {  InitColors        Kann Åberschrieben werden. Belegt Speicher fÅr }
   {                     die Farbpalette und setzt Anfangswerte.       }
   {  HandleError       Behandelt Fehler.                              }
   {  HandleEvent       Behandelt die Ereignisse                       }
   { ***************************************************************** }
   HView = ^LView;
   LView = object(LObject)
     Bounds  : LRect;
     Options : Word;
     Colors  : HColors;
     Canvas  : HCanvas;
     Parent  : HView;
     Next    : HView;
     EventMask : Byte;
     Delta   : LPoint;
     Client  : LPoint;
     Cursor  : Pointer;
     BMPName : HString;
     constructor Init(AParent : HView; ABounds : LRect);
     destructor Done; virtual;
     procedure Show; virtual;
     procedure ShowBmp(AName: String); virtual;
     procedure Hide; virtual;
     procedure Draw; virtual;
     procedure ReDraw; virtual;
     procedure InitColors; virtual;
     procedure HandleError(Nr : Integer); virtual;
     procedure HandleEvent(var AEvent); virtual;
   end;

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Text des Buttons.                  }
   {  ˘MyCmd            Das Kommando, welches der Button auslîst.      }
   {  ˘MKeyPos          Der Index des Buchstabens, welcher mit der Alt }
   {                     Taste zusammen das Kommando des Buttons aus-  }
   {                     lîst.                                         }
   {  Init              => Siehe LView /// Um einen Buchstaben im      }
   {                     Namen unterstreichen zu lassen und als KÅrzel }
   {                     zu verwenden, stellen sie ihm ein "&" bevor.  }
   { ***************************************************************** }
   HButton = ^LButton;
   LButton = object(LView)
     Caption : String[31];
     MyCmd   : Word;
     MKeyPos : Byte;
     constructor Init(AParent: HView; ABounds: LRect; ACaption: String; ACmd: Word);
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
     procedure InitColors; virtual;
   end;

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Titel des Fensters.                }
   {  ˘First            Ein zeiger auf das erste untergeordnete Object }
   {  ˘CloseBut         Ob der Close-Button links-oben gerade gedrÅckt }
   {                     wird.                                         }
   {  ˘XMS_Handle       Der Hintergrund wird im hohen Speicherbereich  }
   {                     abgelegt. Dies ist das Zugriffshandle.        }
   {  ˘MouseDelta       Dient zur Verschiebung des Fensters.           }
   {  ˘myKey            Gibt die Taste an, bei der das Fenster ge-     }
   {                     schlossen wird.                               }
   {  Init              Ein Fenster kann kein Åbergeordnetes Object    }
   {                     besitzen.                                     }
   {  Done              Alle untergeordneten Objecte werden ebenfalls  }
   {                     entfernt.                                     }
   {  Insert            FÅgt ein untergeordnetes Object ein.           }
   {  HandleMove        Wird zur Verschiebung des Fensters aufgerufen. }
   {  MoveMe            Verschiebt das Fenster um Dx bzw. DY Pixel.    }
   {  CanClose          PrÅft, ob das Fenster momentan geschlossen     }
   {                     werden darf. Kann Åberschrieben werden.       }
   {  SetFocus          Setzt beim angegebenen Fenster den Focus und   }
   {                     lîscht ihn bei allen andren.                  }
   { ***************************************************************** }
   HWindow = ^LWindow;
   LWindow = object(LView)
     Caption  : String;
     First    : HView;
     CloseBut : Boolean;
     XMS_Handle : Word;
     MouseDelta : LPoint;
     myKey    : Word;
     constructor Init(ABounds: LRect; ACaption: String);
     destructor Done; virtual;
     procedure Insert(AView: HView);
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
     procedure InitColors; virtual;
     procedure Show; virtual;
     procedure Hide; virtual;
     procedure HandleMove(var AEvent); virtual;
     procedure MoveMe(Dx,Dy: Integer); virtual;
     function CanClose: Boolean;
     procedure SetFocus(AView: HView);
   end;

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Text des Labels.                   }
   {  ˘TextStyle        Die Schriftart, die benutzt wird.              }
   {  ˘FocusCtrl        Zeigt auf ein anderes Objekt, das gegebenen-   }
   {                     falls anstatt des Labels selektiert wird.     }
   {  ˘MKeyPos          Der Index des Buchstabens, welcher mit der Alt }
   {                     Taste zusammen das Kommando des Buttons aus-  }
   {                     lîst.                                         }
   {  InitColors        Falls ein Åbergeordnetes Fenster vorhanden ist }
   {                     werden dessen ersten 2 Farben Åbernommen.     }
   { ***************************************************************** }
   HLabel = ^LLabel;
   LLabel = object(LView)
     Caption   : String;
     TextStyle : Byte;
     FocusCtrl : HView;
     MKeyPos   : Byte;
     constructor Init(AParent: HView; ABounds: LRect; ACaption: String);
     procedure InitColors; virtual;
     procedure Draw; virtual;
     procedure HandleEvent(var AEvent); virtual;
   end;

   { ***************************************************************** }
   {  ˘Where            EnthÑlt nach einem Aufruf von Run die Koordi-  }
   {                     naten der Maus.                               }
   {  ˘Button           EnthÑlt den gedrÅckten Mausbutton.             }
   {  ˘Visible          Ob die Maus sichtbar ist.                      }
   {  ˘StdCursor        Ein Zeiger auf den Standart-Mauscursor.        }
   {  ˘AktCursor        EnthÑlt den aktuellen Cursor.                  }
   {  ˘KeyCode          Werden fÅr die Erweiterung einer Tastatur-     }
   {  ˘ShiftState        Steuerung benîtigt.                           }
   {  Init              Initialisiert die Maus und setzt die Anfangs-  }
   {                     werte fÅr die Felder.                         }
   {  Done              Entfernt die Maus vom Bildschirm.              }
   {  Show              Stellt die Maus dar.                           }
   {  Hide              Entfernt die Muas vom Bildschirm.              }
   {  Run               Setzt die Felder mit dem Mausdaten.            }
   {  SetPos            Setzt die Maus auf die Koordinaten von Where.  }
   {  SetCursor         Setzt einen neuen Cursor.                      }
   {  Wait              Wartet, bis die Maustaste wieder losgelassen   }
   {                     wurde.                                        }
   { ***************************************************************** }
   HMouse = ^LMouse;
   LMouse = object(LObject)
     Where : LPoint;
     Button: Byte;
     Visible:Boolean;
     StdCursor: Pointer;
     AktCursor: Pointer;
     KeyCode: Word;
     ShiftState: Byte;
     constructor Init;
     destructor Done; virtual;
     procedure Show; virtual;
     procedure Hide; virtual;
     procedure Run; virtual;
     procedure SetPos; virtual;
     procedure SetCursor(var ACursor); virtual;
     procedure Wait; virtual;
   end;

 VAR
   { ***************************************************************** }
   {  Die Maus fÅr die Zugriffe der Objekte (View und nachfahren).     }
   { ***************************************************************** }
   Mouse: HMouse;

   { ***************************************************************** }
   {  SetRect           öbertrÑgt die Werte in ein LRect-Object.       }
   {  Conatain          öberprÅft, ob der Punkt innerhalb des Recht-   }
   {                     eckes liegt.                                  }
   {  TestOption        öberprÅft, ob ein gewisses Bit eines Words ge- }
   {                     setzt ist.                                    }
   {  GetEvent          Liest Maus und Tastaturdaten in einen LEvent-  }
   {                     record ein.                                   }
   { ***************************************************************** }
   {  PushCanvas        öbertrÑgt die Bilddaten des Canvas in den      }
   {                     hohen Speicherbereich (XMS) und gibt den      }
   {                     "normalen" Speicher wieder frei               }
   {  PopCanvas         öbertrÑgt die Bilddaten im hohen Speicher      }
   {                     zurÅck in ein Canvas.                         }
   { ***************************************************************** }
   procedure SetRect(var ARect : LRect; x1,y1,x2,y2 : Integer);
   function Contain(ARect : LRect; x,y : Word) : Boolean;

   function TestOption(AOptions, AWert : Word) : Boolean;

   procedure GetEvent(var AEvent: LEvent);

   function PushCanvas(ACanvas: HCanvas) : Word;
   function PopCanvas(AHandle: Word; pX, pY : Word) : HCanvas;

{ ************************************************************************** }
IMPLEMENTATION
{ ************************************************************************** }
 USES XMS;

   { ***************************************************************** }
   {  Stellt die Grundlage fÅr alle auf dem Bildschirm sichtbaren      }
   { Objecte dar.                                                      }
   {  ˘Bounds           Die Koordinaten des Objects auf dem Bildschirm }
   {  ˘Options          Speichert Einstellungen fÅe das Object.        }
   {  ˘Colors           Die Farbpalette                                }
   {  ˘Canvas           Die "Zeichnungsunterlage"                      }
   {  ˘Parent           Das Åbergeordnete Fenster                      }
   {  ˘Next             Ein Zeiger auf das nÑchste Fenster in einer    }
   {                     Liste.                                        }
   {  ˘EventMask        Speichert, auf welche Ereignisse das Object    }
   {                     reagiert.                                     }
   {  ˘Delta            Bei untergeordneten Objecten, ist der eigene   }
   {                     Punkt (0|0) nicht an der Stelle (0|0) des     }
   {                     Canvas. Delta zeigt nun auf den eigenen Punkt }
   {                     (0|0). Bei "normalen" objecten ist Delta      }
   {                     immer Null. Aus kompatibilitÑtsgrÅnden sollte }
   {                     Delta jedoch immer (!) verwendet werden.      }
   {  Init              Initialisiert das Object und setzt gewisse     }
   {                    Standarteinstellungen.                         }
   {  Done              Gibt belegten Speicher wieder frei.            }
   {  Show              Legt eine  "Zeichnungsunterlage" im Speicher   }
   {                     an und sorgt dafÅr, dass das Bild zum ersten  }
   {                     Mal gezeichnet wird.                          }
   {  Hide              Gibt die "Zeichnungsunterlage" wieder frei und }
   {                     sperrt alle Darstellungsroutinen.             }
   {  Draw              Zu Åberschreiben ! Zeichnet das Bild in den    }
   {                     Speicher.                                     }
   {  ReDraw            Ruft Draw auf und ÅbertrÑgt danach das Bild    }
   {                     auf den Bildschirm.                           }
   {  InitColors        Kann Åberschrieben werden. Belegt Speicher fÅr }
   {                     die Farbpalette und setzt Anfangswerte.       }
   {  HandleError       Behandelt Fehler.                              }
   {  HandleEvent       Behandelt die Ereignisse                       }
   { ***************************************************************** }
 constructor LView.Init(AParent : HView; ABounds : LRect);
 begin
   Bounds := ABounds;                   { Koordinaten Åbertragen }
   if (Bounds.A.X = Bounds.B.X) or (Bounds.A.Y = Bounds.B.Y) then begin
     HandleError(er_SmRect or er_opt_Done);
     Exit;                              { öberprÅfen, ob Koordinaten genug gross }
   end;
   Options := opt_Init;                 { Object ist nun verfÅgbar. }
   Parent := AParent;                   { Parent Åbertragen }
   if AParent <> nil then Options := Options or opt_Child;
   Next := nil;                         { Kein nÑchstes vorhanden }
   InitColors;                          { Farben initialisieren }
   EventMask := ev_Command;             { Kommados werden bearbeitet }
   if AParent <> nil then begin         { Delta setzen. }
     Delta.X := ABounds.A.X; Delta.Y := ABounds.A.Y;
   end else begin
     Delta.X := 0; Delta.Y := 0;
   end;
   Client.X := Bounds.B.X - Bounds.A.X;
   Client.Y := Bounds.B.Y - Bounds.A.Y;
   Cursor := Addr(c1);                  { Standartcursor setzen }
   BmpName := nil;                      { Kein Bild geladen.    }
 end;

 destructor LView.Done;
 begin
   if TestOption(Options,opt_Visible)   { Wenn noch sichtbar, dann zuerst... }
    then Hide;                          { ...Hide aufrufen }
   if Colors <> nil then FreeMem(Colors,Colors^[0]); { Farbpalette freigeben }
   Options := $0000;                    { Object nicht mehr verfÅgbar. }
 end;

 procedure LView.Show;
 type
   ARect = Array[1..4] of Integer;
 var
   B : ARect absolute Bounds;   { Vereinfacht(?) und verkÅrzt den Quelltext }
 begin
   if TestOption(Options,opt_Visible) then Exit;  { Abbrechen, wenn bereits sichtbar }
   if (Options and opt_Child) = 0                 { PrÅfen, ob eigenes Canvas erstellen }
    then Canvas := New(HCanvas, Init(b[3]-b[1],b[4]-b[2],Colors^[2]))
    else Canvas := Parent^.Canvas;
   if Canvas = nil              { Wenn kein Canvas, dann Fehler }
    then HandleError(er_NoCanvas)
    else Options := Options or opt_Visible;     { ...Darstellungsroutinen freigeben }
   ReDraw;                      { Auf den Bildschirm ! }
 end;

 procedure LView.ShowBmp(AName: String);
 begin
   if TestOption(Options, opt_Visible) then Exit;       { Abbrechen, wenn bereits sichtbar }
   Show;
   BmpName := New(HString);
   BmpName^ := AName;
 end;

 procedure LView.Hide;
 begin
   if not TestOption(Options, opt_Visible) then Exit;    { Wenn nicht sichtbar, dann beenden }
   if (Options and opt_Child) = 0           { Nur eigenes Canvas entfernen }
    then Dispose(Canvas, Done);
   Options := Options and not opt_Visible;  { Darstellungsroutinen sperren }
 end;

 procedure LView.Draw;
 begin end;

 procedure LView.ReDraw;
 var
   can : HCanvas;
   c   : LRect;                         { Maus auch deaktivieren, ... }
 begin
   if not TestOption(Options,opt_Visible) then Exit; { Abbrechen, wenn nicht Visible }
   if Canvas = nil then begin
     HandleError(er_noCanvas);          { Wenn Canvas nicht vorhanden, dann }
     Exit;                              { Fehler und abbruch. }
   end;
   if not (BmpName = nil) then begin  { Ein BMP-Bild laden als Hintergrund laden. }
     can := LoadBmp(BmpName^);             { Bild laden }
     Canvas^.Insert(can,Delta.X,Delta.Y);  { Bild einfÅgen }
     Dispose(can, Done);                   { TemporÑrspeicher wieder freigeben. }
   end;
   if TestOption(Options, opt_Child) then begin
     Parent^.ReDraw;   Exit;            { öbergeordnetes Fenster Åbernimmt Aufgabe. }
   end;
   c := Bounds;                                 { ...wenn die Maus 16 Pixel vom Object... }
   c.A.X := c.A.X - 16; c.A.Y := c.A.Y - 16;    { ...entfernt ist. }
   c.B.X := c.B.X + 2; c.B.Y := c.B.Y + 2;
   if TestOption(Options, opt_3d) then Canvas^.Dim3(Colors^[3],Colors^[4]); { 3D-Rahmen }
   Draw;                                { Bild in Speicher zeichnen. }
   Mouse^.Run;
   if Contain(C,Mouse^.Where.X,Mouse^.Where.Y)  { Auf Object, dann Maus "verstecken" }
    then Mouse^.Hide;
   Canvas^.Show(Bounds.A.X,Bounds.A.Y); { Object auf den Bildschirm }
   if TestOption(EventMask, ev_MVisible){ Wenn nîtig, Maus wieder neu darstellen }
    then Mouse^.Show;
 end;

 procedure LView.InitColors;
 begin
   GetMem(Colors,5);            { Speicher belegen }
   if Colors = nil then begin   { Wenn kein Speicher vorhande, dann Fehler }
     HandleError(er_NoColors);  { und abbrechen }
     exit;
   end;
   Colors^[0] := 5;             { Die Grîsse setzten }
   Colors^[1] := $0F;           { Einige Farbwerte vorgeben. }
   Colors^[2] := $10;           { ( sollten von Nachkommen eigentlich... }
   Colors^[3] := $1D;           { ...Åberschrieben werden) }
   Colors^[4] := $12;
 end;

 procedure LView.HandleError(Nr : Integer);
 var
   i : Byte;                    { "Stack"-Ersatz }
 begin
   if (Nr and er_opt_Msg) > 0 then begin  { Mit roter Farbe das... }
     i := Screen.Colr;                    { ... Wort Fehler ausgeben. }
     Screen.Colr := cl_Red;
     Screen.OutPut(10,10,'Fehler !');
     Screen.Colr := i;                    { Farbe wiederherstellen }
   end;
   if (Nr and er_opt_Done) > 0 then Done;       { Object entfernen }
   if (Nr and er_opt_Halt) > 0 then Halt;       { Programm anhalten }
   if (Nr and er_opt_Run) > 0 then RunError(Nr and $0FFF); { Runtime-Error erzeugen. }
 end;

 procedure LView.HandleEvent(var AEvent);
 var
   Event : LEvent absolute AEvent;       { Parameter als Event interpretieren }
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
     if (Contain(Bounds,Event.Mouse.X,Event.Mouse.Y)) then begin
       if not TestOption(Options, opt_Mouse) then begin
         Options := Options or opt_Mouse;    { Option "Mouse" setzen }
         Mouse^.SetCursor(Cursor^);           { Den richtigen Mauscursor wÑhlen }
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
         Mouse^.SetCursor(Mouse^.StdCursor^);  { Cursor zurÅcksetzen. }
       end;
     end;
     { Maustaste auf Object gedrÅckt. }
     if (Event.MButton > 0) and (Contain(Bounds,Event.Mouse.X,Event.Mouse.Y))
      then begin if not TestOption(Options,opt_Select) then begin
        Options := Options or opt_Select;             { Wenn Maus auf Object und Taste gedrÅckt, }
        ReDraw;
      end; end else if TestOption(Options, opt_Select) then begin
        Options := Options and not opt_Select; { dann Option "Select" setzen. }
        ReDraw;
      end;
   end;
 end;
{ ************************************************************************** }

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Text des Buttons.                  }
   {  ˘MyCmd            Das Kommando, welches der Button auslîst.      }
   {  ˘MKeyPos          Der Index des Buchstabens, welcher mit der Alt }
   {                     Taste zusammen das Kommando des Buttons aus-  }
   {                     lîst.                                         }
   {  Init              => Siehe LView /// Um einen Buchstaben im      }
   {                     Namen unterstreichen zu lassen und als KÅrzel }
   {                     zu verwenden, stellen sie ihm ein "&" bevor.  }
   { ***************************************************************** }

 constructor LButton.Init(AParent: HView; ABounds: LRect; ACaption: String; ACmd: Word);
 begin
   Inherited Init(AParent, ABounds);
   Caption := ACaption;                 { Titel Åbernehmen }
   MyCmd   := ACmd;                     { Kommando Åbernehmen }
   MKeyPos := Pos('&',Caption);         { Position der HotKey-Taste ermitteln }
   if MKeyPos > 0 then Delete(Caption,MKeyPos,1);   { "&"-Zeichen lîschen. }
   EventMask := EventMask or ev_Mouse or ev_Key;    { Alle Befehlsoptionen zulassen. }
 end;

 procedure LButton.Draw;
 var
   a,b : Word;
   can : HCanvas;
 begin
   if not TestOption(Options, opt_Visible) then Exit;       { Nur zeichnen, wenn... }
   if Canvas = nil then begin                               { ...freigegeben und eine... }
     HandleError(er_NoCanvas);                              { ..."Zeichnungsunterlage" vorhanden. }
     Exit;
   end;
   if TestOption(Options, opt_Child) then begin
     can := Canvas;
     Canvas := New(HCanvas, Init(Bounds.B.X-Bounds.A.X,Bounds.B.Y-Bounds.A.Y,Colors^[2]));
     if Canvas = nil then begin
       HandleError(er_NoCanvas);  Exit;
     end;
   end;
   if TestOption(Options, opt_Disable) then begin         { Wenn nicht verfÅgbar: }
     Canvas^.Dim3(Colors^[3],Colors^[4]);
     DrawTextXY(Canvas,a,b,Colors^[6],0,Caption);
   end else begin
     if TestOption(Options, opt_Select)                   { Button selektiert. }
      then Canvas^.Dim3(Colors^[4],Colors^[3])
      else Canvas^.Dim3(Colors^[3],Colors^[4]);
     a := ((Bounds.B.X - Bounds.A.X) div 2) - (ord(Caption[0]) * 4);     { Text zentrieren. }
     b := ((Bounds.B.Y - Bounds.A.Y) div 2) - (Mem[$0000:$0485] div 2);
     if TestOption(Options, opt_Focus)           { Text schreiben. }
      then DrawTextXY(Canvas,a,b,Colors^[5],0,Caption)
      else DrawTextXY(Canvas,a,b,Colors^[1],0,Caption);
     if (MKeyPos > 0) then begin
       a := a + ((MKeyPos - 1) * 8);             { HotKey unterstreichen. }
       DrawTextXY(Canvas,a,b,Colors^[1],0,'_');
     end;
   end;
   if TestOption(Options, opt_Child) then begin
     Can^.Insert(Canvas,Delta.X,Delta.Y);
     Dispose(Canvas, Done);
     Canvas := can;
   end;
 end;

 procedure LButton.HandleEvent(var AEvent);
 var
   Event: LEvent absolute AEvent;
   MyKey: Char;
 begin
   if TestOption(Options, opt_Disable) then Exit;
   if not (Parent = nil) then                   { Wenn Åbergeordnetes fenster nicht Fokus hat, abbrechen. }
    if not TestOption(Parent^.Options, opt_Focus) then Exit;
   MyKey := UpCase(Caption[MKeyPos]);      { HotKeyTaste ermitteln. }
   if (Event.MButton = 0) and (TestOption(Options, opt_Select)) then begin
      Options := Options and not opt_Select;       { Wenn Button gedrÅckt wurde }
      ReDraw;                                      { neu zeichnen und Kommando }
      Event.Command := MyCmd;                      { weitergeben. }
   end;
   if Event.KeyCode = (ScanCodes[MyKey] * $100)    { Wenn HotKey + ALT gedrÅckt,  }
    then Event.Command := MyCmd;                   { ebenfalls Kommando auslîsen. }
   inherited HandleEvent(AEvent);
   if (EventMask and ev_KeyCode) > 0 then begin    { Button hat Fokus und "Enter" wird gedrÅckt: }
     if (Event.KeyCode = $1C0D) and (TestOption(Options, opt_Focus))
      then Event.Command := MyCmd;
   end;
 end;

 procedure LButton.InitColors;
 begin
   GetMem(Colors,7);
   if Colors = nil then begin
     HandleError(er_NoColors);
     exit;
   end;
   Colors^[0] := 7;
   Colors^[1] := $10;                   { Schwarze Schrift }
   Colors^[2] := $19;                   { Grauer Grund }
   Colors^[3] := $1D;                   { Rahmen hell }
   Colors^[4] := $12;                   { Rahmen dunkel }
   Colors^[5] := $68;                   { Selektierte Schrift: Dunkelblau }
   Colors^[6] := $15;                   { Nicht verfÅgbare Schrift. }
 end;
{ ************************************************************************** }

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Titel des Fensters.                }
   {  ˘First            Ein zeiger auf das erste untergeordnete Object }
   {  ˘CloseBut         Ob der Close-Button links-oben gerade gedrÅckt }
   {                     wird.                                         }
   {  ˘XMS_Handle       Der Hintergrund wird im hohen Speicherbereich  }
   {                     abgelegt. Dies ist das Zugriffshandle.        }
   {  ˘MouseDelta       Dient zur Verschiebung des Fensters.           }
   {  Init              Ein Fenster kann kein Åbergeordnetes Object    }
   {                     besitzen.                                     }
   {  Done              Alle untergeordneten Objecte werden ebenfalls  }
   {                     entfernt.                                     }
   {  Insert            FÅgt ein untergeordnetes Object ein.           }
   {  HandleMove        Wird zur Verschiebung des Fensters aufgerufen. }
   {  MoveMe            Verschiebt das Fenster um Dx bzw. DY Pixel.    }
   {  CanClose          PrÅft, ob das Fenster momentan geschlossen     }
   {                     werden darf. Kann Åberschrieben werden.       }
   { ***************************************************************** }
 constructor LWindow.Init(ABounds: LRect; ACaption: String);
 begin
   Inherited Init(nil, ABounds);           { LView.Init aufrufen }
   Caption := ACaption;                    { Fenstertitel Åbernehmen }
   First   := nil;                         { Noch keine untergeordneten Fenster }
   Options := Options or opt_3D;           { 3D-Aussehen. }
   CloseBut:= False;                       { Schliess-Button nicht gedrÅckt. }
   EventMask := $FF;                       { Alle Ereignisse }
   XMS_Handle := 0;                        { Hintergrund noch nicht gespeichert.   }
   MouseDelta.X := 0; MouseDelta.Y := 0;   { Fenster wird gerade nicht verschoben. }
   myKey := 27136;                         { Bei "ALT-F3" das Fenster schliessen.  }
   Options := Options or opt_Window;       { Fenster als solches in Options markieren. }
   Options := Options or opt_SaveBackG;    { Den Hintergrund zuerst abspeichern. }
 end;

 destructor LWindow.Done;
 var
   p,q : HView;
 begin
   if not (First = nil) then begin        { Alle untergeordneten Fenster }
     p := First;                          { ebenfalls schliessen. }
     q := First^.Next;
     while not (p = nil) do begin
       Dispose(p, Done);
       p := q;
       q := p^.Next;
     end;
   end;
   Inherited Done;
 end;

 procedure LWindow.Insert(AView: HView);
 var
   p : HView;
 begin
   p := First;                          { Bei "noch"-letztem untergeordnetem }
   if First = nil then begin            { Fenster den Next-Zeiger auf das neue }
     First := AView;                    { stellen. }
     First^.Options := First^.Options or opt_Focus;     { Erstes erhÑlt den Fokus }
   end else begin
     while not (p^.Next = nil) do
      p := p^.Next;
     p^.Next := AView;
   end;
   AView^.Next := nil;                            { Als letztes Fenster markieren }
   AView^.Delta.Y := AView^.Delta.Y + 20;         { Erster Punkt unterhalb der Titelleiste }
   AView^.Parent := @Self;                        { öbergeordnetes Fenster setzen. }
   AView^.Options := AView^.Options or opt_Child; { Als untergeordnet markieren. }
 end;

 procedure LWindow.Show;
 var
   Can : HCanvas;
   p   : HView;
 begin
   Mouse^.Hide;              { Mauszeiger deaktivieren }
   if TestOption(Options, opt_SaveBackG) then begin
     { Hintergrund im XMS abspeichern }
     Can := GetPicture(Bounds.A.X,Bounds.A.Y,Bounds.B.X+10,Bounds.B.Y+10);
     if Can <> nil
      then XMS_Handle := PushCanvas(Can);
   end else XMS_Handle := 0;
   Inherited Show;
   Options := Options or opt_Focus;
   { Alle untergeordneten Fenster ebenfalls auf Visible setzen. }
   if not (First = nil) then begin
     p := First;
     while not (p = nil) do begin
       p^.Show;
       p := p^.Next;
     end;
   end;
   { Mauszeiger gegebenenfalls wieder darstellen. }
   if (EventMask and ev_MVisible) > 0 then Mouse^.Show;
 end;

 procedure LWindow.Hide;
 var
   x,y : Word;
   p   : HView;
 begin
   if (Options and opt_Visible) = 0 then Exit;
   if not CanClose then Exit;                  { Nur, wenn Fenster geschlossen werden kann. }
   Mouse^.Hide;                                 { Mauszeiger verstecken. }
   if XMS_Handle = 0 then begin
     Canvas^.Clear(0);
     Canvas^.Show(Bounds.A.X,Bounds.A.Y);
   end;
   if not (First = nil) then begin         { Alle untergeordneten Objekte auf }
     p := First;                           { unsichtbar stellen }
     while not (p = nil) do begin
       if (p^.Options and opt_Visible) > 0 then p^.Hide;
       p := p^.Next;
     end;
   end;
   inherited Hide;
   if XMS_Handle > 0 then begin            { Hintergrund wiederherstellen. }
     x := Bounds.B.X - Bounds.A.X;
     y := Bounds.B.Y - Bounds.A.Y;
     Canvas := PopCanvas(XMS_Handle,x+10,y+10);
     if Canvas = nil then Exit;
     Canvas^.Show(Bounds.A.X,Bounds.A.Y);
     Dispose(Canvas, Done);
     XMS_Handle := 0;
   end;
   if (EventMask and ev_MVisible) > 0     { Maus wieder darstellen }
    then Mouse^.Show;
 end;

 procedure LWindow.Draw;
 var
   p : HView;
   c : HCanvas;
   i : Byte;
   x,y : Word;
 begin
   if not TestOption(Options, opt_Visible) then Exit;
   if Canvas = nil then begin
     HandleError(er_NoCanvas);
     Exit;
   end;
   p := First;                  { Alle untergeordneten Objekte sollen sich }
   while not (p = nil) do begin { zeichnen. }
     p^.Draw;
     p := p^.Next;
   end;
   { Titelleiste zeichnen: }
   if TestOption(Options, opt_Focus)
    then i := 6
    else i := 12;
   c := New(HCanvas, Init(Bounds.B.X-Bounds.A.X-28,20,Colors^[i]));
   if c = nil then begin
     HandleError(er_NoCanvas); Exit;
   end;
   c^.Dim3(Colors^[4],Colors^[3]);              { Titelleiste mit 3D-Aussehen }
   x := (Bounds.B.X - Bounds.A.X - 28) div 2;   { Titel in die Mitte }
   x := x - (ord(Caption[0]) * 4);
   y := 11 - (Mem[$0000:$0485] div 2);
   DrawTextXY(c,x,y,Colors^[i-1],0,Caption);      { Titel schreiben }
   Canvas^.Insert(c,24,3);                      { Titelleiste einfÅgen. }
   Dispose(c, Done);
   if CloseBut then x := 10 else x := 8;
   c := New(HCanvas, Init(20,20,Colors^[x]));   { Schliess-Button zeichnen: }
   if c = nil then begin
     HandleError(er_NoCanvas); Exit;
   end;
   c^.Dim3(Colors^[4],Colors^[3]);
   y := 10 - (Mem[$0000:$0485] div 2);
   DrawTextXY(c,6,y,Colors^[x-1],0,'-');
   Canvas^.Insert(c,3,3);
   Dispose(c, Done);
 end;

 procedure LWindow.HandleEvent(var AEvent);
 var
   R : LRect;
   Event : LEvent absolute AEvent;
   ChilEv: LEvent;
   p : HView;
 begin
   if TestOption(Options, opt_Disable) then Exit;
   inherited HandleEvent(AEvent);
   { *** Tastatur-Ereignisse: *** }
   if (EventMask and ev_KeyCode) > 0 then begin
     if Event.KeyCode = myKey then Event.Command := cm_Close;   { Fenster schliessen }
     if (Event.KeyCode mod $100) = 9 then begin                 { Tab: nÑchstes Objekt fokusieren. }
       Event.KeyCode := 0;
       p := First;
       while not (p = nil) do begin
         if (p^.Options and opt_Focus) > 0 then begin
           p^.Options := p^.Options and not opt_Focus;
           p := p^.Next;
           if p = nil then p := First;
           p^.Options := p^.Options or opt_Focus;
           ReDraw;
           Break;
         end;
         p := p^.Next;
       end;
     end;
   end;
   { *** Maus-Ereignisse: *** }
   if (EventMask and ev_Mouse) > 0 then begin
     { Fenster verschieben: }
     SetRect(R,Bounds.A.X+26,Bounds.A.Y+3,Bounds.B.X-3,Bounds.A.Y+23);
     if Contain(R,Event.Mouse.X,Event.Mouse.Y) then begin
       HandleMove(AEvent);
       Exit;
     end;
     if (MouseDelta.X > 0) and (Event.MButton = 1) then begin
       HandleMove(AEvent);
       Exit;
     end;
     { Fenster schliessen: }
     SetRect(R,Bounds.A.X+3,Bounds.A.Y+3,Bounds.A.X+23,Bounds.A.Y+23);
     if (Event.MButton > 0) then begin
       if Contain(R,Event.Mouse.X,Event.Mouse.Y) then begin
         if not CloseBut then begin
           CloseBut := True;  ReDraw;
         end;
       end else begin
         if CloseBut then begin
           CloseBut := False; ReDraw;
         end;
       end;
     end else begin
       if Contain(R,Event.Mouse.X,Event.Mouse.Y) then
        if CloseBut then begin
          CloseBut := False;  ReDraw;
          Event.Command := cm_Close;
        end;
     end;
   end;
   { Untergeordnete Fenster sollen nun Ereignisse behandleln. }
   if not (First = nil) then begin
     ChilEv := Event;
     ChilEv.Mouse.X := ChilEv.Mouse.X - Bounds.A.X;
     ChilEv.Mouse.Y := ChilEv.Mouse.Y - Bounds.A.Y - 20;
     p := First;
     while not (p = nil) do begin
       p^.HandleEvent(ChilEv);
       p := p^.Next;
     end;
     Event.Command := ChilEv.Command;
   end;
   { Fenster schliessen: }
   if (EventMask and ev_Command) > 0 then begin
     if Event.Command = cm_Close then Hide;
   end;
 end;

 procedure LWindow.InitColors;
 begin
   GetMem(Colors,13);           { Speicher belegen }
   if Colors = nil then begin   { Wenn kein Speicher vorhande, dann Fehler }
     HandleError(er_NoColors);  { und abbrechen }
     exit;
   end;
   Colors^[0] := 13;            { Die Grîsse setzten }
   Colors^[1] := $10;           { Schwarze Schrift }
   Colors^[2] := $19;           { Grauer Hintergrund }
   Colors^[3] := $1D;           { Grauer Rahmen }
   Colors^[4] := $12;
   Colors^[5] := $1F;           { Der Titel: Weisse Schrift }
   Colors^[6] := cl_Blue;       { auf Blauem Grund }
   Colors^[7] := $10;           { Der nichtselektierte Button: }
   Colors^[8] := $19;
   Colors^[9] := $1D;           { Der selektierte Button }
   Colors^[10] := $12;
   Colors^[11] := $10;          { Der Titel des nichtfokusierten Fensters }
   Colors^[12] := $35;
 end;

 procedure LWindow.HandleMove(var AEvent);
 var
   Event: LEvent absolute AEvent;
   a,b  : Integer;
 begin
   if (Event.MButton = 1) then begin        { Die linke Maustaste gedrÅckt. }
     if (MouseDelta.X = 0) then begin
       MouseDelta := Event.Mouse;
     end else begin
       a := Event.Mouse.X - MouseDelta.X;   { die Differenzen zwischen der Mausposition }
       b := Event.Mouse.Y - MouseDelta.Y;   { und der Fensterposition bestimmen. }
       MouseDelta := Event.Mouse;           { Fensterposition als aktuelle Mausposition }
       MoveMe(a,b);                         { Fenster verschieben. }
     end;
   end else
    if (MouseDelta.X > 0) then MouseDelta.X := 0;
 end;

 procedure LWindow.MoveMe(DX,DY: Integer);
 begin
   if ((Bounds.A.X + DX) < 0) or ((Bounds.A.Y + DY) < 0) then Exit;
   if ((Bounds.B.X + DX) > Screen.X) or ((Bounds.B.Y + DY) > Screen.Y) then Exit;
   if (Dx = 0) and (Dy = 0) then Exit;
   Hide;               { Fenster entfernen. }
   Bounds.A.X := Bounds.A.X + DX; Bounds.A.Y := Bounds.A.Y + DY;   { Die Koordinaten }
   Bounds.B.X := Bounds.B.X + DX; Bounds.B.Y := Bounds.B.Y + DY;   { verschieben.    }
   Show;               { Fenster wieder neu zeichnen. }
 end;

 function LWindow.CanClose: Boolean;
 begin
   CanClose := True;   { Fenster kann geschlossen werden. }
 end;

 procedure LWindow.SetFocus(AView: HView);
 var
   p: HView;
 begin
   { Wenn keine untergeordneten Objekte vorhanden oder AView kein Objekt }
   { enthÑlt, Prozedur abbrechen.                                        }
   if (First = nil) or (AView = nil) then Exit;
   p := First;                                  { Beim ersten beginnen. }
   while not (p = nil) do begin                 { FÅr alle wiederholen. }
     if (p = AView) then begin                  { Wenn gesuchtes Objekt: }
       p^.Options := p^.Options or opt_Focus;   { auf Focus stellen }
       p := p^.Next;                            { NÑchstes Objekt }
       Continue;                                { Focus nicht lîschen. }
     end;
     if (p^.Options and opt_Focus) > 0 then begin      { Wenn Focus gesetzt: }
       p^.Options := p^.Options and not opt_Focus;     { Diesen lîschen }
       p^.Options := p^.Options and not opt_Select;    { Ebenfalls die Selektierung }
     end;
     p := p^.Next;      { Das nÑchste Objekt. }
   end;
   ReDraw;              { Neu zeichnen }
 end;

{ ************************************************************************** }

   { ***************************************************************** }
   {  ˘Caption          EnthÑlt den Text des Labels.                   }
   {  ˘TextStyle        Die Schriftart, die benutzt wird.              }
   {  InitColors        Falls ein Åbergeordnetes Fenster vorhanden ist }
   {                     werden dessen ersten 2 Farben Åbernommen.     }
   { ***************************************************************** }
 constructor LLabel.Init(AParent: HView; ABounds: LRect; ACaption: String);
 begin
   Inherited Init(AParent, ABounds);
   Caption := ACaption;               { Titel Åbernehmen }
   TextStyle := 0;                    { "normale" Schriftart }
   EventMask := $FF;                  { Alle Kommandos bearbeiten. }
   FocusCtrl := nil;                  { Noch kein Objekt fÅr Focus-öbergabe. }
   MKeyPos := Pos('&', Caption);      { Zu unterstreichendes Zeichen. }
   if MKeyPos > 0 then Delete(Caption, MKeyPos, 1);
 end;

 procedure LLabel.Draw;
 var
   Canv: HCanvas;
   x,y : Word;
 begin
   if not TestOption(Options, opt_Visible) then Exit;
   if TestOption(Options, opt_Child) then begin
     x := Bounds.B.X - Bounds.A.X;                  { Ein temprorÑres }
     y := Bounds.B.Y - Bounds.A.Y;                  { Canvas erzeugen }
     Canv := Canvas;
     Canvas := New(HCanvas, Init(x,y,Colors^[2]));
   end;
   if Canvas = nil then begin                          { Fehler. }
     HandleError(er_NoCanvas); Exit;
   end;
   if TestOption(Options, opt_Disable) then begin
     DrawTextXY(Canvas,1,1,Colors^[5],TextStyle,Caption); { Text schreiben. }
   end else begin
     DrawTextXY(Canvas,1,1,Colors^[1],TextStyle,Caption); { Text schreiben. }
     if MKeyPos > 0 then
      DrawTextXY(Canvas, MKeyPos, 1, Colors^[1],TextStyle,'_');
   end;
   if TestOption(Options, opt_Child) then begin    { TemporÑres Canvas entfernen }
     Canv^.Insert(Canvas,Delta.X,Delta.Y);
     Dispose(Canvas, Done);
     Canvas := Canv;
   end;
 end;

 procedure LLabel.InitColors;
 begin
   GetMem(Colors,6);
   if Colors = nil then begin
     HandleError(er_NoColors);
     exit;
   end;
   Colors^[0] := 6;
   Colors^[3] := $1D;          { Rahmen hell }
   Colors^[4] := $12;          { Rahmen dunkel }
   Colors^[5] := $15;          { Nicht auswÑhlbare Schrift }
   if not (Parent = nil) then begin            { Farben von Åbergeordnetem }
     Colors^[1] := Parent^.Colors^[1];         { Fenster Åbernehmen.       }
     Colors^[2] := Parent^.Colors^[2];
   end else begin
     Colors^[1] := $10;         { Schwarze Schrift auf grauem Grund. }
     Colors^[2] := $19;
   end;
 end;

 procedure LLabel.HandleEvent(var AEvent);
 var
   Event: LEvent absolute AEvent;
 begin
   if TestOption(Options, opt_Disable) then Exit;
   Inherited HandleEvent(AEvent);
   if not (Parent = nil) then                   { Wenn Åbergeordnetes fenster nicht Fokus hat, abbrechen. }
    if not TestOption(Parent^.Options, opt_Focus) then Exit;
   if TestOption(EventMask, ev_KeyCode) and (MKeyPos > 0) then    { Wenn ALT + "unterstrichene Taste" gedrÅckt, }
    if Event.KeyCode = (ScanCodes[UpCase(Caption[MKeyPos])] * $100){ dann auf Focus setzen. }
     then Options := Options or opt_Focus;
   if (Options and opt_Focus) > 0 then begin                { Fokus gleich weiterleiten. }
     Options := Options and not opt_Focus;
     if not (FocusCtrl = nil) then begin
       if not (Parent = nil) then begin
         if (Parent^.Options and opt_Window) > 0
          then HWindow(Parent)^.SetFocus(FocusCtrl)
          else FocusCtrl^.Options := FocusCtrl^.Options or opt_Focus;
       end else FocusCtrl^.Options := FocusCtrl^.Options or opt_Focus;
     end else if not (Next = nil) then
      Next^.Options := Next^.Options or opt_Focus;
   end;
 end;

   { ***************************************************************** }
   {  ˘Where            EnthÑlt nach einem Aufruf von Run die Koordi-  }
   {                     naten der Maus.                               }
   {  ˘Button           EnthÑlt den gedrÅckten Mausbutton.             }
   {  ˘Visible          Ob die Maus sichtbar ist.                      }
   {  ˘StdCursor        Ein Zeiger auf den Standart-Mauscursor.        }
   {  ˘AktCursor        EnthÑlt den aktuellen Cursor.                  }
   {  Init              Initialisiert die Maus und setzt die Anfangs-  }
   {                     werte fÅr die Felder.                         }
   {  Done              Entfernt die Maus vom Bildschirm.              }
   {  Show              Stellt die Maus dar.                           }
   {  Hide              Entfernt die Muas vom Bildschirm.              }
   {  Run               Setzt die Felder mit dem Mausdaten.            }
   {  SetPos            Setzt die Maus auf die Koordinaten von Where.  }
   {  SetCursor         Setzt einen neuen Cursor.                      }
   {  Wait              Wartet, bis die Maustaste wieder losgelassen   }
   {                     wurde.                                        }
   { ***************************************************************** }
 constructor LMouse.Init;
 begin
   Where.X := 10; Where.Y := 10;    { Koordinaten auf Null setzen }
   Button  := 0;                    { Noch keine Maustaste        }
   Visible := False;                { Maus noch nicht sichtbar.   }
   StdCursor:= @c1;                 { StandartmÑssig: Pfeilcursor }
   AktCursor:= @c1;                 { Aktueller Cursor: Pfeilcursor }
   KeyCode  := 0;                   { Tastaturcode auf Null setzen. }
   ShiftState := 0;                 { ShiftStatus auf Null setzen.  }
   asm
       XOR     AX,AX                { Maus Åber interrupt initialisieren }
       INT     33h
   end;
 end;

 destructor LMouse.Done; assembler;
 asm
       PUSH     ES
       LES      DI,Self
       ADD      DI,07
       MOV      AL,ES:[DI]          { Visible gesetzt ? }
       OR       AL,AL               { Wenn False, ... }
       JZ       @@1                 { ...dann beenden }
       MOV      AL,False
       MOV      ES:[DI],AL          { ...sonst Visible auf False }
       LES      DI,Self
       PUSH     ES                  { ...und Maus unsichtbar machen }
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR [DI+16]   { Hide aufrufen }
 @@1:  POP      ES
 end;

 procedure LMouse.Show; assembler;
 asm
       PUSH     ES
       LES      DI,Self
       ADD      DI,07
       MOV      AL,TRUE             { Visible auf True setzen }
       MOV      ES:[DI],AL
       MOV      AX,01h              { Interrupt aufrufen, um die Maus }
       INT      33h                 { sichtbar zu machen. }
       POP      ES
 end;

 procedure LMouse.Hide; assembler;
 asm
       PUSH     ES
       LES      DI,Self
       ADD      DI,07
       MOV      AL,FALSE            { Visible auf False setzen }
       MOV      ES:[DI],AL
       MOV      AX,02h              { Interrupt aufrufen, um die Maus }
       INT      33h                 { unsichtbar zu machen. }
       POP      ES
 end;

 procedure LMouse.Run; assembler;
 asm
       PUSH     ES
       MOV      AX,03h              { öber Interrupt die Mausdaten laden }
       INT      33h
       LES      DI,Self
       ADD      DI,02               { Daten in eigene Felder Åbertragen. }
       MOV      ES:[DI],CX
       MOV      ES:[DI+02],DX
       MOV      ES:[DI+04],BL
       POP      ES
 end;

 procedure LMouse.SetPos; assembler;
 asm
       PUSH     ES
       LES      DI,Self
       MOV      AL,ES:[DI+07]       { AL := Visible }
       PUSH     AX                  { AL sichern }
       OR       AL,AL
       JZ       @@1                 { Wenn Visible=False, dann }
       PUSH     DI                  { Hide nicht aufrufen }
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR [DI+16]   { Hide aufrufen }
       POP      DI
 @@1:  ADD      DI,02               { X,Y-Position aus den Feldern laden }
       MOV      CX,ES:[DI]          { ...und in die Register Åbertragen }
       MOV      DX,ES:[DI+02]
       MOV      AX,04h              { Interrupt soll Maus neu setzen. }
       INT      33h
       POP      AX                  { AL=Visible }
       OR       AL,AL
       JZ       @@2                 { Show nicht aufrufen, wenn Visible=False }
       LES      DI,Self
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR [DI+12]   { Show aufrufen }
 @@2:  POP      ES
 end;

 procedure LMouse.SetCursor(var ACursor); assembler;
 var
       Buf: Byte;
 asm
       PUSH     ES
       PUSH     DS
       LES      DI,Self
       MOV      AL,ES:[DI+07]     { AL=Visible }
       MOV      Buf,AL
       OR       AL,AL
       JZ       @@1
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR [DI+16] { Hide aufrufen }
 @@1:  LDS      SI,Self
       ADD      SI,12             { DS:SI => Aktueller Cursor }
       LES      DI,ACursor        { Adresse des Cursors laden }
       MOV      AX,ES
       MOV      DS:[SI+02],AX     { Aktuellen Cursor setzen. }
       MOV      DS:[SI],DI
       MOV      BX,ES:[DI]        { Den Referenzpunkt des Mauszeigers  }
       MOV      CX,ES:[DI+02]     { setzen und ES:DX auf Cursormasken- }
       MOV      DX,DI             { Daten setzen.                      }
       ADD      DX,04
       MOV      AX,09h            { Interruptfunktion 9 }
       INT      33h               { Interrupt aufrufen }
       MOV      AL,Buf            { AL=Visible von vorhin }
       OR       AL,AL
       JZ       @@2               { Show nicht aufrufen, wenn nicht dargestellt }
       LES      DI,Self
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR [DI+12] { Show aufrufen }
 @@2:  POP      DS
       POP      ES
 end;

 procedure LMouse.Wait; assembler;
 asm
       PUSH     ES
 @@1:  MOV      AX,03h              { Interrupt fÅr Daten aufrufen. }
       INT      33h
       OR       BL,BL               { Wenn Taste > 0, dann zurÅck }
       JNZ      @@1
       LES      DI,Self             { Die Koordinaten in eigene }
       MOV      ES:[DI+02],CX       { Felder Åbertragen und     }
       MOV      ES:[DI+04],DX       { Taste auf Null setzen.    }
       MOV      ES:[DI+06],BL
       POP      ES
 end;

{ ************************************************************************** }

   { ***************************************************************** }
   {  SetRect           öbertrÑgt die Werte in ein LRect-Object.       }
   {  Conatain          öberprÅft, ob der Punkt innerhalb des Recht-   }
   {                     eckes liegt.                                  }
   {  TestOption        öberprÅft, ob ein gewisses Bit eines Words ge- }
   {                     setzt ist.                                    }
   {  GetEvent          Liest Maus und Tastaturdaten in einen LEvent-  }
   {                     record ein.                                   }
   { ***************************************************************** }
 procedure SetRect(var ARect : LRect; x1,y1,x2,y2 : Integer);
 var
   i : Integer;
 begin
   ARect.A.X := x1; ARect.A.Y := y1;      { Daten Åbertragen }
   ARect.B.X := x2; ARect.B.Y := y2;
   if (ARect.A.X > ARect.B.X) then begin  { Bei vertauschten Koordinaten nochmals vertauschen }
     i := ARect.A.X;  ARect.A.X := ARect.B.X;  ARect.B.X := i;
   end;
   if (ARect.A.Y > ARect.B.Y) then begin
     i := ARect.A.Y;  ARect.A.Y := ARect.B.Y;  ARect.B.Y := i;
   end;
 end;

 function Contain(ARect : LRect; x,y : Word) : Boolean;
 begin
   if (x > ARect.A.X) and (x < ARect.B.X)
    and (y > ARect.A.Y) and (y < ARect.B.Y)
     then Contain := True
     else Contain := False;
 end;

 function TestOption(AOptions, AWert : Word) : Boolean; assembler;
 asm
    MOV    AX,AOptions
    MOV    CX,AWert
    TEST   AX,CX
    JE     @@1
    MOV    AX,TRUE
    JMP    @@2
 @@1:
    MOV    AX,FALSE
 @@2:
 end;

 procedure GetEvent(var AEvent: LEvent);
 var
   a,b,c : Word;
   d     : Byte;
 begin
   c := 0;
   asm
      MOV     AH,01h
      INT     16h               { Tastaturinterrupt }
      JZ      @@1
      XOR     AX,AX
      INT     16h
      MOV     c,AX              { Tastencode }
   @@1:
   end;
   Mouse^.KeyCode := c;         { mîgliche Tastatursteuerung unterstÅtzen. }
   Mouse^.ShiftState := Mem[$0000:$0417];
   Mouse^.Run;                  { Mausdaten neu lesen. }
   AEvent.Command := 0;
   AEvent.MButton := Mouse^.Button;     { Werte Åbertragen }
   AEvent.Mouse.X := Mouse^.Where.X;
   AEvent.Mouse.Y := Mouse^.Where.Y;
   AEvent.KeyCode := c;
   AEvent.KeyState:= Mem[$0000:$0417];  { Tastenstatus }
 end;
{ ************************************************************************** }

 function PushCanvas(ACanvas: HCanvas) : Word;
 var
   s1 : LongInt;
   s2, Handle : Word;
 begin
   s1 := (ACanvas^.XSize * ACanvas^.YSize);             { Die benîtigte Grîsse }
   s1 := (s1 div $400) + 1;                             { ...in Kilobytes }
   Handle := get_emb(s1);                               { Speicher reservieren }
   if (xmm_Error <> 0) or (Handle = 0) then begin       { Nicht genÅgend Speicher vorhanden. }
     PushCanvas := 0; Exit;
   end;
   s1 := (ACanvas^.XSize * ACanvas^.YSize) + 16;        { Grîsse neu berechnen }
   PushMem(Handle,Ptr(ACanvas^.MemSeg, 0)^,s1);         { Daten verschieben }
   Dispose(ACanvas, Done);                              { Canvas im normalen Speicher entfernen }
   PushCanvas := Handle;                                { Handle als RÅckgabewert. }
 end;

 function PopCanvas(AHandle: Word; pX, pY : Word) : HCanvas;
 var
   Canv: HCanvas;
   s1  : LongInt;
 begin
   Canv := nil;
   if AHandle = 0 then begin
     PopCanvas := nil; Exit;
   end;
   Canv := New(HCanvas, Init(pX, pY, 0));       { Canvas im normalen Speicher erzeugen }
   if Canv = nil then begin                     { Nicht genÅgend Speicher }
     PopCanvas := nil; Exit;
   end;
   s1 := (Canv^.XSize * Canv^.YSize);           { Grîsse berechnen }
   PopMem(AHandle,Ptr(Canv^.MemSeg, 0)^, s1);   { Daten verschieben }
   Free_emb(AHandle);                           { Speicher im XMS freigeben }
   PopCanvas := Canv;                           { Zeiger auf Canvas als RÅckgabewert }
 end;
{ ************************************************************************** }

{ ************************************************************************** }
BEGIN
  Mouse := New(HMouse, Init);           { Maus initialisieren }
  if (Mouse = nil) then begin
    WriteLn('Fehler: Zu Wenig Heap-Speicher fÅr die Maus !');
    Halt;
  end;
  Mouse^.StdCursor := @c1;              { Standart-Cursor: Pfeil }
END.