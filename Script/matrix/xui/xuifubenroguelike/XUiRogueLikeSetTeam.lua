local XUiRogueLikeSetTeam = XClass(nil, "XUiRogueLikeSetTeam")
local XUiGridTopicInfo = require("XUi/XUiFubenRogueLike/XUiGridTopicInfo")
local XUiDayTopicCharacter = require("XUi/XUiFubenRogueLike/XUiDayTopicCharacter")
local XUiRogueLikeMemberHead = require("XUi/XUiFubenRogueLike/XUiRogueLikeMemberHead")
local MaxMemberCount = 3

function XUiRogueLikeSetTeam:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCloseClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnBuff.CallBack = function() self:OnBtnBuffClick() end

    self.MemberView = {}
    self.GridMemberList = {}
    for i = 1, MaxMemberCount do
        self.MemberView[i] = self[string.format("TeamMember%d", i)]
        self.GridMemberList[i] = XUiRogueLikeMemberHead.New(self.MemberView[i])
        self.GridMemberList[i]:ClearMemberHead()
        self.GridMemberList[i]:SetMemberCallBack(function()
            self:OnTeamMemberClick(i)
        end)
    end

    self.GridTopicList = {}
    self.GridHeadList = {}
    self.ChooseCharList = {}
end

function XUiRogueLikeSetTeam:ShowSetTeamView()
    self.GameObject:SetActiveEx(true)

    self:UpdateThemeHeads()
    self:UpdateBuffs()
end

function XUiRogueLikeSetTeam:CloseSetTeamView()
    self.GameObject:SetActiveEx(false)
    self.ChooseCharList = {}
    for i = 1, MaxMemberCount do
        self.GridMemberList[i]:ClearMemberHead()
    end
end

function XUiRogueLikeSetTeam:SetCharacterType(characterLimitType, limitBuffId)
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
end

function XUiRogueLikeSetTeam:UpdateBuffs()
    self.BuffRed.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.HasNewBuffs() > 0)
    self.BtnBuff:SetNameByGroup(0, #XDataCenter.FubenRogueLikeManager.GetMyBuffs())
end

function XUiRogueLikeSetTeam:GetDayBuffs()

end

-- teamEffectId变化
function XUiRogueLikeSetTeam:UpdateThemeHeads()
    local teamEffectId = XDataCenter.FubenRogueLikeManager.GetTeamEffectId()
    if XDataCenter.FubenRogueLikeManager.IsSectionPurgatory() then
        self.PanelTheme.gameObject:SetActiveEx(false)
        self.PanelResetTime.gameObject:SetActiveEx(false)
        self.TitleText.text = CS.XTextManager.GetText("RogueLikeSetTeamTitlePurgatory")
        self.PanelThemeTrial.gameObject:SetActiveEx(true)
        self.TxtTheme1.text = string.gsub(CS.XTextManager.GetText("RogueLikeSetTeamPurRuleValue"), "\\n", "\n")
        return
    else
        self.PanelTheme.gameObject:SetActiveEx(true)
        self.PanelResetTime.gameObject:SetActiveEx(true)
        self.TitleText.text = CS.XTextManager.GetText("RogueLikeSetTeamTitleNormal")
        self.PanelThemeTrial.gameObject:SetActiveEx(false)
    end
    if teamEffectId <= 0 then return end
    local teamEffectTemplate = XFubenRogueLikeConfig.GetTeamEffectTemplateById(teamEffectId)
    if not teamEffectTemplate then return end
    local dayBuffs = {}
    local lock_character = {}
    for _, id in pairs(self.ChooseCharList or {}) do
        lock_character[id] = true
    end
    local buff_count = 0
    for _, characterId in pairs(teamEffectTemplate.CharacterId) do
        if lock_character[characterId] then
            buff_count = buff_count + 1
        end
    end
    for i, buffId in pairs(teamEffectTemplate.BuffId) do
        table.insert(dayBuffs, {
            BuffId = buffId,
            IsActive = i <= buff_count
        })
    end

    -- 今日主题
    for i = 1, #dayBuffs do
        if not self.GridTopicList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridThemeBuff.gameObject)
            ui.transform:SetParent(self.PanelThemeBuff, false)
            ui.gameObject:SetActiveEx(true)
            self.GridTopicList[i] = XUiGridTopicInfo.New(ui, self)
        end
        self.GridTopicList[i].GameObject:SetActiveEx(true)
        self.GridTopicList[i]:SetTopicInfo(dayBuffs[i])
    end
    for i = #dayBuffs + 1, #self.GridTopicList do
        self.GridTopicList[i].GameObject:SetActiveEx(false)
    end

    -- 今日角色
    local characterIds = teamEffectTemplate.CharacterId
    for i = 1, #characterIds do
        local characterId = characterIds[i]
        if not self.GridHeadList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridHead.gameObject)
            ui.transform:SetParent(self.PanelThemeHead, false)
            self.GridHeadList[i] = XUiDayTopicCharacter.New(ui, self)
        end
        self.GridHeadList[i].GameObject:SetActiveEx(true)
        self.GridHeadList[i]:SetTopicInfoById(characterId)
    end
    for i = #characterIds + 1, #self.GridHeadList do
        self.GridHeadList[i].GameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeSetTeam:UpdateResetTime(resetTime)
    self.TxtResetTime.text = resetTime
