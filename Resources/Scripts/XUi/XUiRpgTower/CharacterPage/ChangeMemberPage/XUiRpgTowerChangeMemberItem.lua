-- 兵法蓝图养成界面更换成员列表项控件
local XUiRpgTowerChangeMemberItem = XClass(nil, "XUiRpgTowerChangeMemberItem")
local XUiRpgTowerCharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
function XUiRpgTowerChangeMemberItem:Ctor()
    
end

function XUiRpgTowerChangeMemberItem:Init(ui, list)
    XTool.InitUiObjectByUi(self, ui)
    self.List = list
    self:SetPanelSelect(false)
    self.CharacterItem = XUiRpgTowerCharaItem.New(ui,
        XDataCenter.RpgTowerManager.CharaItemShowType.Normal)
end
--================
--刷新角色数据
--================
function XUiRpgTowerChangeMemberItem:RefreshData(rCharacter, gridIndex)
    self.CharacterItem:RefreshData(rCharacter)
    self.RChara = rCharacter
    self.GridIndex = gridIndex
end
--================
--点击事件
--================
function XUiRpgTowerChangeMemberItem:OnClick()
    if self.IsSelect then return end
    self:SetSelect(true)
    local updateModelCb = function(model)
        self.List.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.ADAPT)
    end
    self.List.RootUi:OnCharaSelect(self.RChara, updateModelCb)
end
--================
--选中
--================
function XUiRpgTowerChangeMemberItem:SetSelect(isSelect)
    self.IsSelect = isSelect
    self:SetPanelSelect(isSelect)
    self.List:SetSelect(self)
end
--================
--设置UI选中状态
--================
function XUiRpgTowerChangeMemberItem:SetPanelSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.ImgInTeam.gameObject:SetActiveEx(isSelect)
end

return XUiRpgTowerChangeMemberItem