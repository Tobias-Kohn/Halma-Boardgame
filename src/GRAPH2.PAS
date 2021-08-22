{ ******************************************************************* }
{  Diese Unit enthÑlt Grundobjekte und Prozeduren zur Programmierung  }
{ des VGA-Modus mit 256 Farben                                        }
{  Um sie auf anderen Bildschirm-Betriebsarten laufen zu lassen, sind }
{ gewisse énderungen unumgÑnglich. Dies beinhaltet in erster Linie    }
{ das umschreiben des LScreen-Objektes. FÅr 16 Farben sind zusÑtzlich }
{ noch die anderen Objekte anzupassen im Bezug auf die Berechnung des }
{ Speicherplatzes. Ausser dem LScreen-Objekt benutzt jedoch kein      }
{ anderes direkt die Bildschirmkarte.                                 }
{  Falls sie diese Unit mit Erfolg laufen lassen wollen, ist es leider}
{ unumgÑnglich, den Standart-Heap des Turbo Pascal auf ein Minimum zu }
{ redzieren, da LCanvas noch freien Speicher im MS-DOS benîtigt, um   }
{ die Bilder abzulegen. Den Heapspeicher kînnen sie mittels des       }
{ Compiler-Befehls "$M" oder Åber das MenÅ "Option|Speicherauslegung" }
{ kÅrzen. Schlagen sie in ihrem Handbuch nach.                        }
{  FÅr die Prozeduren PushCanvasHandle und PopCanvasHandle wird der   }
{ obere Speicherbereich (XMS) benîtigt. Die Unit wird im implementa-  }
{ tions-Teil aufgerufen (XMS.TPU). Falls die gefprderte Unit nicht    }
{ vorhanden ist, mÅssen neben ihr auch die beiden genannten Proze-    }
{ uren ganz am Ende des Quelltextes entfernt werden, sowie ihre       }
{ Deklarationen im Interface-Teil. Andere Prozeduren greiffen nicht   }
{ auf den oberen Speicherbereich zu.                                  }
{  Der Nachfolgende Compilerbefehl ($G+) schaltet die 286-Codes ein.  }
{ Der 286 stellt einige ZusÑtzliche Assembler-Befehle zur verfÅgung,  }
{ die in den Prozeduren und Funktionen zum Teil verwendet werden.     }
{ Wenn kein 286 verfÅgbar ist, mÅssen diese Befehle ersetzt werden.   }
{ PUSHA sichert alle Register. POPA holt alle Register wieder zurÅck. }
{ (Segment-Register werden nicht berÅcksichtigt.) PUSH "Zahl" muss    }
{ ersetzt werden durch: MOV AX,"Zahl"  /  PUSH AX. Es kann gegebenen- }
{ falls anstatt AX auch ein anderes Register verwendet werden.        }
{ ******************************************************************* }
{$G+}
UNIT Graph2;
{ *************************************** }
{                                         }
{       (c) Okt 1998 by Tobias Kohn       }
{                                         }
{            VERSION 1.3                  }
{                                         }
{  UrsprÅmgliche Version: (c) Aug 1998.   }
{                                         }
{ *************************************** }

{****************************************************************************}
INTERFACE
{****************************************************************************}

CONST
 { ****** Vesa-Modi fÅr den Bildschirm: ****** }
 { vm_XXX gibt den Vesamodus an, y_XXX die maximale y-Koordinate. }
  vm_320  = $0013; y_320  = 320;      {  320x200 - 256 }
  vm_640  = $0101; y_640  = 480;      {  640x480 - 256 }
  vm_800  = $0103; y_800  = 600;      {  800x600 - 256 }
  vm_1024 = $0105; y_1024 = 768;      { 1024x768 - 256 }

 { ****** Farb-Konstanten bei 256 Farben ******* }
   cl_White  = $1F;   cl_Blue   = $20;   cl_Red     = $28;
   cl_Brown  = $72;   cl_Black  = $10;   cl_LiGreen = $30;
   cl_Green  = $77;   cl_Yellow = $2C;   cl_Orange  = $2A;
   cl_LiBlue = $36;   cl_Cyan   = $7C;   cl_Violet  = $23;

 { ***** Text-Attribut-Konstanten: ***** }
   ts_Standart   = $00;    ts_Mirror_H   = $04;
   ts_Vertical   = $01;    ts_Mirror_V   = $05;
   ts_Vertical_B = $02;    ts_UnderLine  = $06;
   ts_Top        = $03;    ts_Big        = $07;


