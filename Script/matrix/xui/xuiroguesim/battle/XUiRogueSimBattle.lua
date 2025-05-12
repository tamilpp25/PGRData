local XUiPanelRogueSimAsset = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset")
---@class XUiRogueSimBattle : XLuaUi
---@field private _Control XRogueSimControl
---@field private AssetPanel XUiPanelRogueSimAsset
local XUiRogueSimBattle = XLuaUiManager.Register(XLuaUi, "UiRogueSimBattle")

local MinMaxCurve = CS.UnityEngine.ParticleSystem.MinMaxCurve

function XUiRogueSimBattle:OnAwake()
    self:RegisterUiEvents()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.PanelNews.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimBuff[]
    self.GridBuffList = {}
    -- 特效
    self.Effect = {
        [1] = {
            StartNode = self.Effect01,
            Particle = self.FxIconLaunch01,
            EndNode = self.FxtBaodian01,
        },
        [2] = {
            StartNode = self.Effect02,
            Particle = self.FxIconLaunch02,
            EndNode = self.FxtBaodian02,
        },
        [3] = {
            StartNode = self.Effect03,
            Particle = self.FxIconLaunch03,
            EndNode = self.FxtBaodian03,
        }
    }
    -- 隐藏特效
    for _, effect in pairs(self.Effect) do
        effect.StartNode.gameObject:SetActiveEx(false)
        effect.EndNode.gameObject:SetActiveEx(false)
    end
    -- 隐藏音效
    self:SFXCollectActive(false)
end

function XUiRogueSimBattle:OnStart()
    -- 显示资源
    self.AssetPanel = XUiPanelRogueSimAsset.New(self.PanelAsset, self, XEnumConst.RogueSim.ResourceId.Gold, XEnumConst.RogueSim.CommodityIds, true)
    self.AssetPanel:Open()
    -- 是否第一次进入
    self.IsFirstEnter = true
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd(true)
        end
    end)
end

function XUiRogueSimBattle:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTurnNumber()
    self:RefreshPopulation()
    self:RefreshBuff()
    self:RefreshEvent()
    self:RefreshBtn()
    self:RefreshBuildReward()
    self:RefreshRedPoint()
    self:RefreshTarget()
    self:RefreshPanelMapDistance()
    self:StartNextTipsTimer()

    if self.IsFirstEnter then
        -- 打开过场
        self:OpenTransition()
        self.IsFirstEnter = false
    end
end

function XUiRogueSimBattle:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
    }
end

function XUiRogueSimBattle:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE,
        XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE,
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
        XEventId.EVENT_ROGUE_SIM_BUILDING_ADD,
        XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE,
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_TEMPORARY_BAG_CHANGE,
    }
end

function XUiRogueSimBattle:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE then
        self:RefreshPopulation()
    elseif event == XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE then
        self:RefreshTurnNumber()
    elseif event == XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE then
        self:RefreshBuff()
    elseif event == XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP then
    elseif event == XEventId.EVENT_ROGUE_SIM_BUILDING_ADD then
        self:RefreshBuildBtn()
        self:RefreshBuildReward()
    elseif event == XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE then
    elseif event == XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE then
        self:RefreshPopulation()
    elseif event == XEventId.EVENT_ROGUE_SIM_TEMPORARY_BAG_CHANGE then
        self:RefreshBuildReward()
        self:PlayBuildCommodityAnim(...)
    elseif event == XEventId.EVENT_GUIDE_START then
        self._Control:SaveGuideIsTriggerById(...)
    end
end

function XUiRogueSimBattle:OnDisable()
    self.Super.OnDisable(self)
    self:StopTips()
    self:ClearNextTipsTimer()
    self:StopParticleEffectTimer()
    -- 隐藏特效
    for _, effectData in pairs(self.Effect) do
        effectData.StartNode.gameObject:SetActiveEx(false)
        effectData.EndNode.gameObject:SetActiveEx(false)
    end
    -- 隐藏传闻
    self.PanelNews.gameObject:SetActiveEx(false)
    -- 隐藏音效
    self:SFXCollectActive(false)
end

