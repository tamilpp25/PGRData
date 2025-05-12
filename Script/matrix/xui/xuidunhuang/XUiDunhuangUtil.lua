local XUiDunhuangUtil = {}

---@param control XDunhuangControl
local function GetUiPaintingByIndex(ui, index, control)
    local uiPainting = ui.UiPaintings[index]
    if not uiPainting then
        uiPainting = XUiHelper.Instantiate(ui.ImgMaterial, ui.ImgMaterial.transform.parent)
        ui.UiPaintings[#ui.UiPaintings + 1] = uiPainting

        ---@type XUiComponent.XUiButton
        local button = XUiHelper.TryGetComponent(uiPainting.transform, "", "XUiButton")
        if button then
            XUiHelper.RegisterClickEvent(ui, button, function()
                local uiData = control:GetUiData()
                local paintingToDraw = uiData.PaintingToDraw
                local data = paintingToDraw[index]
                control:SetSelectedPaintingOnGame(data)
            end)
        end
    end
    return uiPainting
end

---@param ui XUiDunhuangEdit
---@param control XDunhuangControl
function XUiDunhuangUtil.UpdateDraw(ui, control)
    local uiData = control:GetUiData()
    local paintingToDraw = uiData.PaintingToDraw
    for i = 1, #paintingToDraw do
        local data = paintingToDraw[i]
        local uiPainting = GetUiPaintingByIndex(ui, i, control)
        ---@type UnityEngine.RectTransform
        local rectTransform = uiPainting.rectTransform
        rectTransform.anchoredPosition = Vector2(data.X, data.Y)
        uiPainting:SetRawImage(data.Icon)
        uiPainting.gameObject:SetActiveEx(true)

        rectTransform.sizeDelta = Vector2(data.OriginalWidth, data.OriginalHeight)
        rectTransform.localEulerAngles = Vector3(0, 0, data.Rotation)

        local scale = rectTransform.localScale
        scale.x = data.Scale
        scale.y = data.Scale
        if data.FlipX == 1 then
            scale.x = -math.abs(scale.x)
            rectTransform.localScale = scale
        else
            scale.x = math.abs(scale.x)
            rectTransform.localScale = scale
        end

        if data.IsOnTop then
            uiPainting.transform:SetSiblingIndex(uiPainting.transform.parent.childCount - 1)
        end
    end

    for i = #paintingToDraw + 1, #ui.UiPaintings do
        local uiPainting = ui.UiPaintings[i]
        uiPainting.gameObject:SetActiveEx(false)
    end
end

return XUiDunhuangUtil