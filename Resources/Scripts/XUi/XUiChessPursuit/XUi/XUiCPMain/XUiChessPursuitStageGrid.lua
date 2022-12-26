local XUiChessPursuitStageGrid = XClass(nil, "XUiChessPursuitStageGrid")
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local UI_TYPE = {
    OPEN = 1, --开放
    CLOSE = 2, -- 未开放
    FINISH = 3, -- 通关
}

function XUiChessPursuitStageGrid:Ctor(ui, uiRoot, mapId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MapId = mapId
    self.RewardPanelList = {}
    self.GameObject:SetActiveEx(true)
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiChessPursuitStageGrid:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end
end
--@region 点击事件

function XUiChessPursuitStageGrid:AutoAddListener()
    self.BtnReceive.CallBack = function() self:OnBtnBtnReceiveClick() end
    XUiHelper.RegisterClickEvent(self, self.GridStage, self.OnGridStageClick)
end

function XUiChessPursuitStageGrid:OnBtnBtnReceiveClick()
    local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)

    XDataCenter.TaskManager.FinishTask(mapCfg.TaskId, function(rewards)
        XUiManager.OpenUiObtain(rewards, nil, function()
            self:Refresh()
        end, nil)
    end)
end

function XUiChessPursuitStageGrid:OnGridStageClick()
    local uiType = self:GetUIType()
    if uiType == UI_TYPE.OPEN or uiType == UI_TYPE.FINISH then
        XSaveTool.SaveData(self.UiRoot:GetSaveToolKey(), self.MapId)
    
        self.UiRoot:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.SCENE, {
            MapId = self.MapId
        })
    else
        XUiManager.TipText("ChessPursuitStageNotOpen")
    end
end

--@endregion

function XUiChessPursuitStageGrid:Refresh()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local bossId = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId).BossId
    local chessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(bossId)
    local uiType = self:GetUIType()
    if uiType == UI_TYPE.OPEN then
        local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
        local bossCfg = XChessPursuitConfig.GetChessPursuitBossTemplate(mapCfg.BossId)

        self:RefreshActive(uiType)
        self:RefreshReward()
        self.BtnReceive.gameObject:SetActiveEx(false)

        self.TxtBossName.text = bossCfg.Name
        self.TxtStageName.text = mapCfg.StageName
        self.GridStage:SetRawImage(bossCfg.BossBg)
        local ration = chessPursuitMapDb:GetBossHp() / chessPursuitMapBoss:GetInitHp()
        self.ImgJd.fillAmount = ration
        local bloodVolume = ration * 100
        if bloodVolume > 0 and bloodVolume < 0.01 then
            bloodVolume = 0.01
        end
        self.TxtJd.text = CSXTextManagerGetText("ChessPursuitBloodCount", string.format("%.2f", bloodVolume))
        self.GridStage:SetDisable(false)
    elseif uiType == UI_TYPE.FINISH then
        local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
        local bossCfg = XChessPursuitConfig.GetChessPursuitBossTemplate(mapCfg.BossId)

        self:RefreshActive(uiType)
        self:RefreshReward()
        self.BtnReceive.gameObject:SetActiveEx(true)

        if chessPursuitMapDb:IsCanTakeReward() then
            self.BtnReceive:SetDisable(false)
        else
            self.BtnReceive:SetDisable(true, false)
        end

        self.TxtBossName.text = bossCfg.Name
        self.TxtStageName.text = mapCfg.StageName
        self.GridStage:SetRawImage(bossCfg.BossBg)
        self.ImgJd.fillAmount = 0
        self.TxtJd.text = CSXTextManagerGetText("ChessPursuitBloodCount", 0)
        self.GridStage:SetDisable(false)
    elseif uiType == UI_TYPE.CLOSE then
        self.GridStage:SetDisable(true)
        self:RefreshActive(uiType)
    end
end

function XUiChessPursuitStageGrid:RefreshActive(uiType)
    self.ImgFubenEnd.gameObject:SetActiveEx(uiType == UI_TYPE.FINISH)
    self.PanelJd.gameObject:SetActiveEx(not (uiType == UI_TYPE.CLOSE))
    self.PanelName.gameObject:SetActiveEx(not (uiType == UI_TYPE.CLOSE))
    self.PanelReward.gameObject:SetActiveEx(not (uiType == UI_TYPE.CLOSE))
end

function XUiChessPursuitStageGrid:RefreshReward()
    local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    local rewards = XRewardManager.GetRewardList(mapCfg.RewardShow) or {}

    for i = 1, #rewards do
        local gridReward = self.RewardPanelList[i]
        if not gridReward then
            local ui = CSUnityEngineObjectInstantiate(self.GridReward, self.PanelRewardList)
            ui.gameObject:SetActiveEx(true)
            ui.gameObject.name = string.format("GridReward%d", i)
            gridReward = XUiGridCommon.New(self.UiRoot, ui)
            table.insert(self.RewardPanelList, i, gridReward)
        end

        self.RewardPanelList[i].GameObject:SetActiveEx(true)
        self.RewardPanelList[i]:Refresh(rewards[i])
    end

    for i = #rewards + 1, #self.RewardPanelList do
        self.RewardPanelList[i].GameObject:SetActiveEx(false)
    end
end

function XUiChessPursuitStageGrid:GetUIType()
    if XChessPursuitConfig.CheckChessPursuitMapIsOpen(self.MapId) then
        local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
        if chessPursuitMapDb:IsKill() then
            return UI_TYPE.FINISH
        else
            return UI_TYPE.OPEN
        end
    else
        return UI_TYPE.CLOSE
    end
end

return XUiChessPursuitStageGrid