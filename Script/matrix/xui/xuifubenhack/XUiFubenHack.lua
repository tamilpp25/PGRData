local XUiPanelLineChapter = require("XUi/XUiFubenHack/ChildView/XUiPanelLineChapter")
local XUiPanelLevelInfo = require("XUi/XUiFubenHack/ChildView/XUiPanelLevelInfo")
local XUiGridStarReward = require("XUi/XUiFubenHack/ChildItem/XUiGridStarReward")

local XUiFubenHack = XLuaUiManager.Register(XLuaUi, "UiFubenHack")
function XUiFubenHack:OnAwake()
    self.GridTreasureList = {}      -- 任务格子
end

function XUiFubenHack:OnResume(data)
    self.LastChapter = data
end

function XUiFubenHack:OnEnable()
    if self.RedPointId then
        XRedPointManager.Check(self.RedPointId)
    end

    self:Refresh()
end

function XUiFubenHack:OnStart()
    self.ActTemplate = XDataCenter.FubenHackManager.GetCurrentActTemplate()
    self.ChapterTemplate = XDataCenter.FubenHackManager.GetCurChapterTemplate()
    if not self.ActTemplate then
        return
    end

    self:CreateActivityTimer(XDataCenter.FubenHackManager.GetCurChapterEndTime())
    self.TxtChapterName.text = self.ActTemplate.Name

    self:InitUiView()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, true)
end

function XUiFubenHack:OnGetEvents()
    return { XEventId.EVENT_FUBEN_HACK_UPDATE,
             CS.XEventId.EVENT_UI_DONE}
end

function XUiFubenHack:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_HACK_UPDATE then
        self:Refresh(args)
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Hack then return end
        XDataCenter.FubenHackManager.OnActivityEnd()
    elseif evt == CS.XEventId.EVENT_UI_DONE then
        if self:CheckIsNeedPop() then
            XDataCenter.FubenHackManager.OnActivityEnd()
        end
    end
end

function XUiFubenHack:Refresh()
    if self:CheckIsNeedPop() then return end
    self.PanelChapter:Refresh()
    self.AssetActivityPanel:Refresh({self.ActTemplate.TicketId})
    self:SetupStarReward()
    self.PanelLevelInfo:Refresh(true)

    XDataCenter.FubenHackManager.GetHackDailyTicket()
    self.BtnLevel:ShowReddot(XDataCenter.FubenHackManager.CheckAffixRedPoint())
end

function XUiFubenHack:OnDisable()
    if self.PanelLevelInfo then
        self.PanelLevelInfo:OnDisable()
    end
end

function XUiFubenHack:OnDestroy()
    if self.PanelChapter then
        self.PanelChapter:OnDestroy()
    end
    self:StopActivityTimer()
end

function XUiFubenHack:OnReleaseInst()
    return self.LastChapter
end

function XUiFubenHack:SetupStarReward()
    local curStars, totalStars = XDataCenter.FubenHackManager.GetStarProgress()
    local rewardList, isRed = XDataCenter.FubenHackManager.GetStarRewardList()
    self.RewardList = rewardList

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.ImgLingqu.gameObject:SetActiveEx(totalStars <= curStars and (not isRed))
    self.ImgRedProgress.gameObject:SetActiveEx(isRed)

    self.TxtStarNum.text = string.format("%d/%d", curStars, totalStars)
end

function XUiFubenHack:InitUiView()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnRole.CallBack = function() self:OnBtnRoleClick() end
    self.BtnLevel.CallBack = function() self:OnBtnLevelClick() end
    self.BtnLevel:SetNameByGroup(0, XUiHelper.ReadTextWithNewLine("FubenHackDevelopBtn"))
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick)

    self:BindHelpBtn(self.BtnHelp, "FubenHack")
    self.PanelChapter = XUiPanelLineChapter.New(self, self.PaneStageList, self.ChapterTemplate)
    self.PanelChapter:OnShow()
    self.PanelLevelInfo = XUiPanelLevelInfo.New(self, self.PanelLvInfo)
end

-- 是否显示红点
function XUiFubenHack:OnCheckAffix(count)
    self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenHack:OnBtnBackClick()
    self:Close()
end

function XUiFubenHack:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenHack:OnBtnTreasureBgClick()
    --self.TreasureDisable:PlayTimelineAnimation(function()
        self.PanelTreasure.gameObject:SetActiveEx(false)
    --end)
end

function XUiFubenHack:OnBtnTreasureClick()
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self.TreasureEnable:PlayTimelineAnimation()
end

function XUiFubenHack:OnBtnRoleClick()
    XLuaUiManager.Open("UiHackCharInfo")
end

function XUiFubenHack:OnBtnLevelClick()
    XLuaUiManager.Open("UiHackDevelop")
end

function XUiFubenHack:InitTreasureGrade()
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end

    if not self.RewardList then
        return
    end

    local offsetValue = 260
    local gridCount = #self.RewardList

    for i = 1, gridCount do
        local offerY = (1 - i) * offsetValue
        local grid = self.GridTreasureList[i]

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridTreasureGrade, self.PanelGradeContent)  -- 复制一个item
            grid = XUiGridStarReward.New(self, item)
            grid.Transform.localPosition = CS.UnityEngine.Vector3(item.transform.localPosition.x, item.transform.localPosition.y + offerY, item.transform.localPosition.z)
            self.GridTreasureList[i] = grid
        end

        grid:Refresh(self.RewardList[i])

        --grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiFubenHack:SwitchBg(actTemplate)
    if not actTemplate or not actTemplate.MainBackgound then return end
    self.RImgFestivalBg:SetRawImage(actTemplate.MainBackgound)
end

-- 计时器
function XUiFubenHack:CreateActivityTimer(endTime)
    local time = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = XTime.GetServerNowTimestamp()
            if time > endTime then
                self:StopActivityTimer()
                XDataCenter.FubenHackManager.OnActivityEnd()
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
end
 
function XUiFubenHack:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

function XUiFubenHack:CheckIsNeedPop()
    local chapter = XDataCenter.FubenHackManager.GetCurChapterTemplate()
    if self.LastChapter and chapter ~= self.LastChapter then
        return true
    else
        self.LastChapter = XDataCenter.FubenHackManager.GetCurChapterTemplate()
    end
end