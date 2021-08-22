{                                       }
{       (c) 1998 Tobias Kohn            }
{                                       }
UNIT GStdDlg;
{ ************************************************************************** }
{  Diese Unit stellt im 256-Farben-Graphik-Modus einige Standart-Dialog-     }
{ Fenster zur VerfÅgung. AbgestÅtzt sind sÑmtliche Objekte auf den Units     }
{ Graph2, GObjects, GEditors. Auch die Unit XMS wird von Graph2 aufgerufen,  }
{ muss also vorhanden sein.                                                  }
{  Die Prozeduren in dieser Unit sind nicht fÅr den alleinigen Gebrauch ge-  }
{ dacht, sondern als ErgÑnzung zu den obengenannten Units. Weitere Hinweise  }
{ sind in den anderen Units enthalten.                                       }
{ ************************************************************************** }
{$G+}          { 286-Code erzeugen }
INTERFACE
 USES GObjects, GEditors, Graph2;

   { ***************************************************************** }
   {  EditDialog        Erzeugt ein Dialogfenster mit einem Editier-   }
   {                     feld und einem Label, sowie einem OK-Button.  }
   {                     Der RÅckgabewert ist die Eingabe.             }
   { ***************************************************************** }
   function EditDialog(ATitle, AFrage: String): String;

IMPLEMENTATION

   { ***************************************************************** }
   {  EditDialog        Erzeugt ein Dialogfenster mit einem Editier-   }
   {                     feld und einem Label, sowie einem OK-Button.  }
   {                     Der RÅckgabewert ist die Eingabe.             }
   { ***************************************************************** }
 function EditDialog(ATitle,AFrage: string): String;
 var
   AView  : HView;
   AEdit  : HEdit;
   ADialog: HDialog;
   R      : LRect;
   x1,x2,y: Word;
 begin
   y := (Screen.Y div 2) - 60;                  { Die Koordinaten berechnen, damit }
   x1 := (length(AFrage)+2) * 8;                { das Dialogfeld in der Mitte ist. }
   x2 := (Screen.X + x1) shr 1; x1 := (Screen.X - x1) shr 1;
   SetRect(R,x1-5,y,x2+5,y+105);                { Den Dialog erzeugen }
   ADialog := New(HDialog, Init(R, ATitle));
   SetRect(R,5,5,(x2-x1),25);                   { Das Frage-Label einfÅgen. }
   AView := New(HLabel, Init(ADialog, R, AFrage));
   ADialog^.Insert(AView);
   SetRect(R,5,30,(x2-x1),50);                  { Das Editierfeld... }
   AEdit := New(HEdit, Init(ADialog, R));
   HLabel(AView)^.FocusCtrl := AEdit;           { Das Label auf das Editierfeld ausrichten. }
   SetRect(R,15,55,(x2-x1-10),75);              { Den OK-Button einfÅgen. }
   AView := New(HButton, Init(ADialog, R, '&OK', cm_OK));
   AEdit^.OkButton := HButton(AView);           { Bei <Enter> OK auslîsen. }
   ADialog^.Insert(AEdit);                      { Editierfeld einfÅgen. }
   ADialog^.Insert(AView);
   ADialog^.Execute;                            { Den Dialog ausfÅhren. }
   EditDialog := AEdit^.Text;                   { Text als RÅckgabe. }
   Dispose(ADialog, Done);                      { Dialog vom Speicher entfernen. }
 end;
END.