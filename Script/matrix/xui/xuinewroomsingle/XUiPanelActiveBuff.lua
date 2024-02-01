local XUiPanelActiveBuff = XClass(nil, "XUiPanelActiveBuff")

function XUiPanelActiveBuff:Ctor(ui, uiRoot,stageId, challengeId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.PlayerActiveBuffOnList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Hide()
    self.StageId = stageId
    self.ChallengeId = challengeId
end

function XUiPanelActiveBuff:AutoAddListener()
    self.BtnDesc.CallBack = function() self:OnBenDescClick() end
end

function XUiPanelActiveBuff:Show()
    self:Refresh()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelActiveBuff:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelActiveBuff:Refresh()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        return
    end
    self.PlayerActiveBuffOnList = {}
    local PlayerDataList = {}
    self.BuffCfg = XDataCenter.ArenaOnlineManager.GetActiveBuffCfgByStageId(self.ChallengeId)
    local enoughCount = 0

    self.teamData = self.UiRoot:GetTeamData()
    
    for _, player in pairs(self.teamData.TeamData) do
        local info = XMVCA.XCharacter:GetCharacter(player)
        table.insert(PlayerDataList, info)
    end
    if not next(PlayerDataList) then return end
    for _, player in pairs(PlayerDataList) do
        local initQualty = player.InitQuality
        if initQualty <= self.BuffCfg.Quality then
            enoughCount = enoughCount + 1
        end
    end

    if enoughCount >= self.BuffCfg.QualityCount then
        self.PanalOn.gameObject:SetActiveEx(true)
        self.PanelOFF.gameObject:SetActiveEx(false)
        self.UiRoot:PlayAnimation("PanalOnQiHuan")

        for _, player in pairs(PlayerDataList) do
            local initQualty = player.InitQuality
            if initQualty <= self.BuffCfg.AffectQuality then
                self.PlayerActiveBuffOnList[player.Id] = true
            end
        end

        if not self.ActiveOn then
            XUiManager.TipMsgEnqueue(self.BuffCfg.ActiveTip)
            -- self.UiRoot:InsertActiveTips(self.BuffCfg.ActiveTip)
        end
        self.ActiveOn = true
    else
        self.ActiveOn = false
        self.PanalOn.gameObject:SetActiveEx(false)
        self.PanelOFF.gameObject:SetActiveEx(true)
        self.UiRoot:PlayAnimation("PanelOFFQiHuan")
    end
    self.TxtDesc.text = CS.XTextManager.GetText("ArenaOnlineActiveBuffDesc", enoughCount, self.BuffCfg.QualityCount)
    self.RawOnIcon:SetRawImage(self.BuffCfg.OnIcon)
    self.RawOffIcon:SetRawImage(self.BuffCfg.OffIcon)
end

function XUiPanelActiveBuff:CheckActiveOn(playerId)
    return self.PlayerActiveBuffOnList and self.PlayerActiveBuffOnList[playerId]
end

function XUiPanelActiveBuff:OnBenDescClick()
    self.ActiveBuffPanelTip:Show(self.BuffCfg)
    self.UiRoot:PlayAnimation("ActiveBuffEnable")
end

function XUiPanelActiveBuff:RegisterPanel(panel)
    self.ActiveBuffPanelTip = panel
end


return XUiPanelActiveBuff