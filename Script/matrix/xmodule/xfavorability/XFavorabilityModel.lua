---@class XFavorabilityModel : XModel
local XFavorabilityModel = XClass(XModel, "XFavorabilityModel")

local TABLE_LIKE_BASEDATA = "Client/Trust/CharacterBaseData.tab"
local TABLE_LIKE_INFORMATION = "Client/Trust/CharacterInformation.tab"
local TABLE_LIKE_STORY = "Client/Trust/CharacterStory.tab"
local TABLE_LIKE_STRANGENEWS = "Client/Trust/CharacterStrangeNews.tab"
local TABLE_LIKE_TRUSTEXP = "Share/Trust/CharacterTrustExp.tab"
local TABLE_LIKE_TRUSTITEM = "Share/Trust/CharacterTrustItem.tab"
local TABLE_LIKE_VOICE = "Client/Trust/CharacterVoice.tab"
local TABLE_LIKE_LEVELCONFIG = "Share/Trust/FavorabilityLevelConfig.tab"
local TABLE_LIKE_ACTION = "Client/Trust/CharacterAction.tab"
local TABLE_CV_SPLIT = "Client/Audio/CvSplit.tab"
local TABLE_CHARACTER_GROUP = "Share/FestivalMail/FestivalCharacterGroup.tab"
local TABLE_FESTIVAL = "Share/FestivalMail/Festival.tab"
local TABLE_STORY_LAYOUT="Client/Trust/StoryLayout.tab"
local TABLE_CHARACTER_COLLABORATION = "Client/Trust/CharacterCollaboration.tab"
local TABLE_SIGNBOARD_FEEDBACK = "Client/Signboard/SignBoardFeedback.tab";

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
        [TABLE_CV_SPLIT]={XConfigUtil.ReadType.Int,XTable.XTableCvSplit,"Id",XConfigUtil.CacheType.Preload},

        [TABLE_LIKE_BASEDATA]={XConfigUtil.ReadType.Int,XTable.XTableCharacterBaseData,"CharacterId",XConfigUtil.CacheType.Normal},
        [TABLE_SIGNBOARD_FEEDBACK]={XConfigUtil.ReadType.Int,XTable.XTableSignBoardFeedback,"Id",XConfigUtil.CacheType.Normal},


        [TABLE_STORY_LAYOUT]={XConfigUtil.ReadType.Int,XTable.XTableStoryLayout,"CharacterId",XConfigUtil.CacheType.Private},
        [TABLE_CHARACTER_COLLABORATION]={XConfigUtil.ReadType.Int,XTable.XTableCharacterCollaboration,"CharacterId",XConfigUtil.CacheType.Private},
        [TABLE_LIKE_TRUSTITEM]={XConfigUtil.ReadType.Int,XTable.XTableCharacterTrustItem,"Id",XConfigUtil.CacheType.Private},
        [TABLE_FESTIVAL]={XConfigUtil.ReadType.Int,XTable.XTableFestival,"Id",XConfigUtil.CacheType.Private},
        [TABLE_CHARACTER_GROUP]={XConfigUtil.ReadType.Int,XTable.XTableFestivalCharacterGroup,"CharacterId",XConfigUtil.CacheType.Private},
        [TABLE_LIKE_LEVELCONFIG]={XConfigUtil.ReadType.Int,XTable.XTableFavorabilityLevelConfig,"Id",XConfigUtil.CacheType.Private},

        [TABLE_LIKE_INFORMATION]={XConfigUtil.ReadType.Int,XTable.XTableCharacterInformation, "Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_STORY]={XConfigUtil.ReadType.Int,XTable.XTableCharacterStory,"Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_STRANGENEWS]={XConfigUtil.ReadType.Int,XTable.XTableCharacterStrangeNews,"Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_TRUSTEXP]={XConfigUtil.ReadType.Int,XTable.XTableCharacterTrustExp,"Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_VOICE]={XConfigUtil.ReadType.Int,XTable.XTableCharacterVoice,"Id",XConfigUtil.CacheType.Temp},
        [TABLE_LIKE_ACTION]={XConfigUtil.ReadType.Int,XTable.XTableCharacterAction,"Id",XConfigUtil.CacheType.Temp},

    })
    
    self._CharacterInformation=nil
    self._CharacterInformationUnlockLv=nil
    self._CharacterStory=nil
    self._CharacterStoryUnlockLv=nil
    self._CharacterRumors=nil
    self._CharacterRumorsPriority=nil
    self._CharacterTrustExp=nil
    self._CharacterSendGift=nil
    self._CvSplit=nil
    
    self._CharacterVoice=nil
    self._CharacterVoiceUnlockLv=nil
    self._CharacterAction=nil
    self._CharacterActionUnlockLv=nil
    self._CharacterActionKeySignBoardActionId=nil
    
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
    self._sceneAnim=require("XEntity/XSignBoard/XSignBoardCamAnim").New()
    self._sceneAnimPrefab=nil
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
    self._CharacterRumorsPriority=nil
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
    self._CharacterInformation=nil
    self._CharacterInformationUnlockLv=nil
    self._CharacterStory=nil
    self._CharacterStoryUnlockLv=nil
    self._CharacterRumors=nil
    self._CharacterTrustExp=nil
    self._CharacterSendGift=nil
    self._DontStopCvContent=nil
    
    --clear nonpri&secondary analysis table data
    self._CharacterVoice=nil
    self._CharacterVoiceUnlockLv=nil
    self._CharacterAction=nil
    self._CharacterActionUnlockLv=nil
    self._CharacterActionKeySignBoardActionId=nil
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
    self._sceneAnimPrefab=nil
    self._PlayedList={}
