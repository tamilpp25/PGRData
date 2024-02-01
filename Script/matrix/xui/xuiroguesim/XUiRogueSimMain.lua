---@class XUiRogueSimMain : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimMain = XLuaUiManager.Register(XLuaUi, "UiRogueSimMain")
local MAX_REWARD_CNT = 3

function XUiRogueSimMain:OnAwake()
    self:RegisterUiEvents()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.RogueSimCoin }, self.PanelSpecialTool, self)
end

function XUiRogueSimMain:OnStart()
    self.EndTime = self._Control:GetActivityEndTime()
    self.GameEndTime = self._Control:GetActivityGameEndTime()
    self.IsGameTime = false
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)
end

function XUiRogueSimMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTime()
    self:RefreshBtnBattle()
    self:RefreshShopPreview()
    self:RefreshIllustrateAndStoryRed()
end

function XUiRogueSimMain:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRogueSimMain:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    -- 游戏时间
    local gameTime = self.GameEndTime - XTime.GetServerNowTimestamp()
    if gameTime > 0 then
        self.IsGameTime = true
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = string.format(self._Control:GetClientConfig("MainCountDownDesc"), timeStr)
    else
        if self.IsGameTime then
            self.IsGameTime = false
            self:RefreshBtnBattle()
        end
        -- 兑换时间
        local exchangeTime = self.EndTime - XTime.GetServerNowTimestamp()
        if exchangeTime < 0 then
            exchangeTime = 0
        end
        local timeStr = XUiHelper.GetTime(exchangeTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = string.format(self._Control:GetClientConfig("ExchangeCountDownDesc"), timeStr)
    end
end

function XUiRogueSimMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnBtnStartClick)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnBtnContinueClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRetreat, self.OnBtnRetreatClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHandBook, self.OnBtnHandBookClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStory, self.OnBtnStoryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiRogueSimMain:OnBtnBackClick()
    self:Close()
end

function XUiRogueSimMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 开始游戏，进入关卡选择界面
function XUiRogueSimMain:OnBtnStartClick()
    if self._Control:CheckStageDataIsEmpty() then
        XLuaUiManager.Open("UiRogueSimChapter")
    end
end

-- 继续游戏
function XUiRogueSimMain:OnBtnContinueClick()
    if not self._Control:CheckStageDataIsEmpty() then
        self._Control:EnterSceneFromMain()
    end
end

-- 放弃
function XUiRogueSimMain:OnBtnRetreatClick()
    self._Control:RogueSimStageSettleRequest(function()
        self:RefreshBtnBattle()
        XLuaUiManager.Open("UiRogueSimSettlement")
    end)
end

-- 图鉴
function XUiRogueSimMain:OnBtnHandBookClick()
    XLuaUiManager.Open("UiRogueSimHandbook")
end

-- 故事
function XUiRogueSimMain:OnBtnStoryClick()
    XLuaUiManager.Open("UiRogueSimStory")
end

-- 商店
function XUiRogueSimMain:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    local shopId = tonumber(self._Control:GetClientConfig("ShopId"))
    XShopManager.GetShopInfo(shopId, function()
        XLuaUiManager.Open("UiRogueSimShop", shopId)
    end)
end

-- 刷新战斗按钮
function XUiRogueSimMain:RefreshBtnBattle()
    local isEmpty = self._Control:CheckStageDataIsEmpty()
    self.BtnStart.gameObject:SetActiveEx(isEmpty and self.IsGameTime)
    self.BtnRetreat.gameObject:SetActiveEx(not isEmpty)
    self.BtnContinue.gameObject:SetActiveEx(not isEmpty)
end

-- 刷新商店预览
function XUiRogueSimMain:RefreshShopPreview()
    self.ShopRewards = self.ShopRewards or {}
    self.PanelReward.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.BtnShop:ShowReddot(false)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
        return
    end
    local shopId = XMVCA:GetAgency(ModuleId.XRogueSim):GetShopId()
    local previewShopGoodIds = self._Control:GetClientConfigParams("PreviewShopGoodIds")
    local previewIdDic = {}
    for _, goodId in ipairs(previewShopGoodIds) do
        previewIdDic[tonumber(goodId)] = true
    end
    XShopManager.GetShopInfo(shopId, function()
        local isShowRed = XMVCA:GetAgency(ModuleId.XRogueSim):IsShowShopRedPoint()
        self.BtnShop:ShowReddot(isShowRed)

        local shopGoods = XShopManager.GetShopGoodsList(shopId)
        local previewGoods = {}
        for _, good in ipairs(shopGoods) do
            local isPreview = previewIdDic[good.Id]
            local isSellOut = good.BuyTimesLimit > 0 and good.TotalBuyTimes >= good.BuyTimesLimit
            if isPreview and not isSellOut and #previewGoods < MAX_REWARD_CNT then
                table.insert(previewGoods, good)
            end
        end
        if #previewGoods > 0 then
            self.PanelReward.gameObject:SetActiveEx(true)
            XUiHelper.CreateTemplates(self, self.ShopRewards, previewGoods, XUiGridCommon.New, self.GridReward, self.PanelList, function(grid, data)
                grid:Refresh(data.RewardGoods, nil, true)
                XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
                    self:OnBtnShopClick()
                end)
            end)
        end
    end, true)
end

-- 图鉴和故事红点
function XUiRogueSimMain:RefreshIllustrateAndStoryRed()
    local illIds = self._Control:GetShowRedIllustrates()
    local isIllusRed = false
    local isStoryRed = false
    for _, illId in ipairs(illIds) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == XEnumConst.RogueSim.IllustrateType.Event then
            isStoryRed = true
        else
            isIllusRed = true
        end
    end
    self.BtnHandBook:ShowReddot(isIllusRed)
    self.BtnStory:ShowReddot(isStoryRed)
end

return XUiRogueSimMain
