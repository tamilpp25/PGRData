local XAiBengyue = XDlcScriptManager.RegCharScript(8001, "XAiBengyue")

---@param proxy StatusSyncFight.XFightScriptProxy
function XAiBengyue:Ctor(proxy)
    print("XLuaFightScript.Ctor Bengyue")
    self._proxy = proxy

    self._npcList = {}
    self._targetId = 0 --2002
    self._targetPosition = nil --200201

    self._isWaiting = false --buff 80010010
    self._waitingTimer = 0
    self._waitingTime = 3.0

    self._skillPlanId = 0 --5001

    self._skillList = {8001032, 8001033, 8001034, 8001043, 8001044, 8001049, 8001050}
    self._skillCDList = {}
    for i = 1, #self._skillList do
        self._skillCDList[i] = 0
    end
    self._skillCDTimer = 0
    self._skillCDTime = 3.0

    self._turnActionId = 0 --7001
    self._farDistance = 999
    self._midDistance = 18
    self._nearDistance = 8

    self._farDistTurnStopAngle = 67.5
    self._midDistTurnStopAngle = 42.5
    self._nearDistTurnStopAngle = 27.5



    self._turnSkillList = {
        [3] = 8001003,
        [4] = 8001004,
        [5] = 8001005,
        [6] = 8001006,
        [7] = 8001007,
        [8] = 8001008,
        [9] = 8001009,
    }

    self._farDistTurnAngles = {
        [1] = 67.5,
        [2] = 112.5,
        [3] = 112.5,
        [4] = 157.5,
        [5] = -67.5,
        [6] = -112.5,
        [7] = -112.5,
        [8] = -157.5,
        [9] = 157.5,
        [10] = 202.5,
    }
    self._midDistTurnAngles = {
        [1] = 42.5,
        [2] = 84.375,
        [3] = 84.375,
        [4] = 116.25,
        [5] = 116.25,
        [6] = 148.125,
        [7] = -42.5,
        [8] = -84.375,
        [9] = -84.375,
        [10] = -116.25,
        [11] = -116.25,
        [12] = -148.125,
        [13] = 148.125,
        [14] = 211.875,
    }
    self._nearDistTurnAngles = {
        [1] = 27.5,
        [2] = 58.125,
        [3] = 58.125,
        [4] = 103.75,
        [5] = 103.75,
        [6] = 144.375,
        [7] = -27.5,
        [8] = -58.125,
        [9] = -58.125,
        [10] = -103.75,
        [11] = -103.75,
        [12] = -144.375,
        [13] = 144.375,
        [14] = 215.625,
    }

    self._turnPlanDataTable = {
        [3] = {
            {self._farDistTurnAngles[1], self._farDistTurnAngles[2], 311},
            {self._farDistTurnAngles[3], self._farDistTurnAngles[4], 312},
            {self._farDistTurnAngles[6], self._farDistTurnAngles[5], 321},
            {self._farDistTurnAngles[8], self._farDistTurnAngles[7], 322},
            {self._farDistTurnAngles[9], self._farDistTurnAngles[10], 330},
        },
        [2] = {
            {self._midDistTurnAngles[1], self._midDistTurnAngles[2], 310},
            {self._midDistTurnAngles[3], self._midDistTurnAngles[4], 311},
            {self._midDistTurnAngles[5], self._midDistTurnAngles[6], 312},
            {self._midDistTurnAngles[8], self._midDistTurnAngles[7], 320},
            {self._midDistTurnAngles[10], self._midDistTurnAngles[9], 321},
            {self._midDistTurnAngles[12], self._midDistTurnAngles[11], 322},
            {self._midDistTurnAngles[13], self._midDistTurnAngles[14], 330},
        },
        [1] = {
            {self._nearDistTurnAngles[1], self._nearDistTurnAngles[2], 310},
            {self._nearDistTurnAngles[3], self._nearDistTurnAngles[4], 311},
            {self._nearDistTurnAngles[5], self._nearDistTurnAngles[6], 312},
            {self._nearDistTurnAngles[8], self._nearDistTurnAngles[7], 320},
            {self._nearDistTurnAngles[10], self._nearDistTurnAngles[9], 321},
            {self._nearDistTurnAngles[12], self._nearDistTurnAngles[11], 322},
            {self._nearDistTurnAngles[13], self._nearDistTurnAngles[14], 330},
        },
    }

    self._turnActionMap = {
        [310] = self._turnSkillList[3],
        [320] = self._turnSkillList[4],
        [311] = self._turnSkillList[5],
        [321] = self._turnSkillList[6],
        [312] = self._turnSkillList[7],
        [322] = self._turnSkillList[8],
        [330] = self._turnSkillList[9],
    }

    self._enable = false
    self._enable = true
end

