---@class XMechanismActivityControl : XControl
---@field private _Model XMechanismActivityModel
local XMechanismActivityControl = XClass(XControl, "XMechanismActivityControl")
function XMechanismActivityControl:OnInit()
    self:StartTimeUpdater()
end

function XMechanismActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMechanismActivityControl:RemoveAgencyEvent()

end

function XMechanismActivityControl:OnRelease()
    self:StopTimeUpdater()
end


--region --------------------到点踢出判断-------------------------
function XMechanismActivityControl:StartTimeUpdater()
    self:StopTimeUpdater()
    self:OnTimeUpdate()
    self._TimerUpdaterId = XScheduleManager.ScheduleForever(handler(self, self.OnTimeUpdate), XScheduleManager.SECOND)
end

function XMechanismActivityControl:OnTimeUpdate()
    local leftTime = XMVCA.XMechanismActivity:GetLeftTime()
    --到点踢出
    if leftTime <= 0 then
        XLuaUiManager.RunMain()
        XUiManager.TipText('ActivityMainLineEnd')
    end
end

function XMechanismActivityControl:StopTimeUpdater()
    if self._TimerUpdaterId then
        XScheduleManager.UnSchedule(self._TimerUpdaterId)
        self._TimerUpdaterId = nil
    end
end
--endregion

--region -------------------------配置表读取---------------------------
------------ Activity
function XMechanismActivityControl:GetChapterIdsByActivityId(activityId)
    return self._Model:GetMechanismActivityChapterIdsById(activityId)
end

function XMechanismActivityControl:GetCoinItemByActivityId(activityId)
    local cfg = self._Model:GetMechanismActivityCfgById(activityId)
    if cfg then
        return cfg.CoinItem
    end
    return 0
end

function XMechanismActivityControl:GetShowRewardIdsByActivityId(activityId)
    local cfg = self._Model:GetMechanismActivityCfgById(activityId)
    if cfg then
        return cfg.ShowRewardId
    end
end

------------ Chapter
function XMechanismActivityControl:GetChapterNameById(chapterId)
    local cfg = self._Model:GetMechanismChapterCfgById(chapterId)
    if cfg then
        return cfg.Name
    end
    return ''
end

function XMechanismActivityControl:GetChapterIconById(chapterId)
    local cfg = self._Model:GetMechanismChapterCfgById(chapterId)
    if cfg then
        return cfg.Icon
    end
    return ''
end

function XMechanismActivityControl:GetChapterTeamNameById(chapterId)
    local cfg = self._Model:GetMechanismChapterCfgById(chapterId)
    if cfg then
        return cfg.TeamName
    end
    return ''
end

---@return number @该章节总星数
function XMechanismActivityControl:GetStarLimitByChapterId(chapterId)
    local stageIds = self._Model:GetMechanismChapterStageIdsById(chapterId)
    local curCount = 0

    if not XTool.IsTableEmpty(stageIds) then
        for i, stageId in pairs(stageIds) do
            local starLimit = self._Model:GetMechanismStageStarLimitById(stageId)
            curCount = curCount + starLimit
        end
    end

    return curCount
end

