
local XUiHitMousePanelInfo = {}
local CsTime = CS.UnityEngine.Time

local TempTimeCount = 0

function XUiHitMousePanelInfo.Init(ui)
    ui.InfoPanel = {}
    XTool.InitUiObjectByUi(ui.InfoPanel, ui.PanelInformation)
    XUiHitMousePanelInfo.InitText(ui)
    TempTimeCount = 0
end

function XUiHitMousePanelInfo.InitText(ui)
    if not ui.InfoPanel then return end
    if ui.InfoPanel.TxtScore then
        ui.InfoPanel.TxtScore.text = 0
    end
    if ui.InfoPanel.TxtRemainTime then
        local stageConfig = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Stage,
            ui.StageId
        )
        ui.RemainTime = stageConfig and stageConfig.Time or 999
        ui.InfoPanel.TxtRemainTime.text = ui.RemainTime
    end
end

function XUiHitMousePanelInfo.OnMoleDead(ui, mole)
    if mole.ContainId and mole.ContainId > 0 then
        local moleCfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Mole,
            mole.ContainId
        )
        ui.Score = ui.Score + (moleCfg.ScoreAffix * ui.ScoreRate)
        XUiHitMousePanelInfo.OnScoreChange(ui)
        if ui.RemainTime > 0 then
            ui.RemainTime = ui.RemainTime - (moleCfg.ReduceTime or 0)
            ui.InfoPanel.TxtRemainTime.text = ui.RemainTime > 0 and ui.RemainTime or 0
            if ui.RemainTime <= 0 then
                TempTimeCount = 0
                ui.RemainTime = 0
                ui:TimesUp()
                return
            end
        end
    end
end

function XUiHitMousePanelInfo.OnScoreChange(ui)
    if ui.InfoPanel.TxtScore then
        ui.InfoPanel.TxtScore.text = ui.Score
    end
end

function XUiHitMousePanelInfo.OnUpdate(ui)
    local deltaTime = CsTime.deltaTime
    if not ui.IsFever and ui.RemainTime > 0 then
        TempTimeCount = TempTimeCount + deltaTime
        if ui.RemainTime >= 1 and TempTimeCount >= 1 then
            TempTimeCount = TempTimeCount - 1
            ui.RemainTime = ui.RemainTime - 1
            ui.InfoPanel.TxtRemainTime.text = ui.RemainTime
        end
        if ui.RemainTime <= 0 then
            TempTimeCount = 0
            ui:TimesUp()
            return
        end
    end
    if ui.RoundTimeFlag then
        if not ui.RoundTime then
            local refreshDic = XHitMouseConfigs.GetCfgByIdKey(
                XHitMouseConfigs.TableKey.Stage2Refresh,
                ui.StageId
            )
            local hitKeyList = {}
            for hitKey, _ in pairs(refreshDic) do
                table.insert(hitKeyList, hitKey)
            end
            table.sort(hitKeyList, function(v1, v2) return v1 > v2 end)
            local targetHitKey = 1
            for _, hitKey in pairs(hitKeyList) do
                if ui.ComboCount >= hitKey then
                    targetHitKey = hitKey
                    break
                end
            end
            local targetRefreshCfg = refreshDic[targetHitKey]
            ui.RoundTime = targetRefreshCfg.MaxShowTime
            ui.BreakTime = targetRefreshCfg.RestTime
        end
        if ui.IsFever then
            ui.FeverTimeCount = ui.FeverTimeCount + deltaTime
            if ui.FeverTimeCount >= ui.FeverTime then
                ui.RoundTimeFlag = false
                ui.RoundTimeCount = 0
                ui:EndFever(true)
                return
            end
        end
        ui.RoundTimeCount = ui.RoundTimeCount + deltaTime
        if ui.RoundTimeCount >= ui.RoundTime then
            ui.RoundTimeFlag = false
            ui.RoundTimeCount = 0
            --XLog.Error("轮数：" .. ui.Round .." 清屏触发：本轮时间到")
            ui:ClearRound()
            return
        end
    end
    if ui.BreakTimeFlag then
        ui.BreakTimeCount = ui.BreakTimeCount + deltaTime
        if ui.BreakTime and ui.BreakTimeCount >= ui.BreakTime then
            ui.BreakTimeFlag = false
            ui.BreakTime = nil
            ui:NewRound()
        end
    end
end

return XUiHitMousePanelInfo