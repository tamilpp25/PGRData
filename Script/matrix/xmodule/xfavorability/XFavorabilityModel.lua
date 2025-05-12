---@class XFavorabilityModel : XModel
local XFavorabilityModel = XClass(XModel, "XFavorabilityModel")

local TABLE_LIKE_BASEDATA = "Client/Trust/CharacterBaseData.tab"
local TABLE_LIKE_INFORMATION = "Client/Trust/CharacterInformation.tab"
local TABLE_LIKE_STRANGENEWS = "Client/Trust/CharacterStrangeNews.tab"
local TABLE_LIKE_TRUSTEXP = "Share/Trust/CharacterTrustExp.tab"
local TABLE_LIKE_TRUSTITEM = "Share/Trust/CharacterTrustItem.tab"
local TABLE_LIKE_LEVELCONFIG = "Share/Trust/FavorabilityLevelConfig.tab"
local TABLE_CV_SPLIT = "Client/Audio/CvSplit.tab"
local TABLE_CV_SPLIT_RANGE = "Client/Audio/CvSplitRange.tab"
local TABLE_CHARACTER_GROUP = "Share/FestivalMail/FestivalCharacterGroup.tab"
local TABLE_FESTIVAL = "Share/FestivalMail/Festival.tab"
local TABLE_CHARACTER_COLLABORATION = "Client/Trust/CharacterCollaboration.tab"
local TABLE_SIGNBOARD_FEEDBACK = "Client/Signboard/SignBoardFeedback.tab";

local TableNormal = {
    CharacterVoiceContentMap = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterVoiceRange = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterVoice = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },

    CharacterActionContentMap = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterActionRange = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterAction = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterActionSignBoard = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

local TablePrivate = {
    CharacterTips = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    StoryLayoutBgType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type", ReadFunc = XConfigUtil.ReadType.Int },
    CharacterStoryStageDetailType = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Type", ReadFunc = XConfigUtil.ReadType.Int },
    StoryLayout = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId", ReadFunc = XConfigUtil.ReadType.Int },
}

