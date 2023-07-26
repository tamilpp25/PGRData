local XUiDormFieldGuideGridItem = XClass(nil, "XUiDormFieldGuideGridItem")

function XUiDormFieldGuideGridItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Btnclickcb = function() self:OnBtnClick() end
    XTool.InitUiObject(self)
    self.UiRoot:RegisterClickEvent(self.Transform, self.Btnclickcb)
end


function XUiDormFieldGuideGridItem:OnBtnClick()
    if not self.ItemData then
        return
    end

    self.UiRoot:OpenDesUI(self.ItemData)
end

-- 更新数据
function XUiDormFieldGuideGridItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData

    local curState = XDataCenter.FurnitureManager.IsFieldGuideHave(itemData.Id)
    self.ItemNotGet.gameObject:SetActive(not curState)

    local iconpath = itemData.Icon
    if iconpath then
        self.UiRoot:SetUiSprite(self.ImgIcon, iconpath)
    end

    self.TxtName.text = itemData.Name
end

return XUiDormFieldGuideGridItem