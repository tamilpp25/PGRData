local XUiPurchaseLBTips = XClass(nil ,"XUiPurchaseLBTips")
local TextManager = CS.XTextManager
local PurchaseManager
local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")
local XUiPurchaseSignTip = require("XUi/XUiPurchase/XUiPurchaseSignTip/XUiPurchaseSignTip")
local RestTypeConfig
local LBGetTypeConfig
local Next = _G.next
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiPurchaseLBTips:Ctor(ui,uiroot,parent)
    PurchaseManager = XDataCenter.PurchaseManager
    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
    self.CurState = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiroot
    self.TitleGoPool = {}
    self.ItemPool = {}
    self.PurchaseSignTipDic = {}    -- 签到礼包的奖励预览脚本实例，key:PrefabPath，value:{ PurchaseSignTip, Resource }
    self.Parent = parent
    XTool.InitUiObject(self)
    self:Init()
end

-- 更新数据
function XUiPurchaseLBTips:OnRefresh(data,cb)
    if not data then
        return
    end
    CS.XAudioManager.PlaySound(1100)
    local closeFun = function() self:CloseTips() end
    if data.SignInId and data.SignInId ~= 0 then
        -- 签到礼包展示预览
        self.PanelCommon.gameObject:SetActiveEx(false)
        self.PanelSignGiftPack.gameObject:SetActiveEx(true)

        self.BtnSignGiftPackBgClose.CallBack = closeFun
        self.BtnSignGiftPackClose.CallBack = closeFun
        for _, v in pairs(self.PurchaseSignTipDic) do
            v.PurchaseSignTip.GameObject:SetActiveEx(false)
        end

        self.CurPrefabPath = XSignInConfigs.GetSignPrefabPath(data.SignInId)
        local purchaseSignTip = (self.PurchaseSignTipDic[self.CurPrefabPath] or {}).PurchaseSignTip
        if not purchaseSignTip then
            -- 生成对应prefab的实例
            local resource = CS.XResourceManager.Load(self.CurPrefabPath)
            local go = CS.UnityEngine.Object.Instantiate(resource.Asset)
            go.transform:SetParent(self.SignGiftPackNode, false)
            go.gameObject:SetLayerRecursively(self.SignGiftPackNode.gameObject.layer)
            purchaseSignTip = XUiPurchaseSignTip.New(go, self, self.UiRoot)

            local info = {}
            info.PurchaseSignTip = purchaseSignTip
            info.Resource = resource
            self.PurchaseSignTipDic[self.CurPrefabPath] = info
        end

        purchaseSignTip:Refresh(data, cb)
        purchaseSignTip.GameObject:SetActiveEx(true)
    else
        -- 通用展示预览
        self.PanelCommon.gameObject:SetActiveEx(true)
        self.PanelSignGiftPack.gameObject:SetActiveEx(false)
        self.RetimeSec = 0
        self.UpdateTimerType = nil
        local curtime = XTime.GetServerNowTimestamp()
        self.BtnBuy.CallBack  = cb
        self.BtnBgClick.CallBack = closeFun
        self.BtnCloseBg.CallBack = closeFun
        self.Data = data
        
        -- 直接获得的道具
        self.ListDirData = {}
        self.ListDayData = {}
        local rewards0 = data.RewardGoodsList or {}
        for _,v in pairs(rewards0) do
            v.LBGetType = LBGetTypeConfig.Direct
            table.insert(self.ListDirData,v)
        end
        -- 每日获得的道具
        local rewards1 = data.DailyRewardGoodsList or {}
        for _,v in pairs(rewards1) do
            v.LBGetType = LBGetTypeConfig.Day
            table.insert(self.ListDayData,v)
        end
        local isUseMail = self.Data.IsUseMail or false
        self.TxtContinue.gameObject:SetActive(isUseMail)
        self:SetList()

        if data.TimeToInvalid and data.TimeToInvalid > 0 then
            self.RetimeSec = data.TimeToInvalid - curtime
            self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
            if self.RetimeSec > 0 then--大于0，注册。
                self.TXtTime.gameObject:SetActive(true)
                self.Parent:RegisterTimerFun(data.Id,function()self:UpdataTimer()end,true)
                self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RetimeSec))
            else
                self.TXtTime.gameObject:SetActive(false)
                self.Parent:RemoveTimerFun(data.Id)
            end
        else
            if (data.TimeToShelve == nil or data.TimeToShelve == 0) and (data.TimeToUnShelve == nil or data.TimeToUnShelve == 0) then
                self.TXtTime.gameObject:SetActive(false)
            else
                self.TXtTime.gameObject:SetActive(true)
                if data.TimeToUnShelve > 0 then
                    self.RetimeSec = data.TimeToUnShelve - curtime
                    self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                    self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RetimeSec))
                else
                    self.RetimeSec = data.TimeToShelve-curtime
                    self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
                    self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RetimeSec))
               end
                if self.RetimeSec > 0 then--大于0，注册。
                    self.Parent:RegisterTimerFun(data.Id,function()self:UpdataTimer()end,true)
                else
                    self.Parent:RemoveTimerFun(data.Id)
                end
            end
        end

        self.TxtName.text = data.Name
        local assetpath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
        if assetpath and assetpath.AssetPath then
           self.RawImageIcon:SetRawImage(assetpath.AssetPath)
        end
        self:SetBuyDes()

        if self.Data.UiType == XPurchaseConfigs.YKType.Month or self.Data.UiType == XPurchaseConfigs.YKType.Week or self.Data.UiType == XPurchaseConfigs.YKType.Day then
            self.TxtLimitBuy.gameObject:SetActiveEx(false)
        end

        if data.PayKeySuffix then
            local key
            if Platform == RuntimePlatform.Android then
                key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), data.PayKeySuffix)
            else
                key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), data.PayKeySuffix)
            end

            local payConfig = XPayConfigs.GetPayTemplate(key)
            self.RawImageConsume.gameObject:SetActive(true)
            local path = CS.XGame.ClientConfig:GetString("PurchaseBuyRiYuanIconPath")
            self.RawImageConsume:SetRawImage(path)
            self.BtnBuy:SetName(payConfig.Amount)
        else
            if data.ConsumeCount == 0 then
                self.RawImageConsume.gameObject:SetActive(false)
                self.BtnBuy:SetName(TextManager.GetText("PurchaseFreeText"))
            else
                self.RawImageConsume.gameObject:SetActive(true)
                self.BtnBuy:SetName(data.ConsumeCount)
                local icon = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
                if icon then
                    self.RawImageConsume:SetRawImage(icon)
                end
            end
        end

        if (data.BuyLimitTimes > 0 and data.BuyTimes == data.BuyLimitTimes) or (data.TimeToShelve > 0 and data.TimeToShelve <= curtime) or (data.TimeToUnShelve > 0 and data.TimeToUnShelve <= curtime) then --卖完了，不管。
            self.TXtTime.text = ""
            if self.UpdateTimerType then
                self.Parent:RemoveTimerFun(self.Data.Id)
            end
            self.BtnBuy:SetButtonState(XUiButtonState.Disable)
        else
            self.BtnBuy:SetButtonState(XUiButtonState.Normal)
        end
    end
    self.GameObject:SetActive(true)
    self.UiRoot:PlayAnimation("BuyTipsEnable")
