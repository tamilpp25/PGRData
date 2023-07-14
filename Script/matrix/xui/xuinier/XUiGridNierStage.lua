local XUiGridNierStage = XClass(nil, "XUiGridNierStage")

function XUiGridNierStage:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Transform3d = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GameObject:SetActiveEx(true)
    self.GridAssignStage.CallBack = function() self:OnBtnStageClick() end
    
end

function XUiGridNierStage:UpdateNieRStageGrid(stageId, nierStageType, index, labelStr)
    self.StageId = stageId
    self.StageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    
    self.NierStageType = nierStageType
    self.TextNameNormal.text = self.StageConfig.Name
    local stageIsPassed = XDataCenter.FubenManager.CheckStageIsPass(stageId)
    if self.NierStageType == XNieRConfigs.NieRStageType.BossStage then
        local nieRBoss = XDataCenter.NieRManager.GetNieRBossDataById(stageId)
        local leftHp = nieRBoss:GetLeftHp()
        local maxHp = nieRBoss:GetMaxHp()
        self.ImgFubenEnd.gameObject:SetActiveEx(leftHp == 0)
        
        if not XDataCenter.FubenManager.CheckStageIsUnlock(stageId) then
            self.GridAssignStage:SetDisable(true, true)
            self.TextNameDisable.text = self.StageConfig.Name
            self.RImgStageDisable:SetRawImage(self.StageConfig.Icon)
        else
            self.GridAssignStage:SetDisable(false, true)
            self.ImgJinduNormal.fillAmount = (maxHp - leftHp) / maxHp
            self.TextJinduNormal.text = string.format("%d%s",math.floor( (maxHp - leftHp) / maxHp * 100), "%")
        end
    elseif self.NierStageType == XNieRConfigs.NieRStageType.RepeatPoStage then
        self.TextLabelNormal.text = labelStr or ""
        --self.TextLabelDisable.text = labelStr
        self.ImgFubenEnd.gameObject:SetActiveEx(stageIsPassed)
    elseif self.NierStageType == XNieRConfigs.NieRStageType.Teaching then
        self.Red.gameObject:SetActiveEx(not stageIsPassed)
        self.ImgFubenEnd.gameObject:SetActiveEx(stageIsPassed)
    else
        self.ImgFubenEnd.gameObject:SetActiveEx(stageIsPassed)
    end
    self.RImgStageNormal:SetRawImage(self.StageConfig.Icon)
end

function XUiGridNierStage:OnBtnStageClick()
    local condit, desc
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageInfo.Unlock then
        condit, desc = false, XDataCenter.FubenManager.GetFubenOpenTips(self.StageId)
    else
        condit = true
    end
    if condit then
        if self.NierStageType == XNieRConfigs.NieRStageType.Teaching then
            XLuaUiManager.Open("UiFubenStageDetail", self.StageConfig, nil, true)
        else
            XLuaUiManager.Open("UiFubenNierGuanqiaNormal", self.StageId, self.NierStageType, nil, self.RootUi.CurChapterId)
        end
    else
        XUiManager.TipMsg(desc)
    end
    
end

return XUiGridNierStage