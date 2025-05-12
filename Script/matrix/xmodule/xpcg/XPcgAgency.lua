local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPcgAgency : XFubenActivityAgency
---@field private _Model XPcgModel
local XPcgAgency = XClass(XFubenActivityAgency, "XPcgAgency")
function XPcgAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()

    self.RichTextImageCallBack = handler(self, self.OnRichTextImageCallBack)
end

function XPcgAgency:InitRpc()
    --实现服务器事件注册
    XRpc.PcgStagesNotify = handler(self, self.PcgStagesNotify)
    XRpc.PcgEffectSettleNotify = handler(self, self.PcgEffectSettleNotify)
    XRpc.PcgCharacterUnlockNotify = handler(self, self.PcgCharacterUnlockNotify)
    self.RequestName = {
        PcgStageBeginRequest = "PcgStageBeginRequest",                          -- 请求关卡开始
        PcgStageEndRequest = "PcgStageEndRequest",                              -- 请求结束关卡
        PcgStageRestartRequest = "PcgStageRestartRequest",                      -- 请求重新开始 
        PcgPlayCardRequest = "PcgPlayCardRequest",                              -- 请求出牌
        PcgCommanderBehaviorRequest = "PcgCommanderBehaviorRequest",            -- 请求使用指挥官技能
        PcgCommanderTargetRequest = "PcgCommanderTargetRequest",                -- 请求选中目标怪物
        PcgChangeCharacterRequest = "PcgChangeCharacterRequest",                -- 请求切换角色
        PcgRoundEndRequest = "PcgRoundEndRequest",                              -- 请求回合结束
        PcgDrawPoolRequest = "PcgDrawPoolRequest",                              -- 查看抽牌堆
        PcgDropPoolRequest = "PcgDropPoolRequest",                              -- 查看弃牌堆
    }
end

function XPcgAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 协议数据
-- 通知玩法数据
function XPcgAgency:PcgStagesNotify(data)
    self._Model:PcgStagesNotify(data)
end

-- 通知结算效果列表
function XPcgAgency:PcgEffectSettleNotify(data)
    self._Model:OnEffectSettleNotify(data)
end

-- 通知新角色解锁
function XPcgAgency:PcgCharacterUnlockNotify(data)
    self._Model:OnCharacterUnlockNotify(data)
end

-- 请求进入关卡，开始新游戏/继续游戏/下一关
function XPcgAgency:PcgStageBeginRequest(stageId, characterIds, cb)
    local req = { StageId = stageId, CharacterIds = characterIds }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgStageBeginRequest, req, function(res)
        self._Model:OnStageBegin(res.PlayingStage)
        XEventManager.DispatchEvent(XEventId.EVENT_PCG_GAME_START)
        if cb then cb() end
    end)
end

-- 请求结束关卡
function XPcgAgency:PcgStageEndRequest(stageId, cb)
    local req = { StageId = stageId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgStageEndRequest, req, function(res)
        self._Model:RefreshStageRecord(stageId, res.StageRecord)
        self._Model:SetStageFinished()
        if cb then cb() end
    end)
end

-- 请求重新开始
function XPcgAgency:PcgStageRestartRequest(stageId, characterIds, cb)
    local req = { StageId = stageId, CharacterIds = characterIds }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgStageRestartRequest, req, function(res)
        self._Model:RefreshStageRecord(stageId, res.StageRecord)
        self._Model:OnStageBegin(res.PlayingStage)
        XEventManager.DispatchEvent(XEventId.EVENT_PCG_GAME_START)
        if cb then cb() end
    end)
end

-- 请求出牌
function XPcgAgency:PcgPlayCardRequest(cardIdx, cb)
    local req = { CardIdx = cardIdx }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgPlayCardRequest, req, function(res)
        self._Model:RefreshStageRecord(res.PlayingStage.Id, res.StageRecord)
        self._Model:RefreshPlayingStageData(res.PlayingStage)
        if cb then cb() end
    end)
end

-- 请求使用指挥官技能
function XPcgAgency:PcgCommanderBehaviorRequest(handPool, cb)
    local req = { HandPool = handPool }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgCommanderBehaviorRequest, req, function(res)
        self._Model:RefreshCommander(res.Commander)
        self._Model:RefreshHandPool(res.HandPool)
        if cb then cb() end
    end)
end

-- 请求选中目标怪物
function XPcgAgency:PcgCommanderTargetRequest(targetMonsterIdx, cb)
    local req = { TargetMonsterIdx = targetMonsterIdx }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgCommanderTargetRequest, req, function(res)
        self._Model:RefreshCommander(res.Commander)
        if cb then cb() end
    end)
end

-- 请求切换角色
function XPcgAgency:PcgChangeCharacterRequest(characterIdx, cb)
    local req = { CharacterIdx = characterIdx }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgChangeCharacterRequest, req, function(res)
        self._Model:RefreshStageRecord(res.PlayingStage.Id, res.StageRecord)
        self._Model:RefreshPlayingStageData(res.PlayingStage)
        if cb then cb() end
    end)
