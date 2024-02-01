
---@class XUiGridHeadCommon : XUiNode
---@field _Control XBlackRockChessControl
local XUiGridHeadCommon = XClass(XUiNode, "XUiGridHeadCommon")

local MAX_HP_GRID = 10

local MAX_HP_COUNT = 3 --血条最大数量

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
    for i = 1, MAX_HP_COUNT do
        local seq = self["Seq" .. i]
        if seq then
            seq:Kill()
            self["Seq" .. i] = nil
        end
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

    local isPiece = pieceInfo:IsPiece()
    self.RImgHead.gameObject:SetActiveEx(isPiece)
    self.TxtUnknown.gameObject:SetActiveEx(not isPiece)
    if isPiece then
        self.RImgHead:SetRawImage(self._Control:GetPieceHeadIcon(configId))
        self.CanvasGroup.alpha = 1.0
    else
        self.CanvasGroup.alpha = self.PreviewAlpha
    end
    
    local attack = false
    if isPiece then
        attack = pieceInfo:IsPrepareAttack()
    end
    local moveCd = pieceInfo:GetMoveCd()
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
    local piece = self:GetPiece()
    local curHp = piece and piece:GetHp() or 0
    local leftHp = math.max(0, curHp - damage)

    self.PanelDead.gameObject:SetActiveEx(leftHp <= 0)
    if piece then
        piece:SetPreviewDead(leftHp <= 0)
    end
    if self.EffectBlood then
        self.EffectBlood.gameObject:SetActiveEx(curHp <= 0)
    end

    for i = MAX_HP_COUNT, 1, -1 do
        local hp = self:GetValueByIndex(curHp, i)
        local left = self:GetValueByIndex(curHp - damage, i)
        
        self:PreviewHp(i, hp, left)
    end
end

function XUiGridHeadCommon:GetValueByIndex(value, index)
    return math.max(0, math.min(value - (index - 1) * MAX_HP_GRID, MAX_HP_GRID))
end

function XUiGridHeadCommon:PreviewHp(index, curHp, leftHp)
    local seq = self["Seq" .. index]
    local hpBar = self["ImgHp" .. index .."Bar"]
    local hpBarPreview = self["ImgHp" .. index .."BarPreview"]
    if seq then
        seq:Pause()
    end
    if not hpBar or not hpBarPreview then
        return
    end
    
    local isDamage = curHp ~= leftHp
    hpBar.gameObject:SetActiveEx(curHp > 0)
    hpBarPreview.gameObject:SetActiveEx(isDamage and leftHp >= 0)
    hpBar.fillAmount = CsClamp01(leftHp / MAX_HP_GRID)
    if isDamage then
        hpBarPreview.fillAmount = CsClamp01(curHp / MAX_HP_GRID)
        if not seq then
            seq = CsTween.DOTween.Sequence()
            seq:Append(hpBarPreview:DOFade(PreviewAlphaMin, PreviewDuration):SetEase(CsTween.Ease.Flash))
            seq:Append(hpBarPreview:DOFade(PreviewAlphaMax, PreviewDuration):SetEase(CsTween.Ease.Flash))
            seq:SetLoops(-1)
            self["Seq" .. index] = seq
        end
        seq:Play()
    end
end

---@return XBlackRockChessPiece
function XUiGridHeadCommon:GetPiece()
    return self._Control:GetChessEnemy():GetPieceInfo(self.PieceId)
end

return XUiGridHeadCommon