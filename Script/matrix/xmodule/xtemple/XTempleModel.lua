local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local TALK = XTempleEnumConst.NPC_TALK

local TableKey = {
    TempleGrid = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    TempleTime = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    TempleRule = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    TempleBlock = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    TempleFairStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    TempleConstConfig = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    TempleFairActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    TempleNpc = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, Identifier = "Id" },
    TempleNpcCouple = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, TableDefindName = "XTableTempleNpc", Identifier = "NpcId" },
    TempleFairChapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XTempleModel : XModel
local XTempleModel = XClass(XModel, "XTempleModel")
function XTempleModel:OnInit()
    -- debug用
    if self:IsEditor() then
        TableKey.TempleBlock.CacheType = XConfigUtil.CacheType.Temp
    end
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/TempleFair", TableKey)

    self._IsConfigDirty = true

    self._ActivityId = 1

    self._ActivityData = nil
end

function XTempleModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XTempleModel:ResetAll()
    --这里执行重登数据清理
    self._ActivityData = nil
end

function XTempleModel:GetGrid(gridType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleGrid, gridType, true)
end

function XTempleModel:GetTimeOfDay(timeOfDay)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleTime, timeOfDay)
end

function XTempleModel:GetGridIcon(gridId)
    return self:GetGrid(gridId).Icon
end

function XTempleModel:GetGridFusionIcon(gridId)
    return self:GetGrid(gridId).Fusion
end

function XTempleModel:GetGridFusionType(gridId)
    return self:GetGrid(gridId).FusionType
end

function XTempleModel:GetGridName(gridType)
    return self:GetGrid(gridType).Name
    --return gridType
end

function XTempleModel:GetTimeOfDayName(timeOfDay)
    return self:GetTimeOfDay(timeOfDay).Name
end

function XTempleModel:GetTimeOfDayIconOn(timeOfDay)
    return self:GetTimeOfDay(timeOfDay).IconOn
end

function XTempleModel:GetTimeOfDayIconOff(timeOfDay)
    return self:GetTimeOfDay(timeOfDay).IconOff
end

function XTempleModel:GetStageGamePath(stageId, fullPath)
    if fullPath then
        return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/" .. self:GetStageGamePath(stageId)
    end
    local path = "Client/MiniActivity/TempleFair/TempleStage/TempleStage" .. stageId .. ".tab"
    return path
end

function XTempleModel:EditorGetBlockPath()
    return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/Client/MiniActivity/TempleFair/TempleBlock.tab"
end

local function FileExists(filePath)
    local file = io.open(filePath, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function XTempleModel:GetStageGameConfig(stageId)
    if XMain.IsWindowsEditor then
        local fullPath = self:GetStageGamePath(stageId, true)
        if not FileExists(fullPath) then
            XLog.Debug("[XTempleModel] 文件尚不存在:", fullPath)
            return {}
        end
    end

    local path = self:GetStageGamePath(stageId)
    if self:IsEditor() then
        self._ConfigUtil:Clear(path)
    end
    if not self._ConfigUtil:HasArgs(path) then
        if self:IsEditor() then
            self._ConfigUtil:InitConfig({
                [path] = { XConfigUtil.ReadType.Int, XTable.XTableTempleStageGame, "Id", XConfigUtil.CacheType.Temp },
            })
        else
            self._ConfigUtil:InitConfig({
                [path] = { XConfigUtil.ReadType.Int, XTable.XTableTempleStageGame, "Id", XConfigUtil.CacheType.Private },
            })
        end
    end
    local configs = self._ConfigUtil:Get(path)
    if not configs then
        XLog.Debug("[XTempleModel] 文件尚不存在:", stageId)
        return {}
    end
    return configs
end

function XTempleModel:GetActionRecord(stageId)
    if XMain.IsWindowsEditor then
        local fullPath = self:GetActionRecordPath(stageId, true)
        if not FileExists(fullPath) then
            XLog.Debug("[XTempleModel] 文件尚不存在:", fullPath)
            return {}
        end
    end

    local path = self:GetActionRecordPath(stageId)
    if self:IsEditor() then
        self._ConfigUtil:Clear(path)
    end
    if not self._ConfigUtil:HasArgs(path) then
        --if self:IsEditor() then
        --    self._ConfigUtil:InitConfig({
        --        [path] = { XConfigUtil.ReadType.Int, XTable.XTableTempleActionRecord, "Id", XConfigUtil.CacheType.Temp },
        --    })
        --else
        --end
        self._ConfigUtil:InitConfig({
            [path] = { XConfigUtil.ReadType.Int, XTable.XTableTempleActionRecord, "Id", XConfigUtil.CacheType.Temp },
        })
    end

    local configs = self._ConfigUtil:Get(path)
    return configs
end

function XTempleModel:GetStageConfigList()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleFairStage)
end

