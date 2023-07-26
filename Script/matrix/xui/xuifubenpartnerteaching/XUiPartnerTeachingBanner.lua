local XUiPartnerTeachingBanner = XLuaUiManager.Register(XLuaUi, "UiPartnerTeachingBanner")

local XUiGridPartnerTeachingBanner = require("XUi/XUiFubenPartnerTeaching/XUiGridPartnerTeachingBanner")
local CurrentSchedule

function XUiPartnerTeachingBanner:OnStart()
    self.TimerFunctions = {}

    self:InitComponent()
    self:AddListener()
end

function XUiPartnerTeachingBanner:OnEnable()
    self.DataSource = XDataCenter.PartnerTeachingManager.GetSortedChapterList()
    self.DynamicTable:SetDataSource(self.DataSource)
    self.DynamicTable:ReloadDataASync()
end

function XUiPartnerTeachingBanner:OnDestroy()
    self:DestroyTimer()
end

function XUiPartnerTeachingBanner:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin)

    self.GridPartnerTeachingBanner.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
    self:StartTimer()
end

function XUiPartnerTeachingBanner:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBannerList)
    self.DynamicTable:SetProxy(XUiGridPartnerTeachingBanner, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPartnerTeachingBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

-----------------------------------------------按钮响应函数---------------------------------------------------------------
function XUiPartnerTeachingBanner:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiPartnerTeachingBanner:OnBtnBackClick()
    self:Close()
end

function XUiPartnerTeachingBanner:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

---------------------------------------------------计时器----------------------------------------------------------------
function XUiPartnerTeachingBanner:StartTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, 1000)
end

function XUiPartnerTeachingBanner:UpdateTimer()
    if next(self.TimerFunctions) then
        for _, timerFun in pairs(self.TimerFunctions) do
            if timerFun then
                timerFun()
            end
        end
    end
end

function XUiPartnerTeachingBanner:RegisterTimerFun(id, fun)
    self.TimerFunctions[id] = fun
end

function XUiPartnerTeachingBanner:RemoveTimerFun(id)
    self.TimerFunctions[id] = nil
end

function XUiPartnerTeachingBanner:DestroyTimer()
    if CurrentSchedule then
        self.IsStart = false
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
        self.TimerFunctions = {}
    end
end