-- 刷新回合数
function XUiRogueSimBattle:RefreshTurnNumber()
    -- 回合数
    local desc = self._Control:GetClientConfig("BattleRoundNumDesc", 1)
    local curTurnCount = self._Control:GetCurTurnNumber()
    self.TxtTime.text = XUiHelper.ReplaceTextNewLine(string.format(desc, curTurnCount))
    -- 进度条
    local maxTurnCount = self._Control:GetRogueSimStageMaxTurnCount(self._Control:GetCurStageId())
    self.ImgBar.fillAmount = XTool.IsNumberValid(maxTurnCount) and curTurnCount / maxTurnCount or 1
    -- 进度线
    local lineIcon = self._Control:GetClientConfig(string.format("BattleRoundLine%d", maxTurnCount), 1)
    if self.RImgLine then
        self.RImgLine:SetRawImage(lineIcon)
    end
    -- 重置下一回合提示
    self:ResetNextTips()
end

-- 刷新人口（生产力）
function XUiRogueSimBattle:RefreshPopulation()
    local resourceId = XEnumConst.RogueSim.ResourceId.Population
    -- 拥有的生产力
    local ownPopulation = self._Control.ResourceSubControl:GetResourceOwnCount(resourceId)
    -- 剩余生产力
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    self.TxtPoint.text = string.format("%d/%d", remainingPopulation, ownPopulation)
    local icon = self._Control.ResourceSubControl:GetResourceIcon(resourceId)
    if icon then
        self.ImgMovePoint:SetSprite(icon)
    end
end

-- 刷新Buff
function XUiRogueSimBattle:RefreshBuff()
    local buffIds = self._Control.BuffSubControl:GetBattleInterfaceShowBuffs()
    self.PanelBuff.gameObject:SetActiveEx(not XTool.IsTableEmpty(buffIds))
    for index, id in pairs(buffIds) do
        local grid = self.GridBuffList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridBuff, self.GridBuff.transform.parent)
            grid = require("XUi/XUiRogueSim/Battle/XUiGridRogueSimBuff").New(go, self)
            self.GridBuffList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
    end
    for i = #buffIds + 1, #self.GridBuffList do
        self.GridBuffList[i]:Close()
    end
end

-- 刷新事件
function XUiRogueSimBattle:RefreshEvent()
    if not self.UiPanelEvent then
        ---@type XUiPanelRogueSimEvent
        self.UiPanelEvent = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimEvent").New(self.PanelEvent, self)
        self.UiPanelEvent:Open()
    end
    self.UiPanelEvent:Refresh()
end

-- 刷新按钮
function XUiRogueSimBattle:RefreshBtn()
    self:RefreshBuildBtn()
    self:RefreshEndBtn()
end

-- 刷新建筑按钮
function XUiRogueSimBattle:RefreshBuildBtn()
    -- 建筑按钮(有建筑数据时才显示)
    self.BtnBuild.gameObject:SetActiveEx(self._Control.MapSubControl:CheckHasBuildingData())
end

-- 刷新提前结算按钮
function XUiRogueSimBattle:RefreshEndBtn()
    -- 关卡三星条件达成时显示
    self.BtnEnd.gameObject:SetActiveEx(self._Control:CheckCurStageStarConditions())
end

-- 刷新建筑奖励
function XUiRogueSimBattle:RefreshBuildReward()
    if not self._Control.MapSubControl:CheckHasBuildingData() then
        return
    end
    local commodityIds = self._Control.ResourceSubControl:GetTemporaryBagCommodityIds()
    local rewardDropIdCount = self._Control.ResourceSubControl:GetTemporaryBagRewardDropIdCount()
    if XTool.IsTableEmpty(commodityIds) and rewardDropIdCount <= 0 then
        if self.BuildRewardUi and self.BuildRewardUi:IsNodeShow() then
            self.BuildRewardUi:OnBtnClose()
        end
        return
    end
    if not self.BuildRewardUi then
        ---@type XUiPanelRogueSimBuildReward
        self.BuildRewardUi = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimBuildReward").New(self.PanelReward, self)
    end
    self.BuildRewardUi:Open()
    self.BuildRewardUi:Refresh()
end

-- 刷新红点
function XUiRogueSimBattle:RefreshRedPoint()
end

