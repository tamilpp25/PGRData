--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local ScoreTowerKey = {
    ScoreTowerActivity = { CacheType = XConfigUtil.CacheType.Normal },
    ScoreTowerChapter = { CacheType = XConfigUtil.CacheType.Normal },
    ScoreTowerFloor = { CacheType = XConfigUtil.CacheType.Normal },
    ScoreTowerRobot = {},
    ScoreTowerStage = { CacheType = XConfigUtil.CacheType.Normal },
    ScoreTowerTower = {},
    ScoreTowerCharTag = {},
    ScoreTowerPlugPoint = {},
    ScoreTowerPlug = {},
    ScoreTowerStrengthen = {},
    ScoreTowerClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key"
    },
    ScoreTowerTag = { DirPath = XConfigUtil.DirectoryType.Client, },
    ScoreTowerCharGroup = { DirPath = XConfigUtil.DirectoryType.Client, },
    ScoreTowerTask = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
}

---@class XScoreTowerModel : XModel
---@field ActivityData XScoreTowerActivity 活动数据
local XScoreTowerModel = XClass(XModel, "XScoreTowerModel")
function XScoreTowerModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("ScoreTower", ScoreTowerKey)

    -- 塔编队数据
    ---@type table<number, XScoreTowerTowerTeam> key :塔Id value :塔编队数据
    self.TowerTeamList = nil
    -- 关卡编队数据
    ---@type table<number, XScoreTowerStageTeam> key :关卡Id value :关卡编队数据
    self.StageTeamList = nil

    -- 排行榜数据
    ---@type XScoreTowerQueryRank
    self.QueryRankData = nil

    -- 是否初始化塔层表
    self.IsInitFloor = false
    -- 塔Id对应的塔层Id列表
    self.TowerIdToFloorIdList = {}

    -- 是否初始化关卡表
    self.IsInitStage = false
    -- 塔层Id对应的关卡Id列表
    self.FloorIdToStageIdList = {}

    -- 是否初始化机器人表
    self.IsInitRobot = false
    -- 机器人组Id对应的机器人Id列表
    self.RobotGroupIdToRobotIdList = {}

    -- 是否初始化强化表
    self.IsInitStrengthen = false
    -- 所有的所属章节Id
    self.BelongChapterIds = {}
    -- 章节Id和槽位对应的强化Id列表
    self.ChapterIdAndSlotToStrengthenIdList = {}

    -- 塔Id对应最终boss关卡Id
    self.TowerIdToBossStageId = {}
    -- 任务组Id列表
    self.TaskGroupIdList = {}
end

function XScoreTowerModel:ClearPrivate()
    --这里执行内部数据清理
end

function XScoreTowerModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.TowerTeamList = nil
    self.StageTeamList = nil
    self.QueryRankData = nil
    self.TowerIdToBossStageId = {}
    self.TaskGroupIdList = {}
end

--region 服务端信息处理

function XScoreTowerModel:NotifyScoreTowerActivityData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerActivity").New()
    end
    self.ActivityData:NotifyScoreTowerActivityData(data)
end

--endregion

--region 获取服务端数据

--region 章节数据

--- 获取当前的章节Id
function XScoreTowerModel:GetCurrentChapterId()
    if not self.ActivityData then
        return 0
    end
    return self.ActivityData:GetCurChapterId() or 0
end

--- 获取所有的章节数据
function XScoreTowerModel:GetAllChapterData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetChapterDatas()
end

