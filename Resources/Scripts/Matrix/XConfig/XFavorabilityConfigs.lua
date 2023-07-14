XFavorabilityConfigs = XFavorabilityConfigs or {}

XFavorabilityConfigs.RewardUnlockType = {
    FightAbility = 1,
    TrustLv = 2,
    CharacterLv = 3,
    Quality = 4,
}

XFavorabilityConfigs.InfoState = {
    Normal = 1,
    Available = 2,
    Lock = 3,
}

XFavorabilityConfigs.StrangeNewsUnlockType = {
    TrustLv = 1,
    DormEvent = 2,
}

XFavorabilityConfigs.SoundEventType = {
    FirstTimeObtain = 1, -- 首次获得角色
    LevelUp = 2, -- 角色升级
    Evolve = 3, -- 角色进化
    GradeUp = 4, -- 角色升军阶
    SkillUp = 5, -- 角色技能升级
    WearWeapon = 6, -- 角色穿戴武器
    MemberJoinTeam = 7, --角色入队(队员)
    CaptainJoinTeam = 8, --角色入队（队长）
}

XFavorabilityConfigs.TrustItemType = {
    Normal = 1, -- 普通
    Communication = 2, -- 触发通讯的道具
}

-- [礼物品质]
XFavorabilityConfigs.GiftQualityIcon = {
    [1] = CS.XGame.ClientConfig:GetString("QualityIconColor1"),
    [2] = CS.XGame.ClientConfig:GetString("QualityIconColor2"),
    [3] = CS.XGame.ClientConfig:GetString("QualityIconColor3"),
    [4] = CS.XGame.ClientConfig:GetString("QualityIconColor4"),
    [5] = CS.XGame.ClientConfig:GetString("QualityIconColor5"),
    [6] = CS.XGame.ClientConfig:GetString("QualityIconColor6"),
}

local TABLE_LIKE_BASEDATA = "Client/Trust/CharacterBaseData.tab"
local TABLE_LIKE_INFORMATION = "Client/Trust/CharacterInformation.tab"
local TABLE_LIKE_STORY = "Client/Trust/CharacterStory.tab"
local TABLE_LIKE_STRANGENEWS = "Client/Trust/CharacterStrangeNews.tab"
local TABLE_LIKE_TRUSTEXP = "Share/Trust/CharacterTrustExp.tab"
local TABLE_LIKE_TRUSTITEM = "Share/Trust/CharacterTrustItem.tab"
local TABLE_LIKE_VOICE = "Client/Trust/CharacterVoice.tab"
local TABLE_LIKE_LEVELCONFIG = "Share/Trust/FavorabilityLevelConfig.tab"
local TABLE_LIKE_ACTION = "Client/Trust/CharacterAction.tab"

--local TABLE_AUDIO_CV = "Client/Audio/Cv.tab"
local TABLE_CHARACTER_COLLABORATION = "Client/Trust/CharacterCollaboration.tab"

local CharacterFavorabilityConfig = {}
local CharacterTrustExp = {}
local CharacterBaseData = {}
local CharacterInformation = {}
local CharacterInformationUnlockLv = {}
local CharacterRumors = {}
local CharacterVoice = {}
local CharacterVoiceUnlockLv = {}
local CharacterStory = {}
local CharacterStoryUnlockLv = {}
local CharacterSendGift = {}
local CharacterGiftReward = {}
local likeReward = {}
local CharacterAction = {}
local CharacterActionUnlockLv = {}
local CharacterCollaboration = {}

--local AudioCV = {}
local DEFAULT_CV_TYPE = CS.XGame.Config:GetInt("DefaultCvType")