-- 刷新三星目标
function XUiRogueSimBattle:RefreshTarget()
    local stageId = self._Control:GetCurStageId()
    local conditions = self._Control:GetRogueSimStageStarConditions(stageId)
    if #conditions == 0 then
        self.PanelTarget.gameObject:SetActiveEx(false)
        return
    end
    if not self.UiPanelTarget then
        ---@type XUiPanelRogueSimTarget
        self.UiPanelTarget = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimTarget").New(self.PanelTarget, self)
        self.UiPanelTarget:Open()
    end
    self.UiPanelTarget:Refresh()
end

-- 刷新传闻播报
---@field tipIds table<number>
function XUiRogueSimBattle:RefreshTips(tipIds)
    if XTool.IsTableEmpty(tipIds) then
        self.PanelNews.gameObject:SetActiveEx(false)
        return
    end
    self:StopTips()
    local time = self._Control:GetClientConfig("NewsShowTime")
    time = tonumber(time)
    self.TipTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopTips()
            return
        end
        self.PanelNews.gameObject:SetActiveEx(false)
        if XTool.IsTableEmpty(tipIds) then
            self:StopTips()
            return
        end
        local tipId = table.remove(tipIds, 1)
        if XTool.IsNumberValid(tipId) then
            self.PanelNews.gameObject:SetActiveEx(true)
            self.TxtNews.text = self._Control:GetTipContent(tipId)
            local icon = self._Control:GetTipIcon(tipId)
            if icon then
                self.RImgNews:SetRawImage(icon)
            end
        end
    end, time)
end

-- 刷新地图距离面板
function XUiRogueSimBattle:RefreshPanelMapDistance()
    if not self.UiPanelMapDistance then
        ---@type XUiPanelRogueSimMapDistance
        self.UiPanelMapDistance = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimMapDistance").New(self.PanelMapDistance, self)
    end
    self.UiPanelMapDistance:Open()
    self.UiPanelMapDistance:Refresh()
end

-- 停止传闻播报
function XUiRogueSimBattle:StopTips()
    if self.TipTimer then
        XScheduleManager.UnSchedule(self.TipTimer)
        self.TipTimer = nil
    end
end

-- 打开三星目标详情
function XUiRogueSimBattle:OpenTargetDetail()
    if not self.UiPanelTargetDetail then
        ---@type XUiPanelRogueSimTargetDetail
        self.UiPanelTargetDetail = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimTargetDetail").New(self.PanelTargetDetail, self)
    end
    self.UiPanelTargetDetail:Open()
    self.UiPanelTargetDetail:Refresh()
end

-- 过场
function XUiRogueSimBattle:OpenTransition()
    if not self.Transition then
        ---@type XUiPanelRogueSimTransition
        self.Transition = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimTransition").New(self.PanelTransition, self)
    end
    self.Transition:Open()
    self.Transition:Refresh()
end

---@param grid XRogueSimGrid
function XUiRogueSimBattle:OnGridClick(grid)
    if not grid then
        XLog.Error("error: grid is nil")
        return
    end
    local landType = grid:GetLandType()
    if landType == XEnumConst.RogueSim.LandformType.BuildingField then
        XLuaUiManager.Open("UiRogueSimPopupBuild", grid)
    elseif landType == XEnumConst.RogueSim.LandformType.Main or landType == XEnumConst.RogueSim.LandformType.City then
        XLuaUiManager.Open("UiRogueSimPopupCity", grid)
    else
        -- 是否可探索
        if not grid:GetCanExplore() then
            self:OpenLandBubble(grid)
            return
        end
        self:ExploreGridConfirm(grid)
    end
end

