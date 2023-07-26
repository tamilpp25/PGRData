--================
--我方角色头像控件
--================
local XUiSSBPickGridCharaHead = XClass(nil, "XUiSSBPickGridCharaHead")

function XUiSSBPickGridCharaHead:Ctor()
    
end

function XUiSSBPickGridCharaHead:Init(ui, list)
    self.List = list
    XTool.InitUiObjectByUi(self, ui)
    --点击事件写在列表事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function() self:OnClick() end)
end

function XUiSSBPickGridCharaHead:Refresh(roleData, teamData)
    if roleData and roleData.RandomGrid then --若这是随机格，则设置为随机选取
        self:SetRandom()
        return
    end
    self.Role = roleData
    self.IsRandom = false
    if self.PanelAbility then
        self.PanelAbility.gameObject:SetActiveEx(true)
    end
    if self.TxtAbility then
        self.TxtAbility.text = self.Role:GetAbility()
    end
    if self.RImgHead then
        self.RImgHead:SetRawImage(self.Role:GetSmallHeadIcon())
    end
    if self.PanelCore then
        local core = self.Role:GetCore()
        self.PanelCore.gameObject:SetActiveEx(core ~= nil)
        if core and self.RImgCore then
            self.RImgCore:SetRawImage(core:GetIcon())
        end
    end
    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(self.Role:GetIsRobot())
    end
    if self.PanelCheck then
        local roleId = self.Role:GetId()
        local isCheck = false
        local pos = 0
        for position, teamRoleId in pairs(teamData.RoleIds) do
            if teamRoleId == roleId then
                isCheck = true
                pos = position
                break
            end
        end
        self.PanelCheck.gameObject:SetActiveEx(isCheck)
        if isCheck and self.TxtCheck then
            self.TxtCheck.text = XUiHelper.GetText("SSBCharaHeadCheck", pos)
        end
    end
end

function XUiSSBPickGridCharaHead:SetRandom()
    self.IsRandom = true
    if self.PanelAbility then
        self.PanelAbility.gameObject:SetActiveEx(false)
    end
    if self.RImgHead then
        self.RImgHead:SetRawImage(CS.XGame.ClientConfig:GetString("SmashBrosCharaHeadRandom"))
    end
    if self.PanelCore then
        self.PanelCore.gameObject:SetActiveEx(false)
    end
    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(false)
    end
    if self.PanelCheck then
        self.PanelCheck.gameObject:SetActiveEx(false)
    end
end

function XUiSSBPickGridCharaHead:GetRoleId()
    if self.IsRandom then return XSuperSmashBrosConfig.PosState.Random end
    return self.Role:GetId()
end

function XUiSSBPickGridCharaHead:OnClick()
    self.List:OnGridSelect(self)
end

return XUiSSBPickGridCharaHead