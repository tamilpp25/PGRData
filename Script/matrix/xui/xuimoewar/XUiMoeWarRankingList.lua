local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiMoeWarRankingList = XLuaUiManager.Register(XLuaUi, "UiMoeWarRankingList")

local XUiGridRank = require("XUi/XUiMoeWar/ChildItem/XUiGridRank")
local XUiPanelMyRank = require("XUi/XUiMoeWar/SubPage/XUiPanelMyRank")
local DEFAULT_TOG_INDEX = 1

function XUiMoeWarRankingList:OnAwake()
    self:AddListener()
    self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[1], function()
        self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    end, self.AssetActivityPanel)

    XDataCenter.MoeWarManager.ClearCache()
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiMoeWarRankingList:OnStart()
    self.BtnGoList = {}
    self.RankingListTables = {}
    self.tagCount = 1
    self.TabGroup = {}

    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self.DynamicTable:SetProxy(XUiGridRank)
    self.DynamicTable:SetDelegate(self)

    self.MyRank = XUiPanelMyRank.New(self, self.PanelMyRank)

    self:UpdateTog()
    self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)

    self.LastMatchType = XDataCenter.MoeWarManager.GetCurMatch():GetType()
end

function XUiMoeWarRankingList:OnEnable()
    self:CheckIsNeedPop()
end

function XUiMoeWarRankingList:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiMoeWarRankingList:OnGetEvents()
    return { XEventId.EVENT_MOE_WAR_UPDATE,
             XEventId.EVENT_MOE_WAR_ACTIVITY_END}
end

function XUiMoeWarRankingList:OnNotify(evt, ...)
    if evt == XEventId.EVENT_MOE_WAR_UPDATE then
        self:CheckIsNeedPop()
    elseif evt == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
        XDataCenter.MoeWarManager.OnActivityEnd()
    end
end

function XUiMoeWarRankingList:OnBtnBackClick()
    self:Close()
end

function XUiMoeWarRankingList:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMoeWarRankingList:OnDestroy()

end

function XUiMoeWarRankingList:UpdateTog()
    local infoList = XDataCenter.MoeWarManager.GetRankTabList()
    local selectIndex = DEFAULT_TOG_INDEX
    local SubGroupIndexMemo = 0

    for i = 1, #self.BtnGoList do
        self.BtnGoList[i].gameObject:SetActiveEx(false)
    end

    for index, info in pairs(infoList) do
        local btn = self.BtnGoList[self.tagCount]
        if self.TabGroup[info.RankType] then
            if self.TabGroup[info.RankType][index] then
                btn = self.BtnGoList[self.TabGroup[info.RankType] [index]]
            end
        end

        if not btn then
            local name
            local SubGroupIndex

            if info.IsSub then
                if info.SecondTagType == XMoeWarConfig.SubTagType.Top then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondTop)
                elseif info.SecondTagType == XMoeWarConfig.SubTagType.Mid then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecond)
                elseif info.SecondTagType == XMoeWarConfig.SubTagType.Btm then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondBottom)
                else
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondAll)
                end

                SubGroupIndex = SubGroupIndexMemo
            else
                if info.HasSub then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd)
                else
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
                end
                SubGroupIndexMemo = self.tagCount
                SubGroupIndex = 0
            end

            name = info.TagName

            if btn then
                if not self.TabGroup[info.RankType] then
                    self.TabGroup[info.RankType] = {}
                end
                table.insert(self.TabGroup[info.RankType], self.tagCount)
                self.tagCount = self.tagCount + 1

                table.insert(self.RankingListTables, info)

                btn.transform:SetParent(self.TabBtnContent, false)
                local uiButton = btn:GetComponent("XUiButton")
                uiButton.SubGroupIndex = SubGroupIndex
                uiButton:SetName(name)
                table.insert(self.BtnGoList, uiButton)
                btn.gameObject.name = info.Id
            end
        end

        btn.gameObject:SetActiveEx(true)
        --selectIndex = self.TabGroup[info.RankType][index]
    end

    if #infoList <= 0 then
        return
    end

    self.TabBtnGroup:Init(self.BtnGoList, function(index) self:SwitchTab(index) end)
    self.TabBtnGroup:SelectIndex(selectIndex, false)
    self:SwitchTab(selectIndex, true)
end

function XUiMoeWarRankingList:SetTitleName(rankType, playerId)
    local cfg = XMoeWarConfig.GetRankGroupByType(rankType)
    local player = XDataCenter.MoeWarManager.GetPlayer(playerId)
    self.TxtTitle.text = string.format(cfg.Title, player and player:GetName() or nil)
    self.TxtResetTip.text = cfg.ResetTip
end

function XUiMoeWarRankingList:ShowRank(isFromOtherUi)
    XDataCenter.MoeWarManager.RequestRank(self.CurTabInfo.RankType, self.CurTabInfo.PlayerId or 0, function(rankData)
        self.RankData = rankData
        self:UpdateRankList(isFromOtherUi)
    end)
end

--显示排行详情
function XUiMoeWarRankingList:SwitchTab(index, isFromOtherUi)
    if self.CurSelectIndex ~= index then
        self.CurTabInfo = self.RankingListTables[index]
        self:ShowRank(isFromOtherUi)
        self.CurSelectIndex = index
    end
end

function XUiMoeWarRankingList:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

--动态列表事件
function XUiMoeWarRankingList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.RankData.RankingList[index]
        grid:Refresh(data, self.CurTabInfo.RankType)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        --grid:OnRecycle()
    end
end

function XUiMoeWarRankingList:UpdateRankList(isFromOtherUi)
    if not isFromOtherUi then
        self:PlayAnimation("QieHuan")
    end
    --XLog.Warning(self.RankData)
    local count = self.RankData.RankingList and #self.RankData.RankingList or 0
    self.DynamicTable:SetDataSource(self.RankData.RankingList)
    self.DynamicTable:ReloadDataASync()

    self.PanelRankingList.gameObject:SetActiveEx(count > 0)
    self.PanelMyRank.gameObject:SetActiveEx(count > 0)
    if count > 0 then
        self.MyRank:Refresh(self.RankData.UserRank, self.CurTabInfo.RankType)
    end
    self.PanelNoRank.gameObject:SetActiveEx(count <= 0)
    self:SetTitleName(self.CurTabInfo.RankType, self.CurTabInfo.PlayerId)
end


function XUiMoeWarRankingList:CheckIsNeedPop()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match:GetType() == XMoeWarConfig.MatchType.Voting and self.LastMatchType == XMoeWarConfig.MatchType.Publicity then
        XUiManager.TipText("MoeWarMatchEnd")
        XLuaUiManager.RunMain()
        return true
    else
        self.LastMatchType = match:GetType()
    end
end