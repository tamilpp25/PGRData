local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerTitleGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerTitleGrid")

---@class XUiDlcMultiPlayerTitle : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field PanelTitleList UnityEngine.RectTransform
---@field GridTitle UnityEngine.RectTransform
---@field TxtTitleName UnityEngine.UI.Text
---@field TxtTime UnityEngine.UI.Text
---@field TxtDecs UnityEngine.UI.Text
---@field BtnReplace XUiComponent.XUiButton
---@field BtnUnReplace XUiComponent.XUiButton
---@field PanelTime UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerTitle = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerTitle")

-- region 生命周期
function XUiDlcMultiPlayerTitle:OnAwake()
    self._CurrentWearTitleIndex = self._Control:GetCurrentWearTitleIndex()
    self._CurrentSelectIndex = XTool.IsNumberValid(self._CurrentWearTitleIndex) and self._CurrentWearTitleIndex or 1
    self._TitleList = self._Control:GetTitleList()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelTitleList)
    self._DynamicTable:SetProxy(XUiDlcMultiPlayerTitleGrid, self)
    self._DynamicTable:SetDelegate(self)
    self._LastChangeTime = 0
    self._IsPlayAnimation = true

    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerTitle:OnStart()
    self.GridTitle.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerTitle:OnEnable()
    self:_RefreshDynamicTable()
    self:_RefreshTitleDesc()
    self:_RefreshTitleNumber()
end

-- endregion

function XUiDlcMultiPlayerTitle:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self._CurrentSelectIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:_ChangeTitleSelect(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        if self._IsPlayAnimation then
            self._Control:SetGridTransparent(grid, false, "Bg")
        end
    end
end

-- region 按钮事件

function XUiDlcMultiPlayerTitle:OnBtnTanchuangCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MULTIPLAYER_REFRESH_RED_POINT)
end

function XUiDlcMultiPlayerTitle:OnBtnReplaceClick()
    local nowTime = XTime.GetServerNowTimestamp()

    if not XTool.IsNumberValid(self._LastChangeTime) or self._LastChangeTime + 1 <= nowTime then
        local title = self._TitleList[self._CurrentSelectIndex]

        if title and title:GetIsUnlock() then
            self._LastChangeTime = nowTime
            XMVCA.XDlcMultiMouseHunter:RequestWearTitle(title:GetId(), function()
                self:_UnWearCurrentTitle()
                self:_WearCurrentSelectTitle()
                self:_RefreshDynamicTable()
                self:_RefreshTitleDesc()
            end)
        end
    end
end

function XUiDlcMultiPlayerTitle:OnBtnCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MULTIPLAYER_REFRESH_RED_POINT)
end

function XUiDlcMultiPlayerTitle:OnBtnUnReplaceClick()
    local nowTime = XTime.GetServerNowTimestamp()

    if not XTool.IsNumberValid(self._LastChangeTime) or self._LastChangeTime + 1 <= nowTime then
        self._LastChangeTime = nowTime
        XMVCA.XDlcMultiMouseHunter:RequestWearTitle(0, function()
            self:_UnWearCurrentTitle()
            self:_RefreshDynamicTable()
            self:_RefreshTitleDesc()
        end)
    end
end

-- endregion

-- region 私有方法
function XUiDlcMultiPlayerTitle:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
    self:RegisterClickEvent(self.BtnReplace, self.OnBtnReplaceClick, true)
    self:RegisterClickEvent(self.BtnUnReplace, self.OnBtnUnReplaceClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiDlcMultiPlayerTitle:_RefreshDynamicTable()
    self._DynamicTable:SetDataSource(self._TitleList)
    self._DynamicTable:ReloadDataASync(self._CurrentSelectIndex)
end

function XUiDlcMultiPlayerTitle:_RefreshTitleDesc()
    local title = self._TitleList[self._CurrentSelectIndex]

    if title then
        if title:GetIsUnlock() then
            self.PanelTime.gameObject:SetActiveEx(true)
            self.TxtTime.text = title:GetUnlockTime()
        else
            self.PanelTime.gameObject:SetActiveEx(false)
        end
        if title:GetIsProgress() then
            local desc = title:GetDesc()
            local progress = title:GetProgress()

            self.TxtDecs.text = string.format(XUiHelper.ConvertLineBreakSymbol(desc), progress)
        else
            self.TxtDecs.text = title:GetDesc()
        end
        if title:GetIsWear() then
            self.BtnUnReplace.gameObject:SetActiveEx(true)
            self.BtnReplace.gameObject:SetActiveEx(false)
        else
            self.BtnUnReplace.gameObject:SetActiveEx(false)
            self.BtnReplace.gameObject:SetActiveEx(true)
            self.BtnReplace:SetButtonState(title:GetIsUnlock() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        end

        self.TxtTitleName.text = title:GetContent()
    end
end

function XUiDlcMultiPlayerTitle:_RefreshTitleNumber()
    local unlockCount = self._Control:GetTitleUnlockNumber()
    local totalCount = self._Control:GetTitleTotalNumber()

    self.TxtNum.text = unlockCount .. "/" .. totalCount
end

function XUiDlcMultiPlayerTitle:_ChangeTitleSelect(selectIndex, selectGrid)
    if self._CurrentSelectIndex ~= selectIndex then
        local grid = self._DynamicTable:GetGridByIndex(self._CurrentSelectIndex)

        if grid then
            grid:OnTouched(false)
        end

        selectGrid:OnTouched(true)

        self._CurrentSelectIndex = selectIndex
        self:_RefreshTitleDesc()
    end
end

function XUiDlcMultiPlayerTitle:_UnWearCurrentTitle()
    if XTool.IsNumberValid(self._CurrentWearTitleIndex) then
        local wearTitle = self._TitleList[self._CurrentWearTitleIndex]

        if wearTitle then
            wearTitle:UnWear()
            self._CurrentWearTitleIndex = 0
        end
    end
end

function XUiDlcMultiPlayerTitle:_WearCurrentSelectTitle()
    local title = self._TitleList[self._CurrentSelectIndex]

    if title then
        title:Wear()
        self._CurrentWearTitleIndex = self._CurrentSelectIndex
    end
end

function XUiDlcMultiPlayerTitle:_PlayOffFrameAnimation()
    if self._IsPlayAnimation then
        self._Control:PlayOffFrameAnimation(self._DynamicTable:GetGrids(), "GridTitleEnable", "Bg", 0.02)
        self._IsPlayAnimation = false
    end
end

-- endregion

return XUiDlcMultiPlayerTitle
