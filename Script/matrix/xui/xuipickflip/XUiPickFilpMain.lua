local XUiPickFlipRewardPanel = require("XUi/XUiPickFlip/XUiPickFlipRewardPanel")
local XUiPickFilpMain = XLuaUiManager.Register(XLuaUi, "UiPickFlipMain")

function XUiPickFilpMain:OnAwake()
    self.PickFlipManager = XDataCenter.PickFlipManager
    -- XPFRewardGroup
    self.RewardGroup = nil
    -- XPFRewardLayer
    self.RewardLayer = nil
    -- XUiPickFlipRewardPanel
    self.UiPickFlipRewardPanel = nil
    self:RegisterUiEvents()
end

-- groupId : 奖励组id
function XUiPickFilpMain:OnStart(groupId)
    self.RewardGroup = self.PickFlipManager.GetRewardGroup(groupId)
    -- 注册资源面板
    XUiHelper.NewPanelActivityAssetSafe(self.RewardGroup:GetAssetItemIds(), self.PanelAsset, self)
    -- 活动名称
    self.TxtName.text = self.RewardGroup:GetName()
    self:RefreshCurrentLayer()
    -- 商店名称
    self.BtnShop:SetNameByGroup(0, XUiHelper.GetText("PickFlipShopName"))
    -- 刷新结束时间和关闭
    self.TxtTime.text = self.RewardGroup:GetLeaveTimeStr()
    local endTime = self.RewardGroup:GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.PickFlipManager.HandleActivityEndTime()
            if self.RewardLayer:GetProgress() >= 1 
            and not self.RewardLayer:GetRewardIsReceived() then
                self.PickFlipManager.RequestFinishGroup(self.RewardGroup:GetId())
            end
        else
            self.TxtTime.text = self.RewardGroup:GetLeaveTimeStr()
        end
    end)
end

function XUiPickFilpMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshConfigStatus()
end

--######################## 私有方法 ########################

function XUiPickFilpMain:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnRule, self.OnBtnRuleClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnLayerReward, self.OnBtnLayerRewardClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnRewardConfig, self.OnBtnRewardConfigClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnRewardSee, self.OnBtnRewardSeeClicked) 
end

-- 奖池规则
function XUiPickFilpMain:OnBtnRuleClicked()
    self.RewardGroup:OpenRuleUi()
end

function XUiPickFilpMain:OnBtnShopClicked()
    self.RewardGroup:OpenShopUi()
end

-- 奖励层奖励领取
function XUiPickFilpMain:OnBtnLayerRewardClicked()
    if self.RewardLayer:GetProgress() >= 1 
        and not self.RewardLayer:GetRewardIsReceived() then
        self.PickFlipManager.RequestFinishGroup(self.RewardGroup:GetId(), function(needRefresh)
            if needRefresh then
                self:RefreshCurrentLayer()
                self.UiPickFlipRewardPanel:PlayAnimFinish2()
            else
                self:RewardLayerProgress()
            end            
            self:RefreshConfigStatus()
        end)
    else
        XUiManager.OpenUiTipRewardByRewardId(self.RewardLayer:GetFinishRewardId()
            , nil, nil, nil, XUiHelper.GetText("PickFlipRewardLayerTip"))
    end
end

-- 奖励配置
function XUiPickFilpMain:OnBtnRewardConfigClicked()
    RunAsyn(function ()
        XLuaUiManager.Open("UiPickFlipSelect", self.RewardLayer, XPickFlipConfigs.UiRewardDetailType.Config)
        local signalCode = XLuaUiManager.AwaitSignal("UiPickFlipSelect", "Close", self)
        if signalCode ~= XSignalCode.SUCCESS then
            return
        end
        self:RefreshConfigStatus()
        self:RefreshRewardContainer()
        if self.RewardLayer:GetIsConfigFinished() then
            self.UiPickFlipRewardPanel:PlayAnimFinish()
        end
    end)
end

-- 奖励查看
function XUiPickFilpMain:OnBtnRewardSeeClicked()
    XLuaUiManager.Open("UiGachaPanelPreview2", self.RewardLayer:GetRewardPreviewViewModel())
    -- XLuaUiManager.Open("UiPickFlipSelect", self.RewardLayer, XPickFlipConfigs.UiRewardDetailType.Check)
end

function XUiPickFilpMain:RefreshCurrentLayer()
    self.RewardLayer = self.RewardGroup:GetCurrentLayer()
    -- 刷新当前信息
    self:RefreshLayerInfo()
    -- 刷新奖励容器
    self:RefreshRewardContainer(true)
end

function XUiPickFilpMain:RefreshLayerInfo()
    -- 刷新当前奖励层数
    local isConfigFinished = self.RewardLayer:GetIsConfigFinished()
    local layerContent = XUiHelper.GetText("PickFlipLayerTip", self.RewardLayer:GetLayerIndex())
    self.TxtNormalLayer.text = layerContent
    self.TxtRewardLayer.text = layerContent
    self.PanelNormalStatus.gameObject:SetActiveEx(not isConfigFinished)
    self.PanelRewardStatus.gameObject:SetActiveEx(isConfigFinished)
    -- 消耗icon
    self.RImgConsumeIcon:SetRawImage(self.RewardLayer:GetConsumeIcon())
    -- 单次消耗的数量
    self.TxtComsumeCount.text = self.RewardLayer:GetConsumeCount()
    -- 层奖励图标
    self.RImgRewardIcon:SetRawImage(self.RewardLayer:GetRewardIcon())
    -- -- 大背景刷新
    -- self.RImgBg:SetRawImage(self.RewardGroup:GetBg())
    -- 刷新进度
    self:RewardLayerProgress()