-- 探索格子二次确认探索
---@param grid XRogueSimGrid
function XUiRogueSimBattle:ExploreGridConfirm(grid, callback)
    -- 是否跳过二次确认
    local isSkipTips = self._Control:IsSkipCommodityFullTips()
    if isSkipTips then
        self:ExploreGrid(grid, callback)
        return
    end
    local isFull, commodityId = self._Control.ResourceSubControl:CheckCommodityIsFullByLandformId(grid:GetLandformId())
    if isFull then
        local title = self._Control:GetClientConfig("CommodityFullTitle", 1)
        local content = self._Control:GetClientConfig("CommodityFullContent", 1)
        local commodityName = self._Control.ResourceSubControl:GetCommodityName(commodityId)
        content = string.format(content, commodityName)
        self._Control:ShowCommonTip(title, content, nil, function()
            self:ExploreGrid(grid, callback)
        end, nil, function(isSkip)
            self._Control:SetSkipCommodityFullTips(isSkip)
        end, { IsShowSkip = true })
        return
    end
    self:ExploreGrid(grid, callback)
end

-- 探索格子
---@param grid XRogueSimGrid
function XUiRogueSimBattle:ExploreGrid(grid, callback)
    self._Control:RogueSimExploreGridRequest(grid:GetId(), function()
        self._Control:ClearGridSelectEffect()
        if callback then
            callback()
        end
    end)
end

-- 打开格子详情气泡
function XUiRogueSimBattle:OpenLandBubble(grid)
    if not self.LandBubble then
        local XUiPanelLandBubble = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimLandBubble")
        ---@type XUiPanelRogueSimLandBubble
        self.LandBubble = XUiPanelLandBubble.New(self.PanelLandBubble, self)
    end
    self.LandBubble:Open()
    self.LandBubble:Refresh(grid)
end

-- 打开任务完成弹框
function XUiRogueSimBattle:OpenTaskSuccess(id)
    if not self.TaskSuccess then
        ---@type XUiPanelRogueSimTaskSuccess
        self.TaskSuccess = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimTaskSuccess").New(self.PanelTaskSuccess, self)
    end
    self.TaskSuccess:Open()
    self.TaskSuccess:Refresh(id)
end

-- 打开城邦跳转弹框
function XUiRogueSimBattle:OpenCityJump()
    if self.PanelCityJumpUi and self.PanelCityJumpUi:IsNodeShow() then
        self.PanelCityJumpUi:OnBtnCloseClick()
        return
    end
    if not self.PanelCityJumpUi then
        ---@type XUiPanelRogueSimCityJump
        self.PanelCityJumpUi = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimCityJump").New(self.PanelCity, self)
    end
    self.PanelCityJumpUi:Open()
    self.PanelCityJumpUi:Refresh()
end

function XUiRogueSimBattle:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCity, self.OnBtnCityClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLog, self.OnBtnLogClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnEnd, self.OnBtnEndClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    self.InputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    self.InputHandler.IsMidButtonEventEnable = true
    self.InputHandler.GoType = CS.XGoType.Ui
end

function XUiRogueSimBattle:OnBtnBackClick()
    self._Control:OnExitScene()
    self:Close()
end

function XUiRogueSimBattle:OnBtnMainUiClick()
    self._Control:OnExitScene()
    XLuaUiManager.RunMain()
end

-- 建筑
function XUiRogueSimBattle:OnBtnBuildClick()
    XLuaUiManager.Open("UiRogueSimBuildBag")
end

-- 道具
function XUiRogueSimBattle:OnBtnPropClick()
    XLuaUiManager.Open("UiRogueSimPropBag")
end

-- 城邦
function XUiRogueSimBattle:OnBtnCityClick()
    self:OpenCityJump()
end

-- 点击日志按钮
function XUiRogueSimBattle:OnBtnLogClick()
    XLuaUiManager.Open("UiRogueSimLog")
end

-- 下一回合
function XUiRogueSimBattle:OnBtnNextClick()
    XLuaUiManager.Open("UiRogueSimPopupRoundEnd")
end

-- 提前结算
function XUiRogueSimBattle:OnBtnEndClick()
    if self._Control:CheckStageDataIsEmpty() then
        XLog.Error("error: stage data is empty")
        return
    end
    if not self._Control:CheckCurStageStarConditions() then
        XUiManager.TipMsg(self._Control:GetClientConfig("StageStarConditionTips"))
        return
    end
    local title = self._Control:GetClientConfig("BattleEarlySettlementTitle")
    local content = self._Control:GetClientConfig("BattleEarlySettlementContent")
    self._Control:ShowCommonTip(title, content, nil, function()
        self._Control:RogueSimStageSettleRequest(function()
            self:HandelEndClick()
        end)
    end)