--- 获取章节数据
---@param chapterId number 章节Id
function XScoreTowerModel:GetChapterData(chapterId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetChapterData(chapterId)
end

--- 获取章节当前积分
---@param chapterId number 章节ID
function XScoreTowerModel:GetChapterCurPoint(chapterId)
    local chapterData = self:GetChapterData(chapterId)
    if not chapterData then
        return 0
    end
    return chapterData:GetCurPoint() or 0
end

--- 获取章节当前星级
---@param chapterId number 章节ID
function XScoreTowerModel:GetChapterCurStar(chapterId)
    local chapterData = self:GetChapterData(chapterId)
    if not chapterData then
        return 0
    end
    return chapterData:GetCurStar() or 0
end

--endregion

--region 章节记录数据

--- 获取所有的章节记录数据
---@return XScoreTowerChapterRecord[] 章节记录数据列表
function XScoreTowerModel:GetAllChapterRecords()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetChapterRecords()
end

--- 获取章节记录数据
---@param chapterId number 章节Id
---@return XScoreTowerChapterRecord 章节记录数据
function XScoreTowerModel:GetChapterRecord(chapterId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetChapterRecord(chapterId)
end

--endregion

--region 塔数据

--- 获取所有的塔数据
---@param chapterId number 章节Id
function XScoreTowerModel:GetAllTowerData(chapterId)
    local chapterData = self:GetChapterData(chapterId)
    if not chapterData then
        return nil
    end
    return chapterData:GetTowerDatas()
end

--- 获取塔数据
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@return XScoreTowerTower 塔数据
function XScoreTowerModel:GetTowerData(chapterId, towerId)
    local chapterData = self:GetChapterData(chapterId)
    if not chapterData then
        return nil
    end
    return chapterData:GetTowerData(towerId)
end

--- 获取塔已锁定角色Id列表（不包含其它关卡已通关的角色Id）
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 塔层ID
---@param cfgId number ScoreTowerStage表的Id
function XScoreTowerModel:GetTowerLockedCharacterIds(chapterId, towerId, floorId, cfgId)
    -- 获取其它关卡已使用的角色位置
    local otherUsedPos, _ = self:GetStagePassCharacterPos(chapterId, towerId, floorId, cfgId)
    local characterIds = {}
    local characterInfos = self:GetTowerRecordCharacterInfos(towerId)
    for _, info in pairs(characterInfos) do
        if not otherUsedPos[info:GetPos()] then
            table.insert(characterIds, info:GetEntityId())
        end
    end
    return characterIds
end

-- 获取塔扫荡次数
---@param towerId number 塔Id
function XScoreTowerModel:GetTowerSweepRecord(towerId)
    if not self.ActivityData then
        return 0
    end
    return self.ActivityData:GetTowerSweepRecord(towerId)
end

--endregion

--region 塔记录数据

--- 获取所有的塔记录数据
---@return XScoreTowerTowerRecord[] 塔记录数据列表
function XScoreTowerModel:GetAllTowerRecords()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetTowerRecords()
end

--- 获取塔记录数据
---@param towerId number 塔Id
---@return XScoreTowerTowerRecord 塔记录数据
function XScoreTowerModel:GetTowerRecord(towerId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetTowerRecord(towerId)
end

--- 获取塔记录的角色信息列表
---@param towerId number 塔Id
---@return XScoreTowerCharacterInfo[] 角色信息列表
function XScoreTowerModel:GetTowerRecordCharacterInfos(towerId)
    local towerRecord = self:GetTowerRecord(towerId)
    if not towerRecord then
        return {}
    end
    return towerRecord:GetCharacterInfos() or {}
end

--- 获取塔记录的角色Ids列表
---@param towerId number 塔Id
---@return table<number, number> 角色Ids列表 key : 槽位 value : 角色Id
function XScoreTowerModel:GetTowerRecordCharacterIds(towerId)
    local characterInfos = self:GetTowerRecordCharacterInfos(towerId)
    local characterIds = {}
    for _, info in ipairs(characterInfos) do
        characterIds[info:GetPos()] = info:GetEntityId()
    end
    return characterIds
end

--endregion

--region 塔层数据

--- 获取所有的塔层数据
---@param chapterId number 章节Id
---@param towerId number 塔Id
function XScoreTowerModel:GetAllFloorData(chapterId, towerId)
    local towerData = self:GetTowerData(chapterId, towerId)
    if not towerData then
        return nil
    end
    return towerData:GetFloorDatas()
end

--- 获取塔层数据
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 塔层Id
function XScoreTowerModel:GetFloorData(chapterId, towerId, floorId)
    local towerData = self:GetTowerData(chapterId, towerId)
    if not towerData then
        return nil
    end
    return towerData:GetFloorData(floorId)
end

--endregion

--region 关卡数据

--- 获取所有的关卡数据
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@return XScoreTowerStage[] 关卡数据列表
function XScoreTowerModel:GetAllStageData(chapterId, towerId)
    local towerData = self:GetTowerData(chapterId, towerId)
    if not towerData then
        return nil
    end
    return towerData:GetStageDatas()
end

--- 获取关卡数据
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
---@return XScoreTowerStage 关卡数据
function XScoreTowerModel:GetStageData(chapterId, towerId, cfgId)
    local towerData = self:GetTowerData(chapterId, towerId)
    if not towerData then
        return nil
    end
    return towerData:GetStageData(cfgId)
end

--- 获取塔层关卡是否通关
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerModel:IsStagePass(chapterId, towerId, cfgId)
    local stageData = self:GetStageData(chapterId, towerId, cfgId)
    if not stageData then
        return false
    end
    return stageData:GetIsPass() or false
end

--- 获取关卡通关后已上阵角色位置列表
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 塔层Id
---@param cfgId number ScoreTowerStage表的Id
function XScoreTowerModel:GetStagePassCharacterPos(chapterId, towerId, floorId, cfgId)
    local otherUsedPos, curUsedPos = {}, {}
    local stageIds = self:GetStageIdListByFloorId(floorId)
    for _, stageId in pairs(stageIds) do
        local isStagePass = self:IsStagePass(chapterId, towerId, stageId)
        if isStagePass then
            local posIds = self:GetStageRecordTeamPosIds(stageId)
            for _, pos in pairs(posIds) do
                if stageId == cfgId then
                    curUsedPos[pos] = stageId
                else
                    otherUsedPos[pos] = stageId
                end
            end
        end
    end
    return otherUsedPos, curUsedPos
end

--- 获取塔层关卡显示的角色信息列表
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 塔层Id
---@param cfgId number ScoreTowerStage表的Id
---@return { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }[]
function XScoreTowerModel:GetStageShowCharacterInfoList(chapterId, towerId, floorId, cfgId)
    -- 获取其它关卡和当前关卡已使用的角色位置
    local otherUsedPos, curUsedPos = self:GetStagePassCharacterPos(chapterId, towerId, floorId, cfgId)
    local showCharacterInfos = {}
    local characterInfos = self:GetTowerRecordCharacterInfos(towerId)
    for _, info in ipairs(characterInfos) do
        local pos = info:GetPos()
        local stageId = otherUsedPos[pos] or 0
        table.insert(showCharacterInfos, {
            Id = info:GetEntityId(),
            Pos = pos,
            IsUsed = stageId > 0,
            IsNow = curUsedPos[pos] and curUsedPos[pos] == cfgId,
            StageId = stageId
        })
    end
    return showCharacterInfos
end

--endregion

--region 关卡记录数据

--- 获取所有的关卡记录数据
---@return XScoreTowerStageRecord[] 关卡记录数据列表
function XScoreTowerModel:GetAllStageRecords()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageRecords()
end

--- 获取关卡记录数据通过关卡Id
---@param stageCfgId number ScoreTowerStage表Id
---@return XScoreTowerStageRecord
function XScoreTowerModel:GetStageRecord(stageCfgId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageRecord(stageCfgId)
end

--- 获取关卡记录的编队数据
---@param stageCfgId number ScoreTowerStage表Id
---@return XScoreTowerTeam
function XScoreTowerModel:GetStageRecordTeamData(stageCfgId)
    local stageRecord = self:GetStageRecord(stageCfgId)
    if not stageRecord then
        return nil
    end
    return stageRecord:GetTeamData() or {}
end

--- 获取关卡记录的编队角色位置
---@param stageCfgId number ScoreTowerStage表Id
---@return table<number, number> 编队角色位置
function XScoreTowerModel:GetStageRecordTeamPosIds(stageCfgId)
    local recordTeamData = self:GetStageRecordTeamData(stageCfgId)
    if not recordTeamData then
        return {}
    end
    return recordTeamData:GetPosIds() or {}
end

--endregion

--region 强化数据

--- 获取所有的强化数据
---@return XScoreTowerStrengthen[] 强化数据列表
function XScoreTowerModel:GetAllStrengthenData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStrengthens()
end

--- 获取强化数据
---@param strengthenId number 强化Id
---@return XScoreTowerStrengthen 强化数据
function XScoreTowerModel:GetStrengthenData(strengthenId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStrengthen(strengthenId)
end

--endregion

--endregion

--region 活动表相关

---@return XTableScoreTowerActivity
function XScoreTowerModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerActivity, curActivityId)
end

--- 获取活动时间Id
function XScoreTowerModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

--- 获取章节Ids
function XScoreTowerModel:GetActivityChapterIds()
    local config = self:GetActivityConfig()
    return config and config.ChapterIds or {}
end

--- 获取排行榜组Id
function XScoreTowerModel:GetActivityRankGroupId()
    local config = self:GetActivityConfig()
    return config and config.RankGroupId or 0
end

--- 获取排行榜开启时间
function XScoreTowerModel:GetActivityRankOpenTimeId()
    local config = self:GetActivityConfig()
    return config and config.RankOpenTimeId or 0
end

--- 获取排行榜开启条件
function XScoreTowerModel:GetActivityRankOpenConditions()
    local config = self:GetActivityConfig()
    return config and config.RankOpenConditions or {}
end

--endregion

--region 章节表相关

---@return XTableScoreTowerChapter[]
function XScoreTowerModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerChapter)
end

---@param chapterId number 章节Id
---@return XTableScoreTowerChapter
function XScoreTowerModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerChapter, chapterId)
end

-- 获取章节塔Id列表
function XScoreTowerModel:GetChapterTowerIds(chapterId)
    local config = self:GetChapterConfig(chapterId)
    return config and config.TowerIds or {}
end

--- 获取章节机器人组Id
---@param chapterId number 章节ID
function XScoreTowerModel:GetChapterRobotGroupId(chapterId)
    local config = self:GetChapterConfig(chapterId)
    return config and config.RobotGroupId or 0
end

--- 获取章节最后一个塔Id
---@param chapterId number 章节ID
function XScoreTowerModel:GetChapterLastTowerId(chapterId)
    local towerIds = self:GetChapterTowerIds(chapterId)
    return towerIds[#towerIds]
end

--- 获取章节的总星级
---@param chapterId number 章节ID
function XScoreTowerModel:GetChapterTotalStar(chapterId)
    local lastTowerId = self:GetChapterLastTowerId(chapterId)
    local finalBossStageId = self:GetFinalBossStageIdByTowerId(lastTowerId)
    if not XTool.IsNumberValid(finalBossStageId) then
        return 0
    end
    return self:GetStageTotalStar(finalBossStageId)
end

--endregion

--region 层数表相关

---@return XTableScoreTowerFloor[]
function XScoreTowerModel:GetFloorConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerFloor)
end

---@param floorId number 层数Id
---@return XTableScoreTowerFloor
function XScoreTowerModel:GetFloorConfig(floorId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerFloor, floorId)
end

--- 初始化塔层数据
function XScoreTowerModel:InitFloorData()
    if self.IsInitFloor then
        return
    end

    for _, floorConfig in pairs(self:GetFloorConfigs()) do
        local towerId = floorConfig.TowerId
        self.TowerIdToFloorIdList[towerId] = self.TowerIdToFloorIdList[towerId] or {}
        table.insert(self.TowerIdToFloorIdList[towerId], floorConfig.Id)
    end

    self.IsInitFloor = true
end

--- 根据塔Id获取塔层Id列表
---@param towerId number 塔Id
---@return table<number> 塔层Id列表
function XScoreTowerModel:GetFloorIdListByTowerId(towerId)
    self:InitFloorData()
    return self.TowerIdToFloorIdList[towerId] or {}
end

--endregion

--region 机器人表相关

---@return XTableScoreTowerRobot[]
function XScoreTowerModel:GetRobotConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerRobot)
end

---@param robotId number 机器人Id
---@return XTableScoreTowerRobot
function XScoreTowerModel:GetRobotConfig(robotId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerRobot, robotId)
end

--- 初始化机器人数据
function XScoreTowerModel:InitRobotData()
    if self.IsInitRobot then
        return
    end

    for _, robotConfig in pairs(self:GetRobotConfigs()) do
        local robotGroupId = robotConfig.GroupId
        self.RobotGroupIdToRobotIdList[robotGroupId] = self.RobotGroupIdToRobotIdList[robotGroupId] or {}
        table.insert(self.RobotGroupIdToRobotIdList[robotGroupId], robotConfig.RobotId)
    end

    self.IsInitRobot = true
end

--- 根据机器人组Id获取机器人Id列表
---@param robotGroupId number 机器人组Id
---@return table<number> 机器人Id列表
function XScoreTowerModel:GetRobotIdListByRobotGroupId(robotGroupId)
    self:InitRobotData()
    return self.RobotGroupIdToRobotIdList[robotGroupId] or {}
end

--endregion

--region 关卡表相关

---@return XTableScoreTowerStage[]
function XScoreTowerModel:GetStageConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerStage)
end

