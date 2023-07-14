
local XUiHitMousePanelCombo = {}

function XUiHitMousePanelCombo.Init(ui)
    ui.ComboPanel = {}
    XTool.InitUiObjectByUi(ui.ComboPanel, ui.PanelCombos)
    XUiHitMousePanelCombo.InitText(ui)
    local showCombo = (ui.FeverCount) and (ui.FeverCount > 0)
    ui.ComboPanel.TxtName.gameObject:SetActiveEx(showCombo)
    ui.ComboPanel.PanelProgress.gameObject:SetActiveEx(showCombo)
    ui.ComboPanel.ComboEffect.gameObject:SetActiveEx(false)
    ui.ComboPanel.ImgProgress.fillAmount = (ui.FeverComboCount > ui.FeverCount and ui.FeverComboCount or ui.FeverComboCount) / ui.FeverCount
end

function XUiHitMousePanelCombo.InitText(ui)
    if not ui.ComboPanel then return end
    XUiHitMousePanelCombo.SetComboText(ui)
end

function XUiHitMousePanelCombo.OnMoleDead(ui, mole)
    if mole.ContainId and mole.ContainId > 0 then
        if mole.Type == 1 then
            ui.ComboCount = ui.ComboCount + 1
            if not ui.IsFever then
                ui.FeverComboCount = ui.FeverComboCount + 1
            end
            XUiHitMousePanelCombo.OnComboChange(ui)
        else
            ui.MolesPanel.SoundHitQiShi.gameObject:SetActiveEx(false)
            ui.MolesPanel.SoundHitQiShi.gameObject:SetActiveEx(true)
            ui:ComboFailed()
        end
    end
end

function XUiHitMousePanelCombo.ComboFailed(ui)
    if not ui.IsFever then
        ui.ComboCount = 0
    end
    ui.FeverComboCount = 0
    XUiHitMousePanelCombo.OnComboChange(ui)
end

function XUiHitMousePanelCombo.SetComboText(ui)
    local targetSize = 50
    for i = #ui.ComboSizeDic, 1, -1 do
        local sizeDic = ui.ComboSizeDic[i]
        if ui.ComboCount >= sizeDic.Count then
            targetSize = sizeDic.Size
            break
        end
    end
    ui.ComboPanel.TxtCombo.text = XUiHelper.GetText("HitMouseComboString", targetSize, ui.ComboCount)
end

function XUiHitMousePanelCombo.OnComboChange(ui)
    XUiHitMousePanelCombo.SetComboText(ui)
    if not ui.IsFever and ui.ComboPanel.ImgProgress then
        ui.ComboPanel.ImgProgress.fillAmount = (ui.FeverComboCount > ui.FeverCount and ui.FeverComboCount or ui.FeverComboCount) / ui.FeverCount
    end
    if not ui.IsFever then
        local targetHitKey = 1
        for _, hitKey in pairs(ui.RefreshHitKeyList) do
            if ui.ComboCount >= hitKey then
                targetHitKey = hitKey
                break
            end
        end
        local targetRefreshCfg = ui.HitKey2RefreshDic[targetHitKey]
        ui.IsFever = false
        ui.ScoreRate = (targetRefreshCfg.HitScoreRate and targetRefreshCfg.HitScoreRate > 0 and targetRefreshCfg.HitScoreRate) or 1
        ui.RoundTime = targetRefreshCfg.MaxShowTime or 5
        ui.BreakTime = targetRefreshCfg.RestTime or 0.2
    end
end

function XUiHitMousePanelCombo.OnUpdate(ui)
    if not ui.IsFever then return end
    if ui.ComboPanel.ImgProgress then
        if ui.FeverTimeCount <= ui.FeverTime then
            ui.ComboPanel.ImgProgress.fillAmount = (ui.FeverTime - ui.FeverTimeCount) / ui.FeverTime
        end
    end
end

function XUiHitMousePanelCombo.StartFever(ui)
    if ui.ComboPanel.ComboEffect then
        ui.ComboPanel.ComboEffect.gameObject:SetActiveEx(true)
    end
end

function XUiHitMousePanelCombo.EndFever(ui)
    if ui.ComboPanel.ComboEffect then
        ui.ComboPanel.ComboEffect.gameObject:SetActiveEx(false)
    end
end

return XUiHitMousePanelCombo