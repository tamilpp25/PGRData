local XUiPanelChangeStage = XClass(nil, "XUiPanelChangeStage")

function XUiPanelChangeStage:Ctor(ui, offlineFlag)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridStageList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GridStage.gameObject:SetActiveEx(false)
    self.OfflineFlag = offlineFlag
end

function XUiPanelChangeStage:AutoAddListener()
    self.BtnClose.CallBack = function() self:Hide() end
end

function XUiPanelChangeStage:Show(challengeId, callBack)
    self:Refresh(challengeId, callBack)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelChangeStage:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelChangeStage:Refresh(challengeId)
    local t = XDataCenter.ArenaOnlineManager.GetCurSectionData()
    local stageIds = t.Stages
    for _, v in ipairs(self.GridStageList) do
        v.gameObject:SetActive(false)
    end

    if not stageIds or #stageIds <= 0 then
        return
    end

    for index, stageId in ipairs(stageIds) do
        local grid = self.GridStageList[index]
        if not grid then
            local go = CS.UnityEngine.GameObject.Instantiate(self.GridStage.gameObject)
            grid = go.transform
            grid:SetParent(self.PanelContent, false)
            table.insert(self.GridStageList, grid)
        end
        grid.gameObject:SetActive(true)

        local btn = XUiHelper.TryGetComponent(grid.transform, "BtnChange", "Button")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtStage", "Text")
        local cur = XUiHelper.TryGetComponent(grid.transform, "PanelCurStgae")

        local cfg = XArenaOnlineConfigs.GetStageById(stageId)
        name.text = cfg.Name
        local isCur = cfg.Id == challengeId
        cur.gameObject:SetActiveEx(isCur)
        btn.gameObject:SetActiveEx(not isCur)
        btn.CallBack = function()
            if self.OfflineFlag and not cfg.SingleSwitch then
                XUiManager.TipText("ArenaOnlineCanNotSwitchToUnopenedSingleStage")
                return
            end
            local titletext = CS.XTextManager.GetText("TipTitle")
            local contenttext = CS.XTextManager.GetText("ArenaOnlineStageChangeTip", cfg.Name)
            XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
                    if self.OfflineFlag then
                        local data = {ChallengeId = stageId}
                        local cfg = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageCfgStageId(stageId)
                        local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(cfg.SingleDiff[1])
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CHANGE_STAGE, levelControl.StageId, data)
                        self:Hide()
                    else
                        XDataCenter.RoomManager.ArenaOnlineSetStageId(stageId ,function()
                            self:Hide()
                        end)
                    end
                end)
        end
    end
end

return XUiPanelChangeStage