local TableTemp = {
    CharacterStory = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

function XFavorabilityModel:OnInit()
    --初始化内部变量
    self._GiftQualityIcon = {
        [1] = CS.XGame.ClientConfig:GetString("QualityIconColor1"),
        [2] = CS.XGame.ClientConfig:GetString("QualityIconColor2"),
        [3] = CS.XGame.ClientConfig:GetString("QualityIconColor3"),
        [4] = CS.XGame.ClientConfig:GetString("QualityIconColor4"),
        [5] = CS.XGame.ClientConfig:GetString("QualityIconColor5"),
        [6] = CS.XGame.ClientConfig:GetString("QualityIconColor6"),
    }
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfig({
        [TABLE_CV_SPLIT]={XConfigUtil.ReadType.Int,XTable.XTableCvSplit,"Id",XConfigUtil.CacheType.Normal},
        [TABLE_CV_SPLIT_RANGE]={XConfigUtil.ReadType.Int,XTable.XTableCvSplitRange,"Id",XConfigUtil.CacheType.Normal},

        [TABLE_LIKE_BASEDATA]={XConfigUtil.ReadType.Int,XTable.XTableCharacterBaseData,"CharacterId",XConfigUtil.CacheType.Normal},
        [TABLE_SIGNBOARD_FEEDBACK]={XConfigUtil.ReadType.Int,XTable.XTableSignBoardFeedback,"Id",XConfigUtil.CacheType.Normal},
        
        [TABLE_CHARACTER_COLLABORATION]={XConfigUtil.ReadType.Int,XTable.XTableCharacterCollaboration,"CharacterId",XConfigUtil.CacheType.Normal},
        [TABLE_LIKE_TRUSTITEM]={XConfigUtil.ReadType.Int,XTable.XTableCharacterTrustItem,"Id",XConfigUtil.CacheType.Private},
        [TABLE_FESTIVAL]={XConfigUtil.ReadType.Int,XTable.XTableFestival,"Id",XConfigUtil.CacheType.Private},
        [TABLE_CHARACTER_GROUP]={XConfigUtil.ReadType.Int,XTable.XTableFestivalCharacterGroup,"CharacterId",XConfigUtil.CacheType.Private},
        [TABLE_LIKE_LEVELCONFIG]={XConfigUtil.ReadType.Int,XTable.XTableFavorabilityLevelConfig,"Id",XConfigUtil.CacheType.Normal},

        [TABLE_LIKE_INFORMATION]={XConfigUtil.ReadType.Int,XTable.XTableCharacterInformation, "Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_STRANGENEWS]={XConfigUtil.ReadType.Int,XTable.XTableCharacterStrangeNews,"Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_TRUSTEXP]={XConfigUtil.ReadType.Int,XTable.XTableCharacterTrustExp,"Id",XConfigUtil.CacheType.Temp},
    })

    self._ConfigUtil:InitConfigByTableKey('Trust', TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Trust', TableTemp, XConfigUtil.CacheType.Temp)
    self._ConfigUtil:InitConfigByTableKey('Trust', TablePrivate, XConfigUtil.CacheType.Private)
    
    self._CharacterInformation=nil
    self._CharacterInformationUnlockLv=nil
    self._CharacterStoryList = nil
    self._CharacterStoryDict = nil
    self._CharacterRumors=nil
    self._CharacterRumorsPriority=nil
    self._CharacterTrustExp=nil
    self._CharacterSendGift=nil
    self._CvSplit=nil
    
    self._CharacterShowVoiceLists=nil
    self._CharacterVoiceMaps=nil
    self._CharacterVoiceInitAll = false
    self._CharacterVoiceInitAny = false
    self._CharacterAction=nil
    self._CharacterActionUnlockLv=nil
    self._CharacterActionKeySignBoardActionId=nil
    self._CharacterActionInitAll = false
    self._CharacterActionInitAny = false
    
    --signBoard相关数据
    self._TableSignBoardRoleIdIndexs=nil
    self._TableSignBoardIndexs=nil
    self._TableSignBoardBreak=nil
    self._ChangeDisplayId = -1
    self._LoginTime=-1
    self._LastLoginTime = -1
    self._SignBoarEvents={}
    --默认 0 普通待机，1 待机站立
    self._StandType = 0
    self._PreLoginPlayedList = {}
    self._PlayerData=nil
    self._RequestTouchBoardLock=false
    self._Timer=nil
    self._StopTime=0
    self._Delay = 10
    ---@type XSignBoardCamAnim
    self._sceneAnim=require("XEntity/XSignBoard/XSignBoardCamAnim").New()
    self._PlayedList={}
    
    self._CharacterFavorabilityDatas= {}
    self._CharacterGiftReward={}
    self._likeReward={}
    self._GivenItemCharacterIdList={}
    self._FestivalActivityMailId = 0
    self._LastPlaySkillCvTime = 0
    
    self._PlayingCvId = nil
    self._PlayingCvInfo = nil
    self._DontStopCvContent=nil
end

function XFavorabilityModel:ClearPrivate()
    --这里执行内部数据清理
end

function XFavorabilityModel:ResetAll()
    --这里执行重登数据清理
    self._GiftQualityIcon = {
        [1] = CS.XGame.ClientConfig:GetString("QualityIconColor1"),
        [2] = CS.XGame.ClientConfig:GetString("QualityIconColor2"),
        [3] = CS.XGame.ClientConfig:GetString("QualityIconColor3"),
        [4] = CS.XGame.ClientConfig:GetString("QualityIconColor4"),
        [5] = CS.XGame.ClientConfig:GetString("QualityIconColor5"),
        [6] = CS.XGame.ClientConfig:GetString("QualityIconColor6"),
    }
    
    --clear private&secondary analysis table data
    self._CharacterInformation = nil
    self._CharacterInformationUnlockLv = nil
    self._CharacterStoryList = nil
    self._CharacterStoryDict = nil
    self._CharacterRumors = nil
    self._CharacterRumorsPriority = nil
    self._CharacterTrustExp = nil
    self._CharacterSendGift = nil
    self._DontStopCvContent = nil
    
    --clear nonpri&secondary analysis table data
    self._CharacterShowVoiceLists=nil
    self._CharacterVoiceMaps=nil
    self._CharacterVoiceInitAll = false
    self._CharacterVoiceInitAny = false
    self._CharacterAction=nil
    self._CharacterActionUnlockLv=nil
    self._CharacterActionKeySignBoardActionId=nil
    self._CharacterActionInitAll = false
    self._CharacterActionInitAny = false
    self._CvSplit=nil

    --clear gaming data
    self._CharacterFavorabilityDatas= {}
    self._CharacterGiftReward={}
    self._likeReward={}
    self._GivenItemCharacterIdList={}
    self._FestivalActivityMailId = 0
    self._LastPlaySkillCvTime = 0

    self._PlayingCvId = nil
    self._PlayingCvInfo = nil
    
    self._ConfigUtil:Clear(TABLE_LIKE_BASEDATA)

    self._ChangeDisplayId = -1
    self._LoginTime=-1
    self._LastLoginTime = -1
    self._SignBoarEvents={}
    self._StandType = 0
    self._PreLoginPlayedList = {}
    self._PlayerData=nil
    self._RequestTouchBoardLock=false
    self._Timer=nil
    self._StopTime=0
    self._Delay = 10
    self._sceneAnim=require("XEntity/XSignBoard/XSignBoardCamAnim").New()
    self._PlayedList={}
end

----------public start----------
function XFavorabilityModel:GetCharacterFavorabilityDatasById(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    
    local datas = self._CharacterFavorabilityDatas[characterId]
    if not datas then
        datas = {}
        datas.UnlockInformation = {}
        datas.UnlockStory = {}
        datas.UnlockReward = {}
        datas.UnlockVoice = {}
        datas.UnlockStrangeNews = {}
        datas.UnlockAction = {}
        self._CharacterFavorabilityDatas[characterId] = datas
    end

    return self._CharacterFavorabilityDatas[characterId]
end

--- 判断玩家好感度数据是否为空
function XFavorabilityModel:IsCharacterFavorabilityDatasEmpty()
    return XTool.IsTableEmpty(self._CharacterFavorabilityDatas)
end

--- 判断玩家指定角色的好感度数据是否为空
function XFavorabilityModel:CheckCharacterFavorabilityDatasIsEmpty(characterId)
    return XTool.IsTableEmpty(self._CharacterFavorabilityDatas) or XTool.IsTableEmpty(self._CharacterFavorabilityDatas[characterId])
end

function XFavorabilityModel:AddGivenItemByCharacterGroupId(groupId)
    self._GivenItemCharacterIdList[groupId]=true
end

function XFavorabilityModel:GetGivenItemByCharacterGroupId(groupId)
    return self._GivenItemCharacterIdList[groupId]
end

function XFavorabilityModel:SetFestivalActivityMailId(id)
    self._FestivalActivityMailId=id
end

function XFavorabilityModel:GetFestivalActivityMailId()
    return self._FestivalActivityMailId or 0
end
    
function XFavorabilityModel:ResetLastPlaySkillCvTime()
    self._LastPlaySkillCvTime = 0
end
----------public end----------

----------private start----------

---检查角色信息数据是否加载并处理
function XFavorabilityModel:CheckInformationDataDone()
    if XTool.IsTableEmpty(self._CharacterInformationUnlockLv) or XTool.IsTableEmpty(self._CharacterInformation) then
        --初始化归类
        self._CharacterInformationUnlockLv={}
        self._CharacterInformation={}
        local tab=self._ConfigUtil:Get(TABLE_LIKE_INFORMATION)
        for i, v in pairs(tab) do
            if self._CharacterInformation[v.CharacterId] == nil then
                self._CharacterInformation[v.CharacterId] = {}
            end
            local data={
                config=v
            }
            table.insert(self._CharacterInformation[v.CharacterId], data)

            if self._CharacterInformationUnlockLv[v.CharacterId] == nil then
                self._CharacterInformationUnlockLv[v.CharacterId] = {}
            end
            self._CharacterInformationUnlockLv[v.CharacterId][v.Id] = v.UnlockLv
        end
        --排序
        for _, characterDatas in pairs(self._CharacterInformation) do
            table.sort(characterDatas, function(infoA, infoB)
                if infoA.config.UnlockLv == infoB.config.UnlockLv then
                    return infoA.config.Id < infoB.config.Id
                end
                return infoA.config.UnlockLv < infoB.config.UnlockLv
            end)
        end
    end
end

function XFavorabilityModel:CheckRumorsDataDone()
    if XTool.IsTableEmpty(self._CharacterRumors) or XTool.IsTableEmpty(self._CharacterRumorsPriority) then
        self._CharacterRumors={}
        self._CharacterRumorsPriority= {}

        local tab=self._ConfigUtil:Get(TABLE_LIKE_STRANGENEWS)
        for _, v in pairs(tab) do
            if self._CharacterRumors[v.CharacterId] == nil then
                self._CharacterRumors[v.CharacterId] = {}
            end

            table.insert(self._CharacterRumors[v.CharacterId], v)

            self._CharacterRumorsPriority[v.Id]=2
        end

        
        for _, strangeNews in pairs(self._CharacterRumors) do
            table.sort(strangeNews, function(strangeNewsA, strangeNewsB)
                return strangeNewsA.Id < strangeNewsB.Id
            end)
        end
    end
end

function XFavorabilityModel:CheckTrustExpDataDone()
    if XTool.IsTableEmpty(self._CharacterTrustExp) then
        self._CharacterTrustExp={}
        local tab=self._ConfigUtil:Get(TABLE_LIKE_TRUSTEXP)
        for _, v in pairs(tab) do
            if self._CharacterTrustExp[v.CharacterId] == nil then
                self._CharacterTrustExp[v.CharacterId] = {}
            end
            self._CharacterTrustExp[v.CharacterId][v.TrustLv] = {
                Exp = v.Exp,
                Name = v.Name,
                PlayId = v.PlayId
            }
        end
    end
end

function XFavorabilityModel:CheckCharacterTrustItemDataDone()
    if XTool.IsTableEmpty(self._CharacterSendGift) then
        self._CharacterSendGift={}
        local CharacterLikeTrustItem = self._ConfigUtil:Get(TABLE_LIKE_TRUSTITEM)
        for _, v in pairs(CharacterLikeTrustItem) do
            local typeList = v.LimitLinkageType
            local dict = {}
            for _, linkageType in ipairs(typeList) do
                dict[linkageType] = true
            end
            local data={
                LimitLinkageTypeDict = dict
            }
            setmetatable(data,{__index=v})
            table.insert(self._CharacterSendGift, data)
        end
    end 
end

function XFavorabilityModel:CheckSignBoardDataDone()
    if XTool.IsTableEmpty(self._TableSignBoardRoleIdIndexs) or XTool.IsTableEmpty(self._TableSignBoardIndexs) then
        self._TableSignBoardRoleIdIndexs={}
        for _, var in pairs(self._ConfigUtil:Get(TABLE_SIGNBOARD_FEEDBACK)) do
            if not var.RoleId then
                self._TableSignBoardIndexs = self._TableSignBoardIndexs or {}
                self._TableSignBoardIndexs[var.ConditionId] = self._TableSignBoardIndexs[var.ConditionId] or {}
                table.insert(self._TableSignBoardIndexs[var.ConditionId], var)
            elseif var.RoleId == "None" then
                self._TableSignBoardBreak = var
            else
                local roleIds = string.Split(var.RoleId, "|")
                if roleIds then
                    for _, roleId in ipairs(roleIds) do
                        roleId = tonumber(roleId)
                        self._TableSignBoardRoleIdIndexs[roleId] = self._TableSignBoardRoleIdIndexs[roleId] or {}
                        self._TableSignBoardRoleIdIndexs[roleId][var.ConditionId] = self._TableSignBoardRoleIdIndexs[roleId][var.ConditionId] or {}
                        table.insert(self._TableSignBoardRoleIdIndexs[roleId][var.ConditionId], var)
                    end
                end
            end
        end
    end
end

----------private end----------

----------config start----------
function XFavorabilityModel:GetCharacterInformation()
    self:CheckInformationDataDone()
    return self._CharacterInformation
end

--获取异闻
function XFavorabilityModel:GetCharacterRumors()
    self:CheckRumorsDataDone()
    return self._CharacterRumors
end

function XFavorabilityModel:GetCharacterRumorsPriority()
    self:CheckRumorsDataDone()
    return self._CharacterRumorsPriority
end

--region ---------- 剧情故事 --------->>>
function XFavorabilityModel:GetCharacterStory()
    self:_CheckStoryDataInit()
    return self._CharacterStoryList
end

function XFavorabilityModel:_CheckStoryDataInit()
    if XTool.IsTableEmpty(self._CharacterStoryDict) or XTool.IsTableEmpty(self._CharacterStoryList) then
        --初始化归类
        self._CharacterStoryDict={}
        self._CharacterStoryList={}
        local tab = self:GetCharacterStoryCfgs()
        for i, v in pairs(tab) do
            if self._CharacterStoryList[v.CharacterId] == nil then
                self._CharacterStoryList[v.CharacterId] = {}
            end

            table.insert(self._CharacterStoryList[v.CharacterId], v)

            if self._CharacterStoryDict[v.CharacterId] == nil then
                self._CharacterStoryDict[v.CharacterId] = {}
            end
            self._CharacterStoryDict[v.CharacterId][v.Id] = v
        end

        --排序
        for i, storys in pairs(self._CharacterStoryList) do
            table.sort(storys, function(storyA, storyB)
                if storyA.UnlockLv == storyB.UnlockLv then
                    return storyA.Id < storyB.Id
                end
                return storyA.UnlockLv < storyB.UnlockLv
            end)
        end
    end
end

function XFavorabilityModel:GetCharacterStoryUnlockLvsById(characterId)
    self:_CheckStoryDataInit()
    local storyUnlockDatas = self._CharacterStoryDict[characterId]
    if not storyUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterStoryUnlockLvsById",
                "CharacterStoryUnlockLv", "Client/Trust/CharacterStory.tab", "characterId", tostring(characterId))
        return
    end
    return storyUnlockDatas
end

--- 剧情实际上是否满足解锁条件
function XFavorabilityModel:IsStorySatisfyUnlock(characterId, Id)
    local storyCfgs = self:GetCharacterStoryUnlockLvsById(characterId)
    
    if storyCfgs == nil or storyCfgs[Id] == nil then
        return false 
    end
    
    ---@type XTableCharacterStory
    local cfg = storyCfgs[Id]

    if XTool.IsNumberValid(cfg.StageId) then
        -- 如果配置了关卡，那么忽略其他配置约束，仅判断关卡是否解锁
        return XMVCA.XFuben:CheckStageIsUnlock(cfg.StageId)
    else
        -- 如果直接配置剧情Id，那么需要玩家拥有角色，且角色好感度满足配置约束
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        if characterData == nil then return false end

        local storyUnlockLv = cfg.UnlockLv or 1
        local trustLv = characterData.TrustLv or 1

        -- 是否满足信赖等级解锁条件
        local isAchieveTrustLv = trustLv >= storyUnlockLv
        
        return isAchieveTrustLv
    end
end

--- 剧情实际上是否满足通关条件
function XFavorabilityModel:IsStorySatisfyPass(characterId, Id)
    local storyCfgs = self:GetCharacterStoryUnlockLvsById(characterId)

    if storyCfgs == nil or storyCfgs[Id] == nil then
        return false
    end

    ---@type XTableCharacterStory
    local cfg = storyCfgs[Id]

    if XTool.IsNumberValid(cfg.StageId) then
        -- 如果配置了关卡，那么忽略其他配置约束，仅判断关卡是否通关
        return XMVCA.XFuben:CheckStageIsPass(cfg.StageId)
    else
        -- 如果直接配置剧情Id，那么需要玩家拥有角色，且角色好感度满足配置约束
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        if characterData == nil then return false end

        local storyUnlockLv = cfg.UnlockLv or 1
        local trustLv = characterData.TrustLv or 1

        -- 是否满足信赖等级解锁条件
        local isAchieveTrustLv = trustLv >= storyUnlockLv
        
        return isAchieveTrustLv
    end
end
--endregion <<<------------------------

--region ---------- 语音相关 --------->>>

--- 遍历所有角色语音配置数据并重组织
---@param self XFavorabilityModel
local InitAllCharacterShowVoiceCfgs = function(self)
    if XTool.IsTableEmpty(self._CharacterShowVoiceLists) then
        local voiceCfgs = self:GetCharacterVoiceCfgs()
        for _, v in pairs(voiceCfgs) do
            --- 只有需要展示的配置才加入进来
            if v.IsShow == 1 then
                local data = {
                    config=v
                }
                
                if self._CharacterShowVoiceLists[v.CharacterId] == nil then
                    self._CharacterShowVoiceLists[v.CharacterId] = {}
                end
                table.insert(self._CharacterShowVoiceLists[v.CharacterId],data)
            end
        end
        for _, v in pairs(self._CharacterShowVoiceLists) do
            table.sort(v, function(item1, item2)
                if item1.config.UnlockLv == item2.config.UnlockLv then
                    return item1.config.Id < item2.config.Id
                end
                return item1.config.UnlockLv < item2.config.UnlockLv
            end)
        end
    end
end

--- 获取所有角色的所有语音配置
function XFavorabilityModel:GetAllCharacterShowVoiceCfgs()
    if self._CharacterShowVoiceLists == nil then
        self._CharacterShowVoiceLists = {}
    end

    -- 检查并初始化尚未加载的数据
    if not self._CharacterVoiceInitAll then
        -- 如果有部分初始化了，则走部分加载逻辑
        if self._CharacterVoiceInitAny then
            local rangeCfgs = self:GetCharacterVoiceRangeCfgs()

            if rangeCfgs then
                for i, v in pairs(rangeCfgs) do
                    self:GetCharacterShowVoiceCfgsById(v.Id)
                end
            end
        else
            -- 否则走全加载逻辑
            InitAllCharacterShowVoiceCfgs(self)
        end
        
        self._CharacterVoiceInitAll = true

        -- 所有数据已经加载并重新组织，配置表句柄可以丢弃
        self._ConfigUtil:Clear(self._ConfigUtil:GetPathByTableKey(TableNormal.CharacterVoice))
        self._ConfigUtil:Clear(self._ConfigUtil:GetPathByTableKey(TableNormal.CharacterVoiceRange))
    end
    
    return self._CharacterShowVoiceLists
end

--- 按角色Id获得对应角色所有的语音配置
function XFavorabilityModel:GetCharacterShowVoiceCfgsById(characterId)
    if XTool.IsTableEmpty(self._CharacterShowVoiceLists) then
        self._CharacterShowVoiceLists = {}
    end

    if XTool.IsTableEmpty(self._CharacterShowVoiceLists[characterId]) then
        local rangeCfg = self:GetCharacterVoiceRangeById(characterId)

        if self._CharacterShowVoiceLists[characterId] == nil then
            self._CharacterShowVoiceLists[characterId] = {}
        end

        if rangeCfg then
            local voiceCfgs = self:GetCharacterVoiceCfgs()
            for i = rangeCfg.BeginIndex, rangeCfg.EndIndex do
                local voiceCfg = voiceCfgs[i]
                if voiceCfg and voiceCfg.IsShow == 1 then
                    local data = {
                        config = voiceCfg
                    }
                    table.insert(self._CharacterShowVoiceLists[characterId], data)
                end
            end
        end

        table.sort(self._CharacterShowVoiceLists[characterId], function (a, b)
            if a.config.UnlockLv == b.config.UnlockLv then
                return a.config.Id < b.config.Id
            end
            return a.config.UnlockLv < b.config.UnlockLv
        end)
        
        self._CharacterVoiceInitAny = true
    end

    return self._CharacterShowVoiceLists[characterId]
end

function XFavorabilityModel:GetCharacterVoiceMapById(characterId)
    if XTool.IsTableEmpty(self._CharacterVoiceMaps) then
        if self._CharacterVoiceMaps == nil then
            self._CharacterVoiceMaps = {}
        end
    end
    -- 按需初始化
    if XTool.IsTableEmpty(self._CharacterVoiceMaps[characterId]) then
        if self._CharacterVoiceMaps[characterId] == nil then
            self._CharacterVoiceMaps[characterId] = {}
        end

        local unlockDict = self._CharacterVoiceMaps[characterId]

        -- 获取该角色所有语音配置
        local rangeCfg = self:GetCharacterVoiceRangeById(characterId)
        if rangeCfg then
            local voiceCfgs = self:GetCharacterVoiceCfgs()
            for i = rangeCfg.BeginIndex, rangeCfg.EndIndex do
                local voiceCfg = voiceCfgs[i]
                if voiceCfg then
                    local data = {
                        config = voiceCfg
                    }
                    unlockDict[voiceCfg.Id] = data
                end
            end
        end
    end

    local voiceMap = self._CharacterVoiceMaps[characterId]
    if not voiceMap then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterVoiceMapById",
                "voiceMap", "Client/Trust/CharacterVoice.tab", "characterId", tostring(characterId))
        return
    end
    return voiceMap
end

--endregion <<<-------------------------

--region ---------- 动作相关 ---------->>>

--- 遍历所有角色行为配置数据并重组织
---@param self XFavorabilityModel
local InitAllCharacterActionCfgs = function(self)
    if XTool.IsTableEmpty(self._CharacterAction) then
        local actionCfgs = self:GetCharacterActionCfgs()
        for _, v in pairs(actionCfgs) do
            local data = {
                config=v
            }
            if self._CharacterAction[v.CharacterId] == nil then
                self._CharacterAction[v.CharacterId] = {}
            end
            table.insert(self._CharacterAction[v.CharacterId],data)
        end
        for _, v in pairs(self._CharacterAction) do
            table.sort(v, function(item1, item2)
                if item1.config.UnlockLv == item2.config.UnlockLv then
                    return item1.config.Id < item2.config.Id
                end
                return item1.config.UnlockLv < item2.config.UnlockLv
            end)
        end
    end
end

function XFavorabilityModel:GetCharacterAction()
    if self._CharacterAction == nil then
        self._CharacterAction = {}
    end

    -- 检查并初始化尚未加载的数据
    if not self._CharacterActionInitAll then
        -- 如果有部分已经加载了，则走部分加载逻辑
        if self._CharacterActionInitAny then
            local rangeCfgs = self:GetCharacterActionRangeCfgs()

            if rangeCfgs then
                for i, v in pairs(rangeCfgs) do
                    self:GetCharacterActionById(v.Id)
                end
            end
        else
            -- 否则走全加载逻辑
            InitAllCharacterActionCfgs(self)
        end

        self._CharacterActionInitAll = true

        -- 所有数据已经加载并重新组织，配置表句柄可以丢弃
        self._ConfigUtil:Clear(self._ConfigUtil:GetPathByTableKey(TableNormal.CharacterActionRange))
    end

    return self._CharacterAction
end

function XFavorabilityModel:GetCharacterActionBySignBoardActionId(signBoardActionId)
    local actionId = self:GetCharacterActionIdBySignBoarId(signBoardActionId)
    return self:GetCharacterActionCfgs()[actionId]
end

function XFavorabilityModel:GetCharacterActionById(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    
    if self._CharacterAction == nil then
        self._CharacterAction = {}
    end

    if XTool.IsTableEmpty(self._CharacterAction[characterId]) then
        local rangeCfg = self:GetCharacterActionRangeById(characterId)

        if self._CharacterAction[characterId] == nil then
            self._CharacterAction[characterId] = {}
        end

        if rangeCfg then
            local actionCfgs = self:GetCharacterActionCfgs()
            for i = rangeCfg.BeginIndex, rangeCfg.EndIndex do
                local actionCfg = actionCfgs[i]
                if actionCfg then
                    local data = {
                        config = actionCfg
                    }
                    table.insert(self._CharacterAction[characterId], data)
                end
            end
        end

        table.sort(self._CharacterAction[characterId], function (a, b)
            if a.config.UnlockLv == b.config.UnlockLv then
                return a.config.Id < b.config.Id
            end
            return a.config.UnlockLv < b.config.UnlockLv
        end)

        self._CharacterActionInitAny = true
    end
    
    return self._CharacterAction[characterId]
end

function XFavorabilityModel:GetCharacterActionUnlockLvsById(characterId)
    if XTool.IsTableEmpty(self._CharacterActionUnlockLv) then
        if self._CharacterActionUnlockLv == nil then
            self._CharacterActionUnlockLv = {}
        end
    end
    -- 按需初始化
    if XTool.IsTableEmpty(self._CharacterActionUnlockLv[characterId]) then
        if self._CharacterActionUnlockLv[characterId] == nil then
            self._CharacterActionUnlockLv[characterId] = {}
        end

        local unlockDict = self._CharacterActionUnlockLv[characterId]

        -- 获取该角色所有语音配置
        local cfgs = self:GetCharacterActionById(characterId)

        if cfgs then
            -- 按照需求重新组织配置
            for i, v in pairs(cfgs) do
                unlockDict[v.config.Id] = v
            end
        end
    end
    
    local actionUnlockDatas = self._CharacterActionUnlockLv[characterId]
    if not actionUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterActionUnlockLvsById",
                "CharacterActionUnlockLv", "Client/Trust/CharacterAction.tab", "characterId", tostring(characterId))
        return
    end
    return actionUnlockDatas
end

function XFavorabilityModel:GetCharacterActionMapText(mapCode)
    local id = XMath.ToMinInt(mapCode / 10000)
    local value = XMath.ToMinInt(mapCode % 10000)

    local cfg = self:GetCharacterActionContentMapCfg(id)

    if cfg then
        if XTool.IsNumberValid(value) then
            return XUiHelper.FormatText(cfg.Text, value)
        else
            return cfg.Text
        end
    end

    return ''
end

function XFavorabilityModel:GetCharacterActionContentMapCfg(id)
    local cfg = self:GetCharacterActionContentMap()[id]

    if cfg then
        return cfg
    else
        XLog.Error('CharacterACtionContentMap表找不到Id为 '..tostring(id)..' 的数据')
    end
end
--endregion <<<-------------------------

--region --------- CV文本相关 ---------->>>
function XFavorabilityModel:GetCvSplit(cvId, cvType)
    local groupId = cvId * 10 + cvType

    if self._CvSplit == nil then
        self._CvSplit={}
    end
    
    if XTool.IsTableEmpty(self._CvSplit[groupId]) then
        -- 读取cv的范围配置
        local rangeCfg = self:GetCvSplitRangeCfgs()[groupId]

        if rangeCfg then
            local cvSplitCfgs = self:GetCvSplitsCfgs()
            if not self._CvSplit[groupId] then
                self._CvSplit[groupId] = {}
            end
            local array = self._CvSplit[groupId]
            
            -- 根据范围读取并重组配置
            for i = 1, rangeCfg.Count do
                local id = cvId * 1000 + cvType * 100 + i
                local cfg = cvSplitCfgs[id]
                if cfg then
                    --插入
                    local insertIndex = #array + 1
                    for i = 1, #array do
                        if array[i].Timing > cfg.Timing then
                            insertIndex = i
                            break
                        end
                    end
                    table.insert(array, insertIndex, cfg)
                end
            end
        end
    end

    local cfgCvSplit = self._CvSplit[groupId]
    if not cfgCvSplit then
        return false
    end
    return cfgCvSplit
end
--endregion <<<--------------------------

--region ---------- Configs ---------->>>
function XFavorabilityModel:GetStoryLayoutCfgById(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.StoryLayout, characterId)
end

function XFavorabilityModel:GetStoryLayoutBgTypeCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.StoryLayoutBgType, type)
end

