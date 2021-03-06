unit Main;

{$MODE Delphi}

{
  Disk Image Manager -  Main window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DiskMap, DskImage, Utils, About, Options, SectorProperties, Settings,
  Classes, Graphics, SysUtils, Forms, Dialogs, Menus, ComCtrls,
  ExtCtrls, Controls, Clipbrd, FileUtil, StrUtils, LazFileUtils;

type
  // Must match the imagelist, put sides last
  ItemType = (itDisk, itSpecification, itTracksAll, itTrack, itFiles, itSector,
    itAnalyse, itSides, itSide0, itSide1, itDiskCorrupt, itMessages);

  TListColumnArray = array of TListColumn;

  { TfrmMain }

  TfrmMain = class(TForm)
    mnuMain: TMainMenu;
    itmDisk: TMenuItem;
    itmOpen: TMenuItem;
    itmNew: TMenuItem;
    N1: TMenuItem;
    itmSaveCopyAs: TMenuItem;
    N2: TMenuItem;
    itmExit: TMenuItem;
    itmView: TMenuItem;
    itmHelp: TMenuItem;
    itmAbout: TMenuItem;
    dlgOpen: TOpenDialog;
    pnlLeft: TPanel;
    splVertical: TSplitter;
    staBar: TStatusBar;
    pnlRight: TPanel;
    pnlListLabel: TPanel;
    tvwMain: TTreeView;
    lvwMain: TListView;
    imlSmall: TImageList;
    pnlTreeLabel: TPanel;
    N4: TMenuItem;
    itmClose: TMenuItem;
    itmOptions: TMenuItem;
    DiskMap: TSpinDiskMap;
    itmCloseAll: TMenuItem;
    dlgSave: TSaveDialog;
    popDiskMap: TPopupMenu;
    itmSaveMapAs: TMenuItem;
    dlgSaveMap: TSaveDialog;
    itmDarkBlankSectorsPop: TMenuItem;
    itmStatusBar: TMenuItem;
    N3: TMenuItem;
    N5: TMenuItem;
    itmDarkUnusedSectors: TMenuItem;
    itmSave: TMenuItem;
    popSector: TPopupMenu;
    itmSectorResetFDC: TMenuItem;
    itmSectorBlankData: TMenuItem;
    itmSectorUnformat: TMenuItem;
    N6: TMenuItem;
    itmSectorProperties: TMenuItem;
    itmEdit: TMenuItem;
    itmEditCopy: TMenuItem;
    itmEditSelectAll: TMenuItem;
    popListItem: TPopupMenu;
    itmCopyDetailsClipboard: TMenuItem;
    N7: TMenuItem;
    itmFind: TMenuItem;
    itmFindNext: TMenuItem;
    dlgFind: TFindDialog;
    procedure itmOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tvwMainChange(Sender: TObject; Node: TTreeNode);
    procedure lvwMainDblClick(Sender: TObject);
    procedure itmAboutClick(Sender: TObject);
    procedure itmCloseClick(Sender: TObject);
    procedure itmExitClick(Sender: TObject);
    procedure itmOptionsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure itmCloseAllClick(Sender: TObject);
    procedure itmSaveCopyAsClick(Sender: TObject);
    procedure itmSaveMapAsClick(Sender: TObject);
    procedure itmDarkBlankSectorsPopClick(Sender: TObject);
    procedure popDiskMapPopup(Sender: TObject);
    procedure itmNewClick(Sender: TObject);
    procedure itmDarkUnusedSectorsClick(Sender: TObject);
    procedure itmStatusBarClick(Sender: TObject);
    procedure itmSaveClick(Sender: TObject);
    procedure itmSectorResetFDCClick(Sender: TObject);
    procedure itmSectorBlankDataClick(Sender: TObject);
    procedure itmSectorUnformatClick(Sender: TObject);
    procedure itmSectorPropertiesClick(Sender: TObject);
    procedure itmEditCopyClick(Sender: TObject);
    procedure itmEditSelectAllClick(Sender: TObject);
    procedure itmFindClick(Sender: TObject);
    procedure dlgFindFind(Sender: TObject);
    procedure itmFindNextClick(Sender: TObject);
    procedure tvwMainDblClick(Sender: TObject);
  private
    NextNewFile: integer;
    function AddTree(Parent: TTreeNode; Text: string; ImageIdx: integer;
      NodeObject: TObject): TTreeNode;
    function AddListInfo(Key: string; Value: string): TListItem;
    function AddListTrack(Track: TDSKTrack; HideSide: boolean): TListItem;
    function AddListSector(Sector: TDSKSector): TListItem;
    function AddListSides(Side: TDSKSide): TListItem;
    procedure SetListSimple;
    function GetSelectedSector(Sender: TObject): TDSKSector;
    function GetTitle(Data: TTreeNode): string;
    function GetCurrentImage: TDSKImage;
    function IsDiskNode(Node: TTreeNode): boolean;
    function AddColumn(Caption: string): TListColumn;
    function AddColumns(Captions: array of string): TListColumnArray;
  public
    Settings: TSettings;

    procedure AddWorkspaceImage(Image: TDSKImage);
    function CloseAll(AllowCancel: boolean): boolean;
    function ConfirmChange(Action: string; Upon: string): boolean;

    procedure SaveImage(Image: TDSKImage);
    procedure SaveImageAs(Image: TDSKImage; Copy: boolean);

    procedure AnalyseMap(Side: TDSKSide);
    procedure RefreshList;
    procedure RefreshListFiles(FileSystem: TDSKFileSystem);
    procedure RefreshListImage(Image: TDSKImage);
    procedure RefreshListMessages(Messages: TStringList);
    procedure RefreshListTrack(OptionalSide: TObject);
    procedure RefreshListSector(Track: TDSKTrack);
    procedure RefreshListSectorData(Sector: TDSKSector);
    procedure RefreshListSpecification(Specification: TDSKSpecification);
    procedure UpdateMenus;

    procedure SelectTree(Parent: TTreeNodes; Item: TObject);
    procedure SelectTreeChild(Parent: TTreeNode; Item: TObject);
    function LoadImage(FileName: TFileName): boolean;
    procedure CloseImage(Image: TDSKImage);
    function GetNextNewFile: integer;
  end;

const
  TAB = #9;
  CR = #13;
  LF = #10;
  CRLF = CR + LF;

var
  frmMain: TfrmMain;

function GetListViewAsText(ForListView: TListView): string;

implementation

{$R *.lfm}

uses New;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Idx: integer;
  FileName: string;
begin
  Settings := TSettings.Create(self);
  Settings.Load;

  NextNewFile := 0;
  Caption := Application.Title;
  itmAbout.Caption := 'About ' + Application.Title;
  itmDarkUnusedSectors.Checked := DiskMap.DarkBlankSectors;

  for Idx := 1 to ParamCount do
  begin
    FileName := ParamStr(Idx);
    if (ExtractFileExt(FileName) = '.dsk') and (FileExistsUTF8(FileName)) then
      LoadImage(FileName);
  end;
end;

procedure TfrmMain.itmOpenClick(Sender: TObject);
var
  Idx: integer;
begin
  if dlgOpen.Execute then
    for Idx := 0 to dlgOpen.Files.Count - 1 do
      LoadImage(dlgOpen.Files[Idx]);
end;

function TfrmMain.LoadImage(FileName: TFileName): boolean;
var
  NewImage: TDSKImage;
begin
  NewImage := TDSKImage.Create;
  if NewImage.LoadFile(FileName) then
  begin
    AddWorkspaceImage(NewImage);
    Result := true;
  end
  else
  begin
    NewImage.Free;
    Result := false;
  end;
end;

procedure TfrmMain.AddWorkspaceImage(Image: TDSKImage);
var
  SIdx, TIdx, EIdx: integer;
  ImageNode, SideNode, TrackNode, TracksNode: TTreeNode;
begin
  tvwMain.Items.BeginUpdate;

  if Image.Corrupt then
    ImageNode := AddTree(nil, ExtractFileName(Image.FileName), Ord(itDiskCorrupt), Image)
  else
    ImageNode := AddTree(nil, ExtractFileName(Image.FileName), Ord(itDisk), Image);

  if Image.Disk.Sides > 0 then
  begin
    // Optional specification
    if Image.Disk.Specification.Read <> dsFormatInvalid then
      AddTree(ImageNode, 'Specification', Ord(itSpecification),
        Image.Disk.Specification);
    // Add the sides
    for SIdx := 0 to Image.Disk.Sides - 1 do
    begin
      SideNode := AddTree(ImageNode, Format('Side %d', [SIdx + 1]),
        Ord(itSide0) + SIdx, Image.Disk.Side[SIdx]);
      AddTree(SideNode, 'Map', Ord(itAnalyse), Image.Disk.Side[SIdx]);
      // Add the tracks
      TracksNode := AddTree(SideNode, 'Tracks', Ord(itTracksAll), Image.Disk.Side[SIdx]);
      with Image.Disk.Side[SIdx] do
        for TIdx := 0 to Tracks - 1 do
        begin
          TrackNode := AddTree(TracksNode, Format('Track %d', [TIdx]),
            Ord(itTrack), Track[TIdx]);
          // Add the sectors
          with Image.Disk.Side[SIdx].Track[TIdx] do
            for EIdx := 0 to Sectors - 1 do
              AddTree(TrackNode, SysUtils.Format('Sector %d', [EIdx]),
                Ord(itSector), Sector[EIdx]);
        end;
    end;
    //FileNode := AddTree(ImageNode,'Files',Ord(itFiles),Image.Disk.FileSystem);
    if Image.Messages.Count > 0 then
      AddTree(ImageNode, 'Messages', Ord(itMessages), Image.Messages);
  end;
  tvwMain.Items.EndUpdate;

  ImageNode.Expanded := True;
  if (Image.Disk.Sides = 1) then
    SideNode.Expanded := True;

  tvwMain.Selected := imageNode;
end;

function TfrmMain.AddTree(Parent: TTreeNode; Text: string; ImageIdx: integer;
  NodeObject: TObject): TTreeNode;
var
  NewTreeNode: TTreeNode;
begin
  NewTreeNode := tvwMain.Items.AddChild(Parent, Text);
  with NewTreeNode do
  begin
    ImageIndex := ImageIdx;
    SelectedIndex := ImageIdx;
    Data := NodeObject;
  end;
  Result := NewTreeNode;
end;

procedure TfrmMain.tvwMainChange(Sender: TObject; Node: TTreeNode);
begin
  UpdateMenus;
end;

procedure TfrmMain.UpdateMenus;
var
  AllowImageFile: boolean;
begin
  AllowImageFile := false;
  tvwMain.PopupMenu := nil;

  // Decide what class operating on
  if (tvwMain.Selected <> nil) and (tvwMain.Selected.Data <> nil) then
  begin
    AllowImageFile := true;
    if (TObject(tvwMain.Selected.Data).ClassType = TDSKSector) or
      (TObject(tvwMain.Selected.Data).ClassType = TDSKTrack) then
      tvwMain.PopupMenu := popSector;
  end;

  // Set main menu options
  itmClose.Enabled := AllowImageFile;
  itmSave.Enabled := AllowImageFile;
  itmSaveCopyAs.Enabled := AllowImageFile;

  // Hide disk map if no longer selected
  if (lvwMain.Selected = nil) and (DiskMap.Visible) then
  begin
     DiskMap.Visible := false;
     lvwMain.Visible := true;
  end;

  RefreshList;
end;

function TfrmMain.GetTitle(Data: TTreeNode): string;
var
  CurNode: TTreeNode;
begin
  Result := '';
  CurNode := Data;
  while CurNode <> nil do
  begin
    if (CurNode.ImageIndex <> 2) or (CurNode = tvwMain.Selected) then
      Result := CurNode.Text + ' > ' + Result;
    CurNode := CurNode.Parent;
  end;
  Result := Copy(Result, 0, Length(Result) - 3);
end;

procedure TfrmMain.RefreshList;
var
  OldViewStyle: TViewStyle;
begin
  with lvwMain do
  begin
    PopupMenu := nil;
    OldViewStyle := ViewStyle;
    Items.BeginUpdate;
    ViewStyle := vsList;
    Items.Clear;
    Columns.BeginUpdate;
    Columns.Clear;

    ParentFont := True;
    ShowColumnHeaders := True;

    if tvwMain.Selected <> nil then
      with tvwMain.Selected do
      begin
        pnlListLabel.Caption := AnsiReplaceStr(GetTitle(tvwMain.Selected), '&', '&&');
        lvwMain.Visible := not (ItemType(ImageIndex) = itAnalyse);
        DiskMap.Visible := not lvwMain.Visible;
        if Data <> nil then
        begin
          case ItemType(ImageIndex) of
            itDisk: RefreshListImage(Data);
            itDiskCorrupt: RefreshListImage(Data);
            itSpecification: RefreshListSpecification(Data);
            itTracksAll: RefreshListTrack(Data);
            itTrack: RefreshListSector(Data);
            itAnalyse: AnalyseMap(Data);
            itFiles: RefreshListFiles(Data);
            itMessages: RefreshListMessages(Data);
            else
              if TObject(Data).ClassType = TDSKSide then
                RefreshListTrack(TDSKSide(Data));
              if TObject(Data).ClassType = TDSKSector then
                RefreshListSectorData(TDSKSector(Data));
          end;
        end;
      end
    else
      pnlListLabel.Caption := '';
    ViewStyle := OldViewStyle;
    Columns.EndUpdate;
    Items.EndUpdate;
  end;
end;

procedure TfrmMain.RefreshListMessages(Messages: TStringList);
var
  Idx: integer;
begin
  SetListSimple;
  if Messages <> nil then
    for Idx := 0 to Messages.Count - 1 do
      AddListInfo('', Messages[Idx]);
end;

procedure TfrmMain.RefreshListImage(Image: TDSKImage);
var
  SIdx: integer;
  Protection: string;
begin
  SetListSimple;
  if Image <> nil then
    with Image do
    begin
      AddListInfo('Creator', Creator);
      if Corrupt then
        AddListInfo('Format', DSKImageFormats[FileFormat] + ' (Corrupt)')
      else
        AddListInfo('Format', DSKImageFormats[FileFormat]);
      AddListInfo('Sides', StrInt(Disk.Sides));
      if Disk.Sides > 0 then
      begin
        if Disk.Sides > 1 then
        begin
          for SIdx := 0 to Disk.Sides - 1 do
            AddListInfo(SysUtils.Format('Tracks on side %d', [SIdx]), StrInt(Disk.Side[SIdx].Tracks));
        end;
        AddListInfo('Tracks total', StrInt(Disk.TrackTotal));
        AddListInfo('Formatted capacity', SysUtils.Format('%d KB',
          [Disk.FormattedCapacity div BytesPerKB]));
        if Disk.IsTrackSizeUniform then
          AddListInfo('Track size', SysUtils.Format(
            '%d bytes', [Disk.Side[0].Track[0].Size]))
        else
          AddListInfo('Largest track size', SysUtils.Format(
            '%d bytes', [Disk.Side[0].GetLargestTrackSize()]));
        if Disk.IsUniform(False) then
          AddListInfo('Uniform layout', 'Yes')
        else
        if Disk.IsUniform(True) then
          AddListInfo('Uniform layout', 'Yes (except empty tracks)')
        else
          AddListInfo('Uniform layout', 'No');
        AddListInfo('Format analysis', Disk.DetectFormat);
        Protection := Disk.DetectCopyProtection();
        if Protection <> '' then
          AddListInfo('Copy protection', Protection);
        if Disk.BootableOn <> '' then
          AddListInfo('Boot sector', Disk.BootableOn);
        if disk.HasFDCErrors then
          AddListInfo('FDC errors', 'Yes')
        else
          AddListInfo('FDC errors', 'No');
        if IsChanged then
          AddListInfo('Is changed', 'Yes')
        else
        begin
          AddListInfo('Is changed', 'No');
          AddListInfo('File size', SysUtils.Format('%d bytes', [FileSize]));
        end;
      end;
    end;
end;

procedure TfrmMain.SetListSimple;
begin
  lvwMain.ShowColumnHeaders := false;
  with lvwMain.Columns do
  begin
    Clear;
    with Add do
    begin
      Caption := 'Key';
      AutoSize := true;
    end;
    with Add do
    begin
      Caption := 'Value';
      AutoSize := true;
    end;
  end;
end;

procedure TfrmMain.RefreshListSpecification(Specification: TDSKSpecification);
begin
  SetListSimple;
  Specification.Read;
  AddListInfo('Format', DSKSpecFormats[Specification.Format]);
  if Specification.Format <> dsFormatInvalid then
  begin
    AddListInfo('Sided', DSKSpecSides[Specification.Side]);
    AddListInfo('Track mode', DSKSpecTracks[Specification.Track]);
    AddListInfo('Tracks/side', StrInt(Specification.TracksPerSide));
    AddListInfo('Sectors/track', StrInt(Specification.SectorsPerTrack));
    AddListInfo('Directory blocks', StrInt(Specification.DirectoryBlocks));
    AddListInfo('Reserved tracks', StrInt(Specification.ReservedTracks));
    AddListInfo('Gap (format)', StrInt(Specification.GapFormat));
    AddListInfo('Gap (read/write)', StrInt(Specification.GapReadWrite));
    AddListInfo('Sector size', StrInt(Specification.SectorSize));
    AddListInfo('Block size', StrInt(Specification.BlockSize));
  end;
end;

function TfrmMain.AddListInfo(Key: string; Value: string): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := Key;
    SubItems.Add(Value);
  end;
  Result := NewListItem;
end;

procedure TfrmMain.RefreshListTrack(OptionalSide: TObject);
var
  SIdx, TIdx: integer;
  HideSide: boolean;
  DSK: TDSKImage;
  Side: TDSKSide;
begin
  HideSide := (OptionalSide.ClassType = TDSKSide);
  AddColumn('Logical');
  AddColumn('Physical');
  if not HideSide then
    AddColumn('Side');
  AddColumn('Track size');
  AddColumn('Sectors');
  AddColumn('Sector size');
  AddColumn('Gap');
  AddColumn('Filler');
  AddColumn('Interleave');
  AddColumn('');

  if HideSide then
  begin
    Side := TDSKSide(OptionalSide);
    for TIdx := 0 to Side.Tracks - 1 do
      AddListTrack(Side.Track[TIdx], HideSide);
  end
  else
  begin
    DSK := TDSKImage(OptionalSide);
    for TIdx := 0 to DSK.Disk.Side[0].Tracks - 1 do
      for SIdx := 0 to DSK.Disk.Sides - 1 do
        AddListTrack(DSK.Disk.Side[SIdx].Track[TIdx], HideSide);
  end;
end;

function TfrmMain.AddListTrack(Track: TDSKTrack; HideSide: boolean): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Track.Logical);
    Data := Track;
    Subitems.Add(StrInt(Track.Track));
    if not HideSide then
      Subitems.Add(StrInt(Track.Side));
    Subitems.Add(StrInt(Track.Size));
    Subitems.Add(StrInt(Track.Sectors));
    Subitems.Add(StrInt(Track.SectorSize));
    Subitems.Add(StrInt(Track.GapLength));
    Subitems.Add(StrHex(Track.Filler));
  end;
  Result := NewListItem;
