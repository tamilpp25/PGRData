local XUiDormFieldGuideListItem = XClass(nil, "XUiDormFieldGuideListItem")

function XUiDormFieldGuideListItem:Ctor(ui)
    self.ObjItems = {}
    self.CurItems = {}
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDormFieldGuideListItem:UpdateItems(itemData, haveids, isRefit, selectId)
    self.Id = itemData.Id
    local curState = haveids[itemData.Id] ~= nil
    self.ItemNotGet.gameObject:SetActive(not curState and not isRefit)

    local iconpath = itemData.Icon
    if iconpath then
        self.UiRoot:SetUiSprite(self.ImgIcon, iconpath)
    end

    self.TxtName.text = itemData.Name
    self.PanelCount.gameObject:SetActiveEx(isRefit)
    if isRefit then
        self.TxtOwnNum.text = XDataCenter.DormManager.GetOwnFurnitureCount(itemData.Id, true)
    end
    self:SetSelect(isRefit and selectId == itemData.Id)
end


function XUiDormFieldGuideListItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiDormFieldGuideListItem:OnRefresh(itemData, haveids, isRefit, selectId)
    if not itemData then
        return
    end

    self:UpdateItems(itemData, haveids, isRefit, selectId)
end

function XUiDormFieldGuideListItem:SetSelect(select)
    self.Select = select
    self.ItemSelect.gameObject:SetActiveEx(select)
end

return XUiDormFieldGuideListItem