end

----------public start----------
function XFavorabilityModel:GetCharacterFavorabilityDatasById(characterId)
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

function XFavorabilityModel:IsCharacterFavorabilityDatasEmpty()
    return XTool.IsTableEmpty(self._CharacterFavorabilityDatas)
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

function XFavorabilityModel:CheckStoryDataDone()
    if XTool.IsTableEmpty(self._CharacterStoryUnlockLv) or XTool.IsTableEmpty(self._CharacterStory) then
        --初始化归类
        self._CharacterStoryUnlockLv={}
        self._CharacterStory={}
        local tab=self._ConfigUtil:Get(TABLE_LIKE_STORY)
        for i, v in pairs(tab) do
            if self._CharacterStory[v.CharacterId] == nil then
                self._CharacterStory[v.CharacterId] = {}
            end

            table.insert(self._CharacterStory[v.CharacterId], v)

            if self._CharacterStoryUnlockLv[v.CharacterId] == nil then
                self._CharacterStoryUnlockLv[v.CharacterId] = {}
            end
            self._CharacterStoryUnlockLv[v.CharacterId][v.Id] = v.UnlockLv
        end

        --排序
        for i, storys in pairs(self._CharacterStory) do
            table.sort(storys, function(storyA, storyB)
                if storyA.UnlockLv == storyB.UnlockLv then
                    return storyA.Id < storyB.Id
                end
                return storyA.UnlockLv < storyB.UnlockLv
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

function XFavorabilityModel:CheckCharacterVoiceDataDone()
    if XTool.IsTableEmpty(self._CharacterVoice) or XTool.IsTableEmpty(self._CharacterVoiceUnlockLv) then
        self._CharacterVoice={}
        self._CharacterVoiceUnlockLv={}
        local likeVoice = self._ConfigUtil:Get(TABLE_LIKE_VOICE)
        for _, v in pairs(likeVoice) do
            local data = {
                config=v
            }
            if v.IsShow == 1 then
                if self._CharacterVoice[v.CharacterId] == nil then
                    self._CharacterVoice[v.CharacterId] = {}
                end
                table.insert(self._CharacterVoice[v.CharacterId],data)
            end

            if self._CharacterVoiceUnlockLv[v.CharacterId] == nil then
                self._CharacterVoiceUnlockLv[v.CharacterId] = {}
            end
            self._CharacterVoiceUnlockLv[v.CharacterId][v.Id] = data
        end
        for _, v in pairs(self._CharacterVoice) do
            table.sort(v, function (a, b)
                if a.config.UnlockLv == b.config.UnlockLv then
                    return a.config.Id < b.config.Id
                end
                return a.config.UnlockLv < b.config.UnlockLv
            end 
            )
        end
    end
end

function XFavorabilityModel:CheckCharacterActionDataDone()
    if XTool.IsTableEmpty(self._CharacterAction) or XTool.IsTableEmpty(self._CharacterActionKeySignBoardActionId) or XTool.IsTableEmpty(self._CharacterActionUnlockLv) then
        self._CharacterActionUnlockLv={}
        self._CharacterAction={}
        self._CharacterActionKeySignBoardActionId={}
        
        local likeAction = self._ConfigUtil:Get(TABLE_LIKE_ACTION)
        for _, v in pairs(likeAction) do
            local data = {
                config=v
            }
            if self._CharacterAction[v.CharacterId] == nil then
                self._CharacterAction[v.CharacterId] = {}
            end
            table.insert(self._CharacterAction[v.CharacterId],data)
            self._CharacterActionKeySignBoardActionId[v.SignBoardActionId] = data

            if self._CharacterActionUnlockLv[v.CharacterId] == nil then
                self._CharacterActionUnlockLv[v.CharacterId] = {}
            end
            self._CharacterActionUnlockLv[v.CharacterId][v.Id] = data
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

function XFavorabilityModel:GetCharacterStory()
    self:CheckStoryDataDone()
    return self._CharacterStory
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

function XFavorabilityModel:GetStoryLayout()
    return self._ConfigUtil:Get(TABLE_STORY_LAYOUT)
end

function XFavorabilityModel:GetCharacterBaseData()
    return self._ConfigUtil:Get(TABLE_LIKE_BASEDATA)
end

function XFavorabilityModel:GetCharacterGroup()
    return self._ConfigUtil:Get(TABLE_CHARACTER_GROUP)
end

function XFavorabilityModel:GetCharacterCollaboration()
    return self._ConfigUtil:Get(TABLE_CHARACTER_COLLABORATION)
end

function XFavorabilityModel:GetCharacterFavorability()
    return self._ConfigUtil:Get(TABLE_LIKE_LEVELCONFIG)
end

function XFavorabilityModel:GetAllCharacterSendGift()
    self:CheckCharacterTrustItemDataDone()
    if not self._CharacterSendGift then
        XLog.Error("XFavorabilityModel.GetAllCharacterSendGift 函数错误, 配置表：" .. TABLE_LIKE_TRUSTITEM .. " 读取失败, 检查配置表")
        return
    end
    return self._CharacterSendGift
end

function XFavorabilityModel:GetCharacterVoice()
    self:CheckCharacterVoiceDataDone()
    return self._CharacterVoice
end

function XFavorabilityModel:GetCharacterAction()
    self:CheckCharacterActionDataDone()
    return self._CharacterAction
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

function XFavorabilityModel:GetCharacterStoryUnlockLvsById(characterId)
    self:CheckStoryDataDone()
    local storyUnlockDatas = self._CharacterStoryUnlockLv[characterId]
    if not storyUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterStoryUnlockLvsById",
                "CharacterStoryUnlockLv", TABLE_LIKE_STORY, "characterId", tostring(characterId))
        return
    end
    return storyUnlockDatas
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

