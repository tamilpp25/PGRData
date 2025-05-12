---@class XUiPanelTheatre4OutpostCommon : XUiNode
---@field private _Control XTheatre4Control
---@field BtnOption XUiComponent.XUiButton
---@field Parent XUiTheatre4Outpost
local XUiPanelTheatre4OutpostCommon = XClass(XUiNode, "XUiPanelTheatre4OutpostCommon")

function XUiPanelTheatre4OutpostCommon:OnStart()
    self.BtnSpecialOption.gameObject:SetActiveEx(false)
    self.BtnRedOption.gameObject:SetActiveEx(false)
    self.BtnOption.gameObject:SetActiveEx(true)
    self._Control:RegisterClickEvent(self, self.BtnOption, self.OnBtnOptionClick)
end

---@param gridData XTheatre4Grid 格子数据
function XUiPanelTheatre4OutpostCommon:Refresh(id, gridData)
    if not XTool.IsNumberValid(id) then
        XLog.Error("XUiPanelTheatre4OutpostCommon:Refresh error: id: " .. id)
        if gridData then
            XLog.Error(string.format("格子数据 Type:%s, State:%s, ContentGroup:%s, ContentId:%s", gridData:GetGridType(),
                gridData:GetGridState(), gridData:GetGridContentGroup(), gridData:GetGridContentId()))
        end
        return
    end
    self.Id = id
    self.GridData = gridData
    self:RefreshContent()
    self:RefreshBtn()
end

-- 刷新内容
function XUiPanelTheatre4OutpostCommon:RefreshContent()
    local title, content, desc = self:GetTitleContentDesc()
    self.TxtTitle.text = title
    self.TxtContent.text = content
    self.TxtDesc.text = desc
end

function XUiPanelTheatre4OutpostCommon:GetBtnName()
    if self.GridData:IsGridStateVisible() then
        return XUiHelper.GetText("Theatre4ExploreVisibleBtnName")
    end
    if not self._Control.AssetSubControl:CheckApEnough(true) then
        return XUiHelper.GetText("Theatre4NotExploreBtnName")
    end
    return XUiHelper.GetText("Theatre4ExploreBtnName")
end

-- 刷新按钮
function XUiPanelTheatre4OutpostCommon:RefreshBtn()
    local isBtnDisable = self.GridData:IsGridStateVisible() or not self._Control.AssetSubControl:CheckApEnough(true)
    local btnName = self:GetBtnName()
    local btn = self.BtnOption
    if btn then
        btn:SetNameByGroup(0, btnName)
        btn:SetDisable(isBtnDisable)
        self:RefreshCostActionPoint()
    else
        XLog.Error("[XUiPanelTheatre4OutpostCommon] RefreshBtn error: btn is nil")
    end
end

-- 刷新消耗的行动点
function XUiPanelTheatre4OutpostCommon:RefreshCostActionPoint()
    local btnOption = self.BtnOption
    local panelOption = XTool.InitUiObjectByUi({}, btnOption)
    local gridIcon = XTool.InitUiObjectByUi({}, panelOption.GridIcon)
    local apIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.ActionPoint)
    if apIcon then
        gridIcon.Icon:SetRawImage(apIcon)
    end
    -- 消耗行动点
    local apCost = XEnumConst.Theatre4.MapExploredCost
    gridIcon.Text.text = string.format("-%d", apCost)
    -- 刷新消耗文本颜色
    local isApEnough = self._Control.AssetSubControl:CheckApEnough(true)
    local index = isApEnough and 1 or 2
    local color = self._Control:GetClientConfig("AssetNotEnoughTextColor", index)
    if not string.IsNilOrEmpty(color) then
        gridIcon.Text.color = XUiHelper.Hexcolor2Color(color)
    end
end

-- 获取标题、内容、描述
function XUiPanelTheatre4OutpostCommon:GetTitleContentDesc()
    local title = ""
    local content = ""
    local desc = ""
    if self.GridData:IsGridTypeBox() then
        title = self._Control:GetBoxGroupTitle(self.Id)
        content = self._Control:GetBoxGroupTitleContent(self.Id)
        desc = self._Control:GetBoxGroupDesc(self.Id)
    elseif self.GridData:IsGridTypeShop() then
        title = self._Control:GetShopTitle(self.Id)
        content = self._Control:GetShopTitleContent(self.Id)
        desc = self._Control:GetShopUnOpenDesc(self.Id)
    elseif self.GridData:IsGridTypeEvent() then
        title = self._Control:GetEventTitle(self.Id)
        content = self._Control:GetEventTitleContent(self.Id)
        desc = self._Control:GetEventUnOpenDesc(self.Id)
    end
    return title, content, desc
end

function XUiPanelTheatre4OutpostCommon:OnBtnOptionClick()
    if not self.GridData then
        return
    end
    if self.GridData:IsGridStateVisible() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreVisibleTip"))
        return
    end
    if self.GridData:IsGridStateDiscover() then
        -- 检查行动点是否足够
        if not self._Control.AssetSubControl:CheckApEnough() then
            return
        end
    end
    self.Parent:ExploreGrid()
end

return XUiPanelTheatre4OutpostCommon