end

function XUiRogueLikeSetTeam:OnBtnBuffClick()
    if #XDataCenter.FubenRogueLikeManager.GetMyBuffs() <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNoneBuff"))
        return
    end

    XLuaUiManager.Open("UiRogueLikeMyBuff")
end

function XUiRogueLikeSetTeam:OnTeamMemberClick(index)
    local args = {}
    args.TeamSelectPos = index
    args.TeamCharIdMap = self.ChooseCharList
    args.Type = XFubenRogueLikeConfig.SelectCharacterType.Character
    args.CharacterLimitType = self.CharacterLimitType
    args.LimitBuffId = self.LimitBuffId
    args.CallBack = function(selectId, isJoin, isReset)
        self:HandleSelectRole(index, selectId, isJoin, isReset)
    end
    args.CancelCallBack = function()
        for i = 1, MaxMemberCount do
            self.GridMemberList[i]:SetMemberInfo(self.ChooseCharList[i], true, false)
        end
    end
    XLuaUiManager.Open("UiRogueLikeRoomCharacter", args)
end

function XUiRogueLikeSetTeam:HandleSelectRole(index, selectId, isJoin, isReset)
    if isReset then
        self.ChooseCharList = {}
    end

    if isJoin then
        local oldIndex
        local oldMember
        for k, v in pairs(self.ChooseCharList) do
            if k ~= index and v == selectId then
                oldIndex = k
                oldMember = v
                break
            end
        end
        if oldIndex and oldMember then
            self.ChooseCharList[oldIndex] = self.ChooseCharList[index]
            self.ChooseCharList[index] = selectId
        else
            self.ChooseCharList[index] = selectId
        end

    else
        self.ChooseCharList[index] = nil
    end

    for i = 1, MaxMemberCount do
        self.GridMemberList[i]:SetMemberInfo(self.ChooseCharList[i], true, false)
    end
    self:UpdateThemeHeads()
end

function XUiRogueLikeSetTeam:IsInTeam(characterId)
    for _, v in pairs(self.ChooseCharList) do
        if v == characterId then
            return true
        end
    end
    return false
end

function XUiRogueLikeSetTeam:OnBtnConfirmClick()
    if #self.ChooseCharList < 3 then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeTeamMaxMember"))
        return
    end

    local title = CS.XTextManager.GetText("RogueLikeSetTeamTitle")
    local content = CS.XTextManager.GetText("RogueLikeSetTeamContent")
    local sureFunc = function()
        XDataCenter.FubenRogueLikeManager.RogueLikeSetTeam(self.ChooseCharList, function()
            self:CloseSetTeamView()
        end)
    end

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        sureFunc()
    end)

end

function XUiRogueLikeSetTeam:OnBtnCloseClick()
    self:CloseSetTeamView()
end

return XUiRogueLikeSetTeam