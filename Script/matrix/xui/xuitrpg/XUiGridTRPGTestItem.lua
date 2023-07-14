local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridTRPGTestItem = XClass(nil, "XUiGridTRPGTestItem")

function XUiGridTRPGTestItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)
end

function XUiGridTRPGTestItem:InitClickCb(clickCb)
    self.BtnClick.CallBack = clickCb
end

function XUiGridTRPGTestItem:Refresh(itemId, actionId)
    self.ItemId = itemId

    if XTRPGConfigs.CheckDefaultEffectItemId(itemId) then

        local desc = XTRPGConfigs.GetExamineActionTypeDefaultItemDesc(actionId)
        self.BtnClick:SetNameByGroup(0, desc)

        local desc1 = ""
        self.BtnClick:SetNameByGroup(1, desc1)

        local icon = XTRPGConfigs.GetExamineActionIcon(actionId)
        self.BtnClick:SetRawImage(icon)

    else

        local desc = XTRPGConfigs.GetItemParamDesc(itemId)
        self.BtnClick:SetNameByGroup(0, desc)

        local curNum = XDataCenter.ItemManager.GetCount(itemId)
        local maxNum = XDataCenter.TRPGManager.GetItemMaxCount(itemId)
        local desc1 = curNum .. "/" .. maxNum
        self.BtnClick:SetNameByGroup(1, desc1)

        local icon = XItemConfigs.GetItemIconById(itemId)
        self.BtnClick:SetRawImage(icon)

        local isDis = XDataCenter.ItemManager.GetCount(itemId) <= 0
        self.BtnClick:SetDisable(isDis)

    end
end

function XUiGridTRPGTestItem:SetSelect(value)
    local itemId = self.ItemId
    local isDis = not XTRPGConfigs.CheckDefaultEffectItemId(itemId) and XDataCenter.ItemManager.GetCount(itemId) <= 0

    if value then
        self.BtnClick:SetButtonState(isDis and CS.UiButtonState.Disable or CS.UiButtonState.Select)
    else
        self.BtnClick:SetButtonState(isDis and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end

end

return XUiGridTRPGTestItem