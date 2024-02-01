local XUiConsumeActivityMain = XLuaUiManager.Register(XLuaUi, "UiConsumeActivityMain")
local XUiGridConsumeActivityTaskItem = require("XUi/XUiAccumulatedConsume/XUiGridConsumeActivityTaskItem")
local XUiGridConsumeActivityCoatTask = require("XUi/XUiAccumulatedConsume/XUiGridConsumeActivityCoatTask")

function XUiConsumeActivityMain:OnAwake()
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self.PanelBigList.gameObject:SetActiveEx(false)
end

function XUiConsumeActivityMain:OnStart()
    ---@type ConsumeDrawActivityEntity
    self.ConsumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()

    local itemId = self.ConsumeDrawActivity:GetShopCoinItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)

    self:InitView()
    self:InitTabBtnGroup()
end

function XUiConsumeActivityMain:OnEnable()
    self:StartTime()
    self:SetupDynamicTable()
    self:UpdateCoat()
end

function XUiConsumeActivityMain:OnGetEvents()
    return { 
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiConsumeActivityMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:SetupDynamicTable()
        self:UpdateCoat()
    end
end

function XUiConsumeActivityMain:OnDisable()
    self:StopTimer()
end

function XUiConsumeActivityMain:InitTabBtnGroup()
    self.BtnTong.gameObject:SetActiveEx(false)
    local groupNames = self.ConsumeDrawActivity:GetTaskGroupName()
    local groupId = self.ConsumeDrawActivity:GetTaskGroupId()
    local tabGroup = {}
    for index, name in pairs(groupNames or {}) do
        local go = XUiHelper.Instantiate(self.BtnTong, self.BtnTab.transform)
        local btn = go:GetComponent("XUiButton")
        btn:SetName(name)
        tabGroup[index] = btn
        XRedPointManager.AddRedPointEvent(btn, function(_, count)
            btn:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.CONDITION_CONSUME_ACTIVITY_REWARD }, groupId[index])
        btn.gameObject:SetActiveEx(true)
    end
    self.BtnTab:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
    self.BtnTab:SelectIndex(1)
end

function XUiConsumeActivityMain:OnClickTabCallBack(tabIndex)
    if self.CurrentSelect and self.CurrentSelect == tabIndex then
        return
    end
    self.CurrentSelect = tabIndex
    self:PlayAnimation("QieHuan")
    self:SetupDynamicTable()
end

--region DynamicTable
function XUiConsumeActivityMain:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridConsumeActivityTaskItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiConsumeActivityMain:SetupDynamicTable()
    self.DynamicTableDataList = self.ConsumeDrawActivity:GetActivityTaskData(self.CurrentSelect)
    self.PanelEmpty.gameObject:SetActive(#self.DynamicTableDataList <= 0)
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiConsumeActivityMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList[index])
    end
end
--endregion

function XUiConsumeActivityMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTransportationReport, self.OnBtnTransportationReport)
    XUiHelper.RegisterClickEvent(self, self.BtnTefuBusiness, self.OnBtnTefuBusiness)
    self:BindHelpBtn(self.BtnHelp, "ConsumeActivityMain")
end

function XUiConsumeActivityMain:InitView()
    -- 涂装背景
    self.BgCommonBai:SetRawImage(self.ConsumeDrawActivity:GetCoatBg())
    -- 涂装名字
    self.CoatNameImage:SetRawImage(self.ConsumeDrawActivity:GetCoatName())
    -- 获取涂装描述
    self.CoatDesc.text = CsXTextManagerGetText("ConsumeActivityMainCoatDesc")
    -- 涂装
    self.CoatTask = XUiGridConsumeActivityCoatTask.New(self.PanelCoat, self)
    -- 注册红点事件
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnTefuBusiness, self.OnCheckBuyGoods, self, { XRedPointConditions.Types.CONDITION_CONSUME_ACTIVITY_BUY_GOODS })
end

function XUiConsumeActivityMain:UpdateCoat()
    local coatTaskId = self.ConsumeDrawActivity:GetCoatTaskId()
    self.CoatTask:Refresh(coatTaskId)
end

function XUiConsumeActivityMain:OnCheckBuyGoods(count)
    if self.BtnTefuBusiness then
        self.BtnTefuBusiness:ShowReddot(count >= 0)
    end
end

function XUiConsumeActivityMain:OnBtnBackClick()
    self:Close()
end

function XUiConsumeActivityMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 行运 聚宝
function XUiConsumeActivityMain:OnBtnTransportationReport()
    --抽卡
    if not self.ConsumeDrawActivity:CheckLuckyTimeout(true) then
        XLuaUiManager.Open("UiConsumeActivityLuckyBag")
    end
end
-- 德福 行商
function XUiConsumeActivityMain:OnBtnTefuBusiness()
    -- 活动商店
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) 
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local shopId = self.ConsumeDrawActivity:GetShopId()
        XShopManager.GetShopInfo(shopId, function()
            XLuaUiManager.Open("UiConsumeActivityShop")
        end)
    end
end

--region 剩余时间
function XUiConsumeActivityMain:StartTime()
    if self.Timer then
        self:StopTimer()
    end
    
    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiConsumeActivityMain:UpdateTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTimer()
        return
    end
    
    local endTime = self.ConsumeDrawActivity:GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    if now >= endTime then
        self:StopTimer()
        XDataCenter.AccumulatedConsumeManager.HandleActivityEndTime()
        return
    end

    local timeText = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeText
end

function XUiConsumeActivityMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--endregion

return XUiConsumeActivityMain