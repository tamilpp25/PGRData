---@class XUiGridReinforcements
---@field Reinforcements XGWReinforcements
---@field Base XUiGuildWarPanelStage
local XUiGridReinforcements = XClass(nil, "XUiGridReinforcements")
local CSTextManagerGetText = CS.XTextManager.GetText
local TweenSpeed = 1
local BornWaitTime = 0.5
local DeadWaitTime = 0.2
local AttackWaitTime = 0.2

local ReinforcementsState = {
    Ready = 1, -- 准备状态
    Rush = 2, -- 进攻状态
}

function XUiGridReinforcements:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self._State = 0
end

function XUiGridReinforcements:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

---@param ReinforcementsEntity XGWReinforcements
function XUiGridReinforcements:UpdateGrid(ReinforcementsEntity, IsPathEdit, IsActionPlaying)
    self.Reinforcements = ReinforcementsEntity
    self.IsPathEdit = IsPathEdit
    if ReinforcementsEntity then
        local currentNodeId = ReinforcementsEntity:GetCurrentNodeId()
        local currentNode = self.BattleManager:GetNode(currentNodeId)
        self.Transform.position = self.Base:GetNodePos(currentNode:GetStageIndexName())
        self.TxtTime.gameObject:SetActiveEx(not IsActionPlaying)

        local nextNodeId = ReinforcementsEntity:GetNextNodeId()
        if XTool.IsNumberValid(nextNodeId) then
            local nextNode = self.BattleManager:GetNode(nextNodeId)
            local IsRetrograde = currentNode:GetStageIndex() > nextNode:GetStageIndex()
            self.RootPosList = self.Base:GetRootPosList(currentNode:GetStageIndexName(), nextNode:GetStageIndexName(), IsRetrograde)
        end
    end
end

function XUiGridReinforcements:SetInjuryShow(damage)
    damage = damage or self.Reinforcements:GetMaxHP()
    self.TextInjury.text = tostring(damage)
end

function XUiGridReinforcements:UpdateTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local readyTime = self.Reinforcements:GetReadyTime()

    if XTool.IsNumberValid(readyTime) and nowTime < readyTime then
        if self._State ~= ReinforcementsState.Ready then
            self._State = ReinforcementsState.Ready
            self.TxtState.text = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushStateDesc')[1]
        end
        local timeStr = XUiHelper.GetTime(math.max(0, readyTime - nowTime), XUiHelper.TimeFormatType.GUILDCD)
        self.TxtTime.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('ReinforcementsReadyDoneTxt')[1], timeStr)
    else
        if self._State ~= ReinforcementsState.Rush then
            self._State = ReinforcementsState.Rush
            self.TxtState.text = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushStateDesc')[2]
        end
        local refreshTime = self.Reinforcements:GetNextMoveTime()
        local timeStr = XUiHelper.GetTime(math.max(0, refreshTime - nowTime), XUiHelper.TimeFormatType.GUILDCD)
        self.TxtTime.text = CSTextManagerGetText("GuildWarForwardTimeTip", timeStr)
    end

end

function XUiGridReinforcements:GetReinforcementUID()
    return self.Reinforcements and self.Reinforcements:GetUID()
end

function XUiGridReinforcements:GetReinforcementCurrentNodeIndexName()
    local currentNode = self.Reinforcements and self.BattleManager:GetNode(self.Reinforcements:GetCurrentNodeId())
    return currentNode and currentNode:GetStageIndexName()
end

function XUiGridReinforcements:OnBtnStageClick()
    if not self.IsPathEdit then
        XLuaUiManager.Open("UiGuildWarReinforcementsDetail", self.Reinforcements) 
    end
end

function XUiGridReinforcements:ShowAction(actType, cb)
    if actType == XGuildWarConfig.GWActionType.ReinforcementDead then
        self:DoDead(cb)
    elseif actType == XGuildWarConfig.GWActionType.ReinforcementBorn then
        self:DoBorn(cb)
    elseif actType == XGuildWarConfig.GWActionType.ReinforcementMove then
        self:DoMove(cb)
    elseif actType == XGuildWarConfig.GWActionType.ReinforcementAttack then
        self:DoAttack(cb)    
    else
        XLog.Debug('援军执行动画不存在, actType: ', actType)
        if cb then
            cb()
        end
    end
