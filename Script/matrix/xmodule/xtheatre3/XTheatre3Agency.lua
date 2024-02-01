local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")
---@class XTheatre3Agency : XFubenSimulationChallengeAgency
---@field _Model XTheatre3Model
local XTheatre3Agency = XClass(XFubenSimulationChallengeAgency, "XTheatre3Agency")
function XTheatre3Agency:OnInit()
    --初始化一些变量
    XMVCA.XFubenEx:RegisterChapterAgency(self)
    XMVCA.XFuben:RegisterFuben(XEnumConst.FuBen.StageType.Theatre3, ModuleId.XTheatre3)
end

function XTheatre3Agency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyTheatre3ActivityData = handler(self, self.NotifyTheatre3ActivityData)
    XRpc.NotifyTheatre3BattlePassExp = handler(self, self.NotifyTheatre3BattlePassExp)
    XRpc.NotifyTheatre3AddChapter = handler(self, self.NotifyTheatre3AddChapter)
    XRpc.NotifyTheatre3AddStep = handler(self, self.NotifyTheatre3AddStep)
    XRpc.NotifyTheatre3AddItem = handler(self, self.NotifyTheatre3AddItem)
    XRpc.NotifyTheatre3AdventureSettle = handler(self, self.NotifyTheatre3AdventureSettle)
    XRpc.NotifyTheatre3NodeNextStep = handler(self, self.NotifyTheatre3NodeNextStep)
    XRpc.NotifyTheatre3AbnormalExit = handler(self, self.NotifyTheatre3AbnormalExit)
    XRpc.NotifyTheatre3EquipPosCapacityChange = handler(self, self.NotifyTheatre3EquipPosCapcityChange)
    XRpc.NotifyTheatre3MaxEnergyChange = handler(self, self.NotifyTheatre3MaxEnergyChange)
    XRpc.NotifyTheatre3Item = handler(self, self.NotifyTheatre3Item)
    XRpc.NotifyTheatre3EquipDatas = handler(self, self.NotifyTheatre3EquipDatas)
    XRpc.NotifyTheatre3QubitValues = handler(self, self.NotifyTheatre3QubitValues)
    XRpc.NotifyTheatre3DestinyValue = handler(self, self.NotifyTheatre3DestinyValue)
    XRpc.NotifyTheatre3ChapterSwitch = handler(self, self.NotifyTheatre3ChapterSwitch)
end

function XTheatre3Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()

end

----------public start----------
--获取活动时间Id
function XTheatre3Agency:GetActivityTimeId()
    local config = self._Model:GetActivityConfig()
    if not config then
        return 0
    end
    return config.TimeId or 0
end

-- 检查是否播放剧情
function XTheatre3Agency:CheckAutoPlayStory()
    local storyId = self._Model:GetClientConfig("Theatre3FirstEntryStoryId", 1)
    if self:GetEnterAutoPlayStory() or string.IsNilOrEmpty(storyId) then
        XLuaUiManager.Open("UiTheatre3Main")
        return
    end
    XDataCenter.MovieManager.PlayMovie(storyId, function()
        XLuaUiManager.Open("UiTheatre3Main")
    end, nil, nil, false)
    self:SaveEnterAutoPlayStory()
end

function XTheatre3Agency:GetRebootCost(rebootId)
    return self._Model:GetRebootCost(rebootId)
end

function XTheatre3Agency:GetMaxRebootCount(rebootId)
    return self._Model:GetMaxRebootCount(rebootId)
end

-- 检查Bp奖励是否全部领取
function XTheatre3Agency:CheckBattlePassAllReceive()
    if not self._Model.ActivityData then
        return false
    end
    local configs = self._Model:GetBattlePassConfigs()
    for id, _ in pairs(configs) do
        if not self._Model.ActivityData:CheckGetRewardId(id) then
            return false
        end
    end
    return true
end

-- 检查Bp是否有未领取的奖励
function XTheatre3Agency:CheckBattlePassIsHaveReward()
    if not self._Model.ActivityData then
        return false
    end
    local totalExp = self._Model:GetBattlePassTotalExp()
    local curLevel = self._Model:GetBattlePassLevelByExp(totalExp)
    local configs = self._Model:GetBattlePassConfigs()
    for id, _ in pairs(configs) do
        if not self._Model.ActivityData:CheckGetRewardId(id) and id <= curLevel then
            return true
        end
    end
    return false
end

-- 检查Bp是否是最大等级
function XTheatre3Agency:CheckBattlePassMaxLevel()
    if not self._Model.ActivityData then
        return false
    end
    local totalExp = self._Model:GetBattlePassTotalExp()
    local curLevel = self._Model:GetBattlePassLevelByExp(totalExp)
    local maxLevel = self._Model:GetMaxBattlePassLevel()
    return curLevel >= maxLevel
