local XUiPurchasePayAdd = XClass(nil, "XUiPurchasePayAdd")
local TextManager = CS.XTextManager
local XUiPurchasePayAddListItem = require("XUi/XUiPurchase/XUiPurchasePayAddListItem")

function XUiPurchasePayAdd:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.PurchaseCanGet = {}
    self.PurchaseGeted = {}
    self.PurchaseCanotGet = {}
    self.ListData = {}
    self.CurLookState = XSaveTool.GetData(XPurchaseConfigs.LjczLookStateKey) or CS.XGame.ClientConfig:GetInt(XPurchaseConfigs.PurchaseLJCZDefaultLookStateKey)
    XTool.InitUiObject(self)
    self:Init()
end

-- 更新数据
function XUiPurchasePayAdd:OnRefresh()
    local data = XDataCenter.PurchaseManager.GetAccumulatePayConfig()
    if not data then
        return
    end

    local beginTimeStr, endTimeStr = XDataCenter.PurchaseManager.GetAccumulatePayTimeStr()
    if beginTimeStr and endTimeStr then
        self.TxtLjczTime.text = beginTimeStr .. "--" .. endTimeStr
    else
        self.TxtLjczTime.text = ""
    end

    self.TxtPaynumber.text = XDataCenter.PurchaseManager.GetAccumulatedPayCount()

    self.CurPayIds = data.PayRewardId or {}
    self:SetListData()
    self:SetLookState(self.CurLookState)

    if XDataCenter.SetManager.RechargeType == XSetConfigs.RechargeEnum.Close then
        self.PanelLjcjValue.gameObject:SetActiveEx(false)
    else
        self.PanelLjcjValue.gameObject:SetActiveEx(true)
    end
end

function XUiPurchasePayAdd:SetListData()
    self.ListData = {}
    self.PurchaseCanGet = {}
    self.PurchaseGeted = {}
    self.PurchaseCanotGet = {}
    for _, id in pairs(self.CurPayIds) do
        local state = XDataCenter.PurchaseManager.PurchaseAddRewardState(id)
        if state == XPurchaseConfigs.PurchaseRewardAddState.CanGet then
            table.insert(self.PurchaseCanGet, id)
        elseif state == XPurchaseConfigs.PurchaseRewardAddState.Geted then
            table.insert(self.PurchaseGeted, id)
        elseif state == XPurchaseConfigs.PurchaseRewardAddState.CanotGet then
            table.insert(self.PurchaseCanotGet, id)
        end
    end

    for _, id in pairs(self.PurchaseCanGet) do
        table.insert(self.ListData, id)
    end

    for _, id in pairs(self.PurchaseCanotGet) do
        table.insert(self.ListData, id)
    end

    for _, id in pairs(self.PurchaseGeted) do
        table.insert(self.ListData, id)
    end
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPurchasePayAdd:Init()
    self:InitList()
    local closeFun = function() self.GameObject:SetActive(false) end
    self.BtnClose.CallBack = closeFun
    self.BtnLjczHelp.CallBack = function() self:OnBtnHelp() end
    self.BtnLjczLook.CallBack = function() self:OnBtnLook() end
    self.BtnCloseBg.CallBack = closeFun
end

function XUiPurchasePayAdd:OnBtnLook()
    if self.CurLookState == XPurchaseConfigs.LjczLookState.Show then
        self.CurLookState = XPurchaseConfigs.LjczLookState.Hide
    else
        self.CurLookState = XPurchaseConfigs.LjczLookState.Show
    end
    self:SetLookState(self.CurLookState)
end

function XUiPurchasePayAdd:SetLookState(state)
    local isShow = (state == XPurchaseConfigs.LjczLookState.Show)
    self.ImgLook.gameObject:SetActive(isShow)
    self.ImgUnlook.gameObject:SetActive(not isShow)
    local num = XDataCenter.PurchaseManager.GetAccumulatedPayCount()
    if isShow then
        self.TxtPaynumber.text = num
    else
        self.TxtPaynumber.text = TextManager.GetText("PurchaseAddHide")
    end

    XSaveTool.SaveData(XPurchaseConfigs.LjczLookStateKey, state)
end


function XUiPurchasePayAdd:OnBtnHelp()
    XUiManager.UiFubenDialogTip("", TextManager.GetText("PurchaseAddPayDes") or "")
end

function XUiPurchasePayAdd:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewardGroup)
    self.DynamicTable:SetProxy(XUiPurchasePayAddListItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiPurchasePayAdd:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
        -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end
return XUiPurchasePayAdd