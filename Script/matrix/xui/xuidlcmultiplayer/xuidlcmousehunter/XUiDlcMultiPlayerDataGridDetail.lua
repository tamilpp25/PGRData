local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerDataGridPlayer = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDataGridPlayer")

---@class XUiDlcMultiPlayerDataGridDetail : XUiNode
---@field ListPlayer UnityEngine.RectTransform
---@field GridPlayer UnityEngine.RectTransform
---@field ImgBgLost UnityEngine.UI.Image
---@field ImgBgWin UnityEngine.UI.Image
---@field ImgWin UnityEngine.UI.RawImage
---@field ImgMouse UnityEngine.UI.RawImage
---@field ImgCat UnityEngine.UI.RawImage
---@field TxtTitle UnityEngine.UI.Text
---@field TxtType UnityEngine.UI.Text
---@field ImgFail UnityEngine.UI.RawImage
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerDataGridDetail = XClass(XUiNode, "XUiDlcMultiPlayerDataGridDetail")

-- region 生命周期

function XUiDlcMultiPlayerDataGridDetail:OnStart(campList, isWin, isCatCamp)
    self._IsSelfCampWin = isWin
    ---@type XUiDlcMultiPlayerDataGridPlayer[]
    self._GridPlayerUiList = {}
    self._DynamicTable = XDynamicTableNormal.New(self.ListPlayer)
    self._DynamicTable:SetProxy(XUiDlcMultiPlayerDataGridPlayer, self)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetDataSource(campList)
    self._DynamicTable:ReloadDataASync(1)

    self:_InitPanel(isWin, isCatCamp)
end

-- endregion

function XUiDlcMultiPlayerDataGridDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self._IsSelfCampWin)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self._Control:SetGridTransparent(grid, false, "GridPlayerUnit")
    end
end

-- region 私有方法

function XUiDlcMultiPlayerDataGridDetail:_InitPanel(isWin, isCatCamp)
    self.ImgWin.gameObject:SetActiveEx(isWin)
    self.ImgFail.gameObject:SetActiveEx(not isWin)
    self.ImgBgWin.gameObject:SetActiveEx(isWin)
    self.ImgBgLost.gameObject:SetActiveEx(not isWin)
    self.ImgCat.gameObject:SetActiveEx(isCatCamp)
    self.ImgMouse.gameObject:SetActiveEx(not isCatCamp)
    self.GridPlayer.gameObject:SetActiveEx(false)
    self.TxtType.text = isCatCamp and self._Control:GetSettleDataCatTitle() or self._Control:GetSettleDataMouseTitle()

    if isCatCamp then
        self.TxtTitle.text = self._Control:GetCatCampName()
    else
        self.TxtTitle.text = self._Control:GetMouseCampName()
    end
end

function XUiDlcMultiPlayerDataGridDetail:_PlayOffFrameAnimation()
    self._Control:PlayOffFrameAnimation(self._DynamicTable:GetGrids(), "GridPlayerAnimEnable", "GridPlayerUnit", 0.03)
end

-- endregion

return XUiDlcMultiPlayerDataGridDetail