function XFavorabilityConfigs.Init()
    local baseData = XTableManager.ReadByIntKey(TABLE_LIKE_BASEDATA, XTable.XTableCharacterBaseData, "Id")
    for _, v in pairs(baseData) do
        if CharacterBaseData[v.CharacterId] == nil then
            CharacterBaseData[v.CharacterId] = {}
        end

        CharacterBaseData[v.CharacterId] = {
            CharacterId = v.CharacterId,
            BaseDataTitle = v.BaseDataTitle,
            BaseData = v.BaseData,
            Cast = v.Cast,
        }
    end

    local likeInformation = XTableManager.ReadByIntKey(TABLE_LIKE_INFORMATION, XTable.XTableCharacterInformation, "Id")
    for _, v in pairs(likeInformation) do
        if CharacterInformation[v.CharacterId] == nil then
            CharacterInformation[v.CharacterId] = {}
        end

        table.insert(CharacterInformation[v.CharacterId], {
            Id = v.Id,
            CharacterId = v.CharacterId,
            UnlockLv = v.UnlockLv,
            Title = v.Title,
            Content = v.Content,
            ConditionDescript = v.ConditionDescript
        })
        if CharacterInformationUnlockLv[v.CharacterId] == nil then
            CharacterInformationUnlockLv[v.CharacterId] = {}
        end
        CharacterInformationUnlockLv[v.CharacterId][v.Id] = v.UnlockLv

    end
    for _, characterDatas in pairs(CharacterInformation) do
        table.sort(characterDatas, function(infoA, infoB)
            if infoA.UnlockLv == infoB.UnlockLv then
                return infoA.Id < infoB.Id
            end
            return infoA.UnlockLv < infoB.UnlockLv
        end)
    end

    local likeStory = XTableManager.ReadByIntKey(TABLE_LIKE_STORY, XTable.XTableCharacterStory, "Id")
    for _, v in pairs(likeStory) do
        if CharacterStory[v.CharacterId] == nil then
            CharacterStory[v.CharacterId] = {}
        end
        table.insert(CharacterStory[v.CharacterId], {
            Id = v.Id,
            Name = v.Name,
            CharacterId = v.CharacterId,
            StoryId = v.StoryId,
            Icon = v.Icon,
            UnlockLv = v.UnlockLv,
            ConditionDescript = v.ConditionDescript,
            SectionNumber = v.SectionNumber,
        })

        if CharacterStoryUnlockLv[v.CharacterId] == nil then
            CharacterStoryUnlockLv[v.CharacterId] = {}
        end
        CharacterStoryUnlockLv[v.CharacterId][v.Id] = v.UnlockLv
    end
    for _, storys in pairs(CharacterStory) do
        table.sort(storys, function(storyA, storyB)
            if storyA.UnlockLv == storyB.UnlockLv then
                return storyA.Id < storyB.Id
            end
            return storyA.UnlockLv < storyB.UnlockLv
        end)
    end

    local likeStrangeNews = XTableManager.ReadByIntKey(TABLE_LIKE_STRANGENEWS, XTable.XTableCharacterStrangeNews, "Id")
    for _, v in pairs(likeStrangeNews) do
        if CharacterRumors[v.CharacterId] == nil then
            CharacterRumors[v.CharacterId] = {}
        end

        table.insert(CharacterRumors[v.CharacterId], {
            Id = v.Id,
            CharacterId = v.CharacterId,
            Type = v.Type,
            UnlockType = v.UnlockType,
            Title = v.Title,
            Content = v.Content,
            Picture = v.Picture,
            UnlockPara = v.UnlockPara,
            ConditionDescript = v.ConditionDescript,
            PreviewPicture = v.PreviewPicture
        })
    end
    for _, strangeNews in pairs(CharacterRumors) do
        table.sort(strangeNews, function(strangeNewsA, strangeNewsB)
            return strangeNewsA.Id < strangeNewsB.Id
        end)
    end

    local likeTrustExp = XTableManager.ReadByIntKey(TABLE_LIKE_TRUSTEXP, XTable.XTableCharacterTrustExp, "Id")
    for _, v in pairs(likeTrustExp) do
        if CharacterTrustExp[v.CharacterId] == nil then
            CharacterTrustExp[v.CharacterId] = {}
        end
        CharacterTrustExp[v.CharacterId][v.TrustLv] = {
            Exp = v.Exp,
            Name = v.Name,
            PlayId = v.PlayId
        }
    end

    local likeTrustItem = XTableManager.ReadByIntKey(TABLE_LIKE_TRUSTITEM, XTable.XTableCharacterTrustItem, "Id")
    for _, v in pairs(likeTrustItem) do
        table.insert(CharacterSendGift, {
            Id = v.Id,
            Exp = v.Exp,
            FavorCharacterId = v.FavorCharacterId,
            FavorExp = v.FavorExp,
            TrustItemType = v.TrustItemType,
        })
    end

    local likeVoice = XTableManager.ReadByIntKey(TABLE_LIKE_VOICE, XTable.XTableCharacterVoice, "Id")
    for _, v in pairs(likeVoice) do
        if v.IsShow == 1 then
            if CharacterVoice[v.CharacterId] == nil then
                CharacterVoice[v.CharacterId] = {}
            end
            table.insert(CharacterVoice[v.CharacterId], {
                Id = v.Id,
                CharacterId = v.CharacterId,
                Name = v.Name,
                CvId = v.CvId,
                UnlockLv = v.UnlockLv,
                ConditionDescript = v.ConditionDescript,
                SoundType = v.SoundType,
                IsShow = v.IsShow,
            })
        end
        if CharacterVoiceUnlockLv[v.CharacterId] == nil then
            CharacterVoiceUnlockLv[v.CharacterId] = {}
        end
        CharacterVoiceUnlockLv[v.CharacterId][v.Id] = v.UnlockLv

    end
    for _, v in pairs(CharacterVoice) do
        table.sort(v, XFavorabilityConfigs.SortVoice)
    end

    local likeAction = XTableManager.ReadByIntKey(TABLE_LIKE_ACTION, XTable.XTableCharacterAction, "Id")
    for _, v in pairs(likeAction) do
        if CharacterAction[v.CharacterId] == nil then
            CharacterAction[v.CharacterId] = {}
        end
        table.insert(CharacterAction[v.CharacterId], {
            Id = v.Id,
            CharacterId = v.CharacterId,
            Name = v.Name,
            SignBoardActionId = v.SignBoardActionId,
            UnlockLv = v.UnlockLv,
            ConditionDescript = v.ConditionDescript,
        })
        if CharacterActionUnlockLv[v.CharacterId] == nil then
            CharacterActionUnlockLv[v.CharacterId] = {}
        end
        CharacterActionUnlockLv[v.CharacterId][v.Id] = v.UnlockLv
    end
    for _, v in pairs(CharacterAction) do
        table.sort(v, function(item1, item2)
            if item1.UnlockLv == item2.UnlockLv then
                return item1.Id < item2.Id
            end
            return item1.UnlockLv < item2.UnlockLv
        end)
    end

    CharacterFavorabilityConfig = XTableManager.ReadByIntKey(TABLE_LIKE_LEVELCONFIG, XTable.XTableFavorabilityLevelConfig, "Id")
    CharacterCollaboration = XTableManager.ReadByIntKey(TABLE_CHARACTER_COLLABORATION, XTable.XTableCharacterCollaboration, "CharacterId")

    --AudioCV = XTableManager.ReadByIntKey(TABLE_AUDIO_CV, XTable.XTableCv, "Id")
