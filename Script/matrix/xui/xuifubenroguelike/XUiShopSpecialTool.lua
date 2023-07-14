local XUiShopSpecialTool = XClass(nil, "XUiShopSpecialTool")

function XUiShopSpecialTool:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    -- if self.BtnSpecialTool then
    --     self.BtnSpecialTool.CallBack = function() self:OnBtnSpecialToolClick() end
    -- end
end

function XUiShopSpecialTool:SetSpecialTool(itemId)
    if not itemId then
        self.GameObject:SetActiveEx(false)
        return
    end
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)

    if self.RImgSpecialTool then
        self.RImgSpecialTool.gameObject:SetActiveEx(true)
        self.RImgSpecialTool:SetRawImage(itemIcon)
    end

    if self.TxtSpecialTool then
        self.TxtSpecialTool.text = itemCount
    end

    if self.TxtXdcs then
        self.TxtXdcs.gameObject:SetActiveEx(false)
    end
end

function XUiShopSpecialTool:SetSpecialToolNum(num)
    if self.TxtSpecialTool then
        self.TxtSpecialTool.text = num
    end

    if self.TxtXdcs then
        self.TxtXdcs.gameObject:SetActiveEx(true)
    end

    if self.RImgSpecialTool then
        self.RImgSpecialTool.gameObject:SetActiveEx(false)
    end
end

-- function XUiShopSpecialTool:OnBtnSpecialToolClick()
-- end
return XUiShopSpecialTool