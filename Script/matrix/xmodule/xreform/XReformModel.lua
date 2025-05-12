local XReformConfigModel = require("XModule/XReform/XReformConfigModel")
local XReform2ndMob = require("XEntity/XReform2/XReform2ndMob")
local XReform2ndAffix = require("XEntity/XReform2/XReform2ndAffix")

---@class XReformModel : XReformConfigModel
local XReformModel = XClass(XReformConfigModel, "XReformModel")

function XReformModel:OnInit()
    self.Super.OnInit(self)

    -- 开始
    self._IsPlaying = false

    -- 活动Id
    self._ActivityId = 0--self:GetActivityDefaultId()

    ---@type XReform2ndStage[]
    self._Stage = {}

    self._ChapterLength = 1

    self._ChapterList = {}

    ---@type XViewModelReform2nd
    self._ViewModel = nil

    ---@type XViewModelReform2ndList
    self._ViewModelList = nil

    ---@type XReform2ndMobGroup[][]
    self._MobGroupList = {}

    self._ServerData = false

    self._IsSuperior = false

    self._AffixCanSelect = {}

    self._IsSelectHardMode = false
end

function XReformModel:ClearPrivate()
    self._ViewModel = nil
    self._ViewModelList = nil

    self._AffixCanSelect = {}
end

function XReformModel:ResetAll()
    --这里执行重登数据清理
    self._IsPlaying = false
    self._ActivityId = 0
    self._Stage = {}
    self._ChapterLength = 1
    self._ChapterList = {}
    self._ViewModel = nil
    self._ViewModelList = nil
    self._MobGroupList = {}
    self._ServerData = false
    self._IsSuperior = false
    self._IsSelectHardMode = false
end

function XReformModel:GetViewModel()
    if not self._ViewModel then
        local XViewModelReform2nd = require("XEntity/XReform2/ViewModel/XViewModelReform2nd")
        self._ViewModel = XViewModelReform2nd.New(self)
    end
    return self._ViewModel
end

function XReformModel:GetViewModelList()
    if not self._ViewModelList then
        local XViewModelReform2ndList = require("XEntity/XReform2/ViewModel/XViewModelReform2ndList")
        self._ViewModelList = XViewModelReform2ndList.New(self)
    end
    return self._ViewModelList
end

function XReformModel:IsOnUiStage(stageId)
    local view = self._ViewModelList
    if view then
        return view:IsOnStage(stageId)
    end
    return false
end

function XReformModel:SetServerData(serverData)
    self._ServerData = serverData
    if serverData then
        self._ActivityId = serverData.ReformFubenDb.ActivityId
    end
end

function XReformModel:InitWithServerData()
    local serverData = self._ServerData
    if serverData then
        self:SetData(serverData.ReformFubenDb)
        self._ServerData = false
    end
end

function XReformModel:GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetCurrentActivityOpenTimeId())
end

function XReformModel:GetHelpKey()
    return self:GetHelpKey1(), self:GetHelpKey2()
end

function XReformModel:GetAvailableChapters()
    local result = {}
    if not self:GetIsOpen() then
        return result
    end
    table.insert(result, {
        Id = self._ActivityId,
        Type = XDataCenter.FubenManager.ChapterType.Reform,
        Name = self:GetActivityName(self._ActivityId),
        Icon = self:GetActivityBannerIcon(self._ActivityId),
    })
    return result
end

function XReformModel:GetCurrentChapterNumber()
    return self._ChapterLength
end

---@return XReform2ndChapter
function XReformModel:GetChapter(chapterId)
    local chapter = self._ChapterList[chapterId]

    if not chapter then
        local XReform2ndChapter = require("XEntity/XReform2/XReform2ndChapter")
        chapter = XReform2ndChapter.New(chapterId)
        self._ChapterList[chapterId] = chapter
        self._ChapterLength = self._ChapterLength + 1
    end

    return chapter
end

function XReformModel:GetChapterNumber()
    return #self:GetChapterConfig()
end

---@return XReform2ndChapter
function XReformModel:GetChapterByIndex(index)
    local configs = self:GetChapterConfig()
    local i = 1

    for id, _ in pairs(configs) do
        if i == index then
            return self:GetChapter(id)
        end
        i = i + 1
    end

    return nil
end

---@return XReform2ndStage[]
function XReformModel:GetStageDic()
    return self._Stage
end

function XReformModel:GetActivityId()
    return self._ActivityId
end

