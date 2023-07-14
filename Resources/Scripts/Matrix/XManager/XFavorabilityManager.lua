XFavorabilityManagerCreator = function()
    local XFavorabilityManager = {}
    local ClientConfig = CS.XGame.ClientConfig

    local CharacterFavorabilityDatas = {}

    local UnlockRewardFunc = {}

    local GivenItemCharacterIdList = {}

    -- 播放语音结束进行回调时，是否调用StopCvContent，语音正常播放结束时调用，查看动作打断语音时不调用
    local DontStopCvContent

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
        for id, v in pairs(allVoice) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(id)
            for _, var in ipairs(v) do
                if var.UnlockLv <= trustLv then
                    XFavorabilityManager.OnUnlockCharacterVoice(id, var.Id)
                end
            end
        end

        --动作
        local allAction = XFavorabilityConfigs.GetCharacterAction()
        for id, v in pairs(allAction) do
            local trustLv = XFavorabilityManager.GetCurrCharacterFavorabilityLevel(id)
            for _, var in ipairs(v) do
                if var.UnlockLv <= trustLv then
                    XFavorabilityManager.OnUnlockCharacterAction(id, var.Id)
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
            XDataCenter.FavorabilityManager.PlayCvByType(characterId, XFavorabilityConfigs.SoundEventType.SkillUp)
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

    -- [获得好感度面板信息]
    function XFavorabilityManager.GetNameWithTitleById(characterId) -- (海外定制)看板角色信息不显示title后缀，国服修改提前
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
        local voiceUnlockLvs = XFavorabilityConfigs.GetCharacterVoiceUnlockLvsById(characterId)
        if voiceUnlockLvs and voiceUnlockLvs[Id] then
            return trustLv >= voiceUnlockLvs[Id]
        end
        return false
    end

    -- [动作是否解锁]
    function XFavorabilityManager.IsActionUnlock(characterId, Id)
        local favorabilityDatas = XFavorabilityManager.GetCharacterFavorabilityDatasById(characterId)
        if favorabilityDatas == nil or favorabilityDatas.UnlockAction == nil then return false end
        return favorabilityDatas.UnlockAction[Id]
    end

    -- [动作是否可以解锁]
    function XFavorabilityManager.CanActionUnlock(characterId, Id)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        if characterData == nil then return false end
        local trustLv = characterData.TrustLv or 1
        local actionUnlockLvs = XFavorabilityConfigs.GetCharacterActionUnlockLvsById(characterId)
        if actionUnlockLvs and actionUnlockLvs[Id] then
            return trustLv >= actionUnlockLvs[Id]
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
        GivenItemCharacterIdList[characterId] = true
    end

    -- [添加ID至已经给过特殊礼物的构造体名单]
    function XFavorabilityManager.SetGivenItemCharacterId(characterIds)
        if not characterIds then return end
        for _, id in pairs(characterIds) do
            GivenItemCharacterIdList[id] = true
        end
    end

    -- [检查目标ID是否存在于一给过特殊礼物的构造体名单中]
    function XFavorabilityManager.IsInGivenItemCharacterIdList(characterId)
        local IsIn = GivenItemCharacterIdList[characterId]
        return IsIn and IsIn or false
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
            local canVoiceUnlock = trustLv >= voice.UnlockLv
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
            local canVoiceUnlock = trustLv >= action.UnlockLv
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

        local voices = XFavorabilityConfigs.GetCharacterVoiceById(characterId)
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
    XDataCenter.FavorabilityManager.SetGivenItemCharacterId(response.CharacterIds)
end