TYPE
 { ********************************************************** }
 {  Init         Initialisiert das Objekt mit virtuellen      }
 {                Methoden                                    }
 {  Done         Deaktiviert das Objekt                       }
 {  Free         Deaktiviert das Objekt und gibt den Speicher }
 {                wieder frei (nur bei Zeiger-Objekten)       }
 { ********************************************************** }

  HObject = ^LObject;
  LObject = Object
    constructor Init;
    destructor Done; virtual;
    procedure Free;
  end;

 { ********************************************************** }
 {  In diesem Record kînnen alle Daten eines Canvas-Objektes  }
 { zwischengespeichert werden. Dadurch kînnen z.B. mit Hilfe  }
 { nur eines Canvas-Objektes im Heap mehrere Bilder verwaltet }
 { werden. Solche "eigenstÑndigen Bilder" ohne Objekt gestat- }
 { ten auch einen leichten Transport in den oberen Speicher-  }
 { bereich (XMS).                                             }
 {  ˘XMSMem      Nimmt das Handle fÅr den XMS auf. (Wird von  }
 {                LCanvas nicht verwendet)                    }
 {  ˘DosMem      Hier legt LCanvas die Speicheradresse des    }
 {                Bildes ab.                                  }
 {  ˘XSize       Die X-Ausdehnung des Bildes.                 }
 {  ˘YSize       Die Y-Ausdehnung des Bildes.                 }
 { ********************************************************** }

  HCanvasHandle = ^LCanvasHandle;
  LCanvasHandle = Record
    XMSMem : Word;
    DosMem : Word;
    XSize  : Word;
    YSize  : Word;
  end;

 { ********************************************************** }
 {  ˘MemSeg      Die Segmentadresse der ZeichenoberflÑche.    }
 {  ˘XSize       Die Maximale X - Ausdehnung.                 }
 {  ˘YSize       Die Maximale Y - Ausdehnung.                 }
 {  Init         Initialisierung mit den geg. Grîssen und     }
 {                reservierung des Speichers.                 }
 {                ˘gColor gibt die Grundfarbe ab, mit der der }
 {                Speicher am Anfang gefÅllt wird.            }
 {  LoadInit     Initialisierung des Objektes. Im Unterschied }
 {                zu Init wird hier aber nicht neuer Speicher }
 {                Platz belegt, sondern die Daten aus dem     }
 {                Åbergebenen Record eingelesen. (Diese Init- }
 {                Prozedur macht nichts anderes, als Load     }
 {                auszurufen)                                 }
 {  Done         Freigabe des Speichers                       }
 {  MemError     Behandlung des Fehlers, dass der Speicher-   }
 {                nicht ausreicht. Ist zum Åberschreiben.     }
 {  SetPixel     Einen Punkt zeichnen.                        }
 {  GetPixel     Einen Punkt lesen.                           }
 {  GetLine      Eine horizontale Linie lesen. (Wird von Show }
 {                zur Darstellung benîtigt)                   }
 {  Show         Zeichnet den Inhalt von Canvas auf den Bild- }
 {                schirm.                                     }
 {  Dim3         Legt einen Ramen um die Zeichnung, um ihr    }
 {                ein 3D-Aussehen zu verleihen.               }
 {               => pC1 sollte heller sein als der Untergrund,}
 {                pC2 dagegen dunkler.                        }
 {  HLine        Zeichnet eine horizontale Linie.             }
 {  VLine        Zeichnet eine vertikale Linie.               }
 {  Clear        Lîscht das Bild.                             }
 {  Insert       FÅgt den Inhalt eines anderen Canvas-Objekts }
 {                an der Stelle (ax|ay) ein.                  }
 {  Store        öbertrÑgt die Daten an einen Handle-Record   }
 {                und lîscht die Daten bei sich selber.       }
 {  Load         Liest die Daten aus einem Handle-Record und  }
 {                speichert sie bei sich ab, wodurch das Bild }
 {                mit diesem Canvas bearbeitet werden kann.   }
 {  SetInsLine   Wird von Insert zum EinfÅgen einer Zeil ver- }
 {                wendet.                                     }
 { ********************************************************** }

  HCanvas = ^LCanvas;
  LCanvas = Object(LObject)
    MemSeg : Word;
    XSize  : Word;
    YSize  : Word;
    constructor Init(pX,pY : Word; gColor : Byte);
    constructor LoadInit(var AHandle: LCanvasHandle);
    destructor Done; virtual;
    procedure MemError; virtual;
    procedure SetPixel(pX, pY: Word; pColor: Byte); virtual;
    function GetPixel(pX, pY: Word) : Byte; virtual;
    procedure GetLine(pY : Word; var pBuffer);
    procedure SetLine(pY : Word; var pBuffer);
    procedure Show(pX,pY : Word); virtual;
    procedure Dim3(pC1,pC2 : Byte);
    procedure HLine(pY : Word; pColor : Byte);
    procedure VLine(pX : Word; pColor : Byte);
    procedure Clear(pColor : Byte);
    procedure Insert(ACanvas: HCanvas; ax, ay: Word);
    function Copy(x1,y1,x2,y2: Word): HCanvas;
    procedure Store(var AHandle: LCanvasHandle);
    procedure Load(var AHandle: LCanvasHandle);
  private
    procedure SetInsLine(pX, pY, pL : Word; var pBuffer);
  end;

 { ********************************************************** }
 {  Folgende Prozeuren wurden aus dem Objekt hinausgenommen,  }
 { um dieses nicht zu gross werden zu lassen. Sie benîtigen   }
 { jedoch daher als ersten Parameter immer einen Zeiger auf   }
 { ein Canvas-Object (HCanvas).                               }
 { ********************************************************** }
 {  DrawLine     Zeichnet eine Linie.                         }
 {  DrawRect     Zeichnet ein Rechteck.                       }
 {  DrawEllipse  Zeichnet eine Ellipse in das angegebene      }
 {                Rechteck.                                   }
 {  DrawCircle   Zeichnet einen Kreis. (Relativ langsam !)    }
 {  DrawBox      Zeichnet ein ausgefÅlltes Rechteck.          }
 {  DrawTextXY   Schreibt einen Text. Dazu wird die Schrift   }
 {                des BIOS verwendet. Der Hintergund zwischen }
 {                den Buchstaben wird nicht Åberschrieben.    }
 {  ShowTextXY   Wie DrawTextXY. öberschreibt jedoch den      }
 {                Hintergrund zwischen den Buchstaben.        }
 {  ReplaceLine  Ersetzt auf der angegebenen Linie alle Punkte}
 {                der Farbe pC1 mit der Farbe pC2. Andersfar- }
 {                bige Pixel werden nicht geÑndert.           }
 {  ReplaceCanvas Ersezt im gesamten Canvas alle Pixel der    }
 {                Farbe pC1 durch Pixel mit der Farbe pC2.    }
 {                                                            }
 {  LoadBMP      LÑdt ein Windows-PaintBrush-Bild in ein      }
 {                Canvas-objekt und liefert einen Zeiger auf  }
 {                das Objekt zurÅck.                          }
 {  GetPicture   öbertrÑgt den Bereich des Bildschirmes in    }
 {                Canvas-Objekt und gibt einen Zeiger darauf  }
 {                zurÅck.                                     }
 { ********************************************************** }
 procedure DrawLine(ACanvas : HCanvas; x1,y1,x2,y2 : Integer; pColor : Byte);
 procedure DrawCircle(ACanvas : HCanvas; pX,pY,pR : Word; pColor : Byte);
 procedure DrawEllipse(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);
 procedure DrawRect(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);
 procedure DrawBox(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);

 procedure DrawTextXY(ACanvas : HCanvas; pX,pY : Word; pColor, pOpt : Byte ; pText : String);
 procedure ShowTextXY(ACanvas : HCanvas; pX,pY : Word; pC1, pC2 : Byte ; pText : String);

 procedure ReplaceLine(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pC1, pC2 : Byte);
 procedure ReplaceCanvas(ACanvas: HCanvas; pC1, pC2 : Byte);

 function LoadBMP(pFileName : String) : HCanvas;

 function GetPicture(x1,y1,x2,y2 : Word) : HCanvas;

