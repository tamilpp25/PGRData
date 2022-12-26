local XUiGuildMemberHornor = XClass(nil, "XUiGuildMemberHornor")
local XUiGridGuildHornorMemberGroup = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildHornorMemberGroup")
local XUiGridGuildMemberCard = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildMemberCard")

function XUiGuildMemberHornor:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildMemberHornor:InitChildView()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelGuildMember.gameObject)
    self.DynamicTable:SetProxy(XUiGridGuildHornorMemberGroup)
    self.DynamicTable:SetDelegate(self)

    self.BtnArrowRight.CallBack = function() self:OnBtnArrowRightClick() end
    self.BtnArrowLeft.CallBack = function() self:OnBtnArrowLeftClick() end

    self.TopMemberList = {}
end

function XUiGuildMemberHornor:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.BottomList[index + 1]
        if not data then return end
        grid:Refresh(data)
    end
end

-- 打开
function XUiGuildMemberHornor:OnEnable()
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return
    end

    self.GameObject:SetActiveEx(true)
    self:UpdateMemberInfo()
end

function XUiGuildMemberHornor:UpdateMemberInfo()
    self:SetupMemberList()
    self:SetupTop5Member()
    self:SetupRestMembers()
end

-- 除去最高贡献剩下的成员
function XUiGuildMemberHornor:SetupRestMembers()
    self.DynamicTable:SetDataSource(self.BottomList)
    self.DynamicTable:ReloadData(-1)
end

-- 最高5名
function XUiGuildMemberHornor:SetupTop5Member()
    for i = 1, XGuildConfig.RankTopListCount do
        if not self.TopMemberList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.UiGuildRank)
            local grid = XUiGridGuildMemberCard.New(ui, self.UiRoot)
            grid.Transform:SetParent(self.RankTop5, false)
            self.TopMemberList[i] = grid
        end
        self.TopMemberList[i].GameObject:SetActiveEx(true)
        self.TopMemberList[i]:RefreshTop5Member(self.Top5List[i])
    end
    -- for i = #self.Top5List + 1, #self.TopMemberList do
    --     self.TopMemberList[i].GameObject:SetActiveEx(false)
    -- end
end

-- 初始化队员数据
function XUiGuildMemberHornor:SetupMemberList()
    local allMemberList = XDataCenter.GuildManager.GetMemberList()

    self.AllMemberList = {}
    for _, v in pairs(allMemberList or {}) do
        table.insert(self.AllMemberList, v)
    end

    table.sort(self.AllMemberList, function(memberA, memberB)
        if memberA.ContributeAct == memberB.ContributeAct then
            if memberA.Level == memberB.Level then
                return memberA.RankLevel < memberB.RankLevel
            end
            return memberA.Level > memberB.Level
        end
        return memberA.ContributeAct > memberB.ContributeAct
    end)

    self.Top5List = {}
    self.BottomList = {}
    local pageNo = 1
    for i = 1, #self.AllMemberList do
        local memberItem = self.AllMemberList[i]
        memberItem.ContributeRank = i
        if i <= XGuildConfig.RankTopListCount then
            table.insert(self.Top5List, memberItem)
        else
            if not self.BottomList[pageNo] then
                self.BottomList[pageNo] = {}
            end
            if #self.BottomList[pageNo] < XGuildConfig.RankBottomPageCount then
                table.insert(self.BottomList[pageNo], memberItem)
            end
            if #self.BottomList[pageNo] == XGuildConfig.RankBottomPageCount then
                pageNo = pageNo + 1
            end
        end
    end
    -- 如果下方列表没有数据，则构造一个空表
    if #self.AllMemberList <= XGuildConfig.RankTopListCount then
        self.BottomList[1] = {}
    end
end

-- 关闭
function XUiGuildMemberHornor:OnDisable()
    self.GameObject:SetActiveEx(false)
end

-- 上一页
function XUiGuildMemberHornor:OnBtnArrowLeftClick()
    local startIndex = self.DynamicTable.Imp.StartIndex
    if startIndex - 1 >= 0 then
        self.DynamicTable.Imp:TweenToIndex(startIndex - 1)
    end
end

-- 下一页
function XUiGuildMemberHornor:OnBtnArrowRightClick()
    local startIndex = self.DynamicTable.Imp.StartIndex
    if startIndex + 1 <= #self.BottomList then
        self.DynamicTable.Imp:TweenToIndex(startIndex + 1)
    end
end

return XUiGuildMemberHornor