-- 组合小游戏
local XUiComposeGame = XLuaUiManager.Register(XLuaUi, "UiComposeGame")
local COMPOSE_ANIME_TIME = 500
function XUiComposeGame:OnAwake()
    XTool.InitUiObject(self)
    self:InitButtons()
end

function XUiComposeGame:OnStart(gameId)
    self.Game = XDataCenter.ComposeGameManager.GetGameById(gameId)
    local asset = XUiPanelAsset.New(self, self.PanelAsset, self.Game:GetCoinId())
    asset:RegisterJumpCallList({[1] = function()
                XLuaUiManager.Open("UiTip", self.Game:GetCoinId())
                end})
    self:InitPanels()
end

function XUiComposeGame:OnEnable()
    self:SetTimer()
    self:RefreshPanels()
    if XDataCenter.ComposeGameManager.GetIsFirstIn(self.Game:GetGameId()) then
        local storyId = self.Game:GetBeginStoryId()
        if string.IsNilOrEmpty(storyId) then
            XDataCenter.ComposeGameManager.DebugLog("已确认首次进入，但是取得StoryId失败!")
            return
        end
        XDataCenter.MovieManager.PlayMovie(storyId)
    end
end

function XUiComposeGame:OnDisable()
    self:StopTimer()
end
--================
--设置页面计时器
--================
function XUiComposeGame:SetTimer()
    self:StopTimer()
    self:SetRefreshTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetRefreshTime()
            self:SetGameTimer()
        end, XScheduleManager.SECOND, 0)
end
--================
--设置刷新时间
--================
function XUiComposeGame:SetRefreshTime()
    local refreshTime = self.Game:GetRefreshTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = refreshTime - now
    if leftTime < 0 then leftTime = 0 end
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.RefreshPanel:SetRefreshTime(remainTime)
end
--================
--设置活动倒计时
--================
function XUiComposeGame:SetGameTimer()
    local endTimeSecond = self.Game:GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    if leftTime <= 0 then
        self:OnGameEnd()
    end
end
--================
--停止计时器
--================
function XUiComposeGame:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    if self.ComposeItemTimer then
        if self.ComposingItem then self.ComposingItem:Empty() end
        self.ComposingItem = nil
        XScheduleManager.UnSchedule(self.ComposeItemTimer)
        self.ComposeItemTimer = nil
    end
end

function XUiComposeGame:OnGetEvents()
    return { XEventId.EVENT_COMPOSEGAME_RESET,
        XEventId.EVENT_COMPOSEGAME_ITEM_COMPOSE,
        XEventId.EVENT_COMPOSEGAME_BAGITEM_REFRESH,
        XEventId.EVENT_COMPOSEGAME_SHOP_ITEM_REFRESH,
        XEventId.EVENT_COMPOSEGAME_SHOP_REFRESH_TIME_CHANGE,
        XEventId.EVENT_COMPOSEGAME_SCHEDULE_REFRESH,
        XEventId.EVENT_COMPOSEGAME_TREASURE_GET,
        }
end

function XUiComposeGame:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_COMPOSEGAME_RESET then
        self:OnGameEnd()
    elseif evt == XEventId.EVENT_COMPOSEGAME_ITEM_COMPOSE then
        local item = args[1]
        self.BagPanel:UpdateData()
        self:ComposeItem(item)
    elseif evt == XEventId.EVENT_COMPOSEGAME_BAGITEM_REFRESH then
        self.BagPanel:UpdateData()        
    elseif evt == XEventId.EVENT_COMPOSEGAME_SHOP_ITEM_REFRESH then
        self.ShopPanel:UpdateData()
    elseif evt == XEventId.EVENT_COMPOSEGAME_SHOP_REFRESH_TIME_CHANGE then
        self.RefreshPanel:RefreshRecruitNumber()
    elseif evt == XEventId.EVENT_COMPOSEGAME_SCHEDULE_REFRESH then
        self.SchedulePanel:OnScheduleRefresh()
    elseif evt == XEventId.EVENT_COMPOSEGAME_TREASURE_GET then
        self.SchedulePanel:RefreshBoxes()
    end
end
--================
--初始化按钮
--================
function XUiComposeGame:InitButtons()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
end
--================
--返回按钮
--================
function XUiComposeGame:OnBtnBackClick()
    self:Close()
end
--================
--主界面按钮
--================
function XUiComposeGame:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--================
--帮助按钮
--================
function XUiComposeGame:OnBtnHelpClick()
    XUiManager.ShowHelpTip("ComposeGameHelp")
end

function XUiComposeGame:InitPanels()
    local XBag = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGamePanelBag")
    local XRefresh = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGamePanelRefresh")
    local XSchedule = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGamePanelSchedule")
    local XShop = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGamePanelShop")
    self.BagPanel = XBag.New(self, self.Game, self.PanelBagItemList)
    self.RefreshPanel = XRefresh.New(self, self.Game, self.PanelRefresh)
    self.SchedulePanel = XSchedule.New(self, self.Game, self.PanelGift)
    self.ShopPanel = XShop.New(self, self.Game, self.PanelShop)
    self.PanelCompose.gameObject:SetActiveEx(false)
    self.GridTreasure.gameObject:SetActiveEx(false)
    self.GridCommodity.gameObject:SetActiveEx(false)
    self.GridBagItem.gameObject:SetActiveEx(false)
end

function XUiComposeGame:RefreshPanels()
    self.BagPanel:UpdateData()
    self.ShopPanel:UpdateData()
    self.SchedulePanel:UpdateData()
    self.RefreshPanel:RefreshRecruitNumber()
end

function XUiComposeGame:ComposeItem(item)
    self.PanelCompose.gameObject:SetActiveEx(true)
    self.RImgComposeItem:SetRawImage(item:GetBigIcon())
    self.ComposingItem = item
    self.ComposeItemTimer = XScheduleManager.ScheduleOnce(function()
            if self.PanelEffectTuowei then self.PanelEffectTuowei.gameObject:SetActiveEx(true) end
            self.ComposeItemTimer = XScheduleManager.ScheduleOnce(function()
                    self:OnComposeEnd()
                end, COMPOSE_ANIME_TIME)
        end, COMPOSE_ANIME_TIME)
end

function XUiComposeGame:OnComposeEnd()
    self.ComposeItemTimer = nil
    if self.PanelEffectTuowei then self.PanelEffectTuowei.gameObject:SetActiveEx(false) end
    self.PanelCompose.gameObject:SetActiveEx(false)
    if self.ComposingItem then self.ComposingItem:Empty() end
    self.ComposingItem = nil
    self.SchedulePanel:SetEffectActive(true)
    self.BagPanel:UpdateData()
end

function XUiComposeGame:OnGameEnd()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ComposeGameEnd"))
end