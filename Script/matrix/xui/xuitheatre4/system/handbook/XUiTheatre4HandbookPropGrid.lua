local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")

---@class XUiTheatre4HandbookPropGrid : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field PanelGroup UnityEngine.RectTransform
---@field GridProp UnityEngine.RectTransform
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4HandbookProp
local XUiTheatre4HandbookPropGrid = XClass(XUiNode, "XUiTheatre4HandbookPropGrid")

-- region 生命周期

function XUiTheatre4HandbookPropGrid:OnStart()
    ---@type XUiGridTheatre4Prop[]
    self._GridList = {}
    ---@type table<number, XTheatre4ItemEntity>
    self._EntityIdMap = {}

    self:_InitUi()
end

-- endregion

---@param grid XUiGridTheatre4Prop
function XUiTheatre4HandbookPropGrid:OnItemClick(grid)
    ---@type XTheatre4ItemEntity
    local entity = self._EntityIdMap[grid.ItemId]

    if entity and not entity:IsEmpty() then
        entity:DisappearRedPoint()
        grid:ShowRedDot(false)
        self.Parent:ShowPropCard(entity, grid)
    end
end

---@param entitys XTheatre4ItemEntity[]
function XUiTheatre4HandbookPropGrid:Refresh(index, entitys)
    self.TxtTitle.text = self._Control:GetClientConfig("ArchieveTypeText", index)
    self:_RefreshGrids(entitys)
end

-- region 私有方法

---@param entitys XTheatre4ItemEntity[]
function XUiTheatre4HandbookPropGrid:_RefreshGrids(entitys)
    self._EntityIdMap = {}
    if not XTool.IsTableEmpty(entitys) then
        for i, entity in pairs(entitys) do
            local grid = self._GridList[i]
            ---@type XTheatre4ItemConfig
            local config = entity:GetConfig()
            local id = config:GetId()

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridProp, self.PanelGroup)

                grid = XUiGridTheatre4Prop.New(gridObject, self, Handler(self, self.OnItemClick))
                self._GridList[i] = grid
            end

            self._EntityIdMap[id] = entity

            grid:Open()
            grid:Refresh({
                Id = id,
                Type = XEnumConst.Theatre4.AssetType.Item,
            })
            grid:SetLock(not entity:IsEligible())
            grid:SetMask(not entity:IsUnlock())
            grid:ShowRedDot(entity:IsShowRedPoint())
        end
        for i = #entitys + 1, #self._GridList do
            self._GridList[i]:Close()
        end
    else
        for _, grid in pairs(self._GridList) do
            grid:Close()
        end
    end
end

function XUiTheatre4HandbookPropGrid:_InitUi()
    self.GridProp.gameObject:SetActiveEx(false)
end

-- endregion

return XUiTheatre4HandbookPropGrid
