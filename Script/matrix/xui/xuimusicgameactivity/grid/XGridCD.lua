---@class XGridCD
local XGridCD = XClass(XUiNode, "XGridCD")

function XGridCD:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XGridCD:OnBtnClick()
    local arrangementMusicId = self.ArrangementMusicId 
    local allArrangementMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    if XTool.IsNumberValid(arrangementMusicId) then
        local musicConfig = allArrangementMusicConfig[arrangementMusicId]
        local hasIconCdSp = musicConfig and (not string.IsNilOrEmpty(musicConfig.IconCdSp))
        local condition2Pass = XMVCA.XMusicGameActivity:CheckShow2Condition(arrangementMusicId)
        local canShow2 = hasIconCdSp and condition2Pass
        if canShow2 then
            local hasShow2Key = string.format("IsFirstShowCD_%d_PlayerId_%d", arrangementMusicId, XPlayer.Id)
            XSaveTool.SaveData(hasShow2Key, true)
        end
    end

    if self.OnClickCallback then
        self.OnClickCallback()
    end
end

function XGridCD:RegisterOnClickCallback(fun)
    self.OnClickCallback = fun
end

function XGridCD:Refresh(arrangementMusicId)
    self.ArrangementMusicId = arrangementMusicId
    local allArrangementMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    if XTool.IsNumberValid(arrangementMusicId) then
        self.BtnClick:SetDisable(false)
        
        local musicConfig = allArrangementMusicConfig[arrangementMusicId]
        self.EffectNormal:SetRawImage(musicConfig.IconCd)
        self.Normal1:SetRawImage(musicConfig.IconCd)
        self.Normal2:SetRawImage(musicConfig.IconCdSp)
        self.Press1:SetRawImage(musicConfig.IconCd)
        self.Press2:SetRawImage(musicConfig.IconCdSp)

        local hasIconCdSp = musicConfig and (not string.IsNilOrEmpty(musicConfig.IconCdSp))
        local condition2Pass = XMVCA.XMusicGameActivity:CheckShow2Condition(arrangementMusicId)
        local canShow2 = hasIconCdSp and condition2Pass
        self.Normal1.gameObject:SetActive(not canShow2)
        self.Normal2.gameObject:SetActive(canShow2)
        self.Press1.gameObject:SetActive(not canShow2)
        self.Press2.gameObject:SetActive(canShow2)

        local isRed = XMVCA.XMusicGameActivity:CheckCanShowGridRed(arrangementMusicId)
        self.BtnClick:ShowReddot(isRed)
        local isHasPlayAnimation = XMVCA.XMusicGameActivity:CheckHasPlayShow2Anim(arrangementMusicId)
        if isRed and not isHasPlayAnimation then
            local key = string.format("HasPlayShow2Anim_%d_PlayerId_%d", arrangementMusicId, XPlayer.Id)
            self:PlayAnimation("NormalQieHuan")
            XSaveTool.SaveData(key, true)
        end
    else
        self.BtnClick:SetDisable(true)
    end
end

return XGridCD