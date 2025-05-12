---@class XUiLineArithmeticGameGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticGameGrid = XClass(XUiNode, "UiLineArithmeticGameGrid")

function XUiLineArithmeticGameGrid:OnStart()
    self._CurrentNumber = 0
    self._TargetScore = 0
    self._Data = false
    self:InitOriginalTextColor()
    if self.TxtNumChange then
        self.TxtNumChange.gameObject:SetActiveEx(false)
    end
    if self.TxtNumChangeEnd then
        self.TxtNumChangeEnd.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmeticGameGrid:InitOriginalTextColor()
    if not self._OriginalTextColor1 then
        self._OriginalTextColor1 = self.TxtNumEnd.color
    end
    if not self._OriginalTextColor2 then
        self._OriginalTextColor2 = self.TxtNum.color
    end
end

function XUiLineArithmeticGameGrid:GetStringNumber(number)
    local strType = type(number)
    if strType == "number" then
        if number > 0 then
            return "+" .. number
        else
            return number
        end
    end
    if strType == "string" then
        return number
    end
    return ""
end

---@param data XLineArithmeticControlMapData
function XUiLineArithmeticGameGrid:Update(data, effectTime)
    self.Transform.name = data.UiName
    self._Data = data

    ---@type UnityEngine.RectTransform
    local transform = self.Transform
    transform.localPosition = Vector3(data.X, data.Y, 0)

    if self.PanelEmpty then
        if data.IsEmpty then
            self.PanelEmpty.gameObject:SetActiveEx(true)
            self.PanelNormal.gameObject:SetActiveEx(false)
            self.PanelProp.gameObject:SetActiveEx(false)
            self.PanelEnd.gameObject:SetActiveEx(false)
            self.PanelSelected.gameObject:SetActiveEx(false)
            self.PanelSelectedBg.gameObject:SetActiveEx(false)
            self.TxtNumTotal.gameObject:SetActiveEx(false)
            return
        else
            self.PanelEmpty.gameObject:SetActiveEx(false)
        end
    end

    local icon = data.Icon
    if data.IsNormal then
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelProp.gameObject:SetActiveEx(false)
        self.PanelEnd.gameObject:SetActiveEx(false)
        local number = data.Number
        self:SetTextNumber(number)
        --if data.NumberOnPreview == 0 then
        --    self.TxtNumChange.gameObject:SetActiveEx(false)
        --else
        --    self.TxtNumChange.gameObject:SetActiveEx(true)
        --    self.TxtNumChange.text = self:GetStringNumber(data.NumberOnPreview)
        --end
        self:SetScorePreview(data.NumberOnPreview)
        self.ImgType:SetRawImage(icon)
        self._CurrentNumber = number

    elseif data.IsEvent then
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelProp.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.TxtNumAddScore.text = self:GetStringNumber(data.Number)
        --self.TxtNumAddScore.text = data.NumberOnGame
        self.ImgTypeHead:SetRawImage(icon)
        if data.IsBuff == true then
            self.TxtNumAddScore.color = XUiHelper.Hexcolor2Color("73F7FFff")
        elseif data.IsBuff == false then
            self.TxtNumAddScore.color = XUiHelper.Hexcolor2Color("a30c32ff")
        else
            self.TxtNumAddScore.color = XUiHelper.Hexcolor2Color("FFEB08ff")
        end

    elseif data.IsFinal then
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelProp.gameObject:SetActiveEx(false)
        self.PanelEnd.gameObject:SetActiveEx(true)
        local number = math.max(data.Number, 0)
        -- 终点不显示负数
        if number == 0 then
            self.TxtNumEnd.gameObject:SetActiveEx(false)
        else
            self.TxtNumEnd.gameObject:SetActiveEx(true)
            self:SetTextNumber(number)
        end

        --if data.NumberOnPreview == 0 then
        --    self.TxtNumChangeEnd.gameObject:SetActiveEx(false)
        --else
        --    self.TxtNumChangeEnd.gameObject:SetActiveEx(true)
        --    self.TxtNumChangeEnd.text = self:GetStringNumber(data.NumberOnPreview)
        --end
        self:SetScorePreview(data.NumberOnPreview)

        self.ImgTypeEnd:SetRawImage(icon)
    end

    if data.TotalNumber then
        self.TxtNumTotal.gameObject:SetActiveEx(true)
        self.TxtNumTotal.text = data.TotalNumber
    else
        self.TxtNumTotal.gameObject:SetActiveEx(false)
    end

    if self.PanelSelectedBg then
        if data.IsSelected then
            -- 设置特效时间
            self.PanelSelected.gameObject:SetActiveEx(true)
            CS.XTool.SetParticleSystemDuration(self.PanelSelected.gameObject, effectTime)
            self.PanelSelectedBg.gameObject:SetActiveEx(true)
        else
            self.PanelSelected.gameObject:SetActiveEx(false)
            self.PanelSelectedBg.gameObject:SetActiveEx(false)
        end
    end

    self:SetEffectByData(data)
    self:SetEmoIcon(data)
