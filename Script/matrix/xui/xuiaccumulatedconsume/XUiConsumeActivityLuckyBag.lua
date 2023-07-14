--- 福袋抽卡
local XUiConsumeActivityLuckyBag = XLuaUiManager.Register(XLuaUi, "UiConsumeActivityLuckyBag")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGridConsumeRewardItem = require("XUi/XUiAccumulatedConsume/XUiGridConsumeRewardItem")
local IndexDropDetail = 1
local defaultAnimationName = "Stand1"
local drawAnimationName = "UIKnock"
local IsDrawing = false

function XUiConsumeActivityLuckyBag:OnAwake()
    self:RegisterUiEvents()
    self:InitSceneRoot()
end

function XUiConsumeActivityLuckyBag:OnStart()
    ---@type ConsumeDrawActivityEntity
    self.ConsumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()
    
    self.ItemId = self.ConsumeDrawActivity:GetDrawCardCoinItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ self.ItemId }, self.PanelSpecialTool)
    
    self:InitRewardList()
    self:InitView()

    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self.ItemId, self.RefreshSurplusCount, self)

    -- 开启自动关闭检查
    local endTime = self.ConsumeDrawActivity:GetLuckyEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        self.IsEnd = isClose
        if isClose and not IsDrawing then
            XDataCenter.AccumulatedConsumeManager.HandleActivityEndTime()
        end
    end)
end

function XUiConsumeActivityLuckyBag:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshModel()
    -- 刷新抽奖进度
    self:RefreshRewardFillAmount()
end

function XUiConsumeActivityLuckyBag:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self.ItemId, self.RefreshSurplusCount, self)
end

function XUiConsumeActivityLuckyBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOpenOne, self.OnBtnOpenOne)
    XUiHelper.RegisterClickEvent(self, self.BtnOpenSurplus, self.OnBtnOpenSurplus)
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchange)
    XUiHelper.RegisterClickEvent(self, self.PaenlBtTips, self.OnBtnPanelTips)
end

function XUiConsumeActivityLuckyBag:OnBtnBackClick()
    self:Close()
end

function XUiConsumeActivityLuckyBag:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 开启一次
function XUiConsumeActivityLuckyBag:OnBtnOpenOne()
    -- 单次开启需要消耗代币的个数
    local coinCost = self.ConsumeDrawActivity:GetCoinCost()
    self:DrawReward(coinCost, 1)
end

-- 开启剩余
function XUiConsumeActivityLuckyBag:OnBtnOpenSurplus()
    -- 单次开启需要消耗代币的个数
    local coinCost = self.ConsumeDrawActivity:GetCoinCost()
    -- X次开启需要消耗代币的个数
    local surplusCount = self.ConsumeDrawActivity:GetMaxDrawCount()
    local surplusCost = surplusCount * coinCost
    self:DrawReward(surplusCost, surplusCount)
end

-- 打开兑换界面
function XUiConsumeActivityLuckyBag:OpenExchangePenal()
    if XLuaUiManager.IsUiShow("UiLottoTanchuang2") then 
        return 
    end
    XLuaUiManager.Open("UiLottoTanchuang2", self.ConsumeDrawActivity:GetAssetItemId(), {
        consumeIcons = XAccumulatedConsumeConfig.GetConsumeSpecialIcons(),
        targetIcon = XAccumulatedConsumeConfig.GetTargetIcon(),
        supportInput = true,
    })
end

-- 福袋兑换
function XUiConsumeActivityLuckyBag:OnBtnExchange()
    self:OpenExchangePenal()
end

-- 规则说明
function XUiConsumeActivityLuckyBag:OnBtnPanelTips()
    XLuaUiManager.Open("UiConsumeActivityLog", IndexDropDetail)
end

