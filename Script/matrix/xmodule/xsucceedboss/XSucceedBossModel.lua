local TableInsert = table.insert

local XSucceedBossConfigModel = require("XModule/XSucceedBoss/XSucceedBossConfigModel")
local XSucceedBossData = require("XModule/XSucceedBoss/DataEntity/XSucceedBossData")
local XTeam = require("XEntity/XTeam/XTeam")

local SUCCEED_BOSS_TEAM = "SUCCEED_BOSS_TEAM"
local SUCCEED_BOSS_ELEMENT = "SUCCEED_BOSS_ELEMENT"

---@class XSucceedBossModel : XSucceedBossConfigModel
local XSucceedBossModel = XClass(XSucceedBossConfigModel, "XSucceedBossModel")

function XSucceedBossModel:OnInit()
    --初始化内部变量
    self.Super.OnInit(self)

    --- @field 玩法总数据节点 XSucceedBossData
    --self.SucceedBossGameData = XSucceedBossData.New()
    self.SucceedBossGameData = nil

    --self.TeamKey = ""
    --- @field 编队实体 XTeam
    self.Team = nil
    
    self._IsJustEnterFight = false
end

function XSucceedBossModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
    --清理视图层依赖数据
end

function XSucceedBossModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
    --清理服务侧依赖数据
    self.Team = nil
    --self.TeamKey = ""
    self.SucceedBossGameData = nil
end

----------public start----------

--region 服务器数据处理
function XSucceedBossModel:InitSucceedBossGameDataByNotify(data)
    if not data then
        return
    end

    if not self.SucceedBossGameData then
        self.SucceedBossGameData = XSucceedBossData.New()
    end

    self.SucceedBossGameData:UpdateByNotify(data)
end

function XSucceedBossModel:GetTeamKey(chapterId)
    if XTool.IsNumberValid(chapterId) then
        return string.format("%s_%d_%d_%d", SUCCEED_BOSS_TEAM, XPlayer.Id, self.SucceedBossGameData:GetActivityId(), chapterId)
    end

    return string.format("%s_%d_%d", SUCCEED_BOSS_TEAM, XPlayer.Id, self.SucceedBossGameData:GetActivityId())
end

function XSucceedBossModel:GetElementKey(chapterId)
    if XTool.IsNumberValid(chapterId) then
        return string.format("%s_%d_%d_%d", SUCCEED_BOSS_ELEMENT, XPlayer.Id, self.SucceedBossGameData:GetActivityId(), chapterId)
    end
end

function XSucceedBossModel:UpdateBattleInfo(battleInfo)
    self.SucceedBossGameData:UpdateBattleInfo(battleInfo)
end

function XSucceedBossModel:UpdateBattleResults(battleResults)
    if XTool.IsTableEmpty(battleResults) then
        return
    end

    if XTool.IsTableEmpty(self.SucceedBossGameData) then
        return
    end
    
    local battleInfo = self.SucceedBossGameData:GetBattleInfo()

    if XTool.IsTableEmpty(battleInfo) then
        return
    end

    battleInfo:UpdateHistoryResults(battleResults)
end

function XSucceedBossModel:UpdateTeam()
    if not self.Team then
        return
    end

    local teamInfo = self:GetCurTeamInfo()
    if not teamInfo then
        return
    end

    local teamEntityIds = {}
    local characterIds = teamInfo:GetCharacterIds()
    local robotIds = teamInfo:GetRobotIds()
    for i = 1, 3 do
        local entityId = XTool.IsNumberValid(characterIds[i]) and characterIds[i] or robotIds[i]
        entityId = XTool.IsNumberValid(entityId) and entityId or 0
        TableInsert(teamEntityIds, entityId)
    end

    self.Team:UpdateEntityIds(teamEntityIds)
    self.Team:UpdateFirstFightPos(teamInfo:GetFirstFightPos())
    self.Team:UpdateCaptainPos(teamInfo:GetCaptainPos())
end

function XSucceedBossModel:UpdateTeamEntityIds()
    if not self.Team then
        return
    end

    local teamInfo = self:GetCurTeamInfo()
    if not teamInfo then
        return
    end

    local teamEntityIds = {}
    local characterIds = teamInfo:GetCharacterIds()
    local robotIds = teamInfo:GetRobotIds()
    for i = 1, 3 do
        local entityId = XTool.IsNumberValid(characterIds[i]) and characterIds[i] or robotIds[i]
        entityId = XTool.IsNumberValid(entityId) and entityId or 0
        TableInsert(teamEntityIds, entityId)
    end

    self.Team:UpdateEntityIds(teamEntityIds)
end

function XSucceedBossModel:ClearTeam()
    self.Team:Clear()
end

-- 当第一关完成时，保存当前完整编队到本地对应章节上
function XSucceedBossModel:SaveChapterLocalTeam()
    if not self.Team then
        return
    end

    local chapterLocalTeamKey = self:GetTeamKey(self:GetCurChapterId())
    local team = XTeam.New(chapterLocalTeamKey)
    team:Clear()
    team:CopyData(self.Team)
end