end

-- 检查是否有完成未领取的任务
function XTheatre3Agency:CheckAllTaskAchieved()
    local taskConfigIdList = self._Model:GetTaskConfigIdList()
    for _, id in pairs(taskConfigIdList) do
        local taskIdList = self._Model:GetTaskIdsById(id)
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
    end
    return false
end

--region Condition
function XTheatre3Agency:CheckFirstOpenChapterId(chapterId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckFirstOpenChapterId(chapterId)
    end
    return false
end

function XTheatre3Agency:CheckHasPassEnding(difficultyId, endingId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckHasPassEnding(difficultyId, endingId)
    end
    return false
end

function XTheatre3Agency:CheckEndingIsPass(endingId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckEndingIsPass(endingId)
    end
    return false
end

function XTheatre3Agency:CheckAdventureHasPassEventStep(eventStepId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckAdventureHasPassEventStep(eventStepId)
    end
    return false
end

function XTheatre3Agency:CheckAdventureHasPassChapter(chapterId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckAdventureHasPassChapter(chapterId)
    end
    return false
end

function XTheatre3Agency:CheckAdventureHasPassNode(nodeId)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckAdventureHasPassNode(nodeId)
    end
    return false
end

-- 检查天赋是否解锁
function XTheatre3Agency:CheckStrengthTreeUnlock(id)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckUnlockStrengthTree(id)
    end
    return false
end

function XTheatre3Agency:CheckAdventureQuantumLevel(level)
    if self._Model.ActivityData then
        local quantumAllValue = self._Model.ActivityData:GetQuantumAllValue()
        local curLevel = self._Model:GetQuantumLevelByValue(quantumAllValue)
        return curLevel >= level
    end
    return false
end

function XTheatre3Agency:CheckAdventureUnQuantumEquipCount(how2Compare, count)
    if self._Model.ActivityData then
        local curCount = self._Model.ActivityData:GetSuitUnQuantumCount()
        if how2Compare == 1 then
            return curCount >= count
        else
            return curCount <= count
        end
    end
    return false
end

function XTheatre3Agency:CheckAdventureItemOwn(itemId, idOwn)
    if self._Model.ActivityData then
        local cfg = self._Model:GetItemConfigById(itemId)
        local isHaveLive = cfg and XTool.IsNumberValid(cfg.ExpireTime)
        return self._Model.ActivityData:CheckAdventureItemOwn(itemId, idOwn, isHaveLive)
    end
    return false
end

function XTheatre3Agency:CheckAdventureQuantumValue(quantumType, value)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckQuantumValue(quantumType, value)
    end
    return false
end

function XTheatre3Agency:CheckAdventureQuantumOpenTipCache(state)
    local isOpenTipCache = XSaveTool.GetData(string.format("XTheatre3OpenQuantumIsTip_%s", XPlayer.Id))
    if state == 1 then
        return isOpenTipCache
    else
        return not isOpenTipCache
    end
end

function XTheatre3Agency:CheckTotalAllPassCount(count)
    if self._Model.ActivityData then
        return self._Model.ActivityData:CheckTotalAllPassCount(count)
    end
    return false
end
--endregion

----------public end----------

--region Rpc

function XTheatre3Agency:NotifyTheatre3ActivityData(data)
    self._Model:NotifyTheatre3Activity(data)
end

function XTheatre3Agency:NotifyTheatre3BattlePassExp(data)
    self._Model.ActivityData:UpdateTotalBattlePassExp(data.TotalBattlePassExp)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE)
end

function XTheatre3Agency:NotifyTheatre3AddChapter(data)
    self._Model:NotifyTheatre3AddChapter(data)
end

function XTheatre3Agency:NotifyTheatre3AddStep(data)
    self._Model:NotifyTheatre3AddStep(data)
end

function XTheatre3Agency:NotifyTheatre3AddItem(data)
    self._Model.ActivityData:NotifyTheatre3AddItem(data.InnerItems)
end

function XTheatre3Agency:NotifyTheatre3NodeNextStep(data)
    self._Model.ActivityData:NotifyTheatre3NodeNextStep(data)
end

function XTheatre3Agency:NotifyTheatre3AdventureSettle(data)
    self._Model:NotifyTheatre3AdventureSettle(data)
    self:RemoveBlackView()
end

--发生非正常退出，触发保底保护
function XTheatre3Agency:NotifyTheatre3AbnormalExit(data)
    
end

function XTheatre3Agency:NotifyTheatre3EquipPosCapcityChange(data)
    self._Model.ActivityData:UpdateEquipPosData(data.EquipPos)
end

function XTheatre3Agency:NotifyTheatre3MaxEnergyChange(data)
    self._Model.ActivityData:UpdateMaxEnergy(data.MaxEnergy)
    self._Model:SetAddEnergyLimitRedPoint(true)
end

function XTheatre3Agency:NotifyTheatre3Item(data)
    self._Model.ActivityData:UpdateItemData(data.InnerItems)
end

function XTheatre3Agency:NotifyTheatre3EquipDatas(data)
    self._Model.ActivityData:_UpdateEquipData(data.Equips)
end

function XTheatre3Agency:NotifyTheatre3QubitValues(data)
    local oldValue = self._Model.ActivityData:GetQuantumAllValue()
    local newValue = data.QubitValueA + data.QubitValueB
    local isChangeA = self._Model.ActivityData:UpdateQuantumValue(data.QubitValueA, true)
    local isChangeB = self._Model.ActivityData:UpdateQuantumValue(data.QubitValueB, false)
    local isLevelUp = self._Model:GetQuantumLevelByValue(newValue) > self._Model:GetQuantumLevelByValue(oldValue)
    self:DispatchEvent(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, isChangeA, isChangeB, isLevelUp)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, isChangeA, isChangeB, isLevelUp)
end

function XTheatre3Agency:NotifyTheatre3DestinyValue(data)
    self._Model.ActivityData:UpdateLuckyValue(data.DestinyValue)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_LUCK_VALUE_UPDATE)
end

function XTheatre3Agency:NotifyTheatre3ChapterSwitch(data)
    self._Model.ActivityData:UpdateChapterSwitch(data.ChapterSwitch)
end
--endregion

--region Fight - 副本相关
function XTheatre3Agency:InitStageInfo()
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    -- 关卡池的关卡
    local configs = self._Model:GetFightStageTemplateConfigs()
    local stageInfo = nil
    for _, config in pairs(configs) do
        stageInfo = fubenAgency:GetStageInfo(config.StageId)
        if stageInfo then
            stageInfo.Type = XEnumConst.FuBen.StageType.Theatre3
        else
            XLog.Error("肉鸽3.0找不到配置的关卡id：", config.StageId)
        end
    end
end

---@param stage XTableStage
function XTheatre3Agency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.RobotIds = self._Model.ActivityData:GetTeamRobotIds()
    preFight.CardIds = self._Model.ActivityData:GetTeamsCharIds()
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist
    preFight.ChallengeCount = challengeCount
    preFight.CaptainPos = self._Model.ActivityData:GetCaptainPos()
    preFight.FirstFightPos = self._Model.ActivityData:GetFirstFightPos()
    return preFight
end

function XTheatre3Agency:CallFinishFight()
    local res = XMVCA.XFuben:GetFubenSettleResult()
    -- 手动结束
    if not res then
        XMVCA.XFuben:ResetSettle()
        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
        -- 恢复回系统音声设置 避免战斗里将BGM音量设置为0导致结算后没有声音
        XSoundManager.ResetSystemAudioVolume()
        
        self:FinishFight({})
        return
    end
    XMVCA.XFuben:CallFinishFight()
end

--战斗结束
function XTheatre3Agency:FinishFight(settle)
    if settle.IsWin then
        local fightResult = XMVCA.XFuben:GetCurFightResult()
        self._Model.ActivityData:AddAdventureFightRecord(settle.StageId, fightResult.DamageSourceDic, fightResult.StringToListIntRecord)
        self._Model.ActivityData:GetCurChapterDb():SetFightNodeSlotAddPassStageId(settle.StageId)
        if not self:CheckAndOpenSettle() then
            -- 战斗胜利没结算就进入选奖励
            if self._Model:CheckChapterIsALine(self._Model.ActivityData:GetCurChapterId()) then
                XLuaUiManager.Open("UiTheatre3RewardChoose", false)
            else
                XLuaUiManager.Open("UiTheatre3QuantumRewardChoose", false)
            end
        end
    else
        if not self:CheckAndOpenSettle() then
            -- 打开黑幕因为手动结束战斗在settle前就走到了这里
            -- 如果notify数据还没同步就先开个黑幕
            self:OpenBlackView()
        end
    end
end
--endregion

--region 副本入口扩展

function XTheatre3Agency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre3) then
        return
    end
    if not self._Model.ActivityData or not self:ExCheckInTime()  then
        XUiManager.TipErrorWithKey("CommonActivityNotStart")
        return
    end

    --分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Theatre3) then
        return
    end
    
    self:CheckAutoPlayStory()
