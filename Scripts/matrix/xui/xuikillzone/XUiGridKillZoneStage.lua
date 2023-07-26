local XUiGridKillZoneStage = XClass(nil, "XUiGridKillZoneStage")

function XUiGridKillZoneStage:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self.StarGrids = {}

    XTool.InitUiObject(self)
    self:SetSelect(false)

    if self.BtnClick then self.BtnClick.CallBack = function() clickCb(self.StageId) end end

    self.GridStar.gameObject:SetActiveEx(false)
end

function XUiGridKillZoneStage:Refresh(stageId)
    self.StageId = stageId

    local bg = XKillZoneConfigs.GetStageBg(stageId)
    self.RImgBg:SetRawImage(bg)

    local name = XKillZoneConfigs.GetStageName(stageId)
    self.TxtName.text = name

    local order = XKillZoneConfigs.GetStageOrder(stageId)
    self.TxtOrder.text = order

    local isLock = not XDataCenter.KillZoneManager.IsStageUnlock(stageId)
    self.PanelStageLock.gameObject:SetActiveEx(isLock)

    local isDailyStage = XDataCenter.KillZoneManager.IsDailyStageId(stageId)
    self.TxtMaxDefeatNum.gameObject:SetActiveEx(not isDailyStage)
    self.PanelStars.gameObject:SetActiveEx(not isDailyStage)
    if isDailyStage then
        return
    end
    local maxScore = XDataCenter.KillZoneManager.GetStageMaxScore(stageId)
    self.TxtMaxDefeatNum.text = CsXTextManagerGetText("KillZoneStageMaxScore", maxScore)

    local star, maxStar = XDataCenter.KillZoneManager.GetStageStar(stageId)
    for index = 1, maxStar do
        local grid = self.StarGrids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridStar.gameObject, self.PanelStars)
            grid = XTool.InitUiObjectByUi({}, go)
            self.StarGrids[index] = grid
        end

        grid.IconStar.gameObject:SetActiveEx(index <= star)
        grid.GameObject:SetActiveEx(true)
    end
    for index = maxStar + 1, #self.StarGrids do
        self.StarGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridKillZoneStage:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

return XUiGridKillZoneStage