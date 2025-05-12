local TableKey = {
    Temple2Stage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    Temple2Grid = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    Temple2Block = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    Temple2Rule = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    Temple2Bubble = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    Temple2Chapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    Temple2Activity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    Temple2Npc = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    Temple2RandomStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    Temple2Map = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    Temple2BlockOption = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    Temple2Chat = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
}

---@class XTemple2Model : XModel
local XTemple2Model = XClass(XModel, "XTemple2Model")

function XTemple2Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/Temple2", TableKey)

    self._ActivityData = false
    ---@alias XTemple2History {StageId:number,Score:number,CharacterId:number,OperatorRecords:XTemple2GameOperation,MapId:number}
    ---@type XTemple2History[]
    self._History = false

    self._CurrentGameStageId = false
end

function XTemple2Model:ClearPrivate()
    self._History = false
end

function XTemple2Model:ResetAll()
    --这里执行重登数据清理
end

function XTemple2Model:GetActivityId()
    if self._ActivityData then
        return self._ActivityData.ActivityId
    end
    return false
end

function XTemple2Model:GetStageGamePath(stageId, fullPath)
    if fullPath then
        return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/" .. self:GetStageGamePath(stageId)
    end
    local path = "Client/MiniActivity/Temple2/Temple2Stage/Temple2Stage" .. stageId .. ".tab"
    return path
end

function XTemple2Model:GetMapConfigList()
    return self._ConfigUtil:GetByTableKey(TableKey.Temple2Map)
end

---@return XTable.XTableTemple2Stage
function XTemple2Model:GetStageConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Stage, stageId)
end

---@return XTable.XTableTemple2Map
function XTemple2Model:GetMapConfig(mapId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Map, mapId)
end

function XTemple2Model:GetStageGameConfig(stageId, isEditor)
    if XMain.IsWindowsEditor then
        local fullPath = self:GetStageGamePath(stageId, true)
        if not XTool.IsFileExists(fullPath) then
            XLog.Debug("[XTemple2Model] 文件尚不存在:", fullPath)
            return false
        end
    end

    local path = self:GetStageGamePath(stageId, false)
    if isEditor then
        self._ConfigUtil:Clear(path)
    end
    if not self._ConfigUtil:HasArgs(path) then
        if isEditor then
            self._ConfigUtil:InitConfig({
                [path] = { XConfigUtil.ReadType.Int, XTable.XTableTemple2StageGame, "Id", XConfigUtil.CacheType.Temp },
            })
        else
            self._ConfigUtil:InitConfig({
                [path] = { XConfigUtil.ReadType.Int, XTable.XTableTemple2StageGame, "Id", XConfigUtil.CacheType.Private },
            })
        end
    end
    local config = self._ConfigUtil:Get(path)
    return config
end

function XTemple2Model:GetGrid(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Grid, id)
end

function XTemple2Model:GetGrids()
    return self._ConfigUtil:GetByTableKey(TableKey.Temple2Grid)
end

function XTemple2Model:EditorGetBlockPath()
    return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/Client/MiniActivity/Temple2/Temple2Block.tab"
end

function XTemple2Model:GetBlock(blockId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Block, blockId)
end

function XTemple2Model:GetAllBlocks()
    if XMain.IsWindowsEditor then
        local fullPath = self:EditorGetBlockPath()
        if not XTool.IsFileExists(fullPath) then
            XLog.Debug("[XTemple2Model] 文件尚不存在:", fullPath)
            return false
        end

        local path = self._ConfigUtil:GetPathByTableKey(TableKey.Temple2Block)
        self._ConfigUtil:Clear(path)
    end
    local blocks = self._ConfigUtil:GetByTableKey(TableKey.Temple2Block)
    return blocks
end

function XTemple2Model:GetAllRules()
    local rules = self._ConfigUtil:GetByTableKey(TableKey.Temple2Rule)
    return rules
end

function XTemple2Model:GetRule(ruleId)
    local rule = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Rule, ruleId)
    return rule
end

function XTemple2Model:GetBubble(bubbleId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Bubble, bubbleId)
    return config
end

function XTemple2Model:SetCurData(curData)
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.CurData = curData
end

function XTemple2Model:SetActivityData(data)
    self._ActivityData = data
    self._History = false
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_STAGE)
end

function XTemple2Model:GiveUpOngoingStage()
    if self._ActivityData then
        self._ActivityData.CurData = false
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_STAGE)
    end
end

function XTemple2Model:SetCharacterData(data)
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.CharacterList = data.CharacterList
end

function XTemple2Model:GetAllChapter()
    return self._ConfigUtil:GetByTableKey(TableKey.Temple2Chapter)
end

