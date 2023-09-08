
---@class XUiGridHeadCommon : XUiNode
---@field _Control XBlackRockChessControl
local XUiGridHeadCommon = XClass(XUiNode, "XUiGridHeadCommon")

local MAX_HP_GRID = 10

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
    self.ImgHpBar1Bg.fillAmount = 1

    self.PreviewAlpha = self._Control:GetPreviewIconAlpha()
    
    self:InitEffect()
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
    if self.Seq1 then
        self.Seq1:Kill()
        self.Seq1 = nil
    end

    if self.Seq2 then
        self.Seq2:Kill()
        self.Seq2 = nil
    end
end

function XUiGridHeadCommon:RefreshView(pieceId)
    self.PieceId = pieceId or self.PieceId
    if not XTool.IsNumberValid(self.PieceId) then
        return
    end
    local enemy = self._Control:GetChessEnemy()
    local pieceInfo = enemy:GetPieceInfo(self.PieceId)
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

    local isPiece = pieceInfo:IsPiece()
    self.RImgHead.gameObject:SetActiveEx(isPiece)
    self.TxtUnknown.gameObject:SetActiveEx(not isPiece)
    if isPiece then
        self.RImgHead:SetRawImage(self._Control:GetPieceHeadIcon(configId))
        self.CanvasGroup.alpha = 1.0
    else
        self.CanvasGroup.alpha = self.PreviewAlpha
    end

    local point = self._Control:GetPlayerMovePoint()
    local attack = false
    if isPiece then
        attack = pieceInfo:CheckAttack(point)
    end
    local moveCd = enemy:GetPieceMoveCd(self.PieceId)
    local isMove = moveCd <= 0
    self.RImgMove.gameObject:SetActiveEx(isMove and not attack)
    self.TxtLeftRound.gameObject:SetActiveEx(not isMove and not attack)
    self.RImgAttack.gameObject:SetActiveEx(attack)
    self.TxtLeftRound.text = moveCd
    if self.EffectLight then
        self.EffectLight.gameObject:SetActiveEx(attack)
    end

    local buffIds = self._Control:GetPieceBuffIds(configId)
    local buffId = buffIds[1]
    local hasBuff = XTool.IsNumberValid(buffId)
    self.PanelBuff.gameObject:SetActiveEx(hasBuff)
    if hasBuff then
        self.RImgBuff:SetRawImage(self._Control:GetBuffIcon(buffId))
    end

    if self.TxtMoveCd then
        local desc
        if isPiece then
            if attack then
                desc = self._Control:GetPieceMoveCdText(3)
            elseif isMove then
                desc = self._Control:GetPieceMoveCdText(1)
            else
                desc = string.format(self._Control:GetPieceMoveCdText(2), moveCd)
            end

            local icon = self._Control:GetPieceHeadIcon(configId)
            self.RImgHead:SetRawImage(icon)
        else
            desc = string.format(self._Control:GetPieceMoveCdText(4), moveCd)
        end

        self.TxtMoveCd.text = desc
    end

    if self.TxtDetails then
        local buffIds = self._Control:GetPieceBuffIds(configId)
        local buffId = buffIds[1]
        local buffDesc = pieceInfo:GetBuffDesc(buffId)
        self.TxtDetails.text = buffDesc
    end

    if self.TxtDetails2 then
        local config = self._Control:GetHandbookChessConfigByIndex(pieceInfo:GetPieceType())
        self.TxtDetails2.text = config.Desc
    end

    if self.TxtName then
        self.TxtName.text = self._Control:GetPieceDesc(configId)
    end

    self:SetTarget(false)
end

function XUiGridHeadCommon:SetTarget(state)
    state = state and true or false
    self.ImgTarget.gameObject:SetActiveEx(state)
end

function XUiGridHeadCommon:PreviewDamage(damage)
    if self.Seq1 then
        self.Seq1:Pause()
    end

    if self.Seq2 then
        self.Seq2:Pause()
    end
    local isDamage = damage ~= 0

    local curHp = self._Control:GetPieceLife(self.PieceId)
    local leftHp = math.max(0, curHp - damage)
    self.PanelHp1.gameObject:SetActiveEx(true)
    local showHp2 = leftHp >= MAX_HP_GRID
    local showHp2Pre = curHp >= MAX_HP_GRID

    self.ImgHp1BarPreview.gameObject:SetActiveEx(isDamage)
    self.ImgHp2BarPreview.gameObject:SetActiveEx(isDamage and showHp2Pre)
    self.PanelHp2.gameObject:SetActiveEx(showHp2)

    self.PanelDead.gameObject:SetActiveEx(leftHp <= 0)

    if self.EffectBlood then
        self.EffectBlood.gameObject:SetActiveEx(curHp <= 0)
    end

    self.ImgHp1Bar.fillAmount = CsClamp01(leftHp / MAX_HP_GRID)

    if isDamage then
        self.ImgHp1BarPreview.fillAmount = CsClamp01(curHp / MAX_HP_GRID)
        if not self.Seq1 then
            local sequence = CsTween.DOTween.Sequence()
            sequence:Append(self.ImgHp1BarPreview:DOFade(PreviewAlphaMin, PreviewDuration):SetEase(CsTween.Ease.Flash))
            sequence:Append(self.ImgHp1BarPreview:DOFade(PreviewAlphaMax, PreviewDuration):SetEase(CsTween.Ease.Flash))
            sequence:SetLoops(-1)
            self.Seq1 = sequence
        end
        self.Seq1:Play()
    end

    if isDamage and showHp2Pre then
        self.ImgHp2BarPreview.fillAmount = CsClamp01((curHp - MAX_HP_GRID) / MAX_HP_GRID)
        if not self.Seq2 then
            local sequence = CsTween.DOTween.Sequence()
            sequence:Append(self.ImgHp2BarPreview:DOFade(PreviewAlphaMin, PreviewDuration):SetEase(CsTween.Ease.Flash))
            sequence:Append(self.ImgHp2BarPreview:DOFade(PreviewAlphaMax, PreviewDuration):SetEase(CsTween.Ease.Flash))
            sequence:SetLoops(-1)
            self.Seq2 = sequence
        end
        self.Seq2:Play()
    end
    
    if showHp2 then
        self.ImgHp2Bar.fillAmount = CsClamp01((leftHp - MAX_HP_GRID) / MAX_HP_GRID)
    end
end

return XUiGridHeadCommon