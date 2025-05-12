local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')
---@class XLinkCraftActivityAgency : XFubenActivityAgency
---@field private _Model XLinkCraftActivityModel
local XLinkCraftActivityAgency = XClass(XFubenActivityAgency, "XLinkCraftActivityAgency")
function XLinkCraftActivityAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
    self[XEnumConst.FuBen.ProcessFunc.PreFight] = self.PreFight
    XMVCA.XFuben:RegisterFuben(XEnumConst.FuBen.StageType.LinkCraftActivity,ModuleId.XLinkCraftActivity)
end

function XLinkCraftActivityAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    
    XRpc.NotifyLinkCraftData = handler(self, self.UpdateLinkCraftData)
    XRpc.NotifyLinkCraftNewChapterData = function()  end
end

function XLinkCraftActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XLinkCraftActivityAgency:OnRelease()
    
end

----------public start----------

--region 活动入口
function XLinkCraftActivityAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LinkCraftActivity) then
        return
    end
    XLuaUiManager.Open('UiLinkCraftActivityMain')
end

function XLinkCraftActivityAgency:ExCheckInTime()
    local activityId = self:GetCurActivityId()
    
    if not XTool.IsNumberValid(activityId) then
        return false 
    end

    local cfg =self._Model:GetLinkCraftActivityCfgById(activityId)
    if cfg then
        return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId,true)
    end
end

function XLinkCraftActivityAgency:ExGetProgressTip()
    local activityData = self._Model:GetActivityData()

    if activityData then
        local awardCount = self._Model:GetActivityData():GetTotalStarAward()
        local totalCount = 0
        
        --统计所有关卡的星级上限
        for i, v in ipairs(activityData._ChapterDataList) do
            local chapterId = v:GetChapterId()
            local chapterCfg = self._Model:GetLinkCraftChapterCfgById(chapterId)
            if chapterCfg then
                for i2, v2 in ipairs(chapterCfg.Stages) do
                    local stageCfg = self._Model:GetLinkCraftStageCfgById(v2)
                    if stageCfg then
                        totalCount = totalCount + stageCfg.StarsCnt
                    end
                end
            end
        end

        if awardCount > totalCount then
            awardCount = totalCount
        end

        if totalCount <=0 then
            totalCount = 1
        end
        
        return XUiHelper.FormatText(self._Model:GetClientConfigString('ProcessTip'),math.floor(awardCount/totalCount*100))
    end
end

function XLinkCraftActivityAgency:ExGetRunningTimeStr()
    return string.format("%s%s", XUiHelper.GetText("ActivityBranchFightLeftTime")
    , XUiHelper.GetTime(self:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY))
end

--endregion

--region getter

function XLinkCraftActivityAgency:GetCurActivityId()
    return self._Model:GetActivityId()
end

function XLinkCraftActivityAgency:GetLeftTime()
    local activityId = self:GetCurActivityId()

    if not XTool.IsNumberValid(activityId) then
        return 0
    end

    local cfg = self._Model:GetLinkCraftActivityCfgById(activityId)
    if cfg then
        local endTime = XFunctionManager.GetEndTimeByTimeId(cfg.TimeId)
        return endTime - XTime.GetServerNowTimestamp()
    end
    return 0
end

