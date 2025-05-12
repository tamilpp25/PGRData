---@class XUiStrongholdMain : XLuaUi
local XUiStrongholdMain = XLuaUiManager.Register(XLuaUi, "UiStrongholdMain")

function XUiStrongholdMain:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnClickBtnMainUi)
    self:RegisterClickEvent(self.BtnShop, self.OnClickBtnShop)
    self:RegisterClickEvent(self.BtnReward, self.OnClickBtnReward)
    self:RegisterClickEvent(self.BtnTeam, self.OnClickBtnTeam)
    self:RegisterClickEvent(self.BtnAssistance, self.OnClickBtnAssistance)
    self:BindHelpBtn(self.BtnHelp, "StrongholdMain")
end

function XUiStrongholdMain:OnStart()
    self:InitCompnent()
    self:InitStageNode()
end

function XUiStrongholdMain:OnEnable()
    if self.IsEnd then
        return
    end

    -- 当从其他界面返回时检查活动是否被在线重置过
    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:RefreshStageNode()
    self:UpdateAssistant()
    XDataCenter.StrongholdManager.ReqAssistCharacterList()
end

function XUiStrongholdMain:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_SHARE_CHARACTER_CHANGE,
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE,
    }
end

function XUiStrongholdMain:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    if evt == XEventId.EVENT_STRONGHOLD_SHARE_CHARACTER_CHANGE then
        self:UpdateAssistant()
    elseif evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE or evt == XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE then
        self:RefreshStageNode()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE then
        -- 1期结束了开2期
        self:RefreshStageNode()
        self:UpdateAssistant()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
        end
    end
end

function XUiStrongholdMain:OnDestroy()
    self:UnBindTimer()
end

function XUiStrongholdMain:InitCompnent()
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh({ itemId })
    end

    self.TxtName = XStrongholdConfigs.GetActivityName()

    local levelId = XDataCenter.StrongholdManager.GetLevelId()

    local levelName = XStrongholdConfigs.GetLevelName(levelId)
    self.TxtLevelName.text = levelName

    local minLevel, maxLevel = XStrongholdConfigs.GetLevelLimit(levelId)
    self.TxtLevel.text = CsXTextManagerGetText("StrongholdLevelLimit", minLevel, maxLevel)

    local levelIcon = XStrongholdConfigs.GetLevelIcon(levelId)
    self:SetUiSprite(self.ImgIconLevel, levelIcon)

    self:UnBindTimer()
    self:BindTimer()
end

function XUiStrongholdMain:InitStageNode()
    local offset
    local chapterIds = XDataCenter.StrongholdManager.GetChaptersByLevel()
    ---@type XUiGridStrongholdStage[]
    self._Nodes = {}
    for i = 1, 7 do
        local node = self["PanelArea" .. i]
        if node then
            if table.contains(chapterIds, i) then
                local grid = XUiHelper.Instantiate(self.ChapterGrid, node)
                self._Nodes[i] = require("XUi/XUiStronghold/Grid/XUiGridStrongholdStage").New(grid, self)
                self._Nodes[i]:Init(i)

                local isUnlock, _ = XDataCenter.StrongholdManager.CheckChapterUnlock(i)
                if isUnlock and i > 1 then
                    offset = node.localPosition.x
                end
            else
                node.gameObject:SetActiveEx(false)
            end
        end
    end
    local contentSize = self.Content.sizeDelta
    if #chapterIds == 4 then
        self.Content.sizeDelta = CS.UnityEngine.Vector2(2638, contentSize.y)
    elseif #chapterIds == 5 then
        self.Content.sizeDelta = CS.UnityEngine.Vector2(3576, contentSize.y)
    elseif #chapterIds == 6 then
        self.Content.sizeDelta = CS.UnityEngine.Vector2(4458, contentSize.y)
    end
    if XTool.IsNumberValid(offset) then
        self.AreaList.horizontalNormalizedPosition = math.min(1, (offset - 50) / (self.Content.rect.width - self.AreaList.transform.rect.width))
    end
    self.ChapterGrid.gameObject:SetActiveEx(false)
end

function XUiStrongholdMain:RefreshStageNode()
    for _, node in pairs(self._Nodes) do
        node:Update()
    end
    local rewardIds = XDataCenter.StrongholdManager.GetCanReceiveReward()
    self.BtnReward:ShowReddot(#rewardIds > 0)
end

--支援角色
function XUiStrongholdMain:UpdateAssistant()
    if not XDataCenter.StrongholdManager.CheckAssistantOpen() then
        self.BtnAssistance.gameObject:SetActiveEx(false)
        return
    end
    self.BtnAssistance.gameObject:SetActiveEx(true)

    if XDataCenter.StrongholdManager.IsHaveAssistantCharacter() then
        local characterId = XDataCenter.StrongholdManager.GetAssistantCharacterId()
        self.RImgAssistantRole:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        self.RImgAssistantRole.gameObject:SetActiveEx(true)
    else
        self.RImgAssistantRole.gameObject:SetActiveEx(false)
    end
end

function XUiStrongholdMain:UnBindTimer()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Stronghold)
end

function XUiStrongholdMain:BindTimer()
    XCountDown.BindTimer(self, XCountDown.GTimerName.Stronghold, function(time)
        time = time > 0 and time or 0
        self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.STRONGHOLD)
    end)
end

function XUiStrongholdMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdMain:OnClickBtnReward()
    XLuaUiManager.Open("UiStrongholdRewardTip")
end

function XUiStrongholdMain:OnClickBtnAssistance()
    XDataCenter.StrongholdManager.EnterUiAssistant()
end

function XUiStrongholdMain:OnClickBtnShop()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local skipId = XStrongholdConfigs.GetCommonConfig("ShopSkipId")
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiStrongholdMain:OnClickBtnTeam()
    local groupId = XDataCenter.StrongholdManager.CheckAnyGroupHasFinishedStage()
    if groupId then
        local title = CSXTextManagerGetText("StrongholdTeamRestartConfirmTitle")
        local content = CSXTextManagerGetText("StrongholdTeamRestartConfirmContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.StrongholdManager.ResetStrongholdGroupRequest(groupId, function()
                XLuaUiManager.Open("UiStrongholdDeploy")
            end)
        end)
    else
        XLuaUiManager.Open("UiStrongholdDeploy")
    end
end

return XUiStrongholdMain