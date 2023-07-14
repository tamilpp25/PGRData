local XUiMainLeftTop = XClass(nil, "XUiMainLeftTop")

local Vector3 = CS.UnityEngine.Vector3
local DOTween = CS.DG.Tweening.DOTween

local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

function XUiMainLeftTop:Ctor(rootUi)
    self.Transform = rootUi.PanelLeftTop.gameObject.transform
    XTool.InitUiObject(self)
    self:UpdateInfo()
    --ClickEvent
    self.BtnRoleInfo.CallBack = function() self:OnBtnRoleInfo() end
    self.BtnMusicPlayer.CallBack = function() self:OnBtnMusicPlayer() end
    --RedPoint
    XRedPointManager.AddRedPointEvent(self.BtnRoleInfo.ReddotObj, self.OnCheckRoleNews, self, {
        XRedPointConditions.Types.CONDITION_PLAYER_ACHIEVE, XRedPointConditions.Types.CONDITION_PLAYER_SETNAME,
        XRedPointConditions.Types.CONDITION_EXHIBITION_NEW, XRedPointConditions.Types.CONDITION_HEADPORTRAIT_RED,
        XRedPointConditions.Types.CONDITION_MEDAL_RED, XRedPointConditions.Types.CONDITION_PLAYER_BIRTHDAY,
    })

    --Filter
    self:CheckFilterFunctions()
end

function XUiMainLeftTop:OnEnable()
    self:UpdateInfo()
    if not self.TweenSequenceTxtMusicPlayer then
        self:UpdateMusicPlayerText()
    elseif self.IsNeedRefreshTweenSequence then
        self.TweenSequenceTxtMusicPlayer:Kill()
        self:UpdateMusicPlayerText()
        self.IsNeedRefreshTweenSequence = false
    else
        self.TweenSequenceTxtMusicPlayer:Play()
    end
    if XUiManager.IsHideFunc then
        self.BtnMusicPlayer.gameObject:SetActiveEx(false)
    end
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
end

function XUiMainLeftTop:OnDisable()
    if self.TweenSequenceTxtMusicPlayer then
        self.TweenSequenceTxtMusicPlayer:Pause()
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, self.UpdateInfo, self)
end

function XUiMainLeftTop:OnDestroy()
    if self.TweenSequenceTxtMusicPlayer then
        self.TweenSequenceTxtMusicPlayer:Kill()
        self.TweenSequenceTxtMusicPlayer = nil
    end
end

function XUiMainLeftTop:CheckFilterFunctions()
    self.BtnRoleInfo.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Player))
end

--个人详情入口
function XUiMainLeftTop:OnBtnRoleInfo()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Player) then
        return
    end
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRoleInfo
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    XLuaUiManager.Open("UiPlayer")
end

function XUiMainLeftTop:OnBtnMusicPlayer()
    XLuaUiManager.Open("UiMusicPlayer", function() self:OnUiMusicPlayerCloseCallback() end)
end

--@region 更新等级经验等
function XUiMainLeftTop:UpdateInfo()
    local curExp = XPlayer.Exp
    local maxExp = XPlayer:GetMaxExp()
    local fillAmount = curExp / maxExp
    self.ImgExpSlider.fillAmount = fillAmount

    local name = XPlayer.Name or ""
    self.TxtName.text = name

    local level = XPlayer.GetLevelOrHonorLevel()
    self.TxtLevel.text = level
    self.TxtId.text = XPlayer.Id
    self.Rankt.text = self:GetLevelTxt()
end

function XUiMainLeftTop:GetLevelTxt()
    self.PanelGlory.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
    if XPlayer.IsHonorLevelOpen() then
        return CS.XTextManager.GetText("HonorLevelShort") .. "/"
    else
        return CS.XTextManager.GetText("HostelDeviceLevel") .. "/"
    end
end

--@endregion
--角色红点
function XUiMainLeftTop:OnCheckRoleNews(count)
    self.BtnRoleInfo:ShowReddot(count >= 0)
end

function XUiMainLeftTop:UpdateMusicPlayerText()
    local albumId = XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId()
    local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
    if not template then return end
    self.MaskMusicPlayer.gameObject:SetActiveEx(true)
    self.TxtMusicName.text = template.Name

    local txtDescWidth = XUiHelper.CalcTextWidth(self.TxtMusicDesc)
    local txtNameWidth = XUiHelper.CalcTextWidth(self.TxtMusicName)
    local txtWidth = txtDescWidth + txtNameWidth
    local maskWidth = self.MaskMusicPlayer.sizeDelta.x
    local txtDescTransform = self.TxtMusicDesc.transform
    local txtLocalPosition = txtDescTransform.localPosition
    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
    local distance = txtWidth + maskWidth
    local sequence = DOTween.Sequence()
    self.TweenSequenceTxtMusicPlayer = sequence
    sequence:Append(txtDescTransform:DOLocalMoveX(-txtWidth, distance / MusicPlayerTextMoveSpeed))
    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
    sequence:SetLoops(-1)
end

function XUiMainLeftTop:OnUiMusicPlayerCloseCallback()
    self.IsNeedRefreshTweenSequence = true
end

return XUiMainLeftTop