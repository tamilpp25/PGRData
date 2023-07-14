local XUiItemGrid = XClass(nil, "XUiItemGrid")

--黄金矿工通用道具格子
function XUiItemGrid:Ctor(ui, useItemCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UseItemCb = useItemCb
    XTool.InitUiObject(self)

    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.GameObject:SetActiveEx(true)
end

--itemColumn：XGoldenMinerItemData
function XUiItemGrid:Refresh(itemColumn)
    self.ItemColumn = itemColumn
    if not itemColumn then
        self:SetRImgIconActive(false)
        return
    end

    local itemId = itemColumn:GetItemId()
    local iconPath = XGoldenMinerConfigs.GetItemIcon(itemId)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(iconPath)
    end
    self:SetRImgIconActive(true)
end

function XUiItemGrid:SetUseItemActive(isActive)
    self.BtnClick.gameObject:SetActiveEx(isActive)
end

function XUiItemGrid:SetRImgIconActive(isActive)
    if self.RImgIcon then
        self.RImgIcon.gameObject:SetActiveEx(isActive)
    end
    if self.ImgNotItem then
        self.ImgNotItem.gameObject:SetActiveEx(not isActive)
    end
end

function XUiItemGrid:GetItemColumn()
    return self.ItemColumn
end

function XUiItemGrid:OnBtnClick()
    local itemColumn = self.ItemColumn
    local itemIndex = not XTool.IsTableEmpty(itemColumn) and itemColumn:GetGridIndex()
    if not itemIndex then
        return
    end

    --玩法中使用道具
    if self.UseItemCb then
        self.UseItemCb(self)
        return
    end
end

return XUiItemGrid