local XMineSweepingChapter = XClass(nil, "XMineSweepingChapter")
local XMineSweepingStage = require("XEntity/XMineSweeping/XMineSweepingStage")
local XMineSweepingGrid = require("XEntity/XMineSweeping/XMineSweepingGrid")
function XMineSweepingChapter:Ctor(id)
    self.ChapterId = id
    self.ChallengeCounts = 0
    self.ChapterStatus = XMineSweepingConfigs.StageState.Prepare --章节状态就取自当前关卡状态
    
    self.ActivityStageList = {}
    self.StageEntityDic = {}
    self.CurActivityStageId = 0
    
    self.AllGridEntityDic = {}
    self.CurGridEntityDic = {}
    self.CurGridList = {}
    
    self.IsChapterLock = true
    self.IsInit = true
end

function XMineSweepingChapter:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
    end
    
    if data["ActivityStageList"] then
        self:UpdateAllStageData()
    end
    
    self:UpdateCurActivityStageId()
    
    if self.IsInit then
        self:UpdateAllGridData()
        self.IsInit = false
    end
    
    if data["CurGridList"] then
        self:UpdateCurGridData()
    end
    
    if data["ActivityStageList"] then
        self:UpdateChapterStatus()
    end
end

function XMineSweepingChapter:CreateAllStageData()
    for _,stageId in pairs(self:GetActivityStageIds() or {}) do
        if not self.StageEntityDic[stageId] then
            self.StageEntityDic[stageId] = XMineSweepingStage.New(stageId)
        end
    end
end

function XMineSweepingChapter:UpdateAllStageData()
    for _,stageInfo in pairs(self.ActivityStageList or {}) do
        local id = stageInfo.ActivityStageId
        if self.StageEntityDic[id] then
            self.StageEntityDic[id]:UpdateData(stageInfo)
        end
    end
    self:UpdateStageLock()
end

function XMineSweepingChapter:UpdateAllGridData()
    local curStageId = self.CurActivityStageId
    if not self.AllGridEntityDic[curStageId] then
        self.AllGridEntityDic[curStageId] = {} 
        local curStageEntity = self.StageEntityDic[curStageId]
        if curStageEntity and next(curStageEntity) then
            local rowCount = curStageEntity:GetRowCount()
            local columnCount = curStageEntity:GetColumnCount()
            for y = 1, rowCount do
                for x = 1, columnCount do
                    local entity = XMineSweepingGrid.New(x, y)
                    local key = XMineSweepingConfigs.GetGridKeyByPos(x, y)
                    self.AllGridEntityDic[curStageId][key] = entity
                end
            end
        end
    end
    self.CurGridEntityDic = self.AllGridEntityDic[curStageId]
end

function XMineSweepingChapter:UpdateCurGridData()
    for _,gridData in pairs(self.CurGridList or {}) do
        local key = XMineSweepingConfigs.GetGridKeyByPos(gridData.XIndex, gridData.YIndex)
        local entity = self.CurGridEntityDic and self.CurGridEntityDic[key]
        if entity then
            entity:UpdateData(gridData)
        end
    end
end

function XMineSweepingChapter:UpdateStageLock()
    for _,entity in pairs(self.StageEntityDic or {}) do
        local preStage = XDataCenter.MineSweepingManager.GetPreStageByStageId(entity:GetStageId())
        if preStage and (not next(preStage) or preStage:IsFinish()) then
            entity:UpdateData({IsStageLock = false})
        end
    end
end

function XMineSweepingChapter:GetGridEntityByPos(x, y)
    local key = XMineSweepingConfigs.GetGridKeyByPos(x, y)
    return self.CurGridEntityDic and self.CurGridEntityDic[key]
end

function XMineSweepingChapter:ResetGrid()
    self:UpdateAllGridData()
    
    for _,gridEntity in pairs(self.CurGridEntityDic or {}) do
        gridEntity:ResetGridType()
    end
end

function XMineSweepingChapter:UpdateCurActivityStageId()
    for _,id in pairs(self:GetActivityStageIds() or {}) do
        self.CurActivityStageId = id
        if not self.StageEntityDic[id]:IsFinish() then
            break
        end
    end
end

function XMineSweepingChapter:UpdateChapterStatus()
    local curStageEntity = self:GetCurStageEntity()
    self.ChapterStatus = curStageEntity:GetStageStatus()
    self.IsChapterLock = curStageEntity:IsLock()
end

function XMineSweepingChapter:GetChapterId()
    return self.ChapterId
end

function XMineSweepingChapter:GetChallengeCounts()
    return self.ChallengeCounts
end

function XMineSweepingChapter:GetCurStageEntity()
    return self.StageEntityDic[self.CurActivityStageId]
end

function XMineSweepingChapter:GetStageEntityDic()
    return self.StageEntityDic
end

function XMineSweepingChapter:GetStageEntityById(id)
    return self.StageEntityDic[id]
end

function XMineSweepingChapter:GetCurGridList()
    return self.CurGridList
end

function XMineSweepingChapter:GetAllGridEntityDic()
    return self.AllGridEntityDic
end

function XMineSweepingChapter:GetActivityStageList()
    return self.ActivityStageList
end

function XMineSweepingChapter:GetStageIndexById(id)
    for index,stageId in pairs(self:GetActivityStageIds()) do
        if id == stageId then
            return index
        end
    end
    return
end

function XMineSweepingChapter:IsLock()
    return self.IsChapterLock
end

function XMineSweepingChapter:IsPrepare()
    return self.ChapterStatus == XMineSweepingConfigs.StageState.Prepare
end

function XMineSweepingChapter:IsSweeping()
    return self.ChapterStatus == XMineSweepingConfigs.StageState.Sweeping
end

function XMineSweepingChapter:IsFinish()
    return self.ChapterStatus == XMineSweepingConfigs.StageState.Finish
end

function XMineSweepingChapter:IsFailed()
    return self.ChapterStatus == XMineSweepingConfigs.StageState.Failed
end

function XMineSweepingChapter:GetCfg()
    return XMineSweepingConfigs.GetMineSweepingChapterById(self.ChapterId)
end

function XMineSweepingChapter:GetName()
    return self:GetCfg().Name
end

function XMineSweepingChapter:GetNameEn()
    return self:GetCfg().NameEn
end

function XMineSweepingChapter:GetActivityStageIds()
    return self:GetCfg().ActivityStageIds
end

function XMineSweepingChapter:GetActivityStageIdByIndex(index)
    return self:GetCfg().ActivityStageIds[index]
end

function XMineSweepingChapter:GetStageCount()
    return #self:GetCfg().ActivityStageIds
end

function XMineSweepingChapter:GetShowActivityStageIds()
    return self:GetCfg().ShowActivityStageIds
end

function XMineSweepingChapter:GetShowActivityStageIdByIndex(index)
    return self:GetCfg().ShowActivityStageIds[index]
end

function XMineSweepingChapter:GetCompleteStoryId()
    return self:GetCfg().CompleteStoryId
end

function XMineSweepingChapter:GetCompleteImg()
    return self:GetCfg().CompletePicture
end

function XMineSweepingChapter:GetAllMineImg()
    return self:GetCfg().AllMinePicture
end

function XMineSweepingChapter:GetMineEffect()
    return self:GetCfg().MineEffect
end

function XMineSweepingChapter:GetWinGridEffect()
    return self:GetCfg().WinGridEffect
end

function XMineSweepingChapter:GetMineIcon()
    return self:GetCfg().MineIcon
end

return XMineSweepingChapter