local XUiFubenBossSingleModeDetailGridHead = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeDetailGridHead")

---@class XUiFubenBossSingleModeDetailGridBuff : XUiNode
---@field PanelDetail UnityEngine.RectTransform
---@field TxtValue UnityEngine.UI.Text
---@field TxtMax UnityEngine.UI.Text
---@field BtnBuff XUiComponent.XUiButton
---@field PanelScoring UnityEngine.RectTransform
---@field ImgTriangleBg UnityEngine.UI.Image
---@field ImgBuffIcon UnityEngine.UI.RawImage
---@field TxtBuffName UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field GridCharacter UnityEngine.RectTransform
---@field TxtNone UnityEngine.UI.Text
---@field BtnTongBlack XUiComponent.XUiButton
---@field ListCharacter UnityEngine.RectTransform
---@field TxtTime UnityEngine.UI.Text
---@field TxtTimeDesc UnityEngine.UI.Text
---@field PanelTime UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
---@field Parent XUiFubenBossSingleModeDetail
local XUiFubenBossSingleModeDetailGridBuff = XClass(XUiNode, "XUiFubenBossSingleModeDetailGridBuff")

-- region 生命周期

function XUiFubenBossSingleModeDetailGridBuff:OnStart()
    self:_InitUi()
    self:_InitAnimation()
    ---@type XBossSingleFeature
    self._Feature = nil
    self._RecordTimer = nil
    self._RecordEndTime = nil
    self._IsDetailOpen = false
    self._Index = 0
    ---@type XUiFubenBossSingleModeDetailGridHead[]
    self._GridHeadUiList = {}

    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleModeDetailGridBuff:OnDisable()
    self:_StopRecordTimer()
end

-- endregion

---@param feature XBossSingleFeature
function XUiFubenBossSingleModeDetailGridBuff:Refresh(feature, index)
    if not feature or not XTool.IsNumberValid(index) then
        return
    end

    self._Feature = feature
    self._Index = index
    self.ImgBuffIcon:SetRawImage(feature:GetIcon())
    self.ImgTriangleBg.gameObject:SetActiveEx(false)
    self.TxtBuffName.text = feature:GetName()
    self.TxtDetail.text = feature:GetDesc()
    self.TxtValue.text = feature:GetScore()
    self.TxtMax.text = "/" .. feature:GetTotalScore()
    self.PanelScoring.gameObject:SetActiveEx(feature:GetIsRecording())

    self:_RefreshRecordTime(index == 1)
end

function XUiFubenBossSingleModeDetailGridBuff:SetDetailActive(isActive)
    self:_PlayDetailAnimation(isActive)
    self._IsDetailOpen = isActive
    if isActive then
        self:_RefreshCharacterList()
        self.BtnBuff:SetButtonState(CS.UiButtonState.Select)
    else
        for _, gridHead in pairs(self._GridHeadUiList) do
            gridHead:Close()
        end
        self.BtnBuff:SetButtonState(CS.UiButtonState.Normal)
        self.BtnBuff.TempState = CS.UiButtonState.Normal
    end
end

function XUiFubenBossSingleModeDetailGridBuff:PlayBuffAnimation(isOpen, isDetailOpen)
    if isOpen then
        self:_PlayAnimation(self._BuffBigAnimation, function()
            self:SetDetailActive(isDetailOpen)
        end)
    else
        self:SetDetailActive(isDetailOpen)
        self:_PlayAnimation(self._BuffSmallAnimation)
    end
end

-- region 按钮事件

