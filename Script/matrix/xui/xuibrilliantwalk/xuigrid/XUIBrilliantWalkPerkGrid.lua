--XUiBrilliantWalkPerk Perk选择界面的PerkGrid
local XUIBrilliantWalkPerkGrid = XClass(nil, "XUIBrilliantWalkPerkGrid")


function XUIBrilliantWalkPerkGrid:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridPerk.CallBack = function()
        self:OnClickGrid()
    end
    self.BtnSelect.CallBack = function()
        self:OnClickSelect()
    end
end

function XUIBrilliantWalkPerkGrid:UpdateView(perkId,index)
    self.BtnSelect.gameObject.name = "BtnSelect"..index
    self.PerkId = perkId
    --如果无id 或者 没解锁 隐藏Grid
    if (not self.PerkId) or (not XDataCenter.BrilliantWalkManager.CheckPluginUnlock(self.PerkId)) then
        self.PanelLock.gameObject:SetActiveEx(true)
        self.PanelUnlock.gameObject:SetActiveEx(false)
        self.GridPerk:ShowReddot(false)
        return
    end
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelUnlock.gameObject:SetActiveEx(true)
    --设置Perk信息
    local perkConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(self.PerkId)
    if perkConfig.Icon then
        self.ImgIcon:SetRawImage(perkConfig.Icon)
    end
    self.TxtName.text = perkConfig.Name
    self.TxtDesc.text = perkConfig.Desc
    --红点
    self.GridPerk:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(self.PerkId))
end

--设置是否已被选择
function XUIBrilliantWalkPerkGrid:SetSelected(state)
    self.BtnSelect:SetDisable(state, not state)
end

function XUIBrilliantWalkPerkGrid:OnClickSelect()
    XDataCenter.BrilliantWalkManager.UiViewPlugin(self.PerkId)
    self.GridPerk:ShowReddot(false)
    self.RootUi:OnGridClick(self)
end

function XUIBrilliantWalkPerkGrid:OnClickGrid()
    if (not self.PerkId) or (not XDataCenter.BrilliantWalkManager.CheckPluginUnlock(self.PerkId)) then
        return
    end
    XDataCenter.BrilliantWalkManager.UiViewPlugin(self.PerkId)
    self.GridPerk:ShowReddot(false)
end

return XUIBrilliantWalkPerkGrid