---@class XUiGridSGBuffItem : XUiNode
---@field _Control XSkyGardenCafeControl
local XUiGridSGBuffItem = XClass(XUiNode, "XUiGridSGBuffItem")

function XUiGridSGBuffItem:OnStart(buffListId)
    self._BuffListId = buffListId
    local listener = self.GameObject:GetComponent("XUguiEventListener")
    if listener then
        listener.OnDown = function() 
            self:OnBuffDown()
        end

        listener.OnUp = function()
            self:OnBuffUp()
        end
    end
    self:RefreshView()
end

function XUiGridSGBuffItem:RefreshView()
    if not self._BuffListId or self._BuffListId <= 0 then
        return
    end
    local id = self._BuffListId
    local icon = self._Control:GetBuffListIcon(id)
    if not string.IsNilOrEmpty(icon) then
        if self.ImgBuff then
            self.ImgBuff:SetSprite(icon)
        elseif self.RImgBuff then
            self.RImgBuff:SetRawImage(icon)
        end
    end
    self.PanelBubble.gameObject:SetActiveEx(false)
    self.PanelNum.gameObject:SetActiveEx(false)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._Control:GetBuffListDesc(id))
end

function XUiGridSGBuffItem:OnBuffDown()
    self.PanelBubble.gameObject:SetActiveEx(true)
end

function XUiGridSGBuffItem:OnBuffUp()
    self.PanelBubble.gameObject:SetActiveEx(false)
end

return XUiGridSGBuffItem