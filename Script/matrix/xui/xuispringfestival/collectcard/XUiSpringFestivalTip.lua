local XUiSpringFestivalTip = XLuaUiManager.Register(XLuaUi,"UiSpringFestivalTip")
function XUiSpringFestivalTip:OnStart(wordId)
    self.WordId = wordId
    self:RegisterButtonClick()
end

function XUiSpringFestivalTip:OnEnable()
    self:RefreshWordInfo()
end

function XUiSpringFestivalTip:RefreshWordInfo()
    local icon = XDataCenter.ItemManager.GetItemIcon(self.WordId)
    if icon and self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
    end
    
    local name = XDataCenter.ItemManager.GetItemName(self.WordId)
    if self.TxtName then
        self.TxtName.text = name
    end

    local func = function()
        local count = XDataCenter.ItemManager.GetCount(self.WordId)
        if self.TxtCount then
            self.TxtCount.text = count
        end
    end
    XDataCenter.ItemManager.AddCountUpdateListener(self.WordId,func,self.TxtCount)
    func()

    local desc = XDataCenter.ItemManager.GetItemDescription(self.WordId)
    if self.TxtDescription then
        self.TxtDescription.text = desc
    end

    local worldDesc = XDataCenter.ItemManager.GetItemWorldDesc(self.WordId)
    if self.TxtWorldDesc then
        self.TxtWorldDesc.text = worldDesc
    end
end

function XUiSpringFestivalTip:RegisterButtonClick()
    if self.BtnBack then
        XUiHelper.RegisterClickEvent(self,self.BtnBack,self.OnClickBtnBack)
    end
    if self.BtnGive then
        self.BtnGive.CallBack = function()
            self:OnClickBtnGive()
        end
    end
end

function XUiSpringFestivalTip:OnClickBtnBack()
    XLuaUiManager.Close("UiSpringFestivalTip")
end

function XUiSpringFestivalTip:OnClickBtnGive()
    XLuaUiManager.Open("UiSpringFestivalFriendTip",self.WordId)
end

return XUiSpringFestivalTip