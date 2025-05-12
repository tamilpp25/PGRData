local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiFubenMaverickPrepare = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickPrepare")
local XUiFubenMaverickCharacterPanel = require("XUi/XUiFubenMaverick/XUiScrollView/XUiFubenMaverickCharacterPanel")

function XUiFubenMaverickPrepare:OnAwake()
    self:InitButtons()
    self:InitPanelAssets()
    self:InitDynamicTable()
end

function XUiFubenMaverickPrepare:OnStart(stageId)
    self.StageId = stageId

    local stage = XDataCenter.MaverickManager.GetStage(self.StageId)
    local activityEndTime = XDataCenter.MaverickManager.GetEndTime()
    local patternEndTime = XDataCenter.MaverickManager.GetPatternEndTime(stage.PatternId)
    if patternEndTime < activityEndTime then
        self:SetAutoCloseInfo(patternEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndPattern(stage.PatternId)
            end
        end, nil , 0)
    else
        self:SetAutoCloseInfo(activityEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndActivity()
            end
        end, nil , 0)
    end

    self.UiCharacterPanel:Refresh(true)
    self.UiCharacterPanel:UpdateCamera(XDataCenter.MaverickManager.CameraTypes.PREPARE)

    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiFubenMaverickPrepare:OnEnable()
    self.Super.OnEnable(self)

    self:UpdateAssets()
end

function XUiFubenMaverickPrepare:OnDestroy()
    self.Super.OnDestroy(self)

    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnOpenLoadingOrBeginPlayMovie, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnOpenLoadingOrBeginPlayMovie, self)
end

function XUiFubenMaverickPrepare:OnOpenLoadingOrBeginPlayMovie()
    self:Remove()
end

function XUiFubenMaverickPrepare:InitButtons()
    self:BindHelpBtn(self.BtnHelp, "MaverickHelp")
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnEnterFight.CallBack = function() XDataCenter.MaverickManager.EnterFight(self.StageId, self.MemberId) end
end

function XUiFubenMaverickPrepare:OnGetEvents()
    return { XEventId.EVENT_MAVERICK_MEMBER_UPDATE }
end

function XUiFubenMaverickPrepare:OnNotify(evt)
    if evt == XEventId.EVENT_MAVERICK_MEMBER_UPDATE then
        self.UiCharacterPanel:Refresh()
    end
end

function XUiFubenMaverickPrepare:InitPanelAssets()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
            {
                XDataCenter.MaverickManager.LvUpConsumeItemId,
            },
            handler(self, self.UpdateAssets),
            self.AssetActivityPanel
    )
end

function XUiFubenMaverickPrepare:UpdateAssets()
    self.AssetActivityPanel:Refresh(
            {
                XDataCenter.MaverickManager.LvUpConsumeItemId,
            }
    )
end

function XUiFubenMaverickPrepare:InitDynamicTable()
    local index = 1
    local uiSkills = { }
    local uiSkill = self["PanelSkill" .. index]
    while uiSkill do
        uiSkills[index] = uiSkill
        index = index + 1
        uiSkill = self["PanelSkill" .. index]
    end
    
    self.UiCharacterPanel = XUiFubenMaverickCharacterPanel.New(self, uiSkills, 
            self.SViewCharacterList, function(memberId) 
                self.MemberId = memberId
                self:OnSelectMember(memberId) 
            end, false)
end

function XUiFubenMaverickPrepare:OnSelectMember(memberId)
    local attributes = XDataCenter.MaverickManager.GetAttributes(memberId)
    self.TxtAttribute1.text = attributes[1]
    self.TxtAttribute2.text = attributes[2]
end 