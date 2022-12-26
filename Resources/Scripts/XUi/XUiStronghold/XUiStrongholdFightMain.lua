local XUiPanelStrongholdChapter = require("XUi/XUiStronghold/XUiPanelStrongholdChapter")

local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdFightMain = XLuaUiManager.Register(XLuaUi, "UiStrongholdFightMain")

function XUiStrongholdFightMain:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)
end

function XUiStrongholdFightMain:OnStart(chapterId)
    self.ChapterId = chapterId

    self:InitView()
end

function XUiStrongholdFightMain:OnEnable()
    if self.IsEnd then return end

    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })

    self:UpdateEndurance()
    self:UpdateChapter()

    XDataCenter.StrongholdManager.CheckNewFinishGroupIds()
end

function XUiStrongholdFightMain:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE,
        XEventId.EVENT_STRONGHOLD_NEW_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
    }
end

function XUiStrongholdFightMain:OnNotify(evt, ...)
    if self.IsEnd then return end

    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        self:UpdateChapter()
    elseif evt == XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE then
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_STRONGHOLD_NEW_FINISH_GROUP_CHANGE then
        XDataCenter.StrongholdManager.CheckNewFinishGroupIds()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiStrongholdFightMain:InitView()
    local chapterId = self.ChapterId
    local name = XStrongholdConfigs.GetChapterName(chapterId)
    self.TxtChapterName.text = name
end

function XUiStrongholdFightMain:UpdateEndurance()
    local curEndurance = XDataCenter.StrongholdManager.GetCurEndurance()
    self.TxtEndurance.text = curEndurance
end

function XUiStrongholdFightMain:UpdateChapter()
    local chapterId = self.ChapterId

    local finishCount, totalCount = XDataCenter.StrongholdManager.GetChapterGroupProgress(chapterId)
    self.TxtProgress.text = finishCount .. "/" .. totalCount

    if not self.ChapterPanel then
        local prefabPath = XStrongholdConfigs.GetChapterPrefabPath(chapterId)
        local ui = self.PanelNormalStageList:LoadPrefab(prefabPath)
        local clickStageCb = handler(self, self.OnClickStage)
        local skipCb = handler(self, self.OnSkipStage)
        self.ChapterPanel = XUiPanelStrongholdChapter.New(ui, clickStageCb, skipCb)
    end

    self.ChapterPanel:Refresh(chapterId)
end

function XUiStrongholdFightMain:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnToEnd.CallBack = function() self:OnClickBtnToEnd() end
    self.BtnActDesc.CallBack = function() self:OnClickBtnActDesc() end
    self:BindHelpBtn(self.BtnHelp, "StrongholdFight")
end

function XUiStrongholdFightMain:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdFightMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdFightMain:OnClickBtnToEnd()
    if self.ChapterPanel then
        self.ChapterPanel:CenterToLastGrid()
    end
end

function XUiStrongholdFightMain:OnClickBtnActDesc()
    local description = XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdUiFightMainActDes"))
    XUiManager.UiFubenDialogTip("", description)
end

function XUiStrongholdFightMain:OnClickStage(groupId)
    local closeCb = handler(self, self.OnStageDetailClose)
    local skipCb = handler(self, self.OnSkipStage)
    local childUi = self:FindChildUiObj("UiStrongholdDetail")
    if childUi then
        childUi:UpdateData(groupId)
    end
    self:OpenOneChildUi("UiStrongholdDetail", groupId, closeCb, skipCb)
end

function XUiStrongholdFightMain:OnStageDetailClose()
    self.ChapterPanel:OnStageDetailClose()
end

function XUiStrongholdFightMain:OnSkipStage(skipGroupId)
    local childUi = self:FindChildUiObj("UiStrongholdDetail")
    if childUi then
        childUi:OnClickBtnClose()
    end
    self.ChapterPanel:OnSkipStage(skipGroupId)
end