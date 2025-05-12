---@class XUiBlackRockChessBattleShop : XLuaUi 局内商店
---@field _Control XBlackRockChessControl
local XUiBlackRockChessBattleShop = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessBattleShop")

local BuyMode = 1
local SellMode = 2

function XUiBlackRockChessBattleShop:OnAwake()
    self.BtnMask.CallBack = handler(self,self.OnBtnMaskClick)
    self.BtnView.CallBack = handler(self, self.OnBtnViewClick)
    self.BtnStart.CallBack = handler(self, self.OnBtnStartClick)
    self.BtnSetting.CallBack = handler(self, self.OnBtnSettingClick)
    self.BtnRefresh.CallBack = handler(self, self.OnBtnRefreshClick)
    self.BtnPullDown.CallBack = handler(self, self.OnBtnPullDownClick)
    self.BtnSell.CallBack = handler(self, self.OnSwitchToSell)
    self.BtnBuy.CallBack = handler(self, self.OnSwitchToBuy)
end

function XUiBlackRockChessBattleShop:OnStart()
    local shopId = self._Control:GetShopInfo():GetShopId()
    self._ShopCfg = self._Control:GetBattleShopById(shopId)
    self._CoinIcon = self._Control:GetClientConfig("CoinIcon")
    
    self._Grids = {}
    self:SetUiSprite(self.ImgIcon, self._CoinIcon)
    self.TxtTitle.text = self._ShopCfg.Name

    self.BtnPullDown:SetButtonState(XUiButtonState.Normal)
    self.PanelShop.gameObject:SetActiveEx(true)
    self._IsShowShop = true

    -- 开始布局
    CS.XBlackRockChess.XBlackRockChessManager.Instance.Partner:SetIsLayout(true)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SELECT_PARTNER, self.OpenPieceTip, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_EXIT_MOVE, self.CloseGoodsTip, self)
end

function XUiBlackRockChessBattleShop:OnEnable()
    self:OnSwitchToBuy()
    self:CloseGoodsTip()
    self._Control:SwitchCameraToDown()
end

function XUiBlackRockChessBattleShop:OnDestroy()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SELECT_PARTNER, self.OpenPieceTip, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_EXIT_MOVE, self.CloseGoodsTip, self)
end

function XUiBlackRockChessBattleShop:OnGetEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_EXIT_MOVE,
    }
end

function XUiBlackRockChessBattleShop:OnNotify(evt, ...)
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_EXIT_MOVE then
        self:CloseGoodsTip()
    end
end

function XUiBlackRockChessBattleShop:UpdateView()
    self._IsMoneyEnough = false

    if self._Mode == BuyMode then
        self:ShowBuyShop()
    else
        self:ShowSellShop()
    end

    self.BtnSell.gameObject:SetActiveEx(self._Mode == BuyMode)
    self.BtnBuy.gameObject:SetActiveEx(self._Mode == SellMode)

    local isSellDisable = self._Control:GetChessPartner():IsPreparePieceEmpty()
    self.BtnSell:SetButtonState(isSellDisable and XUiButtonState.Disable or XUiButtonState.Normal)

    local myCoinCount = self._Control:GetShopInfo():GetCoin()
    local isEnough = myCoinCount >= self._ShopCfg.RefreshCost
    local isLimit = self._Control:GetShopInfo():GetRefreshTimes() >= self._ShopCfg.RefreshLimit
    local isDisable = not isEnough or isLimit
    self.TxtNum.text = myCoinCount
    self.BtnRefresh:SetNameByGroup(0, self._ShopCfg.RefreshCost)
    self.BtnRefresh:SetSprite(self._CoinIcon)
    self.BtnRefresh:SetButtonState(isDisable and XUiButtonState.Disable or XUiButtonState.Normal)
end