function XTempleModel:GetRules()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleRule)
end

function XTempleModel:GetRuleByType(ruleType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleRule, ruleType) or {}
end

function XTempleModel:GetRuleText(ruleType)
    return self:GetRuleByType(ruleType).Text
end

function XTempleModel:GetRuleBlockId(ruleType)
    return XTempleEnumConst.RULE_TIPS_BLOCK | ruleType
end

function XTempleModel:GetAllRule()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleRule)
end

function XTempleModel:GetActionRecordPath(stageId, fullPath)
    if fullPath then
        return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/" .. self:GetActionRecordPath(stageId)
    end

    local directory
    if self:IsCoupleStage(stageId) then
        directory = "Record"
    else
        directory = "RecordIgnore"
    end
    local path = "Client/MiniActivity/TempleFair/TempleStage/" .. directory .. "/TempleStageRecord" .. stageId .. ".tab"
    return path
end

function XTempleModel:GetBlockById(blockId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleBlock, blockId, true)
    return config
end

function XTempleModel:GetAllBlocks()
    if self:IsConfigDirty() then
        self:SetConfigDirty(false)
        local path = self._ConfigUtil:GetPathByTableKey(TableKey.TempleBlock)
        self._ConfigUtil:Clear(path)
    end
    local blocks = self._ConfigUtil:GetByTableKey(TableKey.TempleBlock)
    return blocks
end

function XTempleModel:IsEditor()
    return XMain.IsWindowsEditor
end

function XTempleModel:IsConfigDirty()
    return self._IsConfigDirty
end

function XTempleModel:SetConfigDirty(value)
    self._IsConfigDirty = value
end

function XTempleModel:GetMaxGrid()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.TempleGrid)
    local maxConfig = configs[#configs]
    return maxConfig.Id
end

function XTempleModel:GetGrids()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleGrid)
end

function XTempleModel:GetGridType(gridId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleGrid, gridId).Type
end

function XTempleModel:IsGridCanRotate(gridId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleGrid, gridId).RotateIcon == 1
end

function XTempleModel:GetGridCommunityAmount()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "Grids").Value
end

function XTempleModel:GetActivityEndTime()
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairActivity, self:GetActivityId(), true)
    if config then
        local timeId = config.TimeId
        local time = XFunctionManager.GetEndTimeByTimeId(timeId)
        return time
    end
    return 0
end

function XTempleModel:CheckInTime()
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairActivity, self:GetActivityId(), true)
    if config then
        local timeId = config.TimeId
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    return false
end

---@return XTempleActivityData
function XTempleModel:GetActivityData()
    self._ActivityData = self._ActivityData or require("XEntity/XTemple/XTempleActivityData").New()
    return self._ActivityData
end

function XTempleModel:SetServerData(serverData)
    self:GetActivityData():SetServerData(serverData, self)
end

function XTempleModel:InstantiateServerData()
    self:GetActivityData():Instantiate(self)
end

function XTempleModel:IsStagePassed(stageId)
    if self:IsCoupleStage(stageId) then
        return self:IsStageHasRecord(stageId)
    end
    local star = self:GetStageStar(stageId)
    return star >= 1
end

function XTempleModel:IsStageHasRecord(stageId)
    return self:GetActivityData():IsStageHasRecord(stageId)
end

function XTempleModel:IsCoupleStage(stageId)
    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    if not stage then
        return false
    end
    return stage.ChapterId == XTempleEnumConst.CHAPTER.COUPLE
end

function XTempleModel:GetChapterId(stageId)
    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    if not stage then
        return false
    end
    return stage.ChapterId
end

function XTempleModel:GetActivityId()
    return self:GetActivityData():GetActivityId()
end

function XTempleModel:GetStageMaxStar(stageId)
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    local needStar = stageConfig.StarNumberScore
    return #needStar