end;

function TfrmMain.AddListSides(Side: TDSKSide): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Side.Side + 1);
    SubItems.Add(StrInt(Side.Tracks));
    Data := Side;
  end;
  Result := NewListItem;
end;

procedure TfrmMain.lvwMainDblClick(Sender: TObject);
begin
  if (tvwMain.Selected <> nil) and (lvwMain.Selected <> nil) then
    SelectTree(tvwMain.Items, lvwMain.Selected.Data);
end;

procedure TfrmMain.SelectTree(Parent: TTreeNodes; Item: TObject);
var
  Idx: integer;
begin
  for Idx := 0 to Parent.Count - 1 do
  begin
    if Parent.Item[Idx].Data = Item then
      tvwMain.Selected := Parent.Item[Idx]
    else
      SelectTreeChild(Parent.Item[Idx], Item);
  end;
end;

procedure TfrmMain.SelectTreeChild(Parent: TTreeNode; Item: TObject);
var
  Idx: integer;
begin
  for Idx := 0 to Parent.Count - 1 do
  begin
    if Parent.Items[Idx].Data = Item then
      tvwMain.Selected := Parent.Items[Idx]
    else
      SelectTreeChild(Parent.Items[Idx], Item);
  end;
end;

procedure TfrmMain.RefreshListSector(Track: TDSKTrack);
var
  Idx: integer;