---@param stageId number 关卡Id
---@return XTableScoreTowerStage
function XScoreTowerModel:GetStageConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerStage, stageId)
end

--- 获取塔层关卡类型
---@param stageId number 关卡Id
function XScoreTowerModel:GetStageType(stageId)
    local config = self:GetStageConfig(stageId)
    return config and config.StageType or 0
end

--- 获取塔层关卡上阵角色数量
---@param stageId number 关卡Id
function XScoreTowerModel:GetStageCharacterNum(stageId)
    local config = self:GetStageConfig(stageId)
    return config and config.CharacterNum or 0
end

--- 获取塔层关卡插件关条目ID
---@param stageId number 塔层关卡ID
function XScoreTowerModel:GetStagePlugPointIds(stageId)
    local config = self:GetStageConfig(stageId)
    return config and config.PlugPointIds or {}
end

--- 获取塔层关卡是否是最终BOSS
---@param stageId number 塔层关卡ID
function XScoreTowerModel:IsStageFinalBoss(stageId)
    local config = self:GetStageConfig(stageId)
    return config and config.IsFinalBoss or false
end

--- 获取塔层关卡BOSS积分星级要求
---@param stageId number 塔层关卡ID
function XScoreTowerModel:GetStageBossFightScore(stageId)
    local config = self:GetStageConfig(stageId)
    return config and config.BossFightScore or {}
