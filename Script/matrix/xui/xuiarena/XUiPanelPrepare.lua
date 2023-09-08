---@class XUiPanelPrepare:XUiNode
local XUiPanelPrepare = XClass(XUiNode, "XUiPanelPrepare")

function XUiPanelPrepare:OnStart()
    self:AutoAddListener()
    self:AddRedPointEvent(self.ImgRed, nil, self, { XRedPointConditions.Types.CONDITION_ARENA_APPLY })
end

function XUiPanelPrepare:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelPrepare:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelPrepare:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelPrepare:AutoAddListener()
    self:RegisterClickEvent(self.BtnCreateTeam, self.OnBtnCreateTeamClick)
    self:RegisterClickEvent(self.BtnLevelReward, self.OnBtnLevelRewardClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self.BtnTranscript.CallBack = function()
        self:OnBtnTranscriptClick()
    end
end

function XUiPanelPrepare:OnBtnCreateTeamClick()
    if not XDataCenter.ArenaManager.CheckInTeamState() then
        XUiManager.TipText("ArenaActivityTeamStatusWrong")
        return
    end

    XDataCenter.ArenaManager.RequestMyTeamInfo(function()
        XLuaUiManager.Open("UiArenaTeam")
    end)
    XDataCenter.ArenaManager.RequestApplyData()
end


function XUiPanelPrepare:OnBtnLevelRewardClick()
    XLuaUiManager.Open("UiArenaLevelDetail")
end

function XUiPanelPrepare:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Arena)
end

function XUiPanelPrepare:OnEnable()
    self:Refresh()
end

function XUiPanelPrepare:OnCheckApplyData(count)
    self.ImgRed.gameObject:SetActiveEx(count > 0)
end

function XUiPanelPrepare:Refresh()
    local arenaLevel = XDataCenter.ArenaManager.GetCurArenaLevel()
    local arenaLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(arenaLevel)
    if arenaLevelCfg then
        self.RImgLevel:SetRawImage(arenaLevelCfg.Icon)
    end

    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    if challengeCfg then
        self.TxtLevel.text = CS.XTextManager.GetText("ArenaPlayerLevelRange", challengeCfg.MinLv, challengeCfg.MaxLv)
    end

    local isEnd = XDataCenter.ArenaManager.GetArenaActivityStatus() == XArenaActivityStatus.Over
    self.PanelNorResult.gameObject:SetActiveEx(not isEnd)
    self.PanelSelectResult.gameObject:SetActiveEx(isEnd)
    self.PanelNorTeam.gameObject:SetActiveEx(isEnd)
    self.PanelSelectTeam.gameObject:SetActiveEx(not isEnd)
    self.TxtSelectResultTime.gameObject:SetActiveEx(isEnd)
    self.TxtNorResultTime.gameObject:SetActiveEx(isEnd)

    local resultTime = XDataCenter.ArenaManager.GetResultStartTime()
    self.TxtNorResultTime.text = resultTime
    self.TxtSelectResultTime.text = resultTime

    local fightTime = XDataCenter.ArenaManager.GetFightStartTime()
    self.TxtNorFightTime.text = fightTime

    local teamTime = XDataCenter.ArenaManager.GetTeamStartTime()
    self.TxtNorTeamTime.text = teamTime
    self.TxtSelectTeamTime.text = teamTime
end

--成绩单按钮点击
function XUiPanelPrepare:OnBtnTranscriptClick()
    XDataCenter.ArenaManager.ScoreQueryReq(function()
            XLuaUiManager.Open("UiArenaRank")
        end)
end

return XUiPanelPrepare