begin
  lvwMain.PopupMenu := popSector;

  AddColumns(['Sector', 'Track', 'Side', 'ID', 'FDC size', 'FDC flags', 'Data size']);
  with lvwMain.Columns.Add do
  begin
    Caption := 'Status';
    AutoSize := True;
  end;
  AddColumn('');

  for Idx := 0 to Track.Sectors - 1 do
    AddListSector(Track.Sector[Idx]);
end;

function TfrmMain.AddListSector(Sector: TDSKSector): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Sector.Sector);
    Data := Sector;
    SubItems.Add(StrInt(Sector.Track));
    SubItems.Add(StrInt(Sector.Side));
    SubItems.Add(StrInt(Sector.ID));
    SubItems.Add(StrInt(Sector.FDCSize));
    SubItems.Add(Format('%d, %d', [Sector.FDCStatus[1], Sector.FDCStatus[2]]));
    if (Sector.DataSize <> Sector.AdvertisedSize) then
      SubItems.Add(Format('%d (%d)', [Sector.DataSize, Sector.AdvertisedSize]))
    else
      SubItems.Add(StrInt(Sector.DataSize));
    SubItems.Add(DSKSectorStatus[Sector.Status]);
  end;
  Result := NewListItem;
end;

procedure TfrmMain.RefreshListSectorData(Sector: TDSKSector);
var
  Idx: integer;
  SecData, SecHex: string;
