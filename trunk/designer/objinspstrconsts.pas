{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ObjInspStrConsts;

{$mode objfpc}{$H+}

interface

resourcestring
  //
  oisObjectInspector = 'Object Inspector';
  oisItemsSelected = ' items selected';
  
  oiscAdd = '&Add';
  oiscDelete = '&Delete';

  // component editors commands
  oisProperties='Properties';
  oisEvents='Events';

  //ListView items editor
  sccsLvEdtCaption        = 'ListView editor';
  sccsLvEdtGrpLCaption    = ' Items ';
  sccsLvEdtGrpRCaption    = ' Item property ';
  sccsLvEdtlabCaption     = 'Label';
  sccsLvEdtImgIndexCaption= 'Image index';
  sccsLvEdtBtnAdd         = 'New';
  sccsLvEdtBtnDel         = 'Delete';
  sccsLvEdtBtnAddSub      = 'Sub item';

  //Image editor strings
  sccsILEdtCaption = 'Image list editor';
  sccsILCmbImgSel  = ' Selected image ';
  sccsILCmbImgList = ' Images ';
  sccsILBtnAdd     = 'Add ...';
  sccsILBtnClear   = 'Clear';
  sccsILConfirme   = 'Confirme clear all images ?';

implementation

end.

