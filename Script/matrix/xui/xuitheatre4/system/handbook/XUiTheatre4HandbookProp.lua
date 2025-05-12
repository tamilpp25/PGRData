local XUiTheatre4HandbookPropGrid = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookPropGrid")
local XUiTheatre4HandbookPropCard = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookPropCard")

---@class XUiTheatre4HandbookProp : XUiNode
---@field TxtNum UnityEngine.UI.Text
---@field TxtNumTotal UnityEngine.UI.Text
---@field TxtTips UnityEngine.UI.Text
---@field ListCollection UnityEngine.RectTransform
---@field GridPropCard UnityEngine.RectTransform
---@field PanelProp UnityEngine.RectTransform
---@field PropContent UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field _Control XTheatre4Control
local XUiTheatre4HandbookProp = XClass(XUiNode, "XUiTheatre4HandbookProp")

-- region 生命周期

function XUiTheatre4HandbookProp:OnStart()
    ---@type XUiTheatre4HandbookPropCard
    self.PropCardUi = XUiTheatre4HandbookPropCard.New(self.GridPropCard, self)
    ---@type XUiTheatre4HandbookPropGrid[]
    self._PropGridList = {}

    ---@type XTheatre4ItemEntity
    self._CurrentSelectEntity = nil
    ---@type XUiGridTheatre4Prop
    self._CurrentSelectGrid = nil

    self.PropCardUi:Close()

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiTheatre4HandbookProp:OnEnable()
    self:_RefreshCount()
    self:_RefreshPropGridList()
end

-- endregion

function XUiTheatre4HandbookProp:OnBtnCloseClick()
    self:_ClosePropCard()
end

---@param entity XTheatre4ItemEntity
---@param grid XUiGridTheatre4Prop
function XUiTheatre4HandbookProp:ShowPropCard(entity, grid)
    if entity and not entity:IsEmpty() then
        if self._CurrentSelectEntity and self._CurrentSelectEntity:IsEquals(entity) then
            self:_ClosePropCard()
        else
            if self._CurrentSelectGrid then
                self._CurrentSelectGrid:SetSelect(false)
            end

            grid:SetSelect(true)
            self.PropCardUi:Open()
            self.PropCardUi:Refresh(entity)
            self._CurrentSelectEntity = entity
            self._CurrentSelectGrid = grid
            self.BtnClose.gameObject:SetActiveEx(true)
            self.Parent:RefreshRedDot()
        end
    end
end

function XUiTheatre4HandbookProp:CheckCloseCard()
    if self.PropCardUi and self.PropCardUi:IsNodeShow() then
        self:_ClosePropCard()

        return true
    end

    return false
end

-- region 私有方法

function XUiTheatre4HandbookProp:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiTheatre4HandbookProp:_RefreshPropGridList()
    local itemEntitysList = self._Control.SystemControl:GetAllItemEntityList()

    for i, entitys in pairs(itemEntitysList) do
        local grid = self._PropGridList[i]

        if not grid then
            local gridObject = XUiHelper.Instantiate(self.PanelProp, self.PropContent)

            grid = XUiTheatre4HandbookPropGrid.New(gridObject, self)
            self._PropGridList[i] = grid
        end

        grid:Open()
        grid:Refresh(i, entitys)
    end
    for i = #itemEntitysList + 1, #self._PropGridList do
        self._PropGridList[i]:Close()
    end
end

function XUiTheatre4HandbookProp:_RefreshCount()
    local count, totalCount = self._Control.SystemControl:GetUnlockItemCountAndTotalCount()

    self.TxtNum.text = count
    self.TxtNumTotal.text = "/" .. totalCount
end

function XUiTheatre4HandbookProp:_InitUi()
    self.PanelProp.gameObject:SetActiveEx(false)
end

function XUiTheatre4HandbookProp:_ClosePropCard()
    self.PropCardUi:Close()
    self._CurrentSelectEntity = nil
    self.BtnClose.gameObject:SetActiveEx(false)
    if self._CurrentSelectGrid then
        self._CurrentSelectGrid:SetSelect(false)
        self._CurrentSelectGrid = nil
    end
end

-- endregion

return XUiTheatre4HandbookProp