begin
  SecData := '';
  SecHex := '';
  lvwMain.Font := Settings.SectorFont;

  with lvwMain.Columns do
  begin
    Clear;
    BeginUpdate;
    with Add do
    begin
      Caption := 'Off';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Hex';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'ASCII';
      AutoSize := True;
    end;
  end;

  for Idx := 0 to Sector.DataSize do
  begin
    if (Idx mod Settings.BytesPerLine = 0) and (Idx > 0) then
    begin
      with lvwMain.Items.Add do
      begin
        Caption := StrInt(Idx - Settings.BytesPerLine);
        Subitems.Add(SecHex);
        Subitems.Add(SecData);
      end;
      SecData := '';
      SecHex := '';
    end;

    if Idx < Sector.DataSize then
    begin
      if Sector.Data[Idx] > 31 then
        SecData := SecData + char(Sector.Data[Idx])
      else
        SecData := SecData + Settings.UnknownASCII;
      SecHex := SecHex + StrHex(Sector.Data[Idx]) + ' ';
    end;
  end;
end;

// Menu: Help > About
procedure TfrmMain.itmAboutClick(Sender: TObject);
begin
  frmAbout := TfrmAbout.Create(Self);
  frmAbout.ShowModal;
  frmAbout.Free;
end;

// Find a disk image and remove it from the tree
procedure TfrmMain.CloseImage(Image: TDSKImage);
var
  Idx: integer;
  Previous: TTreeNode;