function XReformModel:GetIsOpen()
    if not self._ActivityId or self._ActivityId == 0 then
        return false
    end
    local openTimeId = self:GetCurrentActivityOpenTimeId()
    return XFunctionManager.CheckInTimeByTimeId(openTimeId)
end

function XReformModel:GetActivityTime()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self:GetCurrentActivityOpenTimeId())
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime < 0 then
        leftTime = 0
    end
    return XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XReformModel:GetStageSelectKey()
    return XDataCenter.Reform2ndManager.GetStageSelectKey()
end

function XReformModel:SetStageEnvironment(stageId, environmentId)
    local stage = self:GetStage(stageId)
    stage:SetSelectedEnvironmentById(environmentId)
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT)
end

function XReformModel:GetToggleFullDescKey()
    return "Reform2_Toggle_Full_Desc_" .. XPlayer.Id
end

---@param mob XReform2ndMob
function XReformModel:GetMobPressureByMob(mob)
    if not mob then
        return 0
    end
    local pressure = self:GetMobPressure(mob:GetId())
    --local affixList = mob:GetAffixList()
    --for i = 1, #affixList do
    --    local affix = affixList[i]
    --    pressure = pressure + self:GetAffixPressure(affix:GetId())
    --end
    return pressure
end

---@param mob XReform2ndMob
function XReformModel:GetMobAffixPressure(mob)
    if not mob then
        return 0
    end
    local pressure = 0
    local affixList = mob:GetAffixList()
    for i = 1, #affixList do
        local affix = affixList[i]
        pressure = pressure + self:GetAffixPressure(affix:GetId())
    end
    return pressure
end

---@param stage XReform2ndStage
function XReformModel:GetStagePressureByStage(stage)
    local pressure = 0
    local list = self:GetMobGroupByStage(stage)
    for i = 1, #list do
        local group = list[i]
        pressure = pressure + self:GetMobGroupPressureByMobGroup(group)
    end
    return pressure
end

---@param mobGroup XReform2ndMobGroup
function XReformModel:GetMobGroupPressureByMobGroup(mobGroup)
    local pressure = 0
    local mobList = mobGroup:GetMobList()
    for i = 1, #mobList do
        local mob = mobList[i]
        pressure = pressure + self:GetMobPressureByMob(mob)
    end
    -- v3.5 词缀和怪物的压力解绑
    local mobCanSelect = mobGroup:GetMobCanSelect()
    local mob = mobCanSelect[1]
    pressure = pressure + self:GetMobAffixPressure(mob)

    return pressure
end

---@param chapter XReform2ndChapter
function XReformModel:GetChapterStarNumber(chapter, distinguishingDifficulty, hardMode)
    if hardMode == nil then
        hardMode = hardMode or self._IsSelectHardMode
    end
    local stageIds = self:GetChapterStageIdById(chapter:GetId())
    local starNumber = 0
    for i = 1, #stageIds do
        local stage = self:GetStage(stageIds[i])
        local isValid = true
        -- 根据难度区分
        if distinguishingDifficulty then
            isValid = hardMode == stage:IsHardStage(self)
        end
        if isValid then
            local starHistory = stage:GetStarHistory()
            if starHistory > starNumber then
                starNumber = starHistory
            end
        end
    end
    return starNumber
end

---@param chapter XReform2ndChapter
function XReformModel:GetChapterFullStar(chapter)
    --local stageIds = self:GetChapterStageIdById(chapter:GetId())
    --local fullStar = 0
    --for i = 1, #stageIds do
    --    local stage = self:GetStage(stageIds[i])
    --    fullStar = fullStar + self:GetStageFullPointById(stage:GetId())
    --end
    --return fullStar
    --return self:GetStarMax(chapter:IsShowToggleHard(self))
    return self:GetStarMax(self._IsSelectHardMode)
end

---@param chapter XReform2ndChapter
function XReformModel:GetChapterStarDesc(chapter)
    local starNumber = self:GetChapterStarNumber(chapter, true)
    local fullNumber = self:GetChapterFullStar(chapter)
    if starNumber > fullNumber then
        starNumber = fullNumber
    end
    return string.format("%s/%s", starNumber, fullNumber)
end

---@param chapter XReform2ndChapter
function XReformModel:IsChapterFinished(chapter)
    local starNumber = self:GetChapterStarNumber(chapter)
    local fullNumber = self:GetChapterFullStar(chapter)
    return starNumber >= fullNumber
end

