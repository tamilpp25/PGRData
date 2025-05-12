local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelUnionKillMainRank = XClass(nil, "XUiPanelUnionKillMainRank")
local XUiPanelUnionKillMyRank = require("XUi/XUiFubenUnionKill/XUiPanelUnionKillMyRank")
local XUiGridUnionRankItem = require("XUi/XUiFubenUnionKill/XUiGridUnionRankItem")
local XUiGridUnionRankTab = require("XUi/XUiFubenUnionKill/XUiGridUnionRankTab")

function XUiPanelUnionKillMainRank:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = root

    XTool.InitUiObject(self)
    self.BtnRankReward.CallBack = function() self:OnBtnRankRewardClick() end
    self.MyRank = XUiPanelUnionKillMyRank.New(self.PanelMyBossRank, self.RootUi)

    self.DynamicTableRank = XDynamicTableNormal.New(self.BossRankList.gameObject)
    self.DynamicTableRank:SetProxy(XUiGridUnionRankItem)
    self.DynamicTableRank:SetDelegate(self)

    self.RankTabs = {}
    self.RankTabBtns = {}

end

function XUiPanelUnionKillMainRank:Refresh(rankType)
    self.RankType = rankType
    local isKillRankType = rankType == XFubenUnionKillConfigs.UnionRankType.KillNumber
    local isPraiseRankType = not isKillRankType

    if isKillRankType then
        self.TxtTime.text = CS.XTextManager.GetText("UnionKillRankDesc")
        self:StartSectionCounter()
    else
        local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        if unionKillInfo then
            local beginTime, endTime = XFubenUnionKillConfigs.GetUnionActivityTimes(unionKillInfo.Id)
            local dayFormat = CS.XTextManager.GetText("UnionCnFormatDate")
            local beginTimeStr = XTime.TimestampToGameDateTimeString(beginTime, dayFormat)
            local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, dayFormat)

            self.TxtTime.text = CS.XTextManager.GetText("UnionPraiseRankDesc", beginTimeStr, endTimeStr)
        end
        self.TxtCurTime.text = ""
    end

    self.BtnRankReward.gameObject:SetActiveEx(isKillRankType)
    self.PanelTags.gameObject:SetActiveEx(isKillRankType)

    if isKillRankType then
        self:InitRankLevelTab()
        self.TxtTitle.text = CS.XTextManager.GetText("UnionKillRankTitle")
    end

    if isPraiseRankType then
        local praiseDatas = XDataCenter.FubenUnionKillManager.GetPraiseRankInfos()
        if not praiseDatas then
            self:SetNoneRankView()
            return
        end
        self.TxtTitle.text = CS.XTextManager.GetText("UnionPraiseRankTitle")
        self.RankList = praiseDatas.PlayerList

        self:UpdateRankView(self.RankList)
    end

    self.MyRank:Refresh(self.RankType, self.CurRankLevel)
end

function XUiPanelUnionKillMainRank:SetNoneRankView()
    self.DynamicTableRank:SetDataSource({})
    self.DynamicTableRank:ReloadDataASync()
    self.PanelNoRank.gameObject:SetActiveEx(false)
end

