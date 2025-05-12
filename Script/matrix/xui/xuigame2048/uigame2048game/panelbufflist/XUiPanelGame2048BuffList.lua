---@class XUiPanelGame2048BuffList: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiPanelGame2048BuffList = XClass(XUiNode, 'XUiPanelGame2048BuffList')
local XUiGridGame2048Buff = require('XUi/XUiGame2048/UiGame2048Game/PanelBuffList/XUiGridGame2048Buff')
local XUiPanelGame2048BuffDetail = require('XUi/XUiGame2048/UiGame2048Game/PanelBuffList/XUiPanelGame2048BuffDetail')

function XUiPanelGame2048BuffList:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.GridSkill.gameObject:SetActiveEx(false)
    self._BuffPool = XPool.New(function()
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridSkill, self.GridSkill.transform.parent)
        local grid = XUiGridGame2048Buff.New(go, self)
        return grid
    end,
    function(grid)
        grid:Close()
    end, false)

    self._ShowedBuffs = {}
    
    self._PanelBuffDetail = XUiPanelGame2048BuffDetail.New(self.PanelSkillBubble, self)
    self._PanelBuffDetail:Close()
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA, self.RefreshCurBuffsShow, self)
end

function XUiPanelGame2048BuffList:InitBuffs()
    self._StageId = self._Control:GetCurStageId()
    self:RecycleBuffs()

    local buffIds = self._Control:GetStageBuffIds(self._StageId)
    local initBuffCharges = self._Control:GetStageInitBuffCharges(self._StageId)

    if not XTool.IsTableEmpty(buffIds) then
        for i, v in ipairs(buffIds) do
            ---@type XUiGridGame2048Buff
            local grid = self._BuffPool:GetItemFromPool()
            grid:Open()
            grid:InitData(v, initBuffCharges[i] or 0)
            table.insert(self._ShowedBuffs, grid)
        end
    end
end

function XUiPanelGame2048BuffList:RecycleBuffs()
    if not XTool.IsTableEmpty(self._ShowedBuffs) then
        for i = #self._ShowedBuffs, 1, -1 do
            self._BuffPool:ReturnItemToPool(self._ShowedBuffs[i])
            table.remove(self._ShowedBuffs, i)
        end
    end
end

function XUiPanelGame2048BuffList:ShowBuffDetail(buffId, grid)
    self._PanelBuffDetail:Open()
    self._PanelBuffDetail:ShowDetail(buffId)
    local detailPos = self._PanelBuffDetail.Transform.position
    detailPos.y = grid.Transform.position.y
    self._PanelBuffDetail.Transform.position = detailPos
end

function XUiPanelGame2048BuffList:RefreshCurBuffsShow()
    if not XTool.IsTableEmpty(self._ShowedBuffs) then
        for i, v in pairs(self._ShowedBuffs) do
            v:RefreshaBuffStatus()
        end
    end
end

return XUiPanelGame2048BuffList