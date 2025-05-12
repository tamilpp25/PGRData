local XUiGridGuildPersonItem = XClass(nil, "XUiGridGuildPersonItem")

function XUiGridGuildPersonItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridGuildPersonItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiGridGuildPersonItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.CurId = itemdata.Id
    --构造体头像
    local path = XMVCA.XCharacter:GetCharacterEmotionIcon(itemdata.Id)
    self.ImgIcon:SetRawImage(path)
    --名字1
    self.TxtName1.text = XMVCA.XCharacter:GetCharacterTradeName(itemdata.Id)
    --名字2
    self.TxtName2.text = XMVCA.XCharacter:GetCharacterName(itemdata.Id)
    self.CurStatus = itemdata.Status or false
    self:SetSeleStatus(self.CurStatus)
end

function XUiGridGuildPersonItem:OnClickSeleStatus()
    self.CurStatus = not self.CurStatus
    self.ItemData.Status = self.CurStatus
    self:SetSeleStatus(self.CurStatus)
end

function XUiGridGuildPersonItem:SetSeleStatus(status)
    self.ImgSelect.gameObject:SetActiveEx(status)
    if status then
        self.UiRoot:RecordSeleId(self.CurId)
    else
        self.UiRoot:RemoveRecordSeleId(self.CurId)
    end
end

return XUiGridGuildPersonItem