begin
  Previous := nil;
  for Idx := 0 to tvwMain.Items.Count - 1 do
  begin
    if IsDiskNode(tvwMain.Items[Idx]) then
    begin
      if tvwMain.Items[Idx].Data = Image then
      begin
        TDSKImage(tvwMain.Items[Idx].Data).Free;
        tvwMain.Items[Idx].Delete;
        RefreshList;
        if (tvwMain.Selected = nil) and (Previous <> nil) then
           Previous.Selected := true;
        exit;
      end;
      Previous := tvwMain.Items[Idx];
    end;
  end;
end;

// Get the current image
function TfrmMain.GetCurrentImage: TDSKImage;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := tvwMain.Selected;
  if (Node = nil) then
    exit;

  while (TObject(Node.Data).ClassType <> TDskImage) do
    Node := Node.Parent;

  Result := TDskImage(Node.Data);
end;

procedure TfrmMain.itmCloseClick(Sender: TObject);
begin
  if (tvwMain.Selected <> nil) then
    CloseImage(GetCurrentImage);
end;

procedure TfrmMain.itmExitClick(Sender: TObject);
begin
  Close;
end;

// Show the disk map
procedure TfrmMain.AnalyseMap(Side: TDSKSide);
begin
  lvwMain.Visible := False;
  DiskMap.Side := Side;
  DiskMap.Visible := True;
