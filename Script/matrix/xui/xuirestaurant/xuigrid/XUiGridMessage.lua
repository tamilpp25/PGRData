
---@class XUiGridChatLocation : XUiNode
---@field _Control XRestaurantControl
---@field Parent XUiRestaurantPopupChat | XUiRestaurantPopupStory
local XUiGridChatLocation = XClass(XUiNode, "XUiGridChatLocation")

function XUiGridChatLocation:Refresh(isShow, talkId, index)
    if not isShow then
        self:Close()
        return
    end
    self:Open()
    local business = self._Control:GetBusiness()
    local template = business:GetTalkTemplate(talkId)
    
    self.StandIcon:SetRawImage(template.Icon)
    self.TxtName.text = template.Nickname
    self.TxtChat.text = self.Parent:GetTalkMessage(talkId)
end


---@class XUiGridMessage : XUiNode
---@field _Control XRestaurantControl
local XUiGridMessage = XClass(XUiNode, "XUiGridMessage")

local LocationType = {
    Left = 1,
    Right = 2
}

function XUiGridMessage:OnStart()
    self.PanelLeft = XUiGridChatLocation.New(self.PanelLeft, self.Parent)
    self.PanelRight = XUiGridChatLocation.New(self.PanelRight, self.Parent)
end

function XUiGridMessage:Refresh(talkId, index)
    local business = self._Control:GetBusiness()
    local template = business:GetTalkTemplate(talkId)
    local isShowRight = template.Type == LocationType.Right
    self.PanelLeft:Refresh(not isShowRight, talkId, index)
    self.PanelRight:Refresh(isShowRight, talkId, index)
end

return XUiGridMessage