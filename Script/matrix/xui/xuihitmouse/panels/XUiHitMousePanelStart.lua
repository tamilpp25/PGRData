
local XUiHitMousePanelStart = {}

function XUiHitMousePanelStart.Init(ui)
    ui.StartPanel = {}
    XTool.InitUiObjectByUi(ui.StartPanel, ui.PanelStart)
    XUiHitMousePanelStart.InitText(ui)
end

function XUiHitMousePanelStart.InitText(ui)
    if not ui.StartPanel then return end
    local title, ruleDes = XDataCenter.HitMouseManager.GetRuleText()
    if ui.StartPanel.TxtTitle then
        ui.StartPanel.TxtTitle.text = title or ""
    end
    if ui.StartPanel.TxtRule then
        ui.StartPanel.TxtRule.text = ruleDes or ""
    end
end

function XUiHitMousePanelStart.PlayStart(ui, finishCb)
    if not ui then return end
    XLuaUiManager.SetMask(true)
    ui.StartPanel.GameObject:SetActiveEx(true)
    ui.StartPanel.PaneStartEnable:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            ui.StartPanel.StartEffect.gameObject:SetActiveEx(false)
            ui.StartPanel.GameObject:SetActiveEx(false)
            if finishCb then
                finishCb()
            end
        end)
end

return XUiHitMousePanelStart