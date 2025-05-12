local XLevelTools = {}

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTools.BasicFightUIControl(proxy, enable)
    --proxy:SetUiActive(EUiIndex.EnergyBarPanel,  enable)
    --proxy:SetUiActive(EUiIndex.ManualLockPanel,  enable)
    --proxy:SetUiActive(EUiIndex.Reborn,  enable)
    proxy:SetUiActive(EUiIndex.SkillBallPanel, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.Joystick, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnDodge, enable)
    --proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnExSkill,  enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, enable)
    --XLog.Debug("<color=#804000>[Guider]</color>常规战斗UI控制" .. tostring(enable))
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTools.AirFightUIControl(proxy, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    proxy:SetUiActive(EUiIndex.SkillBallPanel, enable)
    proxy:SetUiActive(EUiIndex.SpearPenetratePanel, enable)
end

---全局静止开关
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTools.PauseAllNpc(proxy, enable)
    local npcList = proxy:GetNpcList()
    if enable then
        for _, npc in pairs(npcList) do
            proxy:AddBuff(npc, 5000002)
        end
        XLog.Debug("XTOOL: THE WORLD!!!")
    else
        for _, npc in pairs(npcList) do
            proxy:RemoveBuff(npc, 5000002)
        end
        XLog.Debug("XTOOL: DLROW EHT!!!")
    end
end
---开关战斗UI
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTools.SetFightUiActive(proxy, enable)
    proxy:SetUiActive(EUiIndex.SkillBallPanel, enable)
    ---proxy:SetUiActive(EUiIndex.SpearPointPanel, not enable)
    --proxy:SetUiActive(EUiIndex.EnergyBarPanel, not enable)
    ---proxy:SetUiActive(EUiIndex.ManualLockPanel, not enable)
    ---proxy:SetUiActive(EUiIndex.Reborn, not enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.Joystick, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnDodge, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnExSkill, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, enable)
    proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, enable)
    XLog.Debug("<color=#804000>[Guider]</color>设置战斗UI开关" .. tostring(enable))
end

return XLevelTools