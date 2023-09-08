---@class XUiRiftPluginFilterTips : XLuaUi
local XUiRiftPluginFilterTips = XLuaUiManager.Register(XLuaUi, "UiRiftPluginFilterTips")

function XUiRiftPluginFilterTips:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnClickClose)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
    self:RegisterClickEvent(self.BtnClearTag, self.OnBtnClearTagClick)
end

function XUiRiftPluginFilterTips:OnStart(setting, closeCb)
    self._Btns = {}
    self._FilterData = {}
    self._CloseCb = closeCb
    self._Setting = setting

    local setting = XDataCenter.RiftManager:GetFilterSertting(setting)
    for _, type in pairs(XEnumConst.Rift.Filter) do
        self._FilterData[type] = {}
        for id, value in pairs(setting[type] or {}) do
            self._FilterData[type][id] = value
        end
    end

    local configs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftFilterTag)
    self:RefreshTemplateGrids(self.BtnFilterTagGrid1, XEnumConst.Rift.StarFilter, self.BtnFilterTagGrid1.parent, nil, "UiRiftPluginFilterTipsStar", function(grid, value)
        local title = XUiHelper.GetText("RiftPluginFilterTagName", value)
        self:InitFilterBtn(value, title, grid, XEnumConst.Rift.Filter.Star)
    end)
    self:RefreshTemplateGrids(self.BtnFilterTagGrid2, configs, self.BtnFilterTagGrid2.parent, nil, "UiRiftPluginFilterTipsTag", function(grid, value)
        local title = value.Name
        self:InitFilterBtn(value.Id, title, grid, XEnumConst.Rift.Filter.Tag)
    end)
end

function XUiRiftPluginFilterTips:InitFilterBtn(id, title, uiObject, filterType)
    local isSelect = self._FilterData[filterType][id]
    uiObject.TxtCategoryName.text = title
    uiObject.TxtCategoryNameSelect.text = title
    uiObject.PanelNormal.gameObject:SetActiveEx(not isSelect)
    uiObject.PanelSelect.gameObject:SetActiveEx(isSelect)
    if not self._Btns[filterType] then
        self._Btns[filterType] = {}
    end
    self._Btns[filterType][id] = { uiObject.PanelNormal, uiObject.PanelSelect }
    self:RegisterClickEvent(uiObject.BtnFilter, function()
        self:OnClick(id, filterType)
    end)
end

function XUiRiftPluginFilterTips:OnClick(id, filterType)
    local isSelect
    if self._FilterData[filterType][id] then
        self._FilterData[filterType][id] = nil
        isSelect = false
    else
        self._FilterData[filterType][id] = true
        isSelect = true
    end
    if filterType == XEnumConst.Rift.Filter.Star and id == 6 then
        -- 选6星时要同时选中7星的...
        if isSelect then
            self._FilterData[filterType][7] = true
        else
            self._FilterData[filterType][7] = nil
        end
    end
    self._Btns[filterType][id][1].gameObject:SetActiveEx(not isSelect)
    self._Btns[filterType][id][2].gameObject:SetActiveEx(isSelect)
end

function XUiRiftPluginFilterTips:OnBtnFilterClick()
    XDataCenter.RiftManager:SaveFilterSertting(self._Setting, self._FilterData)
    self:OnClickClose()
end

function XUiRiftPluginFilterTips:OnBtnClearTagClick()
    XDataCenter.RiftManager:SaveFilterSertting(self._Setting)
    self:OnClickClose()
end

function XUiRiftPluginFilterTips:OnClickClose()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end

return XUiRiftPluginFilterTips