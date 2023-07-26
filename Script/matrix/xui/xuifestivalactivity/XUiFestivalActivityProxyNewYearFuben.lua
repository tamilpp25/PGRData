local XUiFestivalActivityProxyNewYearFuben = XClass(nil, "XUiFestivalActivityProxyNewYearFuben")

function XUiFestivalActivityProxyNewYearFuben:GetTimeFormatType()
    return XUiHelper.TimeFormatType.ACTIVITY_NEW_YEAR_FUBEN
end

function XUiFestivalActivityProxyNewYearFuben:GetScrollOffsetX(ui)
    local viewPortRectTransform = XUiHelper.TryGetComponent(ui.PanelStageContent.parent,"","RectTransform")
    local left = viewPortRectTransform.offsetMin.x
    return left
end

return XUiFestivalActivityProxyNewYearFuben