function XTemple2Model:GetRemainTime()
    local activityId = self:GetActivityId()
    if activityId then
        local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Activity, activityId)
        if config then
            local timeId = config.TimeId
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
            local currentTime = XTime.GetServerNowTimestamp()
            if currentTime < startTime then
                return 0
            end
            local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
            local remainTime = endTime - currentTime
            remainTime = math.max(remainTime, 0)
            return remainTime
        end
    end
    return 0
end

function XTemple2Model:GetHistory(stageId)
    if self._History == false then
        if self._ActivityData then
            local history = self._ActivityData.History
            self._History = {}
            if history then
                for i = 1, #history do
                    local historyData = history[i]
                    self._History[historyData.StageId] = historyData
                end
            end
        end
    end
    return self._History[stageId]
end

function XTemple2Model:IsStagePassed(stageId)
    local history = self:GetHistory(stageId)
    if history then
        return true
    end
    return false
end

function XTemple2Model:IsStageUnlock(stageId, needTip)
    local reason
    local stageConfig = self:GetStageConfig(stageId)
    if not stageConfig then
        return false
    end
    local timerId = stageConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timerId) then
        if needTip then
            local time = XFunctionManager.GetStartTimeByTimeId(timerId)
            local remainTime = time - XTime.GetServerNowTimestamp()
            reason = XUiHelper.GetText("Temple2UnlockAfterTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY))
        end
        return false, reason
    end
    local preStageId = stageConfig.PreStageId
    if preStageId == 0 then
        return true
    end
    if not self:IsStagePassed(preStageId) then
        if needTip then
            reason = XUiHelper.GetText("Temple2PreStage")
        end
        return false, reason
    end
    return true
end

function XTemple2Model:GetStageOngoing()
    if self._ActivityData then
        if self._ActivityData.CurData then
            local stageId = self._ActivityData.CurData.StageId
            if stageId == 0 then
                return false
            end
            return stageId
        end
    end
    return false
end

function XTemple2Model:GetStageRecordOngoing()
    if self._ActivityData then
        return self._ActivityData.CurData
    end
end

---@return XTable.XTableTemple2Npc[]
function XTemple2Model:GetAllCharacter()
    return self._ConfigUtil:GetByTableKey(TableKey.Temple2Npc)
end

---@return XTable.XTableTemple2Npc[]
function XTemple2Model:GetCharacter(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Npc, npcId)
end

-- 每天角色都会轮换
function XTemple2Model:GetCharacterToday()
    if self._ActivityData then
        return self._ActivityData.CharacterList
    end
    return false
end

function XTemple2Model:GetHistoryScore(stageId)
    local history = self:GetHistory(stageId)
    if history then
        return history.Score
    end
    return 0
end

function XTemple2Model:GetAllStory()
    local bubbles = self._ConfigUtil:GetByTableKey(TableKey.Temple2Bubble)
    local result = {}
    for i, config in pairs(bubbles) do
        if config.StoryId and config.StoryId ~= "" then
            result[#result + 1] = config
        end
    end
    return result
end

function XTemple2Model:IsStoryUnlock(id)
    if self._ActivityData then
        local plot = self._ActivityData.Plot
        for i = 1, #plot do
            if plot[i] == id then
                return true
            end
        end
    end
    return false
end

function XTemple2Model:SetStoryUnlock(id)
    self._ActivityData = self._ActivityData or {}
    if self._ActivityData then
        self._ActivityData.Plot = self._ActivityData.Plot or {}
        table.insert(self._ActivityData.Plot, id)
    end
end

function XTemple2Model:CheckInTime()
    local activityId = self:GetActivityId()
    if activityId then
        local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Activity, activityId)
        if config then
            local timeId = config.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                return true
            end
        end
    end
    return false
end

function XTemple2Model:GetRewardId()
    local activityId = self:GetActivityId()
    if activityId then
        local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Temple2Activity, activityId)
        if config then
            return config.RewardId
        end
    end
    return false
end

function XTemple2Model:GetBlockOptions()
    local blockOptions = self._ConfigUtil:GetByTableKey(TableKey.Temple2BlockOption)
    return blockOptions
end

function XTemple2Model:GetAllChat()
    return self._ConfigUtil:GetByTableKey(TableKey.Temple2Chat)
end

function XTemple2Model:GetAllRandomMap(stageId)
    local allStage = self._ConfigUtil:GetByTableKey(TableKey.Temple2RandomStage, stageId)
    local allMap = {}
    for i, config in pairs(allStage) do
        if config.StageId == stageId then
            if XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
                for i = 1, #config.MapId do
                    local mapId = config.MapId[i]
                    allMap[mapId] = true
                end
            end
        end
    end
    return allMap
end

function XTemple2Model:SetCurrentGameStageId(value)
    self._CurrentGameStageId = value
end

function XTemple2Model:GetCurrentGameStageId()
    return self._CurrentGameStageId
end

return XTemple2Model