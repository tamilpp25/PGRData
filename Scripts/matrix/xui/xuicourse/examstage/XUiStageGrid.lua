--战斗执照-执照关卡界面的格子
local XUiStageGrid = XClass(nil, "XUiStageGrid")

function XUiStageGrid:Ctor(ui, index, rootUi, clickStageCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.Index = index
    self.ClickStageCb = clickStageCb    --点击关卡回调
    self:RegisterButtonEvent()
end

function XUiStageGrid:RegisterButtonEvent()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiStageGrid:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId

    --关卡名和下标
    local index = self.Index
    local asset = XCourseConfig.GetCourseClientConfig("ExamManagementGridNumAsset").Values[index]
    if asset then
        self.RootUi:SetUiSprite(self.ImgNumber, asset)
    end
    self.TxtName.text = XFubenConfigs.GetStageName(stageId)

    --星星控件
    local starPointList = XCourseConfig.GetCourseStageStarPointById(stageId)
    local clearStarCount = XDataCenter.CourseManager.GetStageStarsCount(stageId)
    for index in ipairs(starPointList) do
        if self["Img" .. index] then
            self["Img" .. index].gameObject:SetActiveEx(clearStarCount >= index)
        end
        if self["Star" .. index] then
            self["Star" .. index].gameObject:SetActiveEx(true)
        end
    end

    --隐藏多余的控件
    local index = #starPointList + 1
    local star = self["Star" .. index]
    while not XTool.UObjIsNil(star) do
        star.gameObject:SetActiveEx(false)
        index = index + 1
        star = self["Star" .. index]
    end

    self.PanelStagePass.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckStageIsComplete(stageId))
end

function XUiStageGrid:OnBtnStageClick()
    self:SetSelectActive(true)
    self.RootUi.ChildUiCoursePrepare:UpdateData(self.StageId, self.ChapterId)
    --self.RootUi:OpenOneChildUi("UiCoursePrepare")
    if self.ClickStageCb then
        self.ClickStageCb(self)
    end
end

function XUiStageGrid:SetSelectActive(isActive)
    self.PanelSelect.gameObject:SetActiveEx(isActive)
end

function XUiStageGrid:GetStageId()
    return self.StageId
end

function XUiStageGrid:GetIndex()
    return self.Index
end

return XUiStageGrid