---@class XAreaWarEnterFightInfo
---@field Id number
---@field StageId number
---@field IsQuest boolean
---@field FightCount number


local XAreaWarQuest = require("XEntity/XAreaWar/XAreaWarQuest")

---@class XAreaWarPersonal 玩家个人信息
---@field _Level number 当前的等级
---@field _BuffList number[] 当前的等级解锁的所有Buff
---@field _Exp number 当前Exp
---@field _EnterFightInfo XAreaWarEnterFightInfo 进入战斗前保存的一些信息
---@field _QuestDict table<number, XAreaWarQuest> 个人任务信息
local XAreaWarPersonal = XClass(nil, "XAreaWarPersonal")

local ExpItemId

local CompareNum = function(a, b) 
    return a < b
end

function XAreaWarPersonal:Ctor()
    self._LikeCount = 0
    self._EnterFightInfo = {}
    self._QuestDict = {}
    self._MaxRescueRefreshCount = XAreaWarConfigs.GetMaxRescueRefreshCount()
    self._MaxRescueRewardCount = XAreaWarConfigs.GetMaxRescueRewardCount()
    self._RescueRefreshCount = 0
    self._RandomTimeStamp = 0 --随机探索任务时的时间戳
    self._CoinRecord = 0 --货币累积数
    self._IsInitLocal = false
    ExpItemId = XDataCenter.ItemManager.ItemId.AreaWarPersonalExp
    self:UpdateLevelAndBuff()

    self._LastLevel = self._Level
    self._LastBuffList = XTool.Clone(self._BuffList)

    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX ..
            ExpItemId, self.OnExpChanged, self)
end

function XAreaWarPersonal:Release()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX ..
            ExpItemId, self.OnExpChanged, self)
end

function XAreaWarPersonal:OnExpChanged()
    self._Dirty = true
end

function XAreaWarPersonal:UpdateData(dailyQuests, rescueQuests, refreshCount, coidRecord)
    self._QuestDict = {}
    self:UpdateQuests(dailyQuests)
    self:UpdateQuests(rescueQuests)
    self:SetRescueRefreshCount(refreshCount)
    self:SetCoinRecord(coidRecord)
    local nextRefreshTime = XTime.GetSeverNextRefreshTime()
    if nextRefreshTime ~= self._RandomTimeStamp then
        self:TryClearLocal()
        self._RandomTimeStamp = nextRefreshTime
    end

    self:TryInitLocal()
end

function XAreaWarPersonal:SetCoinRecord(coidRecord)
    if not coidRecord then
        return
    end
    self._CoinRecord = coidRecord
end

function XAreaWarPersonal:GetCoinRecord()
    return self._CoinRecord
end

function XAreaWarPersonal:IsLevelUp()
    return self:GetLevel() ~= self._LastLevel
end

function XAreaWarPersonal:UpdateLevelCache()
    self._LastLevel = self:GetLevel()
    self._LastBuffList = XTool.Clone(self._BuffList)
end

function XAreaWarPersonal:IsMaxLevel(level)
    level = level or self:GetLevel()
    return level >= XAreaWarConfigs.GetMaxLevel()
end

function XAreaWarPersonal:GetLevel()
    if not self._Dirty then
        return self._Level
    end
    self:UpdateLevelAndBuff()

    return self._Level
end

function XAreaWarPersonal:GetBuffList()
    if not self._Dirty then
        return self._BuffList
    end
    self:UpdateLevelAndBuff()

    return self._BuffList
end

function XAreaWarPersonal:GetUnlockBuffDict()
    local buffList = self:GetBuffList()
    local dict = {}
    for _, buffId in ipairs(buffList) do
        dict[buffId] = buffId
    end
    return dict
end

--获取上一次升级与当前等级新增的Buff
function XAreaWarPersonal:GetAddBuffList()
    local dict = {}
    for _, buffId in ipairs(self._LastBuffList) do
        dict[buffId] = true
    end

    local list = {}
    local buffList = self:GetBuffList()
    for _, buffId in ipairs(buffList) do
        if not dict[buffId] then
            table.insert(list, buffId)
        end
    end

    return list
end

function XAreaWarPersonal:GetExpProgress()
    local level = self:GetLevel()
    if self:IsMaxLevel(level) then
        return 1
    end
    local exp = self:GetExp()
    --升级到下一级需要的经验
    local totalExp = XAreaWarConfigs.GetLevelExp(level + 1)
    return exp / totalExp