function XFavorabilityModel:GetCharacterActionBySignBoardActionId(signBoardActionId)
    self:CheckCharacterActionDataDone()
    return self._CharacterActionKeySignBoardActionId[signBoardActionId]
end

function XFavorabilityModel:GetCharacterActionById(characterId)
    self:CheckCharacterActionDataDone()
    return self._CharacterAction[characterId]
end

function XFavorabilityModel:GetCharacterVoiceUnlockLvsById(characterId)
    self:CheckCharacterVoiceDataDone()
    local voiceUnlockDatas = self._CharacterVoiceUnlockLv[characterId]
    if not voiceUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterVoiceUnlockLvsById",
                "CharacterVoiceUnlockLv", TABLE_LIKE_VOICE, "characterId", tostring(characterId))
        return
    end
    return voiceUnlockDatas
end

function XFavorabilityModel:GetCharacterActionUnlockLvsById(characterId)
    local actionUnlockDatas = self._CharacterActionUnlockLv[characterId]
    if not actionUnlockDatas then
        XLog.ErrorTableDataNotFound("XFavorabilityModel.GetCharacterActionUnlockLvsById",
                "CharacterActionUnlockLv", TABLE_LIKE_ACTION, "characterId", tostring(characterId))
        return
    end
    return actionUnlockDatas
end

function XFavorabilityModel:GetCvSplit(cvId, cvType)
    if XTool.IsTableEmpty(self._CvSplit) then
        self._CvSplit={}
        local tabCvSplit = self._ConfigUtil:Get(TABLE_CV_SPLIT)
        for _, v in pairs(tabCvSplit) do
            local cvId = v.CvId
            local cvType = v.Cvs    --语言
            local timing = v.Timing
            if not self._CvSplit[cvId] then
                self._CvSplit[cvId] = {}
            end
            if not self._CvSplit[cvId][cvType] then
                self._CvSplit[cvId][cvType] = {}
            end
            local array = self._CvSplit[cvId][cvType]
            --插入
            local insertIndex = #array + 1
            for i = 1, #array do
                if array[i].Timing > timing then
                    insertIndex = i
                    break
                end
            end
            table.insert(array, insertIndex, v)
        end
        self._ConfigUtil:Clear(TABLE_CV_SPLIT)
    end

    local dictType = self._CvSplit[cvId]
    if not dictType then
        return false
    end
    local cfgCvSplit = dictType[cvType]
    if not cfgCvSplit then
        return false
    end
    return cfgCvSplit
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