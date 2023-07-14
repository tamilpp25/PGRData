--常规主线主界面
local XUiTRPGSecondMain = XLuaUiManager.Register(XLuaUi, "UiTRPGSecondMain")

function XUiTRPGSecondMain:OnAwake()
    self.IsSwitchStatusOpenView = false     --是否从切换模式按钮打开本界面
    self:AutoAddListener()
end

function XUiTRPGSecondMain:OnStart(isSwitchStatusOpenView)
    self.IsSwitchStatusOpenView = isSwitchStatusOpenView
    self.RedMain = XRedPointManager.AddRedPointEvent(self.PanelCut, self.OnCheckMainRedPoint, self, { XRedPointConditions.Types.CONDITION_TRPG_MAIN_MODE }, nil, true)
end

function XUiTRPGSecondMain:OnEnable()
    local openAnimaName = self.IsSwitchStatusOpenView and "QieHuan" or "Enable"
    self:PlayAnimation(openAnimaName)
    self.IsSwitchStatusOpenView = false

    self:Refresh()
    self:OnCheckRedPoint()
end

function XUiTRPGSecondMain:Refresh()
    local percent
    local condition
    local secondMainIdList = XTRPGConfigs.GetSecondMainIdList()
    local ret
    for i, secondMainId in ipairs(secondMainIdList) do
        percent = XDataCenter.TRPGManager.GetSecondMainStagePercent(secondMainId)
        self["PanelEntrance" .. i]:SetName(math.floor(percent * 100) .. "%")

        ret = XDataCenter.TRPGManager.CheckSecondMainCondition(secondMainId)
        self["PanelEntrance" .. i]:SetDisable(not ret)
    end
end

function XUiTRPGSecondMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
    self:RegisterClickEvent(self.PanelCut, self.OnPanelCutClick)

    local secondMainIdList = XTRPGConfigs.GetSecondMainIdList()
    for i, secondMainId in ipairs(secondMainIdList) do
        self["PanelEntrance" .. i].CallBack = function() self:OnGridPanelChapterClick(secondMainId) end
    end
end

function XUiTRPGSecondMain:OnGridPanelChapterClick(secondMainId)
    local ret, desc = XDataCenter.TRPGManager.CheckSecondMainCondition(secondMainId)
    if not ret then
        XUiManager.TipError(desc)
        return
    end
    XLuaUiManager.Open("UiTRPGTruthRoadSecondMain", secondMainId)
end

function XUiTRPGSecondMain:OnCheckRedPoint()
    local secondMainIdList = XTRPGConfigs.GetSecondMainIdList()
    local isShowRedPoint
    for i, secondMainId in ipairs(secondMainIdList) do
        isShowRedPoint = XDataCenter.TRPGManager.IsSecondMainCanReward(secondMainId)
        self["PanelEntrance" .. i]:ShowReddot(isShowRedPoint)
    end

    if self.RedMain then
        XRedPointManager.Check(self.RedMain)
    end
end

function XUiTRPGSecondMain:OnCheckMainRedPoint(count)
    self.PanelCut:ShowReddot(count >= 0)
end

function XUiTRPGSecondMain:OnPanelCutClick()
    XDataCenter.TRPGManager.RequestTRPGChangePageStatus(false)
    XLuaUiManager.PopThenOpen("UiTRPGMain", true)
end

function XUiTRPGSecondMain:OnBtnBackClick()
    self:Close()
end

function XUiTRPGSecondMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end