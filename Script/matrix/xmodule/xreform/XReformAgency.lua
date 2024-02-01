---@class XReformAgency : XAgency
---@field private _Model XReformModel
local XReformAgency = XClass(XAgency, "XReformAgency")
function XReformAgency:OnInit()
    --初始化一些变量

    -- 是否已经发起进入请求，用来避免重复请求
    self._IsEnterRequest = false

    self.Const = {
        -- 枚举
        --EntityType = {
        --    Entity = 1,
        --    Add = 2,
        --},
        ---- 改造页签类型
        --EvolvableGroupType = {
        --    Enemy = 1,
        --    Environment = 2,
        --    Buff = 3,
        --    Member = 4,
        --    EnemyBuff = 5, -- 改造敌人buff
        --    StageTime = 6, -- 改造关卡通关时间
        --},
        --StageType = {
        --    Normal = 1,
        --    Challenge = 2,
        --},
        EnemyGroupType = {
            NormanEnemy = 1,
            ExtraEnemy = 2,
        },
        -- 表现相关配置
        --ScrollTime = 0.3, -- 源面板滚动时间
        --MinDistance = 150, -- 滚动检测最小距离
        --MaxDistance = 500, -- 滚动检测最大距离
        --ScrollOffset = 50, -- 滚动偏移
        --EndTimeCode = 20123001, -- 活动时间结束码
    }
end

function XReformAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyReformFubenActivity = handler(self, self.InitWithServerData)
end

function XReformAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XReformAgency:InitWithServerData(serverData)
    self._Model:SetServerData(serverData)
    self:DispatchEvent(XEventId.EVENT_REFORM_SERVER_DATA)
end

function XReformAgency:GetStageCharacterListByStageId(stageId)
    return self._Model:GetStageRecommendCharacterIds(stageId)
end

function XReformAgency:GetRecommendDescByStageIdAndEntityId(stageId, entityId)
    if XRobotManager.CheckIsRobotId(entityId) then
        local robotIdList = self:GetRecommendRobotIdsByStageId(stageId)
        for i = 1, #robotIdList do
            if robotIdList[i] == entityId then
                local groupId = self._Model:GetStageRecommendCharacterGroupIdById(stageId)
                return true, self._Model:GetMemberGroupRecommendDescById(groupId)
            end
        end

        return false, nil
    else
        local characterIdList = self:GetStageCharacterListByStageId(stageId)
        for i = 1, #characterIdList do
            if characterIdList[i] == entityId then
                local groupId = self._Model:GetStageRecommendCharacterGroupIdById(stageId)
                return true, self._Model:GetMemberGroupRecommendDescById(groupId)
            end
        end

        return false, nil
    end
end

function XReformAgency:GetOwnCharacterListByStageId(stageId, characterType)
    local ownCharacterList = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    local robotList = self:GetRecommendRobotIdsByStageId(stageId)
    local length = #ownCharacterList

    for i = 1, #robotList do
        local robot = XRobotManager.GetRobotById(robotList[i])
        local viewModel = robot:GetCharacterViewModel()

        if viewModel:GetCharacterType() == characterType then
            ownCharacterList[length + 1] = robot
            length = length + 1
        end
    end

    return ownCharacterList
end

function XReformAgency:SortEntitiesInStage(entities, stageId)
    local recommendList = self:GetStageCharacterListByStageId(stageId)

    table.sort(entities, function(entityA, entityB)
        local isARobot = XRobotManager.CheckIsRobotId(entityA:GetId())
        local isBRobot = XRobotManager.CheckIsRobotId(entityB:GetId())

        if isARobot and isBRobot then
            return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
        elseif isARobot and not isBRobot then
            for i = 1, #recommendList do
                if recommendList[i] == entityB:GetId() then
                    return false
                end
            end

            return true
        elseif (not isARobot) and isBRobot then
            for i = 1, #recommendList do
                if recommendList[i] == entityA:GetId() then
                    return true
                end
            end

            return false
        else
            local isARecommend = false
            local isBRecommend = false

            for i = 1, #recommendList do
                if recommendList[i] == entityA:GetId() then
                    isARecommend = true
                end
                if recommendList[i] == entityB:GetId() then
                    isBRecommend = true
                end
            end

            if isARecommend and isBRecommend then
                return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
            elseif isARecommend and not isBRecommend then
                return true
            elseif (not isARecommend) and isBRecommend then
                return false
            else
                return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
            end
        end
    end)

    return entities
