{ ************************************************************************** }
{                                                                            }
{                         HALMA                                              }
{                                                                            }
{                  (c) Dez 1998, Tobias Kohn                                 }
{                                                                            }
{                       VERSION 1.0                                          }
{                                                                            }
{ ************************************************************************** }
Program Halma_Spiel;
{$G+}                   { 286-Code erzeugen }
{$M 49152,1024,3072}    { Speicherbedarf begrenzen }
 uses Graph2, Halma, GObjects, GEditors, GStdDlg;
{ ************************************************************************** }
{ ************************************************************************** }

 const
   cm_Turn   = 100;     { Brett drehen }
   cm_SelFig = 101;     { Figur auswÑhlen }

   DateiPfad = '';      { Gibt den Pfad der Bilddateien an. }
                        { (wurde vor allem bei der Entwicklung benîtigt.) }
 procedure DrawMask; forward;                     { Quelltext folgt erst weiter vorne }

{ ************************************************************************** }
{    Ermîglicht dem Anwender das AuswÑhlen einer Figur und der Farben.       }
{ ************************************************************************** }
 procedure SelectFigure;

  { ************************************************************************ }
  {       Zeichnet einen Rahmen um die momentan selektierte Figur.           }
  { ************************************************************************ }
  procedure ShowRect(Nr: Byte);
  var
    i : Byte;
  begin
    Mouse^.Hide;            { Maus entfernen. }
    For i := 1 to 3 do
     if i = Nr then begin   { Schwarzer Rahmen }
       DrawRect(BFigure,1,1,35,40,$10); BFigure^.Show(i*40-25,95);
     end else begin         { Mîglicher Rahemen entfernen }
       DrawRect(BFigure,1,1,35,40,HGColor); BFigure^.Show(i*40-25,95);
     end;
    Mouse^.Show;             { Maus darstellen }
  end;
  { ************************************************************************ }

 type
   s7 = String[7];
 const
   Names: Array[1..3] of s7 = ('FIGUR','KEGEL','MANN');

 var
   OButton: LButton;       { Der OK-Button }
   R      : LRect;
   Event  : LEvent;
   i,j    : Byte;
   ColBox : LColorBox;     { AuswÑhlen der Hintergrundfarbe. }
   ShowBox: LCanvas;       { Anzeigen der gewÑhlten Farbe. }
   Liste  : HList;         { AuswÑhlen der Farbeinstellungen }
   StList : HStringList;
 begin
   Mouse^.Hide; Dispose(BFigure, Done); { Maus verstecken und Figur-Buffer freigeben. }
   Mouse^.SetCursor(Mouse^.StdCursor^);
   Screen.FillScreen(HGColor);         { Bildschirm lîschen. }
   SetRect(R,10,10,100,30);
   OButton.Init(nil, R, '&OK', cm_Ok); { Buttons initialisieren. }
   SetRect(R,10,200,60,300);
   ColBox.Init(nil, R);                { ColorBox initialisieren }
   SetRect(R,100,200,200,340);
   Liste := New(HList, Init(nil, R));  { Die Liste erzeugen. }
   StList := New(HStringList, Init);
   if (StList = nil) or (Liste = nil) then Exit;
   StList^.Add('Hintergrund');                  { Die StringListe mit Werten belegen. }
   StList^.Add('Normal 1');      StList^.Add('Normal 2');
   StList^.Add('Ziel 1');        StList^.Add('Ziel 2');
   StList^.Add('Lose Platte 1'); StList^.Add('Lose Platte 2');
   Liste^.AssignList(StList);          { Strings zuweisen.   }
   Liste^.Options := Liste^.Options or opt_3D;   { Liste 3-Dimensional darstellen. }
   Liste^.EventMask := Liste^.EventMask and not ev_Key; { FÅr Liste die tastaturereignisse sperren }
   Liste^.Show;
   OButton.Show;                       { Buttons darstellen. }
   ColBox.Show;                        { ColorBox darstellen. }
   ShowBox.Init(32,16,0);              { Anzeigefeld initialisieren. }
   For i := 1 to 3 do begin            { Die drei Mîglichkeiten darstellen }
     LoadFigure(DateiPfad+Names[i]+'.BMP');
     BFigure^.Show((i*40)-15,100);
     Dispose(BFigure, Done);
   end;
   BFigure := New(HCanvas, Init(40,45,0));  { Wird fÅr den Rahmen gebraucht. }
   i := 1; ShowRect(1);                     { Rahmen 1 zeichnen und Maus wieder sichtbar }
   j := 0; Mouse^.Show;
   repeat
     GetEvent(Event);                       { Ereignisse lesen und Maus als aktiv markieren }
     Event.MVisible := True;
     OButton.HandleEvent(Event);            { Ereignisse an Buttons weitergeben. }
     ColBox.HandleEvent(Event);
     Liste^.HandleEvent(Event);
     if (Event.KeyCode = $1414) and (MouseFlag = 0) then begin  { Ctrl-T }
       MouseFlag := 1;
       Dispose(Mouse, Done);              { Tastatur-Maus installieren }
       Mouse := New(HKMouse, Init);
       if (Mouse = nil) then begin
         WriteLn('Fehler: Zu wenig Heap-Speicher fÅr die Maus!');
         Halt;
       end;
       Mouse^.StdCursor := @c3;      { Standartmauszeiger: Kreuz }
       Mouse^.SetCursor(c3);         { Standartzeiger setzen. }
       Mouse^.Show;
     end;
     if (Event.KeyCode = $320D) and (MouseFlag = 1) then begin  { Ctrl-M }
       MouseFlag := 0;
       Dispose(Mouse, Done);              { Maus benutzen }
       Mouse := New(HMouse, Init);
       if (Mouse = nil) then begin
         WriteLn('Fehler: Zu wenig Heap-Speicher fÅr die Maus!');
         Halt;
       end;
       Mouse^.StdCursor := @c3;      { Standartmauszeiger: Kreuz }
       Mouse^.SetCursor(c3);         { Standartzeiger setzen. }
       Mouse^.Show;
     end;
     if (j <> ColBox.MyColor) then begin
       Mouse^.Hide;
       j := ColBox.MyColor;
       if (Liste^.Select = 0)
        then HGColor := j
        else Colors[Liste^.Select] := j;
       ShowBox.Clear(ColBox.MyColor);
       ShowBox.Show(20,300);
       Mouse^.Show;
     end;
     if (Event.MButton = 1) then begin      { Der Anwender wÑhlt eine neue Figur: }
       if (Event.Mouse.Y > 99) and (Event.Mouse.Y < 141) then begin
         Case Event.Mouse.X of
           15..50 : i := 1;
           55..90 : i := 2;
           95..130: i := 3;
         end;
         ShowRect(i);                       { Neue Figur mit Rahmen versehen. }
       repeat GetEvent(Event); until (Event.MButton = 0);   { warten, bis die Maus taste losgelassen wurde. }
     end; end;
   until (Event.Command = cm_Ok) or (Event.KeyCode = kb_Enter);
   Dispose(BFigure, Done); OButton.Done;     { Alles wieder freigeben }
   Dispose(Liste, Done);
   ShowBox.Done;
   ColBox.Done;
   LoadFigure(DateiPfad+Names[i]+'.BMP');  { Neue Figur laden. }
   Mouse^.Hide;
   Mouse^.SetCursor(Mouse^.StdCursor^);
   Screen.FillScreen(HGColor);
   DrawMask;
 end;
{ ************************************************************************** }
{                     NÑchstes Level laden:                                  }
{ ************************************************************************** }
 procedure LoadNextLevel;
 begin
   inc(Level);
   LoadFields(DateiPfad+'LEVEL'+chr((Level div 10)+48)+chr((Level mod 10)+48)+'.DAT');
   DrawMask;
 end;
{ ************************************************************************** }
{                      Variablen des Haupt-Programmes:                       }
{ ************************************************************************** }
var
  Event  : LEvent;
  QButton: LButton;
  DButton: LButton;
  SButton: LButton;
  R      : LRect;
  i,j    : Byte;
  Saver  : LPoint;
  Score  : LongInt;     { Anzahl Punkte }
  BufStr : String[15];
  UserName: String[15]; { Der Name des Benutzers. }
  HighScore:LHighScore;