end

function XAreaWarPersonal:GetExp()
    local level = self:GetLevel()
    if self:IsMaxLevel(level) then
        return 0
    end
    --升级到当前等级需要的总经验
    local total = XAreaWarConfigs.GetTotalExp(level)
    local own = XDataCenter.ItemManager.GetCount(ExpItemId)
    return math.max(0, own - total)
end

function XAreaWarPersonal:GetSkipNum()
    return XAreaWarConfigs.GetGrowSkilNum(self:GetLevel())
end

function XAreaWarPersonal:GetAddSkipNum()
    local last = XAreaWarConfigs.GetGrowSkilNum(self._LastLevel)
    local cur = self:GetSkipNum()

    return math.max(0, cur - last)
end

function XAreaWarPersonal:GetLevelName()
    return XAreaWarConfigs.GetGrowName(self:GetLevel())
end

function XAreaWarPersonal:GetSelectSkipNum(ratio)
    local key = XDataCenter.AreaWarManager.GetCookieKey("SelectRepeatCount")
    local count = 1
    local localData = XSaveTool.GetData(key)
    if localData then
        count = localData
    end
    local ownCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.AreaWarActionPoint)
    local runCount = math.floor(ownCount / ratio)
    if runCount <= 0 then
        return count
    end
    return math.min(runCount, count)
end

function XAreaWarPersonal:SetSelectLocal(count)
    local key = XDataCenter.AreaWarManager.GetCookieKey("SelectRepeatCount")
    XSaveTool.SaveData(key, count)
end

function XAreaWarPersonal:IsNewSkipNum()
    local key = XDataCenter.AreaWarManager.GetCookieKey("MaxSelectRedPoint")
    return XSaveTool.GetData(key) ~= self:GetSkipNum()
end

function XAreaWarPersonal:MarkNewSkipNum()
    local key = XDataCenter.AreaWarManager.GetCookieKey("MaxSelectRedPoint")
    XSaveTool.SaveData(key, self:GetSkipNum())
end

function XAreaWarPersonal:IsOpenMultiChallenge()
    return self:GetSkipNum() > 1
end

function XAreaWarPersonal:UpdateLevelAndBuff()
    local exp = XDataCenter.ItemManager.GetCount(ExpItemId)
    local level, buff = XAreaWarConfigs.GetLevelAndBuffDict(exp)
    self._Level = level
    self._BuffList = buff

    self._Dirty = false
end

function XAreaWarPersonal:SetLikeCount(count)
    self._LikeCount = count
end

function XAreaWarPersonal:GetLikeCount()
    return self._LikeCount
end

function XAreaWarPersonal:SetFightData(id, stageId, isQuest, fightCount)
    self._EnterFightInfo.Id = id
    self._EnterFightInfo.StageId = stageId
    self._EnterFightInfo.IsQuest = isQuest
    self._EnterFightInfo.FightCount = fightCount
end

function XAreaWarPersonal:GetFightData()
    return self._EnterFightInfo
end

function XAreaWarPersonal:UpdateQuests(quests)
    if XTool.IsTableEmpty(quests) then
        return
    end
    for _, questData in ipairs(quests) do
        local questId = questData.Id
        local quest = self:GetQuest(questId)
        quest:UpdateData(questData)
    end
end

function XAreaWarPersonal:UpdateSingle(questData)
    if not questData then
        return
    end
    local questId = questData.Id
    if not questId then
        return
    end
    local quest = self:GetQuest(questId)
    quest:UpdateData(questData)
end

function XAreaWarPersonal:GetQuest(questId)
    local quest = self._QuestDict[questId]
    if quest then
        return quest
    end
    quest = XAreaWarQuest.New(questId)
    self._QuestDict[questId] = quest
    return quest
end

--- 获取个人任务完成，未完成数量
---@return number, number
--------------------------
function XAreaWarPersonal:GetDailyQuestCount()
    local finish, undone = 0, 0
    for _, data in pairs(self._QuestDict) do
        if data:IsFight() or data:IsBeRescued() then
            if data:IsFinsh() then
                finish = finish + 1
            else
                undone = undone + 1
            end
        end
    end
    return finish, undone
