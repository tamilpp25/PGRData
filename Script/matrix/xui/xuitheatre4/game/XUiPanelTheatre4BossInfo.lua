---@class XUiPanelTheatre4BossInfo : XUiNode
---@field RImgTypeIcon UnityEngine.UI.RawImage
---@field ImgTime UnityEngine.UI.Image
---@field TxtTime UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TxtScoreNum UnityEngine.UI.Text
---@field ImgScore UnityEngine.UI.Image
---@field BtnLeft XUiComponent.XUiButton
---@field BtnRight XUiComponent.XUiButton
---@field ImgBar UnityEngine.UI.Image
---@field TxtTips UnityEngine.UI.Text
---@field TxtNextBoss UnityEngine.UI.Text
---@field PanelTime UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiPanelTheatre4BossInfo = XClass(XUiNode, "XUiPanelTheatre4BossInfo")

local BossTag = {
    Current = 1,
    Next = 2,
}

function XUiPanelTheatre4BossInfo:OnStart()
    self.IsPlayAnimation = false
    self._CurrentTag = BossTag.Current
    self:_InitUi()
    self:_RegisterEventClicks()
end

function XUiPanelTheatre4BossInfo:OnEnable()
    self:RefreshBoss()
end

function XUiPanelTheatre4BossInfo:OnBtnLeftClick()
    self._CurrentTag = BossTag.Current
    self:RefreshBoss()
end

function XUiPanelTheatre4BossInfo:OnBtnRightClick()
    self._CurrentTag = BossTag.Next
    self:RefreshBoss()
end

function XUiPanelTheatre4BossInfo:_RegisterEventClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnBtnLeftClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnBtnRightClick, true)
end

function XUiPanelTheatre4BossInfo:RefreshBoss()
    local isHasNextTag = self._Control:CheckCurrentHasNextBoss()
    if isHasNextTag then
        if self._CurrentTag == BossTag.Current then
            self:_RefreshTag(false)
            self:_RefreshCurrentBoss()
        else
            self:_RefreshTag(true)
            self:_RefreshNextBoss()
        end
    else
        self.BtnLeft.gameObject:SetActiveEx(false)
        self.BtnRight.gameObject:SetActiveEx(false)
        self.TxtNextBoss.gameObject:SetActiveEx(false)
        if self.PanelBar then
            self.PanelBar.gameObject:SetActiveEx(true)
        end
        self:_RefreshCurrentBoss()
    end
end

function XUiPanelTheatre4BossInfo:RefreshCurrentProsperity()
    if self._CurrentTag == BossTag.Current then
        local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData(nil, true)
        if not bossGridData then
            return
        end
        if bossGridData:IsGridFightEmpty() then
            return
        end
        self:_RefreshProsperity(bossGridData:GetGridFightGroupId(), true)
    end
end

function XUiPanelTheatre4BossInfo:RefreshCurrentTimeInfo()
    if self._CurrentTag == BossTag.Current then
        local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData()
        if not bossGridData then
            return
        end
        if bossGridData:IsGridFightEmpty() then
            return
        end
        self:_RefreshTimeInfo(bossGridData:GetGridPunishCountdown())
    end
end

function XUiPanelTheatre4BossInfo:_RefreshTag(isLeft)
    self.BtnLeft.gameObject:SetActiveEx(isLeft)
    self.BtnRight.gameObject:SetActiveEx(not isLeft)
    self.TxtNextBoss.gameObject:SetActiveEx(isLeft)
    if self.PanelBar then
        self.PanelBar.gameObject:SetActiveEx(not isLeft)
    end
end

