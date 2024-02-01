--######################## XUiRoleGrid ########################
local XUiRoleGrid = XClass(nil, "XUiRoleGrid")

function XUiRoleGrid:Ctor(ui)
    self.GuildWarManager = XDataCenter.GuildWarManager
    XUiHelper.InitUiClass(self, ui)
end

function XUiRoleGrid:SetData(roleId)
    local hasRole = roleId ~= nil and roleId > 0
    self.PanelNone.gameObject:SetActiveEx(not hasRole)
    self.PanelContent.gameObject:SetActiveEx(hasRole)
    if not hasRole then
        return
    end
    self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(roleId))
    local buffData = self.GuildWarManager.GetSpecialRoleBuff(roleId)
    if buffData == nil then return end
    self.RImgSkillIcon:SetRawImage(buffData.Icon)
    if self.TxtSkillName then
        self.TxtSkillName.text = buffData.Name
    end
    self.TxtSkillDesc.text = buffData.Desc 
end

--######################## XUiGuildWarUpCharacter ########################
local XUiGuildWarUpCharacter = XLuaUiManager.Register(XLuaUi, "UiGuildWarUpCharacter")
local UI_MAX_ROLE = 4

-- 特公角色界面
function XUiGuildWarUpCharacter:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self:RegisterUiEvents()
end

function XUiGuildWarUpCharacter:OnStart()
    -- 特攻角色列表
    local roleIds = self.GuildWarManager.GetSpecialRoleList()
    local roleGrid
    for i = 1, UI_MAX_ROLE do
        roleGrid = XUiRoleGrid.New(self["PanglUpCharater" .. i])
        roleGrid:SetData(roleIds[i])
    end
    -- 队伍技能
    local teamBuff = self.GuildWarManager.GetSpecialTeamBuff()
    if teamBuff == nil then return end
    self.RImgTeamSkillIcon:SetRawImage(teamBuff.Icon)
    self.TxtTeamSkillDesc.text = teamBuff.Desc
end

--######################## 私有方法 ########################

function XUiGuildWarUpCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose1, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClose2, self.Close)
end

return XUiGuildWarUpCharacter