end

function XFavorabilityConfigs.SortVoice(a, b)
    if a.UnlockLv == b.UnlockLv then
        return a.Id < b.Id
    end
    return a.UnlockLv < b.UnlockLv
end

-- [好感度等级经验]
function XFavorabilityConfigs.GetTrustExpById(characterId)
    local trustExp = CharacterTrustExp[characterId]
    if not trustExp then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetTrustExpById", "CharacterTrustExp",
        TABLE_LIKE_TRUSTEXP, "characterId", tostring(characterId))
        return
    end
    return trustExp
end

-- [好感度基础数据]
function XFavorabilityConfigs.GetCharacterBaseDataById(characterId)
    local baseData = CharacterBaseData[characterId]
    if not baseData then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetCharacterBaseDataById",
        "CharacterBaseData", TABLE_LIKE_BASEDATA, "characterId", characterId)
        return
    end
    return baseData
end

-- 获取cv名字
function XFavorabilityConfigs.GetCharacterCvById(characterId)
    local baseData = XFavorabilityConfigs.GetCharacterBaseDataById(characterId)
    if not baseData then return "" end

    local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", DEFAULT_CV_TYPE)
    if baseData.Cast and baseData.Cast[cvType] then return baseData.Cast[cvType] end
    return ""
end

-- 获取cv名字
function XFavorabilityConfigs.GetCharacterCvByIdAndType(characterId, cvType)
    local baseData = XFavorabilityConfigs.GetCharacterBaseDataById(characterId)
    if not baseData then return "" end

    if baseData.Cast and baseData.Cast[cvType] then return baseData.Cast[cvType] end
    return ""
end

-- [好感度档案-资料]
function XFavorabilityConfigs.GetCharacterInformationById(characterId)
    local information = CharacterInformation[characterId]
    return information
end

--获取档案
function XFavorabilityConfigs.GetCharacterInformation()
    return CharacterInformation
end


-- [好感度档案-资料解锁等级]
function XFavorabilityConfigs.GetCharacterInformationUnlockLvById(characterId)
    local informationUnlockDatas = CharacterInformationUnlockLv[characterId]
    if not informationUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetCharacterInformationUnlockLvById",
        "UnlockLv", TABLE_LIKE_INFORMATION, "characterId", tostring(characterId))
        return
    end
    return informationUnlockDatas
