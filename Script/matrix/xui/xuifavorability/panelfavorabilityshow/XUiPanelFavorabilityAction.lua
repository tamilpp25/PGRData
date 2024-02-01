local XUiGridLikeActionItem=require("XUi/XUiFavorability/PanelFavorabilityShow/XUiGridLikeActionItem")
local XUiPanelFavorabilityAction = XClass(XUiNode, "XUiPanelFavorabilityAction")

local CurrentActionSchedule
local loadGridComplete

function XUiPanelFavorabilityAction:OnStart(uiRoot)
    self.UiRoot = uiRoot
    self.GridLikeActionItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.Content=self.SViewActionList.transform:Find('Viewport/Content'):GetComponent('RectTransform')
end

function XUiPanelFavorabilityAction:OnEnable()
    self.UiRoot.SignBoard:SetClickTrigger(false)
    self.UiRoot.SignBoard:SetRoll(false)
    self:Refresh()
end

function XUiPanelFavorabilityAction:OnDisable()
    loadGridComplete = false
    if self.UiRoot then
        self.UiRoot.SignBoard:SetClickTrigger(true)
        self.UiRoot.SignBoard:SetRoll(true)
    end
    self.DynamicTableAction:RecycleAllTableGrid()
end

function XUiPanelFavorabilityAction:OnDestroy()
    self:UnScheduleAction()
end

function XUiPanelFavorabilityAction:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityAction:Refresh()
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local actionDatas = XMVCA.XFavorability:GetCharacterActionById(currentCharacterId)

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
            if self.CurrentPlayAction and self.CurrentPlayAction.config.Id == v.config.Id then
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
        self.DynamicTableAction:SetProxy(XUiGridLikeActionItem,self.UiRoot)
        self.DynamicTableAction:SetDelegate(self)
    end

    self.DynamicTableAction:SetDataSource(self.ActionList)
    self.DynamicTableAction:ReloadDataASync()
end

function XUiPanelFavorabilityAction:SortActions(actions)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, action in pairs(actions) do
        local isUnlock = self._Control:IsActionUnlock(characterId, action.config.Id)
        local canUnlock = self._Control:CanActionUnlock(characterId, action.config.Id)

        action.priority = 2
        if not isUnlock then
            action.priority = canUnlock and 1 or 3
        end
    end
    table.sort(actions, function(action1, action2)
        if action1.priority == action2.priority then
            return action1.config.Id < action2.config.Id
        else
            return action1.priority < action2.priority
        end
    end)
end

function XUiPanelFavorabilityAction:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActionList[index]
        if data ~= nil then
            grid:OnRefresh(self.ActionList[index], index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurrentPlayAction and self.CurrentPlayAction.config.Id == self.ActionList[index].config.Id and self.CurrentPlayAction.IsPlay then
            --点击相同的动作停止播放动作
            self.CurrentPlayAction.IsPlay = false
            grid:OnRefresh(self.CurrentPlayAction, index)
            self:UnScheduleAction(true, true)
            return
        end
        self:OnActionClick(self.ActionList[index], grid, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        loadGridComplete = true
        if self.Content then
            self.Content.anchoredPosition=Vector2(self.Content.anchoredPosition.x,0)
        end
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
    self._Control:SetDontStopCvContent(true)

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsActionUnlock(characterId, clickAction.config.Id)
    local canUnlock = self._Control:CanActionUnlock(characterId, clickAction.config.Id)

    if isUnlock or canUnlock then
        if canUnlock and not isUnlock then
            XMVCA.XFavorability:OnUnlockCharacterAction(characterId, clickAction.config.Id,true)
            grid:HideRedDot()
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_ACTIONUNLOCK)
        end
        --停止正在播放的动作，准备播放新动作
        self:UnScheduleAction(true, true)
        self:ResetPlayStatus(index)

        XScheduleManager.ScheduleNextFrame(function()
            self.UiRoot.SignBoard:ForcePlayCross(clickAction.config.SignBoardActionId, self.Parent.CvType, true)
            --self.UiRoot.SignBoard:ForcePlay(clickAction.SignBoardActionId, self.Parent.CvType, true)
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
                    if clickGrid:GetActionDataId() == clickAction.config.Id then
                        clickGrid:UpdateProgress(progress)
                        clickGrid:UpdateActionAlpha(updateCount)
                    end
                    updateCount = updateCount + 1
                end
                if not self.CurrentPlayAction or isFinish then
                    clickAction.IsPlay = false
                    if clickGrid:GetActionDataId() == clickAction.config.Id then
                        clickGrid:UpdatePlayStatus()
                        clickGrid:UpdateProgress(0)
                    end
                    --自然结束动作，不播放打断特效
                    self:UnScheduleAction(false)
                end
            end, 20)
        end)

    else
        XUiManager.TipMsg(clickAction.config.ConditionDescript)
    end
end

--因为动画CrossFade可能会导致点击取消播放时，动画状态机还在融合阶段，此时运行的动画和
--逻辑里记录的动画不是同一个，无法取消播放，所以增加强制字段取消播放
function XUiPanelFavorabilityAction:UnScheduleAction(playEffect, force)
    self.UiRoot:SetWhetherPlayChangeActionEffect(playEffect)
    if CurrentActionSchedule then
        XScheduleManager.UnSchedule(CurrentActionSchedule)
        CurrentActionSchedule = nil
    end
    self.UiRoot.SignBoard:Stop(force)
    self.CurrentPlayAction = nil
    self.UiRoot:ResumeCvContent()
end

function XUiPanelFavorabilityAction:SetViewActive(isActive)
    self:UnScheduleAction()
    if isActive then
        self:Open()
    else
        self:Close()
    end
end

return XUiPanelFavorabilityAction