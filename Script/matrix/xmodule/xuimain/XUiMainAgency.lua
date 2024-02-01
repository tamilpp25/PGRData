-- 主界面模块管理器
---@class XUiMainAgency : XAgency
---@field private _Model XUiMainModel
local XUiMainAgency = XClass(XAgency, "XUiMainAgency")
function XUiMainAgency:OnInit()
    --初始化一些变量
    self:CheckClearAllPanelTipClicked()
end

function XUiMainAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XUiMainAgency:InitEvent()
    --实现跨Agency事件注册
    self:AddAgencyEvent(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH, self.ClearAllPanelTipClicked, self) -- 每天五点 恢复蓝点检测
end

----------public start----------
function XUiMainAgency:GetModelUiPanelTip()
    return self._Model:GetUiPanelTip()
end

function XUiMainAgency:GetModelUiPanelTipById(id, notTipError)
    local config = self:GetModelUiPanelTip()[id]
    if XTool.IsTableEmpty(config) and not notTipError then
        XLog.Error("表Client/UiMain/UiPanelTip.tab Id:" .. id .. "未配置")
    end

    return config
end

-- 珍惜道具获取接口
function XUiMainAgency:GetAllExpensiveiItems()
    if self._Model.ConfigExpensiveiItem then
        return self._Model.ConfigExpensiveiItem
    end
    local path = "Share/Item/ExpensiveiItem.tab"
    local allConfig = XTableManager.ReadByIntKey(path, XTable.XTableExpensiveiItem, "ItemId")
    self._Model.ConfigExpensiveiItem = allConfig
    return allConfig
end

-- 获取激活提示的珍惜道具
function XUiMainAgency:GetAllActiveTipExpensiveiItems()
    local allConfig = self:GetAllExpensiveiItems()
    local res = {}
    for itemId, v in pairs(allConfig) do
        local leftTime = XDataCenter.ItemManager.GetRecycleLeftTime(itemId)
        -- 检测开启提示的倒计时时间
        local hasCount = XDataCenter.ItemManager.GetCount(itemId)
        if XTool.IsNumberValid(leftTime) and leftTime < v.LeftTime and XTool.IsNumberValid(hasCount) then
            table.insert(res, v)
        end
    end
    return res
end

-- 记录当前点击的终端缓存
function XUiMainAgency:RecordPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked"..panelTipId
    local nextRefreshTs = XTime.GetSeverNextRefreshTime()
    XSaveTool.SaveData(key, nextRefreshTs)
end

-- 每次登录时检测是否清除当天的点击缓存，如果超过5点就清除
function XUiMainAgency:CheckClearAllPanelTipClicked()
    local allPanleTip = self:GetModelUiPanelTip()
    for id, v in pairs(allPanleTip) do
        local recordTs = self:CheckPanelTipClicked(id)
        local nextTs = XTime.GetSeverNextRefreshTime()
        if recordTs and recordTs ~= nextTs then
            self:ClearPanelTipClicked(id)
        end
    end
end

-- 清除所有终端点击缓存
function XUiMainAgency:ClearAllPanelTipClicked()
    local allPanleTip = self:GetModelUiPanelTip()
    for id, v in pairs(allPanleTip) do
        self:ClearPanelTipClicked(id)
    end
end

function XUiMainAgency:ClearPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked"..panelTipId
    XSaveTool.SaveData(key, false)
end

function XUiMainAgency:CheckPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked"..panelTipId
    return XSaveTool.GetData(key)
end

function XUiMainAgency:GetScrollTipList(ignoreOnTerminal)
    local list = {}
    local templates = self:GetModelUiPanelTip() or {}
    for _, template in pairs(templates) do
        if not ignoreOnTerminal or (ignoreOnTerminal and template.IgnoreOnTerminal ~= 1) then
            local func = self[template.FunctionName]
            local tip = func and func(self, ignoreOnTerminal) or nil
            if not string.IsNilOrEmpty(tip) then
                table.insert(list, {
                    Tips = tip,
                    Type = template.Type,
                    Config = template
                })
            end
        end
    end

    if not XTool.IsTableEmpty(list) then
        table.sort(list, function(a, b) 
            return a.Config.Priority < b.Config.Priority
        end)
    end
    
    return list
end

function XUiMainAgency:GetYkScrollTip()
    if not XDataCenter.PurchaseManager.CheckYKContinueBuy() then
        return
    end
    
    return XUiHelper.GetText("PurchaseYKExpireDes")
end

function XUiMainAgency:GetPurchaseScrollTip()
    local giftCount = XDataCenter.PurchaseManager.ExpireCount or 0
    if giftCount <= 0 then
        return
    end

    if giftCount == 1 then
        return XUiHelper.GetText("PurchaseGiftValitimeTips1")
    end
    
    return XUiHelper.GetText("PurchaseGiftValitimeTips2")
end

function XUiMainAgency:GetDormQuestScrollTip()
    -- 宿舍终端提示 可领取 > 可派遣
    local dispatchedCount, unDispatchCount = XDataCenter.DormQuestManager.GetEntranceShowData()
    if dispatchedCount > 0 then
        return XUiHelper.GetText("DormQuestTerminalMainTeamRegress", dispatchedCount)
    elseif unDispatchCount > 0 then
        return XUiHelper.GetText("DormQuestTerminalMainTeamFree", unDispatchCount)
    end
end

function XUiMainAgency:GetExpensiveScrollTip(isIgnoreDayCheck)
    local allItem = self:GetAllActiveTipExpensiveiItems()
    if XTool.IsTableEmpty(allItem) or (self:CheckPanelTipClicked(XEnumConst.Ui_MAIN.TerminalTipType.ExpensiveItem) and not isIgnoreDayCheck) then
        return
    end
    
    return XUiHelper.GetText("ExpensiveItemExpiration")
end

function XUiMainAgency:GetSubpackageScrollTip()
    return XMVCA.XSubPackage:GetDownloadingTip()
end

function XUiMainAgency:GetPreloadScrollTip()
    return XMVCA.XPreload:GetDownloadingTip()
end

----------public end----------

----------private start----------


----------private end----------

return XUiMainAgency