
local XUiSSBPickPanelNormalStage = XClass(nil, "XUiSSBPickPanelNormalStage")

function XUiSSBPickPanelNormalStage:Ctor(uiPrefab, mode, panelRefresh)
    self.Mode = mode
    self.PanelRefreshCb = panelRefresh
    self.IsOneOnOne = self.Mode:GetRoleBattleNum() == 1
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanel()
end

function XUiSSBPickPanelNormalStage:InitPanel()
    self.BtnLeft.CallBack = function() self:OnClickBtnLeft() end
    self.BtnRight.gameObject:SetActiveEx(not self.IsOneOnOne)
    if self.IsOneOnOne then
        self.BtnLeft:SetName(XUiHelper.GetText("SSBCharacterBtnName"))
    else
        self.BtnLeft:SetName(XUiHelper.GetText("SSBOrderSortBtnName"))
        self.BtnRight.CallBack = function() self:OnClickBtnRight() end
    end
end

function XUiSSBPickPanelNormalStage:OnClickBtnLeft()
    if self.IsOneOnOne then
        XLuaUiManager.Open("UiSuperSmashBrosCharacter", XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds, true)
    else
        XLuaUiManager.Open("UiSuperSmashBrosOrder", self.Mode, self.PanelRefreshCb)
    end
end

function XUiSSBPickPanelNormalStage:OnClickBtnRight()
    XLuaUiManager.Open("UiSuperSmashBrosCharacter", XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds, true)
end

return XUiSSBPickPanelNormalStage