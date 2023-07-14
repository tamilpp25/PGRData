local XUiMultiDimSelectDifficult = XLuaUiManager.Register(XLuaUi, "UiMultiDimSelectDifficult")
local XUiGuidMultiDimSelectDifficult = require("XUi/XUiMultiDim/XUiGuidMultiDimSelectDifficult")

function XUiMultiDimSelectDifficult:OnAwake()
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self.GridCondition.gameObject:SetActiveEx(false)
end

function XUiMultiDimSelectDifficult:OnStart(currentThemeId, currentDifficulty, closeCallback)
    self.CurrentThemeId = currentThemeId
    self.CurrentDifficulty = currentDifficulty
    self.CloseCallback = closeCallback

    -- 开启自动关闭检查
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MultiDimManager.HandleActivityEndTime()
        end
    end)
end

function XUiMultiDimSelectDifficult:OnEnable()
    self.Super.OnEnable(self)
    self:SetupDynamicTable()
end

function XUiMultiDimSelectDifficult:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCondition)
    self.DynamicTable:SetProxy(XUiGuidMultiDimSelectDifficult)
    self.DynamicTable:SetDelegate(self)
end

function XUiMultiDimSelectDifficult:SetupDynamicTable()
    self.DynamicTableDataList = XDataCenter.MultiDimManager.GetDifficultyInfoByThemeId(self.CurrentThemeId)
    self.DynamicTable:SetDataSource(self.DynamicTableDataList or {})
    self.DynamicTable:ReloadDataSync(self.CurrentDifficulty)
end

function XUiMultiDimSelectDifficult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTableDataList[index], self.CurrentDifficulty)
    end
end

function XUiMultiDimSelectDifficult:OnClick(currentDifficulty,stageId)
    if self.CloseCallback then
        self.CloseCallback(currentDifficulty,stageId)
    end
    self:Close()
end

function XUiMultiDimSelectDifficult:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBig)
end

function XUiMultiDimSelectDifficult:OnBtnTanchuangCloseBig()
    self:Close()
end

return XUiMultiDimSelectDifficult