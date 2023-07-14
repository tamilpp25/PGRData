local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiBuyAsset = XLuaUiManager.Register(XLuaUi, "UiBuyAsset")

local WinType = {
    "Normal",
    "ShortCut"
}
local MAX_COUNT = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")

--[[
    id : Share\Item\UiBuyAsset.tab的id
]]
function XUiBuyAsset:OnStart(id, successCallback, challengeCountData, buyAmount, isAutoClose)
    self.SuccessCallback = successCallback
    self.LackNum = buyAmount
    self.BuyAmount = buyAmount or 1
    self.IsAutoClose = isAutoClose
    -- 自定义数据处理
    if challengeCountData ~= nil then
        self:RefreshChallengeCount(challengeCountData)
        return
    end
    self.Id = id

    --判断界面的显示类型，根据Id
    local exchangeType = XItemConfigs.GetBuyAssetType(self.Id)
    self.WinType = WinType[exchangeType]

    --初始化数据
    self.curConsumeIdIndex = 1

    self:InitUiType()
    self:FreshCallBack(id)
    self:AutoAddListener()
    local cosumeId = self.Data.ConsumeId[self.curConsumeIdIndex]
    if cosumeId == 2 or cosumeId == 3 then
        self:ShowSpecialRegulationForJP() --日服特定商吸引法弹窗链接显示
    end

    -- -- 设置是否显示打折表现
    -- local discountShow = XItemConfigs.GetDiscountShow(id)
    -- self.PanelDiscount.gameObject:SetActiveEx(discountShow > 0)
    -- if discountShow > 0 then
    --     self.TxtDiscount.text = XUiHelper.GetText("BuyAssetDiscountText", discountShow)
    -- end
end

function XUiBuyAsset:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.PanelInfo:LoadPrefab(url)
            local data = {type = 1,consumeId = self.Data.ConsumeId[self.curConsumeIdIndex]}
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CSXTextManagerGetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(-172.6, -144.8, 0)
            self.ShowSpecialRegBtn.fontSize = 32
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiBuyAsset:OnEnable()
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnDestroy()

end

function XUiBuyAsset:AutoAddListener()
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnPackageExchange.CallBack = function()
        self:OnBtnShowTypeClick()
    end
    --添加 增加减少以及文本框内容改变事件
    self.BtnAddSelect.CallBack = function()
        self:OnBtnAddSelectClick()
    end
    self.BtnMinusSelect.CallBack = function()
        self:OnBtnMinusSelectClick()
    end
    self.TxtSelect.onValueChanged:AddListener(function()
        self:OnSelectTextChange()
    end)
    self.BtnMoneyPackageExchange.CallBack = function()
        self:OnBtnMoneyPackageExchangeClicked()
    end
    self.BtnMax.CallBack = function()
        self:OnBtnMaxClicked()
    end
    self.BtnSkip.CallBack = function()
        self:OnBtnSkipClick()
    end
end
-- auto
function XUiBuyAsset:OnBtnShowTypeClick()
    self:Close()
    XLuaUiManager.Open("UiUsePackage", self.Id, self.SuccessCallback, self.ChallengeCountData, self.BuyAmount)
end

function XUiBuyAsset:OnBtnSkipClick()
    local currentConsumeId = self.Data.ConsumeId[self.curConsumeIdIndex]
    XLuaUiManager.Open("UiSkip", currentConsumeId)
end

function XUiBuyAsset:OnBtnCloseClick()
    self:Close()
end

function XUiBuyAsset:FreshCallBack(id)
    XDataCenter.ItemManager.AddBuyTimesUpdateListener(id, function(targetId)
        if self.Data.LeftTimes == 0 then
            return
        end
        if targetId ~= self.Data.TargetId then
            return
        end
        self:Refresh(targetId)
    end, self.PanelInfo, self.gameObject)
end

function XUiBuyAsset:OnBtnCancelClick()
    self:Close()
end

