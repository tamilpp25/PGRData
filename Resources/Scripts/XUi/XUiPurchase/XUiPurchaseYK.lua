local XUiPurchaseYK = XClass(nil, "XUiPurchaseYK")
local TextManager = CS.XTextManager
local PurchaseManager
local Next = _G.next
local XUiPurchaseYKListItem = require("XUi/XUiPurchase/XUiPurchaseYKListItem")
local XUiPurchaseLBTips = require("XUi/XUiPurchase/XUiPurchaseLBTips")
local XUiGridPurchaseYK = require("XUi/XUiPurchase/XUiGridPurchaseYK")
local BuyState = {
    CanBuy = 1,
    NotCanBuy = 2
}

local UiType =
{
    BgMonth = 2,
    BgWeek = 13,
    BgDay = 14,
}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local TotalCountLimit
local CountLimit

local CurrentSchedule = nil

function XUiPurchaseYK:Ctor(ui, uiroot)
    PurchaseManager = XDataCenter.PurchaseManager
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiroot
    self.TimeFuns = {}
    self.TimeSaveFuns = {}
    XTool.InitUiObject(self)
    self:Init()
    self:InitDynamic()
    --self.NeedUpdateId = {} -- 海外修改（表改为字段）
end

function XUiPurchaseYK:Init()
    self.BtnHelp.CallBack = function() self:OnBtnHelp() end
    self.BuyUITips = XUiPurchaseLBTips.New(self.PanelBuyTips,self.UiRoot, self)
    self.BuyCb = function() return self:BuyReq() end
    self.UpdateCb = function() self:OnUpdate() end
end

function XUiPurchaseYK:InitDynamic()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelYkExInfo)
    self.DynamicTable:SetProxy(XUiGridPurchaseYK)
    self.DynamicTable:SetDelegate(self)
end

--显示面板
function XUiPurchaseYK:ShowPanel()
    XEventManager.AddEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
    self.GameObject:SetActive(true)
end

--隐藏面板
function XUiPurchaseYK:HidePanel()
    self.CurState = false
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
    self.GameObject:SetActive(false)
end

--购买完成回调
function XUiPurchaseYK:OnUpdate()
    if self.CurUitype then
        self:OnRefresh(self.CurUitype)
    end
end

-- 更新数据
function XUiPurchaseYK:OnRefresh(uiType)
    local data = PurchaseManager.GetDatasByUiType(uiType)
    if not data or not data[1] then
        return
    end
    if uiType == XPurchaseConfigs.PurChaseCardUiType then
        XDataCenter.PurchaseManager.SetYKContinueBuy()
    end
    self.CurUitype = uiType
    self.Datas = data

    self.TxtBtnInfo.text = XPurchaseConfigs.GetPurchaseNameByUiType(self.CurUitype)

    self.DynamicTable:SetDataSource(self.Datas)
    self.DynamicTable:ReloadDataASync(1)
    self:StartLBTimer()
end

--动态列表事件
function XUiPurchaseYK:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetBuyClickCallBack(self.UiRoot, function(data)
                self:OnYKBuyClick(data)
            end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Datas[index]
        grid:Refresh(data, self.NeedUpdateId)
        self.NeedUpdateId = nil
    end
end

--帮助按钮点击
function XUiPurchaseYK:OnBtnHelp()
    if self.CurUitype == UiType.BgMonth then
        XUiManager.UiFubenDialogTip("", TextManager.GetText("PurchaseYKDes") or "")
    elseif self.CurUitype == UiType.BgWeek then
        XUiManager.UiFubenDialogTip("", TextManager.GetText("PurchaseYKDes13") or "")
    elseif self.CurUitype == UiType.BgDay then
        XUiManager.UiFubenDialogTip("", TextManager.GetText("PurchaseYKDes14") or "")
    end
end

--月卡子项点击购买回调
function XUiPurchaseYK:OnYKBuyClick(data)
    self.CurData = data
    self.BuyUITips:OnRefresh(data, self.BuyCb)
end

--确认购买按钮回调
function XUiPurchaseYK:BuyReq()
    if not XDataCenter.PayManager.CheckCanBuy(self.CurData.Id) then
        return false
    end
    if self.CurData.BuyLimitTimes > 0 and self.CurData.BuyTimes == self.CurData.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if self.CurData.TimeToShelve > 0 and self.CurData.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if self.CurData.TimeToUnShelve > 0 and self.CurData.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end
    self.NeedUpdateId = nil
    if self.CurData.PayKeySuffix then
        local key
        if Platform == RuntimePlatform.Android then
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.CurData.PayKeySuffix)
        else
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.CurData.PayKeySuffix)
        end
        self.BuyUITips:CloseTips()
        if self.CurData.BuyLimitTimes == 1 and self.CurData.UiType == UiType.BgDay then
            self.NeedUpdateId = self.CurData.Id
        end
        XDataCenter.PayManager.Pay(key, 1, { self.CurData.Id }, self.CurData.Id)
    else
        if self.CurData and self.CurData.Id then
            self.BuyUITips:CloseTips()
            XAppEventManager.HKPurchasePayAppLogEvent(self.CurData.Id) -- 月卡购买埋点
            PurchaseManager.PurchaseRequest(self.CurData.Id,self.UpdateCb)
        end
    end
    return true
end

function XUiPurchaseYK:StartLBTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = CS.XScheduleManager.Schedule(function() self:UpdateLBTimer() end, 1000, 0)
end

function XUiPurchaseYK:UpdateLBTimer()
    if Next(self.TimeFuns) then
        for _, timerfun in pairs(self.TimeFuns) do
            if timerfun then
                timerfun()
            end
        end
        return
    end
    self:DestoryTimer()
end

function XUiPurchaseYK:DestoryTimer()
    if CurrentSchedule then
        self.IsStart = false
        CS.XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end
end

function XUiPurchaseYK:RemoveTimerFun(id)
    self.TimeFuns[id] = nil
end

function XUiPurchaseYK:RecoverTimerFun(id)
    self.TimeFuns[id] = self.TimeSaveFuns[id]
    if self.TimeFuns[id] then
        self.TimeFuns[id](true)
    end
    self.TimeSaveFuns[id] = nil
end

function XUiPurchaseYK:RegisterTimerFun(id, fun, isSave)
    if not isSave then
        self.TimeFuns[id] = fun
        return
    end

    self.TimeSaveFuns[id] = self.TimeFuns[id]
    self.TimeFuns[id] = fun

end

return XUiPurchaseYK