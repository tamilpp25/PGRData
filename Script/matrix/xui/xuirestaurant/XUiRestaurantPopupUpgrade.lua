
---@class XUiRestaurantPopupUpgrade : XLuaUi 升级弹窗
---@field _Control XRestaurantControl
local XUiRestaurantPopupUpgrade = XLuaUiManager.Register(XLuaUi, "UiRestaurantPopupUpgrade")

function XUiRestaurantPopupUpgrade:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantPopupUpgrade:OnStart(level, closeCb)
    self.Level = level
    self.CloseCb = closeCb
    self:InitView()
end

function XUiRestaurantPopupUpgrade:InitUi()
    self.Grids = {}
    self.GridStory.gameObject:SetActiveEx(false)
end

function XUiRestaurantPopupUpgrade:InitCb()
    self.BtnClose.CallBack = function() 
        self:OnBtnCloseClick()
    end
end

function XUiRestaurantPopupUpgrade:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

function XUiRestaurantPopupUpgrade:InitView()
    self.TxtLv.text = string.format("Lv.%s", self.Level)
    local performIds = self._Control:GetLvUpPerformIds(self.Level)
    for idx, performId in ipairs(performIds) do
        local grid = self.Grids[idx]
        if not grid then
            local ui = idx == 1 and self.GridStory or XUiHelper.Instantiate(self.GridStory, self.ListStory)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            ui.gameObject:SetActiveEx(true)
            self.Grids[idx] = grid
        end
        self:RefreshPerformGrid(grid, performId)
    end
end

function XUiRestaurantPopupUpgrade:RefreshPerformGrid(grid, performId)
    if not grid then
        return
    end
    ---@type XRestaurantPerformVM
    local perform = self._Control:GetPerform(performId)
    grid.Txt.text = perform:GetUnlockText()
end