end

function XTempleModel:GetStageMaxStarScore(stageId)
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    local needStar = stageConfig.StarNumberScore
    return needStar[#needStar] or 0
end

function XTempleModel:GetStageStarArray(stageId)
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    local needStar = stageConfig.StarNumberScore
    return needStar
end

function XTempleModel:GetStarByScore(stageId, score)
    local star = 0
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    local needStar = stageConfig.StarNumberScore
    for i = #needStar, 1, -1 do
        if score >= needStar[i] then
            star = i
            break
        end
    end
    return star
end

function XTempleModel:GetStageStarConfig(stageId)
    local starConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    return starConfig.StarNumberScore
end

function XTempleModel:GetStageImageNumber(stageId)
    local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId)
    return stageConfig.ImageNumber
end

function XTempleModel:GetStageStar(stageId)
    local score = self:GetActivityData():GetStageScore(stageId)
    if not score then
        return 0
    end
    return self:GetStarByScore(stageId, score)
end

function XTempleModel:GetChapterStar(chapterId)
    local star = 0
    local totalStar = 0
    local allStage = self._ConfigUtil:GetByTableKey(TableKey.TempleFairStage)
    for i, stage in pairs(allStage) do
        if stage.ChapterId == chapterId then
            star = star + self:GetStageStar(stage.Id)
            local stageConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stage.Id)
            totalStar = totalStar + #stageConfig.StarNumberScore
        end
    end
    return star, totalStar
end

function XTempleModel:GetChapterTimeId(chapterId)
    local chapter = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairChapter, chapterId)
    return chapter.TimeId
end

function XTempleModel:GetMessagePassedStageAmount(chapterId)
    local amount = 0
    local totalAmount = 0
    local allStage = self._ConfigUtil:GetByTableKey(TableKey.TempleFairStage)
    for i, stage in pairs(allStage) do
        if stage.ChapterId == chapterId and not string.IsNilOrEmpty(stage.Message) then
            if self:IsStagePassed(stage.Id) then
                amount = amount + 1
            end
            totalAmount = totalAmount + 1
        end
    end
    return amount, totalAmount
end

function XTempleModel:GetStageScore(stageId)
    return self:GetActivityData():GetStageScore(stageId)
end

function XTempleModel:GetStageName(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId).StageName
end

function XTempleModel:GetStageBg(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId).Bg
end

function XTempleModel:GetStageDetailBg(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId).DetailBg
end

function XTempleModel:GetStageDesc(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId).StageDesc
end

function XTempleModel:GetOptionRewardScore(time)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "OptionRewardScore" .. time).Value
end

function XTempleModel:GetStageUnlockTimeId(stageId)
    --return 25708
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId).TimeId
end

function XTempleModel:IsPreStagePassed(stageId)
    if XMVCA.XTemple:IsOffline() then
        return true
    end

    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    if not stage then
        return true
    end
    local preStageId = stage.LastStage
    if preStageId == 0 then
        return true
    end
    if self:IsStagePassed(preStageId) then
        return true
    end
    return false
end

---@param game XTempleGame
function XTempleModel:SaveStageDataFromClient(stageId, game)
    ---@class XTempleStageData
    local data = {
        StageId = stageId,
        Score = game:GetScore(),
        OperatorRecords = game:GetActionRecords(),
        StageStartTime = XTime.GetServerNowTimestamp()
    }

    local activityData = self:GetActivityData()
    activityData:SetStage2Continue(data, self:GetChapterId(stageId))
end

function XTempleModel:GetNpcIndex(stageId)
    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    local index = stage.StageNpc
    return index
end

function XTempleModel:GetNpcId(stageId)
    if self:IsCoupleStage(stageId) then
        return self:GetActivityData():GetSelectedCharacterId(self)
    end
    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    local index = stage.StageNpc
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleNpc, index)
    return config.NpcId
end

function XTempleModel:GetTalkByStageId(stageId, type, isCouple)
    local npcId
    if isCouple then
        npcId = self:GetActivityData():GetSelectedCharacterId(self)
    else
        npcId = self:GetNpcIndex(stageId)
    end
    return self:GetTalkText(npcId, type, isCouple)
end

