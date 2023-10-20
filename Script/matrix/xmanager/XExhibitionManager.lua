XExhibitionManagerCreator = function()
    local XExhibitionManager = {}
    local METHOD_NAME = {
        GatherRewardListRequest = "GatherRewardListRequest",
        GetGatherReward = "GatherRewardRequest",
    }

    local TotalCharacterNum = {}
    local CharacterTaskFinished = {}
    --临时存放要查看的人的数据
    local CharacterInfo = nil
    local SelfGatherRewards = {}

    -- 自定义字典
    local CharColorBallSkillDic = {}

    XExhibitionManager.ExhibitionType = {
        STRUCT = XCharacterConfigs.CharacterType.Normal, -- 构造体
        PUNISHER = XCharacterConfigs.CharacterType.Isomer, -- 授格者
        Linkage = 3, -- 联动角色
    }
    function XExhibitionManager.HandleExhibitionInfo(data)
        for _, v in pairs(data.GatherRewards) do
            CharacterTaskFinished[v] = true
        end
        SelfGatherRewards = data.GatherRewards
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_EXHIBITION_REFRESH)
    end
    --获得新的角色
    function XExhibitionManager.GetNewCharacter(Id)
        if not CharacterTaskFinished[Id] then
            CharacterTaskFinished[Id] = true
            table.insert(SelfGatherRewards, Id)
        end
    end
    --存放希望查看的玩家所持有图鉴数据
    function XExhibitionManager.SetCharacterInfo(info)
        CharacterInfo = info
    end

    function XExhibitionManager.ClearCharacterInfo()
        CharacterInfo = nil
    end
    --存放自己的所持有图鉴数据
    function XExhibitionManager.GetSelfGatherRewards()
        return SelfGatherRewards
    end

    -- 根据角色id获取该角色的3个颜色的终解球技能
    function XExhibitionManager.GetCharColorBallSkillsByCharacterId(id)
        if XTool.IsTableEmpty(CharColorBallSkillDic) then
            local exhibitionRawardCfgs = XExhibitionConfigs.GetGrowUpTasksConfig()
            for k, cfg in pairs(exhibitionRawardCfgs) do
                local charId = cfg.CharacterId
                if not CharColorBallSkillDic[charId] then
                    CharColorBallSkillDic[charId] = {}
                end
                local skillGroupId = cfg.SkillGroupId
                local skillIds = XTool.IsNumberValid(skillGroupId) and XCharacterConfigs.GetCharSkillGroupTemplatesById(skillGroupId).SkillId or nil
                CharColorBallSkillDic[charId] = skillIds
            end
        end

        return CharColorBallSkillDic[id]
    end

    function XExhibitionManager.CheckTempCharacterTaskFinish(id, IsNotSelf)
        local info = IsNotSelf and CharacterInfo or SelfGatherRewards
        for _, v in pairs(info) do
            if v == id then
                return true
            end
        end
        return false
    end

    function XExhibitionManager.GetCharacterGrowUpLevel(characterId, IsNotSelf)
        local curLevel = XCharacterConfigs.GrowUpLevel.New
        local characterTasks = XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
        if XTool.IsTableEmpty(characterTasks) then
            return curLevel
        end
        for _, task in pairs(characterTasks) do
            if task.LevelId > curLevel and XExhibitionManager.CheckTempCharacterTaskFinish(task.Id, IsNotSelf) then
                curLevel = task.LevelId
            end
        end
        return curLevel
    end

    function XExhibitionManager.IsAchieveMaxLiberation(characterId, IsNotSelf)
        return XExhibitionManager.IsAchieveLiberation(characterId, XCharacterConfigs.GrowUpLevel.End, IsNotSelf)
    end

    function XExhibitionManager.IsAchieveLiberation(characterId, level, IsNotSelf)
        return level and XExhibitionManager.GetCharacterGrowUpLevel(characterId, IsNotSelf) >= level
    end

    function XExhibitionManager.IsMaxLiberationLevel(level)
        return level == XCharacterConfigs.GrowUpLevel.End
    end

    function XExhibitionManager.CheckIsOwnCharacter(characterId, IsNotSelf)
        local growUpTasksConfig = XExhibitionConfigs.GetGrowUpTasksConfig()
        local info = IsNotSelf and CharacterInfo or SelfGatherRewards
        for _, v in pairs(info) do
            if growUpTasksConfig[v].CharacterId == characterId then
                return true
            end
        end
        return false
    end

    function XExhibitionManager.CheckNewCharacterReward(characterId)
        local isNew = false

        if characterId then
            return XExhibitionManager.CheckNewRewardByCharacterId(characterId)
        end

        local tasksConfig = XExhibitionConfigs.GetCharacterGrowUpTasksConfig()
        if XDataCenter.ExhibitionManager.CheckRedPointIsCanSee() then
            for tmpCharacterId, taskConfig in pairs(tasksConfig) do
                if XDataCenter.CharacterManager.IsOwnCharacter(tmpCharacterId) then
                    for taskId, config in pairs(taskConfig) do
                        local canGetReward = true
                        for index = 1, #config.ConditionIds do
                            local ret, _ = XConditionManager.CheckCondition(config.ConditionIds[index], tmpCharacterId)
                            if not ret then
                                canGetReward = false
                            end
                        end
                        if canGetReward and not XExhibitionManager.CheckGrowUpTaskFinish(taskId) then
                            isNew = true
                        end
                    end
                end
            end
        end
        return isNew
    end

    function XExhibitionManager.CheckRedPointIsCanSee()
        return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.CharacterExhibition)
    end

    function XExhibitionManager.CheckNewRewardByCharacterId(characterId)
        if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            return false
        end

        local taskConfig = XExhibitionConfigs.GetCharacterGrowUpTasks(characterId)
        if XTool.IsTableEmpty(taskConfig) then
            return false
        end

        for taskId, config in pairs(taskConfig) do
            local canGetReward = true
            for index = 1, #config.ConditionIds do
                local ret, _ = XConditionManager.CheckCondition(config.ConditionIds[index], characterId)
                if not ret then
                    canGetReward = false
                end
            end
            if canGetReward and not XExhibitionManager.CheckGrowUpTaskFinish(taskId) then
                return true
            end
        end
    end

    function XExhibitionManager.GetCollectionTotalNum(exhibitionType)
        if not TotalCharacterNum[exhibitionType] or TotalCharacterNum[exhibitionType] <= 0 then
            TotalCharacterNum[exhibitionType] = 0
            local characterExhibitionInfo = XExhibitionConfigs.GetExhibitionPortConfigByType(exhibitionType)
            for _, v in pairs(characterExhibitionInfo) do
                if v.CharacterId ~= 0 then
                    TotalCharacterNum[exhibitionType] = TotalCharacterNum[exhibitionType] + 1
                end
            end
        end
        return TotalCharacterNum[exhibitionType]
    end

    function XExhibitionManager.GetCollectionRate(IsNotSelf, exhibitionType)
        local totalTaskNum = XExhibitionConfigs.GetGrowUpLevelMax() * XExhibitionManager.GetTotalCharacterNum(exhibitionType)
        if totalTaskNum == 0 then return 1 end
        local curTaskNum = 0
        local tempData = {}
        local tempConfigData = XExhibitionConfigs.GetGrowUpTasksConfigByType(exhibitionType)
        local tempExhibitionConfigs = XExhibitionConfigs.GetExhibitionLevelPoints()
        local info = IsNotSelf and CharacterInfo or SelfGatherRewards
        for _, v in pairs(info) do
            local tempConfig = tempConfigData[v]
            if tempConfig and tempConfig.LevelId ~= XCharacterConfigs.GrowUpLevel.Super then
                if tempData[tempConfig.CharacterId] then
                    if tempExhibitionConfigs[tempConfig.LevelId] then
                        tempData[tempConfig.CharacterId] = tempData[tempConfig.CharacterId]
                        + tempExhibitionConfigs[tempConfig.LevelId]
                    else
                        tempData[tempConfig.CharacterId] = tempData[tempConfig.CharacterId] + 1
                    end
                else
                    if tempExhibitionConfigs[tempConfig.LevelId] then
                        tempData[tempConfig.CharacterId] = tempExhibitionConfigs[tempConfig.LevelId]
                    else
                        tempData[tempConfig.CharacterId] = 1
                    end
                end
            end
        end
        for _, v in pairs(tempData) do
            curTaskNum = curTaskNum + v
        end
        return curTaskNum / totalTaskNum
    end

    function XExhibitionManager.GetTaskFinishNum(IsNotSelf, exhibitionType)
        local taskFinishNum = {}
        local growUpTasksConfig = XExhibitionConfigs.GetGrowUpTasksConfigByType(exhibitionType) or {}
        local info = IsNotSelf and CharacterInfo or SelfGatherRewards
        for index = XCharacterConfigs.GrowUpLevel.End, 1, -1 do
            taskFinishNum[index] = 0
            for _, v in pairs(info) do
                if growUpTasksConfig[v] and growUpTasksConfig[v].LevelId == index then
                    taskFinishNum[index] = taskFinishNum[index] + 1
                end
            end
        end
        return taskFinishNum
    end

    function XExhibitionManager.GetTotalCharacterNum(exhibitionType)
        local totalCharacterNum = 0
        local characterExhibitionInfo = XExhibitionConfigs.GetExhibitionPortConfigByType(exhibitionType) or {}
        for _, v in pairs(characterExhibitionInfo) do
            if v.CharacterId ~= 0 then
                totalCharacterNum = totalCharacterNum + 1
            end
        end
        return totalCharacterNum
    end

    function XExhibitionManager.CheckGrowUpTaskFinish(taskId)
        return CharacterTaskFinished[taskId] ~= nil
    end

    function XExhibitionManager.CheckCharacterGraduation(characterId, IsNotSelf)
        local count = 0
        local growUpTasksConfig = XExhibitionConfigs.GetGrowUpTasksConfig()
        local info = IsNotSelf and CharacterInfo or SelfGatherRewards
        for _, v in pairs(info) do
            if growUpTasksConfig[v].CharacterId == characterId then
                if growUpTasksConfig[v].LevelId > count then
                    count = growUpTasksConfig[v].LevelId
                end
            end
        end
        return count >= XCharacterConfigs.GrowUpLevel.Higher
    end
    --区分是否是查看自己的信息
    function XExhibitionManager.GetCharHeadPortrait(characterId, IsNotSelf)
        if characterId == nil or characterId == 0 then
            return XExhibitionConfigs.GetDefaultPortraitImagePath()
        elseif XExhibitionManager.CheckCharacterGraduation(characterId, IsNotSelf) then
            return XExhibitionConfigs.GetCharacterGraduationPortrait(characterId)
        else
            return XExhibitionConfigs.GetCharacterHeadPortrait(characterId)
        end
    end

    -- --服务端交互
    -- function XExhibitionManager.RefreshGatherReward(cb)
    --     XNetwork.Call(METHOD_NAME.GatherRewardListRequest, nil,
    --     function(response)
    --         if response.Code ~= XCode.Success then
    --             XUiManager.TipCode(response.Code)
    --             return
    --         end
    --         for _, v in pairs(response.GatherRewards) do
    --             CharacterTaskFinished[v] = true
    --         end
    --         if cb then
    --             cb()
    --         end
    --     end)
    -- end
    function XExhibitionManager.GetGatherReward(characterId, curSelectLevel, cb)
        local taskConfig = XExhibitionConfigs.GetCharacterGrowUpTask(characterId, curSelectLevel)
        local id = taskConfig.Id
        XNetwork.Call(METHOD_NAME.GetGatherReward, { Id = id },
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            XExhibitionManager.GetNewCharacter(id)
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_EXHIBITION_REFRESH)
            if cb then cb() end

            local afterShowTipCb = function ()
                local levelId = taskConfig.LevelId
                local levelName = XExhibitionConfigs.GetExhibitionLevelNameByLevel(levelId)
                XLuaUiManager.Open("UiEquipLevelUpTips", CS.XTextManager.GetText("CharacterLiberateSuccess", levelName))
            end
            
            if XTool.IsTableEmpty(response.RewardGoods) then
                afterShowTipCb()
            else
                XUiManager.OpenUiObtain(response.RewardGoods, nil, afterShowTipCb)
            end

            --终阶解放自动解放技能
            local growUpLevel = XExhibitionManager.GetCharacterGrowUpLevel(characterId)
            if growUpLevel == XCharacterConfigs.GrowUpLevel.End then
                XDataCenter.CharacterManager.UnlockMaxLiberationSkill(characterId)
            end
        end)
    end

    -- 设置超解球颜色(实际为magicId，枚举颜色和magicId的关系)
    function XExhibitionManager.CharacterSwitchLiberateMagicIdRequest(characterId, magicId, cb)
        XNetwork.Call("CharacterSwitchLiberateMagicIdRequest", { CharacterId = characterId, MagicId = magicId },
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 设置超解环
    function XExhibitionManager.CharacterSetLiberateAureoleIdRequest(characterId, aureoleId, cb)
        XNetwork.Call("CharacterSetLiberateAureoleIdRequest", { CharacterId = characterId, AureoleId = aureoleId },
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
          
            if cb then
                cb()
            end
        end)
    end

    return XExhibitionManager
end

XRpc.NotifyGatherRewardList = function(data)
    XDataCenter.ExhibitionManager.HandleExhibitionInfo(data)
    XDataCenter.FashionManager.RefreshAllHeadPortraitIsOwnDicByExhibitionDataNotify()
end

XRpc.NotifyGatherReward = function(data)
    XDataCenter.ExhibitionManager.GetNewCharacter(data.Id)
end