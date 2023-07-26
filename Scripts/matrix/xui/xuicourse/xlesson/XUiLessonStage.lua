local XUiLessonStage = XClass(nil, "XUiLessonStage")

function XUiLessonStage:Ctor(ui, rootUi, cb, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = cb
    self.Parent = parent    --gameObject的父节点
    XTool.InitUiObject(self)
    self:RegisterUiEvents()

    local icon = XItemConfigs.GetItemIconById(XCourseConfig.GetPointItemId())
    if self.RimgNorIcon then
        self.RimgNorIcon:SetRawImage(icon)
    end
    if self.RimgDisIcon then
        self.RimgDisIcon:SetRawImage(icon)
    end
end

function XUiLessonStage:Refresh(stageId, index)
    self.StageId = stageId
    self.Index = index
    -- 刷新基本信息
    self:UpdateStageData()
    -- 刷新关卡状态
    self:RefreshStageState()
    -- 刷新关卡特效
    self:RefreshEffect(false)
end

function XUiLessonStage:UpdateStageData()
    local stageId = self.StageId
    self.IsUnlock = XDataCenter.CourseManager.CheckStageIsOpen(stageId)
    self.Clear = XDataCenter.CourseManager.CheckStageIsFullStarComplete(stageId)
    self.Name = XCourseConfig.GetCourseStageNameById(stageId)
    self.Point = XDataCenter.CourseManager.GetStageMaxPoint(stageId)

    local numImg = XCourseConfig.GetLessonStageImgNum(self.Index)
    self.RootUi:SetUiSprite(self.ImgNumberNormal, numImg)
    self.RootUi:SetUiSprite(self.ImgNumberDisable, numImg)
end

function XUiLessonStage:RefreshStageState()
    if self.IsUnlock then
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelDisable.gameObject:SetActiveEx(false)
        self.ImgClear.gameObject:SetActiveEx(self.Clear)
        self.TxtNameNormal.text = self.Name
        self.TxtCountNormal.text = self.Point
    else
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelDisable.gameObject:SetActiveEx(true)
        self.ImgClear.gameObject:SetActiveEx(false)
        self.TxtNameDisable.text = self.Name
        self.TxtCountDisable.text = self.Point
    end
end

function XUiLessonStage:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStage)
end

function XUiLessonStage:OnBtnStage()
    if not self.IsUnlock then
        local prevStages = XCourseConfig.GetCourseStagePrevStageIdById(self.StageId)
        local noClearPrevStageId
        for _, id in ipairs(prevStages) do
            if not XDataCenter.CourseManager.CheckStageIsComplete(id) then
                noClearPrevStageId = id
                break
            end
        end
        if noClearPrevStageId then
            XUiManager.TipText("ActivityBossSinglePreStage", nil, nil, XCourseConfig.GetCourseStageNameById(noClearPrevStageId))
        end
        return
    end
    
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiLessonStage:GetParentLocalPosX()
    return self.Parent.localPosition.x
end

function XUiLessonStage:RefreshEffect(show)
    if self.FocusEffect then
        self.FocusEffect.gameObject:SetActiveEx(show)
    elseif show then
        self.FocusEffect = self.Transform:LoadPrefab(XUiConfigs.GetComponentUrl("UiFxPanelEffect"))
    end
end

return XUiLessonStage