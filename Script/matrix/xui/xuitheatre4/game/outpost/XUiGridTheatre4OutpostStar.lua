---@class XUiGridTheatre4OutpostStar : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4OutpostStar = XClass(XUiNode, "XUiGridTheatre4OutpostStar")

function XUiGridTheatre4OutpostStar:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

---@param starId number 星级Id
function XUiGridTheatre4OutpostStar:Refresh(starId)
    -- 图标
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.Theatre4BpExperience)
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 数量
    local count = self._Control:GetDifficultyStarRewardBpExp(starId)
    self.TxtNum.text = string.format("x%s", count)
    -- 星级条件数量
    self.TxtName.text = self._Control:GetDifficultyStarConditionCount(starId)
    -- 是否满足
    local isMeet = self._Control:CheckCurDifficultyStarIsMeet(starId)
    self.ImgAchievement01.gameObject:SetActiveEx(isMeet)
    self.ImgAchievement02.gameObject:SetActiveEx(not isMeet)
    if self.PanelNoClaim then
        self.PanelNoClaim.gameObject:SetActiveEx(not isMeet)
    end
end

function XUiGridTheatre4OutpostStar:OnBtnClick()
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", XDataCenter.ItemManager.ItemId.Theatre4BpExperience)
end

return XUiGridTheatre4OutpostStar