-- 兵法蓝图队伍列表控件
local XUiRpgTowerTeamListItem = XClass(nil, "XUiRpgTowerTeamListItem")
local XUiRpgTowerCharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
function XUiRpgTowerTeamListItem:Ctor()
    
end

function XUiRpgTowerTeamListItem:Init(ui, list)
    XTool.InitUiObjectByUi(self, ui)
    self.List = list
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.CharacterItem = XUiRpgTowerCharaItem.New(ui,
        XDataCenter.RpgTowerManager.CharaItemShowType.Normal)
end
--================
--刷新数据
--================
function XUiRpgTowerTeamListItem:RefreshData(rCharacter, gridIndex)
    self.CharacterItem:RefreshData(rCharacter)
    self.RChara = rCharacter
    self.GridIndex = gridIndex
    if self.Red then self.Red.gameObject:SetActiveEx(rCharacter:CheckCanActiveTalent()) end
end
--================
--点击事件
--================
function XUiRpgTowerTeamListItem:OnClick()
    if self.IsSelect then return end
    self:SetSelect(true)
end
--================
--选中事件
--================
function XUiRpgTowerTeamListItem:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.List:SetSelect(self)
end
return XUiRpgTowerTeamListItem