function XFavorabilityModel:GetStageDetailTypeCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.CharacterStoryStageDetailType, type)
end

function XFavorabilityModel:GetCharacterBaseData()
    return self._ConfigUtil:Get(TABLE_LIKE_BASEDATA)
end

function XFavorabilityModel:GetCharacterGroup()
    return self._ConfigUtil:Get(TABLE_CHARACTER_GROUP)
end

---@return XTableCharacterCollaboration[]
function XFavorabilityModel:GetCharacterCollaboration()
    return self._ConfigUtil:Get(TABLE_CHARACTER_COLLABORATION)
end

function XFavorabilityModel:GetCharacterFavorability()
    return self._ConfigUtil:Get(TABLE_LIKE_LEVELCONFIG)
end

--- CharacterStory

function XFavorabilityModel:GetCharacterStoryCfgs()
    return self._ConfigUtil:GetByTableKey(TableTemp.CharacterStory)
end

function XFavorabilityModel:GetCharacterStoryTipsCfg(id)
    return self._ConfigUtil:GetByTableKey(TablePrivate.CharacterTips)[id]
end

--- CharacterVoice

function XFavorabilityModel:GetCharacterVoiceCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterVoice)
end

function XFavorabilityModel:GetCharacterVoiceContentMap()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterVoiceContentMap)
end