end

-- [好感度档案-异闻]
function XFavorabilityConfigs.GetCharacterRumorsById(characterId)
    local rumors = CharacterRumors[characterId]
    return rumors
end

--获取异闻
function XFavorabilityConfigs.GetCharacterRumors()
    return CharacterRumors
end

--获取剧情
function XFavorabilityConfigs.GetCharacterStory()
    return CharacterStory
end

--获取语音
function XFavorabilityConfigs.GetCharacterVoice()
    return CharacterVoice
end

--获取动作
function XFavorabilityConfigs.GetCharacterAction()
    return CharacterAction
end

-- [好感度档案-动作]
function XFavorabilityConfigs.GetCharacterActionById(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
    end
    local action = CharacterAction[characterId]
    return action
end

-- [好感度档案-动作解锁等级]
function XFavorabilityConfigs.GetCharacterActionUnlockLvsById(characterId)
    local actionUnlockDatas = CharacterActionUnlockLv[characterId]
    if not actionUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetCharacterActionUnlockLvsById",
        "CharacterActionUnlockLv", TABLE_LIKE_ACTION, "characterId", tostring(characterId))
        return
    end
    return actionUnlockDatas
end

-- [好感度档案-语音]
function XFavorabilityConfigs.GetCharacterVoiceById(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
    end
    local voice = CharacterVoice[characterId]
    return voice
end

-- [好感度档案-语音解锁等级]
function XFavorabilityConfigs.GetCharacterVoiceUnlockLvsById(characterId)
    local voiceUnlockDatas = CharacterVoiceUnlockLv[characterId]
    if not voiceUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetCharacterVoiceUnlockLvsById",
        "CharacterVoiceUnlockLv", TABLE_LIKE_VOICE, "characterId", tostring(characterId))
        return
    end
    return voiceUnlockDatas
end

-- [好感度剧情]
function XFavorabilityConfigs.GetCharacterStoryById(characterId)
    local storys = CharacterStory[characterId]
    return storys
end

-- [好感度剧情解锁等级]
function XFavorabilityConfigs.GetCharacterStoryUnlockLvsById(characterId)
    local storyUnlockDatas = CharacterStoryUnlockLv[characterId]
    if not storyUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetCharacterStoryUnlockLvsById",
        "CharacterStoryUnlockLv", TABLE_LIKE_STORY, "characterId", tostring(characterId))
        return
    end
    return storyUnlockDatas
end

-- [好感度礼物-送礼]
function XFavorabilityConfigs.GetAllCharacterSendGift()
    if not CharacterSendGift then
        XLog.Error("XFavorabilityConfigs.GetAllCharacterSendGift 函数错误, 配置表：" .. TABLE_LIKE_TRUSTITEM .. " 读取失败, 检查配置表")
        return
    end
    return CharacterSendGift
end

-- [好感度礼物-奖励]
function XFavorabilityConfigs.GetCharacterGiftRewardById(characterId)
    local giftReward = CharacterGiftReward[characterId]
    if not giftReward then
        XLog.Error("XFavorabilityConfigs.GetCharacterGiftRewardById error: not data found by characterId " .. tostring(characterId))
        return
    end
    return giftReward
end

function XFavorabilityConfigs.GetLikeRewardById(rewardId)
    if not likeReward then
        XLog.Error("XFavorabilityConfigs.GetLikeRewardById error: not data found by rewardId " .. tostring(rewardId))
        return
    end
    return likeReward[rewardId]
end

function XFavorabilityConfigs.GetFavorabilityLevelCfg(level)
    local cfgs = CharacterFavorabilityConfig[level]
    if not cfgs then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetFavorabilityLevelCfg",
        "CharacterFavorabilityConfig", TABLE_LIKE_LEVELCONFIG, "level", tostring(level))
    end
    return cfgs
end

-- CharacterFavorabilityConfig
-- [好感度-等级名字]
function XFavorabilityConfigs.GetWordsWithColor(trustLv, name)
    local color = XFavorabilityConfigs.GetFavorabilityLevelCfg(trustLv).WordColor
    return string.format("<color=%s>%s</color>", color, name)
end

-- [好感度-名字-称号]
function XFavorabilityConfigs.GetCharacterNameWithTitle(name, title)
    return string.format("%s <size=36>%s</size>", name, title)
end

