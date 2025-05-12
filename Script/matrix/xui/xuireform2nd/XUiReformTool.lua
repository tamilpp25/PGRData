local XUiReformTool = {}

function XUiReformTool.UpdateStar(ui, starAmount, starMax, extraStar)
    if not ui.UiStar then
        ui.UiStar = {}
        for i = 1, 5 do
            local uiStar = ui["ImgIcon" .. i]
            if uiStar then
                uiStar = uiStar.transform
            else
                uiStar = ui["Star" .. i]
            end
            if uiStar then
                ---@class XUiReformToolStar
                local star = {
                    Root = uiStar,
                    Enable = XUiHelper.TryGetComponent(uiStar, "Icon1", "RectTransform"),
                    Disable = XUiHelper.TryGetComponent(uiStar, "IconDis1", "RectTransform"),
                    Effect = XUiHelper.TryGetComponent(uiStar, "effect", "RectTransform"),
                }
                ui.UiStar[i] = star
            end
        end
    end
    --if not ui.UiStarExtra then
    --    ui.UiStarExtra = {
    --        Root = ui.ImgIcon5,
    --        Enable = XUiHelper.TryGetComponent(ui.ImgIcon5, "Icon1", "RectTransform"),
    --        Disable = XUiHelper.TryGetComponent(ui.ImgIcon5, "IconDis1", "RectTransform"),
    --        Effect = XUiHelper.TryGetComponent(ui.ImgIcon5, "effect", "RectTransform"),
    --    }
    --end
    for i = 1, #ui.UiStar do
        local star = ui.UiStar[i]
        if star then
            if i > starMax then
                star.Root.gameObject:SetActiveEx(false)
            else
                star.Root.gameObject:SetActiveEx(true)
                local enable = starAmount >= i
                XUiReformTool.SetStarEnable(star, enable)
            end
        end
    end
    --local star = ui.UiStarExtra
    --local enable = extraStar
    --XUiReformTool.SetStarEnable(star, enable)
end

function XUiReformTool.SetStarEnable(star, enable)
    star.Enable.gameObject:SetActiveEx(enable)
    star.Disable.gameObject:SetActiveEx(not enable)
    if star.Effect then
        star.Effect.gameObject:SetActive(enable)
    end
end

return XUiReformTool