function XUiBlackRockChessBattleShop:ShowBuyShop()
    local myCoinCount = self._Control:GetShopInfo():GetCoin()
    local goodses = self._Control:GetShopInfo():GetGoods()
    XUiHelper.RefreshCustomizedList(self.GridGoods.parent, self.GridGoods, #goodses, function(idx, go)
        local data = goodses[idx]
        local goodsId = data.GoodsId
        local count = data.Count
        local grid = {}
        XUiHelper.InitUiClass(grid, go)
        local shop = self._Control:GetBattleShopGoodById(goodsId)
        if shop.GoodsType == XEnumConst.BLACK_ROCK_CHESS.GOOD_TYPE.PIECE then
            local piece = self._Control:GetPartnerPieceById(shop.GoodsId)
            grid.RImgGoods:SetRawImage(piece.HeadIcon)
            grid.TxtName.text = piece.Name
            grid.TagUp.gameObject:SetActiveEx(self._Control:IsPartnerLevelUp(shop.GoodsId) and count > 0)
            grid.ListStar.gameObject:SetActiveEx(true)
            XUiHelper.RefreshCustomizedList(grid.ListStar, grid.GridStar, piece.Level)
        else
            local buff = self._Control:GetBuffConfig(shop.GoodsId)
            grid.RImgGoods:SetRawImage(buff.Icon)
            grid.TxtName.text = buff.Name
            grid.TagUp.gameObject:SetActiveEx(false)
            grid.ListStar.gameObject:SetActiveEx(false)
        end
        if count == 0 then
            grid.BtnSellOut.gameObject:SetActiveEx(true)
            grid.BtnBuy.gameObject:SetActiveEx(false)
            grid.BtnSellOut.CallBack = function()
                XUiManager.TipError(XUiHelper.GetText("BlackRockChessShopSellOutTip"))
            end
        else
            grid.BtnSellOut.gameObject:SetActiveEx(false)
            grid.BtnBuy.gameObject:SetActiveEx(true)
            grid.BtnBuy:SetNameByGroup(0, shop.Price)
            grid.BtnBuy:SetSprite(self._CoinIcon)
            grid.BtnBuy:SetButtonState(myCoinCount >= shop.Price and XUiButtonState.Normal or XUiButtonState.Disable)
            grid.BtnBuy.CallBack = function()
                self:BuyPiece(idx, shop.GoodsType, shop.GoodsId, shop.Price)
            end
        end
        grid.BtnGoods.CallBack = function()
            self:OpenGoodsTip(shop.GoodsId, shop.GoodsType)
        end
        if myCoinCount >= shop.Price then
            self._IsMoneyEnough = true
        end
        grid.BtnSell.gameObject:SetActiveEx(false)
    end)
    self.BtnRefresh.gameObject:SetActiveEx(true)
end

function XUiBlackRockChessBattleShop:ShowSellShop()
    local datas = self._Control:GetChessPartner():GetAllPreparePieces()
    XUiHelper.RefreshCustomizedList(self.GridGoods.parent, self.GridGoods, #datas, function(idx, go)
        local grid = {}
        local data = datas[idx]
        local piece = self._Control:GetPartnerPieceById(data.PieceId)
        XUiHelper.InitUiClass(grid, go)
        grid.RImgGoods:SetRawImage(piece.HeadIcon)
        grid.TxtName.text = piece.Desc
        grid.TagUp.gameObject:SetActiveEx(false)
        grid.BtnSellOut.gameObject:SetActiveEx(false)
        grid.BtnBuy.gameObject:SetActiveEx(false)
        grid.BtnSell.gameObject:SetActiveEx(true)
        grid.TagLayout.gameObject:SetActiveEx(data.IsLayout)
        grid.BtnSell:SetNameByGroup(0, string.format("+%s", piece.RecyclePrice))
        grid.BtnSell:SetSprite(self._CoinIcon)
        grid.BtnSell.CallBack = function()
            if data.IsLayout then
                self._Control:AutoPartnerLayout2Site(data.Guid, data.PieceId)
            end
            self._Control:RequestBlackRockChessRecyclePiece(data.Guid, handler(self, self.UpdateView))
            self:CloseGoodsTip()
        end
        grid.BtnGoods.CallBack = function()
            self:OpenPieceTip(data.PieceId, nil, false, true)
        end
        XUiHelper.RefreshCustomizedList(grid.ListStar, grid.GridStar, piece.Level)
    end)
    self.BtnRefresh.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattleShop:OpenGoodsTip(id, goodsType)
    if goodsType == XEnumConst.BLACK_ROCK_CHESS.GOOD_TYPE.PIECE then
        self:OpenPieceTip(id, nil, false, true)
    else
        self:OpenBuffTip(id)
    end
end

function XUiBlackRockChessBattleShop:CloseGoodsTip()
    self.PanelBuffDetail.gameObject:SetActiveEx(false)
    self.PanelEnemyDetails.gameObject:SetActiveEx(false)
    self.BtnMask.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattleShop:OpenBuffTip(id)
    self:CloseGoodsTip()
    if not self._BuffDetail then
        self._BuffDetail = {}
        XUiHelper.InitUiClass(self._BuffDetail, self.PanelBuffDetail)
    end
    local config = self._Control:GetBuffConfig(id)
    self._BuffDetail.TxtDetail.text = config.Desc
    self.PanelBuffDetail.gameObject:SetActiveEx(true)
    self.BtnMask.gameObject:SetActiveEx(true)
end

function XUiBlackRockChessBattleShop:OpenPieceTip(id, guid, isShowDown, isOpen)
    if self.PanelBuffDetail.gameObject.activeSelf then
        self:CloseGoodsTip()
    end
    if not self.PanelEnemyDetails.gameObject.activeSelf and not isOpen then
        return
    end
    self.PanelEnemyDetails.gameObject:SetActiveEx(true)
    if not self._PieceDetail then
        self._PieceDetail = {}
        XUiHelper.InitUiClass(self._PieceDetail, self.PanelEnemyDetails)
        self._PieceDetail.BtnClose.CallBack = handler(self, self.CloseGoodsTip)
        self._PieceDetail.Head = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadCommon").New(self._PieceDetail.GridHead, self, XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER)
    end
    self._PieceDetail.BtnDown.CallBack = function()
        self._Control:AutoPartnerLayout2Site(guid, id, true)
        self:CloseGoodsTip()
    end
    ---@type XUiGridHeadCommon
    local headCommon = self._PieceDetail.Head
    local config = self._Control:GetPartnerPieceById(id)
    headCommon:RefreshShopPieceView(id)
    self._PieceDetail.TxtName.text = config.Name
    self._PieceDetail.TxtDetails.text = config.Desc
    self._PieceDetail.TxtNum.text = config.MaxLife
    self._PieceDetail.BtnDown.gameObject:SetActiveEx(isShowDown)
    if guid and self._IsShowShop then
        self:OnBtnPullDownClick()
    end
