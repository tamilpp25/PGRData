local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRogueSimCity = require("XUi/XUiRogueSim/Bag/XUiGridRogueSimCity")
---@class XUiRogueSimCityBag : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimCityBag = XLuaUiManager.Register(XLuaUi, "UiRogueSimCityBag")

function XUiRogueSimCityBag:OnAwake()
    self:RegisterUiEvents()
    self.GridCity.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
end

function XUiRogueSimCityBag:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd(true)
        end
    end)
    self:InitDynamicTable()
end

function XUiRogueSimCityBag:OnEnable()
    self.Super.OnEnable(self)
    self:SetupDynamicTable()
    -- 拥有数量
    self.TxtNum.text = table.nums(self.DataList)
end

function XUiRogueSimCityBag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListCity)
    self.DynamicTable:SetProxy(XUiGridRogueSimCity, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRogueSimCityBag:SetupDynamicTable()
    self.DataList = self._Control.MapSubControl:GetOwnCityIds()
    if XTool.IsTableEmpty(self.DataList) then
        self.TxtNone.gameObject:SetActiveEx(true)
        return
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridRogueSimCity
function XUiRogueSimCityBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiRogueSimCityBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiRogueSimCityBag:OnBtnBackClick()
    self:Close()
end

return XUiRogueSimCityBag
