-- 刮刮乐活动控制器
local XScratchTicketActivityController = XClass(nil, "XScratchTicketActivityController")

function XScratchTicketActivityController:Ctor(activityId)
    self.ActivityCfg = XScratchTicketConfig.GetActivityConfigById(activityId)
end
--================
--刷新活动数据
--[[
public class ScratchTicketActivityDb
{
public int Id; --对应Activity表Id

//已经开放的Grid
public List<ScratchTicketActivityOpenGridDb>    OpenGrid = new List<ScratchTicketActivityOpenGridDb>();

//缓存配置表
public int LuckNumber { get; set; }

//选择哪一个开奖列
public int SelectOpen { get; set; }

public int GridCfgIndex { get; set; }--ScratchTicket表GridIds的序号，对应Grid表

public int CfgIndex { get; set; }--Activity表ScratchTicket数组的序号，对应ScratchTicket的Id
}

public class ScratchTicketActivityOpenGridDb
{
public int Index;
public int Num;
}
]]
--================
function XScratchTicketActivityController:UpdateData(activityData)
    if activityData.CfgIndex and activityData.CfgIndex >= 0 then
        local ticketId = self:GetScratchTicketByIndex(activityData.CfgIndex + 1) --后端数组从0起，这里要+1
        if (not self.Ticket) and ticketId then
            local ticketScript = require("XEntity/XScratchTicket/XScratchTicketStage")
            self.Ticket = ticketScript.New(ticketId, self)
        elseif self.Ticket and ticketId then
            self.Ticket:UpdateTicket(ticketId)
        end
        if activityData.GridCfgIndex then
            self.Ticket:UpdateGrid(activityData.GridCfgIndex + 1, activityData.LuckNumber)  --后端数组从0起，这里要+1
            self.Ticket:RefreshGrid(activityData.OpenGrid, activityData.SelectOpen)
            self.Ticket:RefreshResult(activityData.CorrectChose, activityData.Num)
        end
    end
    self.TicketIndex = activityData.CfgIndex + 1
    self.IsWin = activityData.IsWin
    self.ResetCount = activityData.ResetCount
    self.ResetStatus = not self.IsWin and activityData.SelectOpen ~= nil
end
--==============
--预览九宫格格子
--==============
function XScratchTicketActivityController:OpenGrid(gridIndex, gridNum)
    self.Ticket:OpenGrid(gridIndex, gridNum)
end
--==============
--结束刮刮卡游戏
--==============
function XScratchTicketActivityController:EndGame()
    self.Ticket:EndGame()
end
--==============
--获取活动Id (Activity表Id)
--==============
function XScratchTicketActivityController:GetId()
    return self.ActivityCfg and self.ActivityCfg.Id
end
--==============
--根据数组序号获取ScratchTicket数组对应序号的值
--@param index:数组序号
--==============
function XScratchTicketActivityController:GetScratchTicketByIndex(index)
    return self.ActivityCfg and self.ActivityCfg.ScratchTicket[index]
end
--==============
--获取活动名称
--==============
function XScratchTicketActivityController:GetName()
    return self.ActivityCfg and self.ActivityCfg.Name
end
--==============
--获取活动TimeId
--==============
function XScratchTicketActivityController:GetTimeId()
    return self.ActivityCfg and self.ActivityCfg.OpenTimeId
end
--==============
--获取活动门票道具Id
--==============
function XScratchTicketActivityController:GetSpendItemId()
    return self.ActivityCfg and self.ActivityCfg.SpendItemId
end
--==============
--获取活动门票道具消耗数量
--==============
function XScratchTicketActivityController:GetSpendItemNum()
    return self.ActivityCfg and self.ActivityCfg.SpendItemCount
end
--==============
--获取活动门票道具Icon
--==============
function XScratchTicketActivityController:GetSpendItemIcon()
    if self.SpendItemIcon then return self.SpendItemIcon end
    self.SpendItemIcon = XDataCenter.ItemManager.GetItemIcon(self:GetSpendItemId())
    return self.SpendItemIcon
end
--==============
--获取能否重置(区分刮刮类型,true为黄金刮刮,false为普通刮刮)
--==============
function XScratchTicketActivityController:GetIsCanReset()
    return self.ActivityCfg and self.ActivityCfg.IsCanReset
end
--==============
--获取可预览的次数
--==============
function XScratchTicketActivityController:GetPreviewCount()
    return self.ActivityCfg and self.ActivityCfg.PreviewCount
end

function XScratchTicketActivityController:CheckPreviewFinish()
    return self:GetPreviewCount() <= (self.Ticket and self.Ticket:GetOpenGridNum() or 0)
end
--==============
--获取当前活动是否已经获胜(仅黄金九宫有效)
--==============
function XScratchTicketActivityController:GetIsWin()
    return self.IsWin
end

function XScratchTicketActivityController:GetScratchTicket()
    return self.ActivityCfg and self.ActivityCfg.ScratchTicket or {}
end

function XScratchTicketActivityController:CheckIsLastTicket()
    return self.TicketIndex and self.TicketIndex >= #self:GetScratchTicket() or false
end

function XScratchTicketActivityController:GetGoldRewardItemId()
    return self.ActivityCfg and self.ActivityCfg.GoldRewardItemId
end

function XScratchTicketActivityController:GetGoldRewardItemNum()
    return self.ActivityCfg and self.ActivityCfg.GoldRewardItemNum
end

function XScratchTicketActivityController:GetGoldRewardItemIcon()
    local itemId = self:GetGoldRewardItemId()
    if not itemId then return nil end
    return XDataCenter.ItemManager.GetItemIcon(itemId)
end
--==============
--获取当前刮刮卡对象
--==============
function XScratchTicketActivityController:GetResetCount()
    return self.ResetCount or 0
end
--==============
--获取当前刮刮卡对象
--==============
function XScratchTicketActivityController:GetTicket()
    return self.Ticket
end
--==============
--获取活动开始时间戳
--==============
function XScratchTicketActivityController:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetTimeId())
end
--==============
--获取活动结束时间戳
--==============
function XScratchTicketActivityController:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
end
--==============
--获取黄金刮刮是否是重置状态
--==============
function XScratchTicketActivityController:GetResetStatus()
    return self.ResetStatus
end

return XScratchTicketActivityController