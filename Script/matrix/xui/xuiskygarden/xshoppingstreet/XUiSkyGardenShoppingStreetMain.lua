local XUiSkyGardenShoppingStreetMainHistory = require("XUi/XUiSkyGarden/XShoppingStreet/XUiSkyGardenShoppingStreetMainHistory")

---@class XUiSkyGardenShoppingStreetMain : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field TxtName UnityEngine.UI.Text
---@field BtnStart XUiComponent.XUiButton
---@field BtnChallenge XUiComponent.XUiButton
---@field BtnHistory XUiComponent.XUiButton
---@field PanelHistory UnityEngine.RectTransform
---@field ListReward UnityEngine.RectTransform
---@field PanelMain UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetMain = XMVCA.XBigWorldUI:Register(nil,  "UiSkyGardenShoppingStreetMain")
local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

local XShoppingStreetMainPageType = {
    Main = 1,
    History = 2,
}

--region 生命周期
function XUiSkyGardenShoppingStreetMain:OnAwake()
    self.BtnChallenge.gameObject:SetActive(false)
    self._Rewards = {}

    ---@type XUiSkyGardenShoppingStreetMainHistory
    self.PanelHistoryUi = XUiSkyGardenShoppingStreetMainHistory.New(self.PanelHistory, self)
    self:_RegisterButtonClicks()
    self:ChangePage(XShoppingStreetMainPageType.Main)

    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Normal)
end

function XUiSkyGardenShoppingStreetMain:OnEnable()
    self._Control:X3CSetVirtualCameraByCameraIndex(1)
    self:RefreshPage()
end

function XUiSkyGardenShoppingStreetMain:OnGetLuaEvents()
    return { XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH }
end

function XUiSkyGardenShoppingStreetMain:OnNotify(event, ...)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH then
        self:RefreshPage()
    end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetMain:OnBtnCloseClick()
    -- if self.PageIndex == XShoppingStreetMainPageType.History then
    --     self:ChangePage(XShoppingStreetMainPageType.Main)
    -- else
    --     self:Close()
    -- end
end

function XUiSkyGardenShoppingStreetMain:OnBtnStartClick()
    local stageId = self._Control:GetCurrentStageId(true)
    local stageCfg = self._Control:GetStageConfigsByStageId(stageId)
    local conditionId = stageCfg.Condition
    if conditionId and conditionId ~= 0 then
        local result, desc = XMVCA.XBigWorldService:CheckCondition(stageCfg.Condition)
        if not result then
            XMVCA.XSkyGardenShoppingStreet:Toast(desc)
            return
        end
    end
    XMVCA.XSkyGardenShoppingStreet:StartStage(self._Control:GetCurrentStageId(true))
end

function XUiSkyGardenShoppingStreetMain:OnBtnChallengeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetAchieve")
end

function XUiSkyGardenShoppingStreetMain:OnBtnHistoryClick()
    self:ChangePage(XShoppingStreetMainPageType.History)
end

function XUiSkyGardenShoppingStreetMain:OnBtnReturnClick()
    self:ChangePage(XShoppingStreetMainPageType.Main)
end

function XUiSkyGardenShoppingStreetMain:OnBtnGiveupClick()
    self._Control:GiveupStage()
end

function XUiSkyGardenShoppingStreetMain:OnBtnLeaveClick()
    XMVCA.XSkyGardenShoppingStreet:ExitGameLevel()
end

--endregion

--region 共有方法
-- 切换页
function XUiSkyGardenShoppingStreetMain:ChangePage(pageIndex)
    if self.PageIndex ~= pageIndex then
        self.PageIndex = pageIndex
        self.PanelMain.gameObject:SetActive(pageIndex == XShoppingStreetMainPageType.Main)
        if pageIndex == XShoppingStreetMainPageType.History then
            self.PanelHistoryUi:Open()
        else
            self.PanelHistoryUi:Close()
        end
    end
    self:RefreshPage(pageIndex)
end

-- 刷新
function XUiSkyGardenShoppingStreetMain:RefreshPage(pageIndex)
    pageIndex = pageIndex or self.PageIndex
    if pageIndex == XShoppingStreetMainPageType.Main then
        self:RefreshMainPage()
    elseif pageIndex == XShoppingStreetMainPageType.History then
        XTool.UpdateDynamicItem(self._Rewards, nil, self.UiBigWorldItemGrid)
        self.PanelHistoryUi:Refresh()
    end
    local isRunningStage = self._Control:IsStageRunning()
    self.BtnGiveup.gameObject:SetActiveEx(isRunningStage)
end

function XUiSkyGardenShoppingStreetMain:RefreshMainPage()
    local isRunningStage = self._Control:IsStageRunning()
    local currentStageId = self._Control:GetCurrentStageId()
    local historyStageIdList = self._Control:GetPassedStageIds()
    local targetStageId = self._Control:GetTargetStageId()

    local isShowReward = false
    local isFinishStage = historyStageIdList ~= nil and table.contains(historyStageIdList, targetStageId)
    if isRunningStage then
        isShowReward = currentStageId == targetStageId
    else
        isShowReward = not isFinishStage
    end

    local key = not isRunningStage and "SG_SS_RunStart" or "SG_SS_RunContinue"
    self.TxtTitle.text = XMVCA.XBigWorldService:GetText(key)
    
    self.PanelNone.gameObject:SetActive(not isShowReward)
    if isShowReward then
        local stageId = self._Control:GetCurrentStageId(true)
        local config = self._Control:GetStageConfigsByStageId(stageId)
        self.TxtStageName.text = config.Name
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        XTool.UpdateDynamicItem(self._Rewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
    else
        self.TxtStageName.text = ""
        XTool.UpdateDynamicItem(self._Rewards, nil, self.UiBigWorldItemGrid)
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetMain:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end
    self.BtnHistory.CallBack = function() self:OnBtnHistoryClick() end
    self.BtnReturn.CallBack = function() self:OnBtnReturnClick() end
    self.BtnGiveup.CallBack = function() self:OnBtnGiveupClick() end
    self.BtnLeave.CallBack = function() self:OnBtnLeaveClick() end
end
--endregion

return XUiSkyGardenShoppingStreetMain
