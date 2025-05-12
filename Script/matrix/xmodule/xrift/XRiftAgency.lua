local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XRiftAgency : XFubenActivityAgency
---@field private _Model XRiftModel
local XRiftAgency = XClass(XFubenActivityAgency, "XRiftAgency")

function XRiftAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.Rift)
end

function XRiftAgency:InitRpc()
    XRpc.NotifyRiftData = handler(self, self.NotifyRiftData)
    XRpc.NotifyRiftNewPlugin = handler(self, self.NotifyRiftNewPlugin)
    XRpc.NotifyRiftDailyReset = handler(self, self.NotifyRiftDailyReset)
    XRpc.NotifyRiftPluginPeakLoadChanged = handler(self, self.NotifyRiftPluginPeakLoadChanged)
    XRpc.NotifyRiftAttrLevelMaxChanged = handler(self, self.NotifyRiftAttrLevelMaxChanged)
    XRpc.NotifyRiftAffixUpdate = handler(self, self.NotifyRiftAffixUpdate)
end

function XRiftAgency:InitEvent()

end

----------public start----------

function XRiftAgency:GetCurrentConfig()
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model:GetActivityById(self._Model.ActivityData.ActivityId)
end

function XRiftAgency:IsInActivity()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.CheckInTimeByTimeId(activity.TimeId)
    end
    return false
end

---关卡是否未解锁
function XRiftAgency:IsLayerLock(layerId)
    if self._Model.ActivityData then
        return layerId > self._Model:GetMaxUnLockFightLayerOrder()
    end
    return false
end

function XRiftAgency:IsLayerPass(layerId)
    return self._Model:CheckLayerFirstPassed(layerId)
end

function XRiftAgency:CheckChapterUnlock(chapterId)
    return self._Model:CheckChapterUnlock(chapterId)
end

function XRiftAgency:GetMaxPassFightLayerId()
    if self._Model.ActivityData then
        return self._Model:GetMaxPassFightLayerOrder()
    end
    return 0
end

function XRiftAgency:IsFuncUnlock(unlockCfgId)
    return self._Model:IsFuncUnlock(unlockCfgId)
end

---@return XBaseRole
function XRiftAgency:GetEntityRoleById(id)
    local roleData = self._Model:GetRoleData(id)
    if roleData then
        return require("XEntity/XRole/XBaseRole").New(roleData)
    end
    return nil
end

---是否显示购买属性红点
function XRiftAgency:IsBuyAttrRed()
    return self._Model:IsBuyAttrRed()
end

function XRiftAgency:IsMemberAddPointRed()
    return self._Model:IsMemberAddPointRed()
end

function XRiftAgency:GetMaxLoad()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetMaxLoad()
end

function XRiftAgency:GetHandbookTakeEffectList()
    return self._Model:GetHandbookTakeEffectList()
end

function XRiftAgency:EnterFight(xTeam)
    self._Model:EnterFight(xTeam)
end

function XRiftAgency:GetAttrTemplate(id)
    return self._Model:GetAttrTemplate(id)
end

---最终显示的战力
function XRiftAgency:GetFinalShowAbility(role)
    return self._Model:GetFinalShowAbility(role)
end

function XRiftAgency:GetCurrentLoad(role)
    return self._Model:GetCurrentLoad(role)
end

function XRiftAgency:GetAttrName(attrId)
    return self._Model:GetTeamAttributeByAttrId(attrId).Name
end

function XRiftAgency:GetTeamAttributeEffect(attrId)
    return self._Model:GetTeamAttributeEffectConfigById(attrId)
end

function XRiftAgency:GetPluginCount(star)
    return self._Model:GetPluginCount(star)
end

function XRiftAgency:CheckSeasonOpen(seasonId)
    XLog.Error("废弃逻辑 4.0版本已无赛季")
    return false
end

function XRiftAgency:GetLuckStageId()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model:GetLuckStageId()
end

function XRiftAgency:CheckIsHasFightLayerRedPoint()
    return self._Model:CheckIsHasFightLayerRedPoint()
end

function XRiftAgency:CheckTaskCanReward()
    if not self._Model.ActivityData then
        return false
    end
    return self._Model:CheckTaskCanReward()
end

---@param stageGroupData RiftStageGroupData
function XRiftAgency:GetStageIdByStageGroup(stageGroupData, index)
    return self._Model:GetStageIdByStageGroup(stageGroupData, index)
end

---@return XTableRiftLayer
function XRiftAgency:GetLayerConfigById(id)
    return self._Model:GetLayerConfigById(id)
end

function XRiftAgency:GetLuckyNodeChapterId()
    return self._Model.ActivityData:GetLuckRiftChapterId()
end

function XRiftAgency:GetLuckyNodeLayerId()
    return self._Model.ActivityData:GetLuckRiftLayerId()
end

---请求保存属性模板
function XRiftAgency:RequestSetAttrSet(attrTemplate, cb)
    local allLevel = attrTemplate:GetAllLevel()
    local attrList = XTool.Clone(attrTemplate.AttrList)
    local isClear = attrTemplate.Id ~= XEnumConst.Rift.DefaultAttrTemplateId and allLevel == 0 -- 默认模板不能设置为nil
    local request = { AttrSet = { Id = attrTemplate.Id, AttrLevels = nil } }
    if not isClear then
        request.AttrSet.AttrLevels = attrList
    end

    XNetwork.Call("RiftSetAttrSetRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateAttrSet(attrTemplate, attrList)

        if cb then
            cb()
        end
    end)
