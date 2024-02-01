---@class XUiRogueSimBattle : XLuaUi
---@field private _Control XRogueSimControl
---@field private AssetPanel XUiPanelRogueSimAsset
local XUiRogueSimBattle = XLuaUiManager.Register(XLuaUi, "UiRogueSimBattle")

function XUiRogueSimBattle:OnAwake()
    self:RegisterUiEvents()
    -- 默认隐藏红点
    self.BtnSell:ShowReddot(false)
    self.BtnProduce:ShowReddot(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimBuff[]
    self.GridBuffList = {}
end

function XUiRogueSimBattle:OnStart()
    -- 显示资源
    self.AssetPanel = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset").New(
        self.PanelAsset,
        self,
        XEnumConst.RogueSim.ResourceId.Gold,
        XEnumConst.RogueSim.CommodityIds,
        true)
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
    self:RefreshProduce()
    self:RefreshTurnNumber()
    self:RefreshActionPoint()
    self:RefreshBuff()
    self:RefreshEvent()
    self:RefreshBtn()
    self:RefreshRedPoint()
    self:RefreshTarget()

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
        XEventId.EVENT_ROGUE_SIM_ACTION_POINT_CHANGE,
        XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE,
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
        XEventId.EVENT_ROGUE_SIM_BUILDING_ADD,
        XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE,
        -- 只刷新红点
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUILDING_BUY,
    }
end

function XUiRogueSimBattle:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE then
        self:RefreshProduce()
    elseif event == XEventId.EVENT_ROGUE_SIM_ACTION_POINT_CHANGE then
        self:RefreshActionPoint()
    elseif event == XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE then
        self:RefreshTurnNumber()
    elseif event == XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE then
        self:RefreshBuff()
    elseif event == XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP then
        self:RefreshScienceBtn()
        self:RefreshScienceRedPoint()
    elseif event == XEventId.EVENT_ROGUE_SIM_BUILDING_ADD then
        self:RefreshBuildBtn()
        self:RefreshBuildRedPoint()
    elseif event == XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE then
        self:RefreshActionPoint()
    elseif event == XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE then
        self:RefreshBuildRedPoint()
    elseif event == XEventId.EVENT_ROGUE_SIM_BUILDING_BUY then
        self:RefreshBuildRedPoint()
    elseif event == XEventId.EVENT_GUIDE_START then
        self._Control:SaveGuideIsTriggerById(...)
    end
end

-- 刷新界面
function XUiRogueSimBattle:RefreshBtn()
    self:RefreshBuildBtn()
    self:RefreshScienceBtn()
end

-- 刷新建筑按钮
function XUiRogueSimBattle:RefreshBuildBtn()
    -- 建筑按钮(有建筑数据时才显示)
    self.BtnBuild.gameObject:SetActiveEx(self._Control.MapSubControl:CheckHasBuildingData())
end

-- 刷新科技树按钮
function XUiRogueSimBattle:RefreshScienceBtn()
    -- 科技按钮(科技等级为1级时才显示)
    self.BtnScience.gameObject:SetActiveEx(self._Control:GetCurTechLv() >= 1)
end

-- 刷新生产
function XUiRogueSimBattle:RefreshProduce()
    -- 生产图标
    local id = self._Control.ResourceSubControl:GetProductCommodityId()
    local isValid = XTool.IsNumberValid(id)
    self.PanelResource.gameObject:SetActiveEx(isValid)
    if isValid then
        self.RImgResource:SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(id))
    end
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
end

-- 刷新行动点
function XUiRogueSimBattle:RefreshActionPoint()
    local curPoint = self._Control:GetCurActionPoint()
    local limitPoint = self._Control:GetActionPointLimit()
    self.TxtPoint.text = string.format("%d/%d", curPoint, limitPoint)
    local actionPointId = XEnumConst.RogueSim.ResourceId.ActionPoint
    local icon = self._Control.ResourceSubControl:GetResourceIcon(actionPointId)
    self.ImgMovePoint:SetSprite(icon)
end

