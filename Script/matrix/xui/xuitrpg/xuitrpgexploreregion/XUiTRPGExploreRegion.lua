local Object
local XUiTRPGPanelTask = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelTask")
local XUiTRPGPanelPlotTab = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelPlotTab")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")
local XUiTRPGExploreRegionChapter = require("XUi/XUiTRPG/XUiTRPGExploreRegion/XUiTRPGExploreRegionChapter")

--区域（城市和迷宫）地图
local XUiTRPGExploreRegion = XLuaUiManager.Register(XLuaUi, "UiTRPGExploreRegion")

function XUiTRPGExploreRegion:OnAwake()
    Object = CS.UnityEngine.Object
    self:AutoAddListener()
    XUiTRPGPanelPlotTab.New(self.PanelPlotTab)
    self.TaskPanel = XUiTRPGPanelTask.New(self.PanelTask, self)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)

    self.GridExploreChapter.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckBtnTreasureRedPoint, self)
end

function XUiTRPGExploreRegion:OnStart(areaId)
    self.PanelChapterList = {}
    self.ChapterList = {}
    self.AreaId = areaId

    local bgPath = XTRPGConfigs.GetSecondAreaBg(areaId)
    self.Background:SetRawImage(bgPath)

    self:PlayStartStory()
end

function XUiTRPGExploreRegion:OnEnable()
    XDataCenter.TRPGManager.CheckActivityEnd()
    XDataCenter.TRPGManager.CheckOpenNewMazeTips()
    self:Refresh()
    self.TaskPanel:OnEnable()
end

function XUiTRPGExploreRegion:OnDisable()
    self.TaskPanel:OnDisable() 
end

function XUiTRPGExploreRegion:OnDestroy()
    self.TaskPanel:Delete()
    self.LevelPanel:Delete()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckBtnTreasureRedPoint, self)
end

function XUiTRPGExploreRegion:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
end

function XUiTRPGExploreRegion:OnCheckRewards(count, chapterId)
    if self.ImgRedProgress and chapterId == self.Chapter.ChapterId then
        self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
    end
end

function XUiTRPGExploreRegion:Refresh()
    self.TxtName.text = XTRPGConfigs.GetMainAreaName(self.AreaId)
    self:UpdateProgress()
    self:UpdateChapter()
    self:OnCheckBtnTreasureRedPoint()
end

function XUiTRPGExploreRegion:UpdateProgress()
    local percent = XDataCenter.TRPGManager.GetAreaRewardPercent(self.AreaId)
    self.TxtBfrtTaskTotalNum.text = math.floor(percent * 100) .. "%"
    self.ImgJindu.fillAmount = percent
end

function XUiTRPGExploreRegion:UpdateChapter()
    if not self.ChapterList[self.AreaId] then
        self.ChapterList[self.AreaId] = {}
    end
    for i = 1, XTRPGConfigs.GetMainAreaMaxNum() do
        self["PanelChapter" .. i].gameObject:SetActiveEx(i == self.AreaId)
    end

    local secondAreaIdList = XTRPGConfigs.GetSecondAreaIdList(self.AreaId)
    for i, secondAreaId in ipairs(secondAreaIdList) do
        if not self.ChapterList[self.AreaId][i] and self["Chapter" .. self.AreaId .. i] then
            local gridExploreChapter = XUiTRPGExploreRegionChapter.New(Object.Instantiate(self.GridExploreChapter), secondAreaId, self.AreaId)
            gridExploreChapter.Transform:SetParent(self["Chapter" .. self.AreaId .. i].transform, false)
            gridExploreChapter.GameObject:SetActiveEx(true)
            self.ChapterList[self.AreaId][i] = gridExploreChapter
        end
        self.ChapterList[self.AreaId][i]:Refresh()
    end
end

--进度领奖
function XUiTRPGExploreRegion:OnBtnTreasureClick()
    local rewardIdList = XTRPGConfigs.GetAreaRewardIdList(self.AreaId)
    XLuaUiManager.Open("UiTRPGRewardTip", rewardIdList)
end

function XUiTRPGExploreRegion:OnBtnBackClick()
    self:Close()
end

function XUiTRPGExploreRegion:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGExploreRegion:PlayStartStory()
    local firstOpenFunctionGroupId = XTRPGConfigs.GetMainAreaFirstOpenFunctionGroupId(self.AreaId)
    if firstOpenFunctionGroupId == 0 then return end

    if not XDataCenter.TRPGManager.IsFunctionGroupConditionFinish(firstOpenFunctionGroupId) then
        return
    end

    local functionIds = XTRPGConfigs.GetFunctionGroupFunctionIds(firstOpenFunctionGroupId)
    for _, functionId in ipairs(functionIds) do
        if not XDataCenter.TRPGManager.IsThirdAreaFunctionFinish(nil, functionId) then
            if XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Story) then
                local params = XTRPGConfigs.GetFunctionParams(functionId)
                local movieId = params[1]
                local cb = function()
                    XDataCenter.TRPGManager.RequestFunctionFinishSend(nil, functionId)
                end
                XDataCenter.MovieManager.PlayMovie(movieId, cb)
            end
        end
    end
end

function XUiTRPGExploreRegion:OnCheckBtnTreasureRedPoint()
    local isShow = XDataCenter.TRPGManager.CheckAreaRewardByAreaId(self.AreaId)
    self.ImgRedProgress.gameObject:SetActiveEx(isShow)
end

function XUiTRPGExploreRegion:OnGetEvents()
    return {XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE}
end

function XUiTRPGExploreRegion:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end