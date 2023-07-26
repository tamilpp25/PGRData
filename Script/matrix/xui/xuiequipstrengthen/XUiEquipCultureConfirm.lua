--一键培养确认弹窗
local XUiEquipCultureConfirm = XLuaUiManager.Register(XLuaUi, "UiEquipCultureConfirm")

function XUiEquipCultureConfirm:OnAwake()
    self:AutoAddListener()

    self.GridAttackChange.gameObject:SetActiveEx(false)
end

function XUiEquipCultureConfirm:OnStart(equipId, originLevelUnit, targetLevelUnit, realTargetLevel, operations)
    self.EquipId = equipId
    self.TemplateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.EquipId)
    self.OriginLevelUnit = originLevelUnit
    self.TargetLevelUnit = targetLevelUnit
    self.RealTargetLevel = realTargetLevel
    self.Operations = operations
    self.GridCostItems = {}

    self:InitView()
end

function XUiEquipCultureConfirm:InitView()
    self.TxtTips.text = CsXTextManagerGetText("EquipMultiStrengthenTips")

    local templateId = self.TemplateId
    local breakthrough, level = XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(templateId, self.OriginLevelUnit)
    local targetBreakthrough, targetLevel =
        XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(templateId, self.TargetLevelUnit)
    local realTargetLevel = self.RealTargetLevel
    if not XTool.IsNumberValid(realTargetLevel) then
        realTargetLevel = targetLevel
    end

    --等级溢出提醒
    local isOver = realTargetLevel > targetLevel
    self.TxtTips.gameObject:SetActiveEx(isOver)
    self.ImgTips.gameObject:SetActiveEx(isOver)

    --等级，突破显示
    self.ImgBreachBefore:SetSprite(XEquipConfig.GetEquipBreakThroughIcon(breakthrough))
    self.ImgBreachAfter:SetSprite(XEquipConfig.GetEquipBreakThroughIcon(targetBreakthrough))
    self.TxtLv1.text = level
    self.TxtLv2.text = realTargetLevel

    local gridCount = 1

    --属性展示
    local attrMap = XDataCenter.EquipManager.ConstructTemplateEquipAttrMap(templateId, breakthrough, level)
    local newAttrMap = XDataCenter.EquipManager.ConstructTemplateEquipAttrMap(templateId, targetBreakthrough, realTargetLevel)
    for attrCount, attrInfo in pairs(attrMap) do
        local grid = self.GridCostItems[gridCount]
        if not grid then
            local ui = CSObjectInstantiate(self.GridAttackChange, self.PanelAttrParent)
            grid = XTool.InitUiObjectByUi({}, ui)
            self.GridCostItems[gridCount] = grid
        end

        grid.TxtName.text = attrInfo.Name
        grid.TxtCurLevel.text = attrInfo.Value
        local newAttrInfo = newAttrMap[attrCount]
        grid.TxtNextLevel.text = newAttrInfo.Value
        grid.GameObject:SetActiveEx(true)

        gridCount = gridCount + 1
    end

    --成长属性展示
    local promotedAttrMap = XDataCenter.EquipManager.ConstructTemplateEquipPromotedAttrMap(templateId, breakthrough)
    local newPromotedAttrMap = XDataCenter.EquipManager.ConstructTemplateEquipPromotedAttrMap(templateId, targetBreakthrough)
    for attrCount, attrInfo in pairs(promotedAttrMap) do
        local grid = self.GridCostItems[gridCount]
        if not grid then
            local ui = CSObjectInstantiate(self.GridAttackChange, self.PanelAttrParent)
            grid = XTool.InitUiObjectByUi({}, ui)
            self.GridCostItems[gridCount] = grid
        end

        grid.TxtName.text = CsXTextManagerGetText("EquipBreakThroughPopUpAttrPrefix", attrInfo.Name)
        grid.TxtCurLevel.text = attrInfo.Value
        local newAttrInfo = newPromotedAttrMap[attrCount]
        grid.TxtNextLevel.text = newAttrInfo.Value
        grid.GameObject:SetActiveEx(true)

        gridCount = gridCount + 1
    end
    for index, grid in pairs(self.GridCostItems) do
        self.GridCostItems[index].GameObject:SetActiveEx(index <= gridCount)
    end
end

function XUiEquipCultureConfirm:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnCloseMask.CallBack = handler(self, self.Close)
    self.BtnCancel.CallBack = handler(self, self.Close)
    self.BtnDetermine.CallBack = handler(self, self.OnClickBtnConfirm)
end

function XUiEquipCultureConfirm:OnClickBtnConfirm()
    local targetBreakthrough, targetLevelUnit = XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(self.TemplateId, self.TargetLevelUnit)
    XMVCA:GetAgency(ModuleId.XEquip):EquipOneKeyFeedRequest(self.EquipId, targetBreakthrough, targetLevelUnit, self.Operations)
    self:Close()
end
