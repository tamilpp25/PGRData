---@class XUiGridGuildMusicEdit
local XUiGridGuildMusicEdit = XClass(nil, "XUiGridGuildEdit")

local DOTween = CS.DG.Tweening.DOTween
local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

function XUiGridGuildMusicEdit:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnTop.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_TOPPING_BGM, self.Index, self.BgmId)
    end
    self.BtnDelete.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DELETE_BGM, self.Index)
    end
    self.ImgBlack = self.GameObject:FindTransform("ImgBlack")
end

function XUiGridGuildMusicEdit:Refresh(index, bgmId, isExperience)
    self.Index = index
    self.BgmId = bgmId
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
    self.TxtListMusicName.text = bgmCfg.Name
    self.TxtListMusicDesc.text = bgmCfg.Desc
    self.TxtSerial.text = index
    self.ImgBlack.gameObject:SetActiveEx(index % 2 ~= 0)

    -- 体验中
    self.ImgAudition.gameObject:SetActiveEx(isExperience)

    self:UpdateMusicTxtAnim()
end

function XUiGridGuildMusicEdit:UpdateMusicTxtAnim()
    if self.TweenSequenceMusicTxt then
        self.TweenSequenceMusicTxt:Kill()
    end
    local txtDescWidth = XUiHelper.CalcTextWidth(self.TxtListMusicDesc)
    local maskWidth = self.TxtListMusicDesc.transform.parent.rect.width
    local txtDescTransform = self.TxtListMusicDesc.transform
    if txtDescWidth < maskWidth then
        txtDescTransform.localPosition = Vector3.zero
        return
    end
    local txtLocalPosition = txtDescTransform.localPosition
    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
    local duration = (txtDescWidth + maskWidth) / MusicPlayerTextMoveSpeed
    local sequence = DOTween.Sequence()
    self.TweenSequenceMusicTxt = sequence
    sequence:Append(txtDescTransform:DOLocalMoveX(-txtDescWidth, duration):SetEase(CS.DG.Tweening.Ease.Linear))
    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
    sequence:SetLoops(-1)
end

return XUiGridGuildMusicEdit