end

--- 初始化关卡数据
function XScoreTowerModel:InitStageData()
    if self.IsInitStage then
        return
    end

    for _, stageConfig in pairs(self:GetStageConfigs()) do
        local floorId = stageConfig.FloorId
        self.FloorIdToStageIdList[floorId] = self.FloorIdToStageIdList[floorId] or {}
        table.insert(self.FloorIdToStageIdList[floorId], stageConfig.Id)
    end

    self.IsInitStage = true
end

--- 根据塔层Id获取关卡Id列表
---@param floorId number 塔层Id
---@return table<number> 关卡Id列表
function XScoreTowerModel:GetStageIdListByFloorId(floorId)
    self:InitStageData()
    return self.FloorIdToStageIdList[floorId] or {}
end

--- 获取塔层关卡总星级
---@param stageId number 塔层关卡ID
---@return number 总星级
function XScoreTowerModel:GetStageTotalStar(stageId)
    local bossScores = self:GetStageBossFightScore(stageId)
    return #bossScores
end

--- 获取最终boss的关卡Id
---@param towerId number 塔Id
---@return number 关卡Id ScoreTowerStage表的Id
function XScoreTowerModel:GetFinalBossStageIdByTowerId(towerId)
    if not XTool.IsNumberValid(towerId) then
        return 0
    end
    local cachedStageId = self.TowerIdToBossStageId[towerId]
    if XTool.IsNumberValid(cachedStageId) then
        return cachedStageId
    end
    local floorIds = self:GetFloorIdListByTowerId(towerId)
    for _, floorId in pairs(floorIds) do
        local stageIds = self:GetStageIdListByFloorId(floorId)
        for _, stageId in pairs(stageIds) do
            if self:IsStageFinalBoss(stageId) then
                self.TowerIdToBossStageId[towerId] = stageId
                return stageId
            end
        end
    end
    return 0
end

--endregion

--region 塔表相关

---@return XTableScoreTowerTower[]
function XScoreTowerModel:GetTowerConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerTower)
end

---@return XTableScoreTowerTower
---@param towerId number 塔层Id
function XScoreTowerModel:GetTowerConfig(towerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerTower, towerId)
end

--- 获取塔的上阵角色数量要求
---@param towerId number 塔ID
function XScoreTowerModel:GetTowerCharacterNum(towerId)
    local config = self:GetTowerConfig(towerId)
    return config and config.CharacterNum or 0
end

--- 获取塔的推荐Tag
---@param towerId number 塔ID
function XScoreTowerModel:GetTowerSuggestTagType(towerId)
    local config = self:GetTowerConfig(towerId)
    return config and config.SuggestTagType or {}
end

--- 获取塔的推荐角色组
---@param towerId number 塔ID
function XScoreTowerModel:GetTowerSuggestCharGroup(towerId)
    local config = self:GetTowerConfig(towerId)
    return config and config.SuggestCharGroup or 0
end

--endregion

--region 角色标签表相关

---@return XTableScoreTowerCharTag[]
function XScoreTowerModel:GetCharTagConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerCharTag)
end

---@param characterId number 角色Id
---@return XTableScoreTowerCharTag
function XScoreTowerModel:GetCharTagConfig(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerCharTag, characterId)
end