end

function XTheatre3Agency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenChallengeBanner
        self.ExConfig = XFubenConfigs.GetChapterBannerByType(self:ExGetChapterType())
    end
    return self.ExConfig
end

function XTheatre3Agency:ExGetChapterType()
    return XDataCenter.FubenManager.ChapterType.Theatre3
end

function XTheatre3Agency:ExGetFunctionNameType()
    return self:ExGetConfig().FunctionId
end

function XTheatre3Agency:ExGetName()
    return self:ExGetConfig().SimpleDesc
end

function XTheatre3Agency:ExGetRewardId()
    return self:ExGetConfig().RewardId
end

function XTheatre3Agency:ExCheckInTime()
    local timeId = self:GetActivityTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        return true
    end
    return false
end

function XTheatre3Agency:ExGetRunningTimeStr()
    return ""
end

function XTheatre3Agency:ExCheckIsShowRedPoint()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Theatre3) then
        return false
    end
    -- 当玩家有尚未领取的BP奖励时
    -- 当玩家BP等级未达到最大且有完成未领取的任务时
    return self:CheckBattlePassIsHaveReward() or (not self:CheckBattlePassMaxLevel() and self:CheckAllTaskAchieved())
end

function XTheatre3Agency:ExGetProgressTip()
    local totalExp = self._Model:GetBattlePassTotalExp()
    local curLevel = self._Model:GetBattlePassLevelByExp(totalExp)
    local maxLevel = self._Model:GetMaxBattlePassLevel()
    curLevel = curLevel > maxLevel and maxLevel or curLevel
    local desc = self._Model:GetClientConfig("Theatre3EntryProgressDesc", 1)
    return string.format(desc, curLevel, maxLevel)
