local XUiSignFirstRecharge = XClass(nil, "XUiSignFirstRecharge")

function XUiSignFirstRecharge:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitAddListen()

    self.SmallGrids = {}
    self.BigGrids = {}
end

function XUiSignFirstRecharge:OnHide()
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
end

function XUiSignFirstRecharge:OnShow()
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
end

function XUiSignFirstRecharge:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiSignFirstRecharge:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiSignFirstRecharge:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiSignFirstRecharge:InitAddListen()
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnAlreadyGet, self.OnBtnAlreadyGetClick)
end

function XUiSignFirstRecharge:OnBtnSkipClick()
    XLuaUiManager.Open("UiPurchase", 1, nil, nil) -- 海外修改（跳转到充值界面）
    XDataCenter.AutoWindowManager.StopAutoWindow()
end

function XUiSignFirstRecharge:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", self.Config.Description or "")
end

function XUiSignFirstRecharge:OnBtnAlreadyGetClick()
    XUiManager.TipText("ChallengeRewardIsGetted")
end

function XUiSignFirstRecharge:OnBtnGetClick()
    XDataCenter.PayManager.GetFirstPayRewardReq(function()
        self.BtnGet.gameObject:SetActive(false)
        self.BtnAlreadyGet.gameObject:SetActive(true)
    end)
end

function XUiSignFirstRecharge:Refresh(configId)
    if not configId then
        configId = self.ConfigId
    end
    self.ConfigId = configId

    self.Config = XSignInConfigs.GetFirstRechargeConfig(configId)

    if XDataCenter.PayManager.GetFirstRecharge() then
        self.BtnSkip.gameObject:SetActive(false)

        local isGet = XDataCenter.PayManager.GetFirstRechargeReward()
        self.BtnGet.gameObject:SetActive(not isGet)
        self.BtnAlreadyGet.gameObject:SetActive(isGet)
    else
        self.BtnSkip.gameObject:SetActive(true)
        self.BtnGet.gameObject:SetActive(false)
        self.BtnAlreadyGet.gameObject:SetActive(false)
    end

    self.GridCommon.gameObject:SetActive(false)
    local smallRewardItems = XRewardManager.GetRewardList(XPayConfigs.GetSmallRewards())
    local bigRewardItems = XRewardManager.GetRewardList(XPayConfigs.GetBigRewards())

    for _, v in ipairs(self.SmallGrids) do
        v.GameObject:SetActive(false)
    end

    for _, v in ipairs(self.BigGrids) do
        v.GameObject:SetActive(false)
    end

    -- 大奖要放到前面
    for i = 1, #bigRewardItems do
        self:SetRewardInfo(bigRewardItems, i, true)
    end

    for i = 1, #smallRewardItems do
        self:SetRewardInfo(smallRewardItems, i)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiSignFirstRecharge:SetRewardInfo(rewardItems, i, isBig)
    local ui
    if isBig then
        ui = self.BigGrids[i]
    else
        ui = self.SmallGrids[i]
    end

    if not ui then
        local grid = CS.UnityEngine.Object.Instantiate(self.GridCommon)
        grid.transform:SetParent(self.PnanelGrid, false)
        local bigReward = XUiHelper.TryGetComponent(grid, "ImgBigReward", "Image")
        bigReward.gameObject:SetActive(isBig)
        ui = XUiGridCommon.New(self.RootUi, grid)

        if isBig then
            table.insert(self.BigGrids, ui)
        else
            table.insert(self.SmallGrids, ui)
        end
    end

    ui:Refresh(rewardItems[i])
end

return XUiSignFirstRecharge