function XUiConsumeActivityLuckyBag:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelModel = root:FindTransform("PanelModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true, false, true)
end

function XUiConsumeActivityLuckyBag:RefreshModel()
    local modelId = self.ConsumeDrawActivity:GetModelId()
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateRoleModel(modelId, self.PanelModel, XModelManager.MODEL_UINAME.XUiConsumeActivityLuckyBag, function(model)
        CS.XShadowHelper.AddShadow(model)
    end, false, false, false, true)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiConsumeActivityLuckyBag:InitView()
    -- 活动时间
    self.TxtTime.text = self.ConsumeDrawActivity:GetActivityTime()
    -- 奖励描述
    self.TxtRewardDesc.text = XUiHelper.ConvertLineBreakSymbol(self.ConsumeDrawActivity:GetRewardDescription())
    -- 单次开启需要消耗代币的个数
    local coinCost = self.ConsumeDrawActivity:GetCoinCost()
    self.BtnOpenOne:SetName(coinCost)
    -- X次开启需要消耗代币的个数
    local surplusCount = self.ConsumeDrawActivity:GetMaxDrawCount()
    local surplusCost = surplusCount * coinCost
    self.BtnOpenSurplus:SetName(surplusCost)
    -- 代币图标
    local coinIcon = XEntityHelper.GetItemIcon(self.ItemId) 
    self.BtnOpenOne:SetRawImage(coinIcon)
    self.BtnOpenSurplus:SetRawImage(coinIcon)
end

function XUiConsumeActivityLuckyBag:InitRewardList()
    self.ProgressIds = self.ConsumeDrawActivity:GetRewardProgressId()
    self.RewardGrids = {}

    local progressNum = #self.ProgressIds
    for i = progressNum, 1, -1 do
        local go = i == progressNum and self.PanelActive or XUiHelper.Instantiate(self.PanelActive, self.PanelGift)
        local grid = XUiGridConsumeRewardItem.New(self, go, self.ProgressIds[i])
        self.RewardGrids[self.ProgressIds[i]] = grid
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiConsumeActivityLuckyBag:RefreshRewardFillAmount()
    local drawNum = XDataCenter.AccumulatedConsumeManager.GetDrawCumulativeNum()
    local progressRequiredInfo = self.ConsumeDrawActivity:GetRewardProgressRequired()
    local maxProgressRequired = progressRequiredInfo[#progressRequiredInfo]
    local cycleIndex, progress = math.modf(drawNum / maxProgressRequired)
    
    self.ImgDaylyActiveProgress.fillAmount = progress
    -- 浮点数计算有误差，这里使用整数计算
    local count = drawNum - cycleIndex * maxProgressRequired
    for _, grid in pairs(self.RewardGrids) do
        grid:Refresh(count)
    end
end

function XUiConsumeActivityLuckyBag:RefreshSurplusCount()
    -- 单次开启需要消耗代币的个数
    local coinCost = self.ConsumeDrawActivity:GetCoinCost()
    -- X次开启需要消耗代币的个数
    local surplusCount = self.ConsumeDrawActivity:GetMaxDrawCount()
    local surplusCost = surplusCount * coinCost
    self.BtnOpenSurplus:SetName(surplusCost)
end

function XUiConsumeActivityLuckyBag:DrawReward(coinCost, count)
    if XEntityHelper.CheckItemCountIsEnough(self.ItemId, coinCost, false) then
        -- 满足抽卡 播放本次抽卡动画
        XLuaUiManager.SetMask(true)
        IsDrawing = true
        XDataCenter.AccumulatedConsumeManager.ConsumeDrawDoDrawRequest(count, handler(self, self.ShowRewardList))
    else
        --不满足 弹窗显示黑卡与新代币的快捷兑换界面
        self:OpenExchangePenal()
    end
end

function XUiConsumeActivityLuckyBag:ShowRewardList(dropRewardList, progressRewardList)
    if XTool.IsTableEmpty(dropRewardList) and XTool.IsTableEmpty(progressRewardList) then
        XLuaUiManager.SetMask(false)
        IsDrawing = false
        if self.IsEnd then
            XDataCenter.AccumulatedConsumeManager.HandleActivityEndTime()
        end
        return
    end
    
    local asynPlayAnima = asynTask(function(animaName, cb)
        -- 播放特效
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        -- 播放动画
        self.RoleModelPanel:PlayAnima(animaName, true, cb, cb)
    end)
    
    local asynDrawResult = asynTask(function(rewardList, cb)
        XLuaUiManager.Open("UiGachaOrganizeDrawResult", rewardList, function()
            if cb then
                cb()
            end
        end)
    end)
    RunAsyn(function()
        -- 抽奖奖励
        if not XTool.IsTableEmpty(dropRewardList) then
            asynPlayAnima(drawAnimationName)
            
            XLuaUiManager.SetMask(false)
            
            local rewards = XRewardManager.MergeAndSortRewardGoodsList(dropRewardList)
            asynDrawResult(rewards)
            
            self.RoleModelPanel:PlayAnima(defaultAnimationName, true)
        end
        -- 更新累计次数
        self:RefreshRewardFillAmount()
        IsDrawing = false
        -- 累计奖励
        if not XTool.IsTableEmpty(progressRewardList) then
            XUiManager.OpenUiObtain(progressRewardList)
            local signalCode = XLuaUiManager.AwaitSignal("UiObtain", "Close", self)
            if signalCode ~= XSignalCode.SUCCESS then return end
        end
        if self.IsEnd then
            XDataCenter.AccumulatedConsumeManager.HandleActivityEndTime()
        end
    end)
end

return XUiConsumeActivityLuckyBag