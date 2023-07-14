
local XUiGuildViewMember = XClass(nil, "XUiGuildViewMember")
local XUiGridMemberItem = require("XUi/XUiGuild/XUiChildItem/XUiGridMemberItem")
local RequestMemberGap = 5

local SortBtnIndex2SortType = {
    [1] = XGuildConfig.GuildMemberSortType.SortByRankLevel,
    [2] = XGuildConfig.GuildMemberSortType.SortByContributeAct,
    [3] = XGuildConfig.GuildMemberSortType.SortByContributeHistory,
    [4] = XGuildConfig.GuildMemberSortType.SortByLastLoginTime,
}

local DefaultSelectSort = 1

function XUiGuildViewMember:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
    self.LastRequestMember = 0
    self.LastSetPanelIndex = 0
end

function XUiGuildViewMember:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_MEMBER_SET, self.OnMemberSet, self)
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return
    end
    self.GameObject:SetActiveEx(true)
    self.GridMemberItem.gameObject:SetActiveEx(false)
    local updateMemberFunc = function()
        local tmpSelect = self.SelectIndex or DefaultSelectSort
        self.SelectIndex = nil
        self.PanelSort:SelectIndex(tmpSelect)

        local allMember = XDataCenter.GuildManager.GetMemberList()
        for _, memberInfo in pairs(allMember or {}) do
            if memberInfo.Id == XPlayer.Id then
                self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(memberInfo.Id, memberInfo.Name)
                XUiPlayerLevel.UpdateLevel(memberInfo.Level, self.TxtLv, CS.XTextManager.GetText("GuildMemberLevel", memberInfo.Level))
                self.TxtJob.text = XDataCenter.GuildManager.GetRankNameByLevel(memberInfo.RankLevel)
                self.TxtContribution.text = memberInfo.ContributeAct or 0
                self.TxtHistoryContribution.text = memberInfo.ContributeHistory or 0
                if memberInfo.OnlineFlag == 1 then
                    self.TxtLastLogin.text = CS.XTextManager.GetText("GuildMemberOnline")
                else
                    self.TxtLastLogin.text = XUiHelper.CalcLatelyLoginTime(memberInfo.LastLoginTime)
                end
                self.TxtPopulation.text = memberInfo.Popularity
                XUiPLayerHead.InitPortrait(memberInfo.HeadPortraitId, memberInfo.HeadFrameId, self.Head)

                break
            end
        end
        local likeItemCount = XDataCenter.ItemManager.GetCount(XGuildConfig.LikeItemId)
        self.TextZan.text = string.format("x%d", likeItemCount)
        local isAdministor = XDataCenter.GuildManager.IsGuildAdminister()
        self.PanelSet.gameObject:SetActiveEx(isAdministor)
    end

    local guildId = XDataCenter.GuildManager.GetGuildId()
    local now = XTime.GetServerNowTimestamp()
    if now - self.LastRequestMember >= RequestMemberGap then
        self.LastRequestMember = now
        XDataCenter.GuildManager.GetGuildMembers(guildId, function()
            updateMemberFunc()
        end)
    else
        updateMemberFunc()
    end
end

function XUiGuildViewMember:OnDisable()
    self.GameObject:SetActiveEx(false)    
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_MEMBER_SET, self.OnMemberSet, self)
end

function XUiGuildViewMember:OnMemberSet(index)
    local tempIndex = self.LastSetPanelIndex
    -- 取消以前的设置面板（如果有）
    if self.LastSetPanelIndex ~= 0 and self.AllMemberList[self.LastSetPanelIndex].IsSetPanel then
        self.AllMemberList[self.LastSetPanelIndex].IsSetPanel = false
        self.LastSetPanelIndex = 0
    end
    -- 加入新的设置面板
    if tempIndex ~= index then
        self.AllMemberList[index].IsSetPanel = true
        self.LastSetPanelIndex = index
    end
    self.DynamicMemberTable:SetDataSource(self.AllMemberList)
    self.DynamicMemberTable:ReloadDataASync()
end

