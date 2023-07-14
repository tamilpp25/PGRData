local XUiSummerStarReward = XLuaUiManager.Register(XLuaUi, "UiSummerStarReward")

local XUiGridStarReward = require("XUi/XUiSummerEpisode/XUiGridStarReward")
function XUiSummerStarReward:OnAwake()

    self.GridTreasureGrade.gameObject:SetActive(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridStarReward)

    CsXUiHelper.RegisterClickEvent(self.BtnTreasureBg, handler(self, self.Close))
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiSummerStarReward:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiSummerStarReward:SetupStarReward()
    local starRewardList = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainNormalChapterReward(self.ChapterId)
    if not starRewardList then
        return
    end

    self.StarRewardList = starRewardList

    self.DynamicTable:SetDataSource(self.StarRewardList)
    self.DynamicTable:ReloadDataSync()
end

function XUiSummerStarReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StarRewardList[index]
        if not data then return end
        grid:Refresh(data, self.ChapterId)
    end
end

function XUiSummerStarReward:OnEnable()
    local chapter = self.RootUi.CurChapter
    self.ChapterId = chapter.Id
    self:SetupStarReward()
end


function XUiSummerStarReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD then

    end
end

function XUiSummerStarReward:OnGetEvents()
    return { XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD }
end