end

-- 提前结算处理
function XUiRogueSimBattle:HandelEndClick()
    if self._Control:CheckStageSettleDataIsEmpty() then
        XLog.Error("error: stage settle data is empty")
        return
    end
    -- 显示结算
    XLuaUiManager.Open("UiRogueSimSettlement")
    -- 退出战斗
    self._Control:OnExitScene()
    self:Remove()
end

-- 开始下一季度提示的定时器
function XUiRogueSimBattle:StartNextTipsTimer()
    self.BtnNext:ShowReddot(false)
    self:ClearNextTipsTimer()
    self.NextTipsTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:ClearNextTipsTimer()
            return
        end
        self:CheckShowNextTips()
    end, 1000)
end

-- 清除定时器
function XUiRogueSimBattle:ClearNextTipsTimer()
    if self.NextTipsTimer then
        XScheduleManager.UnSchedule(self.NextTipsTimer)
        self.NextTipsTimer = nil
    end
end

-- 检测显示下一季度提示
function XUiRogueSimBattle:CheckShowNextTips()
    -- 弹窗界面关闭后重新计时弹窗
    if XLuaUiManager.GetTopUiName() ~= "UiRogueSimBattle" then
        self:ResetNextTips()
        return
    end
    -- 还有弹窗未播完，不触发提示
    local types = self._Control:GetHasDataPopupTypeList()
    if #types > 0 then
        self:ResetNextTips()
        return
    end
    -- 场景在播动画，不触发提示
    local isPlayAreaAnim = self._Control:IsPlayAreaAnim()
    if isPlayAreaAnim then
        self:ResetNextTips()
        return
    end
    -- 延迟过程中持续检测是否提示
    local isShowTips = self:IsShowBtnNextTips()
    local nowTime = XTime.GetServerNowTimestamp()
    if not isShowTips then
        self:ResetNextTips()
        return
    elseif not self.TipsTriggerTime then
        self.TipsTriggerTime = nowTime
        self.IsTipsShowed = false
        self.BtnNext:ShowReddot(false)
    end

    -- 已弹过提示
    if self.IsTipsShowed then return end

    -- 超过配置延迟时间，弹提示
    self.NextTipsDelayTime = self.NextTipsDelayTime or tonumber(self._Control:GetClientConfig("DelayOpenNextTipsTime"))
    if (nowTime - self.TipsTriggerTime) * 1000 > self.NextTipsDelayTime then
        self.IsTipsShowed = true
        self.BtnNext:ShowReddot(true)
    end
end

-- 重置下一回合的提示
function XUiRogueSimBattle:ResetNextTips()
    self.TipsTriggerTime = nil
    self.IsTipsShowed = false
    self.BtnNext:ShowReddot(false)
end

-- 是否显示无事可做的提示显示
function XUiRogueSimBattle:IsShowBtnNextTips()
    -- 检查关卡数据是否为空
    local isStageDataEmpty = self._Control:CheckStageDataIsEmpty()
    if isStageDataEmpty then
        return false
    end

    -- 城邦升级
    local cityCanLevelUpIds = self._Control.MapSubControl:GetCityCanLevelUpIds()
    local cityUpActive = not XTool.IsTableEmpty(cityCanLevelUpIds)
    if cityUpActive then
        return false
    end

    -- 可探索的内容
    local exploreGridIds = self._Control:GetCanExploreGridIds()
    local exploreActive = not XTool.IsTableEmpty(exploreGridIds)
    if exploreActive then
        return false
    end

    -- 可购买的区域
    local areaBuyGridIds = self._Control.MapSubControl:GetCanBuyAreaGridIds()
    local areaBuyActive = not XTool.IsTableEmpty(areaBuyGridIds)
    if areaBuyActive then
        return false
    end

    -- 可建造建筑
    local buildableGridIds = self._Control.MapSubControl:GetBuildableGridIds()
    local buildActive = not XTool.IsTableEmpty(buildableGridIds)
    if buildActive then
        return false
    end

    -- 事件投机
    local eventGambleIds = self._Control.MapSubControl:GetCanGetEventGambleIds()
    if #eventGambleIds > 0 then return false end
    -- 挂起事件
    local eventIds = self._Control.MapSubControl:GetPendingEventIds()
    if #eventIds > 0 then
        for _, eventId in ipairs(eventIds) do
            local canSelect = false -- 事件是否有选项可以选择
            local eventCfgId = self._Control.MapSubControl:GetEventConfigIdById(eventId)
            local optionIds = self._Control.MapSubControl:GetEventOptionIds(eventCfgId)
            for _, optionId in ipairs(optionIds) do
                local result, _ = self._Control.MapSubControl:CheckEventOptionCondition(optionId)
                canSelect = canSelect or result
            end
            if canSelect then return false end
        end
    end

    -- 主城可升级
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    if isCanLevelUp then
        return false
    end

    return true