end

--- 获取救援任务完成，未完成数量
---@return number, number
--------------------------
function XAreaWarPersonal:GetRescueQuestCount()
    local finish, undone = 0, 0
    for _, data in pairs(self._QuestDict) do
        if data:IsRescue() then
            if data:IsFinsh() then
                finish = finish + 1
            else
                undone = undone + 1
            end
        end
    end
    return finish, undone
end

function XAreaWarPersonal:GetDailyQuestList(isFinish)
    isFinish = isFinish or false
    local list = {}
    for _, data in pairs(self._QuestDict) do
        if data:IsFinsh() == isFinish and (data:IsFight() or data:IsBeRescued()) then
            table.insert(list, data:GetId())
        end
    end

    table.sort(list, CompareNum)
    
    return list
end

function XAreaWarPersonal:GetRescueQuestList(isFinish)
    isFinish = isFinish or false

    local list = {}
    for _, data in pairs(self._QuestDict) do
        if data:IsFinsh() == isFinish and data:IsRescue() then
            table.insert(list, data:GetId())
        end
    end

    table.sort(list, CompareNum)
    return list
end

function XAreaWarPersonal:GetAllDailyList(isClear)
    local list = {}
    for _, data in pairs(self._QuestDict) do
        if data:IsFight() or data:IsBeRescued() then
            table.insert(list, data:GetId())
        end
    end
    if isClear then
        for _, questId in pairs(list) do
            self._QuestDict[questId] = nil
        end
    end
    return list
end

function XAreaWarPersonal:GetAllRescueList(isClear)
    local list = {}
    for _, data in pairs(self._QuestDict) do
        if data:IsRescue() then
            table.insert(list, data:GetId())
        end
    end
    if isClear then
        for _, questId in pairs(list) do
            self._QuestDict[questId] = nil
        end
    end
    return list
end

function XAreaWarPersonal:IsFinishDailyQuest()
    local finishCount, _ = self:GetDailyQuestCount()
    local total = XAreaWarConfigs.GetDailyBattleNum()

    return finishCount >= total
end

function XAreaWarPersonal:SetRescueRefreshCount(value)
    self._RescueRefreshCount = value or 0
end

function XAreaWarPersonal:RefreshRescue(quests)
    self._RescueRefreshCount = self._RescueRefreshCount + 1
    self:UpdateQuests(quests)
    self:ClearRescueLocalRandomIndex()
end

function XAreaWarPersonal:GetRescueRefreshCount()
    return self._RescueRefreshCount, self._MaxRescueRefreshCount
end

function XAreaWarPersonal:IsMaxRescueRefresh()
    return self._RescueRefreshCount >= self._MaxRescueRefreshCount
end

function XAreaWarPersonal:IsMaxRescueReward()
    local finish, _ = self:GetRescueQuestCount()
    return finish >= self._MaxRescueRewardCount
end

function XAreaWarPersonal:GetLocalDailyIndex(questId, index)
    if not self._RandomDailyDict then
        self._RandomDailyDict = {}
    end
    return self:GetLocalIndex(self._RandomDailyDict, questId, index)
end

function XAreaWarPersonal:GetDailyQuestLocalKey()
    return XDataCenter.AreaWarManager.GetCookieKey("DailyQuestRandomDict_" .. self._RandomTimeStamp)
end

function XAreaWarPersonal:GetRescueQuestLocalKey()
    return XDataCenter.AreaWarManager.GetCookieKey("RescueQuestRandomDict_" .. self._RandomTimeStamp)
end

function XAreaWarPersonal:GetRandomBlockIdKey()
    return XDataCenter.AreaWarManager.GetCookieKey("RandomBlockIds_" .. self._RandomTimeStamp)
end

function XAreaWarPersonal:GetFocusBlockKey()
    return XDataCenter.AreaWarManager.GetCookieKey("FocusBlock_" .. self._RandomTimeStamp)
end

function XAreaWarPersonal:CheckTodayFocus()
    local key = self:GetFocusBlockKey()
    local data = XSaveTool.GetData(key)
    return not data
end

function XAreaWarPersonal:MarkTodayFocus()
    local key = self:GetFocusBlockKey()
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XAreaWarPersonal:SetLocalDailyRandomDict()
    local key = self:GetDailyQuestLocalKey()
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, self._RandomDailyDict)
end

