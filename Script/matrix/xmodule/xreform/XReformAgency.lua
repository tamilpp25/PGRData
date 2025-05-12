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

function XReformAgency:GetOwnCharacterListByStageId(stageId)
    local ownCharacterList = XMVCA.XCharacter:GetOwnCharacterList()
    local robotList = self:GetRecommendRobotIdsByStageId(stageId)
    local length = #ownCharacterList

    for i = 1, #robotList do
        local robot = XRobotManager.GetRobotById(robotList[i])
        --local viewModel = robot:GetCharacterViewModel()

        ownCharacterList[length + 1] = robot
        length = length + 1
    end

    -- 3.5 只显示配置的角色
    local characterIds = self:GetCharacterCanSelect(stageId)

    -- 配置为空， 代表不过滤任何角色
    if #characterIds == 0 then
        return ownCharacterList
    end
    local dict = {}
    for _, characterIdCanSelect in pairs(characterIds) do
        dict[characterIdCanSelect] = true
    end
    for i = #ownCharacterList, 1, -1 do
        local characterId
        -- 可能是机器人
        if ownCharacterList[i].GetCharacterId then
            characterId = ownCharacterList[i]:GetCharacterId()
        else
            characterId = ownCharacterList[i]:GetId()
        end
        if not dict[characterId] then
            table.remove(ownCharacterList, i)
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
            callback(true)
        end
        return true
    end
    XNetwork.Call("FubenReformEnterRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            callback(false)
            return
        end
        self:InitWithServerData(res)
        self._IsEnterRequest = true
        if callback then
            callback(true)
        end
    end)
    return false
end

function XReformAgency:GetAvailableChapters()
    return self._Model:GetAvailableChapters()
end

function XReformAgency:GetStage(stageId)
    return self._Model:GetStage(stageId)
end

function XReformAgency:GetStarByPressure(pressure, stageId)
    return self._Model:GetStarByPressure(pressure, stageId)
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
    -- 本来想延后, 但是红点需要判断是否通关
    self._Model:InitServerDataStagePassed()
    local progress = 0

    local chapterConfigs = self._Model:GetChapterConfig()
    for i, config in pairs(chapterConfigs) do
        local chapterId = config.Id
        local chapter = self._Model:GetChapter(chapterId)
        local stageList = chapter:GetStageList(self._Model)
        for j = 1, #stageList do
            local stageId = stageList[j]
            local stage = self._Model:GetStage(stageId)
            if stage:GetIsPassed() then
                progress = progress + 1
            else
                -- 普通clear = 普通通关 or 困难通关, 困难clear = 困难通关
                if j == 1 then
                    local hardStageId = stageList[2]
                    if hardStageId then
                        local hardStage = self._Model:GetStage(hardStageId)
                        if hardStage and hardStage:GetIsPassed() then
                            progress = progress + 1
                        end
                    end
                end
            end
        end
    end

    return progress
end

function XReformAgency:GetMaxProgress()
    local progress = 0

    local chapterConfigs = self._Model:GetChapterConfig()
    for i, config in pairs(chapterConfigs) do
        local chapterId = config.Id
        local chapter = self._Model:GetChapter(chapterId)
        local stageList = chapter:GetStageList(self._Model)
        progress = progress + #stageList
    end

    return progress
end