end

function XUiRogueSimBattle:PlayBuildCommodityAnim(changeData)
    if XTool.IsTableEmpty(changeData) then
        return
    end
    local particleCountData = self:HandleParticleCountData(changeData)
    for id, count in pairs(particleCountData) do
        local effectData = self.Effect[id]
        if effectData then
            local emission = effectData.Particle.emission
            if emission.burstCount >= 1 then
                local burst = emission:GetBurst(0)
                burst.count = MinMaxCurve(count)
                emission:SetBurst(0, burst)
            end
            effectData.StartNode.gameObject:SetActiveEx(true)
            effectData.EndNode.gameObject:SetActiveEx(true)
            -- 播放音效
            self:SFXCollectActive(true)
        end
    end

    local particleDuration = tonumber(self._Control:GetClientConfig("TemporaryBagParticleDuration")) or 1000
    self:StopParticleEffectTimer()
    self.ParticleEffectTimer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopParticleEffectTimer()
            return
        end
        if self.AssetPanel then
            self.AssetPanel:RefreshCommodity()
        end
        for _, effectData in pairs(self.Effect) do
            effectData.StartNode.gameObject:SetActiveEx(false)
            effectData.EndNode.gameObject:SetActiveEx(false)
        end
        -- 停止音效
        self:SFXCollectActive(false)
    end, particleDuration)
end

function XUiRogueSimBattle:StopParticleEffectTimer()
    -- 清除定时器
    if self.ParticleEffectTimer then
        XScheduleManager.UnSchedule(self.ParticleEffectTimer)
        self.ParticleEffectTimer = nil
    end
end

-- 处理粒子数量数据
---@param changeData table<number, number> key: commodityId, value: count
function XUiRogueSimBattle:HandleParticleCountData(changeData)
    local particleCountData = {}
    local total = 0
    local totalLimit = tonumber(self._Control:GetClientConfig("TemporaryBagParticleTotalLimit"))

    for id, count in pairs(changeData) do
        local particleCount = self:GetParticleCountByConfig(id, count)
        particleCountData[id] = particleCount
        total = total + particleCount
    end

    if total > totalLimit then
        local ratio = totalLimit / total
        for id, count in pairs(particleCountData) do
            particleCountData[id] = math.floor(count * ratio)
        end
    end

    return particleCountData
end

-- 获取粒子数量通过配置
---@param id number 货物Id
---@param count number 货物数量
---@return number 粒子数量
function XUiRogueSimBattle:GetParticleCountByConfig(id, count)
    local intervals = self._Control:GetClientConfigParams(string.format("TemporaryBagParticleInterval%d", id))
    if XTool.IsTableEmpty(intervals) then
        return count
    end

    for _, interval in pairs(intervals) do
        local ranges = string.Split(interval, "|")
        if #ranges == 3 then
            local min, max, value = tonumber(ranges[1]), tonumber(ranges[2]), tonumber(ranges[3])
            if count >= min and (max == -1 or count < max) then
                return value
            end
        end
    end

    return count
end

function XUiRogueSimBattle:SFXCollectActive(isActive)
    if self.SFX_collectStart then
        self.SFX_collectStart.gameObject:SetActiveEx(isActive)
    end
    if self.SFX_collectEnd then
        self.SFX_collectEnd.gameObject:SetActiveEx(isActive)
    end
end

return XUiRogueSimBattle