function XUiGuildViewMember:OnLeaderDissmissChange()
    if not self.AllMemberList then return end
    for i = 1, #self.AllMemberList do
        local memberInfo = self.AllMemberList[i]
        local grid = self.DynamicMemberTable:GetGridByIndex(i)
        if grid then
            grid:UpdateDissmissState(memberInfo)
        end
    end
end

function XUiGuildViewMember:UpdateMemberJobInfo()
    if not self.AllMemberList then return end
    for i = 1, #self.AllMemberList do
        local memberInfo = self.AllMemberList[i]
        local grid = self.DynamicMemberTable:GetGridByIndex(i)
        if grid then
            grid:UpdateMemberJobInfo(memberInfo)
        end
    end

    local rankLevel = XDataCenter.GuildManager.GetCurRankLevel()
    self.TxtJob.text = XDataCenter.GuildManager.GetRankNameByLevel(rankLevel)
end

function XUiGuildViewMember:UpdateMemberInfo()
    self.LastSetPanelIndex = 0
    local allMember = XDataCenter.GuildManager.GetMemberList()
    self.AllMemberList = {}
    for _, memberInfo in pairs(allMember or {}) do
        table.insert(self.AllMemberList, XTool.Clone(memberInfo))
    end

    --table.sort(self.AllMemberList, function(memberA, memberB)
    --    if memberA.OnlineFlag == memberB.OnlineFlag then
    --        if memberA.RankLevel == memberB.RankLevel then
    --            if memberA.ContributeAct == memberB.ContributeAct then
    --                return memberA.Level > memberB.Level
    --            end
    --            return memberA.ContributeAct > memberB.ContributeAct
    --        end
    --        return memberA.RankLevel < memberB.RankLevel
    --    end
    --    return memberA.OnlineFlag > memberB.OnlineFlag
    --end)
    self.AllMemberList = XGuildConfig.DoMemberSort(self.AllMemberList, self.SortType, self.IsAscendOrder)
    for index, memberInfo in pairs(self.AllMemberList) do
        memberInfo.Index = index
        memberInfo.IsSetPanel = false
    end
    self.DynamicMemberTable:SetDataSource(self.AllMemberList)
    self.DynamicMemberTable:ReloadDataASync()
end



function XUiGuildViewMember:OnViewDestroy()

end

function XUiGuildViewMember:InitChildView()
    if not self.DynamicMemberTable then
        self.DynamicMemberTable = XDynamicTableIrregular.New(self.MemberList.gameObject)
        self.DynamicMemberTable:SetProxy("XUiGridMemberItem", XUiGridMemberItem, self.GridMemberItem.gameObject)
        self.DynamicMemberTable:SetDelegate(self)
    end

    XDataCenter.ItemManager.AddCountUpdateListener(XGuildConfig.LikeItemId, function()
        local likeItemCount = XDataCenter.ItemManager.GetCount(XGuildConfig.LikeItemId)
        self.TextZan.text = string.format("x%d", likeItemCount)
    end, self.TextZan)
    
    
    local tableGroup = {
        self.BtnPosition,
        self.BtnRecent,
        self.BtnHistory,
        self.BtnSign,
    }
    
    self.PanelSort:Init(tableGroup, function(index) self:OnBtnSortSelect(index) end)
    self.BtnOrder:SetButtonState(self.IsAscendOrder and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnOrder.CallBack = function() self:OnBtnOrderClick() end
end

function XUiGuildViewMember:GetProxyType()
    return "XUiGridMemberItem"
end

function XUiGuildViewMember:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.AllMemberList[index]
        if not data then return end
        grid:SetMemberInfo(data, self.LastSetPanelIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnMemberItemClick(index)
    end
end

function XUiGuildViewMember:OnBtnSortSelect(index)
    if index == self.SelectIndex then
        return
    end
    self.SelectIndex = index
    self.SortType = SortBtnIndex2SortType[self.SelectIndex]
    self:UpdateMemberInfo()
end

function XUiGuildViewMember:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self:UpdateMemberInfo()
end

function XUiGuildViewMember:OnMemberItemClick(index)
    local data = self.AllMemberList[index]
    if not data then return end

    if data.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(data.Id)
    end
end


return XUiGuildViewMember