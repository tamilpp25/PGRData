local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridFubenInfestorExploreChapter2Stage = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreChapter2Stage")

local XUiInfestorExploreChapterPart2 = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreChapterPart2")

function XUiInfestorExploreChapterPart2:OnAwake()
    self:AutoAddListener()
    self.GridFubenInfestorExploreChapter2.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiInfestorExploreChapterPart2:OnStart()
    self:InitView()
end

function XUiInfestorExploreChapterPart2:OnEnable()
    self:RefreshView()
end

function XUiInfestorExploreChapterPart2:OnDestroy()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExplore)
end

function XUiInfestorExploreChapterPart2:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_RESET }
end

function XUiInfestorExploreChapterPart2:OnNotify(evt, ...)
    if evt == XEventId.EVENT_INFESTOREXPLORE_RESET then
        XDataCenter.FubenInfestorExploreManager.Reset()
    end
end

function XUiInfestorExploreChapterPart2:InitView()
    self.TxtBuffDes.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
    self.TxtLeftTimeDes.text = CSXTextManagerGetText("InfestorExplorLeftTimeDesSection2")
    self.TxtTile.text = XDataCenter.FubenInfestorExploreManager.GetCurSectionName()
        XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExplore, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
        self.TxtTime.text = timeText
    end)
end

function XUiInfestorExploreChapterPart2:RefreshView()
    self.StageGrids = self.StageGrids or {}

    local index = 1
    local stageIds = XDataCenter.FubenInfestorExploreManager.GetChapter2StageIds()
    for _, stageId in pairs(stageIds) do
        local grid = self.StageGrids[stageId]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridFubenInfestorExploreChapter2, self["Chapter0" .. index])
            local clickCb = function(paramStageId)
                self:OpenOneChildUi("UiInfestorExploreChapterPart2Detail", paramStageId)
                self:FindChildUiObj("UiInfestorExploreChapterPart2Detail"):RefreshView(paramStageId)
            end
            grid = XUiGridFubenInfestorExploreChapter2Stage.New(go, clickCb)
            grid.GameObject:SetActiveEx(true)
            self.StageGrids[stageId] = grid
        end
        grid:Refresh(stageId)
        index = index + 1
    end

    self.TxtScore.text = XDataCenter.FubenInfestorExploreManager.GetPlayerScore(XPlayer.Id)
end

function XUiInfestorExploreChapterPart2:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelpCourse, "InfestorExplore2")
    self.BtnNegativeEffects.CallBack = function() self:OnClickBtnNegativeEffects() end
    self.BtnTacticalCore.CallBack = function() self:OnClickBtnTacticalCore() end
end

function XUiInfestorExploreChapterPart2:OnBtnBackClick()
    self:Close()
end

function XUiInfestorExploreChapterPart2:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiInfestorExploreChapterPart2:OnClickBtnNegativeEffects()
    XLuaUiManager.Open("UiInfestorExploreDebuff")
end

function XUiInfestorExploreChapterPart2:OnClickBtnTacticalCore()
    XLuaUiManager.Open("UiInfestorExploreCore")
end