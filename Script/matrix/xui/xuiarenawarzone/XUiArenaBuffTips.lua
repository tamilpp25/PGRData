local XUiArenaBuffTips = XLuaUiManager.Register(XLuaUi,"UiArenaBuffTips")

function XUiArenaBuffTips:OnStart(buffId)
    self:Refresh(buffId)
    self.BtnTanchuangCloseBig.CallBack = function() 
        self:Close()
    end
end

function XUiArenaBuffTips:OnEnable()

end

function XUiArenaBuffTips:OnDisable()

end

function XUiArenaBuffTips:Refresh(buffId)
    self.BuffId = buffId or self.BuffId
    if not self.BuffId then
        return
    end
    local buffCfg = XArenaConfigs.GetArenaBuffCfg(self.BuffId)
    self.RImgBuffPreview:SetRawImage(buffCfg.BuffBg)
    self.RImgBuffIcon:SetRawImage(buffCfg.Icon)
    self.TxtName.text = buffCfg.Name
    self.TxtDesc.text = buffCfg.Desc
end

return XUiArenaBuffTips