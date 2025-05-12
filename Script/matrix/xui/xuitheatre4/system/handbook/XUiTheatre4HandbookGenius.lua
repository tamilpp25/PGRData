local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4HandbookGeniusCard = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookGeniusCard")
local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")

---@class XUiTheatre4HandbookGenius : XUiNode
---@field BtnSure XUiComponent.XUiButton
---@field ListTab XUiButtonGroup
---@field BtnRed XUiComponent.XUiButton
---@field BtnYellow XUiComponent.XUiButton
---@field BtnBlud XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field TxtNumTotal UnityEngine.UI.Text
---@field TxtTips UnityEngine.UI.Text
---@field ListGenius UnityEngine.RectTransform
---@field GridGenius UnityEngine.RectTransform
---@field GridGeniusCard UnityEngine.RectTransform
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Handbook
local XUiTheatre4HandbookGenius = XClass(XUiNode, "XUiTheatre4HandbookGenius")

-- region 生命周期
function XUiTheatre4HandbookGenius:OnStart()
    ---@type XUiTheatre4HandbookGeniusCard
    self.GeniusCardUi = XUiTheatre4HandbookGeniusCard.New(self.GridGeniusCard, self)
    ---@type XUiComponent.XUiButton[]
    self._BtnListTabList = {
        self.BtnRed,
        self.BtnYellow,
        self.BtnBlud,
    }
    ---@type XTheatre4ColorTalentEntity
    self._CurrentSelectEntity = nil
    self._SelectTabIndex = nil
    self._CurrentSelectIndex = nil

    self._IsFirst = true

    self._RedTag = {}
    self._YellowTag = {}
    self._BlueTag = {}

    self._DynamicTable = XDynamicTableNormal.New(self.ListGenius)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiGridTheatre4Genius, self, Handler(self, self.OnGridClick))

    self.GeniusCardUi:Close()

    XTool.InitUiObjectByUi(self._RedTag, self.BtnRed)
    XTool.InitUiObjectByUi(self._YellowTag, self.BtnYellow)
    XTool.InitUiObjectByUi(self._BlueTag, self.BtnBlud)

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiTheatre4HandbookGenius:OnEnable()
    self._IsFirst = true
    self:_RefreshTabRedDot()
    self:_Refresh()
end

-- endregion

-- region 按钮事件

function XUiTheatre4HandbookGenius:CheckCloseCard()
    if self.GeniusCardUi and self.GeniusCardUi:IsNodeShow() then
        self:_CloseCard()

        return true
    end

    return false
end

function XUiTheatre4HandbookGenius:OnBtnSureClick()
    if self._SelectTabIndex == 1 then
        XLuaUiManager.Open("UiTheatre4Genius", XEnumConst.Theatre4.ColorType.Red, true)
    elseif self._SelectTabIndex == 2 then
        XLuaUiManager.Open("UiTheatre4Genius", XEnumConst.Theatre4.ColorType.Yellow, true)
    elseif self._SelectTabIndex == 3 then
        XLuaUiManager.Open("UiTheatre4Genius", XEnumConst.Theatre4.ColorType.Blue, true)
    end
end

function XUiTheatre4HandbookGenius:OnBtnCloseClick()
    self:_CloseCard()
end

function XUiTheatre4HandbookGenius:OnListTabClick(index)
    self:_CloseCard()
    self._SelectTabIndex = index
    if index == 1 then
        self:_RefreshGeniusCount(XEnumConst.Theatre4.ColorType.Red)
        self:_RefreshDynamicTable(XEnumConst.Theatre4.ColorType.Red)
    elseif index == 2 then
        self:_RefreshGeniusCount(XEnumConst.Theatre4.ColorType.Yellow)
        self:_RefreshDynamicTable(XEnumConst.Theatre4.ColorType.Yellow)
    else
        self:_RefreshGeniusCount(XEnumConst.Theatre4.ColorType.Blue)
        self:_RefreshDynamicTable(XEnumConst.Theatre4.ColorType.Blue)
    end
end

---@param grid XUiGridTheatre4Genius
function XUiTheatre4HandbookGenius:OnGridClick(grid)
    local index = grid:GetOtherValue()
    ---@type XTheatre4ColorTalentEntity
    local entity = self._DynamicTable:GetData(index)

    if entity and not entity:IsEmpty() then
        if self._CurrentSelectEntity and self._CurrentSelectEntity:IsEquals(entity) then
            self:_CloseCard()
        else
            entity:DisappearRedPoint()
            grid:ShowRedDot(false)
            grid:SetSelect(true)
            self:_CancelCurrentSelect()
            self._CurrentSelectIndex = index
            self.Parent:RefreshRedDot()
            self:_RefreshTabRedDot()
            self:_ShowCard(entity)
        end
    end
