local XUiNieRBossFightResult = XLuaUiManager.Register(XLuaUi, "UiNieRBossFightResult")

function XUiNieRBossFightResult:OnAwake()
    self:AutoAddListener()
end

function XUiNieRBossFightResult:OnStart(winData)
    self.WinData = winData
end

function XUiNieRBossFightResult:OnEnable()
    self:Refresh()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
end

function XUiNieRBossFightResult:AutoAddListener()
    self:RegisterClickEvent(self.BtnSaveInfo, self.OnBtnSaveInfoClick)
    self:RegisterClickEvent(self.BtnExitFight, self.OnBtnExitFightClick)
end


function XUiNieRBossFightResult:OnBtnSaveInfoClick()
    XDataCenter.NieRManager.NieRUpdateBossScore(function()
        self:StopAudio()
        self:Close()
    end)
end

function XUiNieRBossFightResult:OnBtnExitFightClick()
    self:StopAudio()
    self:Close()
end

function XUiNieRBossFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end


function XUiNieRBossFightResult:Refresh()
    if not self.WinData or not self.WinData.SettleData or
    not self.WinData.SettleData.NieRBossFightResult then
        return
    end
    local stageId = self.WinData.StageId
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    local data = self.WinData.SettleData.NieRBossFightResult
    local info = XDataCenter.FubenManager.GetStageInfo(stageId)

    self.TxtTile.text = XDataCenter.FubenManager.GetStageName(stageId)
    self.PanelNewRecord.gameObject:SetActiveEx(data.TotalScore > data.TotalHighScore)
    
    self.PanelBossLoseHp.gameObject:SetActiveEx(true)
    self.PanelSurplusHp.gameObject:SetActiveEx(true)
    self.PanelLeftTime.gameObject:SetActiveEx(false)
    self.PanelGroupCount.gameObject:SetActiveEx(true)

    local SetMaxTextDesc = function(text, ponit)
        text.text = ""
        -- if ponit > 0 then
        --     text.text = CS.XTextManager.GetText("NieRMaxSingleScore", ponit)
        -- else
        --     text.text = CS.XTextManager.GetText("NieRMaxSingleNoScore")
        -- end
    end
    
    SetMaxTextDesc(self.TxtHitSocreMax, 0)
    SetMaxTextDesc(self.TxtRemainHpScoreMax, 0)
    SetMaxTextDesc(self.TxtGroupCountScoreMax, data.HpMaxScore or 0)

    -- ????????????
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)

    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        -- ?????????
        
        local hitCombo = math.floor(f * data.BaseScore)
        local hitScore = '+' .. math.floor(f * data.BaseScore)
        self.TxtHitCombo.text = hitCombo
        self.TxtHitScore.text = hitScore


        -- ?????????

        local remainHp = math.floor(f * data.Damage)
        local remainHpScore = '+' .. math.floor(f * data.DamageScore)
        self.TxtRemainHp.text = remainHp
        self.TxtRemainHpScore.text = remainHpScore
  
    
        -- ????????????
        local groupCount = math.floor(f * data.HpLeftPer) .. "%"
        local groupCountSacore = '+' .. math.floor(f * data.HpScore)
        self.TxtGroupCount.text = groupCount
        self.TxtGroupCountScore.text = groupCountSacore


        -- ????????????
        local costTime = XUiHelper.GetTime(math.floor(f * data.UseTime), XUiHelper.TimeFormatType.SHOP)
        self.TxtCostTime.text = costTime

        -- ????????????
        local point = math.floor(f * data.TotalScore)
        
        self.TxtPoint.text = point

        -- ???????????????
        local highScore = math.floor(f * data.TotalHighScore)
        self.TxtHighScore.text = highScore

    end, function()
        self:StopAudio()
    end)
end