--- 获取角色标签列表
---@param characterId number 角色ID
function XScoreTowerModel:GetCharacterTagList(characterId)
    local config = self:GetCharTagConfig(characterId)
    return config and config.TagIds or {}
end

--endregion

--region 插件点数表相关

---@return XTableScoreTowerPlugPoint[]
function XScoreTowerModel:GetPlugPointConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerPlugPoint)
end

---@param plugPointId number 插件点数Id
---@return XTableScoreTowerPlugPoint
function XScoreTowerModel:GetPlugPointConfig(plugPointId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerPlugPoint, plugPointId)
end

--- 获取插件点数的类型
---@param plugPointId number 插件点数ID
function XScoreTowerModel:GetPlugPointType(plugPointId)
    local config = self:GetPlugPointConfig(plugPointId)
    return config and config.Type or 0
end

--- 获取插件点数的参数
---@param plugPointId number 插件点数ID
function XScoreTowerModel:GetPlugPointParams(plugPointId)
    local config = self:GetPlugPointConfig(plugPointId)
    return config and config.Params or {}
end

--endregion

--region 插件表相关

---@return XTableScoreTowerPlug[]
function XScoreTowerModel:GetPlugConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerPlug)
end

---@param plugId number 插件Id
---@return XTableScoreTowerPlug
function XScoreTowerModel:GetPlugConfig(plugId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerPlug, plugId)
end

--endregion

--region 强化表相关

---@return XTableScoreTowerStrengthen[]
function XScoreTowerModel:GetStrengthenConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerStrengthen)
end

---@param strengthenId number 强化Id
---@return XTableScoreTowerStrengthen
function XScoreTowerModel:GetStrengthenConfig(strengthenId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerStrengthen, strengthenId)
end

--- 初始化强化数据
function XScoreTowerModel:InitStrengthenData()
    if self.IsInitStrengthen then
        return
    end

    local chapterIds = {}
    for _, strengthenConfig in pairs(self:GetStrengthenConfigs()) do
        local chapterId = strengthenConfig.BelongChapter
        local slot = strengthenConfig.Slot
        chapterIds[chapterId] = true
        self.ChapterIdAndSlotToStrengthenIdList[chapterId] = self.ChapterIdAndSlotToStrengthenIdList[chapterId] or {}
        self.ChapterIdAndSlotToStrengthenIdList[chapterId][slot] = strengthenConfig.Id
    end

    self.BelongChapterIds = {}
    for chapterId, _ in pairs(chapterIds) do
        table.insert(self.BelongChapterIds, chapterId)
    end

    self.IsInitStrengthen = true
end

--- 获取所有的所属章节Id
function XScoreTowerModel:GetAllBelongChapterIds()
    self:InitStrengthenData()
    return self.BelongChapterIds or {}
end

--- 根据章节Id获取强化Id列表
---@param chapterId number 章节Id
function XScoreTowerModel:GetStrengthenIdsByChapterId(chapterId)
    self:InitStrengthenData()
    return self.ChapterIdAndSlotToStrengthenIdList[chapterId] or {}
end

--- 获取强化Buff战力提升列表
---@param strengthenId number 强化ID
function XScoreTowerModel:GetStrengthenBuffPowers(strengthenId)
    local config = self:GetStrengthenConfig(strengthenId)
    return config and config.BuffPower or {}
end

--- 获取强化Buff战力提升
---@param strengthenId number 强化ID
---@param curLv number 当前等级
function XScoreTowerModel:GetStrengthenBuffPower(strengthenId, curLv)
    if curLv <= 0 then
        return 0
    end
    local buffPowers = self:GetStrengthenBuffPowers(strengthenId)
    return buffPowers[curLv] or 0
end

--- 计算强化Buff提升的战力
function XScoreTowerModel:CalStrengthenFightAbility()
    local allStrengthenData = self:GetAllStrengthenData()
    if XTool.IsTableEmpty(allStrengthenData) then
        return 0
    end
    local fightAbility = 0
    for _, strengthenData in pairs(allStrengthenData) do
        local strengthenId = strengthenData:GetCfgId()
        local curLv = strengthenData:GetLv()
        fightAbility = fightAbility + self:GetStrengthenBuffPower(strengthenId, curLv)
    end
    return fightAbility
end

--endregion

--region 标签表相关

---@return XTableScoreTowerTag[]
function XScoreTowerModel:GetTagConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerTag)
end

---@param tagId number 标签Id
---@return XTableScoreTowerTag
function XScoreTowerModel:GetTagConfig(tagId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerTag, tagId)
end

--endregion

--region 角色组表相关

---@return XTableScoreTowerCharGroup[]
function XScoreTowerModel:GetCharGroupConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerCharGroup)
end

---@param groupId number 角色组Id
---@return XTableScoreTowerCharGroup
function XScoreTowerModel:GetCharGroupConfig(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerCharGroup, groupId)
end

--- 获取角色组的角色Id列表
---@param groupId number 角色组Id
function XScoreTowerModel:GetCharGroupCharacterIds(groupId)
    local config = self:GetCharGroupConfig(groupId)
    return config and config.CharacterIds or {}
end

--endregion

--region 任务表相关

---@return XTableScoreTowerTask[]
function XScoreTowerModel:GetTaskConfigs()
    return self._ConfigUtil:GetByTableKey(ScoreTowerKey.ScoreTowerTask)
end