---@param mobGroup XReform2ndMobGroup
function XReformAgency:RequestSave(mobGroup, callback, oneKeyConfig)
    local mobList = mobGroup:GetMobList()
    self._Model:CheckMobListAffixMutex(mobList, true)

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

            -- 3.5版本开始, 词缀和怪物脱钩, 仅保留第一个怪物的词缀效果
            if i == 1 then
                for j = 1, #affixList do
                    local affix = affixList[j]
                    affixData[#affixData + 1] = affix:GetId()
                end
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
        OneKeyConfig = oneKeyConfig,
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

function XReformAgency:IsUnlockStageHard()
    return self._Model:IsUnlockStageHard()
end

function XReformAgency:GetStarMax(stage, isHardMode)
    return self._Model:GetStageStarMax(stage, isHardMode)
end

---@param stage XReform2ndStage
function XReformAgency:GetGoalDesc(stage)
    return self._Model:GetStageGoalDescById(stage:GetId())
end

function XReformAgency:GetStagePlayerAmount(stageId)
    local playerAmountLimitAffix = self._Model:GetStagePlayerAmountLimitAffix(stageId)
    if #playerAmountLimitAffix > 0 then
        local stage = self._Model:GetStage(stageId)
        local mobGroup = self._Model:GetMonsterGroupByIndex(stage)
        local mobList = mobGroup:GetMobList()

        local playerAmountLimit = self._Model:GetStagePlayerAmountLimit(stageId)
        for i = 1, #playerAmountLimitAffix do
            local affixId = playerAmountLimitAffix[i]

            for j = 1, #mobList do
                local mob = mobList[j]
                local affixList = mob:GetAffixList()
                for k = 1, #affixList do
                    local affix = affixList[k]
                    if affix:GetId() == affixId then
                        return playerAmountLimit[i]
                    end
                end
            end
        end
    end
    local default = self._Model:GetStagePlayerAmountLimitDefault(stageId)
    if default == 0 then
        return XEnumConst.FuBen.PlayerAmount
    end
    return default
end

function XReformAgency:GetRootStageId(stageId)
    return self._Model:GetRootStageId(stageId)
end

function XReformAgency:IsOnUiStage(stageId)
    if XLuaUiManager.IsUiShow("UiReformList") then
        local value = self._Model:IsOnUiStage(stageId)
        return value
    end
    return false
end

function XReformAgency:CheckUiEnvironmentAutoIsOpened(stageId)
    return self._Model:CheckUiEnvironmentAutoIsOpened(stageId)
end

function XReformAgency:GetCharacterCanSelect(stageId)
    local config = self._Model:GetStageConfigById(stageId)
    local id = config.UseCharaGroup
    if id == 0 then
        return {}
    end
    local configUseCharaGroup = self._Model:GetReformUseCharaGroup(id)
    return configUseCharaGroup.CharacterIds
end

function XReformAgency:CheckChapterRedDifficulty(chapter, isHardMode)
    if isHardMode then
        if chapter:IsHasStageHard(self._Model) then
            if XDataCenter.Reform2ndManager.GetChapterRedPointFromLocal(chapter:GetId(), true) then
                local isChapterUnlock = self._Model:IsChapterUnlocked(chapter, true)
                if isChapterUnlock then
                    return true
                end
            end
        end
        return false
    else
        if XDataCenter.Reform2ndManager.GetChapterRedPointFromLocal(chapter:GetId(), false) then
            local isChapterUnlock = self._Model:IsChapterUnlocked(chapter, false)
            if isChapterUnlock then
                return true
            end
        end
        return false
    end
end

---@param chapter XReform2ndChapter
function XReformAgency:CheckChapterRed(chapter)
    --1. 关卡解锁后,在关卡图片的右上方显示蓝点,可传递至外部活动入口处
    --2. 点进关卡后,蓝点消失
    --3. 若解锁的关卡为困难模式,则在普通模式的活动主界面中,切换难度按纽的右上方显示蓝点,在玩家点进相应的蓝点困难关卡后消失

    -- 检查所有chapter
    if chapter == nil then
        for i = 1, self._Model:GetCurrentChapterNumber() do
            chapter = self._Model:GetChapterByIndex(i)
            if chapter then
                if self:CheckChapterRed(chapter) then
                    return true
                end
            end
        end
        return false
    else
        -- 检查单个chapter
        -- 困难模式
        if self:CheckChapterRedDifficulty(chapter, true) then
            return true
        end
        -- 普通模式
        if self:CheckChapterRedDifficulty(chapter, false) then
            return true
        end
        return false
    end
end

function XReformAgency:CheckToggleHard()
    for i = 1, self._Model:GetCurrentChapterNumber() do
        local chapter = self._Model:GetChapterByIndex(i)
        if chapter then
            if chapter:IsHasStageHard(self._Model) then
                if XDataCenter.Reform2ndManager.GetChapterRedPointFromLocal(chapter:GetId(), true) then
                    local isChapterUnlock = self._Model:IsChapterUnlocked(chapter, true)
                    if isChapterUnlock then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return XReformAgency