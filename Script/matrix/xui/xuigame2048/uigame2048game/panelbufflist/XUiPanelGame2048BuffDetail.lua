---@class XUiPanelGame2048BuffDetail: XUiNode
---@field private _Control XGame2048Control
---@field private _GameControl XGame2048GameControl
local XUiPanelGame2048BuffDetail = XClass(XUiNode, 'XUiPanelGame2048BuffDetail')
local XUiGridGame2048StageBuff = require('XUi/XUiGame2048/UiGame2048StageDetail/XUiGridGame2048StageBuff')

function XUiPanelGame2048BuffDetail:OnStart()
    self._BuffGrid = XUiGridGame2048StageBuff.New(self.GridSkill, self)
    self._BuffGrid:Open()

    self._GameControl = self._Control:GetGameControl()
end

function XUiPanelGame2048BuffDetail:OnEnable()
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_OPTION, self.HideDetail, self)
end

function XUiPanelGame2048BuffDetail:OnDisable()
    self._GameControl:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_OPTION, self.HideDetail, self)
end

function XUiPanelGame2048BuffDetail:ShowDetail(buffId)
    local buffIcon = self._Control:GetBuffIcon(buffId)
    local buffDesc = self._Control:GetBuffDesc(buffId)
    local buffName = self._Control:GetBuffName(buffId)
    
    self._BuffGrid:Refresh(buffIcon, buffDesc, buffName)
    self.BtnClose.gameObject:SetActiveEx(true)
    self.BtnClose.CallBack = handler(self, self.HideDetail)
end

function XUiPanelGame2048BuffDetail:HideDetail()
    self.BtnClose.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = nil
    self:Close()
end

return XUiPanelGame2048BuffDetail