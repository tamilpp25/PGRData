-- 刮刮乐活动关卡
local XScratchTicketStage = XClass(nil, "XScratchTicketStage")

-- 关卡状态枚举
XScratchTicketStage.PlayStatus = {
        NotStart = 1, --未开始游戏
        Playing = 2, --正在游玩
    }

function XScratchTicketStage:Ctor(id, activityController)
    self.TicketCfg = XScratchTicketConfig.GetStageConfigById(id)
    self.ActivityController = activityController
    self.Status = XDataCenter.ScratchTicketManager.PlayStatus.NotStart
end

function XScratchTicketStage:Reset()
    self.GridCfg = nil
    self.Status = XDataCenter.ScratchTicketManager.PlayStatus.NotStart
    self.OpenGrids = {}
    self.OpenNum = 0
    self.SelectChoseId = nil
    self.ChoseCfg = nil
    self.CorrectChose = nil
end
--===================
--刷新刮刮配置
--@param ticketId:刮刮配置ID
--===================
function XScratchTicketStage:UpdateTicket(ticketId)
    self.TicketCfg = XScratchTicketConfig.GetStageConfigById(ticketId)
end
--===================
--刷新新的九宫格
--@param gridId:九宫格表配置ID
--===================
function XScratchTicketStage:UpdateGrid(gridId, luckNumber)
    if not gridId then
        self.GridCfg = nil
        self.Status = XDataCenter.ScratchTicketManager.PlayStatus.NotStart
        return
    end
    --self.GridCfg = XScratchTicketConfig.GetGridConfigById(self.TicketCfg.GridIds[gridId])
    self.LuckyNum = luckNumber
end
--===================
--更新九宫格状态
--@param openGrids:List<ScratchTicketActivityOpenGridDb>
--    public int Index
--    public int Num
--@param selectChoseId:被选择的开奖列配置ID
--===================
function XScratchTicketStage:RefreshGrid(openGrids, selectChoseId)
    --更新预览格子状态
    self.OpenGrids = {}
    self.OpenNum = 0
    if openGrids then
        for index, grid in pairs(openGrids) do
            self:OpenGrid(grid.Index + 1, grid.Num)
        end
    end
    --更新开奖状态
    self.SelectChoseId = selectChoseId
    if self.SelectChoseId and self.SelectChoseId > 0 then
        self.ChoseCfg = XScratchTicketConfig.GetChoseConfigById(self.SelectChoseId)
        self.Status = XDataCenter.ScratchTicketManager.PlayStatus.NotStart
    else
        self.ChoseCfg = nil
        self.Status = XDataCenter.ScratchTicketManager.PlayStatus.Playing
    end
end

function XScratchTicketStage:RefreshResult(correctChose, gridNum)
    --更新预览格子状态
    if gridNum and #gridNum > 0 then
        self.OpenNum = 0
        for index, num in pairs(gridNum) do
            self:OpenGrid(index, num)
        end
    end
    self.CorrectChose = correctChose
end

function XScratchTicketStage:OpenGrid(gridIndex, gridNum)
    if not self.OpenGrids then self.OpenGrids = {} end
    self.OpenGrids[gridIndex] = gridNum
    self.OpenNum = self.OpenNum + 1
end

function XScratchTicketStage:EndGame()
    self:Reset()
end

function XScratchTicketStage:GetLuckyNum()
    return self.LuckyNum
end

function XScratchTicketStage:GetWinRewardItemId()
    return self.TicketCfg and self.TicketCfg.WinRewardItemId
end

function XScratchTicketStage:GetWinRewardItemIcon()
    local itemId = self:GetWinRewardItemId()
    if not itemId then return nil end
    return XDataCenter.ItemManager.GetItemIcon(itemId)
end

function XScratchTicketStage:GetWinRewardItemNum()
    return self.TicketCfg and self.TicketCfg.WinRewardItemNum
end

function XScratchTicketStage:GetLoseRewardItemId()
    return self.TicketCfg and self.TicketCfg.LoseRewardItemId
end

function XScratchTicketStage:GetLoseRewardItemNum()
    return self.TicketCfg and self.TicketCfg.LoseRewardItemNum
end

function XScratchTicketStage:GetLoseRewardItemIcon()
    local itemId = self:GetLoseRewardItemId()
    if not itemId then return nil end
    return XDataCenter.ItemManager.GetItemIcon(itemId)
end

function XScratchTicketStage:GetPlayStatus()
    return self.Status
end

function XScratchTicketStage:GetSelectChoseId()
    return self.SelectChoseId
end

function XScratchTicketStage:GetCorrectChose()
    return self.CorrectChose or {}
end

function XScratchTicketStage:CheckIsSelectCorrent()
    local selectId = self:GetSelectChoseId()
    for _, correct in pairs(self:GetCorrectChose()) do
        if selectId == correct then
            return true
        end
    end
    return false
end
--=================
--根据九宫格序号获取九宫格数字
--=================
function XScratchTicketStage:GetGridNumByGridIndex(gridIndex)
    return self.OpenGrids and self.OpenGrids[gridIndex] or 0
end
--=================
--检查对应序号九宫格是否被预览
--=================
function XScratchTicketStage:CheckGridIsOpenByGridIndex(gridIndex)
    return self.OpenGrids and (self.OpenGrids[gridIndex] ~= nil) or false
end
--=================
--获取九宫格已经预览的格子数
--=================
function XScratchTicketStage:GetOpenGridNum()
    return self.OpenNum or 0
end
--=================
--获取幸运奖励ID
--=================
function XScratchTicketStage:GetWinRewardId()
    return self.TicketCfg and self.TicketCfg.WinRewardId
end
--=================
--获取安慰奖励ID
--=================
function XScratchTicketStage:GetLoseRewardId()
    return self.TicketCfg and self.TicketCfg.LoseRewardId
end
return XScratchTicketStage