function XUiPanelTheatre4BossInfo:_RefreshProsperity(fightGroupId, isCurrent)
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)
    local prosperityCount = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Prosperity)
    local prosperityLimit = self._Control:GetFightGroupProsperityLimit(fightGroupId)

    local index = prosperityCount >= prosperityLimit and 1 or 2
    local color = self._Control:GetClientConfig("AssetNotEnoughTextColor", index)
    if not string.IsNilOrEmpty(color) then
        self.TxtScoreNum.color = XUiHelper.Hexcolor2Color(color)
    end
    if prosperityCount >= prosperityLimit then
        self.TxtTips.text = self._Control:GetClientConfig("GameBossInfoTips", 2) or ""
    else
        local content = self._Control:GetClientConfig("GameBossInfoTips", 1) or ""
        self.TxtTips.text = string.format(content, prosperityLimit - prosperityCount)
    end
    if prosperityIcon then
        self.RImgScore:SetRawImage(prosperityIcon)
    end

    if self.IsPlayAnimation then
        if self._TweenTimer then
            XScheduleManager.UnSchedule(self._TweenTimer)
            self._TweenTimer = nil
        end

        local duration = 0.5
        XUiHelper.TweenLabelNumber(self, self.TxtScoreNum, prosperityLimit, duration)
        local fillAmount = XTool.IsNumberValid(prosperityLimit) and prosperityCount / prosperityLimit or 1
        XUiHelper.TweenFillAmount(self, self.ImgBar, fillAmount, duration)
    else
        self.TxtScoreNum.text = prosperityLimit
        if isCurrent then
            self.ImgBar.fillAmount = XTool.IsNumberValid(prosperityLimit) and prosperityCount / prosperityLimit or 1
        end
    end
end

function XUiPanelTheatre4BossInfo:_RefreshUnknowProsperity()
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)

    self.TxtScoreNum.text = self._Control:GetClientConfig("BossUnknowProsperity")
    local color = self._Control:GetClientConfig("AssetNotEnoughTextColor", 2)
    if not string.IsNilOrEmpty(color) then
        self.TxtScoreNum.color = XUiHelper.Hexcolor2Color(color)
    end

    self.PanelBar.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)
    if prosperityIcon then
        self.RImgScore:SetRawImage(prosperityIcon)
    end
end

function XUiPanelTheatre4BossInfo:_RefreshNextBoss()
    local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData(nil, true)
    if not bossGridData then
        return
    end
    local fightId = bossGridData:GetGridContentId()
    local nextFightId = self._Control:GetNextFightId(fightId)
    if XTool.IsNumberValid(nextFightId) then
        local fightGroupId = self._Control:GetFightGroupIdByFightId(nextFightId)
        self:_RefreshTimeInfo()
        if XTool.IsNumberValid(fightGroupId) then
            self:_RefreshBossInfo(nextFightId, fightGroupId)
        end
    end
end

function XUiPanelTheatre4BossInfo:_RefreshCurrentBoss()
    local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData(nil, true)
    if not bossGridData then
        self:_RefreshUnknowBossInfo()
        return
    end
    if bossGridData:IsGridFightEmpty() then
        self:_RefreshUnknowBossInfo()
        return
    end
    local fightId = bossGridData:GetGridContentId()
    if XTool.IsNumberValid(fightId) then
        self:_RefreshTimeInfo(bossGridData:GetGridPunishCountdown())
        self:_RefreshBossInfo(fightId, bossGridData:GetGridFightGroupId(), true)
    else
        self:_RefreshUnknowBossInfo()
    end
end

function XUiPanelTheatre4BossInfo:_RefreshBossInfo(fightId, fightGroupId, isCurrent)
    if XTool.IsNumberValid(fightId) then
        local blockId = self._Control:GetFightBlockIcon(fightId)

        self.RImgTypeIcon:SetRawImage(self._Control:GetBlockIconDefaultIcon(blockId))
        self.TxtName.text = self._Control:GetFightPanelName(fightId)
        self:_RefreshProsperity(fightGroupId, isCurrent)
    else
        self:_RefreshUnknowBossInfo()
    end
end

function XUiPanelTheatre4BossInfo:_RefreshUnknowBossInfo()
    self.RImgTypeIcon:SetRawImage(self._Control:GetClientConfig("BossUnknowIcon"))
    self.TxtName.text = self._Control:GetClientConfig("BossUnknowName")
    self:_RefreshUnknowProsperity()
    self:_RefreshUnknownTimeInfo()
end

function XUiPanelTheatre4BossInfo:_RefreshTimeInfo(countDown)
    if countDown then
        self.TxtTime.text = countDown == 0 and 1 or countDown
        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(true)
        end
    else
        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelTheatre4BossInfo:_RefreshUnknownTimeInfo()
    local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData()
    if not bossGridData then
        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(false)
        end
        return
    end
    self:_RefreshTimeInfo(bossGridData:GetGridPunishCountdown())
end

function XUiPanelTheatre4BossInfo:_InitUi()
    self.PanelBar = self.Transform:FindTransform("PanelBar")
    self.TxtTips.gameObject:SetActiveEx(false)
end

return XUiPanelTheatre4BossInfo