---@param chapter XReform2ndChapter
function XReformModel:IsChapterPassed(chapter)
    ---@type XReform2ndStage
    local stageIds = self:GetChapterStageIdById(chapter:GetId())
    local stageHard = chapter:GetStageByDifficulty(self, true)
    if stageHard then
        if stageHard:GetIsPassed() then
            return true
        end
    end
    --for i = 1, #stageIds do
    --for i = 1, 1 do
    local stage = self:GetStage(stageIds[1])
    if not stage:GetIsPassed() then
        return false
    end
    --end
    return true
end

---@param chapter XReform2ndChapter
function XReformModel:GetChapterName(chapter)
    return self:GetChapterDescById(chapter:GetId())
end

---@param chapter XReform2ndChapter
function XReformModel:GetChapterOpenTimeByChapter(chapter, isSelectHardMode)
    local stage = chapter:GetStageByDifficulty(self, isSelectHardMode)
    if not stage then
        stage = chapter:GetStageByDifficulty(self, false)
    end
    return self:GetStageOpenTimeById(stage:GetId())
end

-- 在5.0中，删除chapter概念，为了不改变原结构，取第一个stage
---@param chapter XReform2ndChapter
function XReformModel:GetChapterFirstStage(chapter)
    local stageIdList = self:GetChapterStageIdById(chapter:GetId())
    local firstStageId = stageIdList[1]
    return self:GetStage(firstStageId)
end

---@return XReform2ndStage
function XReformModel:GetStage(stageId)
    if not self:IsStageValid(stageId) then
        XLog.Error("[XReform2ndData] stageId invalid", stageId)
        return
    end
    local stage = self._Stage[stageId]
    if not stage then
        local XReform2ndStage = require("XEntity/XReform2/XReform2ndStage")
        stage = XReform2ndStage.New(stageId)
        self._Stage[stageId] = stage
    end
    return stage
end

function XReformModel:InitServerDataStagePassed()
    local data = self._ServerData
    if data and data.ReformFubenDb then
        local stages = data.ReformFubenDb.StageDbs

        if stages then
            -- stage
            for i = 1, #stages do
                local stageData = stages[i]
                local stageId = stageData.Id
                if self:IsStageValid(stageId) then
                    local stage = self:GetStage(stageId)
                    if stage then
                        local pass = stageData.Pass
                        stage:SetIsPassed(pass)
                    end
                end
            end
        end
    end
end

-- 这个结构有点复杂
function XReformModel:SetData(data)
    local stages = data.StageDbs

    -- stage
    for i = 1, #stages do
        local stageData = stages[i]
        local stageId = stageData.Id
        if self:IsStageValid(stageId) then
            local stage = self:GetStage(stageId)
            local pass = stageData.Pass
            stage:SetIsPassed(pass)

            local envId = stageData.EnvId
            if envId then
                stage:SetSelectedEnvironmentById(envId)
            end

            -- abandon: 每个stage有难度，现在默认为1
            local difficulty = stageData.CurDiffIndex + 1
            local detailData = stageData.DifficultyDbs[difficulty]
            if detailData then
                stage:SetStarHistory(self:GetStarByPressure(detailData.Score, stageId))
                stage:SetExtraStar(detailData.ExtraStar > 0)

                -- 每个难度有n组mobGroup
                local enemyList = detailData.EnemyReplaceIds
                for j = 1, #enemyList do
                    local enemy = enemyList[j]
                    local groupId = enemy.EnemyGroupId
                    local mobGroup = self:GetMonsterGroupByGroupId(stage, groupId)

                    -- 每个mobGroup有一组mob
                    if mobGroup then
                        local sourceId = enemy.SourceId
                        local index = mobGroup:GetIndexBySourceId(sourceId)
                        if index then
                            local mobId = enemy.TargetId
                            ---@type XReform2ndMob
                            local mob = XReform2ndMob.New(mobId)
                            mobGroup:SetMob(index, mob)

                            -- v3.5 从这期开始, 词缀效果只挂在第一个boss身上, 实际等于跟随boss, 改为了跟随stage
                            local mobCanSelect = mobGroup:GetMobCanSelect()
                            local firstMob = mobCanSelect[1]

                            -- 每个mob有一组affix
                            local affixList = enemy.AffixSourceId
                            for k = 1, #affixList do
                                local affixId = affixList[k]
                                if self:IsAffixValid(affixId) then
                                    local affix = XReform2ndAffix.New(affixId)
                                    mob:SetAffixSelected(affix)
                                    firstMob:SetAffixSelected(affix)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    self._IsSuperior = data.IsSuperior

    self._IsPlaying = data.IsPlaying
    local activityId = data.ActivityId
    if not self:IsActivityExist(activityId) then
        activityId = self:GetActivityDefaultId()
    end
