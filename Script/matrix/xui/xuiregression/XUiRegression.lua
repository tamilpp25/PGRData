local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--
--Author: wujie
--Note: 回归活动主界面

local UiRegression = XLuaUiManager.Register(XLuaUi, "UiRegression")

function UiRegression:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.BtnIndexToTypeDic = {}

    self:InitTabBtnGroup()
    self:AutoAddListener()
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE,self.OnOpenStatusUpdate, self)
end

function UiRegression:OnStart()
    if not XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen() then
        self:Close()
        return
    end

    XDataCenter.RegressionManager.HandlePlayStory(true)
    self.BtnReview.gameObject:SetActiveEx(XDataCenter.RegressionManager.IsShowActivityViewStoryBtn())

    for _, type in pairs(XRegressionConfigs.MainViewShowedTypeList) do
        if XDataCenter.RegressionManager.IsRegressionActivityOpen(type) then
            table.insert(self.BtnIndexToTypeDic, type)
        end
    end
    local showedTabBtnCount = #self.BtnIndexToTypeDic

    local activityType
    for i, btn in ipairs(self.BtnTabList) do
        if i > showedTabBtnCount then
            btn.gameObject:SetActiveEx(false)
        else
            btn.gameObject:SetActiveEx(true)
            activityType = self.BtnIndexToTypeDic[i]
            btn:SetName(XRegressionConfigs.ActivityTypeToTabText[activityType])
            XRedPointManager.AddRedPointEvent(
                    btn.ReddotObj,
                    nil,
                    self,
                    {XRegressionConfigs.ActivityTypeToRedPointCondition[activityType]}
            )
        end
    end

    if showedTabBtnCount > 0 then
        local firstBtnIndex = 1
        self.TabBtnGroup:SelectIndex(firstBtnIndex)
    end
end

function UiRegression:InitTabBtnGroup()
    self.BtnTabList = {
        self.BtnTab1,
        self.BtnTab2
    }
    self.TabBtnGroup:Init(self.BtnTabList, function(index) self:OnTabBtnGroupClick(index) end)
end

function UiRegression:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnReview.CallBack = function() self:OnBtnReviewClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self:BindHelpBtnOnly(self.BtnHelp)
end

--事件相关------------------------------------>>>
function UiRegression:OnTabBtnGroupClick(index)
    if self.SelectTabBtnIndex == index then return end
    self.SelectTabBtnIndex = index
    if index == XRegressionConfigs.ActivitySubType.Task then
        self:OpenOneChildUi("UiRegressionTask", self)
        local activityId = XDataCenter.RegressionManager.GetTaskActivityId()
        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
        local helpId = activityTemplate.HelpId
        self.BtnHelp.gameObject:SetActiveEx(helpId ~= nil)
    end
end

function UiRegression:OnBtnReviewClick()
    XDataCenter.RegressionManager.HandlePlayStory()
end

function UiRegression:OnBtnHelpClick()
    if self.SelectTabBtnIndex == XRegressionConfigs.ActivitySubType.Task then
        local activityId = XDataCenter.RegressionManager.GetTaskActivityId()
        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
        local helpId = activityTemplate.HelpId
        local helpCourseTemplate = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(helpCourseTemplate.Function)
    end
end

function UiRegression:OnOpenStatusUpdate()
    if not XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen() then
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("RegressionActivityOver")
        XLuaUiManager.RunMain()
    end
end
--事件相关------------------------------------<<<