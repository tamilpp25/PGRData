---@class XUiTemple2Map
local XUiTemple2Map = XClass(nil, "XUiTemple2Map")

---@param seed number
---@param pieces UnityEngine.UI.Image[]
---@param map UnityEngine.UI.GridLayoutGroup
function XUiTemple2Map:SetRandomMap(seed, pieces, map)
    if not seed then
        XLog.Error("[XUiTemple2Map] 地图随机种子为空")
        return
    end

    local piecesAmount = #pieces
    if piecesAmount <= 0 then
        XLog.Error("[XUiTemple2Map] 地图随机碎片为空")
        return
    end

    if not map then
        XLog.Error("[XUiTemple2Map] 地图ui为空")
        return
    end

    math.randomseed(seed)

    ---@type UnityEngine.RectTransform
    local rectTransform = map.transform
    local width = rectTransform.rect.width
    local height = rectTransform.rect.height

    local cellSize = map.cellSize
    local x = math.ceil(width / cellSize.x)
    local y = math.ceil(height / cellSize.y)
    local needAmount = x * y
    map.constraintCount = x

    local existPieceAmount = map.transform.childCount
    if needAmount > existPieceAmount then
        for i = 1, needAmount do
            if i > existPieceAmount then
                local index = math.random(1, piecesAmount)
                local piece = pieces[index]
                CS.UnityEngine.Object.Instantiate(piece.transform, piece.transform.parent)
            end
        end
    end
end

return XUiTemple2Map