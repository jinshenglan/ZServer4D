{
  Based on FPC FGL unit, copyright by FPC team.
  License of FPC RTL is the same as our engine (modified LGPL,
  see COPYING.txt for details).
  Fixed to compile also under FPC 2.4.0 and 2.2.4.
  Some small comfortable methods added.
}

{ Generic list of any type (TGenericStructList). }
unit FPCGenericStructlist;

{$IFDEF FPC}
{$mode objfpc}{$H+}

{$IF defined(VER2_2)} {$DEFINE OldSyntax} {$IFEND}
{$IF defined(VER2_4)} {$DEFINE OldSyntax} {$IFEND}

{$define HAS_ENUMERATOR}
{$ifdef VER2_2} {$undef HAS_ENUMERATOR} {$endif}
{$ifdef VER2_4_0} {$undef HAS_ENUMERATOR} {$endif}
{ Just undef enumerator always, in FPC 2.7.1 it's either broken
  or I shouldn't overuse TFPGListEnumeratorSpec. }
{$undef HAS_ENUMERATOR}

{ FPC < 2.6.0 had buggy version of the Extract function,
  also with different interface, see http://bugs.freepascal.org/view.php?id=19960. }
{$define HAS_EXTRACT}
{$ifdef VER2_2} {$undef HAS_EXTRACT} {$endif}
{$ifdef VER2_4} {$undef HAS_EXTRACT} {$endif}
{$ENDIF FPC}

interface

{$IFDEF FPC}

uses fgl, h264Types;

type
  { Generic list of types that are compared by CompareByte.

    This is equivalent to TFPGList, except it doesn't override IndexOf,
    so your type doesn't need to have a "=" operator built-in inside FPC.
    When calling IndexOf or Remove, it will simply compare values using
    CompareByte, this is what TFPSList.IndexOf uses.
    This way it works to create lists of records, vectors (constant size arrays),
    old-style TP objects, and also is suitable to create a list of methods
    (since for methods, the "=" is broken, for Delphi compatibility,
    see http://bugs.freepascal.org/view.php?id=9228).

    We also add some trivial helper methods like @link(Add) and @link(L). }
  generic TGenericStructList<t> = class(TFPSList)
  private
    type
      TCompareFunc = function(const Item1, Item2: t): int32_t;
      TTypeList = array[0..MaxGListSize] of t;
      PTypeList = ^TTypeList;
      pt = ^t;
  {$ifdef HAS_ENUMERATOR} TFPGListEnumeratorSpec = specialize TFPGListEnumerator<t>; {$endif}

  {$ifndef OldSyntax}protected var{$else}
      {$ifdef PASDOC}protected var{$else} { PasDoc can't handle "var protected", and I don't know how/if they should be handled? }
                     var protected{$endif}{$endif} FOnCompare: TCompareFunc;

    procedure CopyItem(Src, dest: Pointer); override;
    procedure Deref(Item: Pointer); override;
    function  Get(index: int32_t): t; {$ifdef CLASSESINLINE} inline; {$endif}
    function  GetList: PTypeList; {$ifdef CLASSESINLINE} inline; {$endif}
    function  ItemPtrCompare(Item1, Item2: Pointer): int32_t;
    procedure Put(index: int32_t; const Item: t); {$ifdef CLASSESINLINE} inline; {$endif}
  public
    constructor Create;
    function Add(const Item: t): int32_t; {$ifdef CLASSESINLINE} inline; {$endif}
    {$ifdef HAS_EXTRACT} function Extract(const Item: t): t; {$ifdef CLASSESINLINE} inline; {$endif} {$endif}
    function First: t; {$ifdef CLASSESINLINE} inline; {$endif}
    {$ifdef HAS_ENUMERATOR} function GetEnumerator: TFPGListEnumeratorSpec; {$ifdef CLASSESINLINE} inline; {$endif} {$endif}
    function IndexOf(const Item: t): int32_t;
    procedure Insert(index: int32_t; const Item: t); {$ifdef CLASSESINLINE} inline; {$endif}
    function Last: t; {$ifdef CLASSESINLINE} inline; {$endif}
{$ifndef OldSyntax}
    procedure Assign(Source: TGenericStructList);
{$endif OldSyntax}
    function Remove(const Item: t): int32_t; {$ifdef CLASSESINLINE} inline; {$endif}
    procedure Sort(Compare: TCompareFunc);
    property Items[index: int32_t]: t read Get write Put; default;
    property List: PTypeList read GetList;

    { Pointer to items. Exactly like @link(List), but this points to a single item,
      which means you can access particular item by @code(L[I]) instead of
      @code(List^[I]) in FPC objfpc mode.

      This is just trivial shortcut,  but we use direct access a @italic(lot)
      for structures. Reasonis: using Items[] default
      property means copying the structures, which is
      @orderedList(
        @item(very dangerous (you can trivially easy modify a temporary result))
        @item(slow (important for us, since these are used for vector arrays that
         are crucial for renderer and various processing).)
      ) }
    function L: pt;

    { Increase Count and return pointer to new item.
      Comfortable and efficient way to add a new item that you want to immediately
      initialize. }
    function Add: pt;
  end;

{$ENDIF FPC}

implementation

{$IFDEF FPC}
constructor TGenericStructList.Create;
begin
  inherited Create(SizeOf(t));
end;

procedure TGenericStructList.CopyItem(Src, dest: Pointer);
begin
  t(dest^) := t(Src^);
end;

procedure TGenericStructList.Deref(Item: Pointer);
begin
  Finalize(t(Item^));
end;

function TGenericStructList.Get(index: int32_t): t;
begin
  Result := t(inherited Get(index)^);
end;

function TGenericStructList.GetList: PTypeList;
begin
  Result := PTypeList(FList);
end;

function TGenericStructList.ItemPtrCompare(Item1, Item2: Pointer): int32_t;
begin
  Result := FOnCompare(t(Item1^), t(Item2^));
end;

procedure TGenericStructList.Put(index: int32_t; const Item: t);
begin
  inherited Put(index, @Item);
end;

function TGenericStructList.Add(const Item: t): int32_t;
begin
  Result := inherited Add(@Item);
end;

{$ifdef HAS_EXTRACT}
function TGenericStructList.Extract(const Item: t): t;
begin
  inherited Extract(@Item, @Result);
end;
{$endif}

function TGenericStructList.First: t;
begin
  Result := t(inherited First^);
end;

{$ifdef HAS_ENUMERATOR}
function TGenericStructList.GetEnumerator: TFPGListEnumeratorSpec;
begin
  Result := TFPGListEnumeratorSpec.Create(Self);
end;
{$endif}

function TGenericStructList.IndexOf(const Item: t): int32_t;
begin
  Result := inherited IndexOf(@Item);
end;

procedure TGenericStructList.Insert(index: int32_t; const Item: t);
begin
  t(inherited Insert(index)^) := Item;
end;

function TGenericStructList.Last: t;
begin
  Result := t(inherited Last^);
end;

{$ifndef OldSyntax}
procedure TGenericStructList.Assign(Source: TGenericStructList);
var
  i: int32_t;
begin
  Clear;
  for i := 0 to Source.Count - 1 do
    Add(Source[i]);
end;
{$endif OldSyntax}

function TGenericStructList.Remove(const Item: t): int32_t;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TGenericStructList.Sort(Compare: TCompareFunc);
begin
  FOnCompare := Compare;
  inherited Sort(@ItemPtrCompare);
end;

function TGenericStructList.L: pt;
begin
  Result := pt(FList);
end;

function TGenericStructList.Add: pt;
begin
  Count := Count + 1;
  Result := addr(L[Count - 1]);
end;

{$ENDIF FPC}

end.  
 
 
 
