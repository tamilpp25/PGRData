local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSkyGardenShoppingStreetAchieve : XLuaUi
---@field UiBigWorldTopControlBlack UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field ListAchieve UnityEngine.RectTransform
---@field GridAchieve UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetAchieve = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetAchieve")

function XUiSkyGardenShoppingStreetAchieve:Ctor()
end

--region 生命周期
function XUiSkyGardenShoppingStreetAchieve:OnAwake()
    self:_RegisterButtonClicks()

    local XUiSkyGardenShoppingStreetAchieveGridAchieve = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetAchieveGridAchieve")
    self.DynamicTable = XDynamicTableNormal.New(self.ListAchieve.gameObject)
    self.DynamicTable:SetProxy(XUiSkyGardenShoppingStreetAchieveGridAchieve, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSkyGardenShoppingStreetAchieve:OnStart(...)
    self:RefreshAchieveList()
end

function XUiSkyGardenShoppingStreetAchieve:OnDestroy()
    
end
--endregion

function XUiSkyGardenShoppingStreetAchieve:RefreshAchieveList()
    self.GridCount = 0
    self.StoryTasks = XDataCenter.TaskManager.GetStoryTaskList()
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataSync()
end

--动态列表事件
function XUiSkyGardenShoppingStreetAchieve:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StoryTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    --     if not self.IsPlayAnimation then
    --         return
    --     end

    --     local grids = self.DynamicTable:GetGrids()
    --     self.GridIndex = 1
    --     self.CurAnimationTimerId = XScheduleManager.Schedule(function()
    --         local item = grids[self.GridIndex]
    --         if item then
    --             item.GameObject:SetActive(true)
    --             item:PlayAnimation()
    --         end
    --         self.GridIndex = self.GridIndex + 1
    --     end, GridTimeAnimation, self.GridCount, 0)
    end
end

--region 按钮事件
function XUiSkyGardenShoppingStreetAchieve:OnBtnBackClick()
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetAchieve:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetAchieve
