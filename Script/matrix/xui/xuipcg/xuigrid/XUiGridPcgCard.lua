---@class XUiGridPcgCard : XUiNode
---@field private _Control XPcgControl
local XUiGridPcgCard = XClass(XUiNode, "XUiGridPcgCard")

function XUiGridPcgCard:OnStart()
    self.PanelSlay:GetObject("RImgTagIcon").gameObject:SetActiveEx(false)
    self.PanelNormal:GetObject("RImgTagIcon").gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiGridPcgCard:OnEnable()
    if self.IsAnimDisable then
        self:PlayAnimCardEnable()
    end
end

function XUiGridPcgCard:OnDisable()
    
end

function XUiGridPcgCard:OnDestroy()
    self:KillTween()
end

function XUiGridPcgCard:RegisterUiEvents()
    if self.InputHandler then
        self.InputHandler:AddPointerClickListener(function(eventData)
            if self.PointerClickCb then self.PointerClickCb(self.Idx, eventData) end
        end)
        self.InputHandler:AddPressListener(function(time)
            if self.PressCb then self.PressCb(self.Idx, time) end
        end)
        self.InputHandler:AddBeginDragListener(function(eventData)
            if self.BeginDragCb then self.BeginDragCb(self.Idx, eventData) end
        end)
        self.InputHandler:AddDragListener(function(eventData)
            if self.DragCb then self.DragCb(self.Idx, eventData) end
        end)
        self.InputHandler:AddEndDragListener(function(eventData)
            if self.EndDragCb then self.EndDragCb(self.Idx, eventData) end
        end)
        self.InputHandler:AddPointerUpListener(function(eventData)
            if self.PointerUpCb then self.PointerUpCb(self.Idx, eventData) end
        end)
    end
    self.PanelSlay:GetObject("TxtDetail").requestImage = XMVCA.XPcg.RichTextImageCallBack
    if not self.TxtDetail then
        self.TxtDetail = self.PanelPreview.transform:Find("TxtDetail"):GetComponent("XUiRichTextCustomRender") -- TODO 改预制体引用
    end
    self.TxtDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
end

-- 设置卡牌数据
function XUiGridPcgCard:SetCardData(cfgId, idx, parent, isDetailBrief, getTokenLayerFunc)
    self.CfgId = cfgId
    self.Idx = idx
    self.IsDetailBrief = isDetailBrief or false -- 卡牌详情是否简短
    self.GetTokenLayerFunc = getTokenLayerFunc
    local cardCfg = self._Control:GetConfigCards(self.CfgId)
    self.CardType = cardCfg.Type
    self.CardColor = cardCfg.Color
    if parent then
        self:SetParent(parent)
        self:SetLocalPosition(XLuaVector3.New(0, 0, 0))
    end
    self:Refresh()
end

-- 设置卡牌下标
function XUiGridPcgCard:ChangeIdx(idx, parent, isPosBack, cb)
    self.Idx = idx
    self:SetParent(parent)
    if isPosBack then
        self:PlayAnimBack(cb)
    end
end

-- 设置卡牌挂点
function XUiGridPcgCard:SetParent(parent)
    self.Transform:SetParent(parent, true)
end

-- 获取卡牌配置表Id
function XUiGridPcgCard:GetCfgId()
    return self.CfgId
end

-- 获取卡牌下标
function XUiGridPcgCard:GetIdx()
    return self.Idx
end

-- 获取卡牌类型
function XUiGridPcgCard:GetCardType()
    return self.CardType
end

-- 获取卡牌颜色
function XUiGridPcgCard:GetCardColor()
    return self.CardColor
end

-- 设置输入回调
function XUiGridPcgCard:SetInputCallBack(pointerClickCb, pressCb, beginDragCb, dragCb, endDragCb, pointerUpCb)
    self.PointerClickCb = pointerClickCb
    self.PressCb = pressCb
    self.BeginDragCb = beginDragCb
    self.DragCb = dragCb
    self.EndDragCb = endDragCb
    self.PointerUpCb = pointerUpCb
end

