--- 涂装筛选界面能量筛选面板
---@class XUiPanelFilterElement: XUiNode
local XUiPanelFilterElement = XClass(XUiNode, 'XUiPanelFilterElement')

function XUiPanelFilterElement:OnStart(fliterTagList, defaultSelectTags)
    self.PanelDataOwn.gameObject:SetActiveEx(false)

    self._FliterTagList = fliterTagList

    self._SelectedTags = defaultSelectTags or {}

    self:Init()
end

function XUiPanelFilterElement:Init()
    if not XTool.IsTableEmpty(self._FliterTagList) then
        XUiHelper.RefreshCustomizedList(self.PanelDataOwn.transform.parent, self.PanelDataOwn, #self._FliterTagList, function(index, go)
            local tagId = self._FliterTagList[index].TagId
            local btn = go:GetComponent(typeof(CS.XUiComponent.XUiButton))

            btn:SetNameByGroup(0, XRoomCharFilterTipsConfigs.GetFilterTagName(tagId))
            
            btn.CallBack = function()
                self:OnTagGridClick(tagId, btn)
            end

            local isSelect = self._SelectedTags[tagId]
            btn:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
            btn:SetRawImage(isSelect and XRoomCharFilterTipsConfigs.GetFilterTagSelectedIcon(tagId) or XRoomCharFilterTipsConfigs.GetFilterTagUnSelectedIcon(tagId))
        end)
    end
end

function XUiPanelFilterElement:GetSelectedTags()
    return self._SelectedTags
end

function XUiPanelFilterElement:OnTagGridClick(tag, btn)
    if self._SelectedTags[tag] then
        self._SelectedTags[tag] = nil
    else
        self._SelectedTags[tag] = true
    end

    local isSelect = self._SelectedTags[tag]
    btn:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    btn:SetRawImage(isSelect and XRoomCharFilterTipsConfigs.GetFilterTagSelectedIcon(tag) or XRoomCharFilterTipsConfigs.GetFilterTagUnSelectedIcon(tag))

    self.Parent:RefreshCharacterListShow()
end


return XUiPanelFilterElement