---@param taskId number 任务Id
---@return XTableScoreTowerTask
function XScoreTowerModel:GetTaskConfig(taskId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerTask, taskId)
end

--- 获取任务组Id列表
function XScoreTowerModel:GetTaskGroupIdList()
    if XTool.IsTableEmpty(self.TaskGroupIdList) then
        local configs = self:GetTaskConfigs()
        for _, config in pairs(configs) do
            table.insert(self.TaskGroupIdList, config.Id)
        end
        table.sort(self.TaskGroupIdList)
    end
    return self.TaskGroupIdList
end

--- 获取任务Id列表
---@param taskGroupId number 任务组ID
function XScoreTowerModel:GetTaskIdsByGroupId(taskGroupId)
    local config = self:GetTaskConfig(taskGroupId)
    return config and config.TaskIds or {}
end

--endregion

--region 客户端配置表相关

--- 获取客户端配置参数
---@param key string 配置表Key
function XScoreTowerModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(ScoreTowerKey.ScoreTowerClientConfig, key)
    return config and config.Params or nil
end

--- 获取客户端配置参数
---@param key string 配置表Key
---@param index number 参数索引
function XScoreTowerModel:GetClientConfig(key, index)
    local params = self:GetClientConfigParams(key)
    return params and params[index] or nil
end

--endregion

--region 编队相关

-- 获取所有的机器人Id
---@param chapterId number 章节Id
function XScoreTowerModel:GetAllRobotIds(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return {}
    end
    -- 获取机器人组Id
    local robotGroupId = self:GetChapterRobotGroupId(chapterId)
    if not XTool.IsNumberValid(robotGroupId) then
        return {}
    end
    -- 获取机器人Id列表
    return self:GetRobotIdListByRobotGroupId(robotGroupId)
end

--- 获取塔编队缓存key
---@param towerId number 塔Id
function XScoreTowerModel:GetTowerTeamCacheKey(towerId)
    local activityId = self.ActivityData:GetActivityId()
    return string.format("ScoreTower_TowerTeam_%s_%s_%s", XPlayer.Id, activityId, towerId)
end

--- 获取塔编队数据
---@param towerId number 塔Id
---@return XScoreTowerTowerTeam 塔编队数据
function XScoreTowerModel:GetTowerTeam(towerId)
    self.TowerTeamList = self.TowerTeamList or {}
    if not self.TowerTeamList[towerId] then
        self.TowerTeamList[towerId] = require("XModule/XScoreTower/XEntity/XScoreTowerTowerTeam").New(self:GetTowerTeamCacheKey(towerId))
        -- 设置塔编队槽位
        self.TowerTeamList[towerId]:SetSlotCount(self:GetTowerCharacterNum(towerId))
        -- 同步服务端数据
        self.TowerTeamList[towerId]:SyncServerData(self:GetTowerRecordCharacterInfos(towerId))
    end
    return self.TowerTeamList[towerId]
end

--- 获取关卡编队缓存key
---@param cfgId number ScoreTowerStage表的Id
function XScoreTowerModel:GetStageTeamCacheKey(cfgId)
    local activityId = self.ActivityData:GetActivityId()
    return string.format("ScoreTower_StageTeam_%s_%s_%s", XPlayer.Id, activityId, cfgId)
end

--- 获取关卡编队数据
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表的Id
---@return XScoreTowerStageTeam 关卡编队数据
function XScoreTowerModel:GetStageTeam(towerId, cfgId)
    self.StageTeamList = self.StageTeamList or {}
    if not self.StageTeamList[cfgId] then
        self.StageTeamList[cfgId] = require("XModule/XScoreTower/XEntity/XScoreTowerStageTeam").New(self:GetStageTeamCacheKey(cfgId))
        -- 设置当前角色数量
        self.StageTeamList[cfgId]:SetCurrentEntityLimit(self:GetStageCharacterNum(cfgId))
        -- 同步记录的编队数据
        local recordTeamData = self:GetStageRecordTeamData(cfgId)
        local recordCharacterIds = self:GetTowerRecordCharacterIds(towerId)
        self.StageTeamList[cfgId]:SyncRecordTeamData(recordTeamData, recordCharacterIds)
    end
    return self.StageTeamList[cfgId]
end

--- 关卡编队同步服务端数据
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表的Id
function XScoreTowerModel:SyncStageTeamServerData(towerId, cfgId)
    if not self.StageTeamList or not self.StageTeamList[cfgId] then
        return
    end
    local recordTeamData = self:GetStageRecordTeamData(cfgId)
    local recordCharacterIds = self:GetTowerRecordCharacterIds(towerId)
    self.StageTeamList[cfgId]:SyncRecordTeamData(recordTeamData, recordCharacterIds)
end

--- 获取关卡编队数据通过teamId
---@param teamId number 队伍ID
---@return XScoreTowerStageTeam 队伍数据
function XScoreTowerModel:GetStageTeamByTeamId(teamId)
    for _, stageTeam in pairs(self.StageTeamList) do
        if stageTeam:GetId() == teamId then
            return stageTeam
        end
    end
    return nil
end

--- 请求设置关卡角色通过关卡编队
---@param team XScoreTowerStageTeam 关卡编队
---@param isJoin boolean 是否上阵 true : 上阵  false : 下阵
---@param callback function 回调
function XScoreTowerModel:SetStageTeamRequestByTeam(team, isJoin, callback)
    if not team then
        XLog.Error("error: team is nil")
        return
    end
    local chapterId = team:GetChapterId()
    local towerId = team:GetTowerId()
    local stageCfgId = team:GetStageCfgId()
    local characterPos = { 0, 0, 0 }

    if isJoin then
        local entityIdSet = {}
        local characterInfos = self:GetTowerRecordCharacterInfos(towerId)
        for _, info in ipairs(characterInfos) do
            entityIdSet[info:GetEntityId()] = info:GetPos()
        end
        for index = 1, 3 do
            local entityId = team:GetEntityIdByTeamPos(index)
            characterPos[index] = XTool.IsNumberValid(entityId) and entityIdSet[entityId] or 0
        end
    end

    self:SetStageTeamRequest(chapterId, towerId, stageCfgId, characterPos, callback)
end

--- 请求设置关卡角色
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param characterPos table 角色位置 永远都发3个，没角色就填0
---@param cb function 回调
function XScoreTowerModel:SetStageTeamRequest(chapterId, towerId, stageCfgId, characterPos, cb)
    local req = { StageCfgId = stageCfgId, CharacterPos = characterPos }
    XNetwork.CallWithAutoHandleErrorCode("XScoreTowerSetStageTeamRequest", req, function(res)
        -- 更新关卡数据
        local towerData = self:GetTowerData(chapterId, towerId)
        if towerData then
            towerData:AddStageData(res.StageData)
        end
        -- 更新关卡记录数据
        if self.ActivityData then
            self.ActivityData:AddStageRecord(res.StageRecord)
        end
        if cb then
            cb()
        end
    end)
end

--endregion

--region 角色排序相关

--- 获取塔角色过滤排序
---@param towerId number 塔Id
--- CharacterSortFunType.Custom1 : 一键上阵角色组
--- CharacterSortFunType.Custom2 : 推荐Tag
function XScoreTowerModel:GetTowerCharacterFilterSort(towerId)
    if not XTool.IsNumberValid(towerId) then
        return nil
    end
    return {
        CheckFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isSuggestCharA = self:IsTowerSuggestCharacter(towerId, idA)
                local isSuggestCharB = self:IsTowerSuggestCharacter(towerId, idB)
                if isSuggestCharA ~= isSuggestCharB then
                    return true
                end
            end,
            [CharacterSortFunType.Custom2] = function(idA, idB)
                local isSuggestTagA = self:IsTowerSuggestTag(towerId, idA)
                local isSuggestTagB = self:IsTowerSuggestTag(towerId, idB)
                if isSuggestTagA ~= isSuggestTagB then
                    return true
                end
            end
        },
        SortFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isSuggestCharA = self:IsTowerSuggestCharacter(towerId, idA)
                local isSuggestCharB = self:IsTowerSuggestCharacter(towerId, idB)
                if isSuggestCharA ~= isSuggestCharB then
                    return isSuggestCharA
                end
            end,
            [CharacterSortFunType.Custom2] = function(idA, idB)
                local isSuggestTagA = self:IsTowerSuggestTag(towerId, idA)
                local isSuggestTagB = self:IsTowerSuggestTag(towerId, idB)
                if isSuggestTagA ~= isSuggestTagB then
                    return isSuggestTagA
                end
            end
        }
    }
