---@class XMusicGameActivityAgency : XAgency
---@field private _Model XMusicGameActivityModel
local XMusicGameActivityAgency = XClass(XAgency, "XMusicGameActivityAgency")
function XMusicGameActivityAgency:OnInit()
    --初始化一些变量
end

function XMusicGameActivityAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyMusicGameData = handler(self, self.NotifyMusicGameData)
end

function XMusicGameActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

-- 判断是否可以显示红点，是基于大好感剧情是否产生互动做的，并且只有固定的两个cd入口能显示（这个靠策划配置，程序通过检测有没有配置 IconSp 来判断
function XMusicGameActivityAgency:CheckCanShowGridRed(arrangementMusicId)
    local allArrangementMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    if not XTool.IsNumberValid(arrangementMusicId) then
        return false
    end
    
    local musicConfig = allArrangementMusicConfig[arrangementMusicId]
    local hasIconCdSp = musicConfig and (not string.IsNilOrEmpty(musicConfig.IconCdSp))
    if not hasIconCdSp then
        return false
    end
    
    local condition2 = self:CheckShow2Condition(arrangementMusicId)
    local canShow2 = hasIconCdSp and condition2
    local hasShow2Key = string.format("IsFirstShowCD_%d_PlayerId_%d", arrangementMusicId, XPlayer.Id)
    local hasShow2 = XSaveTool.GetData(hasShow2Key)

    local isFirstShow2 = (not hasShow2) and canShow2
    if isFirstShow2 then
        return true
    else
        return false
    end
end

function XMusicGameActivityAgency:CheckHasPlayShow2Anim(arrangementMusicId)
    local key = string.format("HasPlayShow2Anim_%d_PlayerId_%d", arrangementMusicId, XPlayer.Id)
    local res = XSaveTool.GetData(key)
    return res
end

function XMusicGameActivityAgency:CheckShow2Condition(arrangementMusicId)
    local tbk = -- Q：为什么是这俩id ；A：策划设计的
    {
        [101] = 1050106,
        [106] = 1050105,
    }
    local cId = tbk[arrangementMusicId]
    if not cId then
        return false
    end

    local res = XConditionManager.CheckCondition(cId)
    return res
end

function XMusicGameActivityAgency:OpenUi()
    if not XTool.IsNumberValid(self._Model.ActivityId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("ConsumeActivityNotOpen"))
        return
    end
    XSaveTool.SaveData(self:GetHasEnterKey(), true)

    XLuaUiManager.Open("UiMusicGameActivityMain")
end

function XMusicGameActivityAgency:GetHasEnterKey()
    local key = string.format("XMusicGameActivityAgency.OpenUi:PlayerId%d", XPlayer.Id)
    return key
end

function XMusicGameActivityAgency:GetTaskGroupIds()
    if not XTool.IsNumberValid(self._Model.ActivityId) then
        return
    end
    
    return self._Model:GetMusicGameActivity()[self._Model.ActivityId].TaskGroupIds
end

function XMusicGameActivityAgency:GetCurActivityConfig()
    return self._Model:GetMusicGameActivity()[self._Model.ActivityId]
end

function XMusicGameActivityAgency:GetPassArrangementMusicIds()
    return self._Model.ArrangementMusicIds
end

function XMusicGameActivityAgency:GetPassRhythmMapIds()
    return self._Model.PassRhythmMapIds
end

function XMusicGameActivityAgency:GetEnableMapIds()
    local musicGameControlConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()
    local rhythmGameControlConfig = XMVCA.XRhythmGame:GetModeltRhythmGameControl()[musicGameControlConfig.RhythmGameControlId]
    local res = {}
    for k, mapId in pairs(rhythmGameControlConfig.MapIds) do
        local cId = rhythmGameControlConfig.MapConditions[k]
        if (not cId) or (XConditionManager.CheckCondition(cId)) then
            table.insert(res, mapId)
        end
    end
    return res
end

function XMusicGameActivityAgency:NotifyMusicGameData(data)
    if XTool.IsTableEmpty(data) then
        -- 发空的
        return
    end
    self._Model:RefreshServerData(data)
end

return XMusicGameActivityAgency