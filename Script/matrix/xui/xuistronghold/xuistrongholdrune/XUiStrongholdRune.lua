local XUiGridSubRune = require("XUi/XUiStronghold/XUiStrongholdRune/XUiGridSubRune")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdRune = XLuaUiManager.Register(XLuaUi, "UiStrongholdRune")

function XUiStrongholdRune:OnAwake()
    self:AutoAddListener()

    self.GridSubRune.gameObject:SetActiveEx(false)
    self.BtnRune.gameObject:SetActiveEx(false)
end

function XUiStrongholdRune:OnStart(teamList, teamId, groupId, runeId)
    self.TeamList = teamList
    self.TeamId = teamId
    self.GroupId = groupId
    self.DefaultRuneId = runeId
    self.TabBtnList = {}
    self.SubRuneGrids = {}
end

function XUiStrongholdRune:OnEnable()
    self:InitTabBtnGroup()
end

function XUiStrongholdRune:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_RUNE_CHANGE
    }
end

function XUiStrongholdRune:OnNotify(evt, ...)
    if evt == XEventId.EVENT_STRONGHOLD_RUNE_CHANGE then
        self:InitTabBtnGroup()
    end
end

function XUiStrongholdRune:InitTabBtnGroup()
    self.RuneIdList = XDataCenter.StrongholdManager.GetAllRuneIds()
    if XTool.IsTableEmpty(self.RuneIdList) then
        XLog.Error("XUiStrongholdRune:InitTabBtnGroup error, 服务器下发可用符文列表为空")
        return
    end

    local defaultSelectIndex = 1
    for index, runeId in ipairs(self.RuneIdList) do
        local btn = self.TabBtnList[index]
        if not btn then
            local go = CS.UnityEngine.Object.Instantiate(self.BtnRune, self.PanelTabBtns.transform)
            btn = go:GetComponent("XUiButton")
            self.TabBtnList[index] = btn
        end

        btn:SetSprite(XStrongholdConfigs.GetRuneIcon(runeId))
        btn:SetNameByGroup(0, XStrongholdConfigs.GetRuneName(runeId))

        local usingTeamId = XDataCenter.StrongholdManager.GetRuneUsingTeamId(runeId)
        if XTool.IsNumberValid(usingTeamId) then
            btn:SetNameByGroup(1, CsXTextManagerGetText("StrongholdTeamIndex", usingTeamId))
        else
            btn:SetNameByGroup(1, "")
        end

        local hasRecord = XDataCenter.StrongholdManager.IsRuneLock(runeId, self.GroupId)
        btn:ShowTag(hasRecord)

        btn.gameObject:SetActiveEx(true)

        if runeId == self.DefaultRuneId then
            defaultSelectIndex = index
            self.DefaultRuneId = nil
        end
    end

    self.PanelTabBtns:Init(self.TabBtnList, handler(self, self.OnTabBtnGroupClick))
    self.PanelTabBtns:SelectIndex(self.SelectTabIndex or defaultSelectIndex)
end

function XUiStrongholdRune:OnTabBtnGroupClick(index)
    self.SelectTabIndex = index
    self.SubRuneId = nil

    local runeId = self.RuneIdList[index]
    self.ImgBg.color = XStrongholdConfigs.GetRuneColor(runeId)
    self.ImgIcon:SetSprite(XStrongholdConfigs.GetRuneIcon(runeId))
    self.TxtName.text = XStrongholdConfigs.GetRuneName(runeId)
    self.TxtDesc.text = XStrongholdConfigs.GetRuneDesc(runeId)

    local subRuneIds = XStrongholdConfigs.GetSubRuneIds(runeId)
    for index, subRuneId in ipairs(subRuneIds) do
        local grid = self.SubRuneGrids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridSubRune.gameObject, self.PanelContent)
            local clickCb = handler(self, self.OnClickSubRune)
            grid = XUiGridSubRune.New(go, clickCb)
            self.SubRuneGrids[index] = grid
        end

        grid:Refresh(runeId, subRuneId, self.GroupId)
        grid:SetSelect(self.SubRuneId == subRuneId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #subRuneIds + 1, #self.SubRuneGrids do
        self.SubRuneGrids[index].GameObject:SetActiveEx(false)
    end

    local isLock = XDataCenter.StrongholdManager.IsRuneLock(runeId, self.GroupId)
    if isLock then
        self.BtnSave:SetDisable(true, false)
        self.TxtTips.text = CsXTextManagerGetText("StrongholdTeamRuneLockTip")
        self.TxtTips.gameObject:SetActiveEx(true)
    else
        self.BtnSave:SetDisable(false, true)
        self.TxtTips.gameObject:SetActiveEx(false)
    end

    self:PlayAnimationWithMask("QieHuan")
end

function XUiStrongholdRune:OnClickSubRune(subRuneId)
    self.SubRuneId = subRuneId
    for index, grid in pairs(self.SubRuneGrids) do
        grid:SetSelect(grid.SubRuneId == subRuneId)
    end
end

function XUiStrongholdRune:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnSave.CallBack = handler(self, self.OnClickBtnSave)
end

function XUiStrongholdRune:OnClickBtnSave()
    local runeId = self.RuneIdList[self.SelectTabIndex]
    local subRuneId = self.SubRuneId
    if not subRuneId then
        XUiManager.TipText("StrongholdTeamSelectSubRuneEmpty")
        return
    end

    local oldTeamId
    for teamId, team in pairs(self.TeamList) do
        if team:IsRuneUsing(runeId) then
            oldTeamId = teamId
            break
        end
    end

    local callFunc = function()
        if oldTeamId then
            local oldTeam = self.TeamList[oldTeamId]
            oldTeam:ClearRune()
        end

        local curTeam = self.TeamList[self.TeamId]
        curTeam:SetRune(runeId, subRuneId)

        self:Close()
    end

    if oldTeamId and oldTeamId ~= self.TeamId then
        local title = CSXTextManagerGetText("StrongholdTeamSelectRuneConfirmTitle")
        local content = CSXTextManagerGetText("StrongholdTeamSelectRuneConfirmContent", oldTeamId)
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        callFunc()
    end
end
