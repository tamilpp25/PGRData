local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiMainLine3DStoryDetail = XLuaUiManager.Register(XLuaUi, "UiMainLine3DStoryDetail")

function XUiMainLine3DStoryDetail:OnAwake()
    self:InitAutoScript()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiMainLine3DStoryDetail:OnStart(stageId)
    self.StageId = stageId
end

function XUiMainLine3DStoryDetail:OnEnable(stageId)
    if stageId then
        self.StageId = stageId
    end
    self:Refresh()
end

function XUiMainLine3DStoryDetail:UpdateEventPanel()
    local eventCfg = XFubenMainLineConfigs.GetStageExById(self.StageId)
    self.PanelMessage.gameObject:SetActiveEx(eventCfg)
    if eventCfg then
        local isShowHead = not string.IsNilOrEmpty(eventCfg.EventIcon)
        self.RImgHead.gameObject:SetActiveEx(isShowHead)
        if isShowHead then
            self.RImgHead:SetRawImage(eventCfg.EventIcon)
        end
        self.TextFirstTitle.text = eventCfg.EventParams[2]
        self.TxtFirstContent.text = eventCfg.EventParams[3]
        self.TextSecondTitle.text = eventCfg.EventParams[4]
        self.TxtSecondContent.text = eventCfg.EventParams[5]
        self.TxtContent.text = eventCfg.EventParams[1]
        self.TextFirstTitle.gameObject:SetActiveEx(not string.IsNilOrEmpty(eventCfg.EventParams[2]))
        self.TxtFirstContent.gameObject:SetActiveEx(not string.IsNilOrEmpty(eventCfg.EventParams[3]))
        self.TextSecondTitle.gameObject:SetActiveEx(not string.IsNilOrEmpty(eventCfg.EventParams[4]))
        self.TxtSecondContent.gameObject:SetActiveEx(not string.IsNilOrEmpty(eventCfg.EventParams[5]))
        self.PanelHead.gameObject:SetActiveEx(not (string.IsNilOrEmpty(eventCfg.EventParams[1]) and string.IsNilOrEmpty(eventCfg.EventIcon)))
        self.PanelReat.gameObject:SetActiveEx(not (string.IsNilOrEmpty(eventCfg.EventParams[2]) and string.IsNilOrEmpty(eventCfg.EventParams[4])))
    end
end

function XUiMainLine3DStoryDetail:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end

function XUiMainLine3DStoryDetail:Refresh()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageId = stageCfg.StageId
    local chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(stageId)

    self.TxtTitle.text = chapterOrderId .. "-" .. stageCfg.OrderId .. stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description
    if stageCfg.Icon then
        self.RImgNandu:SetRawImage(stageCfg.Icon)
    end
    if stageCfg.StoryIcon then
        self.RImgTitleBg:SetRawImage(stageCfg.StoryIcon)
    end
    self:UpdateEventPanel()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiMainLine3DStoryDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiMainLine3DStoryDetail:AutoAddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end
-- auto
function XUiMainLine3DStoryDetail:OnBtnEnterClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageId = stageCfg.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
    self:Hide()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            end)
        end)
    end
end

function XUiMainLine3DStoryDetail:Hide()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end