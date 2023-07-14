local XUiGuildRoomTemplate = XLuaUiManager.Register(XLuaUi,"UiGuildRoomTemplate")

function XUiGuildRoomTemplate:OnStart(themeId)
    self.CurIndex = 1
    local themeCfg = XGuildDormConfig.GetThemeCfgById(themeId)
    self.ImgList = themeCfg.PreviewImageList
    self.TxtThemeName.text = themeCfg.Name
    self:InitButtonEvent()
    self:Refresh()
end

function XUiGuildRoomTemplate:InitButtonEvent()
    self.BtnTanchuangCloseWhite.CallBack = function()
        self:Close()
    end
    
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnLeft.CallBack = function()
        self:OnBtnLeftClick()
    end
    
    self.BtnRight.CallBack = function()
        self:OnBtnRightClick()
    end
end

function XUiGuildRoomTemplate:OnBtnLeftClick()
    self.CurIndex = self.CurIndex - 1
    if self.CurIndex < 1 then
        self.CurIndex = 1
    end
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiGuildRoomTemplate:OnBtnRightClick()
    self.CurIndex = self.CurIndex + 1
    if self.CurIndex > #self.ImgList then
        self.CurIndex = #self.ImgList
    end
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiGuildRoomTemplate:Refresh()
    local img = self.ImgList[self.CurIndex]
    if not string.IsNilOrEmpty(img) then
        self.RImgPreview:SetRawImage(img)
    end
    self.TxtImageCount.text = string.format("%d/%d", self.CurIndex, #self.ImgList)
end






return XUiGuildRoomTemplate