{ ************************************************************************** }
 procedure DrawMask;
 var
   FColor: Byte;
 begin
   Mouse^.Hide;
   Screen.FillScreen(HGColor);          { Bildschirm lîschen   }
   DrawBrett;                           { Brett neu zeichnen   }
   QButton.ReDraw; DButton.ReDraw;      { Buttons neu zeichnen }
   SButton.ReDraw;
   Case HGColor of                      { Auf dunklem Grund auf }
     $10..$17: FColor := $1F;           { die weisse, anstatt der }
     $00     : FColor := $1F;           { schwarzen Schriftfarbe }
     $B0..$FF: FColor := $1F;           { wechseln }
   else
     FColor := $10;
   end;
   BCanvas.Clear(0);                    { Anzahl Punkte neu darstellen. }
   ShowTextXY(@BCanvas,1,1,FColor,HGColor,'Punkte:');
   Str(Score, BufStr);
   ShowTextXY(@BCanvas,1,20,FColor,HGColor,BufStr);
   ShowTextXY(@BCanvas,1,40,FColor,HGColor,'Level:');
   Str(Level, BufStr);                  { Level-Nummer neu darstellen. }
   ShowTextXY(@BCanvas,1,60,FColor,HGColor,BufStr);
   BCanvas.Show(500,20); BCanvas.Clear(0);
   Mouse^.Show;
 end;
{ ************************************************************************** }

