--城市内地图
local XUiTRPGExploreChapter = XLuaUiManager.Register(XLuaUi, "UiTRPGExploreChapter")

local XUiTRPGPanelTask = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelTask")
local XUiTRPGPanelPlotTab = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelPlotTab")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")

function XUiTRPGExploreChapter:OnAwake()
    self.GridList = {}
    self:AutoAddListener()
    XUiTRPGPanelPlotTab.New(self.PanelPlotTab)
    self.TaskPanel = XUiTRPGPanelTask.New(self.PanelTask, self)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)
end

function XUiTRPGExploreChapter:OnStart(secondAreaId, mainAreaId)
    XDataCenter.TRPGManager.SaveIsAlreadyOpenExploreChapter(secondAreaId, mainAreaId)
    self.SecondAreaId = secondAreaId
    self.MainAreaId = mainAreaId

    self.TxtName.text = XTRPGConfigs.GetSecondAreaName(secondAreaId)

    local bgPath = XTRPGConfigs.GetExploreChapterBg(secondAreaId)
    self.Background:SetRawImage(bgPath)

    local btnName, iconPath
    local thirdAreaIdList = XTRPGConfigs.GetThirdAreaIdList(secondAreaId)
    for i, thirdAreaId in ipairs(thirdAreaIdList) do
        if not self.GridList[i] then
            local grid
            if i == 1 then
                grid = self.GridPanelChapter
            else
                grid = CS.UnityEngine.Object.Instantiate(self.GridPanelChapter)
                grid.transform:SetParent(self.PanelChapter, false)
            end
            local thirdAreaIdTemp = thirdAreaId
            self:RegisterClickEvent(grid, function() self:OnGridClick(thirdAreaIdTemp) end)
            self.GridList[i] = grid
        end
        btnName = XTRPGConfigs.GetThirdAreaName(thirdAreaId)
        iconPath = XTRPGConfigs.GetThirdAreaIcon(thirdAreaId)
        self.GridList[i]:SetName(btnName)
        self.GridList[i]:SetRawImage(iconPath)
    end
end

function XUiTRPGExploreChapter:OnEnable()
    XDataCenter.TRPGManager.CheckActivityEnd()
    XDataCenter.TRPGManager.CheckOpenNewMazeTips()
    self:Refresh()
    self.TaskPanel:OnEnable()
end

function XUiTRPGExploreChapter:OnDisable()
    self.TaskPanel:OnDisable() 
end

function XUiTRPGExploreChapter:OnDestroy()
    self.TaskPanel:Delete()
    self.LevelPanel:Delete()
end

function XUiTRPGExploreChapter:Refresh()
    self:UpdateGridList()
end

function XUiTRPGExploreChapter:UpdateGridList()
    local thirdAreaIdList = XTRPGConfigs.GetThirdAreaIdList(self.SecondAreaId)
    local conditionId
    local ret
    local isThirdAreaFunctionAllFinish
    for i, thirdAreaId in ipairs(thirdAreaIdList) do
        conditionId = XTRPGConfigs.GetThirdAreaCondition(thirdAreaId)
        ret = XConditionManager.CheckCondition(conditionId)
        isThirdAreaFunctionAllFinish = XDataCenter.TRPGManager.IsThirdAreaFunctionAllFinish(thirdAreaId)
        self.GridList[i].gameObject:SetActiveEx(ret and not isThirdAreaFunctionAllFinish)
    end
end

function XUiTRPGExploreChapter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
end

function XUiTRPGExploreChapter:OnGridClick(thirdAreaId)
    local secondAreaId = self.SecondAreaId
    local mainAreaId = self.MainAreaId
    XLuaUiManager.Open("UiTRPGExploreChapterStage", thirdAreaId, secondAreaId, mainAreaId)
end

function XUiTRPGExploreChapter:OnBtnBackClick()
    self:Close()
end

function XUiTRPGExploreChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGExploreChapter:OnGetEvents()
    return {XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE}
end

function XUiTRPGExploreChapter:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end