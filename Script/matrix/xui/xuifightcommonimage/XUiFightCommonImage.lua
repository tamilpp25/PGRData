local XUiFightCommonImage = XLuaUiManager.Register(XLuaUi, "UiFightCommonImage")

function XUiFightCommonImage:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
    end
end

function XUiFightCommonImage:OnEnable(configId)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    --设置图片
    self.RawImage:SetRawImage(XFightCommonImageConfigs.GetRawImagePath(configId))

    --设置位置
    local rectTransform = self.RawImage.gameObject:GetComponent("RectTransform")
    local posConfigX = XFightCommonImageConfigs.GetImageX(configId)
    local posConfigY = XFightCommonImageConfigs.GetImageY(configId)
    rectTransform.anchoredPosition = Vector2(posConfigX, posConfigY)

    --设置大小
    local widthConfig = XFightCommonImageConfigs.GetImageWidth(configId)
    local heightConfig = XFightCommonImageConfigs.GetImageHeight(configId)
    rectTransform.sizeDelta = Vector2(widthConfig, heightConfig)
    
    --是否显示背景图片
    local isShow = XFightCommonImageConfigs.GetIsShowBg(configId)
    if self.Image then
        self.Image.gameObject:SetActiveEx(isShow)
    end
    if self.Image2 then
        self.Image2.gameObject:SetActiveEx(isShow)
    end
    
    --是否显示mask
    self.Mask.gameObject:SetActiveEx(XFightCommonImageConfigs.GetIsShowMask(configId))
end

function XUiFightCommonImage:Close()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self.Super.Close(self)
end 