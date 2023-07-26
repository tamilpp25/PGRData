local STATUS = {
    None = 0,
    START = 1,
    PROGRESS = 2, -- 在跑进度条
    ACTION_CHECK = 3, --到达一次单位时间, 检查是否有角色行动
    ACTION_START = 4, -- 角色行动开始
    ACTION = 5,
    ACTION_END = 6, -- 角色行动结束
    END = 7
}

local XUiPlanetRunningSystemAction = require("XUi/XUiPlanet/Fight/System/XUiPlanetRunningSystemAction")
local XUiPlanetRunningActionAttack = require("XUi/XUiPlanet/Fight/Action/XUiPlanetRunningActionAttack")

---@class XUiPlanetRunningFight
local XUiPlanetRunningFight = XClass(nil, "XUiPlanetRunningFight")

function XUiPlanetRunningFight:Ctor()
    self.ObjFight = false

    ---@type XUiPlanetRunningEntity[]
    self.UiEntities = {}

    self.TimelineHelper = false

    self._Status = STATUS.None

    self._ActionIndex = 0

    self._DurationProgress = 0
    self._DurationProgressMax = 0

    self._BeginData = false

    self._MaxTurn = 2000

    ---@type XUiPlanetRunningSystemAction
    self._SystemAction = XUiPlanetRunningSystemAction.New()

    ---@type XUiPlanetRunningAction
    self._Action = false

    self._AnimationAttack = false

    self._DurationEnd = 1

    self._TimeScale = 1

    self._Debug = false

    local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform
    local UnityApplication = CS.UnityEngine.Application
    if UnityApplication.platform == UnityRuntimePlatform.WindowsEditor then
        self._Debug = true
    end

    self._ResultLua = false
    self._ResultCharacterHp = false

    self._IsRequest = false
    self._SkipCallback = false

    self.IsEnd = false
    self._IsSkip = false
end

function XUiPlanetRunningFight:SetScale(scale)
    self._TimeScale = scale
end

function XUiPlanetRunningFight:GetScale()
    return self._TimeScale
end

function XUiPlanetRunningFight:SetData(data)
    self._BeginData = data
    self:CreateFight(data)
end

function XUiPlanetRunningFight:CreateFight(data)
    local fight = CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningFight()
    if data then
        fight:Init(data)
    end
    self.ObjFight = fight
    self._Status = STATUS.START
end

function XUiPlanetRunningFight:Init()
    local entities = self.ObjFight.Entities
    for i = 0, entities.Count - 1 do
        local entity = entities[i]
        local entityId = entity.Id
        self:UpdateHp(entityId)
    end
end