function XFavorabilityModel:GetCharacterVoiceRangeCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterVoiceRange)
end

function XFavorabilityModel:GetCharacterVoiceRangeById(characterId)
    local cfgs = self:GetCharacterVoiceRangeCfgs()
    local cfg = cfgs[characterId]

    if cfg then
        return cfg
    else
        XLog.Error('CharacterVoiceRange表找不到Id为 '..tostring(characterId)..' 的数据')
    end
end

--- CharacterAction

function XFavorabilityModel:GetCharacterActionCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterAction)
end

function XFavorabilityModel:GetCharacterActionContentMap()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterActionContentMap)
end

function XFavorabilityModel:GetCharacterActionRangeCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.CharacterActionRange)
end

function XFavorabilityModel:GetCharacterActionRangeById(characterId)
    local cfgs = self:GetCharacterActionRangeCfgs()
    local cfg = cfgs[characterId]

    if cfg then
        return cfg
    else
        XLog.Error('CharacterVoiceRange表找不到Id为 '..tostring(characterId)..' 的数据')
    end
end

function XFavorabilityModel:GetCharacterActionIdBySignBoarId(signboardId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableNormal.CharacterActionSignBoard)
    
    local cfg = cfgs[signboardId]

    if cfg then
        return cfg.CharacterActionId
    end