end

--- 获取塔推荐的角色Id列表
---@param towerId number 塔Id
function XScoreTowerModel:GetTowerSuggestCharacterIds(towerId)
    local suggestCharGroup = self:GetTowerSuggestCharGroup(towerId)
    if not XTool.IsNumberValid(suggestCharGroup) then
        return {}
    end
    return self:GetCharGroupCharacterIds(suggestCharGroup)
end

--- 检查是否是塔推荐角色
---@param towerId number 塔Id
---@param entityId number 实体Id
function XScoreTowerModel:IsTowerSuggestCharacter(towerId, entityId)
    if not XTool.IsNumberValid(entityId) then
        return false
    end
    local suggestCharacterIds = self:GetTowerSuggestCharacterIds(towerId)
    return table.contains(suggestCharacterIds, entityId)
end

--- 检查是否是塔推荐Tag
---@param towerId number 塔Id
---@param entityId number 实体Id
function XScoreTowerModel:IsTowerSuggestTag(towerId, entityId)
    if not XTool.IsNumberValid(entityId) then
        return false
    end
    local suggestTagTypes = self:GetTowerSuggestTagType(towerId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local characterTagList = self:GetCharacterTagList(characterId)
    for _, tagType in pairs(suggestTagTypes) do
        if table.contains(characterTagList, tagType) then
            return true
        end
    end
    return false
end

--- 获取关卡角色过滤排序
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
--- CharacterSortFunType.Custom1 : 推荐Tag
function XScoreTowerModel:GetStageCharacterFilterSort(stageCfgId)
    if not XTool.IsNumberValid(stageCfgId) then
        return nil
    end
    return {
        CheckFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isSuggestTagA = self:IsStageSuggestTag(stageCfgId, idA)
                local isSuggestTagB = self:IsStageSuggestTag(stageCfgId, idB)
                if isSuggestTagA ~= isSuggestTagB then
                    return true
                end
            end
        },
        SortFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isSuggestTagA = self:IsStageSuggestTag(stageCfgId, idA)
                local isSuggestTagB = self:IsStageSuggestTag(stageCfgId, idB)
                if isSuggestTagA ~= isSuggestTagB then
                    return isSuggestTagA
                end
            end
        }
    }
end

