
---@class XUiGridHeadCommon : XUiNode
---@field _Control XBlackRockChessControl
local XUiGridHeadCommon = XClass(XUiNode, "XUiGridHeadCommon")

local MAX_HP_GRID = 10

local MAX_HP_COUNT = 8 --血条最大数量

local CsClamp01 =  CS.UnityEngine.Mathf.Clamp01

local CsTween = CS.DG.Tweening

local PreviewAlphaMin = 0.1
local PreviewAlphaMax = 0.8

local PreviewDuration = 0.2

local KingType = CS.XBlackRockChess.XChessPieceType.King:GetHashCode()

function XUiGridHeadCommon:OnStart()
    self.RImgAttack = self.RImgMove.transform.parent:Find("RImgAttack")
    if self.RImgAttack then
        self.RImgAttack.gameObject:SetActiveEx(false)
    end
    --self.ImgHpBar1Bg.fillAmount = 1

    self.PreviewAlpha = self._Control:GetPreviewIconAlpha()
    
    self:InitEffect()

    self.PanelBoss = self.PanelBoss or self.Transform:Find("PanelBoss")
    if self.PanelBoss then
        self.PanelBoss.gameObject:SetActiveEx(false)
    end
end

function XUiGridHeadCommon:SetPieceType(pieceType)
    self._PieceType = pieceType or XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY
end

function XUiGridHeadCommon:InitEffect()
    if not self.RImgHead then
        return
    end
    local parent = self.RImgHead.transform.parent
    self.EffectSmoke = parent:FindTransform("PanelEffectSmoke")
    self.EffectBlood = parent:FindTransform("PanelEffectBlood")
    self.EffectLight = parent:FindTransform("PanelEffectLight")
end


function XUiGridHeadCommon:OnDisable()
    if self._Seq then
        self._Seq:Kill()
        self._Seq = nil
    end
end

function XUiGridHeadCommon:RefreshView(pieceId)
    self.PieceId = pieceId or self.PieceId
    if not XTool.IsNumberValid(self.PieceId) then
        return
    end
    local pieceInfo = self:GetPiece()
    if not pieceInfo then
        self:Close()
        return
    end
    
    local configId = pieceInfo:GetConfigId()
    self.GameObject.name = "GridHead" .. tostring(self.PieceId)
    self._ConfigId = configId
    if self.EffectLight then
        self.EffectSmoke.gameObject:SetActiveEx(pieceInfo:GetPieceType() == KingType)
    end

    self:PreviewDamage(0)

    local isPiece = pieceInfo:IsPiece() or pieceInfo:IsPartner()
    self.RImgHead.gameObject:SetActiveEx(isPiece)
    self.TxtUnknown.gameObject:SetActiveEx(not isPiece)
    if isPiece then
        self.RImgHead:SetRawImage(self._Control:GetPieceHeadIconByType(configId, self._PieceType))
        self.CanvasGroup.alpha = 1.0
    else
        self.CanvasGroup.alpha = self.PreviewAlpha
    end
    
    local attack = false
    if isPiece then
        attack = pieceInfo:IsPrepareAttack()
    end
    local moveCd = pieceInfo:IsEnemyPreview() and pieceInfo:GetReinforceCd() or pieceInfo:GetMoveCd()
    local isMove = moveCd <= 0
    self.RImgMove.gameObject:SetActiveEx(isMove and not attack)
    self.TxtLeftRound.gameObject:SetActiveEx(not isMove and not attack)
    self.RImgAttack.gameObject:SetActiveEx(attack)
    self.TxtLeftRound.text = moveCd
    if self.EffectLight then
        self.EffectLight.gameObject:SetActiveEx(attack)
    end

    local buffIds = self._Control:GetPieceBuffIdsByType(configId, self._PieceType)
    local buffId = buffIds[1]
    local hasBuff = XTool.IsNumberValid(buffId)
    self.PanelBuff.gameObject:SetActiveEx(hasBuff)
    if hasBuff then
        self.RImgBuff:SetRawImage(self._Control:GetBuffIcon(buffId))
    end

    if self.TxtMoveCd then
        local desc
        -- 友方棋子预告
        if pieceInfo:IsPartnerPreview() then
            local bornCd = self._Control:GetPartnerPieceBornCd(pieceInfo:GetConfigId())
            local cd = bornCd - self._Control:GetChessRound() + 1
            desc = string.format(self._Control:GetPieceMoveCdText(4), cd)
        elseif isPiece then
            if attack then
                desc = self._Control:GetPieceMoveCdText(3)
            elseif isMove then
                desc = self._Control:GetPieceMoveCdText(1)
            else
                desc = string.format(self._Control:GetPieceMoveCdText(2), moveCd)
            end

            local icon = self._Control:GetPieceHeadIconByType(configId, self._PieceType)
            self.RImgHead:SetRawImage(icon)
        else
            desc = string.format(self._Control:GetPieceMoveCdText(4), moveCd)
        end

        self.TxtMoveCd.text = desc
    end

    if self.TxtDetails then
        -- 友方棋子
        if pieceInfo:IsPartner() then
            self.TxtDetails.text = self._Control:GetPartnerPieceDesc(pieceInfo:GetConfigId())
        else
            self.TxtDetails.text = pieceInfo:GetBuffDesc(buffId)
        end
    end

    if self.TxtDetails2 then
        local config = self._Control:GetHandbookChessConfigByIndex(self._PieceType)
        self.TxtDetails2.text = config.Desc
    end

    if self.TxtName then
        self.TxtName.text = self._Control:GetPieceDescByType(configId, self._PieceType)
    end

    if self.TxtHp then
        self.TxtHp.text = pieceInfo:GetHp()
    end

    if self.ImgStar then
        if self._PieceType == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER then
            local starCount = self._Control:GetPartnerPieceById(configId).Level
            XUiHelper.RefreshCustomizedList(self.ImgStar.parent, self.ImgStar, starCount)
        else
            XUiHelper.RefreshCustomizedList(self.ImgStar.parent, self.ImgStar, 0)
        end
    end

    self:SetTarget(false)
end

function XUiGridHeadCommon:RefreshPartnerPrepareView(pieceId)
    self.PieceId = pieceId or self.PieceId
    local pieceInfo = self._Control:GetChessPartner():GetPieceInfo(pieceId)
    if not pieceInfo then
        return
    end
    
    local configId = pieceInfo:GetConfigId()
    self:RefreshShopPieceView(configId)

    if self._Control:GetChessPartner():IsPassPreparationStage() then
        self.PanelMove.gameObject:SetActiveEx(true)
        local moveCd
        if pieceInfo:IsEnemyPreview() then
            moveCd = pieceInfo:GetReinforceCd()
        elseif pieceInfo:IsPartnerPreview() then
            moveCd = pieceInfo:GetPartnerBornCd()
        else
            moveCd = pieceInfo:GetMoveCd()
        end
        local attack = pieceInfo:IsPrepareAttack()
        local isMove = moveCd <= 0
        self.RImgMove.gameObject:SetActiveEx(isMove and not attack)
        self.TxtLeftRound.gameObject:SetActiveEx(not isMove and not attack)
        self.RImgAttack.gameObject:SetActiveEx(attack)
        self.TxtLeftRound.text = moveCd
    end
end