end

---@param grid XUiGridTheatre4Genius
function XUiTheatre4HandbookGenius:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        ---@type XTheatre4ColorTalentEntity
        local entity = self._DynamicTable:GetData(index)
        ---@type XTheatre4ColorTalentConfig
        local config = entity:GetConfig()
        local showLevel = config:GetShowLevel()

        grid:Refresh(config:GetId())
        grid:SetOther(index)
        grid:SetSelect(index == self._CurrentSelectIndex)
        grid:SetLock(not entity:IsEligible())
        grid:SetMask(not entity:IsUnlock())
        grid:ShowRedDot(entity:IsShowRedPoint())
        grid:SetLvIcon(self._Control:GetClientConfig("GeniusLevelIcon", showLevel))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayGeniusAnimation()
    end
end

-- endregion

-- region 私有方法

function XUiTheatre4HandbookGenius:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, true)
    self.ListTab:Init(self._BtnListTabList, Handler(self, self.OnListTabClick))
end

function XUiTheatre4HandbookGenius:_RefreshDynamicTable(colorType)
    local entitys = self._Control.SystemControl:GetTalentEntitysByColorType(colorType) or {}

    self._DynamicTable:SetDataSource(entitys)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTheatre4HandbookGenius:_RefreshGeniusCount(colorType)
    local unlockCount, totalCount = self._Control.SystemControl:GetUnlockTalentCountAndTotalCountByType(colorType)

    self.TxtNum.text = unlockCount
    self.TxtNumTotal.text = "/" .. totalCount
end

function XUiTheatre4HandbookGenius:_Refresh()
    self.ListTab:SelectIndex(self._SelectTabIndex or 1)
end

function XUiTheatre4HandbookGenius:_RefreshTabRedDot()
    if self._SelectTabIndex == 1 then
        self.BtnRed:ShowReddot(self._Control.SystemControl:CheckRedColorTalentHandBookRedDot())
    elseif self._SelectTabIndex == 2 then
        self.BtnYellow:ShowReddot(self._Control.SystemControl:CheckYellowColorTalentHandBookRedDot())
    elseif self._SelectTabIndex == 3 then
        self.BtnBlud:ShowReddot(self._Control.SystemControl:CheckBlueColorTalentHandBookRedDot())
    else
        self.BtnRed:ShowReddot(self._Control.SystemControl:CheckRedColorTalentHandBookRedDot())
        self.BtnYellow:ShowReddot(self._Control.SystemControl:CheckYellowColorTalentHandBookRedDot())
        self.BtnBlud:ShowReddot(self._Control.SystemControl:CheckBlueColorTalentHandBookRedDot())
    end
end

---@param entity XTheatre4ColorTalentEntity
function XUiTheatre4HandbookGenius:_ShowCard(entity)
    if entity and not entity:IsEmpty() then
        self.GeniusCardUi:Open()
        self.GeniusCardUi:Refresh(entity)
        self._CurrentSelectEntity = entity
        self.BtnClose.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre4HandbookGenius:_CloseCard()
    self.GeniusCardUi:Close()
    self._CurrentSelectEntity = nil
    self.BtnClose.gameObject:SetActiveEx(false)
    self:_CancelCurrentSelect()
end

function XUiTheatre4HandbookGenius:_CancelCurrentSelect()
    if self._CurrentSelectIndex then
        local selectGrid = self._DynamicTable:GetGridByIndex(self._CurrentSelectIndex)

        if selectGrid then
            selectGrid:SetSelect(false)
        end
        self._CurrentSelectIndex = nil
    end
end

function XUiTheatre4HandbookGenius:_InitUi()
    self.GridGenius.gameObject:SetActiveEx(false)
    self._RedTag.PanelClassOn.gameObject:SetActiveEx(false)
    self._RedTag.PanelClassOff.gameObject:SetActiveEx(false)
    self._YellowTag.PanelClassOn.gameObject:SetActiveEx(false)
    self._YellowTag.PanelClassOff.gameObject:SetActiveEx(false)
    self._BlueTag.PanelClassOn.gameObject:SetActiveEx(false)
    self._BlueTag.PanelClassOff.gameObject:SetActiveEx(false)
end

function XUiTheatre4HandbookGenius:_PlayGeniusAnimation()
    if not self._IsFirst then
        self:PlayAnimationWithMask("PanelGeniusEnable")
    end
    self._IsFirst = false
end

-- endregion

return XUiTheatre4HandbookGenius