function XAiBengyue:Init()
    self._npcId = self._proxy:GetSelfNpcId()
    --self._npcCamp = self._proxy.Npc.Camp
    --local enemyNpcId = self._proxy:GetBehaviorNoteBool(1, 2002)
    print("XLuaFightScript.Init Bengyue")
end

---@param dt number @ delta time
function XAiBengyue:Update(dt)
    --print("XLuaFightScript.Update Bengyue")

    local selfId = self._proxy:GetBehaviorNoteInt(1, 2001)
    local testId = self._proxy:GetBehaviorNoteInt(1, 95786)
    if selfId > 0 then
        --print("1#2001 " .. tostring(selfId))
        self._proxy:SetBehaviorNoteInt(1, 95786, 123456)
    end
    if testId > 0 then
        --print("1#95786 " .. tostring(testId))
    end

    if not self._enable then
        return
    end

    if self._targetId == 0 then
        self._npcList = self._proxy:GetNpcList()
        for i = 1, #self._npcList do
            local npcId = self._npcList[i]
            if not self._proxy:CompareNpcCamp(npcId, self._npcId) and npcId ~= self._targetId then
                self._targetId = npcId
                --print(string.format("new target:%d", npcId))
            end
        end
    end

    if not self._proxy:CheckNpc(self._targetId) then
        self._targetId = 0
        --print("target does not exist")
        return
    end

    if self._isWaiting then
        self._waitingTimer = self._waitingTimer + dt
        if self._waitingTimer >= self._waitingTime then
            self._waitingTimer = 0
            self._isWaiting = false
        else
            return
        end
    end

    self._targetPosition = self._proxy:GetNpcPosition(self._targetId)

    -- skill plan
    local noCastingSkill = not self._proxy:CheckNpcAction(self._npcId, ENpcAction.Skill)
    local canCastSkill = self._proxy:CheckCanCastSkill(self._npcId)
    if noCastingSkill and canCastSkill and self._skillPlanId == 0 then

    end

    --self._skillCDTimer = self._skillCDTimer + dt
    --if self._skillCDTimer >= self._skillCDTime and self._proxy:CheckCanCastSkill(self._npcId) then
    --    local index = math.random(1, #self._skillList)
    --    local skillId = self._skillList[index]
    --    self._proxy:CastSkill(self._npcId, skillId)
    --    --print("Bengyue Cast skill " .. tostring(skillId))
    --end

    self:Steering()

end

---Steering 游荡行为
function XAiBengyue:Steering()
    --Turn logic 转向逻辑
    if not self._isWaiting and not self._proxy:CheckNpcAction(self._npcId, ENpcAction.Skill) then
        local turnPlan = -1
        local targetDist = self._proxy:CalcNpcDistance(self._npcId, self._targetId)
        if self._turnActionId < 3 and targetDist >= self._midDistance and targetDist < self._farDistance
                and not self:IsTargetInMyAngle(self._farDistTurnStopAngle)
        then
            turnPlan = 3
        elseif self._turnActionId < 2 and targetDist >= self._nearDistance and targetDist < self._midDistance
                and not self:IsTargetInMyAngle(self._midDistTurnStopAngle)
        then
            turnPlan = 2
        elseif self._turnActionId < 1 and targetDist < self._nearDistance
                and not self:IsTargetInMyAngle(self._nearDistTurnStopAngle)
        then
            turnPlan = 1
        elseif self._turnActionId > 0 and self:IsTargetInMyAngle(self._nearDistTurnStopAngle) then
            turnPlan = 0
        end
        --print("Turn plan: " .. tostring(turnPlan))

        for planId, data in pairs(self._turnPlanDataTable) do
            --print("Check Turn plan: " .. tostring(planId))
            if turnPlan == planId then
                for j = 1, #data do
                    local pair = data[j]
                    if self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, pair[1], pair[2]) then
                        self._turnActionId = pair[3]
                        --print("Turn action: " .. tostring(self._turnActionId))
                        break
                    end
                end
                break
            end
        end

        --if turnPlan == 3 then
        --    if self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._farDistTurnAngles[1], self._farDistTurnAngles[2]) then
        --        self._turnActionId = 311
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._farDistTurnAngles[3], self._farDistTurnAngles[4]) then
        --        self._turnActionId = 312
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._farDistTurnAngles[6], self._farDistTurnAngles[5]) then
        --        self._turnActionId = 321
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._farDistTurnAngles[8], self._farDistTurnAngles[7]) then
        --        self._turnActionId = 322
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._farDistTurnAngles[9], self._farDistTurnAngles[10]) then
        --        self._turnActionId = 330
        --    end
        --elseif turnPlan == 2 then
        --    if self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[1], self._midDistTurnAngles[2]) then
        --        self._turnActionId = 310
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[3], self._midDistTurnAngles[4]) then
        --        self._turnActionId = 311
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[5], self._midDistTurnAngles[6]) then
        --        self._turnActionId = 312
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[8], self._midDistTurnAngles[7]) then
        --        self._turnActionId = 320
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[10], self._midDistTurnAngles[9]) then
        --        self._turnActionId = 321
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[12], self._midDistTurnAngles[11]) then
        --        self._turnActionId = 322
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._midDistTurnAngles[13], self._midDistTurnAngles[14]) then
        --        self._turnActionId = 330
        --    end
        --elseif turnPlan == 1 then
        --    if self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[1], self._nearDistTurnAngles[2]) then
        --        self._turnActionId = 310
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[3], self._nearDistTurnAngles[4]) then
        --        self._turnActionId = 311
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[5], self._nearDistTurnAngles[6]) then
        --        self._turnActionId = 312
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[8], self._nearDistTurnAngles[7]) then
        --        self._turnActionId = 320
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[10], self._nearDistTurnAngles[9]) then
        --        self._turnActionId = 321
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[12], self._nearDistTurnAngles[11]) then
        --        self._turnActionId = 322
        --    elseif self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, self._nearDistTurnAngles[13], self._nearDistTurnAngles[14]) then
        --        self._turnActionId = 330
        --    end
        --end

        --execute turn action
        for actionId, skillId in pairs(self._turnActionMap) do
            if self._turnActionId == actionId then
                self._proxy:CastSkill(self._npcId, skillId)
                break
            end
        end

        --if self._turnActionId == 310 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[3])
        --elseif self._turnActionId == 320 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[4])
        --elseif self._turnActionId == 311 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[5])
        --elseif self._turnActionId == 321 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[6])
        --elseif self._turnActionId == 312 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[7])
        --elseif self._turnActionId == 322 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[8])
        --elseif self._turnActionId == 330 then
        --    self._proxy:CastSkill(self._npcId, self._turnSkillList[9])
        --end

        self._turnActionId = 0
    end

    --Approach logic 接近逻辑
    if not self._proxy:CheckNpcAction(self._targetId, ENpcAction.BeHit) and
        not self._proxy:CheckNpcAction(self._npcId, ENpcAction.Skill)
    then
        local movePlan = 0
        local targetDist = self._proxy:CalcNpcDistance(self._npcId, self._targetId)
        if movePlan < 2 and targetDist >= self._farDistance and self:IsTargetInMyAngle(self._farDistTurnStopAngle) then
            movePlan = 2
        elseif movePlan < 1 and targetDist >= self._midDistance and targetDist < self._farDistance
                and self:IsTargetInMyAngle(self._farDistTurnStopAngle)
        then
            movePlan = 1
        elseif movePlan < 1 and targetDist >= self._midDistance and targetDist < self._midDistance then
            movePlan = 0
        end

        if movePlan == 2 then
            self._proxy:NpcStartMove(self._npcId, self._targetPosition)
            self._proxy:SetNpcMoveDirection(self._npcId, 0)
            self._proxy:SetNpcMoveType(self._npcId, 1)
        elseif movePlan == 1 then
            self._proxy:NpcStartMove(self._npcId, self._targetPosition)
            self._proxy:SetNpcMoveDirection(self._npcId, 0)
            self._proxy:SetNpcMoveType(self._npcId, 0)
        elseif movePlan == 0 then
            self._proxy:NpcStopMove(self._npcId)
        end
    end


    self:StartWaiting()
