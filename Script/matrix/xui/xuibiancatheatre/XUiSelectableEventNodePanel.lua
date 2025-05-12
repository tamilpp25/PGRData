--######################## XUiSelectableEventNodePanel ########################
local XUiSelectableEventNodePanel = XClass(nil, "XUiSelectableEventNodePanel")

function XUiSelectableEventNodePanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    -- XASelectableEventNode
    self.Node = nil
    self.RootUi = rootUi
    -- 当前选择
    self.CurrentIndex = -1
end

-- node : XASelectableEventNode
function XUiSelectableEventNodePanel:SetData(node)
    self.Node = node
    -- 标题
    self.RootUi:ShowPanelTitle(node:GetTitle(), node:GetTitleContent())
    -- 事件描述
    self.TxtDesc.text = node:GetDesc()
    -- 刷新选项
    self:RefreshOptions()
    self.BtnOK:SetNameByGroup(0, node:GetBtnConfirmText())
    XUiHelper.RegisterClickEvent(self, self.BtnOK, self.OnBtnOKClicked)
end

function XUiSelectableEventNodePanel:OnBtnOKClicked()
    if self.CurrentIndex <= 0 then
        XUiManager.TipErrorWithKey("TheatreNotSelectItem")
        return
    end
    self.Node:RequestTriggerNode(function(newEventNode)
        self.RootUi:RefreshNode(newEventNode)
    end, self.Node:GetSelectableItems()[self.CurrentIndex]:GetOptionId())
end

function XUiSelectableEventNodePanel:RefreshOptions()
    self.BtnOption.gameObject:SetActiveEx(false)
    local child
    local childCount = self.PanelOption.transform.childCount
    for i = 0, childCount - 1 do
        child = self.PanelOption.transform:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    local items = self.Node:GetSelectableItems()
    local button, item
    local buttons = {}
    local count = nil
    for i = 1, #items do
        if i > childCount then
            child = XUiHelper.Instantiate(self.BtnOption, self.PanelOption.transform)
        else
            child = self.PanelOption.transform:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        button = child:GetComponent("XUiButton")
        table.insert(buttons, button)
        item = items[i]
        -- 描述1
        button:SetNameByGroup(0, item:GetDesc())
        -- 描述2
        button:SetNameByGroup(1, item:GetDownDesc())
        -- 图标数量
        count = item:GetItemCount()
        button:SetNameByGroup(2, count)
        button:SetButtonState(CS.UiButtonState.Normal)
        for i = 3, 5 do
            button.ImageList[i].gameObject:SetActiveEx(count ~= nil)
        end
        -- 图标
        local iconPath = item:GetIcon()
        for i = 0, button.RawImageList.Count - 1 do
            button.RawImageList[i].gameObject:SetActiveEx(iconPath ~= nil)
        end
        for i = 0, 2 do
            button.ImageList[i].gameObject:SetActiveEx(iconPath ~= nil)
        end
        if iconPath ~= nil then
            button:SetRawImage(item:GetIcon())
        end
    end
    self.PanelOption:Init(buttons, function(index)
        self.CurrentIndex = index
    end)
    self:CancelSelect()
end

function XUiSelectableEventNodePanel:CancelSelect()
    self.CurrentIndex = -1
    self.PanelOption:CancelSelect()
end

return XUiSelectableEventNodePanel