{ ************************************************************************** }
{                          Hauptprogramm                                     }
{ ************************************************************************** }
var
  FColor: Byte;
begin
  if GetMaxMem < 2048 then begin        { Das Programm benîtigt Mindestspeicher! }
    WriteLn('FÅr dieses Programm werden mindestens 84 Kilobytes freier Speicher benîtigt.');
    WriteLn('Leider kann das Programm nicht ausgefÅhrt werden, da nicht genÅgend Speicher');
    WriteLn('zur VerfÅgung steht.');
  end;

  { *** Initialisierungen und Titelbild: *** }
  Score := 0;                   { Am Anfang noch keine Punkte }
  Screen.InitStd;
  Screen.FillScreen(HGColor);   { Bildschirm in Graphikmodus schalten }
  BFigure := LoadBMP(DateiPfad+'TITLE.BMP');
  if (BFigure = nil) then FileError(DateiPfad+'TITLE.BMP');
  BFigure^.Show(40,120);        { Das Titelbild anzeigen. }
  Dispose(BFigure, Done);
  UserName := '';               { Noch kein Benutzername }
  Mouse^.StdCursor := @c3;      { Standartmauszeiger: Kreuz }
  Mouse^.SetCursor(c3);         { Standartzeiger setzen. }
  BCanvas.Init(280,40,0);
  DrawTextXY(@BCanvas,1,1,16,0,'Programmiert von Tobias Kohn, 1998');
  DrawTextXY(@BCanvas,1,21,16,0,'Figuren von Benjamin Kohn');
  BCanvas.Show(50,400);
  BCanvas.Done;
  BCanvas.Init(80,150,0);
  BrettInit;  HalmaInit;        { Brett und Halma initialisieren }
  For i := 4 to 13 do Felder[i,i].State := fs_Mauer;
  For i := 4 to 12 do Felder[i+1,i].State := Felder[i+1,i].State + 4;
  WinCol[4] := 111; WinCol[6] := 64;
  WinCol[12] := 39; WinCol[7] := $18;
  WinCol[8] := $1B; WinCol[9] := $10;
  repeat                        { Aud tastendruck oder Maus warten }
    GetEvent(Event);
  until (Event.KeyCode > 0);
  LoadFigure(DateiPfad+'FIGUR.BMP');
  if (BFigure = nil) then FileError(DateiPfad+'FIGUR.BMP');
  BMauer  := LoadBMP(DateiPfad+'BLOCK.BMP');
  if (BMauer = nil) then FileError(DateiPfad+'BLOCK.BMP');
  Saver.x := 0; Saver.y := 0;
  SetRect(R,10,10,100,30);
  QButton.Init(nil, R, '&Beenden', cm_Quit);  { Beenden-Button initialisieren }
  SetRect(R,10,40,100,60);
  DButton.Init(nil, R, '&Drehen', cm_Turn);   { Dreh-Button initialisieren }
  SetRect(R,10,70,100,90);
  SButton.Init(nil, R, '&Optionen', cm_SelFig);{ Figur-WÑhl-Button initialisieren. }
  QButton.EventMask := $FF; DButton.EventMask := $FF;
  { *** Darstellen und AusfÅhren: *** }
  QButton.Show;                 { Buttons darstellen }
  DButton.Show;
  SButton.Show;
  DrawMask;                     { Den Bildschirm aufbauen. }
  Mouse^.Show;                  { Maus darstellen }
  repeat
    GetEvent(Event);
    Event.MVisible := True;     { Ereignisse lesen und Maus als aktiv markieren }
    QButton.HandleEvent(Event); DButton.HandleEvent(Event);   { Ereignisse weitergeben. }
    SButton.HandleEvent(Event);
    if (Event.KeyCode = $1414) and (MouseFlag = 0) then begin  { Ctrl-T }
      MouseFlag := 1;
      Dispose(Mouse, Done);              { Tastatur-Maus installieren }
      Mouse := New(HKMouse, Init);
      if (Mouse = nil) then begin
        WriteLn('Fehler: Zu wenig Heap-Speicher fÅr die Maus!');
        Halt;
      end;
      Mouse^.StdCursor := @c3;      { Standartmauszeiger: Kreuz }
      Mouse^.SetCursor(c3);         { Standartzeiger setzen. }
      Mouse^.Show;
    end;
    if (Event.KeyCode = $320D) and (MouseFlag = 1) then begin  { Ctrl-M }
      MouseFlag := 0;
      Dispose(Mouse, Done);              { Maus benutzen }
      Mouse := New(HMouse, Init);
      if (Mouse = nil) then begin
        WriteLn('Fehler: Zu wenig Heap-Speicher fÅr die Maus!');
        Halt;
      end;
      Mouse^.StdCursor := @c3;      { Standartmauszeiger: Kreuz }
      Mouse^.SetCursor(c3);         { Standartzeiger setzen. }
      Mouse^.Show;
    end;
    if Event.Command = cm_Quit then Break;      { Programm verlassen. }
    if Event.Command = cm_Turn then begin       { Drehen-Button wurde gewÑhlt. }
      Mouse^.Hide;
      Drehen;
      DrawMask;
      Saver.x := 0; saver.y := 0;               { Weiter beim nÑchsten Durchlauf }
      Mouse^.Show;
      Continue;
    end;
    if Event.Command = cm_SelFig                { Eine neue Figur auswÑhlen }
     then SelectFigure;
    if (Event.MButton = 1) then begin           { Maustaste gedrÅckt. }
      i := Round(Event.Mouse.Y - (0.7 * Event.Mouse.X) + 197) div 28 + 1;
      j := Round(Event.Mouse.Y + (0.7 * Event.Mouse.X) - 250) div 28 + 1;
      i := 17 - i;             { Brett-Koordinaten berechnet. }
      if (i > 0) and (i < 17) and (j > 0) and (j < 17) then   { Wenn auf dem Brett: }
       if Felder[i,j].Figur then begin              { Wenn Figur gewÑhlt,... }
         NotPoss;                                   { Mîglichkeiten prÅfen und markieren. }
         PossJump(i,j);
         PossPush(i,j);
         Saver.x := i; Saver.y := j;                { Figur als selektiert markieren. }
       end else if (Saver.x > 0) and (Felder[i,j].Select) then begin { Figur soll auf ein... }
         Mouse^.Hide;                                { ... anderes Feld bewegt werden. }
         Felder[i,j].Figur := True;
         Felder[Saver.x,Saver.y].Figur := False;
         if (Felder[Saver.x,Saver.y].State = fs_WegFall1)
          or (Felder[Saver.x,Saver.y].State = fs_WegFall2)
           then Felder[Saver.x,Saver.y].State := fs_Black;        { Wegfallendes Feld "lîschen" }
         Score := Score + Sqr(abs(i-Saver.x)+abs(j-Saver.y)-1);   { Punkte berechnen }
         Draw(i,j);                                { Alte Figur lîschen und an neuem Platz zeichnen. }
         Draw(Saver.x,Saver.y);
         Saver.x := i; Saver.y := j;               { Figur wiederum als selektiert markieren. }
         NotPoss;                                  { Mîglichkeiten markieren }
         PossJump(i,j);
         PossPush(i,j);
         Case HGColor of                      { Auf dunklem Grund auf   }
           $10..$17: FColor := $1F;           { die weisse, anstatt der }
           $00     : FColor := $1F;           { schwarzen Schriftfarbe  }
           $B0..$FF: FColor := $1F;           { wechseln                }
         else
           FColor := $10;
         end;
         Str(Score, BufStr);                  { Punkte auf dem Bildschirm anzeigen. }
         BCanvas.Clear(0);
         ShowTextXY(@BCanvas,1,1,FColor,HGColor,'Punkte: ');
         ShowTextXY(@BCanvas,1,20,FColor,HGColor,BufStr);
         BCanvas.Show(500,20);
         BCanvas.Clear(0);
         Mouse^.Show;
       end;
       if AllOnDest then begin                     { Alle Figuren sind im Ziel ! }
         if (UserName = '') then UserName := EditDialog('','Name:          ');   { Namen eingeben. }
         HighScore.Init(DateiPfad+'HIGHSCOR.DAT'); { HighScore erzeugen }
         HighScore.Load;                           { HighScore laden. }
         HighScore.Insert(Score, UserName);        { Benutzer hinzufÅgen }
         Mouse^.Hide;
         Screen.FillScreen(HGColor);
         Screen.OutPut(100,300,'Eine Taste drÅcken...');
         HighScore.Show(100,100);                  { HighScore darstellen. }
         repeat                                    { Auf Taste oder Maus warten. }
           GetEvent(Event);
         until (Event.MButton > 0) or (Event.KeyCode > 0);
         HighScore.Save;                           { HighScore speichern. }
         HighScore.Done;                           { Speicher wieder freigeben. }
         Mouse^.Show;
         LoadNextLevel;
       end;
    end;
  until Event.Command = cm_Quit;{ Bis Beenden-Ereigniss ausgelîst wurde. }
  BCanvas.Done;
  Dispose(BFigure, Done);
  Dispose(BMauer, Done);
  QButton.Done;                 { Buttons deaktivieren }
  DButton.Done;
  SButton.Done;
  Mouse^.Done;                  { Maus deaktivieren }
  Screen.Done;                  { Textmodus reaktivieren }
end.