--- 显示处于备战栏和上阵状态中的友方棋子的信息
function XUiGridHeadCommon:RefreshShopPieceView(pieceConfigId)
    local partnerConfig = self._Control:GetPartnerPieceById(pieceConfigId)
    self.EffectSmoke.gameObject:SetActiveEx(false)
    self.RImgHead.gameObject:SetActiveEx(true)
    self.TxtUnknown.gameObject:SetActiveEx(false)
    self.RImgHead:SetRawImage(self._Control:GetPieceHeadIconByType(pieceConfigId, self._PieceType))
    self.CanvasGroup.alpha = 1.0
    self.PanelMove.gameObject:SetActiveEx(false)
    self.EffectLight.gameObject:SetActiveEx(false)
    self.PanelBuff.gameObject:SetActiveEx(false)
    self:SetTarget(false)
    if self._Control:GetChessPartner():IsPassPreparationStage() then
        self:PreviewDamage(0)
    else
        self:PreviewHp(partnerConfig.MaxLife, partnerConfig.MaxLife)
    end
    self.EffectBlood.gameObject:SetActiveEx(false)
    XUiHelper.RefreshCustomizedList(self.ImgStar.parent, self.ImgStar, partnerConfig.Level)
end

function XUiGridHeadCommon:RefreshBossView(bossId)
    if bossId then
        self.BossId = bossId
    end
    local charCfg = self._Control:GetCharacterConfig(self.BossId)
    self.RImgHead:SetRawImage(charCfg.CircleIcon)

    self.GameObject.name = "GridHead" .. tostring(self.BossId)
    self.PanelBuff.gameObject:SetActiveEx(false)
    self.PanelMove.gameObject:SetActiveEx(false)
    self.EffectSmoke.gameObject:SetActiveEx(false)
    self.EffectBlood.gameObject:SetActiveEx(false)
    self.EffectLight.gameObject:SetActiveEx(false)
    self.PanelHp = self.PanelHp or self.Transform:Find("PanelHp")
    self.PanelHp.gameObject:SetActiveEx(false)
    self.PanelHead = self.PanelHead or self.Transform:Find("PanelHead")
    self.PanelHead.gameObject:SetActiveEx(false)
    self.PanelStar = self.PanelStar or self.Transform:Find("PanelStar")
    self.PanelStar.gameObject:SetActiveEx(false)
    self.PanelBoss = self.PanelBoss or self.Transform:Find("PanelBoss")
    self.PanelBoss.gameObject:SetActiveEx(false)
    
    -- 显示移动/攻击 示意图
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    if bossInfo and bossInfo:IsAlive() then
        self.PanelBoss.gameObject:SetActiveEx(true)
        self.TxtBossLeftRound = self.TxtBossLeftRound or self.Transform:Find("PanelBoss/TxtLeftRound")
        self.TxtBossLeftRound.gameObject:SetActiveEx(false)
        
        local isAttack = bossInfo:IsExitSkillDelay()
        self.RImgBossAttack.gameObject:SetActiveEx(isAttack)
        self.RImgBossMove.gameObject:SetActiveEx(not isAttack)
    else
        self.PanelBoss.gameObject:SetActiveEx(false)
    end
end

function XUiGridHeadCommon:SetTarget(state)
    state = state and true or false
    self.ImgTarget.gameObject:SetActiveEx(state)
end

function XUiGridHeadCommon:PreviewDamage(damage)
    local curHp, leftHp = 0, 0
    local piece = self:GetPiece()
    if piece then
        curHp = piece:GetHp()
        leftHp = math.max(0, curHp - damage)
    end
    local boss = self:GetBoss()
    if boss then
        curHp = boss:GetHp()
        leftHp = math.max(0, curHp - damage)
    end

    self.PanelDead.gameObject:SetActiveEx(leftHp <= 0)
    if piece then
        piece:SetPreviewDead(leftHp <= 0)
    end
    if self.EffectBlood then
        self.EffectBlood.gameObject:SetActiveEx(curHp <= 0)
    end
    
    self:PreviewHp(curHp, curHp - damage)
end

