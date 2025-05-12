local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XMechanismActivityAgency : XAgency
---@field private _Model XMechanismActivityModel
--- 机制玩法
local XMechanismActivityAgency = XClass(XFubenActivityAgency, "XMechanismActivityAgency")

function XMechanismActivityAgency:OnInit()
    self:RegisterActivityAgency()
    XMVCA.XFuben:RegisterFuben(XEnumConst.FuBen.StageType.MechanismActivity,ModuleId.XMechanismActivity)
end

function XMechanismActivityAgency:InitRpc()
    XRpc.NotifyMechanismDataDb = handler(self, self.RecieveMechanismDataDbNotify)
end

function XMechanismActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

--region -----------------------------override------------------------------->>

-------------------------------------活动入口----------------------------------
function XMechanismActivityAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MechanismActivity) then
        return
    end

    if XTool.IsNumberValid(self._Model:GetActivityIdFromCurData()) then
        XLuaUiManager.Open('UiMechanismMain')
    else
        XUiManager.TipText('CommonActivityNotStart')
    end
end

function XMechanismActivityAgency:ExGetProgressTip()
    local activityId = self._Model:GetActivityIdFromCurData()
    if XTool.IsNumberValid(activityId) then
        local chapterIds = self._Model:GetMechanismActivityChapterIdsById(activityId)
        -- 统计当前活动所有章节关卡的星数上限之和
        local totalCount = 0

        if not XTool.IsTableEmpty(chapterIds) then
            for i1, chapterId in ipairs(chapterIds) do
                local stageIds = self._Model:GetMechanismChapterStageIdsById(chapterId)

                if not XTool.IsTableEmpty(stageIds) then
                    for i2, stageId in pairs(stageIds) do
                        local starLimit = self._Model:GetMechanismStageStarLimitById(stageId)
                        totalCount = totalCount + starLimit
                    end
                end
            end
        end

        -- 统计当前活动已经获得的星数
        local curCount = self._Model:GetStarRewardGotTotalFromCurData()

        -- 上限修正
        if totalCount <=0 then
            totalCount = 1
        end
        -- 溢出修正
        if curCount > totalCount then
            curCount = totalCount
        end

        return XUiHelper.FormatText(self._Model:GetMechanismClientConfigString('ProcessTip'), curCount, totalCount)
    else
        return ''
    end


end

function XMechanismActivityAgency:ExGetRunningTimeStr()
    return string.format("%s%s", XUiHelper.GetText("ActivityBranchFightLeftTime")
    , XUiHelper.GetTime(self:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY))
end

------------------------------------关卡/战斗---------------------------------

---@param stageId @Stage.tab表的Id
function XMechanismActivityAgency:CheckPassedByStageId(stageId)
    if XTool.IsNumberValid(stageId) then
        local data = self._Model:GetPassStageDataById(stageId)
        return not XTool.IsTableEmpty(data)
    end
    return false
end

---@param stageId @Stage.tab表的Id
function XMechanismActivityAgency:CheckUnlockByStageId(stageId)
    -- 解锁仅有前置关卡限制
    if XTool.IsNumberValid(stageId) then
        ---@type XTableStage
        local mainCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if mainCfg and not XTool.IsTableEmpty(mainCfg.PreStageId) then
            for i, v in pairs(mainCfg.PreStageId) do
                if not self:CheckPassedByStageId(v) then
                    return false, v
                end
            end
        end
    end
    return true
end

function XMechanismActivityAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.RobotIds={}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    
    ---@type XTeam
    local teamData = nil

    -- 如果关卡有配置固定队伍，则不读玩法自己的队伍
    if not stage.RobotId or #stage.RobotId <= 0 then
        teamData = self._Model:GetTeamDataByChapterId(self:GetMechanismCurChapterId())
    else
        -- 固定队伍会创建临时队伍数据
        teamData = XDataCenter.TeamManager.GetTempTeam(teamId)
    end

    if not XTool.IsTableEmpty(teamData) then
        for _, v in pairs(teamData:GetEntityIds()) do
            if XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.RobotIds, v)
                table.insert(preFight.CardIds, 0)
            else
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            end
        end
        preFight.CaptainPos = teamData:GetCaptainPos()
        preFight.FirstFightPos = teamData:GetFirstFightPos()
        preFight.GeneralSkill = teamData:GetCurGeneralSkill()
    end

    self._Model:UITempDataTransferFight()
    
    return preFight
