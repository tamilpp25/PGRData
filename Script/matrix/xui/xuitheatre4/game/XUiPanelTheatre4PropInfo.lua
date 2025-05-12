local XUiTheatre4BubbleBagGrid = require("XUi/XUiTheatre4/Game/Bubble/XUiTheatre4BubbleBagGrid")
---@class XUiPanelTheatre4PropInfo : XUiNode
---@field _Control XTheatre4Control
local XUiPanelTheatre4PropInfo = XClass(XUiNode, "XUiPanelTheatre4PropInfo")

function XUiPanelTheatre4PropInfo:OnStart()
    ---@type XUiTheatre4BubbleBagGrid[]
    self.PropGridList = {}
    self.PanelNone.gameObject:SetActiveEx(false)
    self.Grid.gameObject:SetActiveEx(false)

    if self.PanelStartEffect then
        XUiHelper.RegisterClickEvent(self, self.PanelStartEffect, self.OnOpenBag)
    end
end

function XUiPanelTheatre4PropInfo:OnEnable()
    self:Refresh()
end

function XUiPanelTheatre4PropInfo:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_ADD_PROP,
        XEventId.EVENT_THEATRE4_REMOVE_PROP,
        XEventId.EVENT_THEATRE4_UPDATE_PROP,
        XEventId.EVENT_THEATRE4_EFFECT_CHANGE,
    }
end

function XUiPanelTheatre4PropInfo:OnNotify(event, ...)
    self:Refresh()
end

function XUiPanelTheatre4PropInfo:Refresh()
    self:RefreshAffixInfo()
    self:RefreshPropList()
    self:RefreshNum()
end

-- 刷新藏品数量和上限
function XUiPanelTheatre4PropInfo:RefreshNum()
    local count = table.nums(self.ItemDataList)
    local limit = self._Control.AssetSubControl:GetItemLimit()
    self.TxtNum.text = string.format("%s/%s", count, limit)
end

-- 刷新词缀信息
function XUiPanelTheatre4PropInfo:RefreshAffixInfo()
    local affix = self._Control:GetAffix()
    local icon = self._Control:GetAffixIcon(affix)
    if icon then
        self.ImgStartEffect:SetSprite(icon)
    end
    self.TxtDetail.text = self._Control:GetAffixDesc(affix)
end

function XUiPanelTheatre4PropInfo:RefreshPropList()
    self.ItemDataList = self._Control:GetBagSideItemDataList()
    if XTool.IsTableEmpty(self.ItemDataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    self.PanelNone.gameObject:SetActiveEx(false)
    for index, itemData in pairs(self.ItemDataList) do
        local grid = self.PropGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.Grid, self.ListProp)
            grid = XUiTheatre4BubbleBagGrid.New(go, self)
            self.PropGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(itemData)
    end
    for i = #self.ItemDataList + 1, #self.PropGridList do
        self.PropGridList[i]:Close()
    end
end

function XUiPanelTheatre4PropInfo:OnOpenBag()
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    XLuaUiManager.Open("UiTheatre4Bag")
end

return XUiPanelTheatre4PropInfo
