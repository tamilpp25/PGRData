local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local STR_MINUTES = ''
local STR_HOUR =''
local STR_DAY = ''
---@class XKotodamaActivityAgency : XAgency
---@field private _Model XKotodamaActivityModel
local XKotodamaActivityAgency = XClass(XFubenActivityAgency, "XKotodamaActivityAgency")
function XKotodamaActivityAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
    self[XEnumConst.FuBen.ProcessFunc.FinishFight]=self.FinishFight
    self[XEnumConst.FuBen.ProcessFunc.PreFight]=self.PreFight
    XMVCA.XFuben:RegisterFuben(XEnumConst.FuBen.StageType.KotodamaActivity,ModuleId.XKotodamaActivity)

     STR_MINUTES = CS.XTextManager.GetText("Minutes") -- 分钟
     STR_HOUR = CS.XTextManager.GetText("Hour")
    STR_DAY = CS.XTextManager.GetText("Day")
end

function XKotodamaActivityAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyKotodamaData=function(data) 
        self._Model:SetActivityData(data)
    end
end

function XKotodamaActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

--region 副本入口相关
function XKotodamaActivityAgency:ExOpenMainUi()
    if XSaveTool.GetData(self:GetKotodamaNotFirstIntoKey()) then
        XLuaUiManager.Open('UiKotodamaMain')
    else
        local activityCfg=self._Model:GetKotodamaActivity()[self:GetCurActivityId()]
        if activityCfg and XTool.IsNumberValid(activityCfg.PrologueId) then
            XDataCenter.MovieManager.PlayMovie(activityCfg.PrologueId,function()
                XSaveTool.SaveData(self:GetKotodamaNotFirstIntoKey(),true)
                XLuaUiManager.Open('UiKotodamaMain')
            end,nil,nil,false)
        else
            XLuaUiManager.Open('UiKotodamaMain')
            XLog.Error('活动缺少序章配置,activityId:'..self:GetCurActivityId())
        end
    end
end

function XKotodamaActivityAgency:ExCheckInTime()
    local activityId=self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then return false end
    local cfg=self._Model:GetKotodamaActivity()[activityId]
    if cfg then
        return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId,true)
    end
end

function XKotodamaActivityAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)

    return self.ExConfig
end

function XKotodamaActivityAgency:ExGetProgressTip()
    local passCount=self._Model:GetPassedStageCount()
    local totalCount=self._Model:GetKotodamaStageCount()
    return XUiHelper.GetText('KotodamaProcess',passCount,totalCount)
end

function XKotodamaActivityAgency:ExGetChapterType()
    
end