---------- stage
function XMechanismActivityControl:GetStageNameById(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.Name
        end
    end
    return ''
end

function XMechanismActivityControl:GetStarLimitByStageId(stageId)
    if XTool.IsNumberValid(stageId) then
        local starLimit = self._Model:GetMechanismStageStarLimitById(stageId)
        return starLimit
    end
    return 0
end

function XMechanismActivityControl:GetStageTypeByStageId(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.Type
        end
    end
    return 0
end

function XMechanismActivityControl:GetStageStarRewardIds(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.StarRewards
        end
    end
    return ''
end

function XMechanismActivityControl:GetStageStarDescList(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.StarDesc
        end
    end
    return ''
end

function XMechanismActivityControl:GetStageAffixIcons(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.AffixIcons
        end
    end
    return ''
end

function XMechanismActivityControl:GetStageAffixDesc(stageId)
    if XTool.IsNumberValid(stageId) then
        local cfg = self._Model:GetMechanismStageCfgById(stageId)
        if cfg then
            return cfg.AffixDesc
        end
    end
    return ''
end

---------- Character
function XMechanismActivityControl:GetBuffIconsByCharacterIndex(index)
    if XTool.IsNumberValid(index) then
        local cfg = self._Model:GetMechanismCharacterCfgById(index)
        if cfg then
            return cfg.BuffIcons
        end
    end
end

function XMechanismActivityControl:GetBuffConditionsByCharacterIndex(index)
    if XTool.IsNumberValid(index) then
        local cfg = self._Model:GetMechanismCharacterCfgById(index)
        if cfg then
            return cfg.BuffConditions
        end
    end
end

function XMechanismActivityControl:GetMechanismCharacterIndexByEntityId(entityId)
    return self._Model:GetMechanismCharacterIndexByEntityId(entityId)
end

function XMechanismActivityControl:GetMechanismCharacterCfgByIndex(index)
    if XTool.IsNumberValid(index) then
        local cfg = self._Model:GetMechanismCharacterCfgById(index)
        if cfg then
            return cfg
        end
    end
end

---------- ClientConfig
---@return table @数值数组
function XMechanismActivityControl:GetMechanismClientConfigNumArray(key)
    return self._Model:GetMechanismClientConfigNumArray(key)
end

function XMechanismActivityControl:GetMechanismClientConfigNum(key)
    return self._Model:GetMechanismClientConfigNumber(key)
end

function XMechanismActivityControl:GetMechanismClientConfigStr(key)
    return self._Model:GetMechanismClientConfigString(key)
end

function XMechanismActivityControl:GetMechanismClientConfigStrArray(key)
    return self._Model:GetMechanismClientConfigStringArray(key)
end
--endregion

--region -------------------------------活动数据读取------------------------------
function XMechanismActivityControl:GetCurActivityId()
    return self._Model:GetActivityIdFromCurData()
end

function XMechanismActivityControl:GetSumStarOfStagesById(chapterId)
    local stageIds = self._Model:GetMechanismChapterStageIdsById(chapterId)

    if not XTool.IsTableEmpty(stageIds) then
        return self._Model:GetSumStarOfStages(stageIds)
    end
    return 0
end

function XMechanismActivityControl:GetStarOfStageById(stageId)
    if XTool.IsNumberValid(stageId) then
        return self._Model:GetStarOfStage(stageId)
    end
end

function XMechanismActivityControl:CheckHasGetStarRewardById(stageId, index)
    if XTool.IsNumberValid(stageId) then
        return self._Model:CheckHasGetStarRewardById(stageId, index)
    end
end

function XMechanismActivityControl:CheckGoodsIsBuyAll(templateIds, cb)
    local shopId = XMVCA.XMechanismActivity:GetCurShopId()
    local shopInfo = XShopManager.GetShopGoodsList(shopId, true, true)
    
    local result = {}
    
    local checkFunc = function()
        if not XTool.IsTableEmpty(shopInfo) then
            for i, Id in ipairs(templateIds) do
                for _, goods in pairs(shopInfo) do
                    if goods and goods.RewardGoods and goods.RewardGoods.TemplateId == Id.TemplateId then
                        if goods.TotalBuyTimes >= goods.BuyTimesLimit then
                            -- 只有这个道具的结果未出时，才能判定为true，否则（如已为false：存在商品没购买完）不能设置
                            if result[i] == nil then
                                result[i] = true
                            end
                        else
                            result[i] = false
                        end
                    end
                end
            end
        end

        if cb then
            cb(result)
        end
    end
    
    -- 第一次读取空的，可能是没有服务端数据，请求一次
    if XTool.IsTableEmpty(shopInfo) then
        XShopManager.GetShopInfo(shopId, function()
            checkFunc()
        end, true)
    else
        checkFunc()    
    end

    
end

--endregion

--region -------------------------------活动数据读取------------------------------
function XMechanismActivityControl:CheckBuffIsOld(characterIndex, buffIndex)
    return self._Model:CheckBuffIsOld(characterIndex, buffIndex)
end

function XMechanismActivityControl:CheckCharacterHasNewBuff(characterIndex)
    ---@type XTableMechanismCharacter
    local characterCfg = self:GetMechanismCharacterCfgByIndex(characterIndex)
    -- 以图标数量为参考，没有配图标的话对玩家而言就是不存在
    for i, v in ipairs(characterCfg.BuffIcons) do
        -- buff解锁且不为旧
        if XConditionManager.CheckCondition(characterCfg.BuffConditions[i]) and not self:CheckBuffIsOld(characterIndex, i) then
            return true
        end
    end
    return false
end

function XMechanismActivityControl:SetBuffToOld(characterIndex, buffIndex)
    self._Model:SetBuffToOld(characterIndex, buffIndex)
end

function XMechanismActivityControl:SetCharacterBuffsToOld(characterIndex)
    ---@type XTableMechanismCharacter
    local characterCfg = self:GetMechanismCharacterCfgByIndex(characterIndex)
    -- 以图标数量为参考，没有配图标的话对玩家而言就是不存在
    for i, v in ipairs(characterCfg.BuffIcons) do
        -- 只有解锁了才要设置成旧的(没有解锁条件或满足解锁条件）
        if not XTool.IsNumberValid(characterCfg.BuffConditions[i]) or XConditionManager.CheckCondition(characterCfg.BuffConditions[i]) then
            self:SetBuffToOld(characterIndex, i)
        end
    end
end

function XMechanismActivityControl:SetChapterCharactersBuffsToOld()
    local characterCfgs = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(self:GetMechanismCurChapterId())

    if characterCfgs then
        ---@param characterCfg XTableMechanismCharacter
        for i, characterCfg in ipairs(characterCfgs) do
            -- 以图标数量为参考，没有配图标的话对玩家而言就是不存在
            for i, v in ipairs(characterCfg.BuffIcons) do
                -- 只有解锁了才要设置成旧的(没有解锁条件或满足解锁条件）
                if not XTool.IsNumberValid(characterCfg.BuffConditions[i]) or XConditionManager.CheckCondition(characterCfg.BuffConditions[i]) then
                    self:SetBuffToOld(characterCfg.Id, i)
                end
            end
        end
    end
end

function XMechanismActivityControl:CheckChapterIsOld(chapterId)
    return self._Model:CheckChapterIsOld(chapterId)
end

function XMechanismActivityControl:SetChapterToOld(chapterId)
    self._Model:SetChapterToOld(chapterId)
end

function XMechanismActivityControl:CheckStageIsOld(stageId)
    return self._Model:CheckStageIsOld(stageId)
end

function XMechanismActivityControl:SetStageToOld(stageId)
    self._Model:SetStageToOld(stageId)
end
--endregion

--region --------------------界面数据------------------------------
function XMechanismActivityControl:GetMechanismCurChapterId()
    return self._Model:GetMechanismCurChapterId()
end

function XMechanismActivityControl:SetMechanismCurChapterId(chapterId)
    self._Model:SetMechanismCurChapterId(chapterId)
end

function XMechanismActivityControl:GetLastSelectStageIndex(chapterId)
    return self._Model:GetLastSelectStageIndex(chapterId)
end

function XMechanismActivityControl:SetSelectStageIndex(chapterId, stageIndex)
    self._Model:SetSelectStageIndex(chapterId, stageIndex)
end
--endregion

function XMechanismActivityControl:GetChapterUnLockLeftTime(chapterId)
    local leftTime = 0
    local timeId = self._Model:GetMechanismChapterTimeIdById(chapterId)
    if XTool.IsNumberValid(timeId) then
        leftTime = XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
        if leftTime < 0 then
            leftTime = 0
        end
    end
    
    return leftTime
end

--- 可见的关卡列表，虽然在当前需求下“可见=已解锁”，但从接口的角度并不能将其视为等同
---@return table @关卡的Id
function XMechanismActivityControl:GetVisibleStageListByChapterId(chapterId)
    local isShow = self._Model:GetMechanismClientConfigBool('IsShowStageAlways')

    if isShow then
        return self._Model:GetMechanismChapterStageIdsById(chapterId)
    else
        return self:GetUnLockStageListByChapterId(chapterId)
    end
end

---@return table @关卡的Id
function XMechanismActivityControl:GetUnLockStageListByChapterId(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    
    local stageIds = self._Model:GetMechanismChapterStageIdsById(chapterId)
    
    local unlockIds = {}
    if not XTool.IsTableEmpty(stageIds) then
        for i, v in ipairs(stageIds) do
            if XMVCA.XMechanismActivity:CheckUnlockByStageId(v) then
                table.insert(unlockIds, v)
            end
        end
    end
    
    return unlockIds
end

function XMechanismActivityControl:GetTeamDataByChapterId(chapterId)
    local teamData = self._Model:GetTeamDataByChapterId(chapterId)
    if not teamData then
        XLog.Error('找不到该章节的队伍，章节Id:',chapterId)
    end
    return teamData
end

return XMechanismActivityControl