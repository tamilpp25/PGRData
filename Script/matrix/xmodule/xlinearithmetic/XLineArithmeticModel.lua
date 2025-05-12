local TableKey = {
    LineArithmeticCell = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    LineArithmeticMap = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },

    LineArithmeticActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticChapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XLineArithmeticModel : XModel
local XLineArithmeticModel = XClass(XModel, "XLineArithmeticModel")

function XLineArithmeticModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LineArithmetic", TableKey)

    self._ActivityId = false
    self._CurrentGameData = false
    self._StageRecord = false

    self._EditorGameData = false

    self._CurrentGameStageId = false
    
    self._IsRequesting = false
end

function XLineArithmeticModel:ClearPrivate()
    self._CurrentGameStageId = false
    self._IsRequesting = false
end

function XLineArithmeticModel:ResetAll()
end

function XLineArithmeticModel:GetGridById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticCell, id)
end

function XLineArithmeticModel:GetMapByStageId(stageId)
    local map = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticMap)
    for i, config in pairs(configs) do
        if config.MapId == stageId then
            map[config.Line] = config
        end
    end
    return map
end

function XLineArithmeticModel:GetStageEventCellId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
    if not config then
        return {}
    end
    return config.CellId
end

function XLineArithmeticModel:GetStageStarCondition(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
    if not config then
        return {}
    end
    return config.StarCondition
end

function XLineArithmeticModel:GetStageStarConditionDesc(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
    if not config then
        return {}
    end
    return config.StarDesc
end

function XLineArithmeticModel:GetStageName(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
    if not config then
        return ""
    end
    return config.Name
end

function XLineArithmeticModel:IsPlaying()
    return self._CurrentGameData and true or false
end

function XLineArithmeticModel:SetDataFromServer(serverData)
    self._ActivityId = serverData.ActivityId
    self._CurrentGameData = serverData.CurData
    self._StageRecord = serverData.StageRecords
end

function XLineArithmeticModel:GetCurrentGameData()
    return self._CurrentGameData
end

function XLineArithmeticModel:SetCurrentGameData(gameData)
    --self._CurrentGameData = gameData

    if XMain.IsEditorDebug and gameData then
        self._EditorGameData = gameData
    end
end

function XLineArithmeticModel:GetConfigActivityTimeId(activityId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticActivity, activityId)
    if not config then
        return false
    end
    return config.TimeId
end

function XLineArithmeticModel:GetActivityRemainTime()
    local activityId = self._ActivityId
    local timeId = self:GetConfigActivityTimeId(activityId)
    local currentTime = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local remainTime = endTime - currentTime
    return remainTime
end

function XLineArithmeticModel:GetAllChapter()
    local allChapter = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticChapter)
    return allChapter
end

function XLineArithmeticModel:GetAllChaptersCurrentActivity()
    local chapters = self:GetAllChapter()
    local activityId = self:GetActivityId()
    local result = {}
    for i, chapterConfig in pairs(chapters) do
        if activityId == chapterConfig.ActivityId then
            result[#result + 1] = chapterConfig
        end
    end
    return result
end

function XLineArithmeticModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticChapter, chapterId)
end

function XLineArithmeticModel:GetChapterTitleImg(chapterId)
    local config = self:GetChapterConfig(chapterId)
    if not config then
        return ""
    end
    return config.TitleImg
end

function XLineArithmeticModel:GetActivityId()
    return self._ActivityId
end

function XLineArithmeticModel:GetChapterIdByStageId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
    if not config then
        return false
    end
    return config.ChapterId
end

function XLineArithmeticModel:IsNewChapter(chapterId)
    return XSaveTool.GetData("XLineArithmetic" .. XPlayer.Id .. "/" .. chapterId) == nil
end

function XLineArithmeticModel:SetNotNewChapter(chapterId)
    XSaveTool.SaveData("XLineArithmetic" .. XPlayer.Id .. "/" .. chapterId, true)
end

function XLineArithmeticModel:CheckInTime()
    local activityId = self._ActivityId
    if not activityId then
        return false
    end
    if activityId == 0 then
        return false
    end
    local timeId = self:GetConfigActivityTimeId(activityId)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return isInTime
end

function XLineArithmeticModel:GetStarAmount(chapterId)
    if not self._StageRecord then
        return 0
    end
    local star = 0
    local stageRecord = self._StageRecord
    for i, record in pairs(stageRecord) do
        local stageId = record.StageId
        local recordChapterId = self:GetChapterIdByStageId(stageId)
        if recordChapterId == chapterId and record.Star > 0 then
            star = star + self:HideExtraStar(record.Star)
        end
    end
    return star
end

function XLineArithmeticModel:GetMaxStarAmount(chapterId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticStage)
    local amount = 0
    for i, config in pairs(configs) do
        if config.ChapterId == chapterId then
            amount = amount + self:HideExtraStar(#config.StarCondition)
        end
    end
    return amount
end

function XLineArithmeticModel:HideExtraStar(starAmount)
    --return XMath.Clamp(starAmount, 0, 3)
    -- 开放4星
    return starAmount
end

function XLineArithmeticModel:IsStagePassed(stageId)
    if not self._StageRecord then
        return false
    end
    local stageRecord = self._StageRecord
    for i, record in pairs(stageRecord) do
        if record.StageId == stageId and record.Star >= 0 and record.IsPass then
            return true
        end
    end
    return false
end

function XLineArithmeticModel:GetRewardOnMainUi()
    local activityConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticActivity, self._ActivityId)
    if not activityConfig then
        return {}
    end
    local rewardId = activityConfig.RewardId
    local rewardList = XRewardManager.GetRewardList(rewardId)
    return rewardList
end

function XLineArithmeticModel:GetStageByChapter(chapterId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticStage)
    local stages = {}
    for i, config in pairs(configs) do
        if config.ChapterId == chapterId then
            stages[#stages + 1] = config
        end
    end
    table.sort(stages, function(a, b)
        return a.Id < b.Id
    end)
    return stages
end

function XLineArithmeticModel:GetAllStage()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticStage)
    return configs
end

function XLineArithmeticModel:GetStarAmountByStageId(stageId)
    if not self._StageRecord then
        return 0
    end
    local stageRecord = self._StageRecord
    for i, record in pairs(stageRecord) do
        if record.StageId == stageId then
            if record.Star >= 0 then
                return self:HideExtraStar(record.Star)
            else
                return 0
            end
        end
    end
    return 0
end

function XLineArithmeticModel:GetMaxStarAmountByStageId(stageId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticStage)
    for i, config in pairs(configs) do
        if config.Id == stageId then
            return self:HideExtraStar(#config.StarCondition)
        end
    end
    return 0
end

function XLineArithmeticModel:GetChapterTimeId(chapterId)
    local chapterConfig = self:GetChapterConfig(chapterId)
    if not chapterConfig then
        return 0
    end
    return chapterConfig.TimeId
end

function XLineArithmeticModel:IsChapterOpen(chapterId)
    local timeId = self:GetChapterTimeId(chapterId)

    local isOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    if isOpen then
        local chapterConfig = self:GetChapterConfig(chapterId)
        local preStageId = chapterConfig.PreStageId
        if preStageId and preStageId > 0 then
            isOpen = self:IsStagePassed(preStageId)
        end
    end
    return isOpen
end

function XLineArithmeticModel:IsUnlockHelpBtn()
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticActivity, self._ActivityId)
    if config then
        return config.Help == 1
    end
    return false
end

function XLineArithmeticModel:SaveCurrentGameData2Config()
    local data = self._EditorGameData
    if not data then
        XLog.Error("[XLineArithmeticModel] 当前没有可保存的游戏数据， 请先进行一局游戏")
        return
    end
    XLog.Error(data)
    local stageId = data.StageId
    local operationRecords = data.OperatorRecords
    local toSave = {}
    local id = 0
    for i = 1, #operationRecords do
        local record = operationRecords[i]
        for j = 1, #record.Points do
            id = id + 1
            local point = record.Points[j]
            local pointData = { Id = id, Round = i, X = point.X, Y = point.Y }
            toSave[#toSave + 1] = pointData
        end
    end

    local path = self:GetHelpStageGamePath(stageId, true)
    local headTable = {
        "Id", "Round", "X", "Y"
    }
    local isTable = {}
    local content = self:GetConfigContent(toSave, headTable, isTable)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));
end

function XLineArithmeticModel:GetHelpStageGamePath(stageId, fullPath)
    if fullPath then
        return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/" .. self:GetHelpStageGamePath(stageId)
    end
    local path = "Client/MiniActivity/LineArithmetic/LineArithmeticHelp/LineArithmeticHelp" .. stageId .. ".tab"
    return path
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

function XLineArithmeticModel:GetStageHelpConfig(stageId)
    if XMain.IsWindowsEditor then
        local fullPath = self:GetHelpStageGamePath(stageId, true)
        if not FileExists(fullPath) then
            XLog.Debug("[XLineArithmeticModel] 文件尚不存在:", fullPath)
            return {}
        end
    end

    local path = self:GetHelpStageGamePath(stageId)
    if XMain.IsWindowsEditor then
        self._ConfigUtil:Clear(path)
    end
    if not self._ConfigUtil:HasArgs(path) then
        self._ConfigUtil:InitConfig({
            [path] = { XConfigUtil.ReadType.Int, XTable.XTableLineArithmeticHelp, "Id", XConfigUtil.CacheType.Private },
        })
    end
    local configs = self._ConfigUtil:Get(path)
    if not configs then
        XLog.Debug("[XTempleModel] 文件尚不存在:", stageId)
        return {}
    end
    return configs
end

function XLineArithmeticModel:GetConfigContent(toSave, headTable, isTable)
    local defaultTable = { 0 }

    -- 收集数组
    local headTableAmount = {}
    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local amount = #value
                amount = math.max(amount, 1)
                if (not headTableAmount[key]) or (headTableAmount[key] < amount) then
                    headTableAmount[key] = amount
                end
            else
                headTableAmount[key] = 0
            end
        end
    end

    local contentTable = {}
    for i = 1, #headTable do
        local key = headTable[i]
        local amount = headTableAmount[key] or 0
        if amount == 0 then
            contentTable[#contentTable + 1] = key
            contentTable[#contentTable + 1] = '\t'
        else
            for j = 1, amount do
                contentTable[#contentTable + 1] = key
                contentTable[#contentTable + 1] = '['
                contentTable[#contentTable + 1] = j
                contentTable[#contentTable + 1] = ']'
                contentTable[#contentTable + 1] = '\t'
            end
        end
    end
    contentTable[#contentTable] = nil
    contentTable[#contentTable + 1] = "\r\n"

    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local size = headTableAmount[key]
                for k = 1, size do
                    local element = value[k]
                    if element then
                        contentTable[#contentTable + 1] = element
                    end
                    contentTable[#contentTable + 1] = '\t'
                end
            else
                contentTable[#contentTable + 1] = value
                contentTable[#contentTable + 1] = '\t'
            end
        end
        contentTable[#contentTable] = nil
        contentTable[#contentTable + 1] = "\r\n"
    end
    local content = table.concat(contentTable)
    return content
end

function XLineArithmeticModel:GetNextChapterId(chapterId)
    chapterId = chapterId + 1
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticChapter, chapterId, true)
    if not config then
        return false
    end
    return chapterId
end

function XLineArithmeticModel:SetCurrentGameStageId(stageId)
    self._CurrentGameStageId = stageId
end

function XLineArithmeticModel:IsOnGame(stageId)
    return self._CurrentGameStageId == stageId
end

function XLineArithmeticModel:IsRequesting()
    return self._IsRequesting
end

function XLineArithmeticModel:SetRequesting(value)
    self._IsRequesting = value
end

return XLineArithmeticModel
