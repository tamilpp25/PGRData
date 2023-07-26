local XUiColorTableStageRoll = XLuaUiManager.Register(XLuaUi,"UiColorTableStageRoll")

function XUiColorTableStageRoll:OnAwake()
    self.BtnSkip = self.Transform:Find("SafeAreaContentPane/PanelMessage/BtnSkip"):GetComponent("XUiButton")
    self.ResultEffect = {
        [3] = self.Effect02,
        [4] = self.Effect03,
        [5] = self.Effect04,
    }
    self.RollAngle = {
        [3] = -60,
        [4] = -120,
        [5] = 155,
    }
    self.RollEffect = {
        [XColorTableConfigs.ColorType.Red] = self.Effect05,
        [XColorTableConfigs.ColorType.Green] = self.Effect07,
        [XColorTableConfigs.ColorType.Blue] = self.Effect06,
    }
    if self.Effect01 then self.Effect01.gameObject:SetActiveEx(false) end
    self:_AddBtnListener()
end

function XUiColorTableStageRoll:OnStart(colorType, data, canReRoll, callback)
    self.ColorType = colorType
    self.RollCount = data.RollCount
    self.RollAddData = data.RollAddData
    self.CanReRoll = canReRoll
    self.CallBack = callback
    self.BaseLocalEulerAngles = self.RImgRoll.transform.localEulerAngles
    self._GameManager = XDataCenter.ColorTableManager.GetGameManager()
    self._GameData = self._GameManager:GetGameData()

    self:_Refresh()
end

function XUiColorTableStageRoll:OnEnable()
    self:PlayAnimationWithMask("AnimEnable1", function ()
        self:PlayAnimation("Loop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    if not self._GameManager:GetDontShowRollBoss() then
        self:PlayRollAnim()
    else
        self:ShowPanel()
    end
end

-- 笔杆旋转停止对应角度
function XUiColorTableStageRoll:PlayRollAnim()
    if self.RollEffect[self.ColorType] then
        self.RollEffect[self.ColorType].gameObject:SetActiveEx(false)
        self.RollEffect[self.ColorType].gameObject:SetActiveEx(true)
    end
    self:PlayAnimationWithMask("Result"..self.RollAddData, function ()
        self:ShowPanel()
    end)
end

function XUiColorTableStageRoll:ShowPanel()
    self:_RefreshPoint()
    self.Effect.gameObject:SetActiveEx(false)
    self.RImgRoll.transform.localEulerAngles = Vector3(self.RImgRoll.transform.localEulerAngles.x, self.RImgRoll.transform.localEulerAngles.y, self.RollAngle[self.RollAddData])
    self.PanelMessage.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function ()
        if XTool.UObjIsNil(self.Transform) then return end
        self:RefreshResultPanelEffect()
    end, 250)
    self:PlayAnimationWithMask("PanelMessageEnable")

end

function XUiColorTableStageRoll:RefreshResultPanelEffect()
    if self.ResultEffect[self.RollAddData] then
        self.ResultEffect[self.RollAddData].gameObject:SetActiveEx(false)
        self.ResultEffect[self.RollAddData].gameObject:SetActiveEx(true)
    end
    if self.Effect01 then
        self.Effect01.gameObject:SetActiveEx(false)
        self.Effect01.gameObject:SetActiveEx(true)
        -- 因为特效用的是控件加载，不是脚本控制加载，所以等加载完下一帧再处理
        XScheduleManager.ScheduleOnce(function ()
            if XTool.UObjIsNil(self.GameObject) or self.Effect01.childCount <= 0 then return end
            local effect = self.Effect01.transform:GetChild(0):GetChild(0)
            if not effect then return end
            local particleSystem = effect:GetChild(0):GetComponent("ParticleSystem")
            local color = XUiHelper.Hexcolor2Color(XColorTableConfigs.GetColorStageRollPoint(self.ColorType, self.RollAddData))
            particleSystem.main.startColor = CS.UnityEngine.ParticleSystem.MinMaxGradient(color)
            effect.gameObject:SetActiveEx(false)
            effect.gameObject:SetActiveEx(true)
        end, 0)
    end
end



-- private
----------------------------------------------------------------

function XUiColorTableStageRoll:_Refresh()
    local colorTxt = XColorTableConfigs.GetColorText(self.ColorType)
    local canReroll = self.CanReRoll and not self._GameData:CheckIsFirstGuideStage()

    self.TxtInfo.text = XUiHelper.GetText("ColorTableRollPointTxt", colorTxt, self.RollAddData)
    self.TxtTips.gameObject:SetActiveEx(false)
    self.TxtBtnTips.gameObject:SetActiveEx(false)
    self.BtnAgain.gameObject:SetActiveEx(canReroll)
    if not canReroll and self.BtnSkip then
        self.BtnEnter.transform.localPosition = Vector3(self.BtnSkip.transform.localPosition.x,
            self.BtnEnter.transform.localPosition.y,
            self.BtnEnter.transform.localPosition.z)
    end
    self.RImgBg:SetRawImage(XColorTableConfigs.GetRImgStageRollPanel(self.ColorType))
    self.RImgColor.color = XUiHelper.Hexcolor2Color(XColorTableConfigs.GetColorStageRollPoint(self.ColorType, self.RollAddData))
    self:_RefreshPoint()
    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(not self._GameData:CheckIsFirstGuideStage())
        local dontShowRollAnim = self._GameManager:GetDontShowRollBoss()
        if dontShowRollAnim then
            self.BtnSkip:SetButtonState(CS.UiButtonState.Select)
        end
    end
end

function XUiColorTableStageRoll:_RefreshPoint()
    if not XTool.IsNumberValid(self.RollAddData) then
        return
    end
    if XColorTableConfigs.GetImgStageRollPoint(self.RollAddData) then
        self.ImgNumber:SetSprite(XColorTableConfigs.GetImgStageRollPoint(self.RollAddData))
    end
end

function XUiColorTableStageRoll:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self._OnBtnReRollClick)
    if self.BtnSkip then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self._OnBtnDonShowRollAnimClick)
    end
end

function XUiColorTableStageRoll:_OnBtnCloseClick()
    self._GameManager:RequestExecute(0)
    self:Close()
end

function XUiColorTableStageRoll:_OnBtnReRollClick()
    self._GameManager:RequestReRoll(function (data, canReRoll)
        XLuaUiManager.PopThenOpen("UiColorTableStageRoll", self.ColorType, data, canReRoll)
    end)
end

function XUiColorTableStageRoll:_OnBtnDonShowRollAnimClick()
    self._GameManager:SetDontShowRollBoss(not self._GameManager:GetDontShowRollBoss())
end

----------------------------------------------------------------