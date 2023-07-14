--######################## XUiPlayerRankGrid ########################
local XUiPlayerRankGrid = XClass(nil, "XUiPlayerRankGrid")

function XUiPlayerRankGrid:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.RankInfo = nil
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
end

function XUiPlayerRankGrid:SetData(rankInfo)
    local sameColorActivityManager = XDataCenter.SameColorActivityManager
    local roleManager = sameColorActivityManager.GetRoleManager()
    self.RankInfo = rankInfo
    local showSpecialRank = rankInfo.Rank <= XSameColorGameConfigs.MaxSpecialRankIndex
    self.TxtRank.text = rankInfo.Rank
    self.TxtRank.gameObject:SetActiveEx(not showSpecialRank)
    self.ImgRankSpecial.gameObject:SetActiveEx(showSpecialRank)
    if showSpecialRank then
        local rankIcons = sameColorActivityManager.GetRankIcons()
        self.ImgRankSpecial:SetSprite(rankIcons[rankInfo.Rank])
    end
    XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    self.TxtRankScore.text = XUiHelper.GetText("SCRankScoreTips", rankInfo.Score)
    self.TxtPlayerName.text = rankInfo.Name
    local roleId = rankInfo.RoleId > 0 and rankInfo.RoleId or 1
    local role = roleManager:GetRole(roleId)
    self.RImgRoleIcon:SetRawImage(role:GetCharacterViewModel():GetSmallHeadIcon())
    local skillGroupId, rImgSkillIcon, panelSkill
    for i = 1, 3 do
        skillGroupId = rankInfo.RoleSkillId[i]
        rImgSkillIcon = self["RImgSkillIcon" .. i]
        panelSkill = self["PanelSkill" .. i]
        if skillGroupId then
            local skill = sameColorActivityManager.GetRoleShowSkill(skillGroupId)
            rImgSkillIcon:SetRawImage(skill:GetIcon())
            rImgSkillIcon.gameObject:SetActiveEx(true)
            panelSkill.gameObject:SetActiveEx(true)
            XUiHelper.RegisterClickEvent(self, self["BtnSkill" .. i], function()
                self.RootUi.UiPanelSkillDetail:Open()
                self.RootUi.UiPanelSkillDetail:SetData(XTool.Clone(skill))
            end)
        else
            rImgSkillIcon.gameObject:SetActiveEx(false)
            panelSkill.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPlayerRankGrid:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.PlayerId)
end

--######################## XUiSameColorGameRank ########################
local XUiSameColorPanelSkillDetail = require("XUi/XUiSameColorGame/XUiSameColorPanelSkillDetail")
local XUiSameColorGameRank = XLuaUiManager.Register(XLuaUi, "UiFubenSameColorGameRank")

local RankType = {
    Total = 0,
    Boss = 1,
}

function XUiSameColorGameRank:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.BossManager = self.SameColorGameManager.GetBossManager()
    self.CurrentRankList = nil
    self.CurrentMyRankInfo = nil
    self.CurrentRankType = nil
    self.CurrentBosses = nil
    self.CurrentTabIndex = 1
    -- 排行动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiPlayerRankGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridPlayerRank.gameObject:SetActiveEx(false)
    -- 资源栏
    XUiHelper.NewPanelActivityAsset(self.SameColorGameManager.GetAssetItemIds(), self.PanelAsset)
    -- 技能详情
    self.UiPanelSkillDetail = XUiSameColorPanelSkillDetail.New(self.PanelPopup)
    self:RegisterUiEvents()
end

function XUiSameColorGameRank:OnStart(rankList, myRankInfo)
    self.CurrentRankType = RankType.Total
    self.CurrentRankList = rankList
    self.CurrentMyRankInfo = myRankInfo
    self.CurrentBosses = self.BossManager:GetBosses(true)
    self.CurrentTabIndex = 1
    self:RefreshRankTags()
    self:RefreshMyRankInfo(self.CurrentMyRankInfo)
    self:RefreshRankList(self.CurrentRankList)
    local endTime = self.SameColorGameManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.SameColorGameManager.HandleActivityEndTime()
        end
    end)
end

function XUiSameColorGameRank:RefreshRankTags()
    self.BtnRankTag:SetNameByGroup(0, XUiHelper.GetText("SCRankTotalName"))
    local btnTabList = { self.BtnRankTag }
    local bosses = self.CurrentBosses
    local go, xUiButton, boss
    for i = 1, #bosses do
        boss = bosses[i]
        go = CS.UnityEngine.Object.Instantiate(self.BtnRankTag, self.PanelTag.transform)
        xUiButton = go.transform:GetComponent("XUiButton")
        xUiButton:SetNameByGroup(0, boss:GetName())
        table.insert(btnTabList, xUiButton)
    end
    self.PanelTag:Init(btnTabList, function(index)
        self:OnBtnTagClicked(index)
    end)
    self.PanelTag:SelectIndex(self.CurrentTabIndex)
end

function XUiSameColorGameRank:RefreshRankList(rankList)
    local index = 1
    if self.CurrentMyRankInfo.Rank <= XSameColorGameConfigs.MaxTopRankCount then
        index = self.CurrentMyRankInfo.Rank
    end
    self.CurrentRankList = rankList
    self.DynamicTable:SetDataSource(self.CurrentRankList)
    self.DynamicTable:ReloadDataSync(index)
    local isEmpty = #rankList <= 0
    self.PanelNoRank.gameObject:SetActiveEx(isEmpty)
    self.PlayerRankList.gameObject:SetActiveEx(not isEmpty)
end

function XUiSameColorGameRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.CurrentRankList[index])
    end
end

function XUiSameColorGameRank:RefreshMyRankInfo(rankInfo)
    self.CurrentMyRankInfo = rankInfo
    self.TxtPlayerName.text = rankInfo.Name
    local rank = rankInfo.Rank
    local rankText = rank
    -- 没进入排行
    if rank <= 0 then
        rankText = XUiHelper.GetText("SCRankEmptyText")
    elseif rank > XSameColorGameConfigs.PercRankLimit then
        local tmp = math.floor((rank / rankInfo.MemberCount) * 100)
        tmp = math.min(math.max(tmp, 1), 99)
        rankText = tmp .. "%"
    end
    self.TxtRank.text = rankText
    self.TxtRankScore.text = rankInfo.Score
    XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
end

function XUiSameColorGameRank:OnBtnTagClicked(index)
    if index == self.CurrentTabIndex then return end
    self.CurrentTabIndex = index
    local bossId = 0
    if index > 1 then
        bossId = self.CurrentBosses[index - 1]:GetId()
    end
    self.SameColorGameManager.RequestRankData(bossId, function(rankList, myRankInfo)
        self:RefreshMyRankInfo(myRankInfo)
        self:RefreshRankList(rankList)
    end)
end

function XUiSameColorGameRank:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnMyRank.CallBack = function() self:OnBtnMyRankClicked() end
    self.BtnMyHead.CallBack = function() self:OnBtnMyHeadClicked() end
    self:BindHelpBtn(self.BtnHelp, self.SameColorGameManager.GetHelpId())
end

function XUiSameColorGameRank:OnBtnMyHeadClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.CurrentMyRankInfo.PlayerId)
end

function XUiSameColorGameRank:OnBtnMyRankClicked()
    self.DynamicTable:ReloadDataSync(1)
end

return XUiSameColorGameRank