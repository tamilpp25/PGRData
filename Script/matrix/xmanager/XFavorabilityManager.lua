XFavorabilityManagerCreator = function()
    local XFavorabilityManager = {}
    local ClientConfig = CS.XGame.ClientConfig

    local CharacterFavorabilityDatas = {}

    local UnlockRewardFunc = {}

    local GivenItemCharacterIdList = {}
    
    local FestivalActivityMailId = 0 --节日邮件活动Id

    -- 播放语音结束进行回调时，是否调用StopCvContent，语音正常播放结束时调用，查看动作打断语音时不调用
    local DontStopCvContent
    
    local SkillCvTimeLimit = CS.XGame.ClientConfig:GetFloat("CharacterSkillLevelUpCvTimeLimit")
    local LastPlaySkillCvTime = 0

    -- [战斗参数达到target, 后端还不能正确计算出战斗参数，暂时返回false]
    UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.FightAbility] = function()
        -- local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        -- local curCharacterAbility = characterData.Ability or 0
        return false
        -- return math.ceil(curCharacterAbility) >= target
    end
    -- [信赖度达到target]
    UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.TrustLv] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local trustLv = characterData.TrustLv or 1
        return trustLv >= target
    end
    -- [角色等级达到target]
    UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.CharacterLv] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local characterLevel = characterData.Level or 1
        return characterLevel >= target
    end
    -- [进化至target]
    UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.Quality] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local characterQuality = characterData.Quality or 1
        return characterQuality >= target
    end

    local UnlockStrangeNewsFunc = {}
    UnlockStrangeNewsFunc[XFavorabilityConfigs.StrangeNewsUnlockType.TrustLv] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if not characterData then
            return false
        end

        local trustLv = characterData.TrustLv or 1
        return trustLv >= target
    end

    -- [宿舍事件:等宿舍完工补上]
    UnlockStrangeNewsFunc[XFavorabilityConfigs.StrangeNewsUnlockType.DormEvent] = function()
        return false
    end


    function XFavorabilityManager.Init()

        CharacterFavorabilityDatas = {}
        --默认打开已解锁的信息
        local allInfo = XFavorabilityConfigs.GetCharacterInformation()
        for id, v in pairs(allInfo) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(id)
            for _, var in ipairs(v) do
                if var.UnlockLv <= trustLv then
                    XFavorabilityManager.OnUnlockCharacterInfomatin(id, var.Id)
                end
            end

        end

        --异闻
        local allRumors = XFavorabilityConfigs.GetCharacterRumors()
        for id, v in pairs(allRumors) do

            for _, var in ipairs(v) do
                local canUnlock = XFavorabilityManager.CanRumorsUnlock(id, var.UnlockType, var.UnlockPara)
                if canUnlock then
                    XFavorabilityManager.OnUnlockCharacterRumor(id, var.Id)
                end
            end
        end

        --剧情
        local allStory = XFavorabilityConfigs.GetCharacterStory()
        for id, v in pairs(allStory) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(id)
            for _, var in ipairs(v) do
                if var.UnlockLv <= trustLv then
                    XFavorabilityManager.OnUnlockCharacterStory(id, var.Id)
                end
            end
        end

        --CV
        local allVoice = XFavorabilityConfigs.GetCharacterVoice()
        for characterId, characterVoice in pairs(allVoice) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
            for _, voice in ipairs(characterVoice) do
                if XFavorabilityManager.CheckCharacterVoiceUnlock(voice,trustLv) then
                    XFavorabilityManager.OnUnlockCharacterVoice(characterId, voice.Id)
                end
            end
        end

        --动作
        local allAction = XFavorabilityConfigs.GetCharacterAction()
        for characterId, characterAction in pairs(allAction) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
            for _, action in ipairs(characterAction) do
                if XFavorabilityManager.CheckCharacterActionUnlock(action,trustLv) then
                    XFavorabilityManager.OnUnlockCharacterAction(characterId, action.Id)
                end
            end
        end

        --XFavorabilityManager.InitEventListener()
    end


    function XFavorabilityManager.InitEventListener()
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, function(characterId)
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.FirstTimeObtain)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_LEVEL_UP, function(characterId)
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.LevelUp)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_QUALITY_PROMOTE, function(characterId)
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.Evolve)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_GRADE, function(characterId)
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.GradeUp)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SKILL_UP, function(characterId)
            XFavorabilityManager.PlayCharacterSkillUpOrUnlockCv(characterId)
        end)
        
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, function(characterId)
            XFavorabilityManager.PlayCharacterSkillUpOrUnlockCv(characterId)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_PUTON_WEAPON_NOTYFY, function(characterId)
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.WearWeapon)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function(characterId)
            XFavorabilityManager.Init()
            -- XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.WearWeapon)
        end)

        XEventManager.AddEventListener(XEventId.EVENT_TEAM_MEMBER_CHANGE, function(curTeamId, characterId, isCaptain)
            if characterId == 0 then return end
            local soundEventType = isCaptain and XFavorabilityConfigs.SoundEventType.CaptainJoinTeam
            or XFavorabilityConfigs.SoundEventType.MemberJoinTeam
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, soundEventType)
        end)
    end

    function XFavorabilityManager.GetFavorabilityColorWorld(trustLv, name)
        return XFavorabilityConfigs.GetWordsWithColor(trustLv, name)
    end
    
    function XFavorabilityManager.ResetLastPlaySkillCvTime()
        LastPlaySkillCvTime = 0
    end
    
    function XFavorabilityManager.PlayCharacterSkillUpOrUnlockCv(characterId)
        local now = XTime.GetServerNowTimestamp()
        if now - LastPlaySkillCvTime < SkillCvTimeLimit then
            return
        end
        LastPlaySkillCvTime = now
        XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.SkillUp)
    end

    -- [获得好感度面板信息]
    function XFavorabilityManager.GetNameWithTitleById(characterId)
        local currCharacterName = XCharacterConfigs.GetCharacterName(characterId)
        --local currCharacterTitle = XCharacterConfigs.GetCharacterTradeName(characterId)
        --return XFavorabilityConfigs.GetCharacterNameWithTitle(currCharacterName, currCharacterTitle)
        return currCharacterName
    end


    function XFavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
        if characterId == nil then
            return 1
        end

        local currCharacterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if currCharacterData == nil then
            return 1
        end

        return currCharacterData.TrustLv or 1
    end

    function XFavorabilityManager.GetCurrCharacterExp(characterId)
        if characterId == nil then
            return 0
        end

        local currCharacterData = XDataCenter.CharacterManager.GetCharacter(characterId)

        if currCharacterData == nil then
            return 0
        end
        return currCharacterData.TrustExp or 0
    end

    function XFavorabilityManager.GetCharacterTrustExpById(characterId)
        local currCharacterData = XDataCenter.CharacterManager.GetCharacter(characterId)

        if currCharacterData == nil then
            return 0
        end
        return currCharacterData.TrustExp or 0
    end

    --获取好感度最高的角色Id
    function XFavorabilityManager.GetHighestTrustExpCharacter()
        local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
        local char = nil
        local highestExp = -1
        for _, v in pairs(characters) do
            --  local exp = XFavorabilityManager.GetCharacterTrustExpById(v.Id)
            local level = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(v.Id)
            --  local num = exp + level * 100000 --权重
            if char and level == highestExp then
                if char.Level == v.Level then

                    if char.CreateTime == v.CreateTime then
                        if char.Id > v.Id then
                            highestExp = level
                            char = v
                        end
                    elseif char.CreateTime > v.CreateTime then
                        highestExp = level
                        char = v
                    end

                elseif char.Level < v.Level then
                    highestExp = level
                    char = v
                end

            elseif level > highestExp then
                char = v
                highestExp = level
            end
        end

        return char.Id
    end
    -- [获取好感度等级经验表数据]
    function XFavorabilityManager.GetFavorabilityTableData(characterId)
        local curTrustExp = XFavorabilityConfigs.GetTrustExpById(characterId)
        if curTrustExp == nil then
            return
        end
        local currLevel = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
        return curTrustExp[currLevel]
    end

    -- [资料是否已经解锁]
    function XFavorabilityManager.IsInformationUnlock(characterId, infoId)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockInformation == nil then return false end
        return favorabilityDatas.UnlockInformation[infoId]
    end

    -- [资料是否可以解锁]
    function XFavorabilityManager.CanInformationUnlock(characterId, infoId)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1
        local characterUnlockLvs = XFavorabilityConfigs.GetCharacterInformationUnlockLvById(characterId)
        if characterUnlockLvs and characterUnlockLvs[infoId] then
            return trustLv >= characterUnlockLvs[infoId]
        end
        return false
    end

    -- [异闻是否解锁]
    function XFavorabilityManager.IsRumorUnlock(characterId, rumorId)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockStrangeNews == nil then return false end
        return favorabilityDatas.UnlockStrangeNews[rumorId]
    end
    -- [异闻是否可以解锁]
    function XFavorabilityManager.CanRumorsUnlock(characterId, unlockType, unlockParam)
        if UnlockStrangeNewsFunc[unlockType] then
            return UnlockStrangeNewsFunc[unlockType](characterId, unlockParam)
        end
        return false
    end

    -- [语音是否解锁]
    function XFavorabilityManager.IsVoiceUnlock(characterId, Id)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockVoice == nil then return false end
        return favorabilityDatas.UnlockVoice[Id]
    end

    -- [语音是否可以解锁]
    function XFavorabilityManager.CanVoiceUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1
        -- voiceDatas 只含有 UnlockLv 和 UnlockCondition
        local voiceDatas = XFavorabilityConfigs.GetCharacterVoiceUnlockLvsById(characterId)
        if voiceDatas and voiceDatas[Id] then
            return XFavorabilityManager.CheckCharacterVoiceUnlock(voiceDatas[Id],trustLv)
        end
        return false
    end

    -- [动作是否解锁]
    function XFavorabilityManager.IsActionUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1
        local actionDatas = XFavorabilityConfigs.GetCharacterActionUnlockLvsById(characterId)
        if actionDatas and actionDatas[Id] then
            if not XFavorabilityManager.CheckCharacterActionUnlock(actionDatas[Id],trustLv) then
                return false
            end
        end

        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockAction == nil then return false end
        return favorabilityDatas.UnlockAction[Id]
    end

    -- [动作是否可以解锁]
    function XFavorabilityManager.CanActionUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1
        -- actionDatas 只含有 UnlockLv 和 UnlockCondition
        local actionDatas = XFavorabilityConfigs.GetCharacterActionUnlockLvsById(characterId)
        if actionDatas and actionDatas[Id] then
            return XFavorabilityManager.CheckCharacterActionUnlock(actionDatas[Id],trustLv)
        end
        return false
    end

    -- 【档案end】
    -- 【剧情begin】
    -- [剧情是否已经解锁]
    function XFavorabilityManager.IsStoryUnlock(characterId, Id)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockStory == nil then return false end
        return favorabilityDatas.UnlockStory[Id]
    end

    -- [剧情剧情是否可以解锁]
    function XFavorabilityManager.CanStoryUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local storys = XFavorabilityConfigs.GetCharacterStoryUnlockLvsById(characterId)
        if storys == nil then return false end
        local storyUnlockLv = storys[Id] or 1
        local trustLv = characterData.TrustLv or 1
        return trustLv >= storyUnlockLv
    end

    -- 【剧情end】
    -- 【礼物begin】
    function XFavorabilityManager.SortTrustItems(itemA, itemB)
        local itemAPriority = XDataCenter.ItemManager.GetItemPriority(itemA.Id) or 0
        local itemBPriority = XDataCenter.ItemManager.GetItemPriority(itemB.Id) or 0

        if itemA.IsFavourWeight == itemB.IsFavourWeight then
            if itemA.TrustItemQuality == itemB.TrustItemQuality then
                if itemAPriority == itemBPriority then
                    return itemA.Id > itemB.Id
                end
                return itemAPriority > itemBPriority
            end
            return itemA.TrustItemQuality > itemB.TrustItemQuality
        end
        return itemA.IsFavourWeight > itemB.IsFavourWeight
    end

    -- 可领取>未解锁>已领取>id排序，权重1,2,3
    local sortTrustItemReward = function(rewardA, rewardB)
        local aWeight = rewardA.Weight or 3
        local bWeight = rewardB.Weight or 3
        if aWeight == bWeight then
            return rewardA.Id < rewardB.Id
        else
            return aWeight < bWeight
        end
    end

    -- [获取奖励道具的列表：排序]
    function XFavorabilityManager.GetTrustItemRewardById(characterId)
        local currRewardDatas = XFavorabilityConfigs.GetCharacterGiftRewardById(characterId)
        for _, v in pairs(currRewardDatas) do
            if XFavorabilityManager.IsRewardCollected(characterId, v.Id) then
                v.Weight = 3
            else
                if XFavorabilityManager.CanRewardUnlock(characterId, v.UnlockType, v.UnlockPara) then--可领取
                    v.Weight = 1
                else
                    v.Weight = 2
                end
            end
        end
        table.sort(currRewardDatas, sortTrustItemReward)
        return currRewardDatas
    end

    -- [角色奖励是否已经领取]
    function XFavorabilityManager.IsRewardCollected(characterId, rewardId)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockReward == nil then return false end
        return favorabilityDatas.UnlockReward[rewardId]
    end

    -- [奖励是否可以解锁]
    function XFavorabilityManager.CanRewardUnlock(characterId, unlockType, unlockParam)
        if UnlockRewardFunc[unlockType] then
            return UnlockRewardFunc[unlockType](characterId, unlockParam)
        end
        return false
    end

    -- [添加ID至已经给过特殊礼物的构造体名单]
    function XFavorabilityManager.AddGivenItemCharacterId(characterId)
        local groupId = XFavorabilityConfigs.GetCharacterGroupId(characterId)
        if not XTool.IsNumberValid(groupId) then return end
        GivenItemCharacterIdList[groupId] = true
    end

    -- [初始化520活动数据]
    function XFavorabilityManager.NotifyFiveTwentyRecord(data)
        FestivalActivityMailId = data.ActivityNo
        for _, groupId in ipairs(data.GroupRecord or {}) do
            GivenItemCharacterIdList[groupId] = true
        end
    end

    -- [检查目标ID是否存在于一给过特殊礼物的构造体名单中]
    function XFavorabilityManager.IsInGivenItemCharacterIdList(characterId)
        --联动角色类型（0则不是联动角色）
        local linkageType = XCharacterConfigs.GetCharacterLinkageType(characterId)
        --跳过联动角色判断
        if XTool.IsNumberValid(linkageType) then
            return false
        end
        local groupId = XFavorabilityConfigs.GetCharacterGroupId(characterId)
        if not XTool.IsNumberValid(groupId) then return end
        local IsIn = GivenItemCharacterIdList[groupId]
        return IsIn and IsIn or false
    end
    
    --==============================
     ---@desc 当前节日邮件活动是否开启
     ---@return boolean
    --==============================
    function XFavorabilityManager.IsDuringOfFestivalMail()
        return XFavorabilityConfigs.IsDuringOfFestivalMail(FestivalActivityMailId)
    end
    -- 【礼物begin】
    -- 【Rpc相关】
    -- [领取角色奖励]
    function XFavorabilityManager.OnCollectCharacterReward(templateId, rewardId, cb)
        XNetwork.Call("CharacterUnlockRewardRequest", { TemplateId = templateId, Id = rewardId }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
                if characterFavorabilityDatas and characterFavorabilityDatas.UnlockReward then
                    characterFavorabilityDatas.UnlockReward[rewardId] = true
                end

                cb()
                XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_COLLECTGIFT)
                local rewards = XFavorabilityConfigs.GetLikeRewardById(rewardId)
                if rewards then
                    local list = {}
                    table.insert(list, XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = rewards.ItemId, Count = rewards.ItemCount }))
                    XUiManager.OpenUiObtain(list)
                end

            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    -- [解锁剧情]解锁成功，返回0，重新登陆数据会绑定再character上，不重新登陆也会有最新的数据绑到character
    function XFavorabilityManager.OnUnlockCharacterStory(templateId, storyId)
        local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
        if characterFavorabilityDatas and characterFavorabilityDatas.UnlockStory then
            characterFavorabilityDatas.UnlockStory[storyId] = true
        end
    end

    -- [解锁数据]
    function XFavorabilityManager.OnUnlockCharacterInfomatin(templateId, infoId)
        local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
        if characterFavorabilityDatas and characterFavorabilityDatas.UnlockInformation then
            characterFavorabilityDatas.UnlockInformation[infoId] = true
        end
    end

    -- [解锁异闻]
    function XFavorabilityManager.OnUnlockCharacterRumor(templateId, rumorId)
        local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
        if characterFavorabilityDatas and characterFavorabilityDatas.UnlockStrangeNews then
            characterFavorabilityDatas.UnlockStrangeNews[rumorId] = true
        end
    end

    -- [解锁语音]
    function XFavorabilityManager.OnUnlockCharacterVoice(templateId, cvId)
        local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
        if characterFavorabilityDatas and characterFavorabilityDatas.UnlockVoice then
            characterFavorabilityDatas.UnlockVoice[cvId] = true
        end
    end

    -- [解锁动作]
    function XFavorabilityManager.OnUnlockCharacterAction(templateId, actionId)
        local characterFavorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(templateId)
        if characterFavorabilityDatas and characterFavorabilityDatas.UnlockAction then
            characterFavorabilityDatas.UnlockAction[actionId] = true
        end
    end
    
    -- [检查语音是否满足解锁条件]
    function XFavorabilityManager.CheckCharacterVoiceUnlock(voiceData, trustLv)
        return voiceData.UnlockLv <= trustLv and (voiceData.UnlockCondition == 0 or XConditionManager.CheckCondition(voiceData.UnlockCondition,voiceData.CharacterId))
    end

    -- [检查动作是否满足解锁条件]
    function XFavorabilityManager.CheckCharacterActionUnlock(actionData, trustLv)
        -- return actionData.UnlockLv <= trustLv and (actionData.UnlockCondition == 0 or XConditionManager.CheckCondition(actionData.UnlockCondition,actionData.CharacterId))
        local isUnlock = true
        for k, conditionId in pairs(actionData.UnlockCondition) do
           if not XConditionManager.CheckCondition(conditionId, actionData.CharacterId) then
               isUnlock = false
               break
           end
        end
        return actionData.UnlockLv <= trustLv and isUnlock
    end

    -- [试穿][检查动作是否满足解锁条件]
    --- func desc
    ---@param fashionId 试穿的时装id
    function XFavorabilityManager.CheckTryCharacterActionUnlock(actionData, trustLv, tryFashionId, trySceneId)
        if not tryFashionId then
            return false
        end

        local isUnlock = true
        for k, conditionId in pairs(actionData.UnlockCondition) do
            if not XConditionManager.CheckCondition(conditionId, actionData.CharacterId, tryFashionId, trySceneId) then
                isUnlock = false
                break
            end
        end
        return actionData.UnlockLv <= trustLv and isUnlock
    end
    
    -- [使用SignBoardActionId判断动作是否满足解锁条件]
    function XFavorabilityManager.CheckCharacterActionUnlockBySignBoardActionId(signBoardActionId)
        local actionData = XFavorabilityConfigs.GetCharacterActionBySignBoardActionId(signBoardActionId)
        --若动作本身跟好感度系统没有关联 则直接播放
        if actionData == nil then return true end 
        local characterId = actionData.CharacterId
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local trustLv = 1
        if characterData then
            trustLv = characterData.TrustLv or 1
        end
        return XDataCenter.FavorabilityManager.CheckCharacterActionUnlock(actionData, trustLv) , actionData.ConditionDescript
    end

    -- [传入一段SignBoardAction数据(XSignBoardConfigs中获取)，输出其中已经解锁的数据]
    function XFavorabilityManager.FilterSignBoardActionsByFavorabilityUnlock(signBoardActionDatas)
        local unlockActions = {}
        for _,v in ipairs(signBoardActionDatas) do
            if XFavorabilityManager.CheckCharacterActionUnlockBySignBoardActionId(v.Id) then
                table.insert(unlockActions,v)
            end
        end
        return unlockActions
    end
    
    -- [发送礼物]
    function XFavorabilityManager.OnSendCharacterGift(args, cb)
        local gitfs = {}

        for k, v in pairs(args.GiftItems) do
            gitfs[k] = v
        end

        XMessagePack.MarkAsTable(gitfs)

        XNetwork.Call("CharacterSendGiftRequest", { TemplateId = args.CharacterId, GiftItems = gitfs }, function(res)
            cb = cb or function() end
            if res.Code == XCode.Success then
                cb(res)
                XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_GIFT, args.CharacterId)
            else
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    -- [通知更新角色信赖度等级和经验]
    function XFavorabilityManager.OnCharacterTrustInfoUpdate(response)
        local characterData = XDataCenter.CharacterManager.GetCharacter(response.TemplateId)
        if characterData then
            -- 等级变化
            local trustLvHasChanged = characterData.TrustLv ~= response.TrustLv
            characterData.TrustLv = response.TrustLv
            characterData.TrustExp = response.TrustExp
            if trustLvHasChanged then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_LEVELCHANGED, response.TrustLv)
                XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_LEVELCHANGED)
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_MAIN_REFRESH)
        end
    end

    -- [看板交互]
    function XFavorabilityManager.BoardMutualRequest()
        XNetwork.Send("BoardMutualRequest", {})
    end

    function XFavorabilityManager.IsMaxFavorabilityLevel(characterId)
        local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
        local maxLv = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
        return trustLv == maxLv
    end

    -- 【红点相关】
    -- [某个角色是否有资料可以解锁]
    function XFavorabilityManager.HasDataToBeUnlock(characterId)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local characterTrustLv = characterData.TrustLv or 1

        local informationDatas = XFavorabilityConfigs.GetCharacterInformationById(characterId)
        if informationDatas == nil then return false end

        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockInformation == nil then return false end

        for _, info in pairs(informationDatas) do
            local isUnlock = favorabilityDatas.UnlockInformation[info.Id]
            local canUnlock = characterTrustLv >= info.UnlockLv
            if (not isUnlock) and canUnlock then
                return true
            end
        end
        return false
    end

    -- [某个角色是否有异闻可以解锁]
    function XFavorabilityManager.HasRumorsToBeUnlock(characterId)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)

        if characterData == nil then return false end
        local rumors = XFavorabilityConfigs.GetCharacterRumorsById(characterId)
        if rumors == nil then return false end

        for _, news in pairs(rumors) do
            local isNewsUnlock = XFavorabilityManager.IsRumorUnlock(characterId, news.Id)
            local canNewsUnlock = XFavorabilityManager.CanRumorsUnlock(characterId, news.UnlockType, news.UnlockPara)
            if (not isNewsUnlock) and canNewsUnlock then
                return true
            end
        end
        return false
    end
    -- [某个角色是否有语音可以解锁]
    function XFavorabilityManager.HasAudioToBeUnlock(characterId)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1

        local voices = XFavorabilityConfigs.GetCharacterVoiceById(characterId)
        if voices == nil then return false end

        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockVoice == nil then return false end

        for _, voice in pairs(voices) do
            local isVoiceUnlock = favorabilityDatas.UnlockVoice[voice.Id]
            local canVoiceUnlock = XFavorabilityManager.CheckCharacterVoiceUnlock(voice,trustLv)
            if (not isVoiceUnlock) and canVoiceUnlock then
                return true
            end
        end
        return false
    end
    -- [某个角色是否有动作可以解锁]
    function XFavorabilityManager.HasActionToBeUnlock(characterId)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1

        local actions = XFavorabilityConfigs.GetCharacterActionById(characterId)
        if actions == nil then return false end

        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockAction == nil then return false end

        for _, action in pairs(actions) do
            local isActionUnlock = favorabilityDatas.UnlockAction[action.Id]
            local canVoiceUnlock = XFavorabilityManager.CheckCharacterActionUnlock(action,trustLv)
            if (not isActionUnlock) and canVoiceUnlock then
                return true
            end
        end
        return false
    end
    -- [某个/当前角色是否有剧情可以解锁]
    function XFavorabilityManager.HasStroyToBeUnlock(characterId)
        local storys = XFavorabilityConfigs.GetCharacterStoryById(characterId)
        if storys == nil then return false end

        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local characterTrustLv = characterData.TrustLv or 1

        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockStory == nil then return false end

        for _, story in pairs(storys) do
            local isStoryUnlock = favorabilityDatas.UnlockStory[story.Id]
            local canStoryUnlock = characterTrustLv >= story.UnlockLv
            if (not isStoryUnlock) and canStoryUnlock then
                return true
            end
        end
        return false
    end

    -- [剧情是否可以解锁]
    function XFavorabilityManager.CanStoryUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local characterLv = characterData.TrustLv or 1

        local storys = XFavorabilityConfigs.GetCharacterStoryUnlockLvsById(characterId)
        if storys == nil then return false end
        local storyLv = storys[Id] or 1

        return characterLv >= storyLv
    end

    -- [播放特殊事件音效]
    local PlayingCvId = nil
    local PlayingCvInfo = nil
    function XFavorabilityManager.PlayCvByType(characterId, soundType)
        if not characterId or characterId == 0 then return end

        --local voices = XFavorabilityConfigs.GetCharacterVoiceById(characterId)
        local voices = XFavorabilityConfigs.GetCharacterVoiceUnlockLvsById(characterId)
        if not voices then
            XLog.Error("角色Id为"..characterId.."的好感语音找不到")
            return
        end
        for _, voice in pairs(voices) do
            if voice.SoundType == soundType then
                local cvId = voice.CvId

                if PlayingCvId and PlayingCvId == cvId then return end
                PlayingCvId = cvId

                PlayingCvInfo = CS.XAudioManager.PlayCv(voice.CvId, function()
                    PlayingCvId = nil
                end)

                return
            end
        end
    end

    function XFavorabilityManager.StopCv()
        if not PlayingCvInfo or not PlayingCvInfo.Playing then return end
        PlayingCvInfo:Stop()
        PlayingCvId = nil
        PlayingCvInfo = nil
    end

    function XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)

        local datas = CharacterFavorabilityDatas[characterId]
        if not datas then
            datas = {}
            datas.UnlockInformation = {}
            datas.UnlockStory = {}
            datas.UnlockReward = {}
            datas.UnlockVoice = {}
            datas.UnlockStrangeNews = {}
            datas.UnlockAction = {}
            CharacterFavorabilityDatas[characterId] = datas
        end

        return CharacterFavorabilityDatas[characterId]
    end

    function XFavorabilityManager.GetFavorabilitySkipIds()
        local skip_size = ClientConfig:GetInt("FavorabilitySkipSize")
        local skipIds = {}
        for i = 1, skip_size do
            table.insert(skipIds, ClientConfig:GetInt(string.format("FavorabilitySkip%d", i)))
        end

        return skipIds
    end

    function XFavorabilityManager.SetDontStopCvContent(value)
        DontStopCvContent = value
    end

    function XFavorabilityManager.GetDontStopCvContent()
        return DontStopCvContent
    end

    XFavorabilityManager.InitEventListener()

    return XFavorabilityManager
end
-- [更新好感度等级，经验]
XRpc.NotifyCharacterTrustInfo = function(response)
    XDataCenter.FavorabilityManager.OnCharacterTrustInfoUpdate(response)
end

XRpc.NotifyCharacterExtraData = function(response)
    --XDataCenter.FavorabilityManager.OnCharacterFavorabilityDatasAsync(response)
end

XRpc.NotifyFiveTwentyRecord = function(response)
    XDataCenter.FavorabilityManager.NotifyFiveTwentyRecord(response)
end