-- [好感度-等级图标]
function XFavorabilityConfigs.GetTrustLevelIconByLevel(level)
    return XFavorabilityConfigs.GetFavorabilityLevelCfg(level).LevelIcon
end

-- [好感度-品质图标]
function XFavorabilityConfigs.GetQualityIconByQuality(quality)
    if quality == nil or XFavorabilityConfigs.GiftQualityIcon[quality] == nil then
        return XFavorabilityConfigs.GiftQualityIcon[1]
    end
    return XFavorabilityConfigs.GiftQualityIcon[quality]
end

function XFavorabilityConfigs.GetCvContent(cvId)
    local cvData = nil

    if CS.XAudioManager.CvTemplates:ContainsKey(cvId) then
        cvData = CS.XAudioManager.CvTemplates[cvId]
    end

    if not cvData then return "" end
    return cvData.CvContent[0] or ""
end

function XFavorabilityConfigs.GetCvContentByIdAndType(cvId, cvType)
    local cvData = nil

    if CS.XAudioManager.CvTemplates:ContainsKey(cvId) then
        cvData = CS.XAudioManager.CvTemplates[cvId]
    end

    if not cvData then return "" end
    return cvData.CvContent[cvType - 1] or ""
end

function XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
    local characterFavorabilityLevelDatas = CharacterTrustExp[characterId]
    if not characterFavorabilityLevelDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetMaxFavorabilityLevel",
        "CharacterTrustExp", TABLE_LIKE_TRUSTEXP, "characterId", tostring(characterId))
        return
    end
    local maxLevel = 1
    for trustLv, levelDatas in pairs(characterFavorabilityLevelDatas) do
        if levelDatas.Exp == 0 then
            maxLevel = trustLv
            break
        end
    end

    return maxLevel
end

function XFavorabilityConfigs.GetFavorabilityLevel(characterId, totalExp, startLevel)
    local characterFavorabilityLevelDatas = CharacterTrustExp[characterId]
    if not characterFavorabilityLevelDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityConfigs.GetMaxFavorabilityLevel",
        "CharacterTrustExp", TABLE_LIKE_TRUSTEXP, "characterId", tostring(characterId))
        return
    end
    startLevel = startLevel or 1
    local level = startLevel
    local leftExp = totalExp
    local levelExp = 0
    for trustLv, levelDatas in pairs(characterFavorabilityLevelDatas) do
        if startLevel <= trustLv then
            local exp = levelDatas.Exp
            levelExp = exp

            if exp == 0 then
                level = trustLv
                break
            end


            if leftExp < exp then
                level = trustLv
                break
            end

            if totalExp >= exp then
                leftExp = leftExp - exp
            end
        end
    end

    return level, leftExp, levelExp
end

--是不是联动角色
function XFavorabilityConfigs.IsCollaborationCharacter(characterId)
    return CharacterCollaboration[characterId]
end

--联动角色语种
function XFavorabilityConfigs.GetCollaborationCharacterCvType(characterId)
    if XFavorabilityConfigs.IsCollaborationCharacter(characterId) then
        local cvType = string.Split(CharacterCollaboration[characterId].languageSet, "|")

        for k, v in pairs(cvType) do
            cvType[k] = tonumber(v)
        end

        return cvType
    else
        return nil
    end
end

--联动角色语种提示
function XFavorabilityConfigs.GetCollaborationCharacterText(characterId)
    if XFavorabilityConfigs.IsCollaborationCharacter(characterId) then
        return CharacterCollaboration[characterId].Text
    else
        return nil
    end
end

--联动角色Logo
function XFavorabilityConfigs.GetCollaborationCharacterIcon(characterId)
    if XFavorabilityConfigs.IsCollaborationCharacter(characterId) then
        return CharacterCollaboration[characterId].IconPath
    else
        return nil
    end
end

--联动角色Logo位置
function XFavorabilityConfigs.GetCollaborationCharacterIconPos(characterId)
    if XFavorabilityConfigs.IsCollaborationCharacter(characterId) then
        local pos = {}
        pos.X = CharacterCollaboration[characterId].IconX
        pos.Y = CharacterCollaboration[characterId].IconY
        return pos
    else
        return nil
    end
end

--联动角色Logo缩放
function XFavorabilityConfigs.GetCollaborationCharacterIconScale(characterId)
    if XFavorabilityConfigs.IsCollaborationCharacter(characterId) then
        return CharacterCollaboration[characterId].IconScale
    else
        return nil
    end
end