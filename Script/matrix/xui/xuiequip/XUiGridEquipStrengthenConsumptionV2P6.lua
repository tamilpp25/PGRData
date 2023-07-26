local LongClickIntervel = 100
local AddCountPerPressTime = 1 / 150

local XUiGridEquipStrengthenConsumptionV2P6 = XClass(nil, "XUiGridEquipStrengthenConsumptionV2P6")

function XUiGridEquipStrengthenConsumptionV2P6:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.ItemGrid = XTool.InitUiObjectByUi({}, self.GridExpItem)
    self.EquipGrid = XTool.InitUiObjectByUi({}, self.GridEquip)
    self.ItemGrid.TxtLevel.gameObject:SetActiveEx(true)
    self.ItemGrid.BtnAdd.gameObject:SetActiveEx(true)
    self.EquipGrid.BtnAdd.gameObject:SetActiveEx(true)

    self.ItemGrid.BtnReduce.CallBack = function() self:OnClickBtnReduce() end
    self.EquipGrid.BtnReduce.CallBack = function() self:OnClickBtnReduce() end
    self.ItemGrid.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
    self.EquipGrid.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
    XUiButtonLongClick.New(self.ItemGrid.BtnReduce, LongClickIntervel, self, nil, self.OnLongClickBtnReduce, nil, true)
    XUiButtonLongClick.New(self.ItemGrid.BtnAdd, LongClickIntervel, self, nil, self.OnLongClickBtnAdd, nil, true)
end

function XUiGridEquipStrengthenConsumptionV2P6:Refresh(parent, index, consume)
    self.Parent = parent
    self.Index = index
    self.Consume = consume
    self.LongPressChangeCnt = 0

    local isEquip = consume:IsEquip()
    self.GridEquip.gameObject:SetActiveEx(isEquip)
    self.GridExpItem.gameObject:SetActiveEx(not isEquip)

    if isEquip then
        local templateId = consume.TemplateId
        local iconBagPath = XDataCenter.EquipManager.GetEquipIconBagPath(templateId)
        self.EquipGrid.RImgIcon:SetRawImage(iconBagPath)

        local qualityPath = XDataCenter.EquipManager.GetEquipQualityPath(templateId)
        self.EquipGrid.ImgEquipQuality:SetSprite(qualityPath)
        self.EquipGrid.TxtCount.text = "x1"
        self.EquipGrid.TxtLevel.text = consume:GetLevel()

        local isSelect = consume:IsSelect()
        self.EquipGrid.ImgSelectBg.gameObject:SetActiveEx(isSelect)
        self.EquipGrid.BtnReduce.gameObject:SetActiveEx(isSelect)
        self.EquipGrid.ImgTxtCount.gameObject:SetActiveEx(isSelect)

    elseif consume:IsItem() then
        local itemId = consume.TemplateId
        self.ItemGrid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))

        local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
        local qualityPath = XArrangeConfigs.GeQualityPath(quality)
        self.ItemGrid.ImgEquipQuality:SetSprite(qualityPath)

        self.ItemGrid.TxtCount.text = "x" .. consume.SelectCount
        self.ItemGrid.TxtLevel.text = consume:GetCount()

        local isSelect = consume:IsSelect()
        self.ItemGrid.ImgSelectBg.gameObject:SetActiveEx(isSelect)
        self.ItemGrid.BtnReduce.gameObject:SetActiveEx(isSelect)
        self.ItemGrid.ImgTxtCount.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridEquipStrengthenConsumptionV2P6:OnClickBtnReduce()
    self.Parent:OnReduceConsume(self.Index)
end

function XUiGridEquipStrengthenConsumptionV2P6:OnClickBtnAdd()
    self.Parent:OnAddConsume(self.Index)
end

function XUiGridEquipStrengthenConsumptionV2P6:OnLongClickBtnReduce(pressingTime)
    local changeCnt = math.floor(pressingTime * AddCountPerPressTime)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnClickBtnReduce()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

function XUiGridEquipStrengthenConsumptionV2P6:OnLongClickBtnAdd(pressingTime)
    local changeCnt = math.floor(pressingTime * AddCountPerPressTime)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnClickBtnAdd()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

return XUiGridEquipStrengthenConsumptionV2P6
