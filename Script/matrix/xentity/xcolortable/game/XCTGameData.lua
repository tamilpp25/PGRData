local XCTGameData = XClass(nil, "XCTGameData")

function XCTGameData:Ctor()
    self:Init()
end

function XCTGameData:UpdateData(data)
    self:SetStageId(data.StageId)
    self:SetMapId(data.MapId)
    self:SetCaptainId(data.CaptainId)
    self:SetRoundId(data.RoundId)
    self:SetCurStage(data.CurStage)
    self:SetIsLose(data.IsLose)
    self:SetActionPoint(data.ActionPoint)
    self:SetCurPosition(data.CurPosition)
    self:SetTimeBlock(data.TimeBlock)
    self:SetTimelineId(data.TimelineId)
    self:SetWinConditionId(data.WinConditionId)
    self:SetBossLevels(data.BossLevels)
    self:SetStudyDatas(data.StudyDatas)
    self:SetStudyLevels(data.StudyLevels)

    self.StudyLevelLimit = XColorTableConfigs.GetMapStudyLevelLimit(self._MapId)
end


-- Public
--=================================================================

-- 重置数据
function XCTGameData:Init()
    self._StageId = nil          -- 关卡
    self._MapId = nil            -- 地图
    self._CaptainId = nil        -- 队长
    self._RoundId = nil          -- 回合数
    self._CurStage = nil         -- 当前阶段，1地图，2关卡
    self._IsLose = nil           -- 是否失败
    self._ActionPoint = nil      -- 当前行动力
    self._CurPosition = nil      -- 当前位置
    self._TimeBlock = nil        -- 时间方块
    self._TimelineId = nil       -- 时间轴位置
    self._WinConditionId = nil   -- 当前地图玩法胜利的胜利条件
    self._BossLevels = {}        -- boss等级
    self._StudyDatas = {}        -- 研究数据
    self._StudyLevels = {}       -- 研究等级

    self.StudyLevelLimit = 0     -- 研究等级上限
    self.TriggerDramaData = {}   -- 触发的剧情数据(本地缓存)
    self.TalkDramaData = {}      -- 客户端类剧情触发条件计数(本地缓存)
end

function XCTGameData:CheckIsInPosition(position)
    return self._CurPosition == position
end

function XCTGameData:CheckIsHideBoss()
    if not XTool.IsNumberValid(self._StageId) then
        return false
    end
    local specialStageId = XColorTableConfigs.GetStageSpecialWinConditionId(self._StageId)
    return XTool.IsNumberValid(specialStageId)
end

function XCTGameData:CheckIsFirstGuideStage()
    local stageType = XColorTableConfigs.GetStageType(self._StageId)
    return stageType == XColorTableConfigs.StageType.FirstGuide
end

function XCTGameData:CheckIsGuideStage()
    local stageType = XColorTableConfigs.GetStageType(self._StageId)
    return stageType == XColorTableConfigs.StageType.FirstGuide or stageType == XColorTableConfigs.StageType.SecondGuide
end

function XCTGameData:CheckIsStudyLevelMax(colorType)
    return self:GetStudyLevels(colorType) >= self.StudyLevelLimit
end

function XCTGameData:CheckBossIsKill(colorType)
    return self:GetBossLevels(colorType) == 0
end

function XCTGameData:AddTriggerDramaData(dramaId, colorType, index)
    local data = {
        DramaId = dramaId,
        ColorType = colorType,
        Index = index,
        IsRead = false,
    }
    table.insert(self.TriggerDramaData, data)
    self:SaveData()
end

function XCTGameData:AddTalkDramaData(dramaId, value)
    if not XTool.IsTableEmpty(self.TalkDramaData[dramaId]) then
        self.TalkDramaData[dramaId].Count = self.TalkDramaData[dramaId].Count + value
    else
        local data = {
            DramaId = dramaId,
            Count = value,
            IsRead = false,
        }
        self.TalkDramaData[dramaId] = data
    end
end

function XCTGameData:LoadData()
    self:LoadTriggerDrama()
    self:LoadTalkDramaData()
end

function XCTGameData:LoadTriggerDrama()
    local data = XSaveTool.GetData(self:GetLocalSaveKey())
    if not data then return end
    for key, value in pairs(data.Trigger) do
        self.TriggerDramaData[key] = value
    end
end

function XCTGameData:LoadTalkDramaData()
    local data = XSaveTool.GetData(self:GetLocalSaveKey())
    if not data then return end
    for key, value in pairs(data.TalkDrama) do
        self.TalkDramaData[key] = value
    end
