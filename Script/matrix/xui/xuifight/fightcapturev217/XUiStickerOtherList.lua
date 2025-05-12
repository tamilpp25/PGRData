local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiStickerOtherList 拍照后其他的选择列表
---@field Parent XUiPanelSticker
local XUiStickerOtherList = XClass(nil, "XUiStickerOtherList")
local XUiGridOther = require("XUi/XUiFight/FightCaptureV217/XUiGridOther")

function XUiStickerOtherList:Ctor(otherList, parent)
    self.OtherList = otherList
    self.Parent = parent
    
    parent._Control:SetUseScreenEffectId(0)
    self.CurSelectGrid = nil
    
    self.DynamicTable = XDynamicTableNormal.New(otherList.gameObject)
    self.DynamicTable:SetProxy(XUiGridOther, self)
    self.DynamicTable:SetDelegate(self)
    
    self.ScreenEffectIdList = parent._Control._Model:GetScreenEffectIdList()
    self.DynamicTable:SetDataSource(self.ScreenEffectIdList)
    self.DynamicTable:ReloadDataASync()
end

---@field grid XUiGridOther
function XUiStickerOtherList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.ScreenEffectIdList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:ChangeToggle()
    end
end

function XUiStickerOtherList:Refresh(grid)
    if self.CurSelectGrid == grid then
        return
    end

    if self.CurSelectGrid then
        self.CurSelectGrid:Refresh()
    end
    self.CurSelectGrid = grid
end

function XUiStickerOtherList:SetActive(isActive)
    self.OtherList.gameObject:SetActiveEx(isActive)
end

return XUiStickerOtherList