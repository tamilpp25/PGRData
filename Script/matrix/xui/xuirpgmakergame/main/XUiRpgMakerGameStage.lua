local XUiRpgMakerGameStage = XClass(nil, "XUiRpgMakerGameStage")

function XUiRpgMakerGameStage:Ctor(ui, rpgMakerGameStageId, tabGroupIndex)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RpgMakerGameStageId = rpgMakerGameStageId
    self.TabGroupIndex = tabGroupIndex

    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnClick)
end

function XUiRpgMakerGameStage:Refresh(newStageId)
    local rpgMakerGameStageId = self:GetRpgMakerGameStageId()
    local stageStatus = XDataCenter.RpgMakerGameManager.GetRpgMakerGameStageStatus(rpgMakerGameStageId)

    self:UpdatePanelStageStatus(stageStatus)
    self:UpdateStar(rpgMakerGameStageId)

    --背景图
    if self.RImgFightActiveNor then
        local bg = XRpgMakerGameConfigs.GetRpgMakerGameStageBG(rpgMakerGameStageId)
        self.RImgFightActiveNor:SetRawImage(bg)
    end

    --关卡名
    if self.TxtStageOrder then
        self.TxtStageOrder.text = stageStatus ~= XRpgMakerGameConfigs.RpgMakerGameStageStatus.Lock and XRpgMakerGameConfigs.GetRpgMakerGameNumberName(rpgMakerGameStageId) or ""
    end

    self.PanelEffect.gameObject:SetActiveEx(newStageId == rpgMakerGameStageId)
end

function XUiRpgMakerGameStage:UpdateStar(rpgMakerGameStageId)
    local totalStar = XRpgMakerGameConfigs.GetRpgMakerGameStageTotalStar(rpgMakerGameStageId)
    local clearStarCount = 0
    local starCfg
    local maxStarCount = XRpgMakerGameConfigs.MaxStarCount
    local stageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(rpgMakerGameStageId)
    local stageClearStarCount = stageDb and stageDb:GetStarCount() or 0   --通关获得的星星数

    for i = 1, totalStar do
        if self["Img" .. i] then
            self["Img" .. i].gameObject:SetActiveEx(stageClearStarCount >= i)
        end
        if self["Star" .. i] then
            self["Star" .. i].gameObject:SetActiveEx(true)
        end
    end
    for i = totalStar + 1, maxStarCount do
        self["Star" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiRpgMakerGameStage:UpdatePanelStageStatus(stageStatus)
    if self.PanelStageNormal then
        self.PanelStageNormal.gameObject:SetActiveEx(stageStatus ~= XRpgMakerGameConfigs.RpgMakerGameStageStatus.Lock)
    end
    if self.PanelStageLock then
        self.PanelStageLock.gameObject:SetActiveEx(stageStatus == XRpgMakerGameConfigs.RpgMakerGameStageStatus.Lock)
    end
    if self.PanelStagePass then
        self.PanelStagePass.gameObject:SetActiveEx(stageStatus == XRpgMakerGameConfigs.RpgMakerGameStageStatus.Clear)
    end
end

function XUiRpgMakerGameStage:OnBtnClick()
    local rpgMakerGameStageId = self:GetRpgMakerGameStageId()
    local ret, desc = XDataCenter.RpgMakerGameManager.IsStageUnLock(rpgMakerGameStageId)
    if not ret then
        XUiManager.TipMsg(desc)
        return
    end

    XLuaUiManager.Open("UiRpgMakerGameDetail", rpgMakerGameStageId)
end

function XUiRpgMakerGameStage:GetRpgMakerGameStageId()
    return self.RpgMakerGameStageId
end

return XUiRpgMakerGameStage