local XUiPanelGuard = XClass(nil, "XUiPanelGuard")
local XUiGuildWarStageDetailEvent = require('XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent')

function XUiPanelGuard:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

---@param node XGWNode
function XUiPanelGuard:SetData(node)
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then return end
    
    self:RefreshCommonBuffs(node)
    
    self.RImgIcon:SetRawImage(buffData.Icon)
    self.TxtName.text = buffData.Name
    self.TxtDetails.text = buffData.Description
    self.PanelPass.gameObject:SetActiveEx(node:GetStutesType() == XGuildWarConfig.NodeStatusType.Die)

    
end

function XUiPanelGuard:RefreshCommonBuffs(node)
    if self._EventUis == nil then
        self._EventUis = {}
    end

    if not XTool.IsTableEmpty(self._EventUis) then
        for i, v in pairs(self._EventUis) do
            v.GameObject:SetActiveEx(false)
        end
    end
    self.PanelPass.gameObject:SetActiveEx(false)

    local buffCfgs = node:GetAllFightEventDetailConfig()
    -- 第一个特殊显示，通用buff从第二个开始
    for i = 2, #buffCfgs do
        local cfg = buffCfgs[i]

        local grid  = self._EventUis[i - 1]

        if not grid then
            local go = CS.UnityEngine.GameObject.Instantiate(self.PanelBuff, self.PanelBuff.transform.parent)
            grid = XUiGuildWarStageDetailEvent.New(go, self)
            self._EventUis[i - 1] = grid
        end

        grid.GameObject:SetActiveEx(true)
        grid:Update(cfg)
    end
end

return XUiPanelGuard