end

--- CvSplit
function XFavorabilityModel:GetCvSplitsCfgs()
    return self._ConfigUtil:Get(TABLE_CV_SPLIT)
end

function XFavorabilityModel:GetCvSplitRangeCfgs()
    return self._ConfigUtil:Get(TABLE_CV_SPLIT_RANGE)
end

--endregion <<<--------------------------

function XFavorabilityModel:GetAllCharacterSendGift()
    self:CheckCharacterTrustItemDataDone()
    if not self._CharacterSendGift then
        XLog.Error("XFavorabilityModel.GetAllCharacterSendGift 函数错误, 配置表：" .. TABLE_LIKE_TRUSTITEM .. " 读取失败, 检查配置表")
        return
    end
    return self._CharacterSendGift
end


function XFavorabilityModel:GetCharacterInformationUnlockLvById(characterId)
    self:CheckInformationDataDone()
    local informationUnlockDatas = self._CharacterInformationUnlockLv[characterId]
    if not informationUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterInformationUnlockLvById",
                "UnlockLv", TABLE_LIKE_INFORMATION, "characterId", tostring(characterId))
        return
    end
    return informationUnlockDatas
end

-- [好感度等级经验]
function XFavorabilityModel:GetTrustExpById(characterId)
    self:CheckTrustExpDataDone()
    local trustExp = self._CharacterTrustExp[characterId]
    if not trustExp then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetTrustExpById", "CharacterTrustExp",
                TABLE_LIKE_TRUSTEXP, "characterId", tostring(characterId))
        return
    end
    return trustExp