end

--region 副本扩展

function XRiftAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    -- 打开主界面
    self:OpenMain()
end

function XRiftAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XRiftAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XRiftAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Rift
end

function XRiftAgency:ExGetProgressTip()
    return ""
end

function XRiftAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("FangKuaiResetTime", timeStr)
    else
        return XUiHelper.GetText("FangKuaiActivityEnd")
    end
end

---活动是否开启
function XRiftAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Rift, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XRiftAgency:GetActivityTimeId()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model:GetActivityById(self._Model.ActivityData.ActivityId).TimeId
end

---检查是否处于活动的游戏时间
function XRiftAgency:CheckActivityIsInGameTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---获取关卡结束时间
function XRiftAgency:GetActivityGameEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XRiftAgency:OpenFightLoading(stageId)
    XDataCenter.FubenManager.OpenFightLoading(stageId)
end

function XRiftAgency:CloseFightLoading(stageId)
    XDataCenter.FubenManager.CloseFightLoading(stageId)
end

function XRiftAgency:FinishFight(settleData)
    local curStageId = self._Model:GetCurrStageId()
    if not curStageId then
        return
    end
    -- 这条代码开新手指引检测
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    -- 不是大秘境stage 返回
    if curStageId ~= settleData.StageId then
        return
    end

    -- 因为会在战斗结束后重复请求战斗 提前移除
    XLuaUiManager.Remove("UiRiftSettleWin")
    XLuaUiManager.Remove("UiRiftSettleLose")
    XLuaUiManager.Remove("UiSettleLose")

    if settleData.IsWin then
        self:DoShowReward({ SettleData = settleData })
    else
        local isGenericSettle = self._Model:IsLoseGenericSettle()
        if settleData.RiftSettleResult and not isGenericSettle then -- 挑战关和幸运关挑战失败后走通用结算界面
            self:DoShowLose(settleData.RiftSettleResult)
        else
            -- 中途退出
            XLuaUiManager.Open("UiSettleLose", settleData)
        end
    end
end

--endregion

function XRiftAgency:OpenMain()
    XLuaUiManager.Open("UiRiftMain", self._Model:GetMainPanelParem())
end

function XRiftAgency:IsAvgPlayed(storyId)
    local config = self._Model:GetRiftStoryById(storyId)
    if config and XTool.IsNumberValid(config.AvgId) then
        local key = string.format("RiftStory_%s_%s", config.Id, XPlayer.Id)
        if XSaveTool.GetData(key) then
            return true
        end
    end
    return false
end

----------public end----------

----------private start----------

---战斗胜利 & 奖励界面
function XRiftAgency:DoShowReward(winData)
    local isLucky = winData.SettleData.RiftSettleResult.IsLuckyNode
    if isLucky then
        self:DoLuckyShowReward(winData)
        return
    end
    self._Model:UpdateReward(winData)
    -- 解锁插件
    local riftSettleResult = winData.SettleData.RiftSettleResult
    self._Model:UnlockedPluginByDrop(riftSettleResult.PluginDropRecords)
    self._Model:UnlockedPluginByDrop(riftSettleResult.FirstPassPluginDropRecords)
    -- 更新幸运值
    self._Model.ActivityData:UpdateLuckNode(nil, riftSettleResult.LuckyValue)
    -- 打开结算界面
    XLuaUiManager.Open("UiRiftSettleWin", self._Model:GetCurrFightLayerId(), winData.SettleData.RiftSettleResult)
end

---幸运关战斗胜利 & 奖励界面
function XRiftAgency:DoLuckyShowReward(winData)
    self._Model:UpdateLuckyReward(winData)
    -- 解锁插件
    local riftSettleResult = winData.SettleData.RiftSettleResult
    self._Model:UnlockedPluginByDrop(riftSettleResult.PluginDropRecords)
    self._Model:UnlockedPluginByDrop(riftSettleResult.FirstPassPluginDropRecords)
    -- 更新幸运值
    self._Model.ActivityData:UpdateLuckNode(nil, riftSettleResult.LuckyValue)
    -- 打开结算界面
    local layerId = self._Model:GetMaxPassFightLayerOrder()
    XLuaUiManager.Open("UiRiftSettleWin", layerId, winData.SettleData.RiftSettleResult)
end

function XRiftAgency:DoShowLose(loseData)
    self._Model:UpdateLose(loseData)
    XLuaUiManager.Open("UiRiftSettleLose", loseData)
end

function XRiftAgency:NotifyRiftData(data)
    self._Model:NotifyRiftData(data.Data)
end

function XRiftAgency:NotifyRiftNewPlugin(data)
    self._Model:NotifyRiftNewPlugin(data.PluginIds)
end

function XRiftAgency:NotifyRiftPluginPeakLoadChanged(data)
    self._Model:NotifyRiftPluginPeakLoadChanged(data.PluginPeakLoad)
end

function XRiftAgency:NotifyRiftAttrLevelMaxChanged(data)
    self._Model:NotifyRiftAttrLevelMaxChanged(data.AttrLevelMax)
end

function XRiftAgency:NotifyRiftDailyReset(data)
    self._Model:NotifyRiftDailyReset(data.SweepTimes)
end

function XRiftAgency:NotifyRiftAffixUpdate(data)
    self._Model:NotifyRiftAffixUpdate(data)
end

----------private end----------

return XRiftAgency