function XUiPlanetRunningFight:Update(deltaTime)
    deltaTime = deltaTime * self._TimeScale
    if self._Status == STATUS.END then
        if self._IsRequest then
            return
        end
        self._DurationEnd = self._DurationEnd - deltaTime
        if self._DurationEnd < 0 then
            if not self.IsEnd then
                self.IsEnd = true
            end
            XLuaUiManager.SafeClose("UiPlanetFightMain")
        end
        return
    end

    if self._Status == STATUS.START then
        self._Status = STATUS.ACTION_CHECK
        return
    end

    if self._Status == STATUS.PROGRESS then
        -- wait to next action
        self._DurationProgress = self._DurationProgress + deltaTime
        local progress = self._DurationProgress / self._DurationProgressMax
        progress = math.min(progress, 1)
        local entities = self.ObjFight.Entities
        for i = 0, entities.Count - 1 do
            local entity = entities[i]
            local entityId = entity.Id
            local uiEntity = self.UiEntities[entityId]
            if uiEntity then
                uiEntity:UpdateProgressAction(progress)
            end
        end

        if progress == 1 then
            self._Status = STATUS.ACTION_CHECK
        end
        return
    end

    if self._Status == STATUS.ACTION_CHECK then
        self.ObjFight:Run(1)

        self._DurationProgress = 0
        local entities = self.ObjFight.Entities
        for i = 0, entities.Count - 1 do
            local entity = entities[i]
            local entityId = entity.Id
            local uiEntity = self.UiEntities[entityId]
            local actionPoint = entity.Action.ActionPoint
            if entity.Attribute.Life <= 0 then
                actionPoint = 0
            end
            if entity.Action.IsWaitingAction then
                -- 等待行动时，显示满进度
                if uiEntity then
                    uiEntity:SetMaxTargetActionPoint()
                end
            else
                if uiEntity then
                    uiEntity:SetTargetActionPoint(actionPoint)
                end
            end
        end

        local actionIndexLast = self._ActionIndex
        local actionIndexCurrent = self.ObjFight.RecordActionList.Count
        if actionIndexCurrent > actionIndexLast then
            self._ActionIndex = actionIndexCurrent
            self._Status = STATUS.ACTION_START
        else
            if self.ObjFight.IsEnd then
                self._Status = STATUS.END
                self:GenerateResultAndEnd()
                return
            else
                self._Status = STATUS.PROGRESS
            end
        end
        return
    end

    if self._Status == STATUS.ACTION_START then
        local actionIndexCurrent = self.ObjFight.RecordActionList.Count
        if self._ActionIndex <= actionIndexCurrent then
            local action = self.ObjFight.RecordActionList[self._ActionIndex - 1]
            local entityId = action.LauncherId
            local launcherUiEntity = self.UiEntities[entityId]
            if launcherUiEntity then
                launcherUiEntity:ResetProgressAction()

                if self._Debug then
                    local entityAction = self.ObjFight:GetEntity(entityId)
                    local entityTarget = self.ObjFight:GetEntity(action.TargetId)
                    local strAction = ""
                    local strTarget = ""
                    local strCritical = "是否暴击: " .. tostring(action.IsCritical)
                    if entityAction and entityTarget then
                        local attrFormat = "生命值:%d/%d, 攻击:%d, 防御:%d, 暴击率:%d, 暴击率增益:%d, 暴击加成:%d, 速度:%d"
                        local attrAction = entityAction.Attribute
                        strAction = string.format(attrFormat, attrAction.Life, attrAction.MaxLife, attrAction.Attack, attrAction.Defense, attrAction.CriticalPercent, attrAction.CriticalPercentBonus, attrAction.CriticalDamageAdded, attrAction.Speed)
                        local attrTarget = entityTarget.Attribute
                        strTarget = string.format(attrFormat, attrTarget.Life, attrTarget.MaxLife, attrTarget.Attack, attrTarget.Defense, attrTarget.CriticalPercent, attrTarget.CriticalPercentBonus, attrTarget.CriticalDamageAdded, attrTarget.Speed)
                    end
                    print("当前回合:" .. actionIndexCurrent .. "   行动者" .. entityId .. "对" .. action.TargetId .. "  造成伤害:" .. action.Value, strAction, strTarget, strCritical)
                end
            end
            self._Action = XUiPlanetRunningActionAttack.New()
            self._Action:Set(action)
            self._Status = STATUS.ACTION
        else
            self._Status = STATUS.ACTION_END
        end
        return
    end

    if self._Status == STATUS.ACTION then
        local action = self._Action
        if not action then
            self._Status = STATUS.ACTION_END
            return
        end
        if not self._SystemAction:Update(deltaTime, action, self) then
            self._Status = STATUS.ACTION_END
        end
        return
    end

    if self._Status == STATUS.ACTION_END then
        self._Status = STATUS.ACTION_CHECK
        return
    end
end

function XUiPlanetRunningFight:UpdateHp(entityId)
    local entity = self.ObjFight:GetEntity(entityId)
    if not entity then
        return
    end
    local uiEntity = self.UiEntities[entityId]
    if not uiEntity then
        return
    end
    uiEntity:SetHp(entity)
end

function XUiPlanetRunningFight:GetPlayerEntityArray()
    return self:GetEntityArrayByCamp(CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningCampType.Player)
end

function XUiPlanetRunningFight:GetBossEntityArray()
    return self:GetEntityArrayByCamp(CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningCampType.Boss)
end

