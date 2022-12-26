local XUiGridCustomNameItem = XClass(nil, "XUiGridCustomNameItem")

function XUiGridCustomNameItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.BtnName.CallBack = function() self:OnBtnName() end
end

function XUiGridCustomNameItem:SetItemData(itemData)
    if not itemData then return end
    self.CustomData = itemData
    self.InputField.text = ""
    local rankName = XDataCenter.GuildManager.GetRankNameByLevel(self.CustomData.Id)
    self.InputField.placeholder.text = rankName
end

function XUiGridCustomNameItem:GetInputName()
    local inputName = self.InputField.text
    return tostring(inputName)
end

function XUiGridCustomNameItem:SetName(name)
    if self.InputField.placeholder.text ~= name then
        self.InputField.text = name
    else
        self.InputField.text = ""
    end
end

function XUiGridCustomNameItem:OnBtnName()
    local oldName = self.InputField.text == "" and self.InputField.placeholder.text or self.InputField.text 
    self.UiRoot:OpenNameSelectPanel(self.CustomData.Id, oldName)
end

return XUiGridCustomNameItem