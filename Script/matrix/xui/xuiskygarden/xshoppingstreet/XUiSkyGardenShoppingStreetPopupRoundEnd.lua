---@class XUiSkyGardenShoppingStreetPopupRoundEnd : XLuaUi
---@field GridFeedback UnityEngine.RectTransform
---@field PanelAsset UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field BtnDetail XUiComponent.XUiButton
---@field ListAsset UnityEngine.RectTransform
---@field ListBuild UnityEngine.RectTransform
---@field GridInsideBuild UnityEngine.RectTransform
---@field GridOutsideBuild UnityEngine.RectTransform
---@field TxtEventNum UnityEngine.UI.Text
---@field TxtConflictNum UnityEngine.UI.Text
---@field BubbleDetail1 UnityEngine.RectTransform
---@field BubbleDetail2 UnityEngine.RectTransform
---@field PanelDetail UnityEngine.RectTransform
---@field ListDetail UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetPopupRoundEnd = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupRoundEnd")

local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetPopupRoundEndGridShop = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetPopupRoundEndGridShop")
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridFeedback")
local XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupRoundEnd:OnStart()
    self:_RegisterButtonClicks()

    self._stageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    self:Switch2Detail(self._IsDetail)

    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelAsset, self)

    local settleData = self._Control:GetSettleResultData()
    local curTotal = settleData.CurrentSettleStatisticData
    local lastTotal = settleData.LastSettleStatisticData or {}

    local insidesList = {}
    local outsidesList = {}
    local allAreaShops = self._Control:GetAllShopAreas()
    for i = 1, #allAreaShops do
        local shopArea = allAreaShops[i]
        if shopArea:HasShop() then
            local isInside = shopArea:IsInside()
            if isInside then
                table.insert(insidesList, shopArea)
            else
                table.insert(outsidesList, shopArea)
            end
        end
    end

    self._InsidesList = {}
    self._OutsidesList = {}
    XTool.UpdateDynamicItem(self._InsidesList, insidesList, self.GridInsideBuild, XUiSkyGardenShoppingStreetPopupRoundEndGridShop, self)
    XTool.UpdateDynamicItem(self._OutsidesList, outsidesList, self.GridOutsideBuild, XUiSkyGardenShoppingStreetPopupRoundEndGridShop, self)

    self._SuggestionsUiA = {}
    self._SuggestionsUiB = {}
    local goodReview = {}
    local badReview = {}
    for i = 1, #settleData.Reviews do
        local reviewId = settleData.Reviews[i]
        local reviewCfg = self._Control:GetReviewConfigById(reviewId)
        if reviewCfg.Type == 1 then
            table.insert(goodReview, reviewId)
        else
            table.insert(badReview, reviewId)
        end
    end
    XTool.UpdateDynamicItem(self._SuggestionsUiA, goodReview, self.GridFeedbackGood, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)
    XTool.UpdateDynamicItem(self._SuggestionsUiB, badReview, self.GridFeedbackBad, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)

    if settleData.EventSettles then
        local eventMap = {}
        for _, StreetStageOperatingEventSettle in pairs(settleData.EventSettles) do
            eventMap[StreetStageOperatingEventSettle.EventType] = StreetStageOperatingEventSettle
        end
        local XSgStreetCustomerEventType = XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerEventType
        local eventData = eventMap[XSgStreetCustomerEventType.Discontent]
        if eventData then
            self.TxtEventNum.text = string.format("%s/%s", eventData.HandledCount, eventData.TotalCount)
        else
            self.TxtEventNum.text = "-/-"
        end

        eventData = eventMap[XSgStreetCustomerEventType.Emergency]
        if eventData then
            self.TxtConflictNum.text = string.format("%s/%s", eventData.HandledCount, eventData.TotalCount)
        else
            self.TxtConflictNum.text = "-/-"
        end
    else
        self.TxtEventNum.text = "-/-"
        self.TxtConflictNum.text = "-/-"
    end

    self.TxtDetail1.text = XMVCA.XBigWorldService:GetText("SG_SS_YesterdayTxtDetail1Tips")
    self.TxtDetail2.text = XMVCA.XBigWorldService:GetText("SG_SS_YesterdayTxtDetail2Tips")

    local resList = {}
    resList[self._stageResType.InitGold] = settleData.AwardGold
    resList[self._stageResType.InitFriendly] = (curTotal.Satisfaction or 0) - (lastTotal.Satisfaction or 0)
    -- local totalCustomerNum = 0
    -- if settleData.CustomerNums then
    --     for _, cNum in pairs(settleData.CustomerNums) do
    --         totalCustomerNum = totalCustomerNum + cNum
    --     end
    -- end
    -- resList[self._stageResType.InitCustomerNum] = totalCustomerNum
    -- resList[self._stageResType.InitEnvironment] = curTotal.Environment
    
    self:RefreshRes(resList)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:Switch2Detail(isDetail)
    self._IsDetail = isDetail
    self.PanelDetail.gameObject:SetActive(isDetail)
    self.ListBuild.gameObject:SetActive(not isDetail)

    if isDetail then
        if not self._DetailUi then
            self._DetailUi = {}
            local settleData = self._Control:GetSettleResultData()
            local curTotal = settleData.CurrentSettleStatisticData
            local lastTotal = settleData.LastSettleStatisticData or {}
            local curOtherSatisfactionNum = curTotal.Satisfaction - curTotal.EnvironmentSatisfaction - curTotal.ShopScoreSatisfaction
            local lastOtherSatisfactionNum = (lastTotal.Satisfaction or 0) - (lastTotal.EnvironmentSatisfaction or 0) - (lastTotal.ShopScoreSatisfaction or 0)
            local StageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
            self._DetailInfos = {
                {
                    {
                        ResId = StageResType.InitGold,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd1"),
                        Num = settleData.CommandAwardGold,
                    },
                    {
                        ResId = StageResType.InitGold,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd2"),
                        Num = settleData.DiscontentAwardGold,
                    },
                    {
                        ResId = StageResType.InitGold,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd3"),
                        Num = settleData.AwardGold - settleData.CommandAwardGold - settleData.DiscontentAwardGold,
                    },
                },
                {
                    {
                        ResId = StageResType.InitFriendly,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd4"),
                        Num = curTotal.EnvironmentSatisfaction - (lastTotal.EnvironmentSatisfaction or 0),
                    },
                    {
                        ResId = StageResType.InitFriendly,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd5"),
                        Num = curTotal.ShopScoreSatisfaction - (lastTotal.ShopScoreSatisfaction or 0),
                    },
                    {
                        ResId = StageResType.InitFriendly,
                        Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd6"),
                        Num = curOtherSatisfactionNum - lastOtherSatisfactionNum,
                    },
                }, {}, {}, }
        end
        
        XTool.UpdateDynamicItem(self._DetailUi, self._DetailInfos, self.ListDetail, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList, self)
    end
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:RefreshRes(resList)
    if not self._ComponentDic then
        self._ResIndex = {
            self._stageResType.InitGold,
            self._stageResType.InitFriendly,
            self._stageResType.InitCustomerNum,
            self._stageResType.InitEnvironment,
        }
        self._ComponentDic = {
            [self._stageResType.InitGold] = {
                self.TxtNumGridGold,
                self.ImgGoldAsset,
                true,
            },
            [self._stageResType.InitFriendly] = {
                self.TxtNumGridFavorability,
                self.ImgFavorabilityAsset,
                true,
            },
            [self._stageResType.InitCustomerNum] = {
                self.TxtNumGridPassenger,
                self.ImgPassengerAsset,
                false,
            },
            [self._stageResType.InitEnvironment] = {
                self.TxtNumGridEnvironmental,
                self.ImgEnvironmentalAsset,
                false,
            },
        }
    end

    local resCfgs = self._Control:GetStageResConfigs()
    for _, key in ipairs(self._ResIndex) do
        local value = self._ComponentDic[key]
        local resInfoNum = resList[key] or 0
        local cfg = resCfgs[key]
        -- value[1].color = XUiHelper.Hexcolor2Color(cfg.Color)
        local desc = self._Control:GetValueByResConfig(resInfoNum, cfg, true)
        value[1].text = desc
        value[2]:SetSprite(cfg.Icon)
        value[1].gameObject:SetActive(value[3])
        value[2].gameObject:SetActive(value[3])
    end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnCloseClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnYesClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnDetailClick()
    self:Switch2Detail(not self._IsDetail)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnPanelConflictClick()
    self.BubbleDetail1.gameObject:SetActive(true)
    XUiManager.CreateBlankArea2Close(self.BubbleDetail1.gameObject, function ()
        self.BubbleDetail1.gameObject:SetActive(false)
    end)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnPanelEventClick()
    self.BubbleDetail2.gameObject:SetActive(true)
    XUiManager.CreateBlankArea2Close(self.BubbleDetail2.gameObject, function ()
        self.BubbleDetail2.gameObject:SetActive(false)
    end)
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupRoundEnd:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnYes.CallBack = function() self:OnBtnYesClick() end
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
    self.PanelConflict.CallBack = function() self:OnPanelConflictClick() end
    self.PanelEvent.CallBack = function() self:OnPanelEventClick() end
end
--endregion

return XUiSkyGardenShoppingStreetPopupRoundEnd
