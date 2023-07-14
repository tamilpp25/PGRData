--
local XUiGuildWarRankTab = XClass(nil, "XUiGuildWarRankTab")
local UiButtonState = CS.UiButtonState
local ComboBtnType = {
    BaseComboType = 1,
    ChildComboType = 2
}
function XUiGuildWarRankTab:Ctor(ui, rootUi, index, tabData)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Button = self.GameObject:GetComponent("XUiButton")
    self.TabData = tabData
    if self.TabData.TabType ~= "BtnFirstHasSnd" then
        self.BtnType = ComboBtnType.ChildComboType
        self.Button:ShowTag(true)
        self.Button:SetNameByGroup(0, self.TabData.Name)
    else
        self.BtnType = ComboBtnType.BaseComboType
        self.Button:SetNameByGroup(0, self.TabData.Name)
    end
    self.Index = index
    --[[
    if self.TabData.IsActive then
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    else
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end]]
end

function XUiGuildWarRankTab:OnClick()
    --if not self.TabData.IsActive then return end
    if self.BtnType == ComboBtnType.ChildComboType then
        self.RootUi:RefreshRanking(self.TabData.Params[1], self.TabData.Params[2], self.TabData.RankingTarget)
        self.RootUi:RefreshRankingName(self.TabData.Name)
    end
end
return XUiGuildWarRankTab