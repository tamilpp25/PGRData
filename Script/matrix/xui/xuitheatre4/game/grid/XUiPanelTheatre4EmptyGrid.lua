-- 空格子 所有完成的格子都会是空格子
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4EmptyGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4EmptyGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4EmptyGrid")

function XUiPanelTheatre4EmptyGrid:OnStart()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
end

function XUiPanelTheatre4EmptyGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    self:RefreshUnknown()
    self:RefreshVisible()
    self:RefreshDiscover()
    self:RefreshProcessed()
end

function XUiPanelTheatre4EmptyGrid:OnBtnGridClick()
    -- 发现状态 可探索
    if self.GridData:IsGridStateDiscover() then
        -- 判断是否有行动点
        if not self._Control.AssetSubControl:CheckApEnough() then
            return
        end

        local posX, posY = self.GridData:GetGridPos()

        -- 请求探索 空格子不会掉事务
        self._Control:ExploreGridRequest(self.MapId, posX, posY, function()
            local mapIds = self._Control:GetClientConfigParams("GuideActiveMapId")
            local currentMapId = self._Control.MapSubControl:GetCurrentMapId()

            if not XTool.IsTableEmpty(mapIds) then
                for _, mapId in pairs(mapIds) do
                    if currentMapId == tonumber(mapId) then
                        XDataCenter.GuideManager.CheckGuideOpen()
                    end
                end
            end
        end)
    end
end

return XUiPanelTheatre4EmptyGrid