function XUiFubenBossSingleModeDetailGridBuff:OnBtnBuffClick()
    if self._IsDetailOpen then
        self.Parent:ChangeCamera(false)
    else
        self.Parent:ChangeBuffGrid(self._Index)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:OnBtnTongBlackClick()
    if self._Feature then
        local stageId = self._Feature:GetStageId()

        self.Parent:ChangeCamera(false)
        self.Parent:SetIsNeedResetAnimation(true)
        self._Control:OnEnterChallengeFight()
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, nil, require(
            "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeBattleRoleRoom"))
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleModeDetailGridBuff:_RegisterButtonClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnBuff, self.OnBtnBuffClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick, true)
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshCharacterList()
    if self._Feature:GetIsCharacterEmpty() then
        self.TxtNone.gameObject:SetActiveEx(true)

        for _, gridHead in pairs(self._GridHeadUiList) do
            gridHead:Close()
        end
    else
        local characterIds = self._Feature:GetCharacterList()
        local count = self._Control:GetMaxTeamCharacterMember()

        self.TxtNone.gameObject:SetActiveEx(false)
        for i = 1, count do
            local girdHead = self._GridHeadUiList[i]
            local characterId = characterIds[i]

            if not girdHead then
                local grid = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)

                girdHead = XUiFubenBossSingleModeDetailGridHead.New(grid, self)
                self._GridHeadUiList[i] = girdHead
            end

            girdHead:Open()
            girdHead:Refresh(characterId)
        end
        for i = count + 1, #self._GridHeadUiList do
            self._GridHeadUiList[i]:Close()
        end
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshRecordTime(isFirst)
    local bossSingle = self._Control:GetBossSingleData()
    local recordTime = bossSingle:GetBossSingleChallengeDeleteRecordTime()

    if XTool.IsNumberValid(recordTime) and isFirst then
        local endTime = recordTime + self._Control:GetChallengeRecordCD()
        local nowTime = XTime.GetServerNowTimestamp()
        local isShow = endTime > nowTime

        self.PanelTime.gameObject:SetActiveEx(isShow)
        if isShow then
            self.TxtTimeDesc.text = XUiHelper.GetText("BossSingleChallengeRecordCD")
            self._RecordEndTime = endTime - nowTime
            self:_RefreshTimer()
            if self._RecordEndTime >= 0 then
                self:_StartRecordTimer()
            end
        end
    else
        self.PanelTime.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_InitUi()
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleModeDetailGridBuff:_InitAnimation()
    local root = self.BtnBuff.transform
    local animationRoot = root:FindTransform("Animation")

    if animationRoot then
        self._BuffBigAnimation = animationRoot:FindTransform("BtnBuffBig")
        self._BuffSmallAnimation = animationRoot:FindTransform("BtnBuffSmall")
    end

    root = self.PanelDetail.transform
    animationRoot = root:FindTransform("Animation")

    if animationRoot then
        self._DetailEnableAnimation = animationRoot:FindTransform("PanelDetailEnable")
        self._DetailDisableAnimation = animationRoot:FindTransform("PanelDetailDisable")
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_PlayAnimation(animation, finishCallback)
    if animation then
        animation:PlayTimelineAnimation(finishCallback)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_PlayDetailAnimation(isOpen)
    if self._IsDetailOpen ~= isOpen then
        if isOpen then
            self.PanelDetail.gameObject:SetActiveEx(isOpen)
            self:_PlayAnimation(self._DetailEnableAnimation, function()
                self.Parent:SetIsBuffPlaying(false)
            end)
        else
            self.Parent:SetIsBuffPlaying(false)
            self.PanelDetail.gameObject:SetActiveEx(isOpen)
        end
    else
        self.Parent:SetIsBuffPlaying(false)
        self.PanelDetail.gameObject:SetActiveEx(isOpen)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_StartRecordTimer()
    self:_StopRecordTimer()

    if XTool.IsNumberValid(self._RecordEndTime) then
        self._RecordTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshTimer), XScheduleManager.SECOND)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_StopRecordTimer()
    if self._RecordTimer then
        XScheduleManager.UnSchedule(self._RecordTimer)
        self._RecordTimer = nil
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshTimer()
    self.TxtTime.text = XUiHelper.GetTime(self._RecordEndTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)

    self._RecordEndTime = self._RecordEndTime - 1
    if not XTool.IsNumberValid(self._RecordEndTime) or self._RecordEndTime <= 0 then
        self.PanelTime.gameObject:SetActiveEx(false)
        self._RecordEndTime = nil
        self:_StopRecordTimer()
    end
end

-- endregion

return XUiFubenBossSingleModeDetailGridBuff