function XLinkCraftActivityAgency:CheckChapterIsLockById(chapterId)
    -- 检查并直接拦截非法id
    if not XTool.IsNumberValid(chapterId) then
        return true
    end
    
    local cfg = self._Model:GetLinkCraftChapterCfgById(chapterId)
    if XTool.IsTableEmpty(cfg) then
        return false
    end
    --优先判断时间
    if XTool.IsNumberValid(cfg.TimeId) then
        if not XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
            local leftTime = XFunctionManager.GetEndTimeByTimeId(cfg.TimeId) - XTime.GetServerNowTimestamp()
            return true, XUiHelper.GetText('BrilliantWalkChapterTime',XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
        end
    end
    --判断其余条件
    if cfg then
        if XTool.IsNumberValid(cfg.Condition) then
            if XConditionManager.CheckCondition(cfg.Condition) then
                return false,''
            else
                return true,XConditionManager.GetConditionDescById(cfg.Condition)
            end
        else
            return false,''
        end
    end
    
    return false,''
end

function XLinkCraftActivityAgency:CheckChapterIsNewById(chapterId)
    --先判断有没解锁
    if self:CheckChapterIsLockById(chapterId) then
        return false
    end
    
    local key = self:GetChapterNewTagKey(chapterId)
    local hasCache = XSaveTool.GetData(key)
    return not hasCache
end

function XLinkCraftActivityAgency:CheckHasNewChapter()
    local curActivityId = self:GetCurActivityId()
    
    -- 检查并直接拦截非法id
    if not XTool.IsNumberValid(curActivityId) then
        return false
    end
    
    local activityCfg = self._Model:GetLinkCraftActivityCfgById(curActivityId)
    if activityCfg and not XTool.IsTableEmpty(activityCfg.Chapters) then 
        local hasNew = false
        for i, v in ipairs(activityCfg.Chapters) do
            hasNew = hasNew or self:CheckChapterIsNewById(v)
        end
        return hasNew
    end
    return false
end

---@param stageId number @LinkStage表里的Id
function XLinkCraftActivityAgency:CheckStageIsPassById(stageId)
    local activityData = self._Model:GetActivityData()
    if XTool.IsTableEmpty(activityData) then
        return false
    end
    for i, v in ipairs(activityData._ChapterDataList) do
        if v:CheckStageIsPassById(stageId) then
            return true
        end
    end
    return false
end

function XLinkCraftActivityAgency:GetSkillIconById(skillId)
    local cfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    if cfg then
        return cfg.Icon
    end
end

function XLinkCraftActivityAgency:GetRobotListById(activityId)
    local cfg = self._Model:GetLinkCraftActivityCfgById(activityId)
    if cfg then
        return cfg.Robots
    end
end

function XLinkCraftActivityAgency:GetChapterNewTagKey(chapterId)
    return 'LinkCraftActivityNewChapter_'..chapterId..'_'..XPlayer.Id
end

function XLinkCraftActivityAgency:GetCurShopId()
    local activityId = self:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetLinkCraftActivityCfgById(activityId)
        if cfg then
            return cfg.ShopId
        end
    end
end

function XLinkCraftActivityAgency:GetStarCntByChapterId(chapterId)
    local chapterCfg = self._Model:GetLinkCraftChapterCfgById(chapterId)
    local count = 0
    if chapterCfg then
        for i, v in ipairs(chapterCfg.Stages) do
            local stageCfg = self._Model:GetLinkCraftStageCfgById(v)
            if stageCfg then
                count = count + stageCfg.StarsCnt
            end
        end
    end

    return count

end

function XLinkCraftActivityAgency:GetStarCntSetsByStageId(stageId)
    local stageCfg = self._Model:GetLinkCraftStageCfgById(stageId)
    if stageCfg then
        return stageCfg.StarsCnt
    end
    return 0
end

---@overload
function XLinkCraftActivityAgency:CheckPassedByStageId(stageId)
    --存储是以玩法里的关卡索引Id找的，需要将stage大表的id转换一下
    local cfg = self._Model:GetLinkCraftStageCfgByStageId(stageId)
    if cfg then
        return self:CheckStageIsPassById(cfg.Id)
    end
    return false
end

--- Stage.tab表的关卡Id找LinkCraftActivityStage表里的关卡Id
function XLinkCraftActivityAgency:GetStageIdOfLinkStageTabById(stageId)
    local cfg = self._Model:GetLinkCraftStageCfgByStageId(stageId)
    if cfg then
        return cfg.Id
    end
end

---@overload
function XLinkCraftActivityAgency:CheckUnlockByStageId(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageCfg then
        if not XTool.IsTableEmpty(stageCfg.PreStageId) then
            -- 判断前置关卡是否通关
            for i, v in pairs(stageCfg.PreStageId) do
                if not self:CheckPassedByStageId(v) then
                    return false
                end
            end
        end
        return true
    end
    return false
end

function XLinkCraftActivityAgency:GetClientConfigInt(key)
    return self._Model:GetClientConfigInt(key)
end
--endregion

--region setter
function XLinkCraftActivityAgency:UpdateLinkCraftData(data)
    self._Model:InitActivityData(data.LinkCraftData)
    
    -- 没有有效数据时不继续执行，防止无意义的配置表加载和数据请求
    local shopId = self:GetCurShopId()
    if XTool.IsNumberValid(shopId) then
        --因为需要商店数据进行蓝点判定，当活动开启时就请求获取商店数据
        --仅当玩家商店权限开放和需要蓝点判定时才主动提前请求数据
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) and XFunctionManager.CheckInTimeByTimeId(self:GetClientConfigInt('ShopShowReddotTimeId')) then
            XShopManager.GetShopInfo(shopId)
        end
    end
end
--endregion

--region 服务端请求
function XLinkCraftActivityAgency:RequestLinkCraftSelectLink(cb)
    local activityData = self._Model:GetActivityData()

    if XTool.IsTableEmpty(activityData) then
        return
    end
    
    local chapterId = activityData:GetCurChapterId()
    local linkId = activityData:GetCurLinkdData():GetId()
    XNetwork.Call("LinkCraftSelectLinkRequest",{ChapterId = chapterId, LinkId = linkId},function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(res.Code == XCode.Success)
        end
    end)
end

function XLinkCraftActivityAgency:RequestLinkCraftSetLinkSkills(cb)
    local activityData = self._Model:GetActivityData()

    if XTool.IsTableEmpty(activityData) then
        return
    end
    
    local linkData = activityData:GetCurLinkdData()
    local linkId = linkData:GetId()
    local skills = linkData:GetSkillList()
    
    XNetwork.Call("LinkCraftSetLinkSkillsRequest", {LinkId = linkId, Skills = skills}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        if cb then
            cb(res.Code == XCode.Success)
        end
    end)
end
--endregion

--region 战斗
function XLinkCraftActivityAgency:CheckPreFight(stage, challengeCount)
    local team = XDataCenter.TeamManager.GetTempTeamForce() or  self._Model:GetLocalTeam()
    if team:GetEntityCount()<=2 then
        XUiManager.TipMsg(XUiHelper.GetText('TeamEntityNoEnoughTip'))
        return false
    end
    local activityData = self._Model:GetActivityData()

    if XTool.IsTableEmpty(activityData) then
        return false
    end
    
    local linkData = activityData:GetCurLinkdData()
    if linkData then
        if XTool.GetTableCount(linkData:GetSkillList()) <=2 then
            XUiManager.TipMsg(self._Model:GetClientConfigString('LinkSkillLessTip'))
            return false
        end
    else
		XUiManager.TipMsg(self._Model:GetClientConfigString('LinkSkillLessTip'))
        return false
    end
    return true
end

function XLinkCraftActivityAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.RobotIds={}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    -- 如果有试玩角色且没有隐藏模式，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = self._Model:GetLocalTeam()
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
    end

    return preFight
end

---@overload
function XLinkCraftActivityAgency:FinishFight(settle)
    XMVCA.XFuben:FinishFight(settle)
end

-- 胜利 & 奖励界面
function XLinkCraftActivityAgency:ShowReward(winData)
    XLuaUiManager.Open("UiSettleWinMainLine", winData)
end

--endregion

----------public end----------

----------private start----------


----------private end----------

return XLinkCraftActivityAgency