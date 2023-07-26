local XUiTRPGPanelTask = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelTask")
local XUiTRPGPanelPlotTab = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelPlotTab")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")

local tonumber = tonumber
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiTRPGExploreChapterStage = XLuaUiManager.Register(XLuaUi, "UiTRPGExploreChapterStage")

function XUiTRPGExploreChapterStage:OnAwake()
    self:AutoAddListener()
    XUiTRPGPanelPlotTab.New(self.PanelPlotTab)
    self.TaskPanel = XUiTRPGPanelTask.New(self.PanelTask, self)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)
    self.GridPanelChapterStage.gameObject:SetActiveEx(false)
end

function XUiTRPGExploreChapterStage:OnStart(thirdAreaId, secondAreaId, mainAreaId)
    self.SecondAreaId = secondAreaId
    self.MainAreaId = mainAreaId
    self.ThirdAreaId = thirdAreaId
    self.FunctionGrids = {}

    self:InitUi()
end

function XUiTRPGExploreChapterStage:OnEnable()
    self.TaskPanel:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_FUNCTION_FINISH_SYN, self.UpdateFunctionBtns, self)
    XDataCenter.TRPGManager.CheckActivityEnd()
    self:UpdateFunctionBtns()
end

function XUiTRPGExploreChapterStage:OnDisable()
    self.TaskPanel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_FUNCTION_FINISH_SYN, self.UpdateFunctionBtns, self)
end

function XUiTRPGExploreChapterStage:OnDestroy()
    self.TaskPanel:Delete()
    self.LevelPanel:Delete()
end

function XUiTRPGExploreChapterStage:InitUi()
    local secondAreaId = self.SecondAreaId
    local mainAreaId = self.MainAreaId
    local thirdAreaId = self.ThirdAreaId

    local bg = XTRPGConfigs.GetThirdAreaBg(thirdAreaId)
    self.RImgBg:SetRawImage(bg)

    local name = XTRPGConfigs.GetThirdAreaName(thirdAreaId)
    self.TxtName.text = name

    local enName = XTRPGConfigs.GetThirdAreaEnName(thirdAreaId)
    self.TxtEnName.text = enName
end

function XUiTRPGExploreChapterStage:UpdateFunctionBtns()
    local thirdAreaId = self.ThirdAreaId

    if XDataCenter.TRPGManager.IsThirdAreaFunctionAllFinish(thirdAreaId) then
        self:Close()
        return
    end

    local functionIdList = XDataCenter.TRPGManager.GetUnFinishedFunctionIdList(thirdAreaId)
    for index, functionId in ipairs(functionIdList) do
        local grid = self.FunctionGrids[index]
        if not grid then
            local ui = index == 1 and self.GridPanelChapterStage or CSUnityEngineObjectInstantiate(self.GridPanelChapterStage.gameObject, self.PanelChapter)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.FunctionGrids[index] = grid
        end

        local uiButton = grid.BtnClick

        local icon = XTRPGConfigs.GetFunctionIcon(functionId)
        uiButton:SetSprite(icon)

        local name = XTRPGConfigs.GetFunctionDesc(functionId)
        uiButton:SetName(name)

        local showTag = XTRPGConfigs.IsFunctionShowTag(functionId)
        uiButton:ShowTag(showTag)

        local paramFunctionId = functionId
        uiButton.CallBack = function()
            self:OnClickBtnStage(paramFunctionId)
        end

        grid.GameObject:SetActiveEx(true)
    end

    for index = #functionIdList + 1, #self.FunctionGrids do
        local grid = self.FunctionGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    XDataCenter.TRPGManager.CheckOpenNewMazeTips()
end

function XUiTRPGExploreChapterStage:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
end

function XUiTRPGExploreChapterStage:OnClickBtnStage(functionId)
    local params = XTRPGConfigs.GetFunctionParams(functionId)

    if XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Story) then
        local movieId = params[1]
        local cb = function()
            XDataCenter.TRPGManager.RequestFunctionFinishSend(nil, functionId)
        end
        XDataCenter.MovieManager.PlayMovie(movieId, cb)
    elseif XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Shop) then
        local shopId = tonumber(params[1])
        XLuaUiManager.Open("UiTRPGExploreShop", shopId, self.SecondAreaId, self.ThirdAreaId)
    elseif XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.CommitItem) then
        XDataCenter.TRPGManager.RequestFunctionFinishSend(nil, functionId)
    elseif XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.FinishStage) then
        XDataCenter.TRPGManager.EnterFunctionFight(functionId)
    elseif XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Examine) then
        local examineId = tonumber(params[1])
        XDataCenter.TRPGManager.EnterFunctionFight(examineId)
    end
end

function XUiTRPGExploreChapterStage:OnBtnBackClick()
    self:Close()
end

function XUiTRPGExploreChapterStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGExploreChapterStage:OnGetEvents()
    return {XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE}
end

function XUiTRPGExploreChapterStage:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end