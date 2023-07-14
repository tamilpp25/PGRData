local XUiGridMonster = XClass(nil, "XUiGridMonster")
local CSTextManagerGetText = CS.XTextManager.GetText
local TweenSpeed = 1
local BornWaitTime = 0.5
local DeadWaitTime = 0.2

function XUiGridMonster:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridMonster:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridMonster:UpdateGrid(monsterEntity, IsPathEdit, IsActionPlaying)
    self.Monster = monsterEntity
    self.IsPathEdit = IsPathEdit
    if monsterEntity then
        local currentNodeId = monsterEntity:GetCurrentNodeId()
        local currentNode = self.BattleManager:GetNode(currentNodeId)
        self.Transform.position = self.Base:GetNodePos(currentNode:GetStageIndexName())
        self.TxtTime.gameObject:SetActiveEx(not IsActionPlaying)

        local nextNodeId = monsterEntity:GetNextNodeId()
        if nextNodeId then
            local nextNode = self.BattleManager:GetNode(nextNodeId)
            local IsRetrograde = currentNode:GetStageIndex() > nextNode:GetStageIndex()
            self.RootPosList = self.Base:GetRootPosList(currentNode:GetStageIndexName(), nextNode:GetStageIndexName(), IsRetrograde)
        end

    end
end

function XUiGridMonster:UpdateTime()
    local refreshTime = XDataCenter.GuildWarManager.GetNextMapRefreshTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local timeStr = XUiHelper.GetTime(math.max(0, refreshTime - nowTime), XUiHelper.TimeFormatType.GUILDCD)
    self.TxtTime.text = CSTextManagerGetText("GuildWarForwardTimeTip", timeStr)
end

function XUiGridMonster:GetMonsterUID()
    return self.Monster and self.Monster:GetUID()
end

function XUiGridMonster:GetMonsterCurrentNodeIndexName()
    local currentNode = self.Monster and self.BattleManager:GetNode(self.Monster:GetCurrentNodeId())
    return currentNode and currentNode:GetStageIndexName()
end

function XUiGridMonster:OnBtnStageClick()
    if not self.IsPathEdit then
        local currentNodeId = self.Monster:GetCurrentNodeId()
        local currentNode = self.BattleManager:GetNode(currentNodeId)
        XLuaUiManager.Open("UiGuildWarStageDetail", currentNode, true) 
    end
end

function XUiGridMonster:ShowAction(actType, cb)
    if actType == XGuildWarConfig.MosterActType.Dead then
        self:DoDead(cb)
    elseif actType == XGuildWarConfig.MosterActType.Born then
        self:DoBorn(cb)
    elseif actType == XGuildWarConfig.MosterActType.Move then
        self:DoMove(cb)
    end
end

function XUiGridMonster:DoMove(cb)
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

function XUiGridMonster:DoBorn(cb)
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

function XUiGridMonster:DoDead(cb)
    coroutine.wrap(function()
            local co = coroutine.running()
            local callBack = function() coroutine.resume(co) end

            if not self.DeadTimer then
                self.DeadTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * DeadWaitTime)
                coroutine.yield()
                self.DeadTimer = nil
            end

            if self.MonsterDisable then
                self.MonsterDisable:PlayTimelineAnimation(callBack)
                coroutine.yield()
            end
            self.Base:KillGridMonster(self)

            if not self.DeadTimer then
                self.DeadTimer = XScheduleManager.ScheduleOnce(callBack, XScheduleManager.SECOND * DeadWaitTime)
                coroutine.yield()
                self.DeadTimer = nil
            end

            if cb then cb() end
        end)()
end

function XUiGridMonster:ShowGrid(IsShow)
    self.GameObject:SetActiveEx(IsShow)
    if IsShow then
        if not self.TimeTimer then
            self.TimeTimer = XScheduleManager.ScheduleForever(function()
                    self:UpdateTime()
                end, XScheduleManager.SECOND, 0)
        end
    else
        if self.TimeTimer then
            XScheduleManager.UnSchedule(self.TimeTimer)
            self.TimeTimer = nil
        end
    end
end

function XUiGridMonster:StopTween()
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

function XUiGridMonster:DoSelect(IsSelect)
    self.ImgSelect.gameObject:SetActiveEx(IsSelect)
end

return XUiGridMonster