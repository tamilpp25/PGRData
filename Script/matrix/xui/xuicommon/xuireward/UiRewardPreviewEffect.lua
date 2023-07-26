local XUiRewardPreviewEffect = XLuaUiManager.Register(XLuaUi, "UiRewardPreviewEffect")

function XUiRewardPreviewEffect:OnStart()
    local duration = 1.5
    if self.AnimEnable then
        duration = self.AnimEnable.duration
    end
    self:SetAutoCloseInfo(XTime.GetServerNowTimestamp() + duration, function (isClose)
        if isClose then
            self:Remove()
        end
    end, nil, 1)
end

return XUiRewardPreviewEffect