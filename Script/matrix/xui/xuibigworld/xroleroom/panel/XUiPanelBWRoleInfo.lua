---@class XUiPanelBWRoleInfo : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldRoleRoom
---@field _Control XBigWorldControl
local XUiPanelBWRoleInfo = XClass(XUiNode, "XUiPanelBWRoleInfo")

function XUiPanelBWRoleInfo:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiPanelBWRoleInfo:InitCb()
    self._RefreshHandler = function()
        --self:RefreshView(self._TeamId, self._EntityId, self._Pos)
        self.Parent:OnBtnDetailClicked()
    end
    self.BtnJoin.CallBack = function()
        self:OnBtnJoinClick()
    end

    self.BtnQuit.CallBack = function()
        self:OnBtnQuitClick()
    end
    
    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClick()
    end
    
    self.BtnExchange.CallBack = function() 
        self:OnBtnExchangeClick()
    end
end

function XUiPanelBWRoleInfo:InitView()
    self.BtnFashion:ShowReddot(false)
end

function XUiPanelBWRoleInfo:RefreshView(teamId, entityId, pos)
    self:Open()
    self._TeamId = teamId
    self._EntityId = entityId
    self._Pos = pos

    local agency = XMVCA.XBigWorldCharacter
    self.TxtName.text = agency:GetCharacterName(entityId)
    self.TxtNameOther.text = agency:GetCharacterTradeName(entityId)

    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(teamId)
    local isInTeam = team:HasSameEntity(entityId)
    local teamPos = team:GetEntityPos(entityId)
    self.BtnJoin.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuit.gameObject:SetActiveEx(isInTeam and teamPos == pos)
    self.BtnFashion.gameObject:SetActiveEx(not XMVCA.XBigWorldCharacter:IsCommandant(entityId))
    self.BtnExchange.gameObject:SetActiveEx(isInTeam and teamPos ~= pos)
end

function XUiPanelBWRoleInfo:OnBtnQuitClick()
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    local pos = team:GetEntityPos(self._EntityId)
    if pos > 0 then
        team:UpdateTeamByPos(pos, 0)
        --同步给服务器
        --XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, self._RefreshHandler)
        --不同步给服务器
        self._RefreshHandler()
    end
end

function XUiPanelBWRoleInfo:OnBtnJoinClick()
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    team:UpdateTeamByPos(self._Pos, self._EntityId)
    --同步给服务器
    --XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, self._RefreshHandler)
    --不同步给服务器
    self._RefreshHandler()
end

function XUiPanelBWRoleInfo:OnBtnFashionClick()
    if XMVCA.XBigWorldCharacter:IsCommandant(self._EntityId) then
        return
    end
    self._Control:OpenFashion(self._EntityId)
end

function XUiPanelBWRoleInfo:OnBtnExchangeClick()
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    local pos = team:GetEntityPos(self._EntityId)
    if pos > 0 and pos ~= self._Pos then
        team:SwitchPos(pos, self._Pos)
        --同步给服务器
        --XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, self._RefreshHandler)
        --不同步给服务器
        self._RefreshHandler()
    end
end

return XUiPanelBWRoleInfo
