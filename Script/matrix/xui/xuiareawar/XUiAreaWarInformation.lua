local XUiGridAreaWarRank = require("XUi/XUiAreaWar/XUiGridAreaWarRank")

local stringFormat = string.format

--侧边栏按钮
local TabBtnIndex = {
    Information = 1, --战况总览
    Rank = 2 --小地图
}

local XUiAreaWarInformation = XLuaUiManager.Register(XLuaUi, "UiAreaWarInformation")

function XUiAreaWarInformation:OnAwake()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self.GridMyRank.gameObject:SetActiveEx(false)
    self.GridBossRank.gameObject:SetActiveEx(false)
    self.GridExamples.gameObject:SetActiveEx(false)
    self.GridInformation.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankList)
    self.DynamicTable:SetProxy(XUiGridAreaWarRank)
    self.DynamicTable:SetDelegate(self)

    self:InitTabGroup()
    self:AutoAddListener()
end

function XUiAreaWarInformation:OnStart()
    self.SelectIndex = 1
    self.ShowTypeGrids = {}
    self.BlockGrids = {}
    self:InitView()
end

function XUiAreaWarInformation:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self.PanelTab:SelectIndex(self.SelectIndex)
end

function XUiAreaWarInformation:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarInformation:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarInformation:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiAreaWarInformation:InitTabGroup()
    local btns = {}
    for _, index in pairs(TabBtnIndex) do
        btns[tonumber(index)] = self["BtnTab" .. index]
    end

    self.PanelTab:Init(
        btns,
        function(index)
            self:OnClickTabBtn(index)
        end
    )
    self.Btns = btns
end

function XUiAreaWarInformation:InitView()
    --区块类型图例
    local showTypes = XAreaWarConfigs.GetAllBlockShowTypes()
    for index, showType in ipairs(showTypes) do
        local grid = self.ShowTypeGrids[index]
        if not grid then
            local go = index == 1 and self.GridExamples or CSObjectInstantiate(self.GridExamples, self.PanelExamples)
            grid = XTool.InitUiObjectByUi({}, go)
            self.ShowTypeGrids[index] = grid
        end

        grid.ImgIcon:SetSprite(XAreaWarConfigs.GetBlockShowTypeIcon(showType))
        grid.TxtExamples.text = XAreaWarConfigs.GetBlockShowTypeName(showType)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #showTypes + 1, #self.ShowTypeGrids do
        self.ShowTypeGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarInformation:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarInformation:OnClickTabBtn(index)
    self.SelectIndex = index

    if index == TabBtnIndex.Information then
        self:UpdateInformation()
        self.PanelRanking.gameObject:SetActiveEx(false)
        self.PanelInformation.gameObject:SetActiveEx(true)
    elseif index == TabBtnIndex.Rank then
        local openUiCb = function()
            self:UpdateRank()
            self.PanelInformation.gameObject:SetActiveEx(false)
            self.PanelRanking.gameObject:SetActiveEx(true)
        end
        XDataCenter.AreaWarManager.OpenUiWorldRank(openUiCb)
    end
end

--全服战况
function XUiAreaWarInformation:UpdateInformation()
    --净化区块进度
    local clearCount, totalCount = XDataCenter.AreaWarManager.GetBlockProgress()
    self.TxtClearCount.text = stringFormat("%d/%d", clearCount, totalCount)

    --特攻角色解锁进度
    local unlockCount, totalRoleCount = XDataCenter.AreaWarManager.GetSpecialRoleProgress()
    self.TxtSpecialRole.text = stringFormat("%d/%d", unlockCount, totalRoleCount)

    --净化经验进度
    local curExp, totalExp = XDataCenter.AreaWarManager.GetSelfPurificationProgress()
    self.TxtExp.text = stringFormat("%d/%d", curExp, totalExp)

    --小地图
    local blockIds = XAreaWarConfigs.GetAllBlockIds()
    for index, blockId in pairs(blockIds) do
        local parent = self["Stage" .. blockId]
        if not parent then
            XLog.Error(
                "XUiAreaWarInformation:UpdateInformation error: 地图信息错误，UiAreaWarInformation上找不到对应的Stage节点，blockId：",
                blockId
            )
            goto CONTINUE
        end

        --不可见区块不做更新
        if not XDataCenter.AreaWarManager.IsBlockVisible(blockId) then
            parent.gameObject:SetActiveEx(false)
            goto CONTINUE
        end
        parent.gameObject:SetActiveEx(true)

        --区块信息
        local grid = self.BlockGrids[index]
        if not grid then
            local go = CSObjectInstantiate(self.GridInformation, parent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.BlockGrids[index] = grid
        end

        if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalCharacter) then
            grid.ImgRole:SetRawImage(XAreaWarConfigs.GetRoleBlockIcon(blockId))
            grid.ImgIcon.gameObject:SetActiveEx(false)
            grid.ImgRole.gameObject:SetActiveEx(true)
        else
            grid.ImgIcon:SetSprite(XAreaWarConfigs.GetBlockShowTypeIconByBlockId(blockId))
            grid.ImgIcon.gameObject:SetActiveEx(true)
            grid.ImgRole.gameObject:SetActiveEx(false)
        end

        local isClear = XDataCenter.AreaWarManager.IsBlockClear(blockId)
        local isUnlock = XDataCenter.AreaWarManager.IsBlockUnlock(blockId)
        grid.Clear.gameObject:SetActiveEx(isClear and not XAreaWarConfigs.IsInitBlock(blockId))
        grid.Disable.gameObject:SetActiveEx(not isClear and not isUnlock)
        grid.Normal.gameObject:SetActiveEx(not isClear and isUnlock)
        grid.GameObject:SetActiveEx(true)

        --当前区块可显示，寻找前置区块中已净化的，尝试连线
        local alternativeList = XAreaWarConfigs.GetBlockPreBlockIdsAlternativeList(blockId)
        for _, preBlockIds in pairs(alternativeList) do
            local preBlockId = preBlockIds[1] --只显示并列表中第一个区块的线
            if XDataCenter.AreaWarManager.IsBlockClear(preBlockId) then
                self:TryShowLine(preBlockId, blockId)
            end
        end

        ::CONTINUE::
    end
end

--Fucking Line!
function XUiAreaWarInformation:TryShowLine(startBlockId, endBlockId)
    local lineName = stringFormat("Line%d_%d", startBlockId, endBlockId)
    local line = self[lineName]
    if not line then
        XLog.Error(
            stringFormat(
                "XUiAreaWarInformation:TryShowLine error: UI上找不到对应的区块连线, 前置区块Id: %d, 当前区块Id: %d",
                startBlockId,
                endBlockId
            )
        )
        return
    end
    line.gameObject:SetActiveEx(true)
end

--排行榜
function XUiAreaWarInformation:UpdateRank()
    local myRankItem = XDataCenter.AreaWarManager.GetWorldRankGetMyRankItem()
    self.GridMyRankItem = self.GridMyRankItem or XUiGridAreaWarRank.New(self.GridMyRank)
    self.GridMyRankItem:Refresh(myRankItem)
    self.GridMyRankItem.GameObject:SetActiveEx(true)

    self.RankList = XDataCenter.AreaWarManager.GetWorldRankList()
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.RankList))
    self.DynamicTable:SetDataSource(self.RankList)
    self.DynamicTable:ReloadDataSync()
end

function XUiAreaWarInformation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankList[index])
    end
end