function XUiGridHeadCommon:PreviewHp(curHp, leftHp)
    if self._Seq then
        self._Seq:Pause()
    end

    local isDead = leftHp <= 0
    self.PanelDead.gameObject:SetActiveEx(isDead)
    self.ImgHpBarTop.gameObject:SetActiveEx(true)
    local colors = self._Control:GetClientConfigValues("EmenyHpColor")
    local colorCount = #colors
    local isDamage = curHp ~= leftHp

    -- 当前血条
    local barIndex = math.ceil(leftHp / colorCount)
    if isDamage and leftHp % MAX_HP_GRID == 0 then
        barIndex = barIndex + 1
        self.ImgHpBarTop.gameObject:SetActiveEx(false)
    end

    -- 当前血条
    local left = self._Control:GetGridValueByHp(leftHp, MAX_HP_GRID)
    local color
    if leftHp <= 0 then
        color = colors[1]
    elseif barIndex % colorCount == 0 then
        color = colors[colorCount]
    else
        color = colors[barIndex]
    end
    self.ImgHpBarTop.fillAmount = CsClamp01(left / MAX_HP_GRID)
    self.ImgHpBarTop.color = XUiHelper.Hexcolor2Color(color)

    -- 底下血条
    local isShowBottom = barIndex > 1
    self.ImgHpBarButtom.gameObject:SetActiveEx(isShowBottom)
    self.ImgMask.gameObject:SetActiveEx(isShowBottom)
    if isShowBottom then
        local colorIndex = (barIndex - 1) % colorCount
        if colorIndex == 0 then
            colorIndex = colorCount
        end
        self.ImgHpBarButtom.color = XUiHelper.Hexcolor2Color(self._Control:GetClientConfig("EmenyHpColor", colorIndex))
        self.ImgHpBarButtom.fillAmount = 1
    end

    -- 预览伤害闪烁效果
    self.ImgHpBarPreview.gameObject:SetActiveEx(isDamage)
    if isDamage then
        local previewProgress = curHp % MAX_HP_GRID / MAX_HP_GRID
        -- 已死亡
        if isDead then
            previewProgress = curHp / MAX_HP_GRID
        -- 当前血条消耗完，开始消耗下一血条
        elseif math.ceil(curHp) ~= math.ceil(leftHp) then
            previewProgress = 1
        end
        
        self.ImgHpBarPreview.fillAmount = previewProgress
        self.ImgHpBarPreview.color = XUiHelper.Hexcolor2Color(color)
        if not self._Seq then
            self._Seq = CsTween.DOTween.Sequence()
            self._Seq:Append(self.ImgHpBarPreview:DOFade(PreviewAlphaMin, PreviewDuration):SetEase(CsTween.Ease.Flash))
            self._Seq:Append(self.ImgHpBarPreview:DOFade(PreviewAlphaMax, PreviewDuration):SetEase(CsTween.Ease.Flash))
            self._Seq:SetLoops(-1)
        end
        self._Seq:Play()
    end
end

---@return XBlackRockChessPiece
function XUiGridHeadCommon:GetPiece()
    if self:IsEnemy() then
        return self._Control:GetChessEnemy():GetPieceInfo(self.PieceId)
    end
    return self._Control:GetChessPartner():GetPieceInfo(self.PieceId)
end

---@return XChessBoss
function XUiGridHeadCommon:GetBoss()
    return self._Control:GetChessEnemy():GetBossInfo(self.BossId)
end

function XUiGridHeadCommon:IsEnemy()
    return self._PieceType == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY
end

function XUiGridHeadCommon:ShowChess(chessIndex)
    local config = self._Control:GetHandbookChessConfigByIndex(chessIndex)
    self.RImgHead:SetRawImage(config.HeadIcon)
    self.TxtLeftRound.text = config.Interval
    self.PanelDead.gameObject:SetActiveEx(false)
    self.ImgTarget.gameObject:SetActiveEx(false)
    self.PanelBuff.gameObject:SetActiveEx(false)
    self.RImgAttack.gameObject:SetActiveEx(false)
    self:PreviewHp(config.Hp, config.Hp)
    if self.EffectSmoke then
        self.EffectSmoke.gameObject:SetActiveEx(config.Type == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KING)
    end
    self.EffectBlood.gameObject:SetActiveEx(false)
    self.EffectLight.gameObject:SetActiveEx(false)
end

return XUiGridHeadCommon