function XKotodamaActivityAgency:ExGetRunningTimeStr()
    local timeId=self._Model:GetActivityTimeId()
    local endTime=XFunctionManager.GetEndTimeByTimeId(timeId)
    local leftTime=endTime-XTime.GetServerNowTimestamp()
    leftTime=leftTime>0 and leftTime or 0
    
    return string.format("%s%s", XUiHelper.GetText("ActivityBranchFightLeftTime")
    , XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
end
--endregion

--region 活动数据相关
function XKotodamaActivityAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

function XKotodamaActivityAgency:CheckStageIsPassById(stageId)
    if self._Model:IsActivityDataExisit() then
        for i, v in pairs(self._Model:GetPassStagesData()) do
            if v.StageId==stageId then
                return true
            end
        end
    end
    return false
end

function XKotodamaActivityAgency:CheckStageIsUnLockById(stageId)
    if not XTool.IsNumberValid(stageId) then
        XLog.Error('错误的关卡Id:'..stageId)
        return false
    end
    --获取当前关卡的前置关卡配置
    local preStageCfg=XDataCenter.FubenManager.GetStageCfg(stageId)
    --判断前置关卡是否通关
    local preIsPass=true
    if XTool.IsNumberValid(preStageCfg.PreStageId[1]) then
        preIsPass=self:CheckStageIsPassById(preStageCfg.PreStageId[1])
    end
    --判断当前关卡是否到达开启时间
    local curStageCfg=self._Model:GetKotodamaStageCfgById(stageId)
    if not XTool.IsTableEmpty(curStageCfg) then
        local curStamp=XTime.GetServerNowTimestamp()
        local startTime=XFunctionManager.GetStartTimeByTimeId(self._Model:GetActivityTimeId())
        local inTime=curStamp>(startTime+curStageCfg.OpenTime)
        return  inTime and preIsPass,inTime,preIsPass
    end
end

function XKotodamaActivityAgency:GetStageUnLockLeftTime(stageId)
    local curStageCfg=self._Model:GetKotodamaStageCfgById(stageId)
    --计算距离解锁剩余的时间
    local startTime = XFunctionManager.GetStartTimeByTimeId(self._Model:GetActivityTimeId())
    local leftTime = curStageCfg.OpenTime + startTime - XTime.GetServerNowTimestamp()
    if leftTime<0 then
        leftTime = 0
    end
    local month, weeks, days, hours, minutes = XUiHelper.GetTimeNumber(leftTime)
    if days>=1 then
        local totalDay = math.floor(leftTime/(3600 * 24))
        return string.format("%d%s",totalDay,STR_DAY)
    end
    if hours >= 1 then
        return string.format("%d%s", hours, STR_HOUR)
    end
    if minutes >= 1 then
        return string.format("%d%s", minutes, STR_MINUTES)
    end
    return string.format("%d%s", 1, STR_MINUTES)
end

function XKotodamaActivityAgency:GetCurStageId()
    local curStageData=self._Model:GetCurStageData()
    if curStageData then
        return curStageData.StageId
    end
    return 0
end

function XKotodamaActivityAgency:GetAllUnLockCollectSentenceIds()
    local allSentences=self._Model:GetAllUnLockSentenceIds()
    local result={}
    if not XTool.IsTableEmpty(allSentences) then
        --筛选出是图鉴的部分
        for i, v in pairs(allSentences) do
            if self._Model:IsSentenceCollectable(v) then
                table.insert(result,v)
            end
        end
        --排序
        table.sort(result,function(a, b)
            return a<b
        end)
    end
    return result
end

function XKotodamaActivityAgency:CheckSpeechStateExsist(sentenceId)
    local key=self:GetKotodamaSpeechKey()..sentenceId
    local result=XSaveTool.GetData(key)
    if result==nil then return false end
    return true
end

function XKotodamaActivityAgency:CheckSpeechIsNew(sentenceId)
    local key=self:GetKotodamaSpeechKey()..sentenceId
    local isNew=XSaveTool.GetData(key)
    if isNew==nil or isNew==XEnumConst.KotodamaActivity.LocalNewState.New then
        return true
    end
    return false
end

function XKotodamaActivityAgency:SetSpeechNewState(sentenceId,isNew)
    local key=self:GetKotodamaSpeechKey()..sentenceId
    XSaveTool.SaveData(key,isNew)
end

function XKotodamaActivityAgency:ClearAllNewSentenceState(sentenceIds)
    if not XTool.IsTableEmpty(sentenceIds) then
        for i, v in pairs(sentenceIds) do
            if self:CheckSpeechIsNew(v) then
                self:SetSpeechNewState(v,XEnumConst.KotodamaActivity.LocalNewState.Old)
            end
        end
    end
end

function XKotodamaActivityAgency:CheckStageIsNew(stageId)
    local key=self:GetKotodamaStageKey()..stageId
    local isNew=XSaveTool.GetData(key)
    if isNew==nil or isNew==XEnumConst.KotodamaActivity.LocalNewState.New then
        return true
    end
    return false
end

function XKotodamaActivityAgency:SetStageNewState(stageId,isNew)
    local key=self:GetKotodamaStageKey()..stageId
    XSaveTool.SaveData(key,isNew)
end

function XKotodamaActivityAgency:CheckStageStateExsist(stageId)
    local key=self:GetKotodamaStageKey()..stageId
    local result=XSaveTool.GetData(key)
    if result==nil then return false end
    return true
end
--endregion

--region 配置相关
function XKotodamaActivityAgency:GetCharacterIdsByStageId(stageId)
    if not XTool.IsNumberValid(stageId) then return end
    local cfgs=self._Model:GetKotodamaCharacterGroup()
    local stageCfg=self._Model:GetKotodamaStageCfgById(stageId)
    if stageCfg then
        --获取属于本关卡的角色、机器人Id
        local characterList={}
        local robotList={}
        for id, cfg in pairs(cfgs) do
            if stageCfg.CharacterGroup==cfg.GroupId then
                if cfg.CharacterId then
                    table.insert(characterList,cfg.CharacterId)
                end
                if cfg.RobotId then
                    table.insert(robotList,cfg.RobotId)
                end
            end
        end
        return characterList,robotList
    end
end

function XKotodamaActivityAgency:GetCurActivityTaskId()
    local activity=self:GetCurActivityId()
    if activity then
        return self._Model:GetActivityTaskId(activity)
    end
end

function XKotodamaActivityAgency:GetAllKotodamaStageCfg()
    return self._Model:GetKotodamaStage()
end

function XKotodamaActivityAgency:GetNextStageIdByStageId(curStageId)
    local stageCfg=self._Model:GetKotodamaStageCfgById(curStageId)
    local allStageCfgs=self._Model:GetKotodamaStage()
    for i, v in pairs(allStageCfgs) do
        if v.Order-stageCfg.Order==1 then
            return v.Id
        end
    end
end

function XKotodamaActivityAgency:GetCurActivityCfg()
    local activity=self:GetCurActivityId()
    if activity then
        return self._Model:GetKotodamaActivity()[activity]
    end
end
--endregion

--region 协议请求相关
function XKotodamaActivityAgency:KotodamaSpellSentenceRequest(cb,stageId,sentenceSpell)
    XNetwork.Call('KotodamaSpellSentenceRequest',{StageId = stageId,SpellSentences = sentenceSpell},function(result)
        if result.Code~=XCode.Success then
            XUiManager.TipCode(result.Code)
            return
        end
        if cb then
            cb(result)
        end
    end)
end


function XKotodamaActivityAgency:KotodamaSpellSentenceResetRequest(cb,stageId)
    XNetwork.Call('KotodamaResetStageSentenceRequest', { StageId = stageId },function(result)
        if result.Code~=XCode.Success then
            XUiManager.TipCode(result.Code)
            return
        end
        if cb then
            cb(result)
        end
    end)
end

function XKotodamaActivityAgency:CheckAndSubmitReset(cb)
    local isReset,resetStageId = self._Model:GetHasResetLocal()
    if isReset then
        --请求重置
        self:KotodamaSpellSentenceRequest(function()
            self:KotodamaSpellSentenceResetRequest(function()
                --取消标记
                self._Model:ClearResetLocalMark()
                if cb then
                    cb()
                end
            end,resetStageId)
        end,resetStageId, {})
    else
        if cb then
            cb()
        end
    end
end
--endregion

function XKotodamaActivityAgency:CallWinPanel()
    if not XTool.IsTableEmpty(self.settleData) and self.settleData.IsWin then
        XLuaUiManager.Open('UiKotodamaSettlement',self.settleData)
        self.settleData=nil
    end
end

function XKotodamaActivityAgency:LoadTeamLocal()
    local team = self._Model:LoadTeamLocal()
    XDataCenter.TeamManager.SetXTeam(team)
    return team
end
----------public end----------

----------private start----------


function XKotodamaActivityAgency:FinishFight(settle)
    self.settleData=settle
    --更新图鉴
    if settle.XKotodamaSettleResult then
        if not XTool.IsTableEmpty(settle.XKotodamaSettleResult.Sentences) then
            for i, v in pairs(settle.XKotodamaSettleResult.Sentences) do
                if self._Model:IsSentenceCollectable(v) then
                    if not self:CheckSpeechStateExsist(v) then
                        self:SetSpeechNewState(v,XEnumConst.KotodamaActivity.LocalNewState.New)
                    end
                end
            end
        end
    end
    --更新关卡
    local nextStageId=self:GetNextStageIdByStageId(settle.StageId)
    if XTool.IsNumberValid(nextStageId) then
        if not self:CheckStageStateExsist(nextStageId) then
            self:SetStageNewState(nextStageId,XEnumConst.KotodamaActivity.LocalNewState.New)
        end
    end
    if not settle.IsWin then
        XMVCA.XFuben:ChallengeLose(settle)
    end
end

function XKotodamaActivityAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.RobotIds={}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    -- 如果有试玩角色且没有隐藏模式，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for _, v in pairs(teamData) do
            if XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.RobotIds, v)
                table.insert(preFight.CardIds, 0)
            else
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            end
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
    end
    
    return preFight
end

function XKotodamaActivityAgency:CheckUnlockByStageId(stageId)
    return self:CheckStageIsUnLockById(stageId)
end

function XKotodamaActivityAgency:CheckPassedByStageId(stageId)
    return self:CheckStageIsPassById(stageId)
end

function XKotodamaActivityAgency:GetKotodamaSpeechKey()
    return 'KotodamaActivity_Speech_'..XPlayer.Id
end

function XKotodamaActivityAgency:GetKotodamaStageKey()
    return 'KotodamaActivity_Stage_'..XPlayer.Id
end

function XKotodamaActivityAgency:GetKotodamaNotFirstIntoKey()
    return 'KotodamaActivity_NotFirstInto_'..XPlayer.Id
end

function XKotodamaActivityAgency:GetKotodamaNotFirstAllPassKey()
    return 'KotodamaActivity_NotFirstAllPass_'..XPlayer.Id
end
----------private end----------

return XKotodamaActivityAgency