end;

// Load list with filenames
procedure TfrmMain.RefreshListFiles(FileSystem: TDSKFileSystem);
var
  Idx: integer;
  NewFile: TDSKFile;
begin
  with lvwMain.Columns do
  begin
    with Add do
    begin
      Caption := 'File name';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Size';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Type';
      AutoSize := True;
    end;
  end;

  for Idx := 0 to 10 do
  begin
    with lvwMain.Items.Add do
    begin
      NewFile := FileSystem.GetDiskFile(Idx);
      Caption := NewFile.FileName;
      Subitems.Add(StrInt(NewFile.Size));
      Subitems.Add(Newfile.FileType);
    end;
  end;
end;

// Menu: View > Options
procedure TfrmMain.itmOptionsClick(Sender: TObject);
begin
  TfrmOptions.Create(self, Settings).Show;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Settings.Save;
  if CloseAll(True) then
    Action := caFree
  else
    Action := caNone;
end;

procedure TfrmMain.itmCloseAllClick(Sender: TObject);
begin
  CloseAll(True);
end;

function TfrmMain.IsDiskNode(Node: TTreeNode): boolean;
begin
 Result := (node.ImageIndex = Ord(itDisk)) or
           (node.ImageIndex = Ord(itDiskCorrupt));
end;

function TfrmMain.CloseAll(AllowCancel: boolean): boolean;
var
  Image: TDSKImage;
  Buttons: TMsgDlgButtons;
begin
  Result := True;
  if AllowCancel then
    Buttons := [mbYes, mbNo, mbCancel]
  else
    Buttons := [mbYes, mbNo];

  while tvwMain.Items.GetFirstNode <> nil do
  begin
    if IsDiskNode(tvwMain.Items.GetFirstNode) then
    begin
      Image := TDSKImage(tvwMain.Items.GetFirstNode.Data);
      if Image.IsChanged and not Image.Corrupt then
        case MessageDlg(Format('Save unsaved image "%s" ?', [Image.FileName]),
            mtWarning, Buttons, 0) of
          mrYes: SaveImage(Image);
          mrCancel:
          begin
            Result := False;
            exit;
          end;
        end;
      Image.Free;
      tvwMain.Items.GetFirstNode.Delete;
    end;
  end;
  RefreshList;
  UpdateMenus;
end;

procedure TfrmMain.itmSaveCopyAsClick(Sender: TObject);
begin
  if tvwMain.Selected <> nil then
    SaveImageAs(GetCurrentImage, True);
end;

