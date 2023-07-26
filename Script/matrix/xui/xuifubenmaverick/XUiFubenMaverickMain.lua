local XUiFubenMaverickMain = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickMain")
local XUiFubenMaverickMainBanner = require("XUi/XUiFubenMaverick/XUiScrollView/XUiFubenMaverickMainBanner")

function XUiFubenMaverickMain:OnAwake()
    self:InitBanner()
    self:InitButtons()
    self:InitPanelAssets()
end

function XUiFubenMaverickMain:OnStart()
    self:SetAutoCloseInfo(XDataCenter.MaverickManager.GetEndTime(), function(isClose)
        self:SetRemainTime()
        self.MainBanner:RefreshTime()
        --检查排行榜是否开放
        self.BtnRank.gameObject:SetActiveEx(XDataCenter.MaverickManager.CheckRankOpen())
        if isClose then
            XDataCenter.MaverickManager.EndActivity()
        end
    end, nil , 0)
    
    --初始化活动标题
    self.TxtTitle.text = CSXTextManagerGetText("MaverickActivityTitle")
end

function XUiFubenMaverickMain:OnCheckTaskRedDot(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiFubenMaverickMain:OnCheckCharacterRedDot(count)
    self.BtnCharacter:ShowReddot(count >= 0)
end

function XUiFubenMaverickMain:OnEnable()
    self.Super.OnEnable(self)
    
    if XDataCenter.MaverickManager.GetIsFirstIn() then
        --XUiManager.ShowHelpTip("MaverickHelp")
    end

    self:CheckRedDots()
    self.MainBanner:Refresh()
end

function XUiFubenMaverickMain:OnGetEvents()
    return { XEventId.EVENT_MAVERICK_MEMBER_GET_TASK_REWARD }
end

function XUiFubenMaverickMain:OnNotify(evt)
    if evt == XEventId.EVENT_MAVERICK_MEMBER_GET_TASK_REWARD then
        self:ChekTaskRedDot()
    elseif evt == XEventId.EVENT_MAVERICK_MEMBER_UPDATE then
        self:ChekCharacterRedDot()
    end
end

function XUiFubenMaverickMain:CheckRedDots()
    self:ChekTaskRedDot()
    self:ChekCharacterRedDot()
end

function XUiFubenMaverickMain:ChekTaskRedDot()
    XRedPointManager.CheckOnce(self.OnCheckTaskRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_TASK })
end

function XUiFubenMaverickMain:ChekCharacterRedDot()
    XRedPointManager.CheckOnce(self.OnCheckCharacterRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER_MAIN })
end

function XUiFubenMaverickMain:InitBanner()
    self.MainBanner = XUiFubenMaverickMainBanner.New(self.PanelChapterList)
end

function XUiFubenMaverickMain:SetRemainTime()
    local endTimeSecond = XDataCenter.MaverickManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = remainTime
end

function XUiFubenMaverickMain:InitButtons()
    self:BindHelpBtn(self.BtnHelp, "MaverickHelp")
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnTask.CallBack = function() XLuaUiManager.Open("UiFubenMaverickTask") end
    self.BtnRank.CallBack = function() XLuaUiManager.Open("UiFubenMaverickRank") end
    self.BtnCharacter.CallBack = function() XLuaUiManager.Open("UiFubenMaverickCharacter") end
end

function XUiFubenMaverickMain:InitPanelAssets()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, 
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end