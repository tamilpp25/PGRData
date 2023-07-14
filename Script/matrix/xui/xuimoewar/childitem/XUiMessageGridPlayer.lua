--local handler = handler

local XUiMessageGridPlayer = XClass(nil, "XUiMessageGridPlayer")

function XUiMessageGridPlayer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)

    --self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
end

function XUiMessageGridPlayer:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiMessageGridPlayer:UpdateData(playerId)
    if not playerId or playerId == self.PlayerId then return end
    if XTool.UObjIsNil(self.GameObject) then return end
    self.Entity = XDataCenter.MoeWarManager.GetPlayer(playerId)
    self.Id = self.Entity.Id
    self:Refresh(playerId)
end

function XUiMessageGridPlayer:Refresh(playerId)
    self.PlayerId = playerId

    self.TxtName.text = self.Entity:GetName()
    self.TxtGroup.text = self.Entity:GetGroupName()
    self.RImgHeadIcon:SetRawImage(self.Entity:GetSquareHead())
end

function XUiMessageGridPlayer:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

function XUiMessageGridPlayer:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb(self.PlayerId)
    end
end

return XUiMessageGridPlayer