end

function XFavorabilityModel:GetLikeTrustItemCfg(itemId)
    local cfg = self._ConfigUtil:Get(TABLE_LIKE_TRUSTITEM)[itemId]
    if not cfg then
        XLog.Error("XFavorabilityModel.GetLikeTrustItemCfg 函数错误, 配置表：" .. TABLE_LIKE_TRUSTITEM .. " 读取失败, 检查配置表")
        return
    end
    return cfg
end

-- [好感度基础数据]
function XFavorabilityModel:GetCharacterBaseDataById(characterId)
    local baseData = self:GetCharacterBaseData()[characterId]
    if not baseData then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterBaseDataById",
                "CharacterBaseData", TABLE_LIKE_BASEDATA, "characterId", characterId)
        return
    end
    return baseData
end

-- [角色队伍Id]
function XFavorabilityModel:GetCharacterTeamIconById(characterId)
    local baseData = self:GetCharacterBaseData()[characterId]
    if not baseData or not baseData.TeamIcon then
        --XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterBaseDataById",
        --        "CharacterBaseData", TABLE_LIKE_BASEDATA, "characterId", characterId)

        local logo=XExhibitionConfigs.GetExhibitionGroupLogoConfig()[characterId]
        return logo
    end
    return baseData.TeamIcon