end

function XReformModel:GetHelpKey1()
    return self:GetActivityHelpKey1(self._ActivityId)
end

function XReformModel:GetHelpKey2()
    return self:GetActivityHelpKey2(self._ActivityId)
end

function XReformModel:GetCurrentActivityOpenTimeId()
    return self:GetActivityOpenTimeId(self._ActivityId)
end

---@param stage XReform2ndStage
function XReformModel:GetStageStar(stage, pressure)
    pressure = pressure or self:GetStagePressureByStage(stage)
    return self:GetStarByPressure(pressure, stage:GetId())
end

---@param stage XReform2ndStage
function XReformModel:IsOverPressure(stage, pressure)
    pressure = pressure or 0
    return self:GetStagePressureByStage(stage) + pressure > self:GetStagePressureMax(stage)
end

---@param stage XReform2ndStage
function XReformModel:GetStagePressureMax(stage)
    --if self:GetIsUnlockedDifficulty() then
    --    return XReform2ndConfigs.GetStagePressureHard(self._Id)
    --end
    --return XReform2ndConfigs.GetStagePressureEasy(self._Id)
    return math.huge
end

---@param stage XReform2ndStage
function XReformModel:IsStageFullPressure(stage)
    return self:GetStagePressureByStage(stage) >= self:GetStagePressureMax(stage)
end

---@param mob XReform2ndMob
function XReformModel:GetMobAffixMaxCountByMob(mob)
    return self:GetMobAffixMaxCount(mob:GetId())
end

---@param stage XReform2ndStage
function XReformModel:GetStageStarMax(stage, isHardMode)
    if isHardMode == nil then
        --isHardMode = self:GetStageIsUnlockedDifficulty(stage)
        isHardMode = stage:IsHardStage(self)
    end
    return self:GetStarMax(isHardMode)
end

---@param stage XReform2ndStage
function XReformModel:GetStageIsUnlockedDifficulty(stage)
    if stage:GetStarHistory(false) >= self:GetStarHardMode() then
        return true
    end
    return false
end

---@param stage XReform2ndStage
---@return XReform2ndMob[]
function XReformModel:GetMobCanSelectByStage(stage)
    local mobGroups = self:GetMobGroupByStage(stage)
    if mobGroups[1] then
        return mobGroups[1]:GetMobCanSelect()
    end
end

