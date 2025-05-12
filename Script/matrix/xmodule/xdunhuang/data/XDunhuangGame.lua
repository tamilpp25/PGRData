---@class XDunhuangGame
local XDunhuangGame = XClass(nil, "XDunhuangGame")

function XDunhuangGame:Ctor()
    ---@type XDunhuangPainting[]
    self._Paintings = {}
end

function XDunhuangGame:GetPaintings()
    return self._Paintings
end

---@param painting XDunhuangPainting
function XDunhuangGame:InsertPainting(painting)
    local isOnPaint, index = self:IsOnPaint(painting)
    if isOnPaint then
        if index ~= #self._Paintings then
            local paintingOnTop = table.remove(self._Paintings, index)
            self._Paintings[#self._Paintings + 1] = paintingOnTop
            return true
        end
        return false
    end
    painting:ClearDataOnGame()
    self._Paintings[#self._Paintings + 1] = painting
    return true
end

function XDunhuangGame:IsOnPaint(painting)
    for i = 1, #self._Paintings do
        local imageOnPaint = self._Paintings[i]
        if imageOnPaint:Equals(painting) then
            return true, i
        end
    end
    return false
end

function XDunhuangGame:RemovePainting(paintingToRemove)
    for i = 1, #self._Paintings do
        local painting = self._Paintings[i]
        if painting:Equals(paintingToRemove) then
            table.remove(self._Paintings, i)
            break
        end
    end
end

function XDunhuangGame:ClearPaintings()
    self._Paintings = {}
end

function XDunhuangGame:SetPaintings(paintings)
    self._Paintings = paintings
end

return XDunhuangGame
