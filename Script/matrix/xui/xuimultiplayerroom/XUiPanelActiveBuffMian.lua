local XUiPanelActiveBuffMian = XClass(nil, "XUiPanelActiveBuffMian")

function XUiPanelActiveBuffMian:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.PlayerActiveBuffOnList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Hide()
end

function XUiPanelActiveBuffMian:AutoAddListener()
    self.BtnDesc.CallBack = function() self:OnBenDescClick() end
end

function XUiPanelActiveBuffMian:Show()
    self:Refresh()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelActiveBuffMian:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelActiveBuffMian:Refresh()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData or not roomData.StageId then
        return
    end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        return
    end

    self.PlayerActiveBuffOnList = {}
    self.BuffCfg = XDataCenter.ArenaOnlineManager.GetActiveBuffCfgByStageId(roomData.ChallengeId)
    local enoughCount = 0
    for _, player in pairs(roomData.PlayerDataList) do
        local initQualty = player.FightNpcData.Character.InitQuality
        if initQualty <= self.BuffCfg.Quality then
            enoughCount = enoughCount + 1
        end
    end

    if enoughCount >= self.BuffCfg.QualityCount then
        self.PanalOn.gameObject:SetActiveEx(true)
        self.PanelOFF.gameObject:SetActiveEx(false)
        self.UiRoot:PlayAnimation("PanalOnQiHuan")

        for _, player in pairs(roomData.PlayerDataList) do
            local initQualty = player.FightNpcData.Character.InitQuality
            if initQualty <= self.BuffCfg.AffectQuality then
                self.PlayerActiveBuffOnList[player.Id] = true
            end
        end

        if not self.ActiveOn then
            -- XUiManager.TipMsg(self.BuffCfg.ActiveTip)
            self.UiRoot:InsertActiveTips(self.BuffCfg.ActiveTip)
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

function XUiPanelActiveBuffMian:CheckActiveOn(playerId)
    return self.PlayerActiveBuffOnList and self.PlayerActiveBuffOnList[playerId]
end

function XUiPanelActiveBuffMian:OnBenDescClick()
    self.UiRoot:PanelActiveBuffShow(self.BuffCfg)
end

return XUiPanelActiveBuffMian