end


---@param eventType number
---@param eventArgs userdata
function XAiBengyue:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDamage then
        local args = eventArgs
        print("XLuaFightScript.HandleEvent Bengyue damaged "
                .. ",damages:" .. args.PhysicalDamage
                .. " attacker camp:" .. self._proxy:GetNpcCamp(args.LauncherId))
    end


end

function XAiBengyue:Terminate()
    print("XLuaFightScript.Terminate Bengyue")
end

function XAiBengyue:StartWaiting()
    self._waitingTimer = 0
    self._isWaiting = true
end

function XAiBengyue:IsTargetInMyAngle(angle)
    return self._proxy:CheckNpcInAngle(self._npcId, self._targetId, angle)
end

return XAiBengyue


--Sequence (And Tree => &&
--action => action
--CheckAction => if CheckAction(...) then nextAction end
--Selector (Or Tree => ||
--[[
    if CheckXXX(...) and
       CheckXXX(...) and
       CheckXXX(...) and
       CheckXXX(...)
    then
        ActionXXX(...)
        ActionXXX(...)
    elseif CheckXXX(...) and
           CheckXXX(...) and
           CheckXXX(...) and
           CheckXXX(...) and
           BoolAction(...)
    then
        ActionXXX(...)
        ActionXXX(...)
    end
]]
--Parallel
--write as normal statements
--RandomSelector
--local m = math.random(1, n)
--same as Selector