-- 刷新Buff
function XUiRogueSimBattle:RefreshBuff()
    local buffIds = self._Control.BuffSubControl:GetBattleInterfaceShowBuffs()
    self.PanelBuff.gameObject:SetActiveEx(not XTool.IsTableEmpty(buffIds))
    for index, id in pairs(buffIds) do
        local grid = self.GridBuffList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridBuff, self.PanelBuff)
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

-- 刷新红点
function XUiRogueSimBattle:RefreshRedPoint()
    self:RefreshBuildRedPoint()
    self:RefreshScienceRedPoint()
end

-- 刷新建筑红点
function XUiRogueSimBattle:RefreshBuildRedPoint()
    local isBuildShow = self._Control.MapSubControl:CheckUnBuyBuildingsRedPoint()
    self.BtnBuild:ShowReddot(isBuildShow)
end

-- 刷新科技红点
function XUiRogueSimBattle:RefreshScienceRedPoint()
    local isScienceShow = self._Control:CheckHasTechUnlockRedPoint()
    self.BtnScience:ShowReddot(isScienceShow)
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

-- 发现城邦
function XUiRogueSimBattle:OpenFindCity(id)
    if not self.FindCity then
        ---@type XUiPanelRogueSimFindCity
        self.FindCity = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimFindCity").New(self.PanelFindCity, self)
    end
    self.FindCity:Open()
    self.FindCity:Refresh(id)
end

-- 回合开始
function XUiRogueSimBattle:OpenRoundStart()
    local curTurnCount = self._Control:GetCurTurnNumber()
    -- 第一回合没有回合开始
    if curTurnCount == 1 then
        return
    end
    if not self.RoundStart then
        ---@type XUiPanelRogueSimRoundStart
        self.RoundStart = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimRoundStart").New(self.PanelRoundStart, self)
    end
    self.RoundStart:Open()
    self.RoundStart:Refresh()
end

-- 回合结算
function XUiRogueSimBattle:OpenRoundSettlement()
    if not self.RoundSettlement then
        ---@type XUiPanelRogueSimRoundSettlement
        self.RoundSettlement = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimRoundSettlement").New(self.PanelRoundSettlement, self)
    end
    self.RoundSettlement:Open()
    self.RoundSettlement:Refresh()
end

-- 打开格子详情气泡
function XUiRogueSimBattle:OpenLandBubble(grid)
    if not grid then
        XLog.Error("error: grid is nil")
        return
    end
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

-- 打开主城等级提升弹框
function XUiRogueSimBattle:OpenMainLevelUp(data)
    if not self.MainLevelUp then
        ---@type XUiPanelRogueSimMainLevelUp
        self.MainLevelUp = require("XUi/XUiRogueSim/Battle/XUiPanelRogueSimMainLevelUp").New(self.PanelLvUp, self)
    end
    self.MainLevelUp:Open()
    self.MainLevelUp:Refresh(data)
end

function XUiRogueSimBattle:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
    XUiHelper.RegisterClickEvent(self, self.BtnScience, self.OnBtnScienceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCity, self.OnBtnCityClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSell, self.OnBtnSellClick)
    XUiHelper.RegisterClickEvent(self, self.BtnProduce, self.OnBtnProduceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
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

-- 科技
function XUiRogueSimBattle:OnBtnScienceClick()
    XLuaUiManager.Open("UiRogueSimScience")
end

-- 城邦
function XUiRogueSimBattle:OnBtnCityClick()
    XLuaUiManager.Open("UiRogueSimCityBag")
end

-- 贸易
function XUiRogueSimBattle:OnBtnSellClick()
    XLuaUiManager.Open("UiRogueSimSell")
end

-- 生产
function XUiRogueSimBattle:OnBtnProduceClick()
    XLuaUiManager.Open("UiRogueSimProduce")
end

-- 下一回合
function XUiRogueSimBattle:OnBtnNextClick()
    if not self.RoundSettlement or not self.RoundSettlement:IsNodeShow() then
        self:OpenRoundSettlement()
    end
end

return XUiRogueSimBattle
