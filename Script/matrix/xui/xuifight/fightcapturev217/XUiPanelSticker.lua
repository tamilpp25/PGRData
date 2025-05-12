local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelSticker : XUiNode 拍照后贴纸和其他的选择列表
---@field Parent XUiFightCaptureV217
---@field _Control XFightCaptureV217Control
local XUiPanelSticker = XClass(XUiNode, "XUiPanelSticker")
local XUiGridSticker = require("XUi/XUiFight/FightCaptureV217/XUiGridSticker")
local XUiStickerOtherList = require("XUi/XUiFight/FightCaptureV217/XUiStickerOtherList")

function XUiPanelSticker:OnStart()
    XTool.InitUiObject(self)

    self.DynamicTableSticker = XDynamicTableNormal.New(self.StickerList.gameObject)
    self.DynamicTableSticker:SetProxy(XUiGridSticker, self)
    self.DynamicTableSticker:SetDelegate(self)

    self.XUiStickerOtherList = XUiStickerOtherList.New(self.OtherList.gameObject, self)
end

function XUiPanelSticker:Refresh()
    -- 刷新贴纸选项列表
    if self.Parent.BtnIndex == self.Parent.BtnIndexEnum.Paster then
        self.StickerList.gameObject:SetActiveEx(true)
        self.StickerIdList = self._Control._Model:GetStickerIdList(self.GroupId)
        self.DynamicTableSticker:SetDataSource(self.StickerIdList)
        self.DynamicTableSticker:ReloadDataASync()
    else
        self.StickerList.gameObject:SetActiveEx(false)
    end

    -- 显隐其他选项列表
    self.XUiStickerOtherList:SetActive(self.Parent.BtnIndex == self.Parent.BtnIndexEnum.Filter)
end

---@field grid XUiGridSticker
function XUiPanelSticker:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local stickerId = self.StickerIdList[index]
        grid:SetData(stickerId, self.UnlockStickerIdDic[stickerId] or false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local stickerId = self.StickerIdList[index]
        if not self.UnlockStickerIdDic[stickerId] then
            XUiManager.TipSuccess(self._Control._Model:GetStickerCfgUnlockDesc(stickerId))
            return
        end
        self:SetSelectStickerId(stickerId, index)
        self.Parent:CreateGridPaster(stickerId)
        self.Parent:StartLeyPaster()
    end
end

--- 设置数据
---@param groupId - CaptureV217Sticker表的GroupId
---@param unlockStickerIdList - 解锁的贴纸id列表
function XUiPanelSticker:SetData(groupId, unlockStickerIdList)
    self.GroupId = groupId
    self.UnlockStickerIdDic = {}
    for _, id in pairs(unlockStickerIdList) do
        self.UnlockStickerIdDic[FixToInt(id)] = true
    end
end

function XUiPanelSticker:SetSelectStickerId(stickerId, gridIndex)
    self.SelectStickerId = stickerId

    local grid
    if self.SelectGridIndex then
        grid = self.DynamicTableSticker:GetGridByIndex(self.SelectGridIndex)
        if grid then
            grid:Refresh()
        end
    end

    grid = self.DynamicTableSticker:GetGridByIndex(gridIndex)
    if grid then
        grid:Refresh()
    end

    self.SelectGridIndex = gridIndex
end

function XUiPanelSticker:OnSelected(isSelected)
    if isSelected then
        self:Open()
        self:Refresh()
    else
        self:Close()
    end
end

return XUiPanelSticker