-- 角色筛选界面的的标签组
local XUiGridFilterTagGroup = XClass(nil, "XUiGridFilterTagGroup")

function XUiGridFilterTagGroup:Ctor(ui, rootUi, tagId, filterTagType, isSelected)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Id = tagId
    self.FilterTagType = filterTagType
    self.IsSelected = isSelected -- 是否选中

    self:AutoInit()
    XTool.InitUiObject(self)
    self:Refresh()
end

function XUiGridFilterTagGroup:GetId()
    return self.Id
end

-- 刷新当前显示的状态
function XUiGridFilterTagGroup:Refresh()
    self.PanelSelect.gameObject:SetActiveEx(self.IsSelected)
end

function XUiGridFilterTagGroup:AutoInit()
    self.Button = self.Transform:GetComponent("XUiButton")
    self.PanelSelect = self.Transform:Find("PanelSelect")
    self.TagName1 = self.Transform:Find("PanelNormal/TxtCategoryName"):GetComponent("Text")
    self.TagName2 = self.Transform:Find("PanelSelect/TxtCategoryNameSelect"):GetComponent("Text")
    self.Icon1 = self.Transform:Find("PanelNormal/Quality"):GetComponent("RawImage")
    self.Icon2 = self.Transform:Find("PanelSelect/Quality"):GetComponent("RawImage")

    local tagName = XRoomCharFilterTipsConfigs.GetFilterTagName(self.Id)
    self.TagName1.text = tagName
    self.TagName2.text = tagName

    self.Icon1:SetRawImage(XRoomCharFilterTipsConfigs.GetFilterTagUnSelectedIcon(self.Id))
    self.Icon2:SetRawImage(XRoomCharFilterTipsConfigs.GetFilterTagSelectedIcon(self.Id))

    XUiHelper.RegisterClickEvent(self, self.Button, self.OnTagClick)
end

function XUiGridFilterTagGroup:OnTagClick()
    self.IsSelected =  not self.IsSelected 
    -- 如果当前为选中状态则切换为未选中状态，反之
    self:Refresh()
    if self.RootUi:GetIsRadio() then
        self.RootUi:ClearAllTagClick(self.Id)
        self.RootUi:SetSelectRadioTagId(self.Id)
    end
    self.RootUi:OnTagClick(self.FilterTagType, XRoomCharFilterTipsConfigs.GetFilterTagValue(self.Id), self.IsSelected)
end

-- 取消选中
function XUiGridFilterTagGroup:CancelSelect()
    self.IsSelected = false
    self:Refresh()
    if self.RootUi:GetIsRadio() then
        self.RootUi:SetSelectRadioTagId(nil)
    end
    self.RootUi:OnTagClick(self.FilterTagType, XRoomCharFilterTipsConfigs.GetFilterTagValue(self.Id), self.IsSelected)
end

return XUiGridFilterTagGroup