end

function XUiLineArithmeticGameGrid:HideScorePreview()
    self.TxtNumChange.gameObject:SetActiveEx(false)
end

function XUiLineArithmeticGameGrid:SetScorePreview(scorePreview)
    local data = self._Data
    if data then
        self:InitOriginalTextColor()
        if data.IsFinal then
            if scorePreview ~= 0 then
                if scorePreview > 0 then
                    self.TxtNumEnd.color = XUiHelper.Hexcolor2Color("a30c32ff")
                else
                    self.TxtNumEnd.color = XUiHelper.Hexcolor2Color("73F7FFff")
                end
            else
                self.TxtNumEnd.color = self._OriginalTextColor1
            end

        elseif data.IsNormal then
            if scorePreview ~= 0 then
                if scorePreview > 0 then
                    self.TxtNum.color = XUiHelper.Hexcolor2Color("73F7FFff")
                else
                    self.TxtNum.color = XUiHelper.Hexcolor2Color("a30c32ff")
                end
            else
                self.TxtNumChange.gameObject:SetActiveEx(false)
                self.TxtNum.color = self._OriginalTextColor2
            end
        end
    end
end

function XUiLineArithmeticGameGrid:SetTextNumber(number)
    self._CurrentNumber = number
    if self._Data then
        if self._Data.IsFinal then
            self.TxtNumEnd.text = number
        elseif self._Data.IsNormal then
            self.TxtNum.text = number
        end
    end
end

function XUiLineArithmeticGameGrid:GetCurrentNumber()
    return self._CurrentNumber
end

function XUiLineArithmeticGameGrid:SetFinalGridIcon(icon)
    self.ImgTypeEnd:SetRawImage(icon)
end

function XUiLineArithmeticGameGrid:SetEffectByData(data)
    if data.IsAwake then
        if self.EffectsSleep.gameObject.activeInHierarchy then
            self.EffectsAwake.gameObject:SetActiveEx(true)
        end
        self.EffectsSleep.gameObject:SetActiveEx(false)
    elseif data.IsSleep then
        self.EffectsAwake.gameObject:SetActiveEx(false)
        if data.EmoIcon or data.IsFinish then
            self.EffectsSleep.gameObject:SetActiveEx(false)
        else
            self.EffectsSleep.gameObject:SetActiveEx(true)
        end
    else
        self.EffectsAwake.gameObject:SetActiveEx(false)
        self.EffectsSleep.gameObject:SetActiveEx(false)
    end
    if self.EffectsVanish then
        self.EffectsVanish.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmeticGameGrid:SetReplaceEffect()
    if self.EffectsVanish then
        self.EffectsVanish.gameObject:SetActiveEx(true)
    end
end

function XUiLineArithmeticGameGrid:SetEmoIcon(data)
    if self.ImgBuff then
        if data.EmoIcon then
            self.ImgBuff:SetSprite(data.EmoIcon)
            self.ImgBuff.gameObject:SetActiveEx(true)
        else
            self.ImgBuff.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLineArithmeticGameGrid:HideEmoIcon()
    if self.ImgBuff then
        self.ImgBuff.gameObject:SetActiveEx(false)
    end
end

return XUiLineArithmeticGameGrid