function XTempleModel:GetTextRandom(textArray)
    local length = #textArray
    if length == 1 then
        return XUiHelper.ReplaceTextNewLine(textArray[1])
    end
    if length == 0 then
        return ""
    end
    local random = math.random(1, length)
    return XUiHelper.ReplaceTextNewLine(textArray[random])
end

function XTempleModel:GetTalkText(npcId, type, isCouple)
    local config
    if isCouple then
        config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleNpcCouple, npcId, true)
    else
        config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleNpc, npcId, true)
    end
    if not config then
        return "", ""
    end
    if type == TALK.STAGE_ENTER then
        return self:GetTextRandom(config.TextStageEnter), config.Body
    end
    if type == TALK.SUCCESS then
        return self:GetTextRandom(config.TextStageSettle), config.Body
    end
    if type == TALK.REFRESH_BLOCK then
        return self:GetTextRandom(config.TextRefreshBlock), config.Body
    end
    if type == TALK.CHOOSE_BLOCK then
        return self:GetTextRandom(config.TextChooseBlock), config.Body
    end
    if type == TALK.MOVE_BLOCK then
        return self:GetTextRandom(config.TextMoveBlock), config.Body
    end
    if type == TALK.ROTATE_BLOCK then
        return self:GetTextRandom(config.TextRotateBlock), config.Body
    end
    if type == TALK.CANCEL_BLOCK then
        return self:GetTextRandom(config.TextCancelBlock), config.Body
    end
    if type == TALK.FAIL then
        return self:GetTextRandom(config.TextFail), config.Body
    end
end

function XTempleModel:GetAllNpc()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleNpc)
end

function XTempleModel:GetAllNpcCouple()
    return self._ConfigUtil:GetByTableKey(TableKey.TempleNpcCouple)
end

function XTempleModel:GetStageMessage(stageId)
    local stage = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleFairStage, stageId, true)
    return stage.Message
end

function XTempleModel:IsCanQuickPass(stageId)
    if not self:IsCoupleStage(stageId) then
        return false
    end
    local passedAmount = self:GetPassedCharacterAmount()
    local needAmount = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "CoupleQuickPass").Value
    if passedAmount >= needAmount then
        return true
    end
    return false
end

function XTempleModel:GetPassedCharacterAmount(chapter)
    local configs
    if chapter == XTempleEnumConst.CHAPTER.COUPLE then
        configs = self:GetAllNpcCouple()
    else
        configs = self:GetAllNpc()
    end
    local amount = 0
    local totalAmount = 0
    for i, config in pairs(configs) do
        local characterId = config.NpcId
        if self:GetActivityData():HasPhotoData(characterId) then
            amount = amount + 1
        end
        totalAmount = totalAmount + 1
    end
    return amount, totalAmount
end

function XTempleModel:GetNpcSmartPutDownBlock(characterId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleNpcCouple, characterId)
    return config.SmartPutDownBlock
end

function XTempleModel:GetRuleBg(index)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "RuleNameBg" .. index)
    return cfg.ValueStr
end

function XTempleModel:GetRuleBgTextColor(index)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "RuleNameBgColor" .. index)
    return cfg.ValueStr
end

function XTempleModel:IsStageCanChallenge(stageId)
    local unlockTimeId = self:GetStageUnlockTimeId(stageId)
    if not XFunctionManager.CheckInTimeByTimeId(unlockTimeId) then
        return false
    end
    if not self:IsPreStagePassed(stageId) then
        return false
    end
    return true
end

function XTempleModel:GetTimeBg(time)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "TimeBg" .. time).ValueStr
end

function XTempleModel:GetTimeText(time)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "TimeText" .. time).ValueStr
end

function XTempleModel:GetRewardId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "RewardId").Value
end

function XTempleModel:GetRewardId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "RewardId").Value
end

function XTempleModel:GetMusicChangeTime()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "TimeChangeVoice").ValueStr)
end

function XTempleModel:GetMusicSuccess()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "SettleVoice").ValueStr)
end

function XTempleModel:GetMusicFail()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "SetFailVoice").ValueStr)
end

function XTempleModel:GetMusicScore(score)
    -- 为什么是5? 因为配置配到了5
    for i = 1, 5 do
        local key = "SetVoice" .. i
        local value = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, key).Value
        if score < value then
            return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, key).ValueStr)
        end
    end
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TempleConstConfig, "SetVoice5").ValueStr)
end

return XTempleModel