function XUiBuyAsset:OnBtnConfirmClick()
    if self.ChallengeCountData ~= nil then
        self:OnBtnChallengeCountClick()
        return
    end

    if self.Data.LeftTimes == 0 then
        local itemName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[self.curConsumeIdIndex])
        local text = CS.XTextManager.GetText('BuyCountIsNotEnough', itemName)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        return
    end

    local item = XDataCenter.ItemManager.GetItem(self.Data.TargetId)
    -- 检查是否在限定购买时间内
    if not item:GetIsInBuyTime() then
        XUiManager.TipMsg(XUiHelper.GetText("BuyAssetTimeLimitTip"))
        return
    end
    -- 检查已购买数量是否超过最大购买数量
    if item:CheckIsOverTotalBuyTimes() then
        XUiManager.TipMsg(XUiHelper.GetText("BuyAssetTotalLimitTip"))
        return 
    end

    -- 检查数量
    if not XDataCenter.ItemManager.CheckItemCountById(self.Data.ConsumeId[self.curConsumeIdIndex], (self.Data.ConsumeCount[self.curConsumeIdIndex]*self.BuyAmount)) then
        local itemName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[self.curConsumeIdIndex])
        local text = CS.XTextManager.GetText('AssetsBuyConsumeNotEnough', itemName)
        
        local itemId = self.Data.ConsumeId[self.curConsumeIdIndex]
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem
            or itemId == XDataCenter.ItemManager.ItemId.HongKa then
            -- 二次确认
            XUiManager.DialogDragTip(CSXTextManagerGetText("TipTitle"), CsXTextManagerGetText("BuyAssetHKNotEnoughTips", itemName), XUiManager.DialogType.Normal, function ()
                -- XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
            end, function ()
                local skipParams = XDataCenter.ItemManager.GetItemSkipIdParams(itemId)
                if skipParams then
                    XFunctionManager.SkipInterface(skipParams[1])
                end
            end)
        else
            if self.SkipList and next(self.SkipList) then --如果有配置跳转 则跳转，没有配置再弹窗提示数量不足
                self:OnBtnSkipClick()
            else
                XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
            end
        end
        return
    end

    local callback = function(targetId, targetCount)
        local name = XDataCenter.ItemManager.GetItemName(targetId)
        XUiManager.TipMsg(CS.XTextManager.GetText("Buy") .." ".. CS.XTextManager.GetText("Success") .. ", " .. targetCount .. " " .. name .." ".. CS.XTextManager.GetText("Acquire"), XUiManager.UiTipType.Tip) -- 海外修改

        local lackNum = self.LackNum
        if self.LackNum then
            lackNum = lackNum - targetCount
        end

        self.BuyAmount = 1
        self.IsInitChanged = false
        self:Refresh(targetId)
        if self.IsAutoClose or XItemConfigs.GetBuyAssetAutoClose(self.Id) ~= 0 then
            self:Close()
        end
        if self.SuccessCallback then
            self.SuccessCallback()
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_FAST_TRADING, lackNum)
    end

    -- local failCallBack = function ()
    --     if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
    --         XFunctionManager.SkipInterface(50024)
    --     end
    -- end
    XDataCenter.ItemManager.BuyAsset(self.Data.TargetId, callback, nil, self.BuyAmount, self.Data.ConsumeId[self.curConsumeIdIndex])
end

function XUiBuyAsset:GetCurrentConsumeNum(itemData, targetId)
    local currentConsumeId = itemData.ConsumeId[self.curConsumeIdIndex]

    local num = "?"
    if targetId then
        if itemData.ConsumeId == XDataCenter.ItemManager.ItemId.Coin then
            num = XDataCenter.ItemManager.GetCoinsNum()
        end
        if itemData.ConsumeId == XDataCenter.ItemManager.ItemId.FreeGem or targetId == XDataCenter.ItemManager.ItemId.PaidGem then
            num = XDataCenter.ItemManager.GetTotalGemsNum()
        end
        if itemData.ConsumeId == XDataCenter.ItemManager.ItemId.ActionPoint then
            num = XDataCenter.ItemManager.GetActionPointsNum() .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
        end
        if itemData.ConsumeId == XDataCenter.ItemManager.ItemId.SkillPoint then
            num = XDataCenter.ItemManager.GetSkillPointNum()
        end
    end
    if num == "?" or not targetId then
        local item = XDataCenter.ItemManager.GetItem(currentConsumeId)
        num = item.Count
        --if item.Template.MaxCount > 0 then
            --num = num .. "/" .. item.Template.MaxCount
        --end
    end
    return num
end

function XUiBuyAsset:SetConsumeTextNum(hasCounsumCount, counsumeNum)
    self.ConsumeNumText = nil -- 判断用黑色的字还是用红色的字显示消费数量
    if self.WinType == WinType[1] then
        self.ConsumeNumText = self.TxtConsumeCount

        self.TxtConsumeCount.gameObject:SetActiveEx(true)
        self.TxtConsumeCountRed.gameObject:SetActiveEx(false)
    else
        if hasCounsumCount < counsumeNum then -- 消耗品不足支付
            self.ConsumeNumText = self.TxtConsumeCountRed

            self.TxtConsumeCount.gameObject:SetActiveEx(false)
            self.TxtConsumeCountRed.gameObject:SetActiveEx(true)
        else    -- 消耗品足够支付
            self.ConsumeNumText = self.TxtConsumeCount

            self.TxtConsumeCount.gameObject:SetActiveEx(true)
            self.TxtConsumeCountRed.gameObject:SetActiveEx(false)
        end
    end

    self.ConsumeNumText.text = counsumeNum
