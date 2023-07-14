local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiBuyAsset = XLuaUiManager.Register(XLuaUi, "UiBuyAsset")

local WinType = {
    "Normal",
    "ShortCut"
}


function XUiBuyAsset:OnStart(id, successCallback, challengeCountData, buyAmount, isAutoClose)
    self.SuccessCallback = successCallback
    self.BuyAmount = buyAmount or 1
    self.IsAutoClose = isAutoClose
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
end

function XUiBuyAsset:OnEnable()
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
end
-- auto
function XUiBuyAsset:OnBtnShowTypeClick()
    self:Close()
    XLuaUiManager.Open("UiUsePackage", self.Id, self.SuccessCallback, self.ChallengeCountData, self.BuyAmount)
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

    if not XDataCenter.ItemManager.CheckItemCountById(self.Data.ConsumeId[self.curConsumeIdIndex], (self.Data.ConsumeCount[self.curConsumeIdIndex]*self.BuyAmount)) then
        local itemName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[self.curConsumeIdIndex])
        local text = CS.XTextManager.GetText('AssetsBuyConsumeNotEnough', itemName)
        
        local itemId = self.Data.ConsumeId[self.curConsumeIdIndex]
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
            -- 二次确认
            XUiManager.DialogDragTip(CSXTextManagerGetText("TipTitle") ,CsXTextManagerGetText("BuyAssetHKNotEnoughTips"), XUiManager.DialogType.Normal, function ()
                -- XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
            end, function ()
                local skipParams = XDataCenter.ItemManager.GetItemSkipIdParams(itemId)
                if skipParams then
                    XFunctionManager.SkipInterface(skipParams[1])
                end
            end)
        else
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        end
        return
    end

    local callback = function(targetId, targetCount)
        local name = XDataCenter.ItemManager.GetItemName(targetId)
        XUiManager.TipMsg(CS.XTextManager.GetText("Buy") .." ".. CS.XTextManager.GetText("Success") .. ", " .. targetCount .. " " .. name .." ".. CS.XTextManager.GetText("Acquire"), XUiManager.UiTipType.Tip) -- 海外修改
        self.BuyAmount = 1
        self:Refresh(targetId)
        if self.IsAutoClose or XItemConfigs.GetBuyAssetAutoClose(self.Id) ~= 0 then
            self:Close()
        end
        if self.SuccessCallback then
            self.SuccessCallback()
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_FAST_TRADING)
    end

    -- local failCallBack = function ()
    --     if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
    --         XFunctionManager.SkipInterface(50024)
    --     end
    -- end
    XDataCenter.ItemManager.BuyAsset(self.Data.TargetId, callback, nil, self.BuyAmount, self.Data.ConsumeId[self.curConsumeIdIndex])
end

function XUiBuyAsset:Refresh(targetId)
    self.Data = XDataCenter.ItemManager.GetBuyAssetInfo(targetId)

    local active = self.Data ~= nil
    self.PanelInfo.gameObject:SetActiveEx(active)
    self.PanelMax.gameObject:SetActiveEx(not active)
    self.BtnCancel.gameObject:SetActiveEx(true)
    self.BtnConfirm.gameObject:SetActiveEx(true)
    self.BtnPackageExchange.gameObject:SetActiveEx(self.Data.TargetId == XDataCenter.ItemManager.ItemId.ActionPoint) -- 海外修改，从JP1.17搬过来的
    self.BtnMoneyPackageExchange.gameObject:SetActiveEx(self.Data.TargetId == XDataCenter.ItemManager.ItemId.Coin)
    -- 当前状态
    local num = "?"
    if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.Coin then
        num = XDataCenter.ItemManager.GetCoinsNum()
    end
    if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.FreeGem or targetId == XDataCenter.ItemManager.ItemId.PaidGem then
        num = XDataCenter.ItemManager.GetTotalGemsNum()
    end
    if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.ActionPoint then
        num = XDataCenter.ItemManager.GetActionPointsNum() .. "/" .. XDataCenter.ItemManager.GetMaxActionPoints()
    end
    if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.SkillPoint then
        num = XDataCenter.ItemManager.GetSkillPointNum()
    end
    if num == "?" then
        local item = XDataCenter.ItemManager.GetItem(self.Data.ConsumeId[self.curConsumeIdIndex])
        num = item.Count
        --if item.Template.MaxCount > 0 then
            --num = num .. "/" .. item.Template.MaxCount
        --end
    end

    local curStateIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId[self.curConsumeIdIndex])
    local curStateName = CS.XTextManager.GetText("AtPresent")
    local curStateCount = num

    -- 消耗道具信息
    local consumeIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId[self.curConsumeIdIndex])
    local consumeName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[self.curConsumeIdIndex])
    local consumeCount = self.Data.ConsumeCount[self.curConsumeIdIndex] * (self.BuyAmount or 1)
    -- 获取道具信息
    local targetIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.TargetId)
    local targetName = XDataCenter.ItemManager.GetItemName(self.Data.TargetId)
    local targetCount = self.Data.TargetCount * (self.BuyAmount or 1)

    -- 修改Ui
    self.TxtCurStateName.text = curStateName
    self.TxtCurStateCount.text = curStateCount
    if curStateIcon ~= nil then
        self.RawImageCurState:SetRawImage(curStateIcon)
    end

    self.Time.gameObject:SetActiveEx(self.Data.LeftTimes ~= nil)
    self.TxtTimes.text = self.Data.LeftTimes == nil and "∞" or self.Data.LeftTimes

    self.TxtConsumeCount.text = consumeCount
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
    self:CheckBuyAmount()
    self.TxtSelect.text = tostring(self.BuyAmount)
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

    if self.WinType == WinType[1] then
        self.FurnitureBlueItem.gameObject:SetActiveEx(false)
        self:SetCanMutiply(false)
        self.BtnExchangeSource.gameObject:SetActiveEx(false)
    else
        self.TargetCount.gameObject:SetActiveEx(false)
        self.CurState.gameObject:SetActiveEx(false)

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
            local curentConsuleName = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId[nextConsumeIdIndex])
            self.BtnExchangeSource:SetName(curentConsuleName)
        end
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
    self.BuyAmount = self.BuyAmount + 1
    self:CheckBuyAmount()
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnBtnMinusSelectClick()
    self.BuyAmount = self.BuyAmount - 1
    if self.BuyAmount < 1 then
        self.BuyAmount = 1
    end
    self:Refresh(self.Id)
end

function XUiBuyAsset:OnSelectTextChange()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        return
    end

    if self.TxtSelect.text == "0" then
        self.TxtSelect.text = 1
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
end

function XUiBuyAsset:OnBtnMoneyPackageExchangeClicked()
    self:Close()
    XLuaUiManager.Open("UiUseCoinPackage")
end