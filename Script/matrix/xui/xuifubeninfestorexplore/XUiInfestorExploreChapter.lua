local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridFubenInfestorExploreChapter = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreChapter")

local XUiInfestorExploreChapter = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreChapter")

function XUiInfestorExploreChapter:OnAwake()
    self:AutoAddListener()
    self.GridFubenInfestorExploreChapter.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiInfestorExploreChapter:OnStart()
    self:InitView()
end

function XUiInfestorExploreChapter:OnEnable()
    self:RefreshView()
end

function XUiInfestorExploreChapter:OnDestroy()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExplore)
end

function XUiInfestorExploreChapter:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_RESET }
end

function XUiInfestorExploreChapter:OnNotify(evt, ...)
    if evt == XEventId.EVENT_INFESTOREXPLORE_RESET then
        XDataCenter.FubenInfestorExploreManager.Reset()
    end
end

function XUiInfestorExploreChapter:InitView()
    self.TxtBuffDes.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    self.TxtTile.text = XDataCenter.FubenInfestorExploreManager.GetCurSectionName()
    self.TxtLeftTimeDes.text = CSXTextManagerGetText("InfestorExplorLeftTimeDesSection1")
    XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExplore, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
        self.TxtTime.text = timeText
    end)
end

function XUiInfestorExploreChapter:RefreshView()
    self.ChapterGrids = self.ChapterGrids or {}

    local index = 1
    local chapterConfigs = XFubenInfestorExploreConfigs.GetChapterConfigs()
    for chapterId in pairs(chapterConfigs) do
        local grid = self.ChapterGrids[chapterId]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridFubenInfestorExploreChapter, self["Chapter0" .. index])
            local clickCb = function()
                if XDataCenter.FubenInfestorExploreManager.IsChapterTeamExist(chapterId) then
                    XLuaUiManager.Open("UiInfestorExploreStage", chapterId)
                else
                    self:OpenOneChildUi("UiInfestorExploreChapterDetail", chapterId)
                    self:FindChildUiObj("UiInfestorExploreChapterDetail"):RefreshView(chapterId)
                end
            end
            grid = XUiGridFubenInfestorExploreChapter.New(go, clickCb)
            grid.GameObject:SetActiveEx(true)
            self.ChapterGrids[chapterId] = grid
        end
        grid:Refresh(chapterId)
        index = index + 1
    end
end

function XUiInfestorExploreChapter:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelpCourse, "InfestorExplore")
end

function XUiInfestorExploreChapter:OnBtnBackClick()
    self:Close()
end

function XUiInfestorExploreChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end