end

function XUiBuyAsset:Refresh(targetId)
    self.Data = XDataCenter.ItemManager.GetBuyAssetInfo(targetId)

    local currentConsumeId = self.Data.ConsumeId[self.curConsumeIdIndex]

    local active = self.Data ~= nil
    self.PanelInfo.gameObject:SetActiveEx(active)
    self.PanelMax.gameObject:SetActiveEx(not active)
    self.BtnConfirm.gameObject:SetActiveEx(true)
    self.BtnPackageExchange.gameObject:SetActiveEx(self.Data.TargetId == XDataCenter.ItemManager.ItemId.ActionPoint) -- 海外修改，从JP1.17搬过来的
    self.BtnMoneyPackageExchange.gameObject:SetActiveEx(self.Data.TargetId == XDataCenter.ItemManager.ItemId.Coin)
    -- 当前状态
    local num = self:GetCurrentConsumeNum(self.Data, targetId) --消耗品拥有数

    local curStateIcon = XDataCenter.ItemManager.GetItemIcon(currentConsumeId)
    local curStateName = CS.XTextManager.GetText("AtPresent")
    local curStateCount = num   

    -- 消耗道具信息
    local consumeIcon = XDataCenter.ItemManager.GetItemIcon(currentConsumeId)
    local consumeName = XDataCenter.ItemManager.GetItemName(currentConsumeId)
    local consumeCount = self.Data.ConsumeCount[self.curConsumeIdIndex] * (self.BuyAmount or 1)
    self:SetConsumeTextNum(num, consumeCount) --设置红色或黑色文本显示消费需要数量

    --动态显示跳转按钮
    self.SkipList = XDataCenter.ItemManager.GetItemSkipIdParams(currentConsumeId)
    if num < consumeCount and self.SkipList and next(self.SkipList) then
        self.BtnSkip.gameObject:SetActiveEx(true)
    else
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    -- 获取道具信息
    local targetIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.TargetId)
    local targetName = XDataCenter.ItemManager.GetItemName(self.Data.TargetId)
    local targetCount = self.Data.TargetCount * (self.BuyAmount or 1)
    local targetNum = XDataCenter.ItemManager.GetItem(targetId).Count --购买品拥有数

    -- 消耗品和购买品拥有数
    num = CS.XTextManager.GetText("UiBuyAssetHasNum", num)
    targetNum = CS.XTextManager.GetText("UiBuyAssetHasNum", targetNum)
    self.ConsumeTxtPossess.text = num
    self.TargetTxtPossess.text = targetNum

    -- 修改Ui
    self.TxtCurStateName.text = curStateName
    self.TxtCurStateCount.text = curStateCount
    if curStateIcon ~= nil then
        self.RawImageCurState:SetRawImage(curStateIcon)
    end

    self.Time.gameObject:SetActiveEx(self.Data.LeftTimes ~= nil)
    self.TxtTimes.text = self.Data.LeftTimes == nil and "∞" or self.Data.LeftTimes
    local totalLimit = XItemConfigs.GetBuyAssetTotalLimit(self.Data.TargetId)
    if totalLimit > 0 then
        self.TxtTimes.text = string.format( "%s(%s)"
        , self.TxtTimes.text, XUiHelper.GetText("BuyAssetTotalLimitText", totalLimit))
    end

    -- self.TxtConsumeCount.text = consumeCount
    self.TxtConsumeName.text = consumeName
    if consumeIcon ~= nil then
        self.RawImageConsume:SetRawImage(consumeIcon)
    end

    self.TxtTargetCount.text = targetCount
    self.TxtTargetName.text = targetName
    self.TargetText.text = targetName
    if targetIcon ~= nil then
        self.RawImageTarget:SetRawImage(targetIcon)
        self.TargetImg:SetRawImage(targetIcon)
    end
    self.TxtSelect.text = tostring(self.BuyAmount)
    -- 更新剩余兑换次数
    -- local currentConsumeCount = XDataCenter.ItemManager.GetCount(currentConsumeId)
    -- local currentConsumeNeedCountOnce = self.Data.ConsumeCount[self.curConsumeIdIndex]
    -- XLog.Warning(currentConsumeCount, currentConsumeNeedCountOnce)
    -- XLog.Warning(math.floor(currentConsumeCount / currentConsumeNeedCountOnce))
