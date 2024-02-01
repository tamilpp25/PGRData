local XUiGridArchive = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridArchive")

---@class XUiBlackRockChessArchive : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessArchive = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessArchive")

local SelectIndex = 1

function XUiBlackRockChessArchive:OnAwake()

end

function XUiBlackRockChessArchive:OnStart()
    self:InitCompnent()
end

function XUiBlackRockChessArchive:OnEnable()
    self.TabBtnContent:SelectIndex(SelectIndex)
end

function XUiBlackRockChessArchive:OnDisable()
    self.TabIndex = nil
end

function XUiBlackRockChessArchive:OnDestroy()

end

function XUiBlackRockChessArchive:InitCompnent()
    local tabs = {}
    local infos = self._Control:GetArchiveData()
    self._ArchiveList = {}
    for i, v in ipairs(infos) do
        local button = i == 1 and self.BtnTabShortNew or XUiHelper.Instantiate(self.BtnTabShortNew, self.TabBtnContent.transform)
        button:SetNameByGroup(0, v.Name)
        table.insert(tabs, button)
        self._ArchiveList[i] = v.archives
    end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchive, self)
    self.DynamicTable:SetDelegate(self)

    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)
    self.TabBtnContent:Init(tabs, function(index)
        self:OnSelectTab(index)
    end)

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessArchive:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = index
    SelectIndex = index
    local data = self._ArchiveList[index]
    self:RefreshCount()
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataSync()
end

---动态列表事件
function XUiBlackRockChessArchive:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:UpdateGrid(data)
    end
end

function XUiBlackRockChessArchive:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
end

function XUiBlackRockChessArchive:RefreshCount()
    local data = self._ArchiveList[self.TabIndex]
    local max = #data
    local count = 0
    for _, v in pairs(data) do
        if XConditionManager.CheckCondition(v.Condition) then
            count = count + 1
        end
    end
    self.TxtMaxCollectNum.text = max
    self.TxtHaveCollectNum.text = count
end

return XUiBlackRockChessArchive