end

function XTheatre3Agency:ExCheckIsFinished(cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre3, nil, true) then
        if cb then
            cb(false)
        end
        return false
    end
    -- 当前BP等级达到满级且已领取所有奖励
    local isGetAllLvReward = self:CheckBattlePassMaxLevel() and self:CheckBattlePassAllReceive()
    if isGetAllLvReward then
        self.IsClear = true
        if cb then
            cb(true)
        end
        return true
    end
    self.IsClear = false
    if cb then
        cb(false)
    end
    return false
end
    
--endregion

--region Settle
function XTheatre3Agency:OpenBlackView()
    XLuaUiManager.Open("UiBiancaTheatreBlack")
end

function XTheatre3Agency:IsBlackViewOpen()
    return XLuaUiManager.IsUiLoad("UiBiancaTheatreBlack")
end

function XTheatre3Agency:RemoveBlackView()
    if self:IsBlackViewOpen() then
        XLuaUiManager.Remove("UiBiancaTheatreBlack")
        self:CheckAndOpenSettle()
    end
end

function XTheatre3Agency:RemoveStepView()
    XLuaUiManager.Remove("UiTheatre3PlayMain")
    XLuaUiManager.Remove("UiTheatre3RewardChoose")
    XLuaUiManager.Remove("UiTheatre3EquipmentChoose")
    XLuaUiManager.Remove("UiTheatre3RoleRoom")
    XLuaUiManager.Remove("UiTheatre3Outpost")
    XLuaUiManager.Remove("UiTheatre3QuantumPlayMain")
    XLuaUiManager.Remove("UiTheatre3QuantumRewardChoose")
    XLuaUiManager.Remove("UiTheatre3QuantumOutpost")
    XLuaUiManager.Remove("UiTheatre3QuantumRoleRoom")
    XLuaUiManager.Remove("UiTheatre3QuantumChoose")
end

function XTheatre3Agency:CheckAndOpenSettle()
    local settle = self._Model.ActivityData:GetSettleData()
    if not settle then
        return false
    end
    local storyId = self._Model:GetEndingById(settle.EndId).StoryId
    if storyId then
        self:OpenBlackView()
        --结局剧情
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            if self:IsBlackViewOpen() then
                XLuaUiManager.Remove("UiBiancaTheatreBlack")
            end
            self:RemoveStepView()
            XLuaUiManager.Open("UiTheatre3EndLoading", settle.EndId)
        end, nil, nil, false)
    else
        self:RemoveStepView()
        XLuaUiManager.Open("UiTheatre3EndLoading", settle.EndId)
    end
    return true
end
--endregion

--region cfg - FightResult
function XTheatre3Agency:GetCfgEquipSuitMagicIdList(suitId)
    local cfg = self._Model:GetEquipDamageSourceCfg(suitId)
    return cfg and cfg.MagicId
end
--endregion

--region 本地数据相关

function XTheatre3Agency:GetEnterAutoPlayStoryKey()
    return string.format("Theatre3EnterAutoPlayStory_%s_%s", XPlayer.Id, self._Model.ActivityData:GetCurActivityId())
end

function XTheatre3Agency:GetEnterAutoPlayStory()
    local key = self:GetEnterAutoPlayStoryKey()
    return XSaveTool.GetData(key) or false
end

function XTheatre3Agency:SaveEnterAutoPlayStory()
    local key = self:GetEnterAutoPlayStoryKey()
    local data = XSaveTool.GetData(key) or false
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

--endregion

return XTheatre3Agency