local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiSSBMonsterRewardList = XClass(nil, "XUiSSBMonsterRewardList")

function XUiSSBMonsterRewardList:Ctor(rootUi, uiPrefab)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitDynamicTable()
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiSSBMonsterRewardList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Monster/Grids/XUiSSBMonsterRewardGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBMonsterRewardList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index], type(self.DataList[index]) == "number")
        end
    end
end

function XUiSSBMonsterRewardList:Refresh(monsterGroup)
    local dropItem = monsterGroup:GetDropLevelItem()
    if not dropItem then return end
    local isClear = monsterGroup:CheckIsClear()
    if isClear then
        if dropItem > 0 then
            self.DataList = {[1] = monsterGroup:GetDropLevelItem()}
        else
            self.DataList = {}
        end
    else
        local dataList = {}
        if monsterGroup:GetRewardId() > 0 then
            dataList = XRewardManager.GetRewardList(monsterGroup:GetRewardId())
        end
        self.DataList = {}
        for k, v in pairs(dataList or {}) do
            self.DataList[k] = v
        end
        if dropItem > 0 then
            table.insert(self.DataList, monsterGroup:GetDropLevelItem())
        end
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiSSBMonsterRewardList