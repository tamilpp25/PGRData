---@class XUiPanelGame2048Fever: XUiNode
---@field private _Control XGame2048Control
---@field private _GameControl XGame2048GameControl
---@field Parent XUiGame2048Game
local XUiPanelGame2048Fever = XClass(XUiNode, 'XUiPanelGame2048Fever')

local FeverTurnChangedTweenTime = nil

function XUiPanelGame2048Fever:OnStart()
    self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    
    self.TxtMax.gameObject:SetActiveEx(false)
    self.PanelBuff.gameObject:SetActiveEx(false)
    
    self._GameControl = self._Control:GetGameControl()
    
    self.TxtDetail.text = self._Control:GetClientConfigText('FerverHelpDetail')
    
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA, self.RefreshFeverLevel, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_DATA_REFRESH, self.RefreshFeverLevel, self)
    
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_OPTION, self.OnHideHelpDetail, self)

    if FeverTurnChangedTweenTime == nil or XMain.IsEditorDebug then
        FeverTurnChangedTweenTime = self._Control:GetClientConfigNum('FeverTurnChangedTweenTime')
    end
end

function XUiPanelGame2048Fever:OnDisable()
    self:StopFeverSequence()
end


function XUiPanelGame2048Fever:OnNewGameInit()
    self.PanelFeverBubble.gameObject:SetActiveEx(false)
    self._IsShowHelpDetail = false

    self:RefreshFeverLevel(true)
    self.PanelBuff.gameObject:SetActiveEx(true)
end

function XUiPanelGame2048Fever:OnBtnHelpClick()
    self._IsShowHelpDetail = not self._IsShowHelpDetail
    self.PanelFeverBubble.gameObject:SetActiveEx(self._IsShowHelpDetail)
end

function XUiPanelGame2048Fever:OnHideHelpDetail()
    if self._IsShowHelpDetail then
        self:OnBtnHelpClick()
    end
end

function XUiPanelGame2048Fever:RefreshFeverLevel(isBegin)
    local curTargetValue = self._GameControl.TurnControl:GetCurTargetMergeValue()
    local feverLeftTurn = self._GameControl.TurnControl:GetFeverLeftRound()
    self.TxtLVNum.text = XUiHelper.FormatText(self._Control:GetClientConfigText('BoardLevelLabel'), self._GameControl.TurnControl:GetBoardLv())
    self.TxtTarget.text = curTargetValue

    local isShowMaxLabel = not self._GameControl.TurnControl:CheckHasNextTarget()
    
    self.TxtMax.gameObject:SetActiveEx(isShowMaxLabel)
    
    local isHaveFeverBuff = XTool.IsNumberValid(feverLeftTurn)

    if isBegin or self._LastFeverLeftTurn == feverLeftTurn then
        if self.FxStepDown then
            self.FxStepDown.gameObject:SetActiveEx(false)
        end
        self.TxtFeverLeftTurn.text = feverLeftTurn
    else
        self:StopFeverSequence()
        
        local curNum = string.IsNumeric(self.TxtFeverLeftTurn.text) and tonumber(self.TxtFeverLeftTurn.text) or feverLeftTurn
        local feverSequence = CS.DG.Tweening.DOTween.Sequence()

        feverSequence:AppendCallback(function()
            if self.FxStepDown then
                self.FxStepDown.gameObject:SetActiveEx(true)
            end
        end)

        feverSequence:Append(CS.DG.Tweening.DOTween.To(function()
            return curNum
        end, function(newNum)
            if self and self.TxtFeverLeftTurn then
                self.TxtFeverLeftTurn.text = XMath.ToMinInt(newNum)
            end
        end, feverLeftTurn, FeverTurnChangedTweenTime))

        feverSequence:AppendCallback(function()
            if self.FxStepDown then
                self.FxStepDown.gameObject:SetActiveEx(false)
            end
        end)
        feverSequence:Play()
        
        self._FeverSequence = feverSequence
    end
    
    
    -- 显示目标方块图片
    ---@type XTableGame2048Block
    local blockCfg = self._GameControl.TurnControl:GetCurTargetBlockCfg()

    if blockCfg then
        if self.TargetImgBg then
            local hasBgRes = not string.IsNilOrEmpty(blockCfg.BgRes)
            
            self.TargetImgBg.gameObject:SetActiveEx(hasBgRes)

            if hasBgRes then
                self.TargetImgBg:SetRawImage(blockCfg.BgRes)
            end
        end

        if self.TargetImgIcon then
            local hasIconRes = not string.IsNilOrEmpty(blockCfg.IconRes)

            self.TargetImgIcon.gameObject:SetActiveEx(hasIconRes)

            if hasIconRes then
                self.TargetImgIcon:SetRawImage(blockCfg.IconRes)
            end
        end
    end

    if self.Parent.FxBg then
        self.Parent.FxBg.gameObject:SetActiveEx(isHaveFeverBuff)
    end
    
    self._LastFeverLeftTurn = feverLeftTurn
end

--- 停止强化步数提升动画
function XUiPanelGame2048Fever:StopFeverSequence()
    if self._FeverSequence then
        if self._FeverSequence:IsActive() then
            self._FeverSequence:Kill(true)
        end
        self._FeverSequence = nil
        if self.FxStepDown then
            self.FxStepDown.gameObject:SetActiveEx(false)
        end
    end
end

return XUiPanelGame2048Fever