procedure TfrmMain.SaveImageAs(Image: TDSKImage; Copy: boolean);
begin
  dlgSave.FileName := Image.FileName;
  case Image.FileFormat of
    diStandardDSK: dlgSave.FilterIndex := 1;
    diExtendedDSK: dlgSave.FilterIndex := 2;
  end;

  if dlgSave.Execute then
    case dlgSave.FilterIndex of
      1:
      begin
        if (not Image.Disk.IsTrackSizeUniform) and Settings.WarnConversionProblems then
          if MessageDlg(
            'This image has variable track sizes that "Standard DSK format" does not support. ' +
            'Save anyway using largest track size?', mtWarning,
            [mbYes, mbNo], 0) = mrOk then
            Image.SaveFile(dlgSave.FileName, diStandardDSK, True, False)
          else
            exit
        else
          Image.SaveFile(dlgSave.FileName, diStandardDSK, Copy, False);
      end;
      2: Image.SaveFile(dlgSave.FileName, diExtendedDSK, Copy, Settings.RemoveEmptyTracks);
    end;
end;

procedure TfrmMain.itmSaveMapAsClick(Sender: TObject);
var
  DefaultFileName: string;
begin
  DefaultFileName := DiskMap.Side.ParentDisk.ParentImage.FileName;
  if DiskMap.Side.Side > 0 then
    DefaultFileName := DefaultFileName + ' Side ' + StrInt(DiskMap.Side.Side);
  dlgSaveMap.FileName := ExtractFileNameOnly(DefaultFileName);
  if dlgSaveMap.Execute then
    DiskMap.SaveMap(dlgSaveMap.FileName, Settings.SaveDiskMapWidth, Settings.SaveDiskMapHeight);
end;

procedure TfrmMain.itmDarkBlankSectorsPopClick(Sender: TObject);
begin
  DiskMap.DarkBlankSectors := not itmDarkBlankSectorsPop.Checked;
  itmDarkBlankSectorsPop.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.popDiskMapPopup(Sender: TObject);
begin
  itmDarkBlankSectorsPop.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.itmNewClick(Sender: TObject);
begin
  TfrmNew.Create(Self).Show;
end;

function TfrmMain.GetNextNewFile: integer;
begin
  NextNewFile := NextNewFile + 1;
  Result := NextNewFile;
end;

procedure TfrmMain.itmDarkUnusedSectorsClick(Sender: TObject);
begin
  DiskMap.DarkBlankSectors := not itmDarkUnusedSectors.Checked;
  itmDarkUnusedSectors.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.itmStatusBarClick(Sender: TObject);
begin
  staBar.Visible := not itmStatusBar.Checked;
  itmStatusBar.Checked := staBar.Visible;
end;

procedure TfrmMain.itmSaveClick(Sender: TObject);
begin
  if tvwMain.Selected <> nil then
    SaveImage(GetCurrentImage);
end;

procedure TfrmMain.SaveImage(Image: TDSKImage);
begin
  if Image.FileFormat = diNotYetSaved then
    SaveImageAs(Image, False)
  else
    Image.SaveFile(Image.FileName, Image.FileFormat, False,
      (Settings.RemoveEmptyTracks and (Image.FileFormat = diExtendedDSK)));
end;

procedure TfrmMain.itmSectorResetFDCClick(Sender: TObject);
var
  Track: TDSKTrack;
  TIdx: integer;
begin
  if tvwMain.Selected <> nil then
  begin
    if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
      if ConfirmChange('reset FDC flags for', 'track') then
      begin
        Track := TDSKTrack(tvwMain.Selected.Data);
        for TIdx := 0 to (Track.Sectors - 1) do
          Track.Sector[TIdx].ResetFDC;
      end;
    if (TObject(tvwMain.Selected.Data).ClassType = TDSKSector) then
      if ConfirmChange('reset FDC flags for', 'sector') then
        TDSKSector(tvwMain.Selected.Data).ResetFDC;
    UpdateMenus;
  end;
end;

function TfrmMain.GetSelectedSector(Sender: TObject): TDSKSector;
begin
  Result := nil;
  if (Sender = lvwMain) and (lvwMain.Selected <> nil) then
    Result := TDSKSector(lvwMain.Selected.Data);
end;

procedure TfrmMain.itmSectorBlankDataClick(Sender: TObject);
var
  Sector: TDSKSector;
begin
  Sector := GetSelectedSector(popSector.PopupComponent);
  if (Sector <> nil) and (ConfirmChange('format', 'sector')) then
  begin
    Sector.DataSize := Sector.ParentTrack.SectorSize;
    Sector.FillSector(Sector.ParentTrack.Filler);
    UpdateMenus;
  end;
end;

procedure TfrmMain.itmSectorUnformatClick(Sender: TObject);
begin
  if tvwMain.Selected <> nil then
  begin
    if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
      if ConfirmChange('unformat', 'track') then
      begin
        TDSKTrack(tvwMain.Selected.Data).Unformat;
        tvwMain.Selected.DeleteChildren;
      end;
    if TObject(tvwMain.Selected.Data).ClassType = TDSKSector then
      if ConfirmChange('unformat', 'sector') then
        TDSKSector(tvwMain.Selected.Data).Unformat;
    UpdateMenus;
  end;
