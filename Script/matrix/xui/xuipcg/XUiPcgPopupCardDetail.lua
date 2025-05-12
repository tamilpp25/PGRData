---@class XUiPcgPopupCardDetail : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPopupCardDetail = XLuaUiManager.Register(XLuaUi, "UiPcgPopupCardDetail")

function XUiPcgPopupCardDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgPopupCardDetail:OnStart(cardId, characterId, isLeft, isHideBlackBg, getTokenLayerFunc)
    self.CardId = cardId
    self.CharacterId = characterId
    self.IsLeft = isLeft
    self.IsHideBlackBg = isHideBlackBg
    self.GetTokenLayerFunc = getTokenLayerFunc
end

function XUiPcgPopupCardDetail:OnEnable()
    self:Refresh()
end

function XUiPcgPopupCardDetail:OnDisable()
    
end

function XUiPcgPopupCardDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiPcgPopupCardDetail:OnBtnCloseClick()
    self:Close()
end

-- 刷新界面
function XUiPcgPopupCardDetail:Refresh()
    -- 设置位置
    local parent = self.IsLeft and self.PosLeft or self.PosCenter
    self.PanelCard.transform:SetParent(parent)
    self.PanelCard.transform.localPosition = XLuaVector3.New(0, 0, 0)

    -- 是否显示黑色背景
    self.RImgBlackBg.gameObject:SetActiveEx(not self.IsHideBlackBg)

    -- 卡牌详情
    if not self.GridPcgCard then
        local XUiGridPcgCard = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCard")
        ---@type XUiGridPcgCard
        self.GridPcgCard = XUiGridPcgCard.New(self.UiPcgGridCard, self)
    end
    self.GridPcgCard:SetCardData(self.CardId, nil, nil, nil, self.GetTokenLayerFunc)
    
    -- 普通卡牌伤害
    local cardCfg = self._Control:GetConfigCards(self.CardId)
    local isShowBall = cardCfg.Color ~= XEnumConst.PCG.COLOR_TYPE.WHITE and self.CharacterId
    self.GridBall.gameObject:SetActiveEx(isShowBall)
    if isShowBall then
        local characterCfg = self._Control:GetConfigCharacter(self.CharacterId)
        local colorBallDesc = { characterCfg.RedBallDesc, characterCfg.BlueBallDesc, characterCfg.YellowBallDesc }
        local colorIcons = self._Control:GetClientConfigParams("CardColorIcons")
        local colorNames = self._Control:GetClientConfigParams("CardColorNames")
        local icon = colorIcons[cardCfg.Color]
        self.GridBall:GetObject("RImgBall"):SetRawImage(icon)
        self.GridBall:GetObject("TxtName").text = colorNames[cardCfg.Color]
        local txtDetail = self.GridBall:GetObject("TxtDetail")
        txtDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
        txtDetail.text = colorBallDesc[cardCfg.Color]
    end

    -- Tokens
    self:RefreshTokens(cardCfg.TokenIds)
end

-- 刷新标记
function XUiPcgPopupCardDetail:RefreshTokens(tokenIds)
    local item = self.UiPcgGridEffectDetail
    item.gameObject:SetActiveEx(false)
    self.GridTokens = self.GridTokens or {}
    for _, grid in ipairs(self.GridTokens) do
        grid:Close()
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridPcgToken = require("XUi/XUiPcg/XUiGrid/XUiGridPcgToken")
    for i, tokenId in ipairs(tokenIds) do
        ---@type XUiGridPcgToken
        local grid = self.GridTokens[i]
        if not grid then
            local go = CSInstantiate(item, item.transform.parent)
            grid = XUiGridPcgToken.New(go, self)
            table.insert(self.GridTokens, grid)
        end
        grid:Open()
        grid:SetData(tokenId)
    end
end

return XUiPcgPopupCardDetail