end

-- 胜利 & 奖励界面
---@overload
function XMechanismActivityAgency:ShowReward(winData)
    XLuaUiManager.Open("UiMechanismSettlement", winData)
end

--endregion <<<<-----------------------------------------------------------------------

function XMechanismActivityAgency:GetLeftTime()
    local activityId = self._Model:GetActivityIdFromCurData()

    if XTool.IsNumberValid(activityId) then
        local timeId = self._Model:GetMechanismActivityTimeIdById(activityId)
        if XTool.IsNumberValid(timeId) then
            local leftTime = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            if leftTime < 0 then
                leftTime = 0
            end
            return leftTime
        end
    end
    return 0
end

function XMechanismActivityAgency:CheckChapterUnLock(chapterId)
    local timeId = self._Model:GetMechanismChapterTimeIdById(chapterId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XMechanismActivityAgency:GetCurShopId()
    local activityId = self._Model:GetActivityIdFromCurData()
    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetMechanismActivityCfgById(activityId)
        if cfg then
            return cfg.ShopId
        end
    end
    return 0
end

--region --------------------界面数据------------------------------
function XMechanismActivityAgency:GetMechanismCurChapterId()
    return self._Model:GetMechanismCurChapterId()
end

function XMechanismActivityAgency:GetMechanismCurChapterIdInFight()
    return self._Model:GetMechanismCurChapterIdInFight()
end
--endregion

--region --------------------配置表数据------------------------------
function XMechanismActivityAgency:GetMechanismCharacterCfgsByChapterId(chapterId)
    if XTool.IsNumberValid(chapterId) then
        local chapterCfg = self._Model:GetMechanismChapterCfgById(chapterId)
        if chapterCfg then
            local characterList = {}
            for i, v in ipairs(chapterCfg.LimitCharacterIds) do
                if XTool.IsNumberValid(v) then
                    local characterCfg = self._Model:GetMechanismCharacterCfgById(v)
                    if characterCfg then
                        table.insert(characterList, characterCfg)
                    end
                end
            end
            return characterList
        end
    end
end

function XMechanismActivityAgency:GetMechanismClientConfigNum(key)
    return self._Model:GetMechanismClientConfigNumber(key)
end
--endregion

--region --------------------蓝点------------------------------
function XMechanismActivityAgency:CheckHasChapterReddot()
    if self:ExCheckInTime() then
        local activityId = self._Model:GetActivityIdFromCurData()
        if XTool.IsNumberValid(activityId) then
            local chapterIds = self._Model:GetMechanismActivityChapterIdsById(activityId)
            for i, v in ipairs(chapterIds) do
                -- 章节解锁且为新
                if self:CheckChapterUnLock(v) then
                    -- 新章节有蓝点
                    if not self._Model:CheckChapterIsOld(v) then
                        return true
                    end
                    
                    -- 章节有新解锁关卡时也有蓝点
                    if self:CheckHasNewStageByChapterId(v) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XMechanismActivityAgency:CheckHasNewStageByChapterId(chapterId)
    if self:ExCheckInTime() and XTool.IsNumberValid(chapterId) then
        local activityId = self._Model:GetActivityIdFromCurData()
        if XTool.IsNumberValid(activityId) then
            local stageIds = self._Model:GetMechanismChapterStageIdsById(chapterId)
            for i, v in ipairs(stageIds) do
                if self:CheckUnlockByStageId(v) and not self._Model:CheckStageIsOld(v) then
                    return true
                end
            end
        end
    end
    return false
end
--endregion
----------public end----------

----------private start----------

function XMechanismActivityAgency:RecieveMechanismDataDbNotify(data)
    self._Model:RecieveActivityData(data)
    --因为需要商店数据进行蓝点判定，当活动开启时就请求获取商店数据
    --仅当玩家商店权限开放和需要蓝点判定时才主动提前请求数据
    if self:ExCheckInTime() and XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) and XFunctionManager.CheckInTimeByTimeId(self:GetMechanismClientConfigNum('ShopShowReddotTimeId')) then
        local shopId = self:GetCurShopId()
        if XTool.IsNumberValid(shopId) then
            XShopManager.GetShopInfo(shopId, nil, true)
        end
    end
end

----------private end----------

return XMechanismActivityAgency