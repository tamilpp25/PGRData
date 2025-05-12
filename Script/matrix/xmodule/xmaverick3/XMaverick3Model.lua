---@class XMaverick3Model : XModel
---@field ActivityData XMaverick3Activity
---@field _ActivityId number
---@field _ChapterStageMap table<number, XTableMaverick3Stage[]>
---@field _InfiniteChapter XTableMaverick3Chapter
---@field _TeachChapter XTableMaverick3Chapter
---@field _RankDatas table
---@field _MyRankData number[] 玩家排名不低于100时使用RankPlayerInfos里的数据，否则使用MyRankPlayer
local XMaverick3Model = XClass(XModel, "XMaverick3Model")

local TableKey = {
    Maverick3Activity = { CacheType = XConfigUtil.CacheType.Normal },
    Maverick3Chapter = { Identifier = "ChapterId", CacheType = XConfigUtil.CacheType.Normal },
    Maverick3Robot = {},
    Maverick3Skill = {},
    Maverick3Stage = { Identifier = "StageId", CacheType = XConfigUtil.CacheType.Normal },
    Maverick3Talent = {},
    Maverick3ClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    Maverick3Story = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XMaverick3Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/Maverick3", TableKey)
end

function XMaverick3Model:ClearPrivate()
    self._ChapterStageMap = nil
    self._InfiniteChapter = nil
    self._TeachChapter = nil
    self._NeedOpenChapterDetailId = nil
end

function XMaverick3Model:ResetAll()
    self._CurSelectChapterId = nil
    self._ActivityId = nil
    self.ActivityData = nil
end

----------public start----------

function XMaverick3Model:IsStageFinish(stageId)
    if not self.ActivityData then
        return false
    end
    local data = self.ActivityData:GetStageData(stageId)
    return data and data.IsPass
end

function XMaverick3Model:IsChapterUnlock(id)
    local chapterCfg = self:GetChapterById(id)
    if XTool.IsNumberValid(chapterCfg.OpenTimeId) then
        if not XFunctionManager.CheckInTimeByTimeId(chapterCfg.OpenTimeId) then
            local startTime = XFunctionManager.GetStartTimeByTimeId(chapterCfg.OpenTimeId)
            return false, XUiHelper.GetText("Maverick3ChapterOpenTime", XUiHelper.GetTime(startTime - XTime.GetServerNowTimestamp()))
        end
    end
    local firstStage = self:GetStagesByChapterId(id)[1]
    if XTool.IsNumberValid(firstStage.PreStageId) then
        if not self:IsStageFinish(firstStage.PreStageId) then
            local preStage = self:GetStageById(firstStage.PreStageId)
            local desc
            if self:GetChapterById(preStage.ChapterId).Difficult == XEnumConst.Maverick3.Difficulty.Normal then
                desc = XUiHelper.GetText("Maverick3PreStageUnlock1", preStage.Name)
            else
                desc = XUiHelper.GetText("Maverick3PreStageUnlock2", preStage.Name)
            end
            return false, desc
        end
    end
    return true, ""
end

function XMaverick3Model:IsStageUnlock(id)
    local preStageId = self:GetStageById(id).PreStageId
    return not XTool.IsNumberValid(preStageId) or self:IsStageFinish(preStageId)
end

function XMaverick3Model:IsStagePlaying(id)
    return self.ActivityData:GetStageSavedData(id) ~= nil
end

function XMaverick3Model:IsTalentUnlock(id)
    local cost = self:GetTalentById(id).NeedItemCount
    if XTool.IsNumberValid(cost) then
        return self.ActivityData:IsTalentUnlock(id)
    end
    -- 免费物品服务端不会记录在UnlockTalent里 默认解锁
    return true
end

function XMaverick3Model:IsStagePlaying(stageId)
    local saved = self.ActivityData:GetStageSavedData(stageId)
    return saved and saved.StageSavePoint > 0
end

function XMaverick3Model:IsShopRed()
    if not XTool.IsNumberValid(self._ActivityId) then
        return false
    end
    -- 每天只显示一次 凌晨5点重置
    local recordTime = XSaveTool.GetData(string.format("Maverick3ShopRedTime_%s", XPlayer.Id)) or 0
    local today = XTime.GetSeverTodayFreshTime()
    if recordTime >= today then
        return false
    end
    -- 活动代币满足购买任意商品
    local shopGoods = XShopManager.GetShopGoodsList(self:GetActivityById(self._ActivityId).ShopId, true)
    if not XTool.IsTableEmpty(shopGoods) then
        for _, good in pairs(shopGoods) do
            -- 售罄
            if good.TotalBuyTimes >= good.BuyTimesLimit then
                goto CONTINUE
            end
            -- 条件
            local conditions = good.ConditionIds
            if not XTool.IsTableEmpty(conditions) then
                for _, condition in pairs(conditions) do
                    if not XConditionManager.CheckCondition(condition) then
                        goto CONTINUE
                    end
                end
            end
            -- 价格
            for _, count in pairs(good.ConsumeList) do
                local itemCount = XDataCenter.ItemManager.GetCount(count.Id)
                if count.Count <= itemCount then
                    return true
                end
            end
            :: CONTINUE ::
        end
    end
    return false
end

function XMaverick3Model:IsDailyRewardCanGain()
    local taskDataList = XDataCenter.TaskManager:GetMaverick3DailyTaskList()
    for _, taskData in pairs(taskDataList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

function XMaverick3Model:IsRankEmpty()
    return XTool.IsTableEmpty(self._RankDatas)
end

--- 已解锁且还没进去过
function XMaverick3Model:IsChapterRed(chapterId)
    return self:IsChapterUnlock(chapterId) and not XSaveTool.GetData(string.format("Maverick3Chapter_%s_%s", chapterId, XPlayer.Id))
end

function XMaverick3Model:IsMainLineNormalRed()
    return self:IsChaptersRed(XEnumConst.Maverick3.ChapterType.MainLine, XEnumConst.Maverick3.Difficulty.Normal)
end

function XMaverick3Model:IsMainLineHardRed()
    return self:IsChaptersRed(XEnumConst.Maverick3.ChapterType.MainLine, XEnumConst.Maverick3.Difficulty.Hard)
end

function XMaverick3Model:IsInfiniteRed()
    return self:IsChaptersRed(XEnumConst.Maverick3.ChapterType.Infinite)
end

function XMaverick3Model:GetFightIndex()
    return XSaveTool.GetData(string.format("Maverick3FightIndex_%s", XPlayer.Id)) or 1
end

function XMaverick3Model:GetShowRobotId()
    return XSaveTool.GetData(string.format("Maverick3ShowRobotId_%s", XPlayer.Id)) or 1
end

---挂饰
function XMaverick3Model:GetSelectOrnamentsId(charIndex)
    return XSaveTool.GetData(string.format("Maverick3OrnamentId_%s_%s", charIndex, XPlayer.Id)) or tonumber(self:GetClientConfig("DefaultOrnamentId"))
end

---必杀
function XMaverick3Model:GetSelectSlayId(charIndex)
    return XSaveTool.GetData(string.format("Maverick3SlayId_%s_%s", charIndex, XPlayer.Id)) or tonumber(self:GetClientConfig("DefaultSlayId"))
end

function XMaverick3Model:GetActivityTimeId()
    if not self:GetActivityId() then
        return false
    end
    return self:GetActivityById(self:GetActivityId()).TimeId
end

function XMaverick3Model:GetActivityId()
    return self._ActivityId
end

function XMaverick3Model:GetInfiniteStageScore(stageId)
    local data = self.ActivityData:GetStageData(stageId)
    return data and data.TotalScore or 0
end

function XMaverick3Model:GetStageStar(stageId)
    local data = self.ActivityData:GetStageData(stageId)
    return data and data.Star or 0
end

function XMaverick3Model:GetClientConfig(key, index)
    local values = self:GetClientConfigs(key)
    return values[index or 1]
end

function XMaverick3Model:GetClientConfigs(key)
    local cfg = self:GetClientConfigById(key)
    return cfg.Values
end

function XMaverick3Model:GetTempFightCharId()
    return self._TempFightCharId
end

function XMaverick3Model:GetRankData(stageId)
    return self._RankDatas[stageId]
end

-- 返回空表示未上榜
function XMaverick3Model:GetMyRankData(stageId)
    if not self._MyRankData[stageId] then
        local data = self:GetRankData(stageId)
        for i, rank in ipairs(data.RankPlayerInfos) do
            if rank.Id == XPlayer.Id then
                self._MyRankData[stageId] = rank
                self._MyRankData[stageId].Rank = i
                break
            end
        end
    end
    return self._MyRankData[stageId]
end

function XMaverick3Model:GetNeedOpenChapterDetailId()
    local id = self._NeedOpenChapterDetailId
    self._NeedOpenChapterDetailId = nil
    return id
end

function XMaverick3Model:GetCurSelectChapterId()
    return self._CurSelectChapterId
end

function XMaverick3Model:GetParam()
    if not self._Param then
        self._Param = {}
    end
    self._Param.IsInit = true
    return self._Param
end

function XMaverick3Model:AddUnlockTalent(id)
    self.ActivityData:AddUnlockTalent(id)
end

function XMaverick3Model:SaveFightIndex(charIndex)
    XSaveTool.SaveData(string.format("Maverick3FightIndex_%s", XPlayer.Id), charIndex)
end

function XMaverick3Model:SaveSelectOrnamentsId(charIndex, id)
    XSaveTool.SaveData(string.format("Maverick3OrnamentId_%s_%s", charIndex, XPlayer.Id), id)
end

function XMaverick3Model:SaveSelectSlayId(charIndex, id)
    XSaveTool.SaveData(string.format("Maverick3SlayId_%s_%s", charIndex, XPlayer.Id), id)
end

function XMaverick3Model:SavetShowRobotId(id)
    XSaveTool.SaveData(string.format("Maverick3ShowRobotId_%s", XPlayer.Id), id)
end

function XMaverick3Model:RecordTempFightCharId(stageId, fightIndex)
    if XTool.IsNumberValid(fightIndex) then
        self._TempFightCharId = fightIndex
    else
        self._TempFightCharId = self.ActivityData:GetStageSavedData(stageId).RobotId
    end
end

function XMaverick3Model:SetRankData(stageId, rankData)
    if not self._RankDatas then
        self._RankDatas = {}
    end
    if not self._MyRankData then
        self._MyRankData = {}
    end
    if rankData.MyRankPlayer and XTool.IsNumberValid(rankData.Rank) then
        self._MyRankData[stageId] = rankData.MyRankPlayer
        self._MyRankData[stageId].Rank = rankData.Rank
    else
        self._MyRankData[stageId] = nil
    end
    self._RankDatas[stageId] = rankData
end

function XMaverick3Model:SetNeedOpenChapterDetailId(stageId)
    self._NeedOpenChapterDetailId = stageId
end

function XMaverick3Model:SetCurSelectChapterId(id)
    self._CurSelectChapterId = id
end

----------public end----------

----------private start----------

function XMaverick3Model:IsChaptersRed(type, difficult)
    local chapters = self:GetChapterConfigs()
    for _, chapter in pairs(chapters) do
        if chapter.Type == type and (not difficult or chapter.Difficult == difficult) then
            if self:IsChapterRed(chapter.ChapterId) then
                return true
            end
        end
    end
    return false
end

----------private end----------

---------service start---------

function XMaverick3Model:NotifyMaverick3Data(maverick3Data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XMaverick3/XEntity/XMaverick3Activity").New()
    end
    self._ActivityId = maverick3Data.ActivityId
    self.ActivityData:SetData(maverick3Data)

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local shopIds = { self:GetActivityById(self._ActivityId).ShopId }
        XShopManager.GetShopInfoList(shopIds, nil, XShopManager.ActivityShopType.Maverick3Shop)
    end
end

function XMaverick3Model:GetSpecialChapter()
    local datas = self:GetChapterConfigs()
    for _, v in pairs(datas) do
        if v.Type == XEnumConst.Maverick3.ChapterType.Infinite then
            self._InfiniteChapter = v
        elseif v.Type == XEnumConst.Maverick3.ChapterType.Teach then
            self._TeachChapter = v
        end
    end
end

---------service end----------

----------config start----------

function XMaverick3Model:GetStagesByChapterId(chapterId)
    if not self._ChapterStageMap then
        self._ChapterStageMap = {}
        local datas = self:GetStageConfigs()
        for _, v in pairs(datas) do
            if not self._ChapterStageMap[v.ChapterId] then
                self._ChapterStageMap[v.ChapterId] = {}
            end
            table.insert(self._ChapterStageMap[v.ChapterId], v)
        end
        for _, tb in pairs(self._ChapterStageMap) do
            table.sort(tb, function(a, b)
                return a.StageId < b.StageId
            end)
        end
    end
    return self._ChapterStageMap[chapterId]
end

function XMaverick3Model:GetInfiniteChapter()
    if not self._InfiniteChapter then
        self:GetSpecialChapter()
    end
    return self._InfiniteChapter
end

function XMaverick3Model:GetTeachChapter()
    if not self._TeachChapter then
        self:GetSpecialChapter()
    end
    return self._TeachChapter
end

---@return XTableMaverick3Activity
function XMaverick3Model:GetActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Activity, id)
end

---@return XTableMaverick3Chapter
function XMaverick3Model:GetChapterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Chapter, id)
end

---@return XTableMaverick3Robot
function XMaverick3Model:GetRobotById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Robot, id)
end

---@return XTableMaverick3Skill
function XMaverick3Model:GetSkillById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Skill, id)
end

---@return XTableMaverick3Stage
function XMaverick3Model:GetStageById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Stage, id)
end

---@return XTableMaverick3Talent
function XMaverick3Model:GetTalentById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Talent, id)
end

---@return XTableMaverick3ClientConfig
function XMaverick3Model:GetClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3ClientConfig, id)
end

---@return XTableMaverick3Story
function XMaverick3Model:GetStoryById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Maverick3Story, id)
end

---@return XTableMaverick3Chapter[]
function XMaverick3Model:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Chapter)
end

---@return XTableMaverick3Robot[]
function XMaverick3Model:GetRobotConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Robot)
end

---@return XTableMaverick3Skill[]
function XMaverick3Model:GetSkillConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Skill)
end

---@return XTableMaverick3Stage[]
function XMaverick3Model:GetStageConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Stage)
end

---@return XTableMaverick3Talent[]
function XMaverick3Model:GetTalentConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Talent)
end

---@return XTableMaverick3Story[]
function XMaverick3Model:GetStoryConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Maverick3Story)
end

----------config end----------


return XMaverick3Model