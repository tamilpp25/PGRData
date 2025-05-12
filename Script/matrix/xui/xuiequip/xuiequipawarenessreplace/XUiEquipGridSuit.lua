local XUiEquipGridSuit = XClass(nil, "XUiEquipGridSuit")

function XUiEquipGridSuit:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiEquipGridSuit:Init(rootUi)
    self.RootUi = rootUi
end

function XUiEquipGridSuit:Refresh(suitInfo, isSelect)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.UiButton:SetButtonState(state)
    self.UiButton.TempState = state

    local stateObjList = { self.Normal, self.Press, self.Select }
    local isAll = suitInfo.SuitId == XEnumConst.EQUIP.ALL_SUIT_ID
    if isAll then
        local suitName = XUiHelper.GetText("ScreenAll")
        local suitCnt = "x" .. suitInfo.Count
        for _, showObj in ipairs(stateObjList) do
            showObj:GetObject("ImgSuitIcon").gameObject:SetActiveEx(not isAll)
            showObj:GetObject("TxtSuitDesc").gameObject:SetActiveEx(not isAll)

            showObj:GetObject("TxtSuitName").text = suitName
            showObj:GetObject("TxtNumber").text = suitCnt
        end
    else
        local agency = XMVCA:GetAgency(ModuleId.XEquip)
        local suitName = agency:GetSuitName(suitInfo.SuitId)
        local suitCnt = "x" .. suitInfo.Count
        local iconPath = agency:GetEquipSuitIconPath(suitInfo.SuitId)
        local suitDesc = agency:GetSuitDescription(suitInfo.SuitId)
        local equipId = agency:GetSuitOneEquipId(suitInfo.SuitId)
        local qualityPath = agency:GetEquipQualityPath(equipId)
        for _, showObj in ipairs(stateObjList) do
            showObj:GetObject("ImgSuitIcon").gameObject:SetActiveEx(not isAll)
            showObj:GetObject("TxtSuitDesc").gameObject:SetActiveEx(not isAll)

            showObj:GetObject("TxtSuitName").text = suitName
            showObj:GetObject("TxtNumber").text = suitCnt
            showObj:GetObject("ImgSuitIcon"):SetSprite(iconPath)
            showObj:GetObject("TxtSuitDesc").text = suitDesc
            showObj:GetObject("ImgQuality"):SetSprite(qualityPath)
        end
    end
end

return XUiEquipGridSuit