-- 设置当前行动的角色
function XUiGridPcgCard:SetCharacterType(characterType)
    self:RefreshTagIcon(characterType)
end

-- 设置选中
function XUiGridPcgCard:SetSelected(isSelected, isIgnoreAnim)
    self._IsSelected = isSelected
    self.ImgSelect.gameObject:SetActiveEx(self._IsSelected)

    local isAnim = not isIgnoreAnim
    if isAnim then
        if self._IsSelected then
            self:PlayAnimPop()
        else
            self:PlayAnimBack()
        end
    end
end

-- 获取本地坐标
function XUiGridPcgCard:GetLocalPosition()
    return self.Transform.localPosition
end

-- 设置本地坐标
function XUiGridPcgCard:SetLocalPosition(pos)
    self.Transform.localPosition = pos
end

-- 播放卡牌弹起动画
function XUiGridPcgCard:PlayAnimPop()
    self:KillTween()
    local SELECT_POSY = 20 -- 卡牌选中时Y轴的高度
    local pos =  XLuaVector3.New(0, SELECT_POSY, 0)
    self.Transform:DOLocalMove(pos, XEnumConst.PCG.ANIM_TIME_CARD_BACK / 1000)
end

-- 播放卡牌归位动画
function XUiGridPcgCard:PlayAnimBack(cb)
    self:KillTween()
    local pos = XLuaVector3.New(0, 0, 0)
    if not cb then
        self.Transform:DOLocalMove(pos, XEnumConst.PCG.ANIM_TIME_CARD_BACK / 1000)
    else
        self.Transform:DOLocalMove(pos, XEnumConst.PCG.ANIM_TIME_CARD_BACK / 1000):OnComplete(function()
            cb()
        end)
    end
end

-- 停止自身Tween函数
function XUiGridPcgCard:KillTween()
    self.Transform:DOKill(true)
end

-- 是否选中
function XUiGridPcgCard:IsSelected()
    return self._IsSelected == true
end

-- 刷新界面
function XUiGridPcgCard:Refresh()
    self.PanelNormal.gameObject:SetActiveEx(false)
    self.PanelSlay.gameObject:SetActiveEx(false)
    if self.CardColor == XEnumConst.PCG.COLOR_TYPE.WHITE then
        self:RefreshSlayCard()
    else
        self:RefreshNormalCard()
    end
end

-- 刷新普通卡
function XUiGridPcgCard:RefreshNormalCard()
    self.PanelNormal.gameObject:SetActiveEx(true)
    local cardCfg = self._Control:GetConfigCards(self.CfgId)
    local uiObj = self.PanelNormal
    local colorIcon = self._Control:GetClientConfig("CardColorIcons", cardCfg.Color)
    local suitIcon = self._Control:GetClientConfig("CardSuitIcons", cardCfg.Suit)
    local pointTxt = self._Control:GetClientConfig("CardPointTexts", cardCfg.Point)
    uiObj:GetObject("TxtNum1").text = pointTxt
    uiObj:GetObject("TxtNum2").text = pointTxt
    uiObj:GetObject("RImgSuit1"):SetRawImage(suitIcon)
    uiObj:GetObject("RImgSuit2"):SetRawImage(suitIcon)

    for _, colorType in pairs(XEnumConst.PCG.COLOR_TYPE) do
        local isShow = cardCfg.Color == colorType
        local bg = uiObj:GetObject("RImgBg"..colorType, false)
        if bg then
            bg.gameObject:SetActiveEx(isShow)
        end
        if isShow then
            uiObj:GetObject("RImgBall"..colorType):SetRawImage(colorIcon)
        end
    end
end

