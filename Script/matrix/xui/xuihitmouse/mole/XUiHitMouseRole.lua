
local XUiHitMouseRole = XClass(nil, "XUiHitMouseRole")

function XUiHitMouseRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
end

function XUiHitMouseRole:RefreshPrefab(prefab)
    self.Mole = {}
    XTool.InitUiObjectByUi(self.Mole, prefab)
    self.Mole.PanelNormal.gameObject:SetActiveEx(true)
    self.Mole.PanelHit.gameObject:SetActiveEx(false)
end

function XUiHitMouseRole:Appear(animFinishCb)
    self:Show()
    if self.Mole.PanelEgg then
        self.Mole.PanelEgg.gameObject:SetActiveEx(false)
    end
    self.Mole.AnimEnable.transform:PlayTimelineAnimation(function()
            if animFinishCb then
                animFinishCb()
            end
        end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiHitMouseRole:Disappear(animFinishCb)
    if self.Mole.GameObject.activeInHierarchy then
        self.Mole.AnimDisable.transform:PlayTimelineAnimation(function()
                if animFinishCb then
                    animFinishCb()
                end
                self:Hide()
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    else
        if animFinishCb then
            animFinishCb()
        end
        self:Hide()
    end
end

function XUiHitMouseRole:Hit(animFinishCb)
    if self.Mole.PanelEgg then
        self.Mole.PanelEgg.gameObject:SetActiveEx(true)
    end
    if self.Mole.AnimHit then
        self.Mole.AnimHit.transform:PlayTimelineAnimation(function()
                if animFinishCb then
                    animFinishCb()
                end
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    else
        self.Mole.PanelNormal.gameObject:SetActiveEx(false)
        self.Mole.PanelHit.gameObject:SetActiveEx(true)
        XScheduleManager.ScheduleOnce(function()
                if self.Mole.GameObject ~= nil then
                    if animFinishCb then
                        animFinishCb()
                    end
                end
            end, 100)
    end
end

function XUiHitMouseRole:Wait()
    self.Mole.PanelNormal.gameObject:SetActiveEx(true)
    self.Mole.PanelHit.gameObject:SetActiveEx(false)
end

function XUiHitMouseRole:Show()
    self.Mole.GameObject:SetActiveEx(true)
end

function XUiHitMouseRole:Hide()
    self.Mole.GameObject:SetActiveEx(false)
end

return XUiHitMouseRole