-- ConditionShow
-- ================================================================================
local XUiGridConItem = XClass(nil, "XUiGridConItem")
function XUiGridConItem:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, self.Ui)

    self.UiGridCommon = XUiGridCommon.New(self.GridCommon)
end

function XUiGridConItem:RefreshUi(isClear, desc, point)
    self.UiGridCommon:Refresh(XDataCenter.CourseManager.GetTipShowItemData())
    self.PanelActive.gameObject:SetActiveEx(isClear)
    self.PanelUnActive.gameObject:SetActiveEx(not isClear)
    self.PanelActive.text = desc
    self.PanelUnActive.text = desc
    self.TxtCount.text = XUiHelper.GetText("EquipReformSelectItemDisplay", point)
    self.UiGridCommon:ShowCount(true)
end


-- 课程关卡详情界面
-- ================================================================================
local XUiCourseStageDetailDP = XLuaUiManager.Register(XLuaUi,"UiCourseStageDetailDP")

function XUiCourseStageDetailDP:OnAwake()
    self:AddButtonListenr()
    self.GridCondition.gameObject:SetActiveEx(false)
end

function XUiCourseStageDetailDP:OnStart(stageId)
    self.StageId = stageId
    self.Conditions = {}
    self.PanelAsset.gameObject:SetActiveEx(false)
end

function XUiCourseStageDetailDP:OnEnable()
    self:RefreshUi()
end

function XUiCourseStageDetailDP:UpdateData(stageId)
    self.StageId = stageId
end

function XUiCourseStageDetailDP:RefreshUi()
    self:RefreshStage()
    self:RefreshCondition()
end

function XUiCourseStageDetailDP:RefreshStage()
    local stageId = self.StageId
    local showTypeId = XCourseConfig.GetCourseStageShowTypeByStageId(stageId)
    self.TxtStageName.text = XCourseConfig.GetCourseStageNameById(stageId)
    self.TxtStoryDes.text = XDataCenter.FubenManager.GetStageDes(stageId)
    self.TxtTypeName.text = XCourseConfig.GetStageShowTypeName(showTypeId)
    self.TxtTypeDescTitle.text = XCourseConfig.GetStageShowTypeTxtDescTitle(showTypeId)
    self.TxtTypeRewardTitle.text = XCourseConfig.GetStageShowTypeTxtRewardTitle(showTypeId)
    self.ImgTypeIcon:SetSprite(XCourseConfig.GetStageShowTypeIconPath(showTypeId))
end

function XUiCourseStageDetailDP:RefreshCondition()
    local stageId = self.StageId
    local starDesc = XFubenConfigs.GetStarDesc(stageId)
    local starsFlag = XDataCenter.CourseManager.GetStageStarsFlagMap(stageId)
    local pointRewards = XCourseConfig.GetCourseStageStarPointById(self.StageId)
    for index, value in ipairs(starDesc) do
        if XTool.IsTableEmpty(self.Conditions[index]) then
            self.Conditions[index] = XUiGridConItem.New(XUiHelper.Instantiate(self.GridCondition, self.PanelAllCondition))
        end
        self.Conditions[index]:RefreshUi(starsFlag[index], starDesc[index], pointRewards[index])
    end

    for i, grid in pairs(self.Conditions or {}) do
        grid.GameObject:SetActiveEx(i <= #starDesc)
    end
end

function XUiCourseStageDetailDP:AddButtonListenr()
    self:RegisterClickEvent(self.BtnReward, self.OnBtnRewardClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

-- 进入战斗房间
function XUiCourseStageDetailDP:OnBtnEnterClick()
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
end

-- 显示首通奖励
function XUiCourseStageDetailDP:OnBtnRewardClick()
    XLuaUiManager.Open("UiCourseObtain", self.StageId)
end