-- 刷新必杀卡
function XUiGridPcgCard:RefreshSlayCard()
    self.PanelSlay.gameObject:SetActiveEx(true)
    local cardCfg = self._Control:GetConfigCards(self.CfgId)
    local uiObj = self.PanelSlay
    local suitIcon = self._Control:GetClientConfig("CardSuitIcons", cardCfg.Suit)
    local pointTxt = self._Control:GetClientConfig("CardPointTexts", cardCfg.Point)
    uiObj:GetObject("TxtNum1").text = pointTxt
    uiObj:GetObject("TxtNum2").text = pointTxt
    uiObj:GetObject("RImgSuit1"):SetRawImage(suitIcon)
    uiObj:GetObject("RImgSuit2"):SetRawImage(suitIcon)

    -- 刷新卡牌图标
    if cardCfg.Type == XEnumConst.PCG.CARD_TYPE.SLAY then
        -- 角色头像
        local headIcon = self._Control:GetCardCharacterHeadIcon(cardCfg.Id)
        uiObj:GetObject("RImgCharacterHead"):SetRawImage(headIcon)
    elseif cardCfg.Type == XEnumConst.PCG.CARD_TYPE.DERIVATIVE then
        -- 卡牌图标
        uiObj:GetObject("RImgCharacterHead"):SetRawImage(cardCfg.CardIcon)
    end
    
    -- 技能名称
    uiObj:GetObject("TxtName").text = cardCfg.Name

    -- 技能描述
    local viewport = uiObj:GetObject("Viewport")
    viewport.raycastTarget = not self.IsDetailBrief
    local textDetail = uiObj:GetObject("TxtDetail")
    textDetail.raycastTarget = not self.IsDetailBrief
    local desc = cardCfg.Desc
    -- 处理\\n
    desc = XUiHelper.ReplaceTextNewLine(desc)
    -- 如文本包含<TokenId=8010|1>（表示读取场中Token8010的层数并显示，不存在8010时显示为默认值1）
    local headLen = string.len("<TokenId=")
    local endLen = string.len(">")
    for matchStr in string.gmatch(desc, "<TokenId=[^/].->") do
        local paramStr = string.sub(matchStr, headLen +1,  string.len(matchStr)- endLen)
        local params = string.Split(paramStr, "|")
        local val = tonumber(params[2])
        -- 需要外部传获取标记数量接口则需要调用接口，不然使用默认值
        if self.GetTokenLayerFunc then
            local layer = self.GetTokenLayerFunc(tonumber(params[1]))
            if layer > val then val = layer end
        end
        desc = string.gsub(desc, matchStr, val)
    end
    -- 简略描述裁剪超出部分
    if self.IsDetailBrief then
        local lengthStr = self._Control:GetClientConfig("CardBriefDetailLength")
        desc = XUiHelper.DeleteOverlengthStringSupportRichFormat(desc, tonumber(lengthStr), "...")
    end
    textDetail.text = desc
end

-- 刷新标签
function XUiGridPcgCard:RefreshTagIcon(characterType)
    local characterTypeCfg = self._Control:GetConfigCharacterType(characterType)
    local cardCfg = self._Control:GetConfigCards(self.CfgId)
    local tagIcon = characterTypeCfg.ColorTagIcons[cardCfg.Color]
    local haveTag = tagIcon and tagIcon ~= ""
    if haveTag then
        local isSlay = self.CardColor == XEnumConst.PCG.COLOR_TYPE.WHITE
        local uiObj = isSlay and self.PanelSlay or self.PanelNormal
        local rImgTagIcon = uiObj:GetObject("RImgTagIcon")
        rImgTagIcon:SetRawImage(tagIcon)
        rImgTagIcon.gameObject:SetActiveEx(true)
    end
end

-- 显示预览文本
function XUiGridPcgCard:ShowPreviewTxt(isShow, txt)
    self.PanelPreview.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtDetail.text = txt
        self.TxtDetail:ForcePopulateIcons()
    end
end

-- 播放显示动画
function XUiGridPcgCard:PlayAnimCardEnable()
    self:PlayAnimation("CardEnable")
    self.IsAnimDisable = false
end

-- 播放消融动画
function XUiGridPcgCard:PlayAnimCardDisable(cb)
    self:PlayAnimation("CardDisable", cb)
    self.IsAnimDisable = true
end

-- 播放翻牌动画
function XUiGridPcgCard:PlayAnimFlipCard()
    self:PlayAnimation("FlipCard")
end

return XUiGridPcgCard
