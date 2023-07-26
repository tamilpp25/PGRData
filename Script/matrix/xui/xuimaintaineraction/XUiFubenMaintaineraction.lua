local XUiFubenMaintaineraction = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineraction")
local XUiPanelBelow = require("XUi/XUiMaintainerAction/XUiPanelBelow")
local XUiPanelIntermediate = require("XUi/XUiMaintainerAction/XUiPanelIntermediate")
local MapNodeMaxIndex = 15
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiFubenMaintaineraction:OnStart()
    self.CardRouteList = {}
    self.BelowPanel = XUiPanelBelow.New(self.PanelBelow,self)
    self.IntermediatePanel = XUiPanelIntermediate.New(self.PanelIntermediate,self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    --self:PlayStory()

    self.BelowPanel:DisableAllCard(false)
    self.PanelIntermediate.gameObject:SetActiveEx(true)
    self.PanelMissioncompleted.gameObject:SetActiveEx(false)
end

function XUiFubenMaintaineraction:OnDestroy()
    
end

function XUiFubenMaintaineraction:OnEnable()
    if not self:CheckWeekUpdateMessage() then
        local player = XDataCenter.MaintainerActionManager.GetPlayerMySelf()

        self:UpdatePanel()
        self:CheckEvent(player:GetPosNodeId(), false, function ()
                self:UpdatePanel()
            end)

        local nowTime = XTime.GetServerNowTimestamp()
        local gameData = XDataCenter.MaintainerActionManager.GetGameData()
        self.TxtTime.text = XUiHelper.GetTime(gameData:GetResetTime() - nowTime, XUiHelper.TimeFormatType.ACTIVITY)

        XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_DAY_UPDATA, self.UpdatePanel, self)
        XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_WEEK_UPDATA, self.CheckWeekUpdateMessage, self)
        XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_USECARD, self.UsedCard, self)
        XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_SELECTCARD, self.SelectCard, self)
        XEventManager.AddEventListener(XEventId.EVENT_MAINTAINERACTION_NODE_CHANGE, self.UpdatePanel, self)
    end
end

function XUiFubenMaintaineraction:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_DAY_UPDATA, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_WEEK_UPDATA, self.CheckWeekUpdateMessage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_USECARD, self.UsedCard, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_SELECTCARD, self.SelectCard, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINTAINERACTION_NODE_CHANGE, self.UpdatePanel, self)
    self.IntermediatePanel:StopPlayerTween()
    self.BelowPanel:StopCardTween()
end

function XUiFubenMaintaineraction:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "MaintainerActionHelp")
end

function XUiFubenMaintaineraction:OnBtnBackClick()
    self:Close()
end

function XUiFubenMaintaineraction:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenMaintaineraction:PlayStory()
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    local storyId = gameData:GetStoryId()
    if storyId and #storyId > 1 then
        local IsCanPlay = XDataCenter.MaintainerActionManager.CheckIsNewStoryID(storyId)
        if IsCanPlay then
            XDataCenter.MovieManager.PlayMovie(storyId)--一次
            XDataCenter.MaintainerActionManager.MarkStoryID(storyId)
        end
    end
end

function XUiFubenMaintaineraction:SelectCard(cradNum)
    self.IntermediatePanel:ShowCardSelectRoute(cradNum)
end

function XUiFubenMaintaineraction:CheckDayUpdateMessage()
    XDataCenter.MaintainerActionManager.CheckDayUpdateMessage()
end

function XUiFubenMaintaineraction:CheckWeekUpdateMessage()
    return XDataCenter.MaintainerActionManager.CheckWeekUpdateMessage()
end

function XUiFubenMaintaineraction:CheckEventComplete()
    XDataCenter.MaintainerActionManager.CheckEventCompleteMessage(function ()
            XDataCenter.MaintainerActionManager.CheckFightCompleteMessage(function ()
                    XDataCenter.MaintainerActionManager.CheckMentorCompleteMessage()
                end)
    end)
end

function XUiFubenMaintaineraction:UpdatePanel()
    self:CheckDayUpdateMessage()
    self.IntermediatePanel:CreateCardRouteList()
    self.IntermediatePanel:UpdatePanel()
    self.IntermediatePanel:SetCurNodeNameTag(XPlayer.Id)
    self.BelowPanel:UpdatePanel()
    self:CheckEventComplete()
end

function XUiFubenMaintaineraction:UsedCard(targetNodeId)
    self.BelowPanel:GetNewCard()
    self.IntermediatePanel:MovePlayerById(XPlayer.Id,targetNodeId,function ()
            XLuaUiManager.SetMask(false)
            self:CheckEvent(targetNodeId, true, function ()
                    self:UpdatePanel()
                end)
        end)
end

function XUiFubenMaintaineraction:CheckEvent(targetNodeId, IsDoTriggeredCb, cb)
    local mapNodeList = XDataCenter.MaintainerActionManager.GetMapNodeList()
    local player = XDataCenter.MaintainerActionManager.GetPlayerMySelf()
    local node = mapNodeList[targetNodeId]
    if player:GetIsNodeTriggered() then
        if IsDoTriggeredCb and cb then cb() end
        return
    end
    
    node:EventRequest(self, player, cb)
end

