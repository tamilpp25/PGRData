local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiPanelStrongholdChapter = require("XUi/XUiStronghold/XUiPanelStrongholdChapter")

local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdFightMain = XLuaUiManager.Register(XLuaUi, "UiStrongholdFightMain")

function XUiStrongholdFightMain:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(
        itemId,
        function()
            self.AssetActivityPanel:Refresh({itemId})
        end,
        self.AssetActivityPanel
    )

    self.RImgBg = self:FindComponent("BgCommonBai", "RawImage")
end

function XUiStrongholdFightMain:OnStart(chapterId, jumpToGroupId)
    self.ChapterId = chapterId
    self.JumpToGroupId = jumpToGroupId --跳转至关卡组Id
    XDataCenter.StrongholdManager:RecordCurChapterId(chapterId)
    self:InitView()
end

function XUiStrongholdFightMain:OnDestroy()
    XDataCenter.StrongholdManager:RecordCurChapterId(nil)
end

function XUiStrongholdFightMain:OnEnable()
    if self.IsEnd then
        return
    end

    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.AssetActivityPanel:Refresh({XDataCenter.StrongholdManager.GetMineralItemId()})

    self:UpdateChapter()
    self:UpdateTask()

    XDataCenter.StrongholdManager.CheckNewFinishGroupIds()
end

function XUiStrongholdFightMain:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_USE_ELECTRIC_CHANGE,
        XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE,
    }
end

function XUiStrongholdFightMain:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        self:UpdateChapter()
        XDataCenter.StrongholdManager.CheckNewFinishGroupIds()
    elseif evt == XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE then
        XDataCenter.StrongholdManager.CheckNewFinishGroupIds()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    elseif evt == XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE then
        self:UpdateTask()
    end
end

function XUiStrongholdFightMain:InitView()
    local chapterId = self.ChapterId

    local name = XStrongholdConfigs.GetChapterName(chapterId)
    self.TxtChapterName.text = name

    local bg = XStrongholdConfigs.GetBg(chapterId)
    if not string.IsNilOrEmpty(bg) then
        self.RImgBg:SetRawImage(bg)
    end
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

    if self.JumpToGroupId then
        self:OnSkipStage(self.JumpToGroupId)
        self.JumpToGroupId = nil
    end
end

function XUiStrongholdFightMain:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnClickBtnBack()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMainUi()
    end
    self.BtnToEnd.CallBack = function()
        self:OnClickBtnToEnd()
    end
    self:BindHelpBtn(self.BtnHelp, "StrongholdFight")
    self:RegisterClickEvent(self.BtnReward, self.OnClickBtnReward)
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

function XUiStrongholdFightMain:OnClickBtnReward()
    XLuaUiManager.Open("UiStrongholdRewardTip")
end

function XUiStrongholdFightMain:UpdateTask()
    local rewardIds = XDataCenter.StrongholdManager.GetCanReceiveReward()
    self.BtnReward:ShowReddot(#rewardIds > 0)
end

return XUiStrongholdFightMain