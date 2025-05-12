---@class XUiReformListHead : XUiNode
---@field _Control XReformControl
local XUiReformListHead = XClass(XUiNode, "XUiReformListHead")

function XUiReformListHead:OnStart()
    self._IsHardMode = nil
end

---@param data XUiReformListHeadData
function XUiReformListHead:Update(characterId)
    local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    self.StandIcon:SetRawImage(icon)
end

function XUiReformListHead:Switch(isHardMode)
    if isHardMode ~= self._IsHardMode then
        self._IsHardMode = isHardMode
        if isHardMode then
            self:PlayAnimation("Red")
        else
            self:PlayAnimation("Green")
        end
    end
end

return XUiReformListHead