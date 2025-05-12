local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridFurnitureDetail = XClass(nil, "XUiGridFurnitureDetail")

function XUiGridFurnitureDetail:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridFurnitureDetail:Refresh(furnitureId)
    if not XTool.IsNumberValid(furnitureId) then
        self.GameObject:SetActiveEx(false)
        return
    end
    
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    if not furniture then
        self.GameObject:SetActiveEx(false)
        return
    end
    
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
    self.RImgIcon:SetRawImage(template.Icon)
    local score = furniture:GetScore()
    local scoreDesc = XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(template.TypeId, score)
    self.TxtSelectScore.text = XUiHelper.GetText("FurnitureRefitScore", scoreDesc)
end


---@class XUiFurnitureReCreateDetail : XLuaUi
local XUiFurnitureReCreateDetail = XLuaUiManager.Register(XLuaUi, "UiFurnitureReCreateDetail")

function XUiFurnitureReCreateDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiFurnitureReCreateDetail:OnStart(txtInfo, furnitureIds, positiveCb, negative)
    if not string.IsNilOrEmpty(txtInfo) then
        self.TxtName.text = XUiHelper.ReplaceTextNewLine(txtInfo)
    end
    self.FurnitureIds = furnitureIds or {}
    self.PositiveCb = positiveCb
    self.NegativeCb = negative
    
    self:SetupDynamicTable()
end

function XUiFurnitureReCreateDetail:InitUi()
    self.GridSelect.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridFurnitureDetail)

end

function XUiFurnitureReCreateDetail:InitCb()
    self.BtnSure.CallBack = function()
        self:Close()
        if self.PositiveCb then self.PositiveCb() end
    end

    self.BtnCancel.CallBack = function()
        self:Close()
        if self.NegativeCb then self.NegativeCb() end
    end
    
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiFurnitureReCreateDetail:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self.FurnitureIds)
    self.DynamicTable:ReloadDataSync()
end

function XUiFurnitureReCreateDetail:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FurnitureIds[index])
    end
end
