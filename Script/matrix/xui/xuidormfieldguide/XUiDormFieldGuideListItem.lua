local XUiDormFieldGuideListItem = XClass(nil, "XUiDormFieldGuideListItem")

function XUiDormFieldGuideListItem:Ctor(ui)
    self.ObjItems = {}
    self.CurItems = {}
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDormFieldGuideListItem:UpdateItems(itemData, haveids)
    local curState = haveids[itemData.Id] ~= nil
    self.ItemNotGet.gameObject:SetActive(not curState)

    local iconpath = itemData.Icon
    if iconpath then
        self.UiRoot:SetUiSprite(self.ImgIcon, iconpath)
    end

    self.TxtName.text = itemData.Name
end


function XUiDormFieldGuideListItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiDormFieldGuideListItem:OnRefresh(itemData, haveids)
    if not itemData then
        return
    end

    self:UpdateItems(itemData, haveids)
end

return XUiDormFieldGuideListItem