end

function XFavorabilityModel:GetFavorabilityLevel(characterId, totalExp, startLevel)
    local characterFavorabilityLevelDatas = self:GetTrustExpById(characterId)
    if not characterFavorabilityLevelDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetMaxFavorabilityLevel",
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

-- [好感度档案-资料]
function XFavorabilityModel:GetCharacterInformationById(characterId)
    local information = self:GetCharacterInformation()[characterId]
    return information
end

-- [好感度礼物-奖励]
function XFavorabilityModel:GetCharacterGiftRewardById(characterId)
    local giftReward = self._CharacterGiftReward[characterId]
    if not giftReward then
        XLog.Error("XFavorabilityModel.GetCharacterGiftRewardById error: not data found by characterId " .. tostring(characterId))
        return
    end
    return giftReward
end

function XFavorabilityModel:GetLikeRewardById(rewardId)
    if not self._likeReward then
        XLog.Error("XFavorabilityModel.GetLikeRewardById error: not data found by rewardId " .. tostring(rewardId))
        return
    end
    return self._likeReward[rewardId]
end

function XFavorabilityModel:GetFavorabilityLevelCfg(level)
    local cfgs = self:GetCharacterFavorability()[level]
    if not cfgs then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetFavorabilityLevelCfg",
                "CharacterFavorabilityConfig", TABLE_LIKE_LEVELCONFIG, "level", tostring(level))
    end
    return cfgs