TYPE
 { ********************************************************** }
 {  ˘Flag        Die zur Zeit aktivierte Speicherbank.        }
 {  ˘X,Y         X bzw. Y - Ausdehnung des Bildschirmes.      }
 {  ˘OldM        Der "alte" Bildschirmmodus.                  }
 {  ˘Colr        Die Schreibfarbe fÅr OutPut und Input.       }
 {  Init         Setzt den Vesamodus "pVesaMode" und pX bzw.  }
 {                pY als maximale X bzw. Y - Ausdehnung.      }
 {  Done         Setzt wieder den alten Modus.                }
 {  InitStd      Ruft die Prozedur Init mit den Parametern    }
 {                fÅr einen 640x480 Bildschirm mit 256 Farben }
 {                auf.                                        }
 {  PutPixel     Zeichnet einen Punkt auf den Bildschirm.     }
 {  PutLine      Zeichnet eine ganze Linie auf den Bildschirm }
 {                ( Verwendet von LCanvas zum Darstellen der  }
 {                Bilder, da diese Prozedur schneller ist als }
 {                das Punktweise zeichnen.                    }
 {  GetPixel     Ermittelt die Farbe eines Pixels (langsam).  }
 {  OutPut       Gibt einen Text auf dem Bildschirm aus.      }
 {  Input        Erwartet die Eingabe eines Textes.           }
 {  FillScreen   FÅllt den gesamten Bildschirm mit der ange-  }
 {                gebenen Farbe aus.                          }
 {  SetBank      Setzt die neue Bank.                         }
 { ********************************************************** }

  HScreen = ^LScreen;
  LScreen = object
    Flag : Word;
    X,Y  : Word;
    OldM : Byte;
    Colr : Byte;
    Shift: Word;
    ChangeBank : procedure;
    procedure Init(pVesaMode, pX ,pY : Word);
    procedure Done;
    procedure InitStd;
    procedure PutPixel(pX,pY : Word; pColor : Byte);
    procedure PutLine(pX,pY,pL : Word; var Buffer);
    procedure GetLine(pX,pY,pL : Word; var Buffer);
    function GetPixel(pX,pY : Word) : Byte;
    procedure OutPut(pX,pY : Word; str : String);
    procedure InPut(pX,pY : Word; var str : String);
    procedure FillScreen(pColor : Byte);
  end;

 { ********************************************************** }
 var
   Screen : LScreen;

 { ********************************************************** }
 {  GetMaxMem    Gibt die Maximale Paragraphenzahl zurÅck     }
 {  GetMemSeg    Reserviert den angeforderten Speicherbereich }
 {  FreeMemSeg   Gibt den SPeicherbereich wieder frei         }
 {                                                            }
 { -Die Speichergrîssen werden hier in Paragraphen angegeben. }
 { -Ein Paragraph enthÑlt 16 Bytes.                           }
 { ********************************************************** }

 function GetMaxMem : Word;
 function GetMemSeg(pSize : Word) : Word;
 procedure FreeMemSeg(pSeg : Word);

 { ********************************************************** }
 {  PushCanvasHandle     Reseriert Speicherplatz im XMS und   }
 {                        ÅbertrÑgt das durch AHandle ange-   }
 {                        gebene Bild in den oberen Speicher. }
 {                        Der Speicher im DOS wird dabei frei-}
 {                        gegeben.                            }
 {  PopCanvasHandle      Reserviert Speicherplatz im DOS und  }
 {                        ÅbertrÑgt das Bild wieder zurÅck.   }
 {                        Der Speicher im XMS wird wieder     }
 {                        freigegeben.                        }
 { ********************************************************** }

 procedure PushCanvasHandle(var AHandle: LCanvasHandle);
 procedure PopCanvasHandle(var AHandle: LCanvasHandle);

{****************************************************************************}
IMPLEMENTATION
{****************************************************************************}
 USES XMS;                         { Zugriff auf den oberen Speicherbereich. }

 { ******************* Die Speicherroutinen: **************** }
  function GetMaxMem : Word; assembler;
  asm
       MOV      AH,48h
       MOV      BX,0FFFFh
       INT      21h
       MOV      AX,BX
  end;

  function GetMemSeg(pSize : Word) : Word; assembler;
  asm
       MOV      AH,48h
       MOV      BX,pSize
       INT      21h
  end;

  procedure FreeMemSeg(pSeg : Word); assembler;
  asm
       PUSH     ES
       MOV      AH,49h
       MOV      DX,pSeg
       MOV      ES,DX
       INT      21h
       POP      ES
  end;

 { ************************ LObject: ************************ }
 { ********************************************************** }
  constructor LObject.Init; assembler;
  asm end;

  destructor LObject.Done; assembler;
  asm end;

  procedure LObject.Free;
  begin
    Dispose(HObject(@Self),Done);
  end;

 { ************************ LCanvas: ************************ }
 { ********************************************************** }
  constructor LCanvas.Init(pX,pY : Word; gColor : Byte); assembler;
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,04
       MOV      AX,pX
       MOV      ES:[DI],AX          { XSize speichern }
       MOV      AX,pY
       MOV      ES:[DI+02],AX       { YSize speichern }
       MOV      CX,pX               { Grîsse berechnen }
       MUL      CX
       MOV      CX,10h              { In Paragraphen }
       DIV      CX
       INC      AX
       PUSH     AX                  { Grîsse sichern }
       CLC
       CALL     GetMaxMem           { Gib maximal-verfÅgbaren Speicherplatz }
       POP      DX
       CMP      AX,DX
       JB       @@1                 { Genug Speicherplatz vorhanden ? }
       PUSH     DX                  { Grîsse wieder sichern. }
       PUSH     DX
       CALL     GetMemSeg           { Speicher reservieren }
       JC       @@1                 { Fehler ? }
       POP      DX                  { Grîsse zurÅck nach DX }
       LES      DI,Self
       ADD      DI,02
       MOV      ES:[DI],AX          { Segment speichern und nach ES }
       MOV      ES,AX               { Speicherbereich lîschen: }
       CLD
       MOV      AX,DX               { Grîsse nach AX }
       MOV      CX,10h              { Grîsse wieder in Bytes }
       MUL      CX
       MOV      CX,DX               { Segmente in CX }
       MOV      BX,AX               { Restlicher Offset in BX }
       JCXZ     @@B                 { Wenn keine Segmente, gehe zu @@B }
       PUSH     BX                  { Offset speichern }
       MOV      BX,0FFFFh           { Ganzes Segment lîschen. }
  @@A: PUSH     CX                  { ZÑhler sichern }
       XOR      DI,DI               { Offset auf Null }
       CALL     @@2                 { Lîschen... }
       MOV      DX,ES               { Adresse um ein Segment erhîhen. }
       ADD      DX,1000h
       MOV      ES,DX
       POP      CX                  { ZÑhler zurÅck }
       LOOP     @@A                 { Wiederhole }
       POP      BX                  { Restlicher Offset wieder zurÅck. }
  @@B: XOR      DI,DI               { Offset wieder auf Null setzten }
       DEC      BX
       CALL     @@2                 { Lîschen }
       JMP      @@3                 { Ende }
  @@1: XOR      AX,AX               { Fehler: Zu wenig Speicher. }
       LES      DI,Self
       MOV      ES:[DI+02],AX       { Segmentadresse des Bildes auf Null setzten. }
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]          { MemError aufrufen. }
       CALL     DWORD PTR ES:[DI+0Ch]
       JMP      @@3                 { Ende... }
  @@2: MOV      CX,BX               { Erwartet in BX die Anzahl zu lîschende Bytes }
       MOV      AL,gColor           { Grundfarbe nach AL }
       REP      STOSB               { Lîschen }
       STOSB                        { Letztes Byte auch noch lîschen. }
       RETN                         { ZurÅck... }
  @@3: POP      DS
  end;

  constructor LCanvas.LoadInit(var AHandle: LCanvasHandle);
  begin
    Load(AHandle);
  end;

  destructor LCanvas.Done; assembler;
  asm
       PUSH     DS
       LES      DI,Self
       MOV      CX,ES:[DI+02]            { Bildsegmentadresse nach CX }
       JCXZ     @@2                      { Wenn Null, prozedur beenden. }
       PUSH     CX
       CALL     FreeMemSeg               { Speicher freigeben }
       JNC      @@2                      { Fehler ? }
       LES      DI,Self
       PUSH     ES
       PUSH     DI
       MOV      DI,ES:[DI]
       CALL     DWORD PTR ES:[DI+0Ch]    { MemError aufrufen. }
  @@2: POP      DS
  end;

  procedure LCanvas.MemError;
  begin
    halt;                               { Programm abbrechen. }
  end;

  procedure LCanvas.SetPixel(pX,pY : Word; pColor : Byte); assembler;
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,02
       MOV      CX,ES:[DI]          { Bildsegmentadresse nach CX }
       JCXZ     @@2                 { Wenn Speicher nicht initialisiert, dann Ende. }
       MOV      AX,ES:[DI+02]
       MOV      CX,ES:[DI+04]       { AX:=XSize / CX:=YSize }
       MOV      BX,pX
       CMP      BX,AX
       JAE      @@2                 { X-Koordinate ÅberprÅfen... }
       MOV      BX,pY
       CMP      BX,CX               { Y-Koordinate ÅberprÅfen...}
       JAE      @@2                 { => Koordinaten nicht ausserhalb des Bereiches }
       MUL      BX                  { DX:AX := (pY * XSize) + pX }
       ADD      AX,pX
       ADC      DX,00
       SHL      DX,12               { DX * $1000 }
       ADD      DX,ES:[DI]          { DX:AX => Speicherkoordinaten }
       MOV      ES,DX
       MOV      DI,AX
       MOV      AL,pColor           { Farbe laden }
       STOSB                        { Farbe setzten }
  @@2: POP      DS
  end;

  function LCanvas.GetPixel(pX, pY : Word) : Byte; assembler;
  asm
       PUSH     DS                  { => Siehe "SetPixel" }
       LES      DI,Self
       ADD      DI,02
       MOV      CX,ES:[DI]
       JCXZ     @@2                 { Nur, wenn ein Bild vorhanden ist. }
       MOV      AX,ES:[DI+02]
       MOV      CX,ES:[DI+04]       { AX:XSize / CX:YSize }
       MOV      BX,pX
       CMP      BX,AX
       JA       @@2
       MOV      BX,pY
       CMP      BX,CX
       JA       @@2                 { Koordinaten nicht ausserhalb des Bereiches }
       MUL      BX
       ADD      AX,pX
       ADC      DX,00
       SHL      DX,12
       ADD      DX,ES:[DI]          { DX:AX => Speicherkoordinaten }
       MOV      ES,DX
       MOV      DI,AX
       MOV      AL,ES:[DI]
  @@2: POP      DS
  end;

  procedure LCanvas.GetLine(pY : Word; var pBuffer); assembler;
  var
     Seg_Buffer : Word;              { SS:[BP-2] }
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,02                { VMT Åberspringen }
       MOV      AX,ES:[DI]
       MOV      SS:[BP-02],AX        { Seg_Buffer mit dem Segment der Zeichnung laden. }
       MOV      BX,ES:[DI+04]        { YSize nach BX }
       MOV      AX,pY                { pY nach AX }
       CMP      AX,BX
       JAE      @@1                  { pY nicht grîsser als BX }
       MOV      CX,ES:[DI+02]
       MUL      CX                   { Offset in DX:AX berechnen. }
       MOV      BX,AX                { Offset retten }
       MOV      CX,10h
       DIV      CX                   { Segmentanteil des Offset berechnen }
       ADD      SS:[BP-02],AX        { Als Segment speichern }
       AND      BX,0Fh               { öbrigbleibender Offset... }
       MOV      SI,BX                { ...nach SI }
       MOV      DX,SS:[BP-02]        { Segment nach DS }
       MOV      DS,DX                { DS:SI => Zeichnung }
       MOV      CX,ES:[DI+02]        { CX mit XSize laden }
       LES      DI,pBuffer           { ES:DI => RÅckgabe }
       CLD
       REP      MOVSB                { Kopieren... }
  @@1: POP      DS
  end;

  procedure LCanvas.SetLine(pY : Word; var pBuffer); assembler;
  var
     Seg_Buffer : Word;         { SS:[BP-2] }
  asm
       PUSH     DS
       LDS      SI,Self
       ADD      SI,02                { VMT Åberspringen }
       MOV      AX,DS:[SI]
       MOV      SS:[BP-02],AX        { Seg_Buffer mit dem Segment der Zeichnung laden. }
       MOV      BX,DS:[SI+04]        { YSize nach BX }
       MOV      AX,pY                { pY nach AX }
       CMP      AX,BX
       JAE      @@1                  { pY nicht grîsser als BX }
       MOV      CX,DS:[SI+02]
       MUL      CX                   { Offset in DX:AX berechnen. }
       MOV      BX,AX                { Offset retten }
       MOV      CX,10h
       DIV      CX                   { Segmentanteil des Offset berechnen }
       ADD      SS:[BP-02],AX        { Als Segment speichern }
       AND      BX,0Fh               { öbrigbleibender Offset... }
       MOV      DI,BX                { ...nach DI }
       MOV      DX,SS:[BP-02]        { Segment nach DS }
       MOV      ES,DX                { ES:DI => Zeichnung }
       MOV      CX,DS:[SI+02]        { CX mit XSize laden }
       LDS      SI,pBuffer           { DS:SI => Buffer }
       CLD
       REP      MOVSB                { Kopieren... }
  @@1: POP      DS
  end;

  procedure LCanvas.Show(pX,pY : Word);
  var
    x,y    : Word;
    Buffer : Array[0..799] of Byte;
  begin
    if (MemSeg = 0) then Exit;                 { Nur, wenn ein Bild vorhanden }
    For x := 0 to 799 do Buffer[x] := 0;       { Buffer lîschen. }
    For y := 0 to (YSize-1) do begin
      GetLine(y,Buffer);                       { Daten in Buffer laden }
      Screen.PutLine(pX,pY+y,XSize-1,Buffer);  { Buffer auf Bildschirm darstellen }
    end;
  end;

  procedure LCanvas.Dim3(pC1,pC2 : Byte); assembler;
  asm
       PUSH     DS
       PUSH     0000h
       MOV      AL,pC1
       PUSH     AX
       LDS      SI,Self
       PUSH     DS
       PUSH     SI
       CALL     HLine
       MOV      AX,DS:[SI+06]
       DEC      AX
       PUSH     AX
       MOV      AL,pC2
       PUSH     AX
       PUSH     DS
       PUSH     SI
       CALL     HLine
       PUSH     0000h
       MOV      AL,pC1
       PUSH     AX
       PUSH     DS
       PUSH     SI
       CALL     VLine
       MOV      AX,DS:[SI+04]
       DEC      AX
       PUSH     AX
       MOV      AL,pC2
       PUSH     AX
       PUSH     DS
       PUSH     SI
       CALL     VLine
       POP      DS
  end;

  procedure LCanvas.HLine(pY : Word; pColor : Byte); assembler;
  var
     Pap_Seg : Word;
     Pap_Ofs : Word;
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,02
       MOV      AX,ES:[DI]
       MOV      SS:[BP-02],AX
       MOV      AX,pY
       MOV      BX,ES:[DI+04]
       CMP      AX,BX
       JAE      @@1
       MOV      CX,ES:[DI+02]
       MUL      CX
       MOV      CX,AX
       MOV      BX,10h
       DIV      BX
       ADD      SS:[BP-02],AX
       AND      CX,0Fh
       MOV      SS:[BP-04],CX
       MOV      CX,ES:[DI+02]
       MOV      DX,SS:[BP-02]
       MOV      ES,DX
       MOV      DI,SS:[BP-04]
       MOV      AL,pColor
       CLD
       REP      STOSB
  @@1: POP      DS
  end;

  procedure LCanvas.VLine(pX : Word; pColor : Byte); assembler;
  var
     Pap_Seg : Word;
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,02
       MOV      AX,ES:[DI]
       MOV      SS:[BP-02],AX
       MOV      AX,pX
       MOV      BX,ES:[DI+02]
       CMP      AX,BX
       JAE      @@4
       MOV      CX,ES:[DI+04]
       MOV      ES,SS:[BP-02]
       MOV      DI,pX
       MOV      AL,pColor
  @@1: MOV      ES:[DI],AL
       ADD      DI,BX
       JNC      @@2
       MOV      DX,ES
       ADD      DX,1000h
       MOV      ES,DX
  @@2: LOOP     @@1
  @@4: POP      DS
  end;

  procedure LCanvas.Clear(pColor : Byte); assembler;
  asm
       PUSH     DS
       LES      DI,Self
       ADD      DI,02
       MOV      AX,ES:[DI+02]
       MOV      CX,ES:[DI+04]
       MUL      CX
       MOV      CX,DX
       MOV      BX,AX
       MOV      AX,ES:[DI]
       MOV      ES,AX
       CLD
       JCXZ     @@B
       PUSH     BX
       MOV      BX,0FFFFh
  @@A: PUSH     CX
       XOR      DI,DI
       CALL     @@1
       MOV      DX,ES
       ADD      DX,1000h
       MOV      ES,DX
       POP      CX
       LOOP     @@A
       POP      BX
       JMP      @@C
  @@B: XOR      DI,DI
  @@C: DEC      BX
       CALL     @@1
       JMP      @@3
  @@1: MOV      CX,BX
       JCXZ     @@2
       MOV      AL,pColor
       REP      STOSB
       STOSB
  @@2: RETN
  @@3: POP      DS
  end;

  procedure LCanvas.Insert(ACanvas: HCanvas; ax,ay : Word);
  var
    y : Word;
    Buf : Array[0..1023] of byte;
  begin
    if ACanvas^.XSize > 1020 then Exit;
    For y := 0 to (ACanvas^.YSize-1) do begin
      ACanvas^.GetLine(y,Buf);
      SetInsLine(ax,ay+y,ACanvas^.XSize,Buf);
    end;
  end;

  function LCanvas.Copy(x1,y1,x2,y2: Word): HCanvas;
  var
    Canv: HCanvas;
    i,j : Word;
    Buf : Array[0..1023] of Byte;
  begin
    Canv := New(HCanvas, Init(x2-x1,y2-y1,0));
    if Canv = nil then begin
      Copy := nil; Exit;
    end;
    For i := y1 to y2 do begin
      GetLine(i, Buf);
      For j := 0 to (x2-x1) do
       Buf[j] := Buf[j+x1];
      Canv^.SetLine(i-y1, Buf);
    end;
    Copy := Canv;
  end;

  procedure LCanvas.SetInsLine(pX, pY, pL : Word; var pBuffer); assembler;
  var
    Seg_Buffer : Word;          { SS:[BP-2] }
  asm
       PUSH     DS
       LDS      SI,Self
       ADD      SI,02                { VMT Åberspringen }
       MOV      AX,DS:[SI]
       MOV      SS:[BP-02],AX        { Seg_Buffer mit dem Segment der Zeichnung laden. }
       MOV      BX,DS:[SI+04]        { YSize nach BX }
       MOV      AX,pY                { pY nach AX }
       CMP      AX,BX
       JAE      @@3                  { pY nicht grîsser als BX }
       MOV      CX,DS:[SI+02]
       MUL      CX                   { Offset in DX:AX berechnen. }
       ADD      AX,pX
       MOV      BX,AX                { Offset retten }
       MOV      CX,10h
       DIV      CX                   { Segmentanteil des Offset berechnen }
       ADD      SS:[BP-02],AX        { Als Segment speichern }
       AND      BX,0Fh               { öbrigbleibender Offset... }
       MOV      DI,BX                { ...nach DI }
       MOV      DX,SS:[BP-02]        { Segment nach DS }
       MOV      ES,DX                { ES:DI => Zeichnung }
       MOV      CX,pL                { CX mit XSize laden }
       LDS      SI,pBuffer           { DS:SI => Buffer }
       CLD
  @@1: LODSB
       OR       AL,AL
       JZ       @@2
       STOSB
       DEC      DI
  @@2: INC      DI
       LOOP     @@1
  @@3: POP      DS
  end;

  procedure LCanvas.Store(var AHandle: LCanvasHandle); assembler;
  asm
       PUSH     DS
       LES      DI,AHandle
       LDS      SI,Self
       ADD      DI,02
       ADD      SI,02
       MOV      CX,DS:[SI]
       JCXZ     @@1
       CLD
       MOVSW
       MOVSW
       MOVSW
       XOR      AX,AX
       LES      DI,Self
       ADD      DI,02
       STOSW
       STOSW
       STOSW
  @@1: POP      DS
  end;

  procedure LCanvas.Load(var AHandle: LCanvasHandle); assembler;
  asm
       PUSH     DS
       LES      DI,Self
       LDS      SI,AHandle
       ADD      DI,02
       ADD      SI,02
       CLD
       MOVSW
       MOVSW
       MOVSW
       POP      DS
  end;


 { ********************************************************** }
 { ********************************************************** }
 procedure DrawLine(ACanvas : HCanvas; x1,y1,x2,y2 : Integer; pColor : Byte);
 var
   V : Real;
   i : Integer;
 begin
   x2 := x2 - x1; y2 := y2 - y1;        { x2 und y2 als Differenzen der Koordinaten }
   if x2 = 0                            { Nicht durch NUll teilen ! }
    then V := 0
    else V := y2 / x2;                  { V : VerhÑltnis zwischen x2 und y2 }
   i := 0;
   if v = 0 then begin                  { Gerade Linie: }
     if (y2 > 0)
      then For i := 0 to y2 do ACanvas^.SetPixel(x1,y1+i,pColor)  { Vertikal }
      else For i := 0 to x2 do ACanvas^.SetPixel(x1+i,y1,pColor); { Horizontal }
     Exit;                              { Prozedur verlassen. }
   end;
   if (abs(v) < 1)                      { Hier wird entschieden, ob der     }
    then repeat                         { Winkel kleiner oder grîsser als   }
      if x2 > 0                         { 45¯ ist, damit die Linie durchge- }
       then inc(i)                      { zogen gezeichnet wird.            }
       else dec(i);
      ACanvas^.SetPixel(x1+i,y1+Round(i * V),pColor)
    until (abs(i) >= abs(x2))
    else repeat
      if y2 > 0                         { "VorwÑrts" und "RÅckwÑrts" zeichnen. }
       then inc(i)
       else dec(i);
      ACanvas^.SetPixel(x1+Round(i / V),y1+i,pColor);
    until (abs(i) >= abs(y2));
 end;

 procedure DrawCircle(ACanvas : HCanvas; pX,pY,pR : Word; pColor : Byte);
 var
   i,j : Integer;
   k   : LongInt;
 begin
   k := Sqr(pR);
   For i := (pX - pR) to (pX + pR) do
    if (i > 0) then begin
      j := Round(Sqrt(k - Sqr(i-pX)));
      ACanvas^.SetPixel(i,pY-j,pColor);
      ACanvas^.SetPixel(i,pY+j,pColor);
    end;
   For j := (pY - pR) to (pY + pR) do
    if (j > 0) then begin
      i := Round(Sqrt(k - Sqr(j-pY)));
      ACanvas^.SetPixel(pX-i,j,pColor);
      ACanvas^.SetPixel(pX+i,j,pColor);
    end;
 end;

 procedure DrawEllipse(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);
 var
   mX,mY : Word;
   Rx,Ry : Word;
   i     : Word;
 begin
   if (x2 < x1) then begin
     i := x1; x1 := x2; x2 := i;
   end;
   if (y2 < y1) then begin
     i := y1; y1 := y2; y2 := i;
   end;
   Rx := (x2 - x1) div 2; Ry := (y2 - y1) div 2;
   mX := x1 + Rx;         mY := y1 + Ry;
   i := 628;
   if (x2 > 300) or (y2 > 300) then i := 2500;
   For i := 1 to i do
     ACanvas^.SetPixel(mX+Round(cos(i / 100)*Rx),
                       mY+Round(sin(i / 100)*Ry),pColor);
 end;

 procedure DrawRect(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);
 var
   i : Word;
 begin
   For i := x1 to x2 do begin
     ACanvas^.SetPixel(i,y1,pColor);
     ACanvas^.SetPixel(i,y2,pColor);
   end;
   For i := y1 to y2 do begin
     ACanvas^.SetPixel(x1,i,pColor);
     ACanvas^.SetPixel(x2,i,pColor);
   end;
 end;

 procedure DrawBox(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pColor : Byte);
 var
   x,y : Word;
 begin
   For y := y1 to y2 do
    For x := x1 to x2 do
     ACanvas^.SetPixel(x,y,pColor);
 end;

 procedure DrawTextXY(ACanvas : HCanvas; pX,pY : Word; pColor, pOpt : Byte ; pText : String);
 var
   CharSize : Word absolute $0000:$0485;
   FPtr     : Pointer absolute $0000:$010C;
   CharRow  : Byte;
   FontSeg,FontOfs,i,j : Word;
   k : byte;
 begin
   Case pOpt of                                 { Bei Optionen mÅssen teilweise... }
     1 : pY := pY + (ord(pText[0]) * 8);        { ... die Anfangskoordinaten neu... }
     3,4: pX := pX + (ord(pText[0]) * 8);       { ...gesetzt werden. }
   end;
   FontSeg := Seg(FPtr^);                       { Segmentadresse des Zeichensatzes. }
   For k := 1 to ord(pText[0]) do begin         { Jedes zeichen. }
     FontOfs := Ofs(FPtr^) + (CharSize * Ord(pText[k]));  { Offset des Zeichensatzes. }
     For i := 0 to (CharSize - 1) do begin      { Zeichenhîhe. }
       CharRow := Mem[FontSeg:FontOfs];         { Zeichenlinie nach CharRow }
       For j := 0 to 7 do begin                 { Jedes Bit testen }
         if (CharRow and $80) <> 0 then         { Wenn gesetzt, dann zeichnen: }
          Case pOpt of
            1 : ACanvas^.SetPixel(pX+i,pY+8-j,pColor);            { Buchstaben um 90¯ gedreht... }
            3 : ACanvas^.SetPixel(pX+8-j,pY+CharSize-i,pColor);   { Buchstaben um 180¯ gedreht... }
            4 : ACanvas^.SetPixel(pX+8-j,pY+i,pColor);            { Buchstaben spiegeln... }
            5 : ACanvas^.SetPixel(pX+j,pY+CharSize-i,pColor);     { Buchstaben spiegeln... }
            7 : begin
              ACanvas^.SetPixel(pX+(j*2),pY+i,pColor);          { Jeden Pixel doppelt adrstellen... }
              ACanvas^.SetPixel(pX+(j*2)+1,pY+i,pColor);
            end;
          else
            ACanvas^.SetPixel(pX+j,pY+i,pColor);          { Normale Pixelausgabe }
          end;
         CharRow := CharRow shl 1;              { NÑchstes Bit. }
       end;
       if pOpt = 6 then For j := 0 to 7         { Unterstreichende Linie: }
        do ACanvas^.SetPixel(pX+j,pY+CharSize,pColor);
       Inc(FontOfs);                            { NÑchste Linie }
     end;
     Case pOpt of
       1 : pY := pY - 8;          { Eins nach Oben... }
       2 : pY := pY + CharSize;   { Eins anch Oben... }
       3,4: pX := pX - 8;         { Eins nach Links... }
       7 : pX := pX + 16;         { Zwei nach Rechts... }
     else
       pX := pX + 8;              { Normal eins nach Rechts... }
     end;
   end;
 end;

 procedure ShowTextXY(ACanvas : HCanvas; pX,pY : Word; pC1, pC2 : Byte ; pText : String);
 var
   CharSize : Word absolute $0000:$0485;
   FPtr     : Pointer absolute $0000:$010C;
   CharRow  : Byte;
   FontSeg,FontOfs,i,j : Word;
   k : byte;
 begin
   FontSeg := Seg(FPtr^);               { => Siehe DrawTextXY }
   For k := 1 to ord(pText[0]) do begin
     FontOfs := Ofs(FPtr^) + (CharSize * Ord(pText[k]));
     For i := 0 to (CharSize - 1) do begin
       CharRow := Mem[FontSeg:FontOfs];
       For j := 0 to 7 do begin
         if (CharRow and $80) <> 0
          then ACanvas^.SetPixel(pX+j,pY+i,pC1)
          else ACanvas^.SetPixel(pX+j,pY+i,pC2);
         CharRow := CharRow shl 1;
       end;
       Inc(FontOfs);
     end;
     pX := pX + 8;
   end;
 end;

 procedure ReplaceLine(ACanvas : HCanvas; x1,y1,x2,y2 : Word; pC1,pC2 : Byte);

  procedure PaintPixel(pX,pY:Word);
  begin
    if ACanvas^.GetPixel(pX,pY) = pC1
     then ACanvas^.SetPixel(pX,pY,pC2);
  end;

 var
   V : Real;
   i : Integer;
 begin
   x2 := x2 - x1; y2 := y2 - y1;        { => Siehe DrawLine }
   if x2 = 0
    then V := 0
    else V := y2 / x2;
    i := 0;
    if v = 0 then begin
      if (y2 > 0)
       then For i := 0 to y2 do PaintPixel(x1,y1+i)
       else For i := 0 to x2 do PaintPixel(x1+i,y1);
      Exit;
    end;
    if (abs(v) < 1)
     then repeat
         if x2 > 0
          then inc(i)
          else dec(i);
         PaintPixel(x1+i,y1+Round(i * V))
       until (abs(i) >= abs(x2))
     else repeat
         if y2 > 0
          then inc(i)
          else dec(i);
         PaintPixel(x1+Round(i / V),y1+i);
       until (abs(i) >= abs(y2));
 end;

 procedure ReplaceCanvas(ACanvas: HCanvas; pC1, pC2: Byte); assembler;
 asm
       PUSH     DS
       MOV      DX,ACanvas.Word[2]      { Segmentadresse laden }
       MOV      ES,DX                   { => LES DI,ACanvas^   }
       MOV      DI,ACanvas.Word[0]      { Offsetadresse laden  }
       ADD      DI,02
       MOV      DX,ES:[DI]
       OR       DX,DX
       JZ       @@3
       MOV      DS,DX                   { Segment des Bildes nach DS }
       XOR      SI,SI                   { Offset Null: LDS SI,Bild   }
       MOV      AX,ES:[DI+02]           { XSize }
       MOV      CX,ES:[DI+04]           { YSize }
       MUL      CX                      { Speichergrîsse in DX:AX }
       MOV      CX,AX                   { Speichergrîsse nach CX }
       JCXZ     @@3                     { Wenn Speicher Null, dann Ende }
       MOV      AH,pC1                  { Vergleichsfarbe pC1 laden }
       CLD                              { AufwÑrts zÑhlen }
  @@1: LODSB                            { Pixel nach AL }
       CMP      AL,AH                   { Wenn nicht identisch... }
       JNE      @@2                     { ...weiter beim nÑchsten Pixel }
       MOV      AL,pC2                  { ...sonst Farbe pC2 setzen. }
       MOV      DS:[SI-1],AL
  @@2: LOOP     @@1                     { NÑchster Pixel }
  @@3: POP      DS
 end;

 function LoadBMP(pFileName : String) : HCanvas;

  function OpenFile(pFN : String) : Word; assembler;
  var
     a : Word;
     h : Word;
  asm
       PUSH     DS
       LDS      SI,pFN               { Dateinamen laden. }
       MOV      DX,SI
       LODSB                       { LÑnge nach AL }
       INC      DX                   { DS:DX als Adresse des Dateinamens }
       XOR      AH,AH
       ADD      SI,AX                { Am Schluss des Strings... }
       MOV      DS:[SI],AH           { ...ein Null-Zeichen }
       MOV      AX,3D00h             { Funktionsnummer laden }
       INT      21h                  { Datei îffnen }
       JNC      @@1                  { Kein Fehler, zu @@1 }
       XOR      AX,AX                { Handle = 0 }
       JMP      @@2                  { Ende }
  @@1: MOV      SS:[BP-04],AX        { Handle nach "h"... }
       MOV      BX,AX                { ... und nach BX }
       PUSH     SS                   { MOV DS,SS }
       POP      DS
       MOV      DX,BP                { DS:DX => Adresse von a }
       SUB      DX,02
       MOV      CX,02                { 2 Bytes lesen }
       MOV      AX,3F00h             { Funktionsnummer }
       INT      21h                  { Aus Datei lesen }
       MOV      CX,SS:[BP-02]        { Gelsenes Word nach CX }
       MOV      BX,'MB'              { ÅberprÅfen, ob erstes Word in Datei = 'BM' }
       XOR      AX,AX
       CMP      CX,BX
       JNE      @@2                  { Wenn nicht BMP-Datei, dann RÅckgabe gleich Null }
       MOV      AX,SS:[BP-04]        { Handle nach AX als RÅckgabewert }
  @@2: POP      DS
  end;

  procedure CloseFile(pHan : Word); assembler;
  asm
       PUSH     DS
       MOV      AH,3Eh              { Funktionsnummer }
       MOV      BX,pHan             { Handle }
       INT      21h                 { Datei schliessen }
       POP      DS
  end;

  procedure ReadFromFile(pHan, pPos, pLen : Word; var ABuffer); assembler;
  asm
       PUSH     DS
       MOV      DX,pPos
       MOV      AX,0FFFFh
       CMP      DX,AX
       JE       @@1                { Wenn Pos = -1, dann Dateizeiger nicht verschieben }
       MOV      BX,pHan
       MOV      AX,4200h
       XOR      CX,CX
       INT      21h                { Dateizeiger auf Position setllen. }
  @@1: LDS      DX,ABuffer         { Adresse von ABuffer nach DS:DX }
       MOV      CX,pLen            { BufferlÑnge nach CX }
       MOV      BX,pHan
       MOV      AX,3F00h
       INT      21h                { Aus Datei lesen }
       POP      DS
  end;

 var
   Handle : Word;
   Buffer : Array[0..1024] of Byte;
   x,y,xs : Word;
   c      : Byte;
   Canvas : HCanvas;
   Size,i : Word;
   j      : Word;
   zus    : LongInt;
 begin
   Handle := OpenFile(pFileName);
   if (Handle = 0) then begin      { Konnte Datei nicht îffnen }
     LoadBMP := nil;
     Exit;
   end;
   ReadFromFile(Handle,$02,2,Size);  { Dateigrîsse lesen }
   ReadFromFile(Handle,$12,2,x);     { X-Ausdehnung }
   ReadFromFile(Handle,$16,2,y);     { Y-Ausdehnung }
   ReadFromFile(Handle,$1C,1,c);     { Anzahl Farben }
   ReadFromFile(Handle,$0A,2,i);     { Beginn des Datenbereiches. }
   ReadFromFile(Handle,i-1,1,Buffer);{ Dateizeiger auf Datenbereich setzten }
   if x > 1020 then begin            { Verarbeitet maximal 1020 Pixel in X-Achse }
     LoadBMP := nil;
     Exit;
   end;
   Zus := (Size - i); Zus := Zus * 2;     { Bei 16 Farben die Anzahl der ... }
   Zus := Zus div y;  Zus := Zus - x;     { ..."FÅllbytes" ermitteln }
   For i := 0 to 1024 do Buffer[i] := 0;  { Buffer lîschen. }
   Canvas := New(HCanvas, Init(x,y,0));   { Ein Canvas auf dem Speicher generieren. }
   if Canvas = nil then begin             { Nicht erfolgreich: }
     LoadBMP := nil;
     Exit;
   end;
   xs := x div 2;                         { Bei 16 Farben sind pro Byte 2 Pixel gespeichert ! }
   for i := (y-1) downto 0 do begin       { Alle Zeilen laden. }
     if c = $04 then begin                 { 16 Farben: }
       ReadFromFile(Handle,$FFFF,(X+Zus) div 2,Buffer);      { Daten lesen }
       For j := 1 to XS do begin
         Canvas^.SetPixel((j*2)-1,i,Buffer[j-1] div $10);    { Pixel schreiben. }
         Canvas^.SetPixel((j*2),i,Buffer[j-1] mod $10);
       end;
     end;
     if c = $08 then begin                 { 256 Farben: }
       ReadFromFile(Handle,$FFFF,x,Buffer);           { Daten lesen }
       For j := 1 to X do
        Canvas^.SetPixel(j-1,i,Buffer[j-1]);          { Pixel schreiben. }
     end;
   end;
   CloseFile(Handle);           { Datei wieder schliessen }
   LoadBMP := Canvas;           { Bild als RÅckgabewert. }
 end;

 function GetPicture(x1,y1,x2,y2 : Word) : HCanvas;
 var
   Buffer : Array[0..1024] of Byte;
   i      : Word;
   ACanvas: HCanvas;
 begin
   if (y2-y1) > 1020 then begin
     GetPicture := nil; Exit;
   end;
   ACanvas := New(HCanvas, Init(x2-x1,y2-y1,0));       { Canvas generieren. }
   if (ACanvas = nil) then begin                { Fehler. }
     GetPicture := nil; Exit;
   end;
   For i := 0 to 1024 do Buffer[i] := $00;      { Buffer lîschen }
   For i := y1 to y2 do begin
     Screen.GetLine(x1,i,x2-x1,Buffer);         { Pixel vom Bildschirm lesen }
     ACanvas^.SetLine(i-y1,Buffer);             { und in Bild schreiben. }
   end;
   GetPicture := ACanvas;       { Bild als RÅckgabewert. }
 end;

 { ********************************************************** }
 { ********************************************************** }

 procedure LScreen.Init(pVesaMode, pX, pY : Word); assembler;
 var
    VesaBuffer : Array[0..255] of Byte;
 asm
      PUSH     DS
      MOV      AH,0Fh
      INT      10h
      PUSH     AX           { Alten Videomodus ermitteln. }
      MOV      DX,SS
      MOV      ES,DX
      MOV      AX,4F00h
      LEA      DI,VesaBuffer
      INT      10h
      CMP      AX,004Fh
      JNE      @@3
      MOV      AX,4F01h
      MOV      CX,pVesaMode
      INT      10h
      CMP      AX,004Fh
      JNE      @@3
      MOV      AX,ES:[DI+04]
      MOV      BX,ES:[DI+12]
      MOV      DX,ES:[DI+14]
      XOR      CX,CX
 @@1: CMP      AX,64
      JAE      @@2
      ADD      AX,AX
      INC      CX
      JMP      @@1
 @@2: CLD
      LES      DI,Self
      XOR      AX,AX
      STOSW                     { Flag auf Null }
      MOV      AX,pX              { Maximale Koordinaten speichern: }
      STOSW
      MOV      AX,pY
      STOSW
      POP      AX                 { Den alten Videmodus speichern. }
      STOSB
      MOV      AL,0Fh             { Als Vordergrundfarbe Weiss nehmen }
      STOSB
      MOV      AX,CX              { Shift speichern }
      STOSW
      MOV      AX,BX              { Adresse der Shift-Change-Prozedur speichern. }
      STOSW
      MOV      AX,DX
      STOSW
      MOV      AX,4F02h
      MOV      BX,pVesaMode       { VESA-Modus setzten }
      INT      10h
      XOR      BX,BX
      MOV      DX,BX
      LES      DI,Self
      CALL     DWORD PTR ES:[DI+10]{ Erste Bank... }
      JMP      @@4
 @@3: ADD      SP,02              { Stack wieder bereinigen. }
 @@4: POP      DS
 end;

 procedure LScreen.Done; assembler;
 asm
      LES      DI,Self                { Den ursprÅnglichen  }
      MOV      AL,ES:[DI+06]          { Videomodus wiederher- }
      XOR      AH,AH                  { stellen. }
      INT      10h
 end;

 procedure LScreen.InitStd;
 begin
   Init($0101,640,480);   { Initialisierung mit 640x480 Pixel und 256 Farben. }
 end;

 procedure LScreen.PutPixel(pX,pY : Word; pColor : Byte); assembler;
 asm
      PUSH     DS
      LES      DI,Self
      MOV      CX,ES:[DI+02]       { CX mit XSize laden }
      MOV      AX,pY
      MUL      CX                  { Die Adresse berechnen. }
      AD      A\.0 =ê", ¨ü ≤92ππ≤ê>ÜÖ ¢!ê",=ê$∑",24≤ê)∏2¥±¥2π10∑5ê>ÜÖ(*©§ ¨Ö&"©ê"$ñ)≤∂3Ö&ß´"$"©ù-¢$ÆÜÖ!¶®"&"$Ö%"ê  ÜÖ&ß´"©ù-¢$Æñ"&Ö,'©"$"$Ö&ß´!¨"©ù-¢$ïò.ÜÖ,'©!,!,Ö)§&",!¶Ö!†¶&"+ß©"(*)"©ù-¢$ïòò.ÜÖ  ù('® ¨Ö&ß´", ò4=ê)≤≥∂≤∑:0≤92ππ≤ê22πê!4∂29±¥4π6πê60≤2∑>ÜÖ&ß´"©ñ",Ö   MOV      DI,AX               { Offsetadresse nach DI }
      MOV      AL,pColor           { Farbe nach AL }
      MOV      ES:[DI],AL          { Pixel setzten }
      POP      DS
 end;

 procedure LScreen.PutLine(pX,pY,pL : Word; var Buffer); assembler;
 asm
      PUSH     DS
      LES      DI,Self
      MOV      AX,ES:[DI+02]
      MOV      CX,pY
      MUL      CX         { Speicheradresse berechnen. }
      ADD      AX,pX      { X-Koordinate hinzuzÑhlen }
      ADC      DX,00      { Speicherbank in DX }
      MOV      CX,pL      { LÑnge des Buffers nach pL }
      ADD      AX,CX      { Kommt Linie in 2 verschiedene Banken }
      JNC      @@2        { Nein, dann weiter bei @@2 }
 @@1: PUSH     DX
      PUSH     AX         { Bank, sowie Koordinaten sichern. }
      SUB      CX,AX      { Zuerst in erste Bank schreiben. }
      CALL     @@3        { Bank setzen. }
      MOV      DX,0A000h  { Segment setzten. }
      MOV      ES,DX
      XOR      DI,DI
      DEC      DI
      LDS      SI,Buffer  { Buffer nach DS:SI }
      ADD      SI,CX
      DEC      SI
      STD
      PUSHA
      CALL     @@5        { REP      MOVSB }
      POPA
      POP      CX
      POP      DX
      INC      DL         { NÑchste Bank. }
 @@2: CALL     @@3        { Bank setzten }
      MOV      DX,0A000h  { Segmentadresse nach ES }
      MOV      ES,DX
      MOV      DI,AX      { Offsetadresse nach DI }
      LDS      SI,Buffer
      STD
      INC      CX
      ADD      SI,pL
      CALL     @@5        { REP      MOVSB }
      JMP      @@8        { Fertig... }
 @@3: PUSHA               { Setzte die richtige Speicherbank }
      PUSH     ES
      LES      DI,Self
      MOV      DH,ES:[DI]
      CMP      DL,DH
      JE       @@4
      MOV      ES:[DI],DL
      XOR      DH,DH
      MOV      CX,ES:[DI+08]
      XOR      BX,BX
      SHL      DX,CL
      CALL     DWORD PTR ES:[DI+10]
 @@4: POP      ES
      POPA                  { Register zurÅck }
      RETN                  { ZurÅck... }
 @@5: LODSB                 { Pixel aus Canvas lesen }
      OR       AL,AL        { Wenn nicht Null, dann zeichnen }
      JNZ      @@6
      OR       DI,DI
      JZ       @@6
      MOV      AX,ES
      DEC      DI
      SBB      AX,00
      MOV      ES,AX
      JMP      @@7
 @@6: STOSB                 { Zeichnen }
 @@7: LOOP     @@5          { Wiederholen }
      RETN                  { ZurÅck }
 @@8: POP      DS
 end;

 procedure LScreen.GetLine(pX,pY,pL : Word; var Buffer); assembler;
 asm
      PUSH     DS
      LES      DI,Self
      MOV      AX,ES:[DI+02]
      MOV      CX,pY
      MUL      CX         { Speicheradresse berechnen. }
      ADD      AX,pX      { X-Koordinate hinzuzÑhlen }
      ADC      DX,00      { Speicherbank in DX }
      MOV      CX,pL      { LÑnge des Buffers nach pL }
      ADD      AX,CX      { Kommt Linie in 2 verschiedene Banken }
      JNC      @@2        { Nein, dann weiter bei @@2 }
 @@1: PUSH     DX
      PUSH     AX         { Bank, sowie Koordinaten sichern. }
      SUB      CX,AX      { Zuerst aus erster Bank lesen. }
      CALL     @@3        { Bank setzen. }
      MOV      DX,0A000h  { Segment setzten. }
      MOV      DS,DX
      XOR      SI,SI
      DEC      SI
      LES      DI,Buffer  { Buffer nach DS:SI }
      ADD      DI,CX
      DEC      DI
      STD
      REP      MOVSB      { lesen... }
      POP      CX
      POP      DX
      INC      DL         { NÑchste Bank. }
 @@2: CALL     @@3
      MOV      DX,0A000h
      MOV      DS,DX
      MOV      SI,AX
      LES      DI,Buffer
      STD
      INC      CX
      ADD      DI,pL
      REP      MOVSB
      JMP      @@5          { Fertig... }
 @@3: PUSHA               { Setzte die richtige Speicherbank }
      PUSH     ES
      LES      DI,Self
      MOV      DH,ES:[DI+01]
      CMP      DL,DH
      JE       @@4
      MOV      ES:[DI+01],DL
      XOR      DH,DH
      MOV      CX,ES:[DI+08]
      MOV      BX,01
      SHL      DX,CL
      CALL     DWORD PTR ES:[DI+10]
 @@4: POP      ES
      POPA
      RETN                  { ZurÅck... }
 @@5: POP      DS
 end;

 function LScreen.GetPixel(pX,pY : Word) : Byte; assembler;
 asm
      MOV      AH,0Dh
      XOR      BX,BX
      MOV      CX,pX              { BIOS aufrufen }
      MOV      DX,pY
      INT      10h
 end;

     { => Siehe DrawTextXY }
 procedure LScreen.Output(pX,pY : Word; Str : String);
 var
    CharSize: Word absolute $0000:$0485;
    FOfs    : Word absolute $0000:$010C;
    FSeg    : Word absolute $0000:$010E;
    CharRow : Byte;
    i,j,Adr : Word;
    k       : Byte;
 begin
   For k := 1 to ord(Str[0]) do begin
     Adr := FOfs + (CharSize * Ord(Str[k]));
     For i := 0 to (CharSize - 1) do begin
       CharRow := Mem[FSeg:Adr+i];
       For j := 0 to 7 do begin
         if (CharRow and $80) > 0 then
          PutPixel(pX+j,pY+i,Colr);
         CharRow := CharRow shl 1;
       end;
     end;
     pX := pX + 8;
   end;
 end;

 procedure LScreen.Input(pX,pY : Word; var Str : String);

  function GetKey : Char; assembler;
  asm
       XOR     AX,AX
       INT     16h
  end;

 var
   AKey : Char;
   BCol : Byte;                 { Die Hintergrundfarbe (bei Backspace) }
   FCol : Byte;
 begin
   FCol := Colr;                { Vordergrundfarbe ermitteln. }
   BCol := GetPixel(pX,pY);     { Hintergrundfarbe ermitteln. }
   repeat
     AKey := GetKey;            { Tastatureingabe. }
     if (AKey = #8) and (ord(Str[0]) > 0) then begin    { BackSpace }
       pX := pX - 8;            { ZurÅck. }
       Colr := BCol;            { Hintergrundfarbe }
       OutPut(pX,pY,Str[ord(Str[0])]);    { Zeichen ausgeben. }
       Str[0] := chr(ord(Str[0])-1);      { Zeichen im String lîschen }
       Colr := FCol;            { Vordergrundfarbe. }
     end;
     if (AKey > #13) and (ord(Str[0]) < 250) then begin   { "Normale" Taste }
       Str := Str + AKey;       { Zeichen an String anhÑngen. }
       OutPut(pX,pY,AKey);      { Zeichen darstellen }
       pX := pX + 8;            { Eins nach Rechts. }
     end;
   until AKey = #13;            { Bis Return gedrÅckt wird. }
 end;

 procedure LScreen.FillScreen(pColor : Byte); assembler;
 asm
      PUSH     DS
      MOV      CX,12        { Maximal 12 Banken vorhanden (Modus 1024x768) }
      XOR      DX,DX        { Bei Bank 0 beginnen... }
 @@A: PUSH     DX           { Bank und ZÑhler sichern }
      PUSH     CX
      CALL     @@1          { Segment FÅllen... }
      POP      CX
      POP      DX
      INC      DL           { NÑchste Bank }
      LOOP     @@A          { Wiederholen... }
      LES      DI,Self      { Wieder auf Bank 0 schalten: }
      XOR      BX,BX
      MOV      ES:[DI],BX
      XOR      DX,DX
      CALL     DWORD PTR ES:[DI+10]
      JMP      @@2          { Unterprozedur Åberspringen... }
 @@1: LES      DI,Self      { Bank setzten: }
      MOV      CX,ES:[DI+08]
      XOR      BX,BX
      SHL      DX,CL
      CALL     DWORD PTR ES:[DI+10]
      MOV      DX,0A000h    { Bildschirmsegment nach ES }
      MOV      ES,DX
      CLD
      XOR      DI,DI
      MOV      AL,pColor    { Farbe nach AL }
      XOR      CX,CX
      DEC      CX
      REP      STOSB        { Alles lîschen. }
      STOSB
      RETN                { ZurÅck... }
 @@2: POP      DS
 end;

 { ********************************************************** }
 { ********************************************************** }

 procedure PushCanvasHandle(var AHandle: LCanvasHandle);
 var
   Handl : Word;
   Size  : LongInt;
   Buffer: Pointer;
 begin
   if (AHandle.XmsMem > 0) or (AHandle.DosMem = 0) then Exit;
   Size := AHandle.XSize * AHandle.YSize + $10;
   Handl := Get_Emb((Size div $400)+1);
   if Handl = 0 then Exit;
   AHandle.XMSMem := Handl;
   Buffer := Ptr(AHandle.DosMem, 0);
   PushMem(Handl, Buffer^, Size);
   FreeMemSeg(AHandle.DosMem);
   AHandle.DosMem := 0;
 end;

 procedure PopCanvasHandle(var AHandle: LCanvasHandle);
 var
   Size  : LongInt;
   Buffer: Pointer;
   MemBeg: Word;
 begin
   if (AHandle.XmsMem = 0) or (AHandle.DosMem > 0) then Exit;
   Size   := AHandle.XSize * AHandle.YSize + $10;
   MemBeg := GetMemSeg(Size div $10);
   if MemBeg = 0 then Exit;
   Buffer := Ptr(MemBeg, 0);
   AHandle.DosMem := MemBeg;
   PopMem(AHandle.XMSMem, Buffer^, Size);
   Free_emb(AHandle.XMSMem);
   AHandle.XMSMem := 0;
 end;
END.