XUiPanelFavorabilityAction = XClass(nil, "XUiPanelFavorabilityAction")

local CurrentActionSchedule
local loadGridComplete

function XUiPanelFavorabilityAction:Ctor(ui, uiRoot, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent
    XTool.InitUiObject(self)

    self.GridLikeActionItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end

function XUiPanelFavorabilityAction:OnSelected(isSelected)
    self.GameObject:SetActiveEx(isSelected)
    if isSelected then
        self.UiRoot.SignBoard:SetClickTrigger(false)
        self.UiRoot.SignBoard:SetRoll(false)
        self:Refresh()
    else
        loadGridComplete = false
        self.UiRoot.SignBoard:SetClickTrigger(true)
        self.UiRoot.SignBoard:SetRoll(true)
    end
end

function XUiPanelFavorabilityAction:Refresh()
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local actionDatas = XFavorabilityConfigs.GetCharacterActionById(currentCharacterId)

    self:UpdateActionList(actionDatas)
end

function XUiPanelFavorabilityAction:UpdateActionList(actionDatas)
    if not actionDatas then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoActionData")
        self.ActionList = {}
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortActions(actionDatas)
        for k, v in pairs(actionDatas or {}) do
            if self.CurrentPlayAction and self.CurrentPlayAction.Id == v.Id then
                v.IsPlay = true
                self.CurrentPlayAction.Index = k
            else
                v.IsPlay = false
            end
        end
        self.ActionList = actionDatas
    end

    if not self.DynamicTableAction then
        self.DynamicTableAction = XDynamicTableNormal.New(self.SViewActionList.gameObject)
        self.DynamicTableAction:SetProxy(XUiGridLikeActionItem)
        self.DynamicTableAction:SetDelegate(self)
    end

    self.DynamicTableAction:SetDataSource(self.ActionList)
    self.DynamicTableAction:ReloadDataASync()
end

function XUiPanelFavorabilityAction:SortActions(actions)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, action in pairs(actions) do
        local isUnlock = XDataCenter.FavorabilityManager.IsActionUnlock(characterId, action.Id)
        local canUnlock = XDataCenter.FavorabilityManager.CanActionUnlock(characterId, action.Id)

        action.priority = 2
        if not isUnlock then
            action.priority = canUnlock and 1 or 3
        end
    end
    table.sort(actions, function(action1, action2)
        if action1.priority == action2.priority then
            return action1.Id < action2.Id
        else
            return action1.priority < action2.priority
        end
    end)
end

function XUiPanelFavorabilityAction:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActionList[index]
        if data ~= nil then
            grid:OnRefresh(self.ActionList[index], index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurrentPlayAction and self.CurrentPlayAction.Id == self.ActionList[index].Id and self.CurrentPlayAction.IsPlay then
            --点击相同的动作停止播放动作
            self.CurrentPlayAction.IsPlay = false
            grid:OnRefresh(self.CurrentPlayAction, index)
            --播放打断特效
            self:UnScheduleAction(true)
            return
        end
        self:OnActionClick(self.ActionList[index], grid, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        loadGridComplete = true
    end
end

function XUiPanelFavorabilityAction:ResetPlayStatus(index)
    for k, v in pairs(self.ActionList) do
        v.IsPlay = (k == index)
        local grid = self.DynamicTableAction:GetGridByIndex(k)
        if grid then
            grid:OnRefresh(v)
        end
    end
end

function XUiPanelFavorabilityAction:OnActionClick(clickAction, grid, index)
    XDataCenter.FavorabilityManager.SetDontStopCvContent(true)

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsActionUnlock(characterId, clickAction.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanActionUnlock(characterId, clickAction.Id)

    if isUnlock or canUnlock then
        if canUnlock and not isUnlock then
            XDataCenter.FavorabilityManager.OnUnlockCharacterAction(characterId, clickAction.Id)
            grid:HideRedDot()
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_ACTIONUNLOCK)
        end
        --停止正在播放的动作，准备播放新动作
        self:UnScheduleAction(true)
        self:ResetPlayStatus(index)

        self.UiRoot.SignBoard:ForcePlay(clickAction.SignBoardActionId, self.Parent.CvType, true)
        self.CurrentPlayAction = clickAction
        self.CurrentPlayAction.Index = index
        local isFinish = false
        local progress = 0
        local updateCount = 0
        local startTime = self.UiRoot.SignBoard.SignBoardPlayer.PlayerData.PlayingElement.StartTime
        local duration = self.UiRoot.SignBoard.SignBoardPlayer.PlayerData.PlayingElement.Duration

        CurrentActionSchedule = XScheduleManager.ScheduleForever(function()
            local clickGrid
            if loadGridComplete then
                --根据index找到点击的数据所在的Grid
                clickGrid = self.DynamicTableAction:GetGridByIndex(self.CurrentPlayAction.Index)
            end
            if  clickGrid == nil then
                --不存在点击数据的grid(列表滑动不显示这个数据的Grid)，使用点击时的Grid来代替
                clickGrid = grid
            end
            if not clickGrid then
                XLog.Error("XUiPanelFavorabilityAction:OnActionClick函数错误：clickGrid不能为空")
                return
            end

            if self.CurrentPlayAction then
                local time = self.UiRoot.SignBoard.SignBoardPlayer.Time
                progress = (time - startTime) / duration
                if progress >= 1 or self.UiRoot.SignBoard.SignBoardPlayer.PlayerData.PlayingElement == nil then
                    progress = 1
                    isFinish = true
                end
                --判断当前grid存放的数据是不是正在播放的数据
                if clickGrid:GetActionDataId() == clickAction.Id then
                    clickGrid:UpdateProgress(progress)
                    clickGrid:UpdateActionAlpha(updateCount)
                end
                updateCount = updateCount + 1
            end
            if not self.CurrentPlayAction or isFinish then
                clickAction.IsPlay = false
                if clickGrid:GetActionDataId() == clickAction.Id then
                    clickGrid:UpdatePlayStatus()
                    clickGrid:UpdateProgress(0)
                end
                --自然结束动作，不播放打断特效
                self:UnScheduleAction(false)
            end
        end, 20)
    else
        XUiManager.TipMsg(clickAction.ConditionDescript)
    end
end

function XUiPanelFavorabilityAction:UnScheduleAction(playEffect)
    self.UiRoot:SetWhetherPlayChangeActionEffect(playEffect)
    if CurrentActionSchedule then
        XScheduleManager.UnSchedule(CurrentActionSchedule)
        CurrentActionSchedule = nil
    end
    self.UiRoot.SignBoard:Stop()
    self.CurrentPlayAction = nil
    self.UiRoot:ResumeCvContent()
end

function XUiPanelFavorabilityAction:SetViewActive(isActive)
    self.GameObject:SetActiveEx(isActive)
    self:UnScheduleAction()
    if isActive then
        self:Refresh()
    end
end

function XUiPanelFavorabilityAction:OnClose()
    self:UnScheduleAction()
end