--信物和其他道具布局的格子控件
local XUiGuidePropGrid = XClass(nil, "XUiGuidePropGrid")

function XUiGuidePropGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TokenManager = XDataCenter.TheatreManager.GetTokenManager()

    self:InitUi()
    self:SetButtonCallBack()
end

function XUiGuidePropGrid:Init(clickCb, isCurSelectTokenFunc)
    self.ClickCallback = clickCb
    self.IsCurSelectTokenFunc = isCurSelectTokenFunc
end

function XUiGuidePropGrid:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnGridBtnClick)
end

function XUiGuidePropGrid:InitUi()
    self.GridBtn = self.GameObject:GetComponent("XUiButton")
end

--token：XTheatreToken
function XUiGuidePropGrid:SetData(token)
    self.Token = token

    local isActive = self.TokenManager:IsActiveToken(token:GetId())
    self.ImgNormalLock.gameObject:SetActiveEx(not isActive)

    local icon = token:GetIcon()
    self.GridBtn:SetRawImage(icon)

    local isSelect = self.IsCurSelectTokenFunc(token)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)

    local qualityIcon = token:GetItemQualityIcon()
    self.GridBtn:SetSprite(qualityIcon)
end

function XUiGuidePropGrid:CancelSelect()
    self.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiGuidePropGrid:OnGridBtnClick()
    if self.ClickCallback then
        self.ClickCallback(self:GetToken(), self)
    end
    self.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiGuidePropGrid:GetToken()
    return self.Token
end

return XUiGuidePropGrid