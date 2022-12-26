local XUiSummerRank = XLuaUiManager.Register(XLuaUi, "UiSummerRank")

local XUiGridSummerRank = require("XUi/XUiSummerEpisode/XUiGridSummerRank")
local RankType = {
    Broadsword = 1,
    Alive = 2
}


function XUiSummerRank:OnAwake()

    self.DynamicTable = XDynamicTableNormal.New(self.RankList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridSummerRank)

    CsXUiHelper.RegisterClickEvent(self.BtnClose, handler(self, self.OnClickClose))
    self.Gridplayer.gameObject:SetActiveEx(false)
end

function XUiSummerRank:OnStart(cb, winData)

    self.Cb = cb
    self.WinData = winData
    self.StageId = winData.StageId
    self.BeginData = XDataCenter.FubenManager.GetFightBeginData()
    local playerList = self.BeginData.PlayerList

    local roleData = self.BeginData.RoleData
    local record = XDataCenter.FubenManager.CurFightResult.StringToIntRecord

    self.PlayerList = {}
    if XFubenSpecialTrainConfig.CheckIsSpecialTrainBroadswordStage(self.StageId) then
        local totalTime = record.jianshengdadaogametime
        for i, v in ipairs(roleData) do
            local data = {}
            for _, var in pairs(playerList) do
                if var.Id == v then
                    data.Player = var
                end
            end

            data.Count = record["jianshengdadaokills" .. tostring(i)] or 0
            data.Time = record["jianshengdadaoalive" .. tostring(i)] or (totalTime + 1)

            data.RankType = RankType.Broadsword

            -- if v == XPlayer.Id then
            --     myData = data
            -- else
            self.PlayerList[i] = data
            --end
        end


        table.sort(self.PlayerList, function(a, b)
            return a.Time > b.Time
        end)

        -- table.insert(self.PlayerList, myData)
    else
        for i, v in ipairs(roleData) do
            local data = {}
            for _, var in pairs(playerList) do
                if var.Id == v then
                    data.Player = var
                end
            end

            data.Time = record["keepwatermelon" .. tostring(i)] or 0
            data.RankType = RankType.Alive

            self.PlayerList[i] = data
        end


        table.sort(self.PlayerList, function(a, b)
            return a.Time > b.Time
        end)
    end


    self:SetupStarReward()
end

function XUiSummerRank:SetupStarReward()
    self.DynamicTable:SetDataSource(self.PlayerList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSummerRank:OnDynamicTableEvent(event, index, grid)

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local player = self.PlayerList[index]
        grid:Refresh(player, index)
    end
end


function XUiSummerRank:OnClickClose()
    if self.Cb then
        self.Cb()
    else
        self:Close()
    end
end