end

function XUiBuyAsset:RefreshChallengeCount(challengeCountData)
    self.ChallengeCountData = challengeCountData

    local active = self.ChallengeCountData.BuyCount < self.ChallengeCountData.BuyChallengeCount
    self.PanelInfo.gameObject:SetActiveEx(active)
    self.PanelMax.gameObject:SetActiveEx(not active)
    self.BtnCancel.gameObject:SetActiveEx(active)
    self.BtnConfirm.gameObject:SetActiveEx(active)

    local num = (self.ChallengeCountData.MaxChallengeNums - self.ChallengeCountData.PassTimesToday) .. " / " .. self.ChallengeCountData.MaxChallengeNums

    local curStateName = CS.XTextManager.GetText("CanChallegeCount")
    local curStateCount = "<color=#FA774FFF>" .. num .. "</color>"

    local consumeName = XDataCenter.ItemManager.GetItemName(XDataCenter.ItemManager.ItemId.FreeGem)
    local consumeCount = self.ChallengeCountData.BuyChallengeCost

    local targetCount = 1
    local targetName = CS.XTextManager.GetText("BuyChallegeDesc")

    self.TxtCurStateName.text = curStateName
    self.TxtCurStateCount.text = curStateCount
    self.TxtTimes.text = self.ChallengeCountData.BuyChallengeCount - self.ChallengeCountData.BuyCount
    self.TxtConsumeCount.text = consumeCount
    self.TxtConsumeName.text = consumeName
    self.TxtTargetCount.text = targetCount
    self.TxtTargetName.text = targetName
end

function XUiBuyAsset:OnBtnChallengeCountClick()
    if not XDataCenter.ItemManager.CheckItemCountById(XDataCenter.ItemManager.ItemId.FreeGem, self.ChallengeCountData.BuyChallengeCost) then
        local itemName = XDataCenter.ItemManager.GetItemName(XDataCenter.ItemManager.ItemId.FreeGem)
        local text = CS.XTextManager.GetText('AssetsBuyConsumeNotEnough', itemName)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        return
    end

    local callback = function()
        local name = CS.XTextManager.GetText("BuyChallegeDesc")
        XUiManager.TipMsg(CS.XTextManager.GetText("Buy") .. CS.XTextManager.GetText("Success") .. "," .. CS.XTextManager.GetText("Acquire") .. 1 .. name, XUiManager.UiTipType.Tip)
        if self.SuccessCallback then
            self.SuccessCallback()
        end
        local challengeCountData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.ChallengeCountData.StageId)
        self:RefreshChallengeCount(challengeCountData)
    end
    XDataCenter.FubenMainLineManager.BuyMainLineChallengeCount(callback, self.ChallengeCountData.StageId)
end

--是否显示或隐藏加减按钮
function XUiBuyAsset:SetCanMutiply(val)
    self.BtnAddSelect.gameObject:SetActive(val)
    self.BtnMinusSelect.gameObject:SetActive(val)
    self.TxtSelect.gameObject:SetActive(val)
end

--根据WinType初始化Ui类型
function XUiBuyAsset:InitUiType()
    self.Data = XDataCenter.ItemManager.GetBuyAssetInfo(self.Id)

    local currentConsumeId = self.Data.ConsumeId[self.curConsumeIdIndex]
    local skipList = XDataCenter.ItemManager.GetItemSkipIdParams(currentConsumeId)
    if self.WinType == WinType[1] then
        self.FurnitureBlueItem.gameObject:SetActiveEx(false)
        self:SetCanMutiply(false)
        self.BtnExchangeSource.gameObject:SetActiveEx(false)

        --隐藏新ui内容
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.BtnMax.gameObject:SetActiveEx(false)
        self.TargetImgPossess.gameObject:SetActiveEx(false)
        self.ConsumeImgPossess.gameObject:SetActiveEx(false)
        self.TxtConsumeCountRed.gameObject:SetActiveEx(false)

        self.BtnCancel.gameObject:SetActiveEx(true)
    else
        self.TxtTargetCount.gameObject:SetActiveEx(false)
        self.CurState.gameObject:SetActiveEx(false)
        self.TargetTxtCountSmall.gameObject:SetActiveEx(false)

        --修改标题
        self.PanelTitle.text = CS.XTextManager.GetText("BuyAssetPanelTitle")

        --显示或隐藏多选
        local canMutiply = XItemConfigs.GetBuyAssetCanMutiply(self.Id)
        if canMutiply == nil or canMutiply == 0 or canMutiply == 1 then
            self:SetCanMutiply(false)
        else
            self:SetCanMutiply(true)
        end

        --显示或隐藏兑换转换按钮
        if #self.Data.ConsumeId <= 1 then
            self.BtnExchangeSource.gameObject:SetActiveEx(false)
        else
            self.BtnExchangeSource.gameObject:SetActiveEx(true)
            self.BtnExchangeSource.CallBack = function()
                self:BtnChangeSourceClick()
            end
            local nextConsumeIdIndex = self.curConsumeIdIndex + 1
            if nextConsumeIdIndex > #self.Data.ConsumeId then
                nextConsumeIdIndex = 1
            end
            -- 设置切换兑换物品的名称
            local curentConsuleName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[nextConsumeIdIndex])
            self.BtnExchangeSource:SetName(curentConsuleName)
        end

        self.BtnCancel.gameObject:SetActiveEx(false)
    end
