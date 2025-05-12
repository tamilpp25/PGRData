---@class XUiPanelSGWall : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _PanelMenu XUiPanelSGWallMenu
---@field _PanelTab XUiPanelSGWallTab
---@field _PanelOp XUiPanelSGWallOp
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiPanelSGWall = XClass(XUiNode, "XUiPanelSGWall")

function XUiPanelSGWall:InitUi()
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    local areaType = self._AreaType
    self._PanelMenu = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallMenu").New(self.PanelMenu, self, areaType)
end

function XUiPanelSGWall:InitCb()
end

function XUiPanelSGWall:Refresh()
    self._PanelMenu:RefreshDynamicTable()
end

function XUiPanelSGWall:OnSelectTab(typeId, furnitureId)
    self._PanelMenu:OnTypeIdChanged(typeId, furnitureId)
end

function XUiPanelSGWall:OnSelectFurniture(id, cfgId, isCreate)
    if not self._PanelOp:TryCheckOpIsSafe(true) then
        return
    end
    if isCreate then
        local majorType = self._Control:GetFurnitureMajorType(cfgId)
        if not self._Control:IsContainerFurniture(cfgId) then
            if self.Parent:CheckIsFull(majorType) then
                XUiManager.TipMsg(self._Control:GetSameTypeFullCountText())
                return
            end
        end
        local func = self._CreateFunc[majorType]

        if func then
            func(id, cfgId)
        end
    else
        self._PanelOp:TryClickSlot(id)
    end
end

--- 选中操作框的家具
---@param id number
function XUiPanelSGWall:OnSelectFurnitureGridOp(id, tabIndex)
    if not id or id <= 0 then
        return self._PanelTab:SelectIndex(tabIndex)
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local typeId = self._Control:GetFurnitureTypeId(cfgId)
    self._PanelTab:OnSelectByTypeId(typeId, cfgId)
end

function XUiPanelSGWall:InitFurniture()
end

function XUiPanelSGWall:EnterEditMode()
    self._PanelMenu:Close()
    self._PanelTab:Close()
    self.Parent:EnterEditMode(false)
end

function XUiPanelSGWall:ExitEditMode()
    self.Parent:ExitEditMode(true)
    self._PanelMenu:Open()
    self._PanelTab:Open()
end

function XUiPanelSGWall:ClearDecoration()
    self._PanelOp:ClearDecoration()
end

function XUiPanelSGWall:TryCheckOpIsSafe(tips)
    return self._PanelOp:TryCheckOpIsSafe(tips)
end

function XUiPanelSGWall:RevertDecoration()
    self._PanelOp:RevertDecoration()
end

function XUiPanelSGWall:ApplyNewLayout()
    self._PanelOp:ApplyNewLayout()
end

function XUiPanelSGWall:OnDestroy()
end

function XUiPanelSGWall:SetVisible(value)
    self.CanvasGroup.blocksRaycasts = value
    if value then
        self._PanelMenu:Open()
        self._PanelTab:Open()
    else
        self._PanelMenu:Close()
        self._PanelTab:Close()
    end
end

return XUiPanelSGWall