-- 清除本地对应章节的编队
function XSucceedBossModel:ClearChapterLocalTeam(chapterId)
    local chapterLocalTeamKey = self:GetTeamKey(chapterId)
    local team = XTeam.New(chapterLocalTeamKey)
    team:Clear()
end

function XSucceedBossModel:UpdateCurBattleProgress(index)
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            battleInfo:UpdateStageProgressIndex(index)
        end
    end
end

function XSucceedBossModel:UpdatePassMonsters(passMonsters)
    if self.SucceedBossGameData then
        self.SucceedBossGameData:UpdatePassMonsters(passMonsters)
    end
end

function XSucceedBossModel:UpdatePassChapters(passChapters)
    if self.SucceedBossGameData then
        self.SucceedBossGameData:UpdatePassChapters(passChapters)
    end
end

function XSucceedBossModel:ClearBattleInfo()
    if self.SucceedBossGameData then
        self.SucceedBossGameData:ClearBattleInfo()
    end
end

function XSucceedBossModel:GetChapterLocalElementId(chapterId)
    local chapterLocalElementKey = self:GetElementKey(chapterId)
    local elementId = XSaveTool.GetData(chapterLocalElementKey)
    if elementId == nil then
        elementId = 0
    end
    
    return elementId
end

function XSucceedBossModel:SaveChapterLocalElementId()
    local elementId = self:GetElementId()
    local chapterId = self:GetCurChapterId()
    local chapterLocalElementKey = self:GetElementKey(chapterId)
    XSaveTool.SaveData(chapterLocalElementKey, elementId)
end

function XSucceedBossModel:ClearChapterLocalElementId(chapterId)
    local chapterLocalElementKey = self:GetElementKey(chapterId)
    XSaveTool.RemoveData(chapterLocalElementKey)
end
--endregion

--region 服务器数据获取
--获取玩法总数据
function XSucceedBossModel:GetSucceedGameData()
    return self.SucceedBossGameData
end

-- 获取当前活动Id
function XSucceedBossModel:GetCurActivityId()
    if self.SucceedBossGameData then
        return self.SucceedBossGameData:GetActivityId()
    end
end

--获取当前章节Id
function XSucceedBossModel:GetCurChapterId()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetChapterId()
        end
    end
end

--获取当前关卡进度
function XSucceedBossModel:GetStageProgressIndex()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetStageProgressIndex() + 1 -- 服务器从0开始
        end
    end
end

-- 获取当前章节的历史记录
function XSucceedBossModel:GetCurChapterHistoryResults()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetHistoryResults()
        end
    end
end

--获取当前关卡信息
function XSucceedBossModel:GetCurStageInfos()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetStageInfos()
        end
    end
end

function XSucceedBossModel:GetFightingChapterId()
    local stageProgressIndex = self:GetStageProgressIndex() -- 当前章节进度
    if stageProgressIndex and stageProgressIndex > 1 then
        return self:GetCurChapterId()
    end
    return false
end

function XSucceedBossModel:GetStageInfo(stageIndex)
    local stageInfos = self:GetCurStageInfos()
    return stageInfos[stageIndex]
end

function XSucceedBossModel:GetCurStageInfo()
    local stageIndex = self:GetStageProgressIndex()
    return self:GetStageInfo(stageIndex)
end

function XSucceedBossModel:GetPassMonster(monsterId)
    if self.SucceedBossGameData then
        return self.SucceedBossGameData:GetPassMonster(monsterId)
    end
end

function XSucceedBossModel:GetElementId()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetElementId()
        end
    end
end

function XSucceedBossModel:GetCurTeamInfo()
    if self.SucceedBossGameData then
        local battleInfo = self.SucceedBossGameData:GetBattleInfo()
        if battleInfo then
            return battleInfo:GetTeamInfo()
        end
    end
end

function XSucceedBossModel:GetTeam(chapterId)
    if XTool.IsTableEmpty(self.Team) then
        self.Team = XTeam.New(self:GetTeamKey())
        self:UpdateTeam()
    end

    if self.Team:GetIsEmpty() and XTool.IsNumberValid(chapterId) then
        local localChapterTeam = XTeam.New(self:GetTeamKey(chapterId))
        if not localChapterTeam:GetIsEmpty() then
            self.Team:CopyData(localChapterTeam)
        end
    end

    return self.Team
end

function XSucceedBossModel:GetPassChapter(chapterId)
    if self.SucceedBossGameData then
        return self.SucceedBossGameData:GetPassChapter(chapterId)
    end
end

--endregion

--region 配置数据获取
function XSucceedBossModel:GetCurActivityConfig()
    if self.SucceedBossGameData then
        local curActivityId = self.SucceedBossGameData:GetActivityId()
        return self:GetSucceedBossActivityById(curActivityId)
    end
end
--endregion

function XSucceedBossModel:SetIsJustEnterFight(value)
    self._IsJustEnterFight = value
end

function XSucceedBossModel:GetIsJustEnterFight()
    return self._IsJustEnterFight
end

----------public end----------

----------private start----------

----------private end----------

return XSucceedBossModel