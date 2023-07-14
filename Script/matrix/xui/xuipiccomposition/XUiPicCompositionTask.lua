XUiPicCompositionTask = XClass(nil, "XUiPicCompositionTask")

local ProTime = 2

function XUiPicCompositionTask:Ctor(parent,ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)

    self:InitPanelActiveGrid()
    self.ItemObjList = {}
    self.GameObject:SetActiveEx(false)
    -- 自适应调整
    self.OriginPosition = self.PanelActiveGrids[1].Transform.localPosition
    self.ActiveProgressRect = self.ImgDaylyActiveProgressTransform

    self:SetButtonCallBack()
    self:InitDynamicTable()

    XDataCenter.ItemManager.AddCountUpdateListener(self.Parent.TaskItem, function()
            self:UpdateActiveness()
        end, self.TxtDailyActive)
end

function XUiPicCompositionTask:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:HidePanel()
        self.Parent.AssetActivityPanel:Refresh({self.Parent.LikeItem})
    end
end

function XUiPicCompositionTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPicCompositionTask:SetupDynamicTable()
    self.DailyTasks = XDataCenter.MarketingActivityManager.GetPicCompositionTaskDatas()
    self.PanelNoneDailyTask.gameObject:SetActiveEx(self.DailyTasks and #self.DailyTasks<=0)
    self.DynamicTable:SetDataSource(self.DailyTasks)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPicCompositionTask:Refresh()
    self:SetupDynamicTable()
    self:UpdateActiveness()
end

--动态列表事件
function XUiPicCompositionTask:OnDynamicTableEvent(event,index,grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DailyTasks[index]
        if data == nil then return end
        grid.RootUi = self.Parent
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiPicCompositionTask:InitPanelActiveGrid()
    self.PanelActiveGrids = {}
    self.PanelActiveGridRects = {}
    local ActivenesTotal = XMarketingActivityConfigs.GetPicCompositionScheduleRewardTotal()
    for i = 1,ActivenesTotal do
        local grid = self.PanelActiveGrids[i]
        if not grid then
            if i == 1 then
                grid = XUiPicCompositionPanelActive.New(self.PanelActive, self.Parent, i, self)
            else
                local activeGO = CS.UnityEngine.Object.Instantiate(self.PanelActive)
                activeGO.transform:SetParent(self.PanelContent, false)
                grid = XUiPicCompositionPanelActive.New(activeGO, self.Parent, i, self)
            end
            self.PanelActiveGrids[i] = grid
            self.PanelActiveGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiPicCompositionTask:UpdateActiveness()
    local curActiveness = XDataCenter.ItemManager.GetCount(self.Parent.TaskItem)
    local ActivenesDatas = XMarketingActivityConfigs.GetPicCompositionScheduleRewardInfoConfigs()
    local ActivenesTotal = XMarketingActivityConfigs.GetPicCompositionScheduleRewardTotal()

    if ActivenesTotal > 0 then
        local fillAmount = curActiveness / ActivenesDatas[ActivenesTotal].Schedule
        if self.Curfillamount ~= fillAmount then
            self.ImgDaylyActiveProgress:DOFillAmount(fillAmount,ProTime)
            self.Curfillamount = fillAmount
        end
    end

    self.TxtDailyActive.text = curActiveness < ActivenesDatas[ActivenesTotal].Schedule and curActiveness or ActivenesDatas[ActivenesTotal].Schedule
    self.TextMax.text = string.format("/%d",ActivenesDatas[ActivenesTotal].Schedule)
    for i = 1, ActivenesTotal do
        self.PanelActiveGrids[i]:UpdateActiveness(ActivenesDatas[i].Schedule,curActiveness)
    end

    -- 自适应
    local activeProgressRectSize = self.ActiveProgressRect.rect.size
    for i = 1, #self.PanelActiveGrids do
        local valOffset = ActivenesDatas[i].Schedule / ActivenesDatas[ActivenesTotal].Schedule
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * valOffset, self.OriginPosition.y, self.OriginPosition.z)
        self.PanelActiveGridRects[i].anchoredPosition3D = adjustPosition
    end
end

function XUiPicCompositionTask:ShowPanel()
    self.GridCount = 0
    self.GameObject:SetActiveEx(true)
    self:SetupDynamicTable()
end

function XUiPicCompositionTask:HidePanel()
    self.GameObject:SetActiveEx(false)
end