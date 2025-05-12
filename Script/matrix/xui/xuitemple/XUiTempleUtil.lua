local XUiTempleUtil = {}

function XUiTempleUtil:UpdateDynamicItem(luaUi, gridArray, dataArray, uiObject, class, isGridClick)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, luaUi)
            gridArray[i] = grid
        end
        if isGridClick and grid.RegisterClick then
            grid:RegisterClick()
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiTempleUtil:ScrollTo(scrollView, gridList, index)

end

return XUiTempleUtil