end

function XReformAgency:GetRecommendRobotIdsByStageId(stageId)
    local groupId = self._Model:GetStageRecommendCharacterGroupIdById(stageId)
    local robotSourceIds = self._Model:GetMemberGroupSubIdsById(groupId)
    local robotIdList = {}
    local length = 0

    for i = 1, #robotSourceIds do
        local robotId = self._Model:GetMemberSourceRobotIdById(robotSourceIds[i])

        robotIdList[length + 1] = robotId
        length = length + 1
    end

    return robotIdList
end

function XReformAgency:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XReformAgency:HandleActivityEndTime()
    XLuaUiManager.RunMain()
    XUiManager.TipError(CS.XTextManager.GetText("ReformAtivityTimeEnd"))
end

function XReformAgency:EnterRequest(callback)
    -- 避免重复请求
    if self._IsEnterRequest then
        if callback then
            callback()
        end
        return
    end
    XNetwork.Call("FubenReformEnterRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:InitWithServerData(res)
        self._IsEnterRequest = true
        if callback then
            callback()
        end
    end)
end

function XReformAgency:GetAvailableChapters()
    return self._Model:GetAvailableChapters()
end

function XReformAgency:GetStage(stageId)
    return self._Model:GetStage(stageId)
end

function XReformAgency:GetStarByPressure(pressure, stageId)
end

function XReformAgency:GetStageStarByPressure(stageId)
    local pressure = self:GetStagePressure(stageId)
    return self._Model:GetStarByPressure(pressure, stageId)
end

function XReformAgency:GetStagePressure(stageId)
    local stage = self._Model:GetStage(stageId)
    local pressure = self._Model:GetStagePressureByStage(stage)
    return pressure
end

function XReformAgency:GetCurrentProgress()
    local stageDic = self._Model:GetStageDic()
    local progress = 0

    for _, stage in pairs(stageDic) do
        if stage:GetIsPassed() then
            progress = progress + 1
        end
    end

    return progress
end

function XReformAgency:GetMaxProgress()
    local chapterConfig = self._Model:GetChapterConfig()
    local progress = 0

    for _, config in pairs(chapterConfig) do
        progress = progress + #config.ChapterStageId
    end

    return progress
end

---@param mobGroup XReform2ndMobGroup
function XReformAgency:RequestSave(mobGroup, callback)
    local mobArray = {}
    local stage = mobGroup:GetStage()

    local groupId = mobGroup:GetGroupId()
    local amount = mobGroup:GetMobAmount()
    local enemyType = self.Const.EnemyGroupType.NormanEnemy
    for i = 1, amount do
        local mob = mobGroup:GetMob(i)
        if mob then
            local sourceId = mobGroup:GetSourceId(i)
            local data = {}
            mobArray[#mobArray + 1] = data
            data.EnemyType = enemyType
            data.EnemyGroupId = groupId
            data.SourceId = sourceId
            data.TargetId = mob:GetId()

            local affixData = {}
            local affixList = mob:GetAffixList()
            for j = 1, #affixList do
                local affix = affixList[j]
                affixData[#affixData + 1] = affix:GetId()
            end
            data.AffixSourceId = affixData
        end
    end

    local stageId = stage:GetId()
    local difficultyIndex = stage:GetDifficultyIndex()

    XNetwork.Call("ReformEnemyRequest", {
        ReplaceIds = mobArray,
        EnemyGroupId = groupId,
        EnemyType = enemyType,
        StageId = stageId,
        DiffIndex = difficultyIndex,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback()
        end
    end)
end

function XReformAgency:GetActivityId()
    return self._Model:GetActivityId()
end

function XReformAgency:GetIsOpen()
    return self._Model:GetIsOpen()
end

function XReformAgency:RequestSelectEnvironment(stageId, environmentId)
    XNetwork.Call("ReformEnvRequest", {
        StageId = stageId,
        DiffIndex = 0,
        EnvId = environmentId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetStageEnvironment(stageId, environmentId)
    end)
end

function XReformAgency:GetIsUnlockedDifficulty(stage)
    return self._Model:GetStageIsUnlockedDifficulty(stage)
end

return XReformAgency