end

function XUiGridReinforcements:DoMove(cb)
    if self.RootPosList and next(self.RootPosList) then
        local tagPos = self.RootPosList[1]
        if not self.MoveTimer then
            self.MoveTimer = XUiHelper.DoWorldMove(self.Transform, tagPos, TweenSpeed, XUiHelper.EaseType.Linear, function ()
                table.remove(self.RootPosList,1)
                self.MoveTimer = nil
                self:DoMove(cb)
            end)
        end
    else
        if cb then cb() end
    end
end

function XUiGridReinforcements:DoBorn(cb)
    coroutine.wrap(function()
            local co = coroutine.running()
            local callBack = function() coroutine.resume(co) end

            if not self.BornTimer then
                self.BornTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * BornWaitTime)
                coroutine.yield()
                self.BornTimer = nil
            end

            self:ShowGrid(true)
            XScheduleManager.ScheduleOnce(function ()
                    if self.MonsterEnable then
                        self.MonsterEnable:PlayTimelineAnimation(callBack)
                    else
                        callBack()
                    end
            end, 1)
            coroutine.yield()
            

            if not self.BornTimer then
                self.BornTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * BornWaitTime)
                coroutine.yield()
                self.BornTimer = nil
            end

            if cb then cb() end
        end)()
end

function XUiGridReinforcements:DoDead(cb)
    coroutine.wrap(function()
            local co = coroutine.running()
            local callBack = function() coroutine.resume(co) end

            if not self.DeadTimer then
                self.DeadTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * DeadWaitTime)
                coroutine.yield()
                self.DeadTimer = nil
            end

            if self.MonsterDisable and self.GameObject.activeInHierarchy then
                self.MonsterDisable:PlayTimelineAnimation(callBack)
                coroutine.yield()
            end
            self.Base:KillGridReinforcement(self)

            if not self.DeadTimer then
                self.DeadTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * DeadWaitTime)
                coroutine.yield()
                self.DeadTimer = nil
            end

            if cb then cb() end
        end)()
end

function XUiGridReinforcements:DoAttack(cb)
    coroutine.wrap(function()
        local co = coroutine.running()
        local callBack = function() coroutine.resume(co) end

        if not self.AttackTimer then
            self.AttackTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * AttackWaitTime)
            coroutine.yield()
            self.AttackTimer = nil
        end

        if self.MonsterHit and self.GameObject.activeInHierarchy then
            self.MonsterHit:PlayTimelineAnimation(callBack)
            coroutine.yield()
        end

        if not self.AttackTimer then
            self.AttackTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * AttackWaitTime)
            coroutine.yield()
            self.AttackTimer = nil
        end

        if cb then cb() end
    end)()
end

function XUiGridReinforcements:ShowGrid(IsShow)
    self.GameObject:SetActiveEx(IsShow)
    if IsShow then
        if not self.TimeTimer then
            self:UpdateTime()
            self.TimeTimer = XScheduleManager.ScheduleForever(function()
                    self:UpdateTime()
                end, XScheduleManager.SECOND, 0)
            self.Base:AddTimerId(self.TimeTimer)
        end
    else
        if self.TimeTimer then
            XScheduleManager.UnSchedule(self.TimeTimer)
            self.Base:RemoveTimerId(self.TimeTimer)
            self.TimeTimer = nil
        end
    end
end

function XUiGridReinforcements:StopTween()
    if self.TimeTimer then
        XScheduleManager.UnSchedule(self.TimeTimer)
        self.TimeTimer = nil
    end

    if self.MoveTimer then
        XScheduleManager.UnSchedule(self.MoveTimer)
        self.MoveTimer = nil
    end

    if self.BornTimer then
        XScheduleManager.UnSchedule(self.BornTimer)
        self.BornTimer = nil
    end

    if self.DeadTimer then
        XScheduleManager.UnSchedule(self.DeadTimer)
        self.DeadTimer = nil
    end
end

function XUiGridReinforcements:DoSelect(IsSelect)
    self.ImgSelect.gameObject:SetActiveEx(IsSelect)
end

return XUiGridReinforcements