-- 兵法蓝图出战换人界面角色列表项控件
local XUiRpgTowerRoomCharaListItem = XClass(nil, "XUiRpgTowerRoomCharaListItem")
local XUiRpgTowerCharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
function XUiRpgTowerRoomCharaListItem:Ctor()
    
end

function XUiRpgTowerRoomCharaListItem:Init(ui, list)
    XTool.InitUiObjectByUi(self, ui)
    self.List = list
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.CharacterItem = XUiRpgTowerCharaItem.New(ui,
        XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar)
end
--================
--刷新数据
--================
function XUiRpgTowerRoomCharaListItem:RefreshData(rCharacter, gridIndex)
    self.CharacterItem:RefreshData(rCharacter)
    self.RChara = rCharacter
    self.GridIndex = gridIndex
    self.TxtFight.text = self.RChara:GetAbility()
    self.ImgInTeam.gameObject:SetActiveEx(self.RChara:GetIsInTeam())
    self:RefreshElements()
end
--================
--刷新元素图标
--================
function XUiRpgTowerRoomCharaListItem:RefreshElements()
    local elementList = self.RChara:GetElements()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActive(true)
            rImg:SetRawImage(elementList[i].Icon)
        elseif rImg then
            rImg.transform.gameObject:SetActive(false)
        end
    end
end
--================
--点击事件
--================
function XUiRpgTowerRoomCharaListItem:OnClick()
    if self.IsSelect then return end
    self:SetSelect(true)
end
--================
--选中事件
--================
function XUiRpgTowerRoomCharaListItem:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    if isSelect then self.List:SetSelect(self) end
end

return XUiRpgTowerRoomCharaListItem