end

function XUiPickFilpMain:RefreshConfigStatus()
    local isConfigFinished = self.RewardLayer:GetIsConfigFinished()
    self.BtnRewardConfig.gameObject:SetActiveEx(not isConfigFinished)
    self.BtnRewardSee.gameObject:SetActiveEx(isConfigFinished)
end

-- PS:经过三次优化，已去掉进度显示，但仍保留代码逻辑
function XUiPickFilpMain:RewardLayerProgress()
    local isReceived = self.RewardLayer:GetRewardIsReceived()
    local progress = self.RewardLayer:GetProgress()
    -- 奖励领取红点
    local isCanGet = progress >= 1 and not isReceived
    self.RewardRedPoint.gameObject:SetActiveEx(isCanGet)
    if self.Effect then self.Effect.gameObject:SetActiveEx(isCanGet) end
    -- 更新进度
    -- self.ImgProgress.fillAmount = progress
    self.PanelReceived.gameObject:SetActiveEx(isReceived)
end

-- 刷新奖励容器
function XUiPickFilpMain:RefreshRewardContainer(isInit)
    if isInit == false then isInit = false end
    if isInit then
        local contentAssetPath = self.RewardLayer:GetAssetPath()
        -- 创建新资源和代理
        local go = self.PanelRewardContainer:LoadPrefab(contentAssetPath)
        self.UiPickFlipRewardPanel = XUiPickFlipRewardPanel.New(go)
    end
    self.UiPickFlipRewardPanel:SetData(self.RewardLayer)
    if isInit then
        self:ConnectSignals("UiPickFlipRewardPanel/RewardGrids", "OnRewardGridClicked", self.OnRewardGridClicked)
    end
    if self.RewardLayer:GetIsConfigFinished() then
        self.RImgGridsBg.color = XUiHelper.Hexcolor2Color("FFFFFF")
    else
        self.RImgGridsBg.color = XUiHelper.Hexcolor2Color("5E5E5E")
    end
end

function XUiPickFilpMain:OnRewardGridClicked(index)
    -- 未配置完直接给提示
    if not self.RewardLayer:GetIsConfigFinished() then
        XUiManager.TipErrorWithKey("PickFlipNotConfigTip")
        -- self:OnBtnRewardConfigClicked()
        return
    end
    -- 已领取打开详情
    local reward = self.RewardLayer:GetRewardByIndex(index)
    if reward:GetIsReceived() then
        XUiManager.OpenGoodDetailUi(reward:GetShowItemId(), "UiPickFlipMain")
        return
    end
    -- 检查需要消耗的道具是否满足
    local consumeItemId = self.RewardLayer:GetConsumeItemId()
    local consumeCount = self.RewardLayer:GetConsumeCount()
    local itemManager = XDataCenter.ItemManager
    local currentCount = itemManager.GetCount(consumeItemId)
    if itemManager.GetCount(consumeItemId) < consumeCount then
        RunAsyn(function()
            XLuaUiManager.Open("UiLottoTanchuang2", self.RewardLayer:GetConsumeItemId(), {
                maxCountFunc = function()
                    return self.RewardLayer:GetCurrentConsumeLimitCount()
                end,
                maxCountTextFunc = function()
                    return XUiHelper.GetText("PickFlipLayerLimitBuyTip")
                end,
                consumeIcons = XPickFlipConfigs.GetConsumeSpecialIcons(),
                targetIcon = XPickFlipConfigs.GetTargetIcon(),
            })
            local signalCode, buyCount = XLuaUiManager.AwaitSignal("UiLottoTanchuang2", "BuySuccess", self)
            if signalCode ~= XSignalCode.SUCCESS then 
                return
            end
            self.RewardLayer:SetCurrentConsumeLimitCount(buyCount)
        end)
        return
    end
    -- 真正领取
    self.PickFlipManager.RequestFlipReward(self.RewardGroup:GetId(), index, function(reward)
        self.UiPickFlipRewardPanel:SetReward(index, reward)
        self:RewardLayerProgress()
        if self.RewardLayer:GetProgress() >= 1 then
            RunAsyn(function()
                local signalCode = XLuaUiManager.AwaitSignal("UiObtain", "Close", self)
                if signalCode ~= XSignalCode.SUCCESS then return end
                XUiManager.TipMsg(XUiHelper.GetText("PickFlipRewardLayerFinishedTip"))
                signalCode = XLuaUiManager.AwaitSignal("UiTipLayer", "_", self)
                if signalCode ~= XSignalCode.RELEASE then return end
                -- 自动领取层级奖励
                self:OnBtnLayerRewardClicked()
            end)
        end
    end)
end

return XUiPickFilpMain