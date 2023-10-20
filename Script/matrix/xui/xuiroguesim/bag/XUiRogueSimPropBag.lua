---@class XUiRogueSimPropBag : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimPropBag = XLuaUiManager.Register(XLuaUi, "UiRogueSimPropBag")

function XUiRogueSimPropBag:OnAwake()
    self:RegisterUiEvents()
    self.GridProp.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimProp[]
    self.GridPropList = {}
    -- 信物格子
    self.GridToken = nil
end

function XUiRogueSimPropBag:OnEnable()
    self:RefreshToken()
    self:RefreshGridProp()
    -- 默认显示最上面
    if self.ScrollRect then
        self.ScrollRect.verticalNormalizedPosition = 1
    end
end

function XUiRogueSimPropBag:RefreshToken()
    local tokenId = self._Control:GetCurTokenId()
    if not XTool.IsNumberValid(tokenId) then
        return
    end
    if not self.GridToken then
        local go = XUiHelper.Instantiate(self.GridProp, self.Content)
        self.GridToken = XTool.InitUiObjectByUi({}, go)
    end
    self.GridToken.GameObject:SetActiveEx(true)
    self.GridToken.RImgProp:SetRawImage(self._Control:GetTokenIcon(tokenId))
    self.GridToken.TxtName.text = self._Control:GetTokenName(tokenId)
    self.GridToken.TxtDetail.text = self._Control:GetTokenEffectDesc(tokenId)
    self.GridToken.TxtStory.text = self._Control:GetTokenDesc(tokenId)
    local rare = self._Control:GetTokenRare(tokenId)
    self.GridToken.RImgBg:SetRawImage(self._Control.MapSubControl:GetPropRareIcon(rare))
end

function XUiRogueSimPropBag:RefreshGridProp()
    local propInfo = self._Control.MapSubControl:GetOwnPropInfo()
    -- 拥有数量
    self.TxtNum.text = #propInfo + 1
    for index, info in pairs(propInfo) do
        local grid = self.GridPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProp, self.Content)
            grid = require("XUi/XUiRogueSim/Common/XUiGridRogueSimProp").New(go, self)
            self.GridPropList[index] = grid
        end
        grid:Open()
        grid:Refresh(info.PropId, info.Id)
    end
    for i = #propInfo + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

function XUiRogueSimPropBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiRogueSimPropBag:OnBtnBackClick()
    self:Close()
end

return XUiRogueSimPropBag
