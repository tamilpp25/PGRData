-- 肉鸽玩法2.1灵视变化动画
-- ================================================================================
local XUiBiancaTheatrePsionicVision = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatrePsionicVision")

local MinVisionValue = 0
local MaxVisionValue = 100

function XUiBiancaTheatrePsionicVision:OnAwake()
    self.UnlockItemTable = {}
    self:AddClickListener()
end

function XUiBiancaTheatrePsionicVision:OnStart(closeCb, isUnLock, visionChangeId, startValue, isSettle)
    self.CloseCb = closeCb
    -- 是否是解锁灵视系统提示
    self.IsUnlock = isUnLock
    self.IsSettle = isSettle
    self.visionChangeId = visionChangeId
    self.StartValue = startValue
    self:Refresh()
    self:PlayAnimationWithMask("AnimEnable1", function ()
        self:PlayAnimation("Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

function XUiBiancaTheatrePsionicVision:Refresh()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetVisionValue() or 0
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    if self.IconBg then
        self.IconBg:SetRawImage(XBiancaTheatreConfigs.GetVisionIcon(visionId))
    end
    if self.IsUnlock then
        XDataCenter.BiancaTheatreManager.SetVisionOpenTipCache()
        self:SetUnlockDescTxt()
        self:UpdateVisionEffect(0)
    elseif self.IsSettle then
        self:SetSettleVisionDesc()
        self:UpdateVisionEffect(adventureManager:GetOldVisionValue() or 0)
    else
        if XTool.IsNumberValid(self.visionChangeId) then
            local changeValue = XBiancaTheatreConfigs.GetVisionChangeChange(self.visionChangeId)
            self.TxtDesc.text = XBiancaTheatreConfigs.GetVisionChangeShowDesc(self.visionChangeId)
            self:PlayVisionChangeAnim(self.StartValue, changeValue, 1)
        else
            self:SetVisionValue(visionValue)
        end
        self:UpdateVisionEffect(visionValue)
    end
end

function XUiBiancaTheatrePsionicVision:UpdateVisionEffect(visionValue)
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    self.EffectBg = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTitle/Bg/Effect")
    if self.Effect then
        self.Effect.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionUiEffectUrl(visionId))
    end
    if self.EffectBg then
        self.EffectBg.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionPsionicEffectUrl(visionId))
    end
end

---设置冒险过程中灵视弹窗
---@param visionValue integer
function XUiBiancaTheatrePsionicVision:SetVisionValue(visionValue)
    self.ImgProgress.transform.parent.gameObject:SetActiveEx(true)
    self.TxtNum.transform.parent.gameObject:SetActiveEx(true)
    self.ImgProgress.fillAmount = visionValue / 100
    self.TxtNum.text = visionValue
end

---设置解锁灵视 弹窗文本
function XUiBiancaTheatrePsionicVision:SetUnlockDescTxt()
    local txt = XUiHelper.ReplaceTextNewLine(XBiancaTheatreConfigs.GetClientConfig("VisionUnlockDesc"))
    local textMeshEffect = self.TxtDesc.gameObject:AddComponent(typeof(CS.TextMeshEffect))

    self.ImgProgress.transform.parent.gameObject:SetActiveEx(false)
    self.TxtNum.transform.parent.gameObject:SetActiveEx(false)
    self.TxtDesc.text = txt
    textMeshEffect.playMode = CS.TextMeshEffect.MeshEffectPlayMode.Loop
    textMeshEffect.endIndex = string.len(txt)
    textMeshEffect.textHorizontalShakeType = CS.TextMeshEffect.ShakeEffectType.Random
    textMeshEffect.textVerticalShakeType = CS.TextMeshEffect.ShakeEffectType.Random
    textMeshEffect:Play()
end

---设置结算弹窗灵视值显示弹窗
function XUiBiancaTheatrePsionicVision:SetSettleVisionDesc()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetOldVisionValue() or 0
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    local txt = XUiHelper.ReplaceTextNewLine(XBiancaTheatreConfigs.GetVisionSettleDesc(visionId))

    if not string.IsNilOrEmpty(txt) then self.TxtDesc.text = txt end
    self.TxtNum.text = visionValue
    self.ImgProgress.fillAmount = visionValue / 100
    self.ImgProgress.transform.parent.gameObject:SetActiveEx(true)
    self.TxtNum.transform.parent.gameObject:SetActiveEx(true)
end

---播放灵视值增长动画
---@param startValue integer 起始灵视值
---@param changeValue integer 增长值
---@param animDuration integer 动画时长
function XUiBiancaTheatrePsionicVision:PlayVisionChangeAnim(startValue, changeValue, animDuration)
    local endValue = math.min(MaxVisionValue, startValue + changeValue)
    endValue = math.max(MinVisionValue, endValue)
    local valueChange = endValue - startValue
    if not XTool.IsNumberValid(valueChange) then
        self:SetVisionValue(endValue)
        return
    end
    self:PlayVisionChangeSound(XBiancaTheatreConfigs.GetVisionIdByValue(startValue), XBiancaTheatreConfigs.GetVisionIdByValue(endValue))
    XUiHelper.Tween(animDuration, function(f)
        if XTool.UObjIsNil(self.GameObject) then return end
        local value = math.floor(startValue + valueChange * f)
        self:SetVisionValue(value)
    end, function()
        if XTool.UObjIsNil(self.GameObject) then return end
        self:SetVisionValue(endValue)
    end)
end

function XUiBiancaTheatrePsionicVision:PlayVisionChangeSound(startVisionId, endVisionId)
    local soundCueId = XBiancaTheatreConfigs.GetVisionChangeGetSoundCueId(self.visionChangeId)
    if startVisionId ~= endVisionId  then
        soundCueId = XBiancaTheatreConfigs.GetVisionUpSoundCueId(endVisionId)
        self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(XBiancaTheatreConfigs.GetVisionUpDesc(endVisionId))
        XDataCenter.BiancaTheatreManager.OpenAudioFilter(endVisionId)
    end
    if XTool.IsNumberValid(soundCueId) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, soundCueId)
    end
end

function XUiBiancaTheatrePsionicVision:AddClickListener()
    self:RegisterClickEvent(self.BtnClose, function () self:OnCloseClick() end)
end

function XUiBiancaTheatrePsionicVision:OnCloseClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end