end;

procedure TfrmMain.itmSectorPropertiesClick(Sender: TObject);
var
  Track: TDSKTrack;
  TIdx: integer;
begin
  if tvwMain.Selected <> nil then
  begin
    if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
    begin
      Track := TDSKTrack(tvwMain.Selected.Data);
      for TIdx := 0 to (Track.Sectors - 1) do
        TfrmSector.Create(Self, Track.Sector[TIdx]);
    end;
    if TObject(tvwMain.Selected.Data).ClassType = TDSKSector then
      TfrmSector.Create(Self, TDSKSector(tvwMain.Selected.Data));
    UpdateMenus;
  end;
end;

function TfrmMain.ConfirmChange(Action: string; Upon: string): boolean;
begin
  if not Settings.WarnSectorChange then
  begin
    Result := True;
    exit;
  end;
  Result := MessageDlg('You are about to ' + Action + ' this ' +
    Upon + ' ' + CR + CR + 'Do you know what you are doing?', mtWarning,
    [mbYes, mbNo], 0) = mrYes;
end;

function GetListViewAsText(ForListView: TListView): string;
var
  CIdx, RIdx: integer;
begin
  Result := '';
  // Headings
  for CIdx := 0 to ForListView.Columns.Count - 1 do
    Result := Result + ForListView.Columns[CIdx].Caption + TAB;
  Result := Result + CRLF;

  // Details
  for RIdx := 0 to ForListView.Items.Count - 1 do
    if ForListView.Items[RIdx].Selected then
    begin
      Result := Result + ForListView.Items[RIdx].Caption + TAB;
      for CIdx := 0 to ForListView.Items[RIdx].SubItems.Count - 1 do
        Result := Result + ForListView.Items[RIdx].SubItems[CIdx] + TAB;
      Result := Result + CRLF;
    end;
end;

procedure TfrmMain.itmEditCopyClick(Sender: TObject);
begin
  Clipboard.AsText := GetListViewAsText(lvwMain);
end;

procedure TfrmMain.itmEditSelectAllClick(Sender: TObject);
var
  i: integer;
begin
  lvwMain.Items.BeginUpdate;
  for i := 0 to lvwMain.Items.Count - 1 do
    lvwMain.Items[i].Selected := True;
  lvwMain.Items.EndUpdate;
end;

procedure TfrmMain.itmFindClick(Sender: TObject);
begin
  dlgFind.Execute;
end;

procedure TfrmMain.dlgFindFind(Sender: TObject);
var
  StartSector, FoundSector: TDSKSector;
  TreeIdx: integer;
  Obj: TObject;
begin
  if tvwMain.Selected.Data = nil then
    exit;

  // Find out where to start searching
  Obj := TObject(tvwMain.Selected.Data);
  StartSector := nil;
  if Obj.ClassType = TDSKImage then
    StartSector := TDSKImage(Obj).Disk.Side[0].Track[0].Sector[0];
  if Obj.ClassType = TDSKDisk then
    StartSector := TDSKDisk(Obj).Side[0].Track[0].Sector[0];
  if Obj.ClassType = TDSKSide then
    StartSector := TDSKSide(Obj).Track[0].Sector[0];
  if Obj.ClassType = TDSKTrack then
    StartSector := TDSKTrack(Obj).Sector[0];
  if Obj.ClassType = TDSKSector then
    StartSector := TDSKSector(Obj);

  if StartSector = nil then
    exit;

  FoundSector := StartSector.ParentTrack.ParentSide.ParentDisk.ParentImage.FindText(
    StartSector, dlgFind.FindText, frMatchCase in dlgFind.Options);

  if FoundSector <> nil then
  begin
    for TreeIdx := 0 to tvwMain.Items.Count - 1 do
      if tvwMain.Items[TreeIdx].Data = FoundSector then
        tvwMain.Selected := tvwMain.Items[TreeIdx];
  end;
end;

procedure TfrmMain.itmFindNextClick(Sender: TObject);
begin
  dlgFindFind(Sender);
end;

procedure TfrmMain.tvwMainDblClick(Sender: TObject);
begin
  itmSectorPropertiesClick(Sender);
end;

function TfrmMain.AddColumn(Caption: string): TListColumn;
begin
  Result := lvwMain.Columns.Add;
  Result.Caption := Caption;
  Result.Alignment := taRightJustify;
  Result.AutoSize := true;
end;

function TfrmMain.AddColumns(Captions: array of string): TListColumnArray;
var
  CIdx: integer;
begin
  SetLength(Result, Length(Captions));
  for CIdx := 0 to Length(Captions) - 1 do
    Result[CIdx] := AddColumn(Captions[CIdx]);
end;

end.
