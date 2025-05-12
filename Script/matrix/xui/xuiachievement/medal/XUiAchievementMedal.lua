local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--================
--勋章页面
--================
local XUiAchievementMedal = XLuaUiManager.Register(XLuaUi, "UiAchievementMedal")

function XUiAchievementMedal:OnStart()
    self:InitTopButtons()
    self:InitPanelAsset()
    self:InitDTable()
    --如果没播放过，播放徽章动画
    if not XDataCenter.MedalManager.CheckMedalStoryIsPlayed() then
        XDataCenter.MovieManager.PlayMovie(XDataCenter.MedalManager.MedalStroyId)
        XDataCenter.MedalManager.MarkMedalStory()
    end
    self:AddEventListeners()
end

function XUiAchievementMedal:InitTopButtons()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
end

function XUiAchievementMedal:OnClickBtnBack()
    self:Close()
end

function XUiAchievementMedal:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiAchievementMedal:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAchievementMedal:InitDTable()
    local XDTable = require("XUi/XUiAchievement/Medal/DTable/XUiAchvMedalDTable")
    self.AchievementDTable = XDTable.New(self.PanelMedalList)
end

function XUiAchievementMedal:OnEnable()
    self.AchievementDTable:Refresh()
    self:RefreshMedalCount()
end

function XUiAchievementMedal:RefreshMedalCount()
    if self.TxtMedalGetCount then
        local medals = XDataCenter.MedalManager.GetMedals()
        local count = 0
        for _, medal in pairs(medals or {}) do
            if not medal.IsLock then
                count = count + 1
            end
        end
        self.TxtMedalGetCount.text = count
    end
end

function XUiAchievementMedal:OnDisable()

end

function XUiAchievementMedal:OnDestroy()
    self:RemoveEventListeners()
end

function XUiAchievementMedal:OnMedalUse()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.AchievementDTable:Refresh()
end

function XUiAchievementMedal:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_MEDAL_USE, self.OnMedalUse, self)
end

function XUiAchievementMedal:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_MEDAL_USE, self.OnMedalUse, self)
end