end

function XUiBlackRockChessBattleShop:OnBtnMaskClick()
    self:CloseGoodsTip()
end

function XUiBlackRockChessBattleShop:OnBtnViewClick()
    self._Control:SwitchCamera()
end

function XUiBlackRockChessBattleShop:OnBtnStartClick()
    --是否有冲突棋子
    local partnerPieces = self._Control:GetChessPartner():GetPreparePieceInfoDict()
    for _, piece in pairs(partnerPieces) do
        if self._Control:GetChessEnemy():IsOverlap(piece) then
            XUiManager.TipError(XUiHelper.GetText("BlackRockChessShopCloseClashTip"))
            return
        end
    end
    --上阵棋子数量超过限制
    local layoutPieces = self._Control:GetChessPartner():GetLayoutDict()
    if XTool.GetTableCount(layoutPieces) > self._Control:GetCurNodeCfg().PartnerPieceLimit then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessPrepareMoreTip"))
        return
    end
    if self._IsMoneyEnough and not self._IgnoreMoneyEnough then
        local title = XUiHelper.GetText("BlackRockChessShopCloseCoinTip")
        local sureText = XUiHelper.GetText("BlackRockChessTipBtnText2")
        local closeText = XUiHelper.GetText("BlackRockChessTipBtnText1")
        XLuaUiManager.Open("UiBlackRockChessTip", title, sureText, function()
            self._IgnoreMoneyEnough = true
            self:OnBtnStartClick()
        end, closeText)
        return
    end

    local sites = self._Control:GetChessPartner():GetPrepareBattleSite()
    if XTool.GetTableCount(sites) > 0 then
        local title = XUiHelper.GetText("BlackRockChessShopClosePieceTip")
        local sureText = XUiHelper.GetText("BlackRockChessTipBtnText4")
        local closeText = XUiHelper.GetText("BlackRockChessTipBtnText3")
        XLuaUiManager.Open("UiBlackRockChessTip", title, sureText, handler(self, self.RequestBlackRockChessFinishShop), closeText, function()
            self._Control:GetChessPartner():TryAutoGoIntoBattle()
            self:RequestBlackRockChessFinishShop()
        end)
        return
    end
    
    self:RequestBlackRockChessFinishShop()
end

function XUiBlackRockChessBattleShop:RequestBlackRockChessFinishShop()
    self._Control:RequestBlackRockChessPartnerLayout(function()
        self._Control:RequestBlackRockChessFinishShop(function()
            self._Control:SwitchCameraToNormal()
            self:Close()
        end)
    end)
end

function XUiBlackRockChessBattleShop:OnBtnSettingClick()
    XLuaUiManager.Open("UiBlackRockChessSetUp")
end

function XUiBlackRockChessBattleShop:OnBtnRefreshClick()
    if self._Control:GetShopInfo():GetRefreshTimes() >= self._ShopCfg.RefreshLimit then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessShopRefreshTip"))
        return
    end
    if self.BtnRefresh.ButtonState == XUiButtonState.Disable then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessCoinTip"))
        return
    end
    self._Control:RequestBlackRockChessRefreshGoods(handler(self, self.UpdateView))
end

function XUiBlackRockChessBattleShop:OnBtnPullDownClick()
    self._IsShowShop = not self._IsShowShop
    self.PanelShop.gameObject:SetActiveEx(self._IsShowShop)
end

function XUiBlackRockChessBattleShop:BuyPiece(idx, goodsType, goodsId, goodsPrice)
    if goodsType == XEnumConst.BLACK_ROCK_CHESS.GOOD_TYPE.PIECE then
        local limit = self._Control:GetPrapareBattleSiteCount()
        local used = self._Control:GetBuyPartnerPieceCount()
        if used >= limit then
            local isLevelUp = self._Control:IsPartnerLevelUp(goodsId)
            if not isLevelUp then
                XUiManager.TipError(XUiHelper.GetText("BlackRockChessPrepareLimitTip"))
                return
            end
        end
    end

    local myCoinCount = self._Control:GetShopInfo():GetCoin()
    if myCoinCount < goodsPrice then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessCoinTip"))
        return
    end

    self._Control:RequestBlackRockChessBuyGoods(idx, 1, handler(self, self.UpdateView))
end

function XUiBlackRockChessBattleShop:OnSwitchToSell()
    if self._Control:GetChessPartner():IsPreparePieceEmpty() then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessSellPiece"))
        return
    end
    self._Mode = SellMode
    self:UpdateView()
end

function XUiBlackRockChessBattleShop:OnSwitchToBuy()
    self._Mode = BuyMode
    self:UpdateView()
end

return XUiBlackRockChessBattleShop