function XAreaWarPersonal:ClearDailyLocalRandomIndex()
    local key = self:GetDailyQuestLocalKey()
    XSaveTool.RemoveData(key)
    self._RandomDailyDict = nil
end

function XAreaWarPersonal:GetLocalRescueIndex(questId, index)
    if not self._RandomRescueDict then
        self._RandomRescueDict = {}
    end

    return self:GetLocalIndex(self._RandomRescueDict, questId, index)
end

function XAreaWarPersonal:SetLocalRescueRandomDict()
    local key = self:GetRescueQuestLocalKey()
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, self._RandomRescueDict)
end

--由于救援任务可以多次刷新，每次刷新时，清理掉上次的缓存
function XAreaWarPersonal:ClearRescueLocalRandomIndex()
    local key = self:GetRescueQuestLocalKey()
    XSaveTool.RemoveData(key)
    self._RandomRescueDict = nil
end

function XAreaWarPersonal:GetRandomBlockIds()
    local key = self:GetRandomBlockIdKey()
    local data = XSaveTool.GetData(key)
    if data then
        return data
    end
    return self:GetTargetBlockIds()
end

function XAreaWarPersonal:GetTargetBlockIds()
    if XDataCenter.AreaWarManager.IsRepeatChallengeTime() then
        local chapterIds = XAreaWarConfigs.GetChapterIds()
        local chapterCount = #chapterIds
        for i = chapterCount, 1, -1 do
            local chapterId = chapterIds[i]
            if XAreaWarConfigs.CheckChapterInTime(chapterId) then
                local bossBlockId = XAreaWarConfigs.GetBossBlockIdByChapterId(chapterId)
                return { bossBlockId }
            end
        end
    end

    return XDataCenter.AreaWarManager.GetFightingBlockIds()
end

function XAreaWarPersonal:TrySetRandomBlockIds(blockIds)
    local key = self:GetRandomBlockIdKey()
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, blockIds)
end

function XAreaWarPersonal:TryClearLocal()
    if not self._RandomTimeStamp or self._RandomTimeStamp <= 0 then
        return
    end
    local key1 = self:GetDailyQuestLocalKey()
    local key2 = self:GetRescueQuestLocalKey()
    local key3 = self:GetRandomBlockIdKey()
    XSaveTool.RemoveData(key1)
    XSaveTool.RemoveData(key2)
    XSaveTool.RemoveData(key3)

    self._RandomDailyDict = nil
    self._RandomRescueDict = nil
end

function XAreaWarPersonal:TryInitLocal()
    if self._IsInitLocal then
        return
    end
    local key = self:GetDailyQuestLocalKey()
    self._RandomDailyDict = XSaveTool.GetData(key)

    key = self:GetRescueQuestLocalKey()
    self._RandomRescueDict = XSaveTool.GetData(key)

    self._IsInitLocal = true
end

function XAreaWarPersonal:GetLocalIndex(dict, questId, index)
    if dict and dict[questId] then
        return dict[questId]
    end

    if dict == nil then
        dict = {}
    end
    dict[questId] = index

    return index
end

function XAreaWarPersonal:CheckMaxRedPoint()
    local key = XDataCenter.AreaWarManager.GetCookieKey("MaxDispatchCount")
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return data < self:GetSkipNum()
end

function XAreaWarPersonal:MarkMaxRedPoint()
    local key = XDataCenter.AreaWarManager.GetCookieKey("MaxDispatchCount")
    local data = XSaveTool.GetData(key)
    local max = self:GetSkipNum()
    if not data or data ~= max then
        XSaveTool.SaveData(key, max)
    end
end

function XAreaWarPersonal:CheckTodayDailyQuestRedPoint()
    --有未完成的个人任务
    for _, quest in pairs(self._QuestDict) do
        if not quest:IsFinsh() and (quest:IsFight() or quest:IsBeRescued()) then
            return true
        end
    end
    return false
end

function XAreaWarPersonal:CheckTodayRescueQuestRedPoint()
    local count = 0
    for _, quest in pairs(self._QuestDict) do
        if quest:IsFinsh() and quest:IsRescue() then
            count = count + 1
            if count >= self._MaxRescueRewardCount then
                return false
            end
        end
    end
    return true
end

return XAreaWarPersonal