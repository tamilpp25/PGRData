---@class XUiConnectingLineGameGrid:XUiNode
local XUiConnectingLineGameGrid = XClass(XUiNode, "XUiConnectingLineGameGrid")

function XUiConnectingLineGameGrid:Ctor()
    self._Pos = { X = 0, Y = 0 }
    self._PosUid = 0
    self._IsConnected = true
    self._IsHole = false
end

function XUiConnectingLineGameGrid:SetPos(x, y, posUid)
    self._Pos.X = x
    self._Pos.Y = y
    self._PosUid = posUid
    self.Transform.name = x .. "/" .. y
end

function XUiConnectingLineGameGrid:Clear()
    self:SetPos(0, 0, 0)
end

function XUiConnectingLineGameGrid:GetPos()
    return self._Pos
end

function XUiConnectingLineGameGrid:GetPosUi()
    ---@type UnityEngine.RectTransform
    local rectTransform = self.Transform:GetComponent("RectTransform")
    local anchoredPosition = rectTransform.anchoredPosition
    return anchoredPosition.x, anchoredPosition.y
end

function XUiConnectingLineGameGrid:GetPosUid()
    return self._PosUid
end

function XUiConnectingLineGameGrid:SetConnected(value)
    if self._IsHole then
        return
    end
    if value ~= self._IsConnected then
        self.On.gameObject:SetActiveEx(value)
        self._IsConnected = value
    end
end

function XUiConnectingLineGameGrid:ResetAnimation()
    if self._IsConnected then
        ---@type UnityEngine.Playables.PlayableDirector
        local playableDirector = self.TipsLoop:GetComponent("PlayableDirector")
        playableDirector.time = 0
    end
end

function XUiConnectingLineGameGrid:SetColor(hexColor)
    ---@type UnityEngine.UI.RawImage
    local image = self.TipsLoop
    local color = XUiHelper.Hexcolor2Color(hexColor)
    image.color = color
end

--function XUiConnectingLineGameGrid:SetGridBg(img)
--    if self.Img then
--        self.Img:SetRawImage(img)
--    end
--end

function XUiConnectingLineGameGrid:SetIsHole(value)
    self._IsHole = value
    self.On.gameObject:SetActiveEx(value)
end

function XUiConnectingLineGameGrid:SetGridBg(gridBg)
    self.TipsLoop:SetSprite(gridBg)
end

--function XUiConnectingLineGameGrid:SetHeadBg(headBg)
--    self.HeadShang:SetSprite(headBg)
--end

return XUiConnectingLineGameGrid