end

--兑换转换按钮点击
function XUiBuyAsset:BtnChangeSourceClick()
    local currentConsuleName

    self.curConsumeIdIndex = self.curConsumeIdIndex + 1
    if self.curConsumeIdIndex > #self.Data.ConsumeId then
        self.curConsumeIdIndex = 1
    end

    local nextConsumeIdIndex = self.curConsumeIdIndex + 1
    if nextConsumeIdIndex > #self.Data.ConsumeId then
        nextConsumeIdIndex = 1
    end

    currentConsuleName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[nextConsumeIdIndex])
    self.BtnExchangeSource:SetName(currentConsuleName)
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnBtnAddSelectClick()
    if not self:CheckCanBuyForMaxLimit() then
        return
    end

    self.BuyAmount = self.BuyAmount + 1
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnBtnMinusSelectClick()
    self.BuyAmount = self.BuyAmount - 1
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnBtnMaxClicked()
    if not self:CheckCanBuyForMaxLimit() then
        return
    end

    self.Data = XDataCenter.ItemManager.GetBuyAssetInfo(self.Id)
    local num = self:GetCurrentConsumeNum(self.Data, self.Id) --消耗品拥有数
    local consumeCountOnce = self.Data.ConsumeCount[self.curConsumeIdIndex]
    local res = math.floor(num/consumeCountOnce)
    res = XDataCenter.EquipManager.GetMaxCountOfBoxOverLimit(self.Id, res, 1)

    self.BuyAmount = res
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnSelectTextChange()
    if not self.IsInitChanged then -- 防止初始化重复调用
        self.IsInitChanged = true
        return
    end

    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        return
    end

    if self.TxtSelect.text == "0" then
        self.TxtSelect.text = 1
    end

    if self.WinType ~= WinType[1] then
        local maxCount = XDataCenter.EquipManager.GetMaxCountOfBoxOverLimit(self.Id, MAX_COUNT, 1)
        local tmp = tonumber(self.TxtSelect.text)
        if maxCount < tmp then
            self.TxtSelect.text = maxCount
        end
    end

    self.BuyAmount = tonumber(self.TxtSelect.text)
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

--监测输入框最大数字
function XUiBuyAsset:CheckBuyAmount()
    if self.Data.LeftTimes ~= nil and self.BuyAmount > self.Data.LeftTimes then
        if self.Data.LeftTimes == 0 then
            self.BuyAmount = 1
        else
            self.BuyAmount = self.Data.LeftTimes
        end
    end

    if self.WinType ~= WinType[1] then
        if self.BuyAmount > MAX_COUNT then
            self.BuyAmount = MAX_COUNT
        elseif self.BuyAmount < 1 then
            self.BuyAmount = 1
        end
    end
end

--检测是否容量已满不能购买
function XUiBuyAsset:CheckCanBuyForMaxLimit()
    local maxCount = XDataCenter.EquipManager.GetMaxCountOfBoxOverLimit(self.Id, MAX_COUNT, 1)
    if maxCount <= self.BuyAmount and XDataCenter.EquipManager.ShowBoxOverLimitText() then
        return false
    end
    
    return true
end

function XUiBuyAsset:OnBtnMoneyPackageExchangeClicked()
    self:Close()
    XLuaUiManager.Open("UiUseCoinPackage", {
        Id = self.Id,
        SuccessCallback = self.SuccessCallback,
        ChallengeCountData = self.ChallengeCountData,
        BuyAmount = self.BuyAmount,
        IsAutoClose = self.IsAutoClose,
    })
end