end

--==============================
---@desc 获取角色组Id
---@characterId 角色id 
---@return number
--==============================
function XFavorabilityModel:GetCharacterGroupId(characterId)
    local cfg = self:GetCharacterGroup()[characterId]
    if not cfg then
        XLog.Error("XFavorabilityModel.GetCharacterGroupId 函数错误, 配置表：" .. TABLE_CHARACTER_GROUP .."CharacterId = "..characterId.." 读取失败, 检查配置表")
        return
    end
    return cfg.GroupId
end

function XFavorabilityModel:GetFestival(id)
    local festivalData=self._ConfigUtil:Get(TABLE_FESTIVAL)[id]
    return festivalData
end

function XFavorabilityModel:GetQualityIconByQuality(quality)
    if quality == nil or self._GiftQualityIcon[quality] == nil then
        return self._GiftQualityIcon[1]
    end
    return self._GiftQualityIcon[quality]
end

--region signboard相关
---@return XTableSignBoardFeedback[]
function XFavorabilityModel:GetSignBoardConfig()
    return self._ConfigUtil:Get(TABLE_SIGNBOARD_FEEDBACK)
end

--获取角色所有事件
function XFavorabilityModel:GetSignBoardConfigByRoldId(roleId)
    self:CheckSignBoardDataDone()
    local all = {}

    if self._TableSignBoardRoleIdIndexs and self._TableSignBoardRoleIdIndexs[roleId] then
        for _, v in pairs(self._TableSignBoardRoleIdIndexs[roleId]) do
            for _, var in ipairs(v) do
                table.insert(all, var)
            end
        end
    end

    if self._TableSignBoardIndexs then
        for _, v in pairs(self._TableSignBoardIndexs) do
            for _, var in ipairs(v) do
                table.insert(all, var)
            end
        end
    end

    return all
end

function XFavorabilityModel:GetSignBoardSceneAnim(signBoardid)
    local signBoard = self:GetSignBoardConfig()[signBoardid]
    if not signBoard then
        return nil
    end
    return signBoard.SceneCamAnimPrefab
end

function XFavorabilityModel:GetIsUseSelfUiAnim(signBoardid, uiName)
    local signBoard = self:GetSignBoardConfig()[signBoardid]
    if not signBoard or XTool.IsTableEmpty(signBoard.IsUseSelfUiAnims) or not uiName then
        return nil
    end
    return signBoard.IsUseSelfUiAnims[XEnumConst.Favorability.XSignBoardUiShowType[uiName]]
end
--endregion
----------config end----------


return XFavorabilityModel