end

function XCTGameData:InitTalkDramaData()
    self:LoadTalkDramaData()
    for key, data in pairs(self.TalkDramaData) do
        if XColorTableConfigs.GetDramaRepeatable(key) then
            data.Count = 0
            data.IsRead = false
        end
    end
    self:SaveData()
end

function XCTGameData:SaveData()
    XSaveTool.SaveData(self:GetLocalSaveKey(), {
        Trigger = self.TriggerDramaData,
        TalkDrama = self.TalkDramaData,
    })
end

--=================================================================



-- Private
--=================================================================

function XCTGameData:GetLocalSaveKey()
    return XDataCenter.ColorTableManager.GetActivitySaveKey() .. "GameData" .. self._StageId
end

--=================================================================



-- Setter
--=================================================================

function XCTGameData:SetStageId(value)
    self._StageId = value
end

function XCTGameData:SetMapId(value)
    self._MapId = value
end

function XCTGameData:SetCaptainId(value)
    self._CaptainId = value
end

function XCTGameData:SetRoundId(value)
    self._RoundId = value
end

function XCTGameData:SetCurStage(value)
    self._CurStage = value
end

function XCTGameData:SetIsLose(value)
    self._IsLose = value
end

function XCTGameData:SetActionPoint(value)
    self._ActionPoint = value
end

function XCTGameData:SetCurPosition(value)
    self._CurPosition = value
end

function XCTGameData:SetTimeBlock(value)
    self._TimeBlock = value
end

function XCTGameData:SetTimelineId(value)
    self._TimelineId = value
end

function XCTGameData:SetWinConditionId(value)
    self._WinConditionId = value
end

function XCTGameData:SetBossLevels(value)
    self._BossLevels = value
end

function XCTGameData:SetStudyDatas(value)
    self._StudyDatas = value
end

function XCTGameData:SetStudyLevels(value)
    self._StudyLevels = value
end

function XCTGameData:SetReadDrama(dramaId)
    for index, data in ipairs(self.TriggerDramaData) do
        if data.DramaId == dramaId then
            self.TriggerDramaData[index].IsRead = true
        end
    end
    self:SaveData()
end

--=================================================================



-- Getter
--=================================================================

function XCTGameData:GetStageId()
    return self._StageId
end

function XCTGameData:GetMapId()
    return self._MapId
end

function XCTGameData:GetCaptainId()
    return self._CaptainId
end

function XCTGameData:GetRoundId()
    return self._RoundId
end

function XCTGameData:GetCurStage()
    return self._CurStage
end

function XCTGameData:GetIsLose()
    return self._IsLose
end

function XCTGameData:GetActionPoint()
    return self._ActionPoint
end

function XCTGameData:GetCurPosition()
    return self._CurPosition
end

function XCTGameData:GetTimeBlock()
    return self._TimeBlock
end

function XCTGameData:GetTimelineId()
    return self._TimelineId
end

function XCTGameData:GetWinConditionId()
    return self._WinConditionId
end

function XCTGameData:GetBossLevels(colorType)
    if not XTool.IsNumberValid(colorType) then
        return self._BossLevels
    end
    if not XTool.IsNumberValid(self._BossLevels[colorType]) then
        self._BossLevels[colorType] = 0
    end
    return self._BossLevels[colorType]
end

function XCTGameData:GetStudyDatas(colorType)
    if not XTool.IsNumberValid(colorType) then
        return self._StudyDatas
    end
    if not XTool.IsNumberValid(self._StudyDatas[colorType]) then
        self._StudyDatas[colorType] = 0
    end
    return self._StudyDatas[colorType]
end

function XCTGameData:GetStudyLevels(colorType)
    if not XTool.IsNumberValid(colorType) then
        return self._StudyLevels
    end
    if not XTool.IsNumberValid(self._StudyLevels[colorType]) then
        self._StudyLevels[colorType] = 0
    end
    return self._StudyLevels[colorType]
end

function XCTGameData:GetTriggerDramaData()
    return self.TriggerDramaData
end

function XCTGameData:GetDramaData(dramaId)
    for _, data in ipairs(self.TriggerDramaData) do
        if data.DramaId == dramaId then
            return data
        end
    end
end

-- 客户端对话剧情开启计数
function XCTGameData:GetTalkDramaData(dramaId)
    for _, data in pairs(self.TalkDramaData) do
        if data.DramaId == dramaId then
            return data
        end
    end
end

--=================================================================

return XCTGameData