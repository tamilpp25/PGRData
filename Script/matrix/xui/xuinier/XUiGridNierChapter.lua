local XUiGridNierChapter = XClass(nil, "XUiGridNierChapter")

function XUiGridNierChapter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Transform3d = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridNierChapter:UpdateChapterGrid(chapterData, needShowDelData)
    if not needShowDelData then
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelEffect.gameObject:SetActiveEx(false)
        local isUnLock  = chapterData:CheckNieRChapterUnLock()
        if not isUnLock then
            self.PanelChapter.gameObject:SetActiveEx(false)
            self.ImgRedDot.gameObject:SetActiveEx(false)
            self.ImgFinish.gameObject:SetActiveEx(false)
            self.PanelChapterLock.gameObject:SetActiveEx(true)
            self:UpdateLockedPanel(chapterData)
        else
            self.PanelChapter.gameObject:SetActiveEx(true)
            self.ImgRedDot.gameObject:SetActiveEx(false)
            self.ImgFinish.gameObject:SetActiveEx(false)
            self.PanelChapterLock.gameObject:SetActiveEx(false)
            self:UpdateUnLockPanel(chapterData)
        end
    else
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(true)
    end
end

function XUiGridNierChapter:UpdateUnLockPanel(chapterData)
    self.TextPart.text =  chapterData:GetNieRChapterName()
    self.ImgPercentNormal.fillAmount = 0
    self.TxtPercentNormal.text = CS.XTextManager.GetText("NieRChapterPercentStr", chapterData:GetIndex())
    self.RImgChapter:SetRawImage(chapterData:GetNieRChapterIcon())

    if XDataCenter.FubenManager.GetStageInfo(chapterData:GetNieRBossStageId()).Unlock then
        self.ImgPercentNormal.gameObject:SetActiveEx(true)
        self.TxtPercentNormalBg.gameObject:SetActiveEx(true)
        local nieRBoss = XDataCenter.NieRManager.GetNieRBossDataById(chapterData:GetNieRBossStageId()) 
        local leftHp = nieRBoss:GetLeftHp()
        local maxHp = nieRBoss:GetMaxHp()
        self.ImgPercentNormal.fillAmount = (maxHp - leftHp) / maxHp
        self.TxtPercentNormal.text = string.format("%d%%",math.floor( (maxHp - leftHp) / maxHp * 100))
        self.TxtPercentNormalBg.text = string.format("%d%%",math.floor( (maxHp - leftHp) / maxHp * 100))
        self.ImgFinish.gameObject:SetActiveEx(leftHp <= 0)  
        
        -- local needShowDelData = XDataCenter.NieRManager.GetNieREasterEggStageShow()
        -- if not needShowDelData then
            
        -- else
        --     self.TxtTitlePart.text = CS.XTextManager.GetText("NieRChapterPhaseStr", 3)
        --     self.TextTitleDesc.text = CS.XTextManager.GetText("NieRChapterBossRate")
        -- end
        
        self.TxtTitlePart.text = CS.XTextManager.GetText("NieRChapterPhaseStr", 2)
        self.TextTitleDesc.text = CS.XTextManager.GetText("NieRChapterBossRate")
    else
        local stageIds = chapterData:GetNierChapterStageIds()
        local stageNum = #stageIds
        local passNum = 0
        for index, stageId in ipairs(stageIds) do
            if index ~= chapterData:GetNieRRepeatPoStagePos() and XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                passNum = passNum + 1
            end
        end
        self.ImgPercentNormal.fillAmount = passNum / (stageNum - 1)
        self.TxtPercentNormal.text = string.format("%d/%d", passNum, (stageNum - 1))
        self.TxtPercentNormalBg.text = string.format("%d%%", math.floor( passNum / (stageNum - 1))* 100)
        self.TxtTitlePart.text = CS.XTextManager.GetText("NieRChapterPhaseStr", 1)
        self.TextTitleDesc.text = CS.XTextManager.GetText("NieRChapterOtherRate")
    end
    
end

function XUiGridNierChapter:UpdateLockedPanel(chapterData)
    local startTime = chapterData:GetNierChapterStartTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime < startTime then
        self.LockTxtDate.text = os.date("%Y/%m/%d", startTime)
    else
        self.LockTxtDate.text = ""
    end

    self.LockTextPart.text =  chapterData:GetNieRChapterName()
    self.LockRImgChapter:SetRawImage(chapterData:GetNieRChapterIcon())
end

return XUiGridNierChapter