function XUiPlanetRunningFight:GetEntityArrayByCamp(camp)
    local entities = self.ObjFight.Entities
    local array = {}
    for i = 0, entities.Count - 1 do
        local entity = entities[i];
        if entity.Camp.CampType == camp then
            array[#array + 1] = entity
        end
    end
    return array
end

function XUiPlanetRunningFight:BindUiEntity(entityId, uiRole)
    self.UiEntities[entityId] = uiRole
end

function XUiPlanetRunningFight:Destroy()
    self.ObjFight = false
end

-- 将c#结构转成lua发送
function XUiPlanetRunningFight:GenerateResultAndEnd()
    -- 隐藏特效
    self:RestoreAllEffect()

    local result = self.ObjFight:GetResult()

    --region c#转lua
    local characterHp = {}
    local resultLua = {}
    resultLua.Grid = result.Grid
    resultLua.Seckill = {}
    for i = 0, result.Seckill.Count - 1 do
        local entityId = result.Seckill[i]
        table.insert(resultLua.Seckill, entityId)
    end

    resultLua.IsWin = result.IsWin
    resultLua.StageId = result.StageId
    resultLua.ResultCharacterInfos = {}
    for i = 0, result.ResultCharacterInfos.Count - 1 do
        local attributeLua = {}
        local dataLua = {
            FightingAttribute = {},
            BaseAttribute = {
                Attribute = attributeLua
            }
        }

        local info = result.ResultCharacterInfos[i]
        local objAttribute = info.BaseAttribute.Attribute
        for j = 0, objAttribute.Count - 1 do
            table.insert(attributeLua, objAttribute[j])
        end
        local characterId = info.CharacterInfo.Id
        dataLua.CharacterInfo = {
            Id = characterId,
        }
        table.insert(resultLua.ResultCharacterInfos, dataLua)
        characterHp[characterId] = attributeLua[XPlanetCharacterConfigs.ATTR.Life]
    end
    self._ResultLua = resultLua
    self._ResultCharacterHp = characterHp
    --endregion c#转lua
    
    -- 血量靠客户端自己更新 失败时不更新 否则角色们会被移除
    if resultLua.IsWin then
        local stageData = XDataCenter.PlanetManager.GetStageData()
        local stageCharacterData = stageData:GetCharacterData()
        for i = 1, #stageCharacterData do
            local characterData = stageCharacterData[i]
            local hp = characterHp[characterData.Id]
            if hp then
                characterData.Life = hp
            end
        end
        stageData:SetCharacterData(stageCharacterData)
    end

    if self._BeginData._IsRequest then
        self:OnRequestEnd()
    else
        self._BeginData._IsRequest = true
        self._IsRequest = true
        
        XDataCenter.FunctionEventManager.LockFunctionEvent()
        XDataCenter.PlanetExploreManager.RequestCheckFight(resultLua, function()
            self._IsRequest = false
            local resultFromServer = XDataCenter.PlanetExploreManager.GetResult()
            if (not resultFromServer) or (not resultFromServer:IsStageFinish()) or (resultFromServer:IsPlayed()) then
                self:OnRequestEnd()
                return
            end
            local settleType = resultFromServer:GetSettleType()
            local condition = nil
            if settleType == XPlanetExploreConfigs.SETTLE_TYPE.Lose then
                condition = XPlanetExploreConfigs.MOVIE_CONDITION.SETTLE_FAIL
            elseif settleType == XPlanetExploreConfigs.SETTLE_TYPE.StageFinish then
                condition = XPlanetExploreConfigs.MOVIE_CONDITION.SETTLE_WIN
            end
            local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
            local movieId = XPlanetExploreConfigs.GetMovieIdByCheckControllerStage(condition, stageId)

            -- 结算剧情
            local explore = XDataCenter.PlanetExploreManager.GetExplore()
            if not movieId then
                explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.RESULT)
                self:OnRequestEnd()
                return
            end

            XLuaUiManager.SafeClose("UiPlanetFightMain")
            explore:PlayMovie(movieId, function()
                explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.RESULT)
                self:OnRequestEnd()
            end)
        end)
    end
end

function XUiPlanetRunningFight:RestoreAllEffect()
    for id, entity in pairs(self.UiEntities) do
        entity:HideEffectMove()
        entity:HideEffectBeAttack()
    end
end

function XUiPlanetRunningFight:OnRequestEnd()
    local resultLua = self._ResultLua

    -- 跳过战斗时, 播放气泡
    if resultLua.IsWin and self._IsSkip then
        local bubbleId
        if #(resultLua.Seckill) > 0 then
            bubbleId = XPlanetConfigs.GetSkipFightBubbleSeckill()
        else
            bubbleId = XPlanetConfigs.GetSkipFightBubble()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PLAY_BUBBLE_ID, bubbleId)
    end

    if resultLua.IsWin then
        XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
            XDataCenter.PlanetExploreManager.HandleResult()
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
            if self._SkipCallback then
                self._SkipCallback()
            end
        end, XPlanetConfigs.TipType.GameWin)
    else
        XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
            XDataCenter.PlanetExploreManager.HandleResult()
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
            if self._SkipCallback then
                self._SkipCallback()
            end
        end, XPlanetConfigs.TipType.GameOver)
    end

    XDataCenter.PlanetExploreManager.OnFightComplete(self._BeginData)
end

function XUiPlanetRunningFight:BindAnimationAttack(timelineHelper)
    self.TimelineHelper = timelineHelper
    --if timelineHelper.Mute then
    --    timelineHelper:Mute("LauncherMove")
    --end
end

function XUiPlanetRunningFight:Skip(callback, isSkip)
    self._IsSkip = isSkip
    self._SkipCallback = callback
    local deltaTime = 1 / 60
    for i = 1, self._MaxTurn do
        if self._Status == STATUS.END then
            break
        end
        self:Update(deltaTime)
        -- 把每个回合产生的action都置空
        self._Action = false
    end
    if self._Status ~= STATUS.END then
        self:GenerateResultAndEnd()
        XLog.Error("[XUiPlanetRunningFight] 这场战斗没有结果")
    end
end

return XUiPlanetRunningFight