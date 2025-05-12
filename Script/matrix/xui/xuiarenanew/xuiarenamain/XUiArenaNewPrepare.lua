---@class XUiArenaNewPrepare : XUiNode
---@field RImgLevel UnityEngine.UI.RawImage
---@field BtnLevelReward XUiComponent.XUiButton
---@field BtnShop XUiComponent.XUiButton
---@field PanelNorResult UnityEngine.RectTransform
---@field PanelSelectResult UnityEngine.RectTransform
---@field TxtNorResultTime UnityEngine.UI.Text
---@field TxtSelectResultTime UnityEngine.UI.Text
---@field TxtNorFightTime UnityEngine.UI.Text
---@field TxtLevel UnityEngine.UI.Text
---@field _Control XArenaControl
local XUiArenaNewPrepare = XClass(XUiNode, "XUiArenaNewPrepare")

-- region 生命周期

function XUiArenaNewPrepare:OnStart(groupData)
    ---@type XArenaGroupDataBase
    self._GroupData = groupData

    self:_RegisterButtonClicks()
end

function XUiArenaNewPrepare:OnEnable()
    self:_Refresh()
end

-- endregion

-- region 按钮事件

function XUiArenaNewPrepare:OnBtnLevelRewardClick()
    local challengeId = self._GroupData:GetChallengeId()
    local arenaLevel = self._GroupData:GetArenaLevel()

    XLuaUiManager.Open("UiArenaContributeTips", challengeId, arenaLevel)
    self.Parent:OnShowTips()
end

function XUiArenaNewPrepare:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Arena)
end

-- endregion

-- region 私有方法

function XUiArenaNewPrepare:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnLevelReward, self.OnBtnLevelRewardClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick, true)
end

function XUiArenaNewPrepare:_Refresh()
    local arenaLevel = self._GroupData:GetArenaLevel()
    local isOverStatus = self._Control:IsInActivityOverStatus()
    local resultTime = self._Control:GetActivityResultTimeStr()
    local fightTime = self._Control:GetActivityFightStartTimeStr()

    self.TxtLevel.text = self._Control:GetCurrentChallengeLevelStr()
    self.RImgLevel:SetRawImage(self._Control:GetArenaLevelWordIconById(arenaLevel))
    self.PanelNorResult.gameObject:SetActiveEx(not isOverStatus)
    self.PanelSelectResult.gameObject:SetActiveEx(isOverStatus)
    self.TxtSelectResultTime.gameObject:SetActiveEx(isOverStatus)
    self.TxtNorResultTime.gameObject:SetActiveEx(isOverStatus)
    self.TxtNorResultTime.text = resultTime
    self.TxtSelectResultTime.text = resultTime
    self.TxtNorFightTime.text = fightTime
end

-- endregion

return XUiArenaNewPrepare
