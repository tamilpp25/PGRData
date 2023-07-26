
local XUiHitMousePanelStageGrid = XClass(nil, "XUiHitMousePanelStageGrid")

function XUiHitMousePanelStageGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.BtnClick.CallBack = function() self:OnClick() end
end

function XUiHitMousePanelStageGrid:RefreshData(stageId)
    self.StageId = stageId
    self:Refresh()
end

function XUiHitMousePanelStageGrid:Refresh()
    local cfg = XHitMouseConfigs.GetCfgByIdKey(
        XHitMouseConfigs.TableKey.Stage,
        self.StageId
    )
    self.TxtStageName.text = cfg.StageName
    self.TxtScore.text = XDataCenter.HitMouseManager.GetStageScore(self.StageId)
    local isUnlock = XDataCenter.HitMouseManager.CheckStageUnlock(self.StageId)
    self.IsUnlock = isUnlock
    if isUnlock then
        self.RImgBg.gameObject:SetActiveEx(true)
        self.RImgEnemy:SetRawImage(cfg.BgImgUrl)
    else
        self.RImgBg.gameObject:SetActiveEx(false)
    end
    if isUnlock then
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.PanelLock.gameObject:SetActiveEx(true)
        self.IsPreUnlock = XDataCenter.HitMouseManager.CheckPreStageUnlock(self.StageId)
        self.IsPreClear = XDataCenter.HitMouseManager.CheckPreStageClear(self.StageId)
        if (not self.IsPreUnlock) or (not self.IsPreClear) then
            self.PanelTextLock.gameObject:SetActiveEx(false)
            self.TxtLock.gameObject:SetActiveEx(true)
            self.TxtLock.text = XUiHelper.GetText("HitMousePreStageNotClear")
        else
            self.PanelTextLock.gameObject:SetActiveEx(true)
            self.TxtLock.gameObject:SetActiveEx(false)
            local itemId = XDataCenter.HitMouseManager.GetUnlockItemId()
            if itemId > 0 then
                self.RImgLockItem:SetRawImage(XEntityHelper.GetItemIcon(itemId))
                self.TxtLockItem.text = XUiHelper.GetText("HitMouseStageLockText", cfg.UnlockItemCount)
            end
        end
    end
end

function XUiHitMousePanelStageGrid:OnClick()
    if self.IsUnlock then
        XLuaUiManager.Open("UiHitMouse", self.StageId)
    else
        if self.IsPreUnlock and self.IsPreClear then
            local itemId = XDataCenter.HitMouseManager.GetUnlockItemId()
            if itemId > 0 then
                local cfg = XHitMouseConfigs.GetCfgByIdKey(
                    XHitMouseConfigs.TableKey.Stage,
                    self.StageId
                )
                if XDataCenter.ItemManager.GetCount(itemId) >= cfg.UnlockItemCount then
                    XDataCenter.HitMouseManager.StageUnlock(self.StageId, function()
                            self.IsUnlock = true
                            self.PanelLock.gameObject:SetActiveEx(false)
                            self.RImgBg.gameObject:SetActiveEx(true)
                            self.RImgEnemy:SetRawImage(cfg.BgImgUrl)
                        end)
                else
                    XUiManager.TipMsg(XUiHelper.GetText("HitMouseItemNotEnough"))
                end
            else
                XUiManager.TipMsg(XUiHelper.GetText("HitMouseCantFindItem"))
            end
        else
            XUiManager.TipMsg(XUiHelper.GetText("HitMousePreStageNotClear"))
        end
    end
end

return XUiHitMousePanelStageGrid