end

-- 更新倒计时
function XUiPurchaseLBTips:UpdataTimer()
    self.RetimeSec = self.RetimeSec - 1

    if self.RetimeSec <= 0 then
        self.Parent:RemoveTimerFun(self.Data.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            self.TXtTime.text = TextManager.GetText("PurchaseLBSettOff")
            return
        end

        self.TXtTime.text  = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RetimeSec))
        return
    end

    self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RetimeSec))
end

function XUiPurchaseLBTips:Init()
    self.AssetPanel = XUiPanelAsset.New(self,self.PanelAssetPay,XDataCenter.ItemManager.ItemId.FreeGem,XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiPurchaseLBTips:CloseTips()
    for _,v in pairs(self.ItemPool) do
        v.Transform:SetParent(self.PoolGo)
        v.GameObject:SetActive(false)
    end

    for _,v in pairs(self.TitleGoPool) do
        v:SetParent(self.PoolGo)
        v.gameObject:SetActive(false)
    end
    
    if self.UpdateTimerType then
        self.Parent:RemoveTimerFun(self.Data.Id)
        self.Parent:RecoverTimerFun(self.Data.Id)
    end
    self.GameObject:SetActive(false)
end

function XUiPurchaseLBTips:SetList()
    local index1 = 1
    local index2 = 1

    if Next(self.ListDirData) ~= nil then
        local obj = self:GetTitlGo(index1)
        index1 = index1 + 1
        obj.transform:Find("TxtTitle"):GetComponent("Text").text =  TextManager.GetText("PurchaseDirGet")
        for _,v in pairs(self.ListDirData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end

    if Next(self.ListDayData) ~= nil then
        local obj = self:GetTitlGo(index1)
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = self.Data.Desc or ""
        for _,v in pairs(self.ListDayData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end
end

function XUiPurchaseLBTips:GetTitlGo(index)
    if self.TitleGoPool[index] then
        self.TitleGoPool[index].gameObject:SetActive(true)
        self.TitleGoPool[index]:SetParent(self.PanelReward)
        return self.TitleGoPool[index]
    end

    local obj = CS.UnityEngine.Object.Instantiate(self.ImgTitle,self.PanelReward)
    obj.gameObject:SetActive(true)
    obj:SetParent(self.PanelReward)
    table.insert(self.TitleGoPool, obj)
    return obj
end

function XUiPurchaseLBTips:GetItemObj(index)
    if self.ItemPool[index] then
        self.ItemPool[index].GameObject:SetActive(true)      
        self.ItemPool[index].Transform:SetParent(self.PanelReward)  
        return self.ItemPool[index]
    end

    local itemobj = CS.UnityEngine.Object.Instantiate(self.PanelPropItem,self.PanelReward)
    itemobj.gameObject:SetActive(true)
    itemobj:SetParent(self.PanelReward)
    local item = XUiPurchaseLBTipsListItem.New(itemobj)
    item:Init(self.UiRoot)
    table.insert(self.ItemPool, item)
    return item
end

-- [监听动态列表事件]
function XUiPurchaseLBTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self,self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiPurchaseLBTips:SetBuyDes()
    if self.Data.UiType == XPurchaseConfigs.YKType.Month or self.Data.UiType == XPurchaseConfigs.YKType.Week or self.Data.UiType == XPurchaseConfigs.YKType.Day then
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
    end
    local clientResetInfo = self.Data.ClientResetInfo or {}
    if Next(clientResetInfo) == nil then
        self.TxtLimitBuy.text = ""
        return 
    end

    local textKey = nil
    if clientResetInfo.ResetType == RestTypeConfig.Interval then
        self.TxtLimitBuy.text = TextManager.GetText("PurchaseRestTypeInterval",clientResetInfo.DayCount,self.Data.BuyTimes,self.Data.BuyLimitTimes)
        return
    elseif clientResetInfo.ResetType == RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end

    if not textKey then
        self.TxtLimitBuy.text = ""
        return
    end
    self.TxtLimitBuy.text = TextManager.GetText(textKey,self.Data.BuyTimes,self.Data.BuyLimitTimes)

    if self.Data.UiType == XPurchaseConfigs.YKType.Month or self.Data.UiType == XPurchaseConfigs.YKType.Week or self.Data.UiType == XPurchaseConfigs.YKType.Day then
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
    end
end

return XUiPurchaseLBTips