---@param stage XReform2ndStage
---@return XReform2ndMobGroup[]
function XReformModel:GetMobGroupByStage(stage)
    local stageId = stage:GetId()
    if not self._MobGroupList[stageId] then
        local t = {}
        self._MobGroupList[stageId] = t
        local groupList = self:GetStageMobGroup(stageId)
        for i = 1, #groupList do
            local data = groupList[i]
            local group = data.MobArray
            local XReform2ndMobGroup = require("XEntity/XReform2/XReform2ndMobGroup")
            ---@type XReform2ndMobGroup
            local mobGroup = XReform2ndMobGroup.New(stage, group, i, data.MobAmount)
            local mobGroupId = data.MobGroupId
            mobGroup:SetGroupId(mobGroupId)
            local mobSourceId = data.MobSourceId
            mobGroup:SetSourceId(mobSourceId)
            t[#t + 1] = mobGroup
        end
    end
    return self._MobGroupList[stageId]
end

---@param stage XReform2ndStage
---@return XReform2ndMobGroup
function XReformModel:GetMonsterGroupByIndex(stage, index)
    index = index or 1
    local group = self:GetMobGroupByStage(stage)[index]
    return group
end

---@return XReform2ndMobGroup
function XReformModel:GetMonsterGroupByGroupId(stage, groupId)
    local groupList = self:GetMobGroupByStage(stage)
    for i = 1, #groupList do
        local group = groupList[i]
        if group:GetGroupId() == groupId then
            return group
        end
    end
    return false
end

---@param stage XReform2ndStage
function XReformModel:GetSubStage(stage)
    local rootStageId = stage:GetId()
    local mobGroup = self:GetMonsterGroupByIndex(stage)
    local configs = self:GetConfigSubStage()
    local mob = mobGroup:GetMob(1)
    if not mob then
        return false
    end
    for stageId, config in pairs(configs) do
        if config.RootStage == rootStageId then
            local affixId = config.Affix
            local affixList = mob:GetAffixList()
            for i = 1, #affixList do
                local affix = affixList[i]
                if affix:GetId() == affixId then
                    return stageId
                end
            end
        end
    end
    return false
end

function XReformModel:IsChapterUnlocked(chapter, isSelectHardMode)
    if isSelectHardMode then
        if not self:IsUnlockStageHard() then
            return false
        end
    end
    
    local timeId = self:GetChapterOpenTimeByChapter(chapter, isSelectHardMode)
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    local preIsPassed = false
    local preChapterOrder = self:GetChapterOrderById(chapter:GetId())

    if preChapterOrder == 0 then
        preIsPassed = true
    else
        local preChapter = self:GetChapter(preChapterOrder)
        preIsPassed = self:IsChapterPassed(preChapter)
    end

    return isTimeOpen and preIsPassed
end

function XReformModel:IsSuperior()
    return self._IsSuperior
end

function XReformModel:IsUnlockStageHard()
    if self:IsSuperior() then
        return true
    end

    if self:IsUnlockAllStageHard() then
        return true
    end
    return false
end

function XReformModel:IsUnlockAllStageHard()
    --if self:IsSuperior() then
    --    if self:IsChapterUnlocked(self) then
    --        return true
    --    end
    --end

    local passedAmountNormalStage = 0
    local chapterAmount = self:GetChapterNumber()
    for i = 1, chapterAmount do
        local chapter = self:GetChapterByIndex(i)
        ---@type XReform2ndStage
        local normalStage = chapter:GetStageByDifficulty(self, false)
        if normalStage:GetIsPassed() then
            passedAmountNormalStage = passedAmountNormalStage + 1
        end
    end
    if passedAmountNormalStage == chapterAmount then
        return true
    end

    return false
end

---@param mob XReform2ndMob
function XReformModel:GetAffixCanSelectByMob(mob)
    if not self._AffixCanSelect[mob:GetId()] then
        self._AffixCanSelect[mob:GetId()] = {}
        local groupId = self:GetMobAffixGroupId(mob:GetId())
        local affixIdList = self:GetAffixGroupByGroupId(groupId)
        for i = 1, #affixIdList do
            local id = affixIdList[i]
            local affix = XReform2ndAffix.New(id)
            self._AffixCanSelect[mob:GetId()][i] = affix
        end
    end
    return self._AffixCanSelect[mob:GetId()]
end

---@param mobList XReform2ndMob[]
function XReformModel:CheckMobListAffixMutex(mobList, forceChange)
    for i = 1, #mobList do
        local mob = mobList[i]
        local isContainMutex = false
        ---@type XReform2ndAffix[]
        local affixListCanSelect = self:GetAffixCanSelectByMob(mob)
        for i = 1, #affixListCanSelect do
            local affix = affixListCanSelect[i]
            if self:IsMutexAffix(affix:GetId()) then
                isContainMutex = true
                break
            end
        end
        if not isContainMutex then
            return false
        end

        isContainMutex = false
        local isMoreMutex = false
        local affixList = mob:GetAffixList()
        for i = #affixList, 1, -1 do
            local affix = affixList[i]
            if self:IsMutexAffix(affix:GetId()) then
                if isContainMutex then
                    if forceChange then
                        -- 选多了互斥词缀, 强制取消
                        mob:SetAffixUnselected(affix)
                        isMoreMutex = true
                    else
                        XUiManager.TipText("ReformAffixMutex2")
                        return true
                    end
                end
                if forceChange and isMoreMutex then
                    --XUiManager.TipText("ReformAffixMutex2")
                    return true
                end
                isContainMutex = true
            end
        end
        if not isContainMutex then
            -- 没有选互斥词缀, 强制选中
            if forceChange then
                for i = 1, #affixListCanSelect do
                    local affix = affixListCanSelect[i]
                    if self:IsMutexAffix(affix:GetId()) then
                        mob:SetAffixSelected(affix)
                        break
                    end
                end
            else
                XUiManager.TipText("ReformAffixMutex1")
            end
            return true
        end
    end
    return false
end

function XReformModel:SetIsSelectHardMode(value)
    self._IsSelectHardMode = value
end

function XReformModel:GetIsSelectHardMode()
    return self._IsSelectHardMode
end

function XReformModel:GetReformAutoEnvironmentKey(stageId)
    local key = "ReformEnvironment" .. XPlayer.Id .. stageId
    return key
end

function XReformModel:CheckUiEnvironmentAutoIsOpened(stageId)
    local key = self:GetReformAutoEnvironmentKey(stageId)
    local value = XSaveTool.GetData(key)
    if value == nil then
        return false
    end
    return true
end

function XReformModel:GetUiCurrentStageId()
    local view = self._ViewModelList
    if view then
        return view:GetCurrentStageId()
    end
end

return XReformModel