--- 检查是否是关卡推荐Tag
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param entityId number 实体Id
function XScoreTowerModel:IsStageSuggestTag(stageCfgId, entityId)
    if not XTool.IsNumberValid(entityId) then
        return false
    end
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local characterTagList = self:GetCharacterTagList(characterId)
    local plugPointIds = self:GetStagePlugPointIds(stageCfgId)
    for _, pointId in pairs(plugPointIds) do
        local pointType = self:GetPlugPointType(pointId)
        local pointParams = self:GetPlugPointParams(pointId)
        if pointType == XEnumConst.ScoreTower.PointType.Tag then
            for _, tagIdStr in pairs(pointParams) do
                if string.IsNumeric(tagIdStr) then
                    local tagId = tonumber(tagIdStr)
                    if table.contains(characterTagList, tagId) then
                        return true
                    end
                end
            end
        elseif pointType == XEnumConst.ScoreTower.PointType.TagCompose then
            for _, tagFormulaStr in pairs(pointParams) do
                local result = string.Split(tagFormulaStr, '|')
                if not string.IsNilOrEmpty(result[2]) and string.IsNumeric(result[2]) then
                    local tagId = tonumber(result[2])
                    if table.contains(characterTagList, tagId) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--endregion

--region 红点相关

--- 检查是否有可领取的任务奖励
---@param taskGroupId number 任务组ID
function XScoreTowerModel:CheckHasCanReceiveTaskReward(taskGroupId)
    local taskIds = self:GetTaskIdsByGroupId(taskGroupId)
    for _, taskId in pairs(taskIds) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

--- 任务按钮是否显示红点
function XScoreTowerModel:IsShowTaskRedPoint()
    local taskGroupIdList = self:GetTaskGroupIdList()
    for _, taskGroupId in pairs(taskGroupIdList) do
        if self:CheckHasCanReceiveTaskReward(taskGroupId) then
            return true
        end
    end
    return false
end

--- 检查章节是否解锁
---@param chapterId number 章节Id
function XScoreTowerModel:IsChapterUnlock(chapterId)
    local config = self:GetChapterConfig(chapterId)
    if not config then
        return false
    end
    local timeId = config.TimeId or 0
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    local preChapterId = config.ChapterIdCondition or 0
    local preChapterScore = config.ScoreCondition or 0
    if not XTool.IsNumberValid(preChapterId) or not XTool.IsNumberValid(preChapterScore) then
        return true
    end
    local currentScore = self:GetChapterCurPoint(preChapterId)
    return currentScore >= preChapterScore
end

--- 检查当前章节是否显示红点
---@param chapterId number 章节Id
function XScoreTowerModel:CheckChapterRedPoint(chapterId)
    -- 章节是否解锁
    if not self:IsChapterUnlock(chapterId) then
        return false
    end
    -- 已点击
    if self:GetChapterClickCache(chapterId) then
        return false
    end
    -- 无挑战记录
    local curStar = self:GetChapterCurStar(chapterId)
    return curStar <= 0
end

--- 是否显示章节红点
function XScoreTowerModel:IsShowChapterRedPoint()
    local chapterIds = self:GetActivityChapterIds()
    for _, chapterId in pairs(chapterIds) do
        if self:CheckChapterRedPoint(chapterId) then
            return true
        end
    end
    return false
end

--- 检查排行榜是否开启
function XScoreTowerModel:IsActivityRankOpen()
    local openTimeId = self:GetActivityRankOpenTimeId()
    if XTool.IsNumberValid(openTimeId) and not XFunctionManager.CheckInTimeByTimeId(openTimeId) then
        return false
    end
    local openConditions = self:GetActivityRankOpenConditions()
    for _, conditionId in pairs(openConditions) do
        if not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--- 是否显示排行榜红点
function XScoreTowerModel:IsShowRankRedPoint()
    return self:IsActivityRankOpen() and not self:GetRankClickCache()
end

--endregion

--region 本地记录相关

--- 获取章节点击缓存key
---@param chapterId number 章节Id
function XScoreTowerModel:GetChapterClickCacheKey(chapterId)
    local activityId = self.ActivityData:GetActivityId()
    return string.format("ScoreTower_ChapterClick_%s_%s_%s", XPlayer.Id, activityId, chapterId)
end

--- 获取章节是否点击
---@param chapterId number 章节Id
function XScoreTowerModel:GetChapterClickCache(chapterId)
    local key = self:GetChapterClickCacheKey(chapterId)
    return XSaveTool.GetData(key) or false
end

--- 保存章节点击
---@param chapterId number 章节Id
function XScoreTowerModel:SaveChapterClickCache(chapterId)
    local key = self:GetChapterClickCacheKey(chapterId)
    XSaveTool.SaveData(key, true)
end

--- 获取排行榜点击缓存key
---@param rankGroupId number 排行榜组Id
function XScoreTowerModel:GetRankClickCacheKey(rankGroupId)
    local activityId = self.ActivityData:GetActivityId()
    return string.format("ScoreTower_RankClick_%s_%s_%s", XPlayer.Id, activityId, rankGroupId)
end

--- 获取排行榜是否点击
function XScoreTowerModel:GetRankClickCache()
    local rankGroupId = self:GetActivityRankGroupId()
    local key = self:GetRankClickCacheKey(rankGroupId)
    return XSaveTool.GetData(key) or false
end

--- 保存排行榜点击
function XScoreTowerModel:SaveRankClickCache()
    local rankGroupId = self:GetActivityRankGroupId()
    local key = self:GetRankClickCacheKey(rankGroupId)
    XSaveTool.SaveData(key, true)
end

--endregion

return XScoreTowerModel
