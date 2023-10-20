local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

---@class XUiStrongholdAnimation : XLuaUi
local XUiStrongholdAnimation = XLuaUiManager.Register(XLuaUi, "UiStrongholdAnimation")

function XUiStrongholdAnimation:OnAwake()
    self.GridBuffBoss.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnClose, self.OnClickClose)
end

function XUiStrongholdAnimation:OnStart(groupId, closeCb)
    self.CloseCb = closeCb
    self.BossBuffGrids = {}

    self.TxtNameTitle.text = XStrongholdConfigs.GetGroupName(groupId)

    --据点BossBuff
    local bossBuffIds = XDataCenter.StrongholdManager.GetGroupBossBuffIds(groupId)
    local showBossBuff = #bossBuffIds > 0
    self.PanelBossBuffs.gameObject:SetActiveEx(showBossBuff)

    for index, buffId in ipairs(bossBuffIds) do
        ---@type XUiGridStrongholdAnimation
        local grid = self.BossBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuffBoss or CSUnityEngineObjectInstantiate(self.GridBuffBoss, self.PanelBossBuffs)
            grid = require("XUi/XUiStronghold/Grid/XUiGridStrongholdAnimation").New(go, self)
            self.BossBuffGrids[index] = grid
        end

        grid:Refresh(buffId, true)
        grid:Open()
    end

    for index = #bossBuffIds + 1, #self.BossBuffGrids do
        local grid = self.BossBuffGrids[index]
        if grid then
            grid:Close()
        end
    end

    --据点BaseBuff
    local baseBuffIds = XDataCenter.StrongholdManager.GetGroupBaseBuffIds(groupId)
    local showBaseBuff = #baseBuffIds > 0
    self.PanelBaseBuffs.gameObject:SetActiveEx(showBaseBuff)

    for i = 1, 3 do
        local go = self["GridBuffBase" .. i]
        if go then
            local buffId = baseBuffIds[i]
            ---@type XUiGridStrongholdAnimation
            local grid = require("XUi/XUiStronghold/Grid/XUiGridStrongholdAnimation").New(go, self)
            if XTool.IsNumberValid(buffId) then
                grid.GridBuffBoss.gameObject:SetActiveEx(true)
                grid.ImgVacant.gameObject:SetActiveEx(false)
                grid:Refresh(buffId, false)
            else
                grid.GridBuffBoss.gameObject:SetActiveEx(false)
                grid.ImgVacant.gameObject:SetActiveEx(true)
            end
        end
    end
end

function XUiStrongholdAnimation:OnClickClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end