end

-- 请求回合结束
function XPcgAgency:PcgRoundEndRequest(cb)
    local stageId = self._Model:GetCurrentStageId()
    local req = {}
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgRoundEndRequest, req, function(res)
        if res.StageRecord then
            self._Model:SetStageFinished()
        end
        self._Model:RefreshStageRecord(stageId, res.StageRecord)
        if res.RoundNextPlayingStage then
            self._Model:RefreshPlayingStageData(res.RoundNextPlayingStage)
        end
        if cb then cb() end
    end)
end

-- 请求查看抽牌堆
function XPcgAgency:PcgDrawPoolRequest(cb)
    local req = {}
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgDrawPoolRequest, req, function(res)
        if cb then cb(res.DrawPool) end
    end)
end

-- 请求查看弃牌堆
function XPcgAgency:PcgDropPoolRequest(cb)
    local req = {}
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PcgDropPoolRequest, req, function(res)
        if cb then cb(res.DropPool) end
    end)
end
--endregion

--region 副本入口扩展
function XPcgAgency:ExOpenMainUi()
    if not self:IsOpen(true) then
        return
    end
    -- 打开玩法主界面
    XLuaUiManager.Open("UiPcgMain")
end

function XPcgAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XPcgAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Pcg
end

function XPcgAgency:ExCheckInTime()
    return self.Super.ExCheckInTime(self)
end

function XPcgAgency:ExGetProgressTip()
    local allStageCnt = 0
    local passedStageCnt = 0
    local chapterCfgs = self._Model:GetConfigChapter()
    for _, chapterCfg in pairs(chapterCfgs) do
        -- 普通关
        for _, stageId in pairs(chapterCfg.StageIds) do
            allStageCnt = allStageCnt + 1
            local isPassed = self._Model:IsStagePassed(stageId)
            if isPassed then
                passedStageCnt = passedStageCnt + 1
            end
        end
        -- 无尽关
        local stageId = chapterCfg.ChallengeStageId
        if XTool.IsNumberValid(stageId) then
            allStageCnt = allStageCnt + 1
            if self._Model:IsStagePassed(stageId) then
                passedStageCnt = passedStageCnt + 1
            end
        end
    end
    local progressFormat = self._Model:GetClientConfig("ProgressTxt")
    return string.format(progressFormat, passedStageCnt, allStageCnt)
end
--endregion

-- 玩法是否开启
function XPcgAgency:IsOpen(isTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Pcg, false, not isTips) then
        return false
    end
    
    -- PcgActivity.tab配置活动是否已结束
    local isEnd = true
    local nowTime = XTime.GetServerNowTimestamp()
    local activityCfgs = self._Model:GetConfigActivity()
    for _, activityCfg in pairs(activityCfgs) do
        if activityCfg.TimeId ~= 0 then
            local endTime = XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId)
            if nowTime < endTime then
                isEnd = false
            end
        end
    end
    
    -- 服务器未下发活动报错提示
    if not self._Model.ActivityData then
        if isTips then
            local tips = self._Model:GetClientConfig("EnterActivityFail", isEnd and 2 or 1)
            XUiManager.TipError(tips)
        end
        return false
    end
    if not self._Model:CheckActivityInTime() then
        if isTips then
            local tips = self._Model:GetClientConfig("EnterActivityFail", isEnd and 2 or 1)
            XUiManager.TipError(tips)
        end
        return false
    end
    return true
end

-- 是否显示蓝点
function XPcgAgency:IsShowRed()
    if not self:IsOpen() then
        return false
    end
    -- 任务蓝点
    if self._Model:IsTaskShowRed() then
        return true
    end
    -- 章节蓝点
    local chapterCfgs = self._Model:GetConfigChapter()
    for _, chapterCfg in pairs(chapterCfgs) do
        if self._Model:IsChapterShowRed(chapterCfg.Id) then
            return true
        end
    end
    return false
end

-- 关卡是否通过
function XPcgAgency:IsStagePassed(stageId)
    return self._Model:IsStagePassed(stageId)
end

-- 获取当前进行中的关卡Id
function XPcgAgency:GetCurrentStageId()
    return self._Model:GetCurrentStageId()
end

-- 获取关卡类型
function XPcgAgency:GetStageType(stageId)
    return self._Model:GetStageType(stageId)
end

-- 文本组件获取图片路径接口
function XPcgAgency:OnRichTextImageCallBack(key, image)
    local url = self._Model:GetClientConfig(key)
    if string.IsNilOrEmpty(url) then
        XLog.Error("创建图片失败! PcgClientConfig.tab 未配置主键 = " .. key)
        return
    end
    image:SetSprite(url)
end

-- c#下标转lua下标
function XPcgAgency:ConvertCSharpIndexToLuaIndex(args)
    if type(args) == "table" then
        local result = {}
        for _, arg in ipairs(args) do
            table.insert(result, arg + 1)
        end
        return result
    elseif type(args) == "number" then
        return args + 1
    end
    return args
end

return XPcgAgency