function XUiPanelUnionKillMainRank:UpdateRankView()
    if self.RankList ~= nil then
        self.DynamicTableRank:Clear()
        self.DynamicTableRank:SetDataSource(self.RankList)
        self.DynamicTableRank:ReloadDataASync()
    end
    self.PanelNoRank.gameObject:SetActiveEx(self.RankList == nil or #self.RankList <= 0)
    self.MyRank:Refresh(self.RankType, self.CurRankLevel)
end

function XUiPanelUnionKillMainRank:InitRankLevelTab()
    self.CurRankLevel = self.CurRankLevel or 1
    local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if unionKillInfo then
        local sectionId = unionKillInfo.CurSectionId
        local sectionInfo = XDataCenter.FubenUnionKillManager.GetSectionInfoById(sectionId)
        if sectionInfo then
            self.CurRankLevel = sectionInfo.RankLevel
        end
    end

    self.AllRankLevels = XFubenUnionKillConfigs.GetAllRankLevel()
    local defaultIdx = 1
    for i = 1, #self.AllRankLevels do
        if not self.RankTabs[i] then
            local tab = CS.UnityEngine.Object.Instantiate(self.GridRankLevel.gameObject)
            tab.transform:SetParent(self.PanelTags.transform, false)
            self.RankTabs[i] = XUiGridUnionRankTab.New(tab, self.RootUi)
            self.RankTabBtns[i] = self.RankTabs[i]:GetUiButton()
        end
        if self.CurRankLevel == self.AllRankLevels[i].Id then
            defaultIdx = i
        end
        self.RankTabs[i].GameObject:SetActiveEx(true)
        self.RankTabs[i]:Refresh(self.AllRankLevels[i])
    end

    -- 初始化
    self.PanelTags:Init(self.RankTabBtns, function(index) self:OnRankLevelChanged(index) end)
    self.PanelTags:SelectIndex(defaultIdx)
end

-- 切换排行榜
function XUiPanelUnionKillMainRank:OnRankLevelChanged(index)
    if not self.AllRankLevels[index] then return end
    local rankLevel = self.AllRankLevels[index].Id
    self.CurRankLevel = rankLevel

    -- 缓存以及限时请求
    local rankLevelInfos = XDataCenter.FubenUnionKillManager.GetKillRankInfosByLevel(rankLevel)
    local now = XTime.GetServerNowTimestamp()
    if not rankLevelInfos or now - rankLevelInfos.LastModify > XFubenUnionKillConfigs.RankRequestInterval then
        XDataCenter.FubenUnionKillManager.GetUnionKillRankData(rankLevel, function()
            local killDatas = XDataCenter.FubenUnionKillManager.GetKillRankInfosByLevel(rankLevel)
            if not killDatas then
                self:SetNoneRankView()
                return
            end
            self.RankList = killDatas.PlayerList
            self:UpdateRankView(self.RankList)
        end)
    else
        self.RankList = rankLevelInfos.PlayerList
        self:UpdateRankView(self.RankList)
    end
end

function XUiPanelUnionKillMainRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi, self.RankType)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankList[index]
        if not data then return end
        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnRankItemClick(index)
    end
end

function XUiPanelUnionKillMainRank:OnBtnRankRewardClick()
    self.RootUi:OpenRankReward(self.CurRankLevel)
end

function XUiPanelUnionKillMainRank:OnRankItemClick(index)
    local data = self.RankList[index]
    if not data then return end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(data.Id)
end

-- 启动活动结束倒计时
function XUiPanelUnionKillMainRank:StartSectionCounter()
    self:EndSectionCounter()

    local unionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if not unionKillInfo then return end


    local now = XTime.GetServerNowTimestamp()
    local _, endTime = XFubenUnionKillConfigs.GetUnionSectionTimes(unionKillInfo.CurSectionId)

    local invalidTime = CS.XTextManager.GetText("UnionMainOverdue")
    if now <= endTime then
        self.TxtCurTime.text = CS.XTextManager.GetText("UnionKillResetDesc", XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY))
    else
        self.TxtCurTime.text = invalidTime
    end

    self.UnionKillTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:EndSectionCounter()

            return
        end

        if now <= endTime then
            self.TxtCurTime.text = CS.XTextManager.GetText("UnionKillResetDesc", XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TxtCurTime.text = invalidTime
        end

    end, XScheduleManager.SECOND, 0)
end

-- 关闭活动结束倒计时
function XUiPanelUnionKillMainRank:EndSectionCounter()
    if self.UnionKillTimer ~= nil then
        XScheduleManager.UnSchedule(self.